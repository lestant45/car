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

function obfuscateLuaXor(code: string, licenseKey = "KEYLESS"): string {
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

local function findGuiInParents(name)
    if gethui then
        local g = gethui():FindFirstChild(name)
        if g then return g end
    end
    local c = game:GetService("CoreGui"):FindFirstChild(name)
    if c then return c end
    local p = player:WaitForChild("PlayerGui"):FindFirstChild(name)
    if p then return p end
    return nil
end

pcall(function()
    local oldErr = findGuiInParents("HipHubError")
    if oldErr then oldErr:Destroy() end
end)

pcall(function()
    local parentGui
    if gethui then
        parentGui = gethui()
    else
        local coreGui = game:GetService("CoreGui")
        local successCore, _ = pcall(function()
            local test = Instance.new("Folder")
            test.Parent = coreGui
            test:Destroy()
        end)
        if successCore then
            parentGui = coreGui
        else
            parentGui = player:WaitForChild("PlayerGui")
        end
    end
    errGui.Parent = parentGui
    
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
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "HIPHUB ERROR"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
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
end)
`;
}

export async function GET(request: NextRequest) {
  try {
    const userAgent = (request.headers.get("user-agent") || "").toLowerCase();
    const isRoblox = userAgent.includes("roblox") && 
                     !userAgent.includes("curl") && 
                     !userAgent.includes("postman") && 
                     !userAgent.includes("insomnia") && 
                     !userAgent.includes("python") && 
                     !userAgent.includes("wget") && 
                     !userAgent.includes("axios");

    // Detect browser headers to block direct browser access even if User-Agent is spoofed
    const isBrowser = request.headers.has("sec-ch-ua") || 
                      request.headers.has("sec-fetch-mode") || 
                      (request.headers.get("accept") || "").includes("text/html");

    // Deny direct browser/curl access immediately if not originating from Roblox client/executors
    if (!isRoblox || isBrowser) {
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
    const isPayload = searchParams.get("payload") === "true";
    const gameId = searchParams.get("gameId");
    const placeId = searchParams.get("placeId");

    const host = request.headers.get("host") || "hiphub.cloud";
    const proto = host.includes("localhost") ? "http" : "https";
    const baseUrl = `${proto}://${host}`;

    // Place ID check
    const allowedPlaceIds = ["14005966837", "130760175971028", "140063367098641", "2640407187"];
    if ((gameId || placeId) && !allowedPlaceIds.includes(String(gameId)) && !allowedPlaceIds.includes(String(placeId))) {
      const errScript = getErrorGuiLua(
        "Access Denied: This script is locked and can only be executed in authorized games.",
        "https://hiphub.cloud/"
      );
      return new NextResponse(errScript, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    // Serve loader bootstrapper script if payload is not requested yet
    if (!isPayload) {
      const loaderScript = `-- HipHub Keyless Loader Bootstrapper
repeat task.wait() until game:IsLoaded()

local allowedPlaceIds = {
    [14005966837] = true,
    [130760175971028] = true,
    [140063367098641] = true,
    [2640407187] = true,
    [4878566378] = true,
}

if not allowedPlaceIds[game.PlaceId] and not allowedPlaceIds[game.GameId] then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "HipHub",
            Text = "Game not supported!",
            Duration = 5
        })
    end)
    print("HipHub: Game not supported!")
    return
end

local player = game:GetService("Players").LocalPlayer
while not player do
    task.wait(0.5)
    player = game:GetService("Players").LocalPlayer
end

local function findGuiInParents(name)
    if gethui then
        local g = gethui():FindFirstChild(name)
        if g then return g end
    end
    local c = game:GetService("CoreGui"):FindFirstChild(name)
    if c then return c end
    local p = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
    if p and p:FindFirstChild(name) then return p[name] end
    return nil
end

local oldGui = findGuiInParents("HipHub") or findGuiInParents("HipHub_CDID")
if oldGui then
    pcall(function() oldGui:Destroy() end)
end

local hwid = "unknown"
local playername = "unknown"
local executor = "unknown"
pcall(function()
    hwid = (gethwid and gethwid()) or game:GetService("RbxAnalyticsService"):GetClientId() or "unknown"
    playername = game:GetService("Players").LocalPlayer.Name or "unknown"
    local execName = identifyexecutor or getexecutorname
    if execName then
        executor = execName()
    end
end)

local encodedExecutor = "unknown"
pcall(function()
    encodedExecutor = game:GetService("HttpService"):UrlEncode(executor)
end)

local url = "${baseUrl}/api/script-roblox/cardrive?payload=true&hwid=" .. tostring(hwid) .. "&username=" .. tostring(playername) .. "&gameId=" .. tostring(game.GameId) .. "&placeId=" .. tostring(game.PlaceId) .. "&executor=" .. tostring(encodedExecutor) .. "&cb=" .. tostring(math.random(100000, 999999))
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

local function showLocalError(errorMessage)
    local player = game:GetService("Players").LocalPlayer
    local errGui = Instance.new("ScreenGui")
    errGui.Name = "HipHubError"
    errGui.ResetOnSpawn = false
    errGui.DisplayOrder = 2147483647
    
    pcall(function()
        local oldErr = findGuiInParents("HipHubError")
        if oldErr then oldErr:Destroy() end
    end)
    
    pcall(function()
        local parentGui
        if gethui then
            parentGui = gethui()
        else
            local coreGui = game:GetService("CoreGui")
            local successCore, _ = pcall(function()
                local test = Instance.new("Folder")
                test.Parent = coreGui
                test:Destroy()
            end)
            if successCore then
                parentGui = coreGui
            else
                parentGui = player:WaitForChild("PlayerGui")
            end
        end
        errGui.Parent = parentGui
        
        local TweenService = game:GetService("TweenService")
        
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
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 1, 0)
        title.Position = UDim2.new(0, 16, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "HIPHUB ERROR"
        title.TextColor3 = Color3.fromRGB(255, 100, 100)
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
    end)
end

if not success then
    showLocalError("Execute error: network latency. Please check your connection and try again!")
    return
end

local func, err = loadstring(content)
if not func then
    local errStr = tostring(err)
    warn("HipHub Loader Error: " .. errStr)
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
    }

    // Serving main script payload (Keyless)
    const scriptDir = path.join(process.cwd(), "app/api/script-roblox/cardrive");
    const uiPath = path.join(scriptDir, "ui.lua");
    const settingsPath = path.join(scriptDir, "settings.lua");
    const teleportPath = path.join(scriptDir, "teleport.lua");
    const visualsPath = path.join(scriptDir, "visuals.lua");
    const vehiclePath = path.join(scriptDir, "vehicle.lua");
    const farmPath = path.join(scriptDir, "farm.lua");
    const mainPath = path.join(scriptDir, "main.lua");

    if (!fs.existsSync(uiPath)) {
      const errScript = getErrorGuiLua(
        "Execute error: failed to load script resources. Please try again later!",
        "https://hiphub.cloud/"
      );
      return new NextResponse(errScript, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    const userRole = "free";
    let luaScript = `_G.hiphub_key = "KEYLESS"\n_G.hiphub_role = "${userRole}"\n_G.hiphub_url = "${baseUrl}"\nif getgenv then getgenv().hiphub_key = "KEYLESS" end\nif getgenv then getgenv().hiphub_role = "${userRole}" end\nif getgenv then getgenv().hiphub_url = "${baseUrl}" end\n`;
    luaScript += fs.readFileSync(uiPath, "utf8");

    if (fs.existsSync(settingsPath)) luaScript += "\n" + fs.readFileSync(settingsPath, "utf8");
    if (fs.existsSync(teleportPath)) luaScript += "\n" + fs.readFileSync(teleportPath, "utf8");
    if (fs.existsSync(visualsPath)) luaScript += "\n" + fs.readFileSync(visualsPath, "utf8");
    if (fs.existsSync(vehiclePath)) luaScript += "\n" + fs.readFileSync(vehiclePath, "utf8");
    if (fs.existsSync(farmPath)) luaScript += "\n" + fs.readFileSync(farmPath, "utf8");
    if (fs.existsSync(mainPath)) luaScript += "\n" + fs.readFileSync(mainPath, "utf8");

    const executor = (searchParams.get("executor") || "").toLowerCase();
    const isArceus = executor.includes("arceus");

    if (isArceus) {
      return new NextResponse(luaScript, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    const disableLuraph = process.env.DISABLE_LURAPH === "true" || isArceus;
    const obfuscationType = disableLuraph ? "xor" : "luraph";

    const sourceHash = crypto.createHash("sha256").update(luaScript + "_" + obfuscationType).digest("hex");

    if (globalCache && globalCache.sourceHash === sourceHash) {
      return new NextResponse(globalCache.obfuscatedCode, {
        headers: {
          "Content-Type": "text/plain",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

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

    let finalScript: string;
    if (disableLuraph) {
      finalScript = obfuscateLuaXor(luaScript, "KEYLESS");
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
        finalScript = obfuscateLuaXor(luaScript, "KEYLESS");
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
      "https://hiphub.cloud/"
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

    // Parse body
    const body = await request.json();
    const { action, placeId } = body;

    // Enforce place ID check for game-specific backend operations
    const allowedPlaceIds = [
      "14005966837", "130760175971028", "140063367098641", "2640407187"
    ];
    if (placeId && !allowedPlaceIds.includes(String(placeId))) {
      return NextResponse.json({ error: "Access Denied: Invalid Place ID" }, { status: 403 });
    }

    if (action === "ping") {
      return NextResponse.json({ success: true, message: "pong" });
    }

    return NextResponse.json({ error: "Invalid action" }, { status: 400 });
  } catch (error: unknown) {
    console.error("Roblox script API POST error:", error);
    return NextResponse.json({ error: "Server Error" }, { status: 500 });
  }
}
