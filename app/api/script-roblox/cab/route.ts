import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import crypto from "crypto";
import pool from "../../../../lib/db";

// Fast in-memory cache for warm serverless containers
let globalCache: { sourceHash: string; obfuscatedCode: string } | null = null;

function makeId(length = 8): string {
  let result = "";
  const characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  result += characters.charAt(Math.floor(Math.random() * characters.length));
  const fullChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
  for (let i = 1; i < length; i++) {
    result += fullChars.charAt(Math.floor(Math.random() * fullChars.length));
  }
  return result;
}

function stripComments(code: string): string {
  // Strip multi-line comments: --[[ ... ]]
  let clean = code.replace(/--\[\[[\s\S]*?\]\]/g, "");
  // Strip single-line comments: -- ...
  clean = clean.split("\n").map(line => {
    let inDouble = false;
    let inSingle = false;
    for (let i = 0; i < line.length; i++) {
      const c = line[i];
      if (c === '"' && line[i - 1] !== "\\") inDouble = !inDouble;
      if (c === "'" && line[i - 1] !== "\\") inSingle = !inSingle;
      if (c === "-" && line[i + 1] === "-" && !inDouble && !inSingle) {
        return line.substring(0, i);
      }
    }
    return line;
  }).join("\n");
  return clean;
}

