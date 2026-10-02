-- 🚀 HipHub DE -- Driving Empire Bootloader
-- Place ID: 9694510481 (Driving Empire)
-- Loads baseui.lua shell first, then DE-specific modules in dependency order

local function debugLog(msg)
	print("[HipHub DE] " .. tostring(msg))
end

-- Load a script file from executor filesystem (tries multiple paths)
local function loadFile(fileName, isBase)
	if readfile then
		local paths = {}
		if isBase then
			paths = {
				".baseui/" .. fileName,
				"HipHub/.baseui/" .. fileName,
				"hiphub/.baseui/" .. fileName,
			}
		else
			paths = {
				fileName,
				"de/" .. fileName,
				"HipHub/de/" .. fileName,
				"hiphub/de/" .. fileName,
			}
		end

		for _, path in ipairs(paths) do
			if isfile and isfile(path) then
				debugLog("Loading: " .. path)
				local content = readfile(path)
				local fn, compileErr = loadstring(content, "@" .. fileName)
				if fn then
					local ok, runErr = pcall(fn)
					if ok then
						debugLog("OK: " .. fileName)
						return true
					else
						warn("[HipHub DE] Runtime error in " .. fileName .. ": " .. tostring(runErr))
						return false
					end
				else
					warn("[HipHub DE] Compile error in " .. fileName .. ": " .. tostring(compileErr))
					return false
				end
			end
		end
	end
	warn("[HipHub DE] Not found: " .. fileName)
	return false
end

local function boot()
	debugLog("Starting HipHub Driving Empire Suite...")

	-- 1. Load base UI shell (creates _G.HipHubUI)
	local baseLoaded = loadFile("baseui.lua", true)
	if not baseLoaded then
		warn("[HipHub DE] Failed to load baseui.lua -- aborting boot")
		return
	end

	-- Wait for _G.HipHubUI to be populated
	local timeout = 0
	while not _G.HipHubUI and timeout < 120 do
		task.wait(0.05)
		timeout = timeout + 1
	end

	if not _G.HipHubUI then
		warn("[HipHub DE] _G.HipHubUI not ready after timeout")
		return
	end

	task.wait(0.18) -- Let UI settle

	-- 2. Load DE modules in dependency order
	local modules = {
		"settings.lua", -- Config first (populates _G.HipHubConfig)
		"ui.lua",       -- UI customization (repurposes base tabs for DE)
		"main.lua",     -- Window controls + anti-AFK + resize handle
		"vehicle.lua",  -- Vehicle mods + teleport (_G.HipHubVehicle, _G.HipHubTeleport)
		"farm.lua",     -- Auto-farm system (_G.HipHubFarm)
		"esp.lua",      -- ESP system (_G.HipHubESP)
	}

	for _, file in ipairs(modules) do
		local ok, loadErr = pcall(loadFile, file, false)
		if not ok then
			warn("[HipHub DE] Error loading " .. file .. ": " .. tostring(loadErr))
		end
		task.wait(0.1)
	end

	debugLog("Driving Empire suite fully initialized!")

	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "HipHub DE",
			Text = "Driving Empire ready. [RightShift] to toggle.",
			Duration = 5,
		})
	end)
end

local ok, err = pcall(boot)
if not ok then
	warn("[HipHub DE Boot Error]: " .. tostring(err))
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "HipHub DE Boot Error",
			Text = tostring(err),
			Duration = 10,
		})
	end)
end
