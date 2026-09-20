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
  const cacheName = makeId(8);
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
local ${cacheName} = {}
local function ${decName}(idx)
  local cached = ${cacheName}[idx]
  if cached then return cached end
  local data = ${arrayName}[idx]
  if not data then return "" end
  local chars = {}
  for i = 1, #data do
    table.insert(chars, string.char(bit32.bxor(data[i], ${key})))
  end
  local str = table.concat(chars)
  ${cacheName}[idx] = str
  return str
end

${result}
`;
}

function obfuscateLuaXor(code: string, licenseKey: string = "KEYLESS"): string {
  const clean = stripComments(code);
  const key = (licenseKey.charCodeAt(0) || 53) ^ 0x5a;
  const decName = makeId(8);
  return localObfuscate(clean, decName, key);
}

function getErrorGuiLua(errorMessage: string, discordUrl = "https://hiphub.cloud/"): string {
  return `
local player = game:GetService("Players").LocalPlayer
local errGui = Instance.new("ScreenGui")
errGui.Name = "HipHubError"
errGui.ResetOnSpawn = false
errGui.DisplayOrder = 2147483647

pcall(function()
    local parentGui = (gethui and gethui()) or game:GetService("CoreGui") or player:WaitForChild("PlayerGui")
    errGui.Parent = parentGui
    
    local COLORS = {
        glassSurface  = Color3.fromRGB(18, 22, 40),
        glassCard     = Color3.fromRGB(22, 28, 50),
        borderGlass   = Color3.fromRGB(55, 70, 120),
        textPrimary   = Color3.fromRGB(230, 240, 255),
        textSecondary = Color3.fromRGB(145, 160, 195),
        dangerRed     = Color3.fromRGB(231, 76, 60),
    }

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 460, 0, 160)
    frame.Position = UDim2.new(0.5, -230, 0.5, -80)
    frame.BackgroundColor3 = COLORS.glassSurface
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = errGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.dangerRed
    stroke.Thickness = 1.2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 36)
    title.Position = UDim2.new(0, 16, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "⚠️ HIPHUB DDS ERROR"
    title.TextColor3 = COLORS.dangerRed
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -32, 0, 60)
    msg.Position = UDim2.new(0, 16, 0, 44)
    msg.BackgroundTransparency = 1
    msg.Text = "${errorMessage.replace(/"/g, '\\"')}"
    msg.TextColor3 = COLORS.textPrimary
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 11
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 80, 0, 28)
    closeBtn.Position = UDim2.new(1, -96, 1, -38)
    closeBtn.BackgroundColor3 = COLORS.glassCard
    closeBtn.Text = "Close"
    closeBtn.TextColor3 = COLORS.textSecondary
    closeBtn.Font = Enum.Font.GothamMedium
    closeBtn.TextSize = 11
    closeBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        errGui:Destroy()
    end)
end)
`;
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const mode = searchParams.get("mode");
    const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "https://hiphub.cloud";

    // Mode: loader script delivery
    if (mode === "loader") {
      const loaderScript = `
local content = nil
local success = false

local function findGuiInParents(name)
    local player = game:GetService("Players").LocalPlayer
    if not player then return nil end
    local pGui = player:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild(name) then return pGui:FindFirstChild(name) end
    if gethui and gethui():FindFirstChild(name) then return gethui():FindFirstChild(name) end
    local coreGui = game:GetService("CoreGui")
    if coreGui:FindFirstChild(name) then return coreGui:FindFirstChild(name) end
    return nil
end

for i = 1, 3 do
    local s, res = pcall(function()
        return game:HttpGet("${baseUrl}/api/script-roblox/dds")
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
    warn("[HipHub DDS] Network error fetching payload.")
    return
end

local func, err = loadstring(content)
if not func then
    warn("[HipHub DDS] Script compilation failure: " .. tostring(err))
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

    // Serving main bundled script payload (Keyless)
    const scriptDir = path.join(process.cwd(), "app/api/script-roblox/dds");
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
    const userAgent = (request.headers.get("user-agent") || "").toLowerCase();
    const executorHeader = (request.headers.get("executor") || "").toLowerCase();
    const isArceus = executor.includes("arceus") || userAgent.includes("arceus") || executorHeader.includes("arceus");

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

    let finalScript = luaScript;
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
        console.error("Failed to save script to database cache:", dbSaveErr);
      }
    } else {
      finalScript = obfuscateLuaXor(luaScript, "KEYLESS");
      globalCache = { sourceHash, obfuscatedCode: finalScript };
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

    const body = await request.json();
    const { action, placeId } = body;

    // Validate Drag Drive Simulator place ID
    const allowedPlaceIds = ["131378148336503"];
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