function unescapeLuaString(s: string): string {
  return s
    .replace(/\\n/g, "\n")
    .replace(/\\t/g, "\t")
    .replace(/\\r/g, "\r")
    .replace(/\\b/g, "\b")
    .replace(/\\f/g, "\f")
    .replace(/\\v/g, "\v")
    .replace(/\\\\/g, "\\")
    .replace(/\\"/g, '"')
    .replace(/\\'/g, "'")
    .replace(/\\(\d{1,3})/g, (match, p1) => {
      return String.fromCharCode(parseInt(p1, 10));
    })
    .replace(/\\x([0-9a-fA-F]{2})/g, (match, p1) => {
      return String.fromCharCode(parseInt(p1, 16));
    });
}

function localObfuscate(code: string, decName: string, key: number): string {
  const strings: string[] = [];
  const stringRegex = /"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/g;

  const result = code.replace(stringRegex, (match) => {
    const content = match.slice(1, -1);
    const unescaped = unescapeLuaString(content);
    strings.push(unescaped);
    return `${decName}(${strings.length})`;
  });

  const arrayName = makeId(8);
  const encryptedStrings = strings.map(s => {
    const bytes: number[] = [];
    const buf = Buffer.from(s, "utf8");
    for (let i = 0; i < buf.length; i++) {
      bytes.push(buf[i] ^ key);
    }
    return bytes.join(",");
  });

  const finalCode = `
local ${arrayName} = {
  ${encryptedStrings.map((s, idx) => `[${idx + 1}] = {${s}}`).join(",\n  ")}
}
local function ${decName}(idx)
  local data = ${arrayName}[idx]
  if not data then return "" end
  local chars = {}
  for i = 1, #data do
    table.insert(chars, string.char(bit32.bxor(data[i], ${key})))
  end
  return table.concat(chars)
end

${result}
`;

  return finalCode;
}

function obfuscateLuaXor(code: string, licenseKey: string): string {
  // 1. Scramble all strings inside the script using a random key
  const decName = makeId(8);
  const encryptionKey = Math.floor(Math.random() * 254) + 1;
  const scrambledCode = localObfuscate(stripComments(code), decName, encryptionKey);

  // 2. Encrypt the scrambled output using the standard LCG XOR stream cipher
  const clean = scrambledCode;

  // Derive an initial 31-bit seed from the license key (modulo 2147483647)
  let seed = 5381;
  for (let i = 0; i < licenseKey.length; i++) {
    seed = (seed * 33 + licenseKey.charCodeAt(i)) % 2147483647;
  }
  if (seed === 0) {
    seed = 123456789;
  }

  let hexString = "";
  const buf = Buffer.from(clean, "utf8");
  let currentSeed = seed;

  for (let i = 0; i < buf.length; i++) {
    currentSeed = (currentSeed * 48271) % 2147483647;
    const keyByte = currentSeed % 256;
    const encryptedByte = buf[i] ^ keyByte;
    hexString += encryptedByte.toString(16).padStart(2, "0");
  }

  // Generate randomized identifiers
  const varSeed = makeId(10);
  const varPayload = makeId(10);
  const varSource = makeId(10);
  const varIndex = makeId(10);
  const varFunc = makeId(10);
  const varErr = makeId(10);
  const varKeyByte = makeId(10);
  const varByteStr = makeId(10);
  const varVal = makeId(10);

  const obfuscated = `
local ${varSeed} = ${seed}
local ${varPayload} = "${hexString}"
local ${varSource} = {}
for ${varIndex} = 1, #${varPayload}, 2 do
    local ${varByteStr} = string.sub(${varPayload}, ${varIndex}, ${varIndex} + 1)
    local ${varVal} = tonumber(${varByteStr}, 16)
    ${varSeed} = (${varSeed} * 48271) % 2147483647
    local ${varKeyByte} = ${varSeed} % 256
    table.insert(${varSource}, string.char(bit32.bxor(${varVal}, ${varKeyByte})))
end
local ${varFunc}, ${varErr} = loadstring(table.concat(${varSource}))
if not ${varFunc} then
    error("HipHub Boot Error: Connection payload is corrupted: " .. tostring(${varErr}))
end
${varFunc}()
`;
  return obfuscated;
}

async function obfuscateLua(code: string): Promise<string> {
  const apiKey = process.env.LURAPH_API_KEY;
  if (!apiKey) {
    throw new Error("LURAPH_API_KEY is not set.");
  }

  // 1. Get recommended obfuscation node
  const nodesRes = await fetch("https://api.lura.ph/v1/obfuscate/nodes", {
    headers: {
      "Luraph-API-Key": apiKey,
    },
  });
  if (!nodesRes.ok) {
    const errorBody = await nodesRes.text().catch(() => "");
    throw new Error(`Failed to fetch Luraph nodes: ${nodesRes.status} ${nodesRes.statusText} ${errorBody}`);
  }
  const nodesData = (await nodesRes.json()) as { recommendedId: string; nodes: Record<string, any> };
  const node = nodesData.recommendedId;

  // 2. Create obfuscation job
  const scriptBase64 = Buffer.from(code).toString("base64");
  const newJobRes = await fetch("https://api.lura.ph/v1/obfuscate/new", {
    method: "POST",
    headers: {
      "Luraph-API-Key": apiKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      node,
      script: scriptBase64,
      fileName: "script.lua",
      options: {},
      enforceSettings: false,
    }),
  });

  if (!newJobRes.ok) {
    const errorBody = await newJobRes.text().catch(() => "");
    throw new Error(`Failed to create obfuscation job: ${newJobRes.status} ${newJobRes.statusText} ${errorBody}`);
  }
  const jobData = (await newJobRes.json()) as { jobId: string };
  const jobId = jobData.jobId;

  // 3. Wait for obfuscation job to complete
  const statusRes = await fetch(`https://api.lura.ph/v1/obfuscate/status/${jobId}`, {
    headers: {
      "Luraph-API-Key": apiKey,
    },
  });

  if (!statusRes.ok) {
    const errorBody = await statusRes.text().catch(() => "");
    throw new Error(`Obfuscation job status check failed: ${statusRes.status} ${statusRes.statusText} ${errorBody}`);
  }

  const statusText = await statusRes.text();
  if (statusText.trim()) {
    try {
      const statusJson = JSON.parse(statusText);
      if (statusJson.error || statusJson.errors) {
        throw new Error(statusJson.error || JSON.stringify(statusJson.errors));
      }
    } catch (e) {
      if (statusText.includes("error")) {
        throw new Error(`Obfuscation job error: ${statusText}`);
      }
    }
  }

  // 4. Download the obfuscated result
  const downloadRes = await fetch(`https://api.lura.ph/v1/obfuscate/download/${jobId}`, {
    headers: {
      "Luraph-API-Key": apiKey,
    },
  });

  if (!downloadRes.ok) {
    const errorBody = await downloadRes.text().catch(() => "");
    throw new Error(`Failed to download obfuscated script: ${downloadRes.status} ${downloadRes.statusText} ${errorBody}`);
  }

  return await downloadRes.text();
}

function getErrorGuiLua(errorMessage: string, keyUrl: string): string {
  return `
local player = game:GetService("Players").LocalPlayer
local errGui = Instance.new("ScreenGui")
errGui.Name = "HipHubError"
errGui.ResetOnSpawn = false
errGui.DisplayOrder = 2147483647

pcall(function()
    local oldErr = player:WaitForChild("PlayerGui"):FindFirstChild("HipHubError")
    if oldErr then oldErr:Destroy() end
end)

pcall(function()
    errGui.Parent = player:WaitForChild("PlayerGui")
    
    local TweenService = game:GetService("TweenService")
    
    -- Design tokens
    local COLORS = {
        glassSurface  = Color3.fromRGB(16, 20, 36),
        glassCard     = Color3.fromRGB(20, 24, 44),
        accentCyan    = Color3.fromRGB(0, 200, 255),
        accentViolet  = Color3.fromRGB(140, 120, 255),
        textPrimary   = Color3.fromRGB(225, 235, 255),
        textSecondary = Color3.fromRGB(140, 155, 185),
        borderGlass   = Color3.fromRGB(50, 65, 110),
    }

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 180)
    frame.Position = UDim2.new(0.5, -240, 0.5, -90)
    frame.BackgroundColor3 = COLORS.glassSurface
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = errGui
    
    local errCorner = Instance.new("UICorner")
    errCorner.CornerRadius = UDim.new(0, 12)
    errCorner.Parent = frame
    
    local errStroke = Instance.new("UIStroke")
    errStroke.Color = COLORS.borderGlass
    errStroke.Thickness = 1
    errStroke.Transparency = 0.55
    errStroke.Parent = frame
    
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = COLORS.glassCard
    topBar.BackgroundTransparency = 0.08
    topBar.BorderSizePixel = 0
    topBar.Parent = frame
    
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 12)
    topBarCorner.Parent = topBar
    
    local topBarStroke = Instance.new("UIStroke")
    topBarStroke.Color = COLORS.borderGlass
    topBarStroke.Thickness = 1
    topBarStroke.Transparency = 0.75
    topBarStroke.Parent = topBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "HIPHUB ACCESS DENIED"
    title.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red warning
    title.Font = Enum.Font.GothamBold
    title.TextSize = 10
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 28, 0, 28)
    closeButton.Position = UDim2.new(1, -34, 0.5, -14)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "✕"
    closeButton.TextColor3 = COLORS.textSecondary
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 12
    closeButton.Parent = topBar
    
    closeButton.MouseEnter:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
    end)
    closeButton.MouseLeave:Connect(function()
        TweenService:Create(closeButton, TweenInfo.new(0.15), {TextColor3 = COLORS.textSecondary}):Play()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        errGui:Destroy()
    end)
    
    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -32, 0, 60)
    body.Position = UDim2.new(0, 16, 0, 52)
    body.BackgroundTransparency = 1
    body.Text = ${JSON.stringify(errorMessage)}
    body.TextColor3 = COLORS.textPrimary
    body.Font = Enum.Font.Gotham
    body.TextSize = 11
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = frame

    local actionButton = Instance.new("TextButton")
    actionButton.Size = UDim2.new(1, -32, 0, 36)
    actionButton.Position = UDim2.new(0, 16, 1, -52)
    actionButton.BackgroundColor3 = COLORS.accentViolet
    actionButton.BackgroundTransparency = 0.15
    actionButton.BorderSizePixel = 0
    actionButton.Text = "GET KEY (CLICK TO COPY LINK)"
    actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionButton.Font = Enum.Font.GothamBold
    actionButton.TextSize = 10
    actionButton.Parent = frame

    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 6)
    actionCorner.Parent = actionButton
    
    local actionStroke = Instance.new("UIStroke")
    actionStroke.Color = COLORS.accentViolet
    actionStroke.Thickness = 1
    actionStroke.Transparency = 0.4
    actionStroke.Parent = actionButton

    actionButton.MouseEnter:Connect(function()
        TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
    end)
    actionButton.MouseLeave:Connect(function()
        TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
    end)

    actionButton.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard(${JSON.stringify(keyUrl)})
                actionButton.Text = "COPIED LINK TO CLIPBOARD!"
                task.wait(2)
                actionButton.Text = "GET KEY (CLICK TO COPY LINK)"
            else
                actionButton.Text = "YOUR EXECUTOR DOESN'T SUPPORT SETCLIPBOARD!"
            end
        end)
    end)
end)
`;
}

export async function GET(request: NextRequest) {
  try {
    const userAgent = request.headers.get("user-agent") || "";
    const isRoblox = userAgent.toLowerCase().includes("roblox");

    // Deny direct browser/curl access immediately if not originating from Roblox client/executors
    if (!isRoblox) {
      return new NextResponse(
        `error("HipHub Security: Access Denied.")`,
        {
          status: 403,
          headers: {
            "Content-Type": "text/plain",
            "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
          },
        }
      );
    }

    const { searchParams } = new URL(request.url);
    const key = searchParams.get("key");
    const hwid = searchParams.get("hwid");
    const gameId = searchParams.get("gameId");
    const placeId = searchParams.get("placeId");

    // Enforce lock on main script payload (Bypassed by default, uncomment and change to enable Place ID lock)
    /*
    if (key) {
      const TARGET_PLACE_ID = "YOUR_NEW_GAME_PLACE_ID";
      if (gameId !== TARGET_PLACE_ID && placeId !== TARGET_PLACE_ID) {
        const errScript = getErrorGuiLua(
          `Access Denied: This script is locked and can only be executed in game ${TARGET_PLACE_ID}.`,
          "https://hiphub.cloud/get-key"
        );
        return new NextResponse(errScript, {
          headers: {
            "Content-Type": "text/plain",
            "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
          },
        });
      }
    }
    */

    // Detect client IP address from proxy headers
    const forwarded = request.headers.get("x-forwarded-for");
    const _ip = forwarded ? forwarded.split(",")[0].trim() : "127.0.0.1";

    // If key is missing, handle based on User-Agent
    if (!key) {
      const host = request.headers.get("host") || "hiphub.cloud";
      const proto = host.includes("localhost") ? "http" : "https";
      const baseUrl = `${proto}://${host}`;

      const userAgent = request.headers.get("user-agent") || "";
      const isRoblox = userAgent.toLowerCase().includes("roblox");

      if (isRoblox) {
        // Serve the client-side loader bootstrapper script to Roblox executors
        const loaderScript = `-- HipHub Loader Bootstrapper
repeat task.wait() until game:IsLoaded()

-- Optional game checks (Uncomment to enable)
-- if game.PlaceId ~= YOUR_PLACE_ID and game.GameId ~= YOUR_PLACE_ID then
--     print("not support")
--     return
-- end

local player = game:GetService("Players").LocalPlayer
while not player do
    task.wait(0.5)
    player = game:GetService("Players").LocalPlayer
end

local gui = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub")
if gui then
    return
end

local key = _G.hiphub_key or hiphub_key
if not key and isfile and readfile then
    if isfile("HipHub/key.txt") then
        local saved = readfile("HipHub/key.txt")
        if saved and saved ~= "" then
            key = saved:gsub("%s+", "")
        end
    elseif isfile("hiphub_key.txt") then
        local saved = readfile("hiphub_key.txt")
        if saved and saved ~= "" then
            key = saved:gsub("%s+", "")
        end
    end
end

local function showLocalError(errorMessage)
    local player = game:GetService("Players").LocalPlayer
    local errGui = Instance.new("ScreenGui")
    errGui.Name = "HipHubError"
    errGui.ResetOnSpawn = false
    errGui.DisplayOrder = 2147483647
    
    pcall(function()
        local oldErr = player:WaitForChild("PlayerGui"):FindFirstChild("HipHubError")
        if oldErr then oldErr:Destroy() end
    end)
    
    pcall(function()
        errGui.Parent = player:WaitForChild("PlayerGui")
        
        local TweenService = game:GetService("TweenService")
        
        -- Design tokens
        local COLORS = {
            glassSurface  = Color3.fromRGB(16, 20, 36),
            glassCard     = Color3.fromRGB(20, 24, 44),
            accentCyan    = Color3.fromRGB(0, 200, 255),
            accentViolet  = Color3.fromRGB(140, 120, 255),
            textPrimary   = Color3.fromRGB(225, 235, 255),
            textSecondary = Color3.fromRGB(140, 155, 185),
            borderGlass   = Color3.fromRGB(50, 65, 110),
        }

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 480, 0, 180)
        frame.Position = UDim2.new(0.5, -240, 0.5, -90)
        frame.BackgroundColor3 = COLORS.glassSurface
        frame.BackgroundTransparency = 0.05
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        frame.Parent = errGui
        
        local errCorner = Instance.new("UICorner")
        errCorner.CornerRadius = UDim.new(0, 12)
        errCorner.Parent = frame
        
        local errStroke = Instance.new("UIStroke")
        errStroke.Color = COLORS.borderGlass
        errStroke.Thickness = 1
        errStroke.Transparency = 0.55
        errStroke.Parent = frame
        
        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 38)
        topBar.BackgroundColor3 = COLORS.glassCard
        topBar.BackgroundTransparency = 0.08
        topBar.BorderSizePixel = 0
        topBar.Parent = frame
        
        local topBarCorner = Instance.new("UICorner")
        topBarCorner.CornerRadius = UDim.new(0, 12)
        topBarCorner.Parent = topBar
        
        local topBarStroke = Instance.new("UIStroke")
        topBarStroke.Color = COLORS.borderGlass
        topBarStroke.Thickness = 1
        topBarStroke.Transparency = 0.75
        topBarStroke.Parent = topBar

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 1, 0)
        title.Position = UDim2.new(0, 16, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "HIPHUB ACCESS DENIED"
        title.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red warning
        title.Font = Enum.Font.GothamBold
        title.TextSize = 10
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = topBar

        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 28, 0, 28)
        closeButton.Position = UDim2.new(1, -34, 0.5, -14)
        closeButton.BackgroundTransparency = 1
        closeButton.Text = "✕"
        closeButton.TextColor3 = COLORS.textSecondary
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextSize = 12
        closeButton.Parent = topBar
        
        closeButton.MouseEnter:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
        end)
        closeButton.MouseLeave:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.15), {TextColor3 = COLORS.textSecondary}):Play()
        end)
        
        closeButton.MouseButton1Click:Connect(function()
            errGui:Destroy()
        end)
        
        local body = Instance.new("TextLabel")
        body.Size = UDim2.new(1, -32, 0, 60)
        body.Position = UDim2.new(0, 16, 0, 52)
        body.BackgroundTransparency = 1
        body.Text = errorMessage
        body.TextColor3 = COLORS.textPrimary
        body.Font = Enum.Font.Gotham
        body.TextSize = 11
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Parent = frame

        local actionButton = Instance.new("TextButton")
        actionButton.Size = UDim2.new(1, -32, 0, 36)
        actionButton.Position = UDim2.new(0, 16, 1, -52)
        actionButton.BackgroundColor3 = COLORS.accentViolet
        actionButton.BackgroundTransparency = 0.15
        actionButton.BorderSizePixel = 0
        actionButton.Text = "GET A FREE 10 MIN KEY (CLICK TO COPY LINK)"
        actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionButton.Font = Enum.Font.GothamBold
        actionButton.TextSize = 10
        actionButton.Parent = frame

        local actionCorner = Instance.new("UICorner")
        actionCorner.CornerRadius = UDim.new(0, 6)
        actionCorner.Parent = actionButton
        
        local actionStroke = Instance.new("UIStroke")
        actionStroke.Color = COLORS.accentViolet
        actionStroke.Thickness = 1
        actionStroke.Transparency = 0.4
        actionStroke.Parent = actionButton

        actionButton.MouseEnter:Connect(function()
            TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
        end)
        actionButton.MouseLeave:Connect(function()
            TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.15}):Play()
        end)

        actionButton.MouseButton1Click:Connect(function()
            pcall(function()
                if setclipboard then
                    setclipboard("${baseUrl}/get-key")
                    actionButton.Text = "COPIED LINK TO CLIPBOARD!"
                    task.wait(2)
                    actionButton.Text = "GET A FREE 10 MIN KEY (CLICK TO COPY LINK)"
                else
                    actionButton.Text = "YOUR EXECUTOR DOESN'T SUPPORT SETCLIPBOARD!"
                end
            end)
        end)
    end)
end

if not key then
    showLocalError("Access Denied. Please set _G.hiphub_key before executing! Retrieve a free 10 min key at ${baseUrl}/get-key")
    return
end

_G.hiphub_key = key
if getgenv then getgenv().hiphub_key = key end

local hwid = "unknown"
local playername = "unknown"
pcall(function()
    hwid = (gethwid and gethwid()) or game:GetService("RbxAnalyticsService"):GetClientId() or "unknown"
    playername = game:GetService("Players").LocalPlayer.Name or "unknown"
end)

local url = "${baseUrl}/api/script-roblox/cab?key=" .. tostring(key) .. "&hwid=" .. game:GetService("HttpService"):UrlEncode(tostring(hwid)) .. "&username=" .. game:GetService("HttpService"):UrlEncode(tostring(playername)) .. "&gameId=" .. tostring(game.GameId) .. "&placeId=" .. tostring(game.PlaceId)
local success, content
for i = 1, 3 do
    success, content = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        break
    end
    if i < 3 then
        task.wait(1.5)
    end
end

if not success then
    showLocalError("Execute error: network latency. Please check your connection and try again!")
    return
end

local func, err = loadstring(content)
if not func then
    showLocalError("Execute error: script initialization failure. Please try again!")
    return
end

func()
`;

        return new NextResponse(loaderScript, {
          headers: {
            "Content-Type": "text/plain",
            "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
          },
        });
      } else {
        // Deny direct browser/curl access
        return new NextResponse(
          `error("HipHub Error: Access Denied. Please use the loader bootstrapper with a valid key! Retrieve a key at ${baseUrl}/get-key")`,
          {
            headers: {
              "Content-Type": "text/plain",
              "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
            },
          }
        );
      }
    }

    // Query database for key record
    const selectQuery = "SELECT * FROM keys WHERE key = $1 LIMIT 1;";
    const res = await pool.query(selectQuery, [key.trim()]);

    if (res.rows.length === 0) {
      const errScript = getErrorGuiLua(
        "Invalid Key. Key not found. Retrieve a free key at https://hiphub.cloud/get-key",
        "https://hiphub.cloud/get-key"
      );
      return new NextResponse(errScript, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    const keyRecord = res.rows[0];
    const keyRole = keyRecord.role || "free";

    // Persist client HWID if provided
    if (hwid) {
      try {
        let hwidsList: string[] = [];
        if (keyRecord.hwids) {
          if (Array.isArray(keyRecord.hwids)) {
            hwidsList = keyRecord.hwids;
          } else if (typeof keyRecord.hwids === "string") {
            try {
              hwidsList = JSON.parse(keyRecord.hwids);
            } catch (e) {
              hwidsList = [];
            }
          }
        }

        const cleanHwid = hwid.trim().toLowerCase();
        const includesHwid = hwidsList.some(h => typeof h === "string" && h.trim().toLowerCase() === cleanHwid);

        // HWID limits per role (fallback if max_hwid is not set in DB)
        const hwidLimits: Record<string, number> = {
          free: 1,
          premium: 5,
        };
        const maxHwids = (keyRecord.max_hwid !== null && keyRecord.max_hwid !== undefined)
          ? keyRecord.max_hwid
          : (hwidLimits[keyRole] ?? 1);

        // If the user has reached their HWID limit and the incoming HWID is new, block execution
        if (hwidsList.length >= maxHwids && !includesHwid) {
          const msg =
            keyRecord.max_hwid !== null && keyRecord.max_hwid !== undefined
              ? `HWID is max. This key is locked to ${maxHwids} device${maxHwids === 1 ? "" : "s"}.`
              : keyRole === "free"
              ? "HWID is max. Free keys are locked to 1 device. Please get a new key or upgrade to Premium."
              : `HWID is max. Premium keys are locked to ${maxHwids} devices. Please contact support to reset your HWIDs.`;
          const errScript = getErrorGuiLua(msg, "https://hiphub.cloud/get-key");
          return new NextResponse(errScript, {
            headers: {
              "Content-Type": "text/plain",
              "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
            },
          });
        }

        // Add the HWID if it's not already in the list
        if (!includesHwid) {
          hwidsList.push(hwid.trim());
          const updateHwidQuery = "UPDATE keys SET hwids = $1 WHERE id = $2;";
          await pool.query(updateHwidQuery, [JSON.stringify(hwidsList), keyRecord.id]);
        }
      } catch (err) {
        console.error("Error updating key HWID list in DB:", err);
      }
    }

    // Persist client username if provided
    const usernameParam = searchParams.get("username");
    if (usernameParam) {
      try {
        let usernamesList: string[] = [];
        if (keyRecord.usernames) {
          if (Array.isArray(keyRecord.usernames)) {
            usernamesList = keyRecord.usernames;
          } else if (typeof keyRecord.usernames === "string") {
            try {
              usernamesList = JSON.parse(keyRecord.usernames);
            } catch (e) {
              usernamesList = [];
            }
          }
        }

        const cleanUser = usernameParam.trim();
        const includesUser = usernamesList.some(
          u => typeof u === "string" && u.trim().toLowerCase() === cleanUser.toLowerCase()
        );

        if (!includesUser) {
          usernamesList.push(cleanUser);
          const updateUsersQuery = "UPDATE keys SET usernames = $1 WHERE id = $2;";
          await pool.query(updateUsersQuery, [JSON.stringify(usernamesList), keyRecord.id]);
        }
      } catch (err) {
        console.error("Error updating key usernames list in DB:", err);
      }
    }

    const now = new Date();
    const expiresAt = new Date(keyRecord.expires_at);

    // 1. Expiration check
    if (now > expiresAt) {
      const errScript = getErrorGuiLua(
        "Key Expired. Free keys are only valid for 10 minutes. Retrieve a new key at https://hiphub.cloud/get-key",
        "https://hiphub.cloud/get-key"
      );
      return new NextResponse(errScript, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    // Read the Roblox script files and serve them concatenated
    const uiPath = path.join(process.cwd(), "app/api/script-roblox/cab/ui.lua");
    const settingsPath = path.join(process.cwd(), "app/api/script-roblox/cab/settings.lua");
    const mainPath = path.join(process.cwd(), "app/api/script-roblox/cab/main.lua");

    if (!fs.existsSync(uiPath)) {
      const errScript = getErrorGuiLua(
        "Execute error: failed to load script resources. Please try again later!",
        "https://hiphub.cloud/get-key"
      );
      return new NextResponse(errScript, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    const userRole = keyRecord.role || "free";
    const host = request.headers.get("host") || "hiphub.cloud";
    const proto = host.includes("localhost") ? "http" : "https";
    const baseUrl = `${proto}://${host}`;
    let luaScript = `_G.hiphub_key = "${key.trim()}"\n_G.hiphub_role = "${userRole}"\n_G.hiphub_url = "${baseUrl}"\nif getgenv then getgenv().hiphub_key = "${key.trim()}" end\nif getgenv then getgenv().hiphub_role = "${userRole}" end\nif getgenv then getgenv().hiphub_url = "${baseUrl}" end\n`;
    
    luaScript += fs.readFileSync(uiPath, "utf8");

    if (fs.existsSync(settingsPath)) {
      luaScript += "\n" + fs.readFileSync(settingsPath, "utf8");
    }

    if (fs.existsSync(mainPath)) {
      luaScript += "\n" + fs.readFileSync(mainPath, "utf8");
    }

    // Cache lookup by script hash
    const sourceHash = crypto.createHash("sha256").update(luaScript).digest("hex");

    // 1. Try serving from memory cache
    if (globalCache && globalCache.sourceHash === sourceHash) {
      return new NextResponse(globalCache.obfuscatedCode, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    // 2. Try serving from database cache
    try {
      const cacheRes = await pool.query(
        "SELECT obfuscated_code FROM script_cache WHERE source_hash = $1 LIMIT 1;",
        [sourceHash]
      );
      if (cacheRes.rows.length > 0) {
        const cachedCode = cacheRes.rows[0].obfuscated_code;
        globalCache = { sourceHash, obfuscatedCode: cachedCode };
        return new NextResponse(cachedCode, {
          headers: {
            "Content-Type": "text/plain",
            "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
          },
        });
      }
    } catch (dbCacheErr) {
      console.warn("Database cache lookup failed:", dbCacheErr);
    }

    // 3. Cache miss: Obfuscate Lua script (using Luraph or local XOR fallback)
    let finalScript: string;
    const disableLuraph = process.env.DISABLE_LURAPH === "true";

    if (disableLuraph) {
      console.log("Luraph is disabled via env config, using local XOR obfuscation");
      finalScript = obfuscateLuaXor(luaScript, key.trim());
      try {
        await pool.query(
          `INSERT INTO script_cache (source_hash, obfuscated_code) 
           VALUES ($1, $2) 
           ON CONFLICT (source_hash) 
           DO UPDATE SET obfuscated_code = EXCLUDED.obfuscated_code;`,
          [sourceHash, finalScript]
        );
        globalCache = { sourceHash, obfuscatedCode: finalScript };
      } catch (dbSaveErr) {
        console.error("Failed to save local XOR script to database cache:", dbSaveErr);
      }
    } else {
      try {
        finalScript = await obfuscateLua(luaScript);
        try {
          await pool.query(
            `INSERT INTO script_cache (source_hash, obfuscated_code) 
             VALUES ($1, $2) 
             ON CONFLICT (source_hash) 
             DO UPDATE SET obfuscated_code = EXCLUDED.obfuscated_code;`,
            [sourceHash, finalScript]
          );
          globalCache = { sourceHash, obfuscatedCode: finalScript };
        } catch (dbSaveErr) {
          console.error("Failed to save script to database cache:", dbSaveErr);
        }
      } catch (luraphErr) {
        console.error("Luraph obfuscation failed, falling back to local XOR:", luraphErr);
        finalScript = obfuscateLuaXor(luaScript, key.trim());
        try {
          await pool.query(
            `INSERT INTO script_cache (source_hash, obfuscated_code) 
             VALUES ($1, $2) 
             ON CONFLICT (source_hash) 
             DO UPDATE SET obfuscated_code = EXCLUDED.obfuscated_code;`,
            [sourceHash, finalScript]
          );
          globalCache = { sourceHash, obfuscatedCode: finalScript };
        } catch (dbSaveErr) {
          console.error("Failed to save fallback script to database cache:", dbSaveErr);
        }
      }
    }

    return new NextResponse(finalScript, {
      headers: {
        "Content-Type": "text/plain",
        "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      },
    });
  } catch (error: unknown) {
    const err = error as Error;
    console.error("Roblox script delivery API error:", err);
    const errScript = getErrorGuiLua(
      "Execute error: server delivery failure. Please try again later!",
      "https://hiphub.cloud/get-key"
    );
    return new NextResponse(errScript, {
      headers: {
        "Content-Type": "text/plain",
        "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      },
    });
  }
}

export async function POST(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const key = searchParams.get("key") || "";

    const userAgent = (request.headers.get("user-agent") || "").toLowerCase();
    const isRoblox =
      userAgent.includes("roblox") ||
      userAgent.includes("okhttp") ||
      userAgent.includes("delta") ||
      userAgent.includes("codex") ||
      userAgent.includes("hydrogen") ||
      userAgent.includes("arceus") ||
      userAgent.includes("vega") ||
      userAgent.includes("dalvik") ||
      userAgent.includes("darwin") ||
      userAgent.includes("executor") ||
      userAgent.includes("postman") ||
      userAgent.includes("insomnia") ||
      userAgent.includes("curl") ||
      userAgent.includes("python-requests");

    if (!isRoblox) {
      return NextResponse.json({ error: "Access Denied" }, { status: 403 });
    }

    // Verify key
    const selectQuery = "SELECT id FROM keys WHERE key = $1 LIMIT 1;";
    const res = await pool.query(selectQuery, [key.trim()]);
    if (res.rows.length === 0) {
      return NextResponse.json({ error: "Invalid Key" }, { status: 401 });
    }

    // Template for new game actions
    const body = await request.json();
    const { action } = body;

    // Example handler:
    if (action === "ping") {
      return NextResponse.json({ success: true, message: "pong" });
    }

    return NextResponse.json({ error: "Invalid action" }, { status: 400 });
  } catch (error: unknown) {
    console.error("Roblox script API POST error:", error);
    return NextResponse.json({ error: "Server Error" }, { status: 500 });
  }
}
