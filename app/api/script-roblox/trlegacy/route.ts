import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import crypto from "crypto";
import pool from "../../../../lib/db";

// In-memory cache for warm serverless instances
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
  let clean = code.replace(/--\[\[[\s\S]*?\]\]/g, "");
  clean = clean
    .split("\n")
    .map((line) => {
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
    })
    .join("\n");
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
    .replace(/\\(\d{1,3})/g, (_, p1) => {
      return String.fromCharCode(parseInt(p1, 10));
    })
    .replace(/\\x([0-9a-fA-F]{2})/g, (_, p1) => {
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
  const encryptedStrings = strings.map((s) => {
    const bytes: number[] = [];
    const buf = Buffer.from(s, "utf8");
    for (let i = 0; i < buf.length; i++) {
      bytes.push(buf[i] ^ key);
    }
    return bytes.join(",");
  });

  return `
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
}

function obfuscateLuaXor(code: string, licenseKey: string = "KEYLESS"): string {
  const clean = stripComments(code);

  let seed = 5381;
  for (let i = 0; i < licenseKey.length; i++) {
    seed = (seed * 33 + licenseKey.charCodeAt(i)) % 2147483647;
  }
  if (seed === 0) seed = 123456789;

  let hexString = "";
  const buf = Buffer.from(clean, "utf8");
  let currentSeed = seed;

  for (let i = 0; i < buf.length; i++) {
    currentSeed = (currentSeed * 48271) % 2147483647;
    const keyByte = currentSeed % 256;
    const encryptedByte = buf[i] ^ keyByte;
    hexString += encryptedByte.toString(16).padStart(2, "0");
  }

  const varSeed = makeId(8);
  const varPayload = makeId(8);
  const varChunks = makeId(8);
  const varBuf = makeId(8);
  const varBufLen = makeId(8);
  const varXor = makeId(8);
  const varMap = makeId(8);
  const varIdx = makeId(8);
  const varH1 = makeId(8);
  const varH2 = makeId(8);
  const varVal = makeId(8);
  const varKeyByte = makeId(8);
  const varFunc = makeId(8);
  const varErr = makeId(8);

  return `
local ${varSeed} = ${seed}
local ${varPayload} = "${hexString}"
local ${varChunks} = {}
local ${varBuf} = {}
local ${varBufLen} = 0
local ${varXor} = (bit32 and bit32.bxor) or (bit and bit.bxor) or function(a, b)
    local r = 0
    for i = 0, 7 do
        local bA = math.floor(a / (2 ^ i)) % 2
        local bB = math.floor(b / (2 ^ i)) % 2
        if bA ~= bB then r = r + 2 ^ i end
    end
    return r
end

local ${varMap} = {
    ["0"]=0,["1"]=1,["2"]=2,["3"]=3,["4"]=4,["5"]=5,["6"]=6,["7"]=7,
    ["8"]=8,["9"]=9,["a"]=10,["b"]=11,["c"]=12,["d"]=13,["e"]=14,["f"]=15,
    ["A"]=10,["B"]=11,["C"]=12,["D"]=13,["E"]=14,["F"]=15
}

for ${varIdx} = 1, #${varPayload}, 2 do
    local ${varH1} = ${varMap}[string.sub(${varPayload}, ${varIdx}, ${varIdx})] or 0
    local ${varH2} = ${varMap}[string.sub(${varPayload}, ${varIdx} + 1, ${varIdx} + 1)] or 0
    local ${varVal} = ${varH1} * 16 + ${varH2}
    ${varSeed} = (${varSeed} * 48271) % 2147483647
    local ${varKeyByte} = ${varSeed} % 256
    ${varBufLen} = ${varBufLen} + 1
    ${varBuf}[${varBufLen}] = string.char(${varXor}(${varVal}, ${varKeyByte}))
    if ${varBufLen} >= 4096 then
        table.insert(${varChunks}, table.concat(${varBuf}))
        ${varBuf} = {}
        ${varBufLen} = 0
    end
end
if ${varBufLen} > 0 then
    table.insert(${varChunks}, table.concat(${varBuf}))
end

local ${varFunc}, ${varErr} = loadstring(table.concat(${varChunks}))
if not ${varFunc} then
    error("HipHub Boot Error: Payload decode failed: " .. tostring(${varErr}))
end
${varFunc}()
`;
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
    local parentGui = (gethui and gethui()) or (syn and syn.protect_gui and game:GetService("CoreGui")) or player:WaitForChild("PlayerGui")
    if syn and syn.protect_gui and parentGui == game:GetService("CoreGui") then
        pcall(function() syn.protect_gui(errGui) end)
    end
    errGui.Parent = parentGui
    
    local COLORS = {
        glassSurface  = Color3.fromRGB(16, 20, 36),
        glassCard     = Color3.fromRGB(20, 24, 44),
        borderGlass   = Color3.fromRGB(50, 65, 110),
        textPrimary   = Color3.fromRGB(225, 235, 255),
        textSecondary = Color3.fromRGB(140, 155, 185),
    }

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 480, 0, 180)
    frame.Position = UDim2.new(0.5, -240, 0.5, -90)
    frame.BackgroundColor3 = COLORS.glassSurface
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = errGui
    
    local errCorner = Instance.new("UICorner")
    errCorner.CornerRadius = UDim.new(0, 12)
    errCorner.Parent = frame
    
    local errStroke = Instance.new("UIStroke")
    errStroke.Color = COLORS.borderGlass
    errStroke.Thickness = 1
    errStroke.Parent = frame
    
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = COLORS.glassCard
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
    body.Parent = frame
end)
`;
}

export async function GET(request: NextRequest) {
  try {
    const userAgent = (request.headers.get("user-agent") || "").toLowerCase();
    const isRoblox =
      userAgent.includes("roblox") ||
      userAgent.includes("okhttp") ||
      userAgent.includes("delta") ||
      userAgent.includes("codex") ||
      userAgent.includes("hydrogen") ||
      userAgent.includes("arceus") ||
      userAgent.includes("potassium") ||
      userAgent.includes("wave") ||
      userAgent.includes("fluxus") ||
      userAgent.includes("synapse") ||
      userAgent.includes("curl") ||
      userAgent.includes("python");

    const isBrowser =
      request.headers.has("sec-ch-ua") ||
      request.headers.has("sec-fetch-mode") ||
      (request.headers.get("accept") || "").includes("text/html");

    if (!isRoblox && isBrowser) {
      return new NextResponse(`error("HipHub Security: Access Denied.")`, {
        status: 403,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    const { searchParams } = new URL(request.url);
    const mode = searchParams.get("mode");
    const isLoader = mode === "loader" || searchParams.get("loader") === "true";
    const raw = searchParams.get("raw") === "true";

    const host = request.headers.get("host") || "hiphub.cloud";
    const proto = host.includes("localhost") ? "http" : "https";
    const baseUrl = `${proto}://${host}`;

    // Mode loader requested
    if (isLoader) {
      const loaderScript = `-- HipHub TR Legacy Keyless Loader
repeat task.wait() until game:IsLoaded()

local allowedPlaceIds = {
    [127089247654125] = true,
}

if not allowedPlaceIds[game.PlaceId] and not allowedPlaceIds[game.GameId] then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "HipHub TR Legacy",
            Text = "This game is not supported by TR Legacy script.",
            Duration = 5
        })
    end)
    return
end

local content = nil
local success = false

for i = 1, 3 do
    local s, res = pcall(function()
        return game:HttpGet("${baseUrl}/api/script-roblox/trlegacy")
    end)
    if s and type(res) == "string" and #res > 50 then
        content = res
        success = true
        break
    end
    if i < 3 then
        task.wait(1.5)
    end
end

if not success or not content then
    warn("[HipHub TR Legacy] Network error fetching script payload.")
    return
end

local func, err = loadstring(content)
if not func then
    warn("[HipHub TR Legacy] Script compilation failure: " .. tostring(err))
    return
end

func()
`;

      return new NextResponse(loaderScript, {
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    // Assemble and bundle all module files
    const scriptDir = path.join(process.cwd(), "app/api/script-roblox/trlegacy");
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
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    const userRole = "free";
    let luaScript = `-- [HipHub TR Legacy] Full Auto Race & Auto Drive Suite\n_G.hiphub_key = "KEYLESS"\n_G.hiphub_role = "${userRole}"\n_G.hiphub_url = "${baseUrl}"\nif getgenv then getgenv().hiphub_key = "KEYLESS" end\nif getgenv then getgenv().hiphub_role = "${userRole}" end\nif getgenv then getgenv().hiphub_url = "${baseUrl}" end\n`;
    luaScript += fs.readFileSync(uiPath, "utf8");

    if (fs.existsSync(settingsPath)) luaScript += "\n" + fs.readFileSync(settingsPath, "utf8");
    if (fs.existsSync(teleportPath)) luaScript += "\n" + fs.readFileSync(teleportPath, "utf8");
    if (fs.existsSync(visualsPath)) luaScript += "\n" + fs.readFileSync(visualsPath, "utf8");
    if (fs.existsSync(vehiclePath)) luaScript += "\n" + fs.readFileSync(vehiclePath, "utf8");
    if (fs.existsSync(farmPath)) luaScript += "\n" + fs.readFileSync(farmPath, "utf8");
    if (fs.existsSync(mainPath)) luaScript += "\n" + fs.readFileSync(mainPath, "utf8");

    if (raw) {
      return new NextResponse(luaScript, {
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    const sourceHash = crypto.createHash("sha256").update(luaScript + "_v2_clean").digest("hex");

    if (globalCache && globalCache.sourceHash === sourceHash) {
      return new NextResponse(globalCache.obfuscatedCode, {
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
        },
      });
    }

    let finalScript = luaScript;
    globalCache = { sourceHash, obfuscatedCode: finalScript };

    return new NextResponse(finalScript, {
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      },
    });
  } catch (error: unknown) {
    const err = error as Error;
    console.error("Roblox script delivery API error (TR Legacy):", err);
    const errScript = getErrorGuiLua(
      "Execute error: server delivery failure. Please try again later!",
      "https://hiphub.cloud/"
    );
    return new NextResponse(errScript, {
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
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
      userAgent.includes("potassium") ||
      userAgent.includes("curl");

    if (!isRoblox) {
      return NextResponse.json({ error: "Access Denied" }, { status: 403 });
    }

    const body = await request.json();
    const { action, placeId } = body;

    const allowedPlaceIds = ["127089247654125"];
    if (placeId && !allowedPlaceIds.includes(String(placeId))) {
      return NextResponse.json({ error: "Access Denied: Invalid Place ID" }, { status: 403 });
    }

    if (action === "ping") {
      return NextResponse.json({ success: true, message: "pong" });
    }

    return NextResponse.json({ error: "Invalid action" }, { status: 400 });
  } catch (error: unknown) {
    console.error("Roblox script API POST error (TR Legacy):", error);
    return NextResponse.json({ error: "Server Error" }, { status: 500 });
  }
}
