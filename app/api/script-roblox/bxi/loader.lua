-- 🚀 HipHub BXI — Bus X Indonesia Local & Production Loader
-- Place ID: 137806249434874 (Jawa Barat)
-- Loads and executes all modular BXI tab scripts in proper dependency order

local MODULE_FILES = {
	"ui.lua",
	"settings.lua",
	"teleport.lua",
	"visuals.lua",
	"vehicle.lua",
	"farm.lua",
	"main.lua"
}

local function debugLog(message)
	print("[HipHub BXI Loader] " .. tostring(message))
end

local function loadScriptFile(fileName)
	-- Check executor readfile capability
	if readfile then
		local localPaths = {
			fileName,
			"bxi/" .. fileName,
			"HipHub/" .. fileName,
			"hiphub/bxi/" .. fileName
		}

		for _, path in ipairs(localPaths) do
			if isfile and isfile(path) then
				debugLog("Loading local " .. path .. "...")
				local content = readfile(path)
				local func, err = loadstring(content, "@" .. fileName)
				if func then
					task.spawn(func)
					debugLog("Successfully executed " .. fileName)
					return true
				else
					warn("[HipHub Loader Error] Failed to compile " .. fileName .. ": " .. tostring(err))
				end
			end
		end
	end

	warn("[HipHub Loader] Could not find local file '" .. fileName .. "'.")
	return false
end

local function loadAll()
	debugLog("Starting HipHub BXI Suite Bootloader...")
	for _, file in ipairs(MODULE_FILES) do
		local success, err = pcall(loadScriptFile, file)
		if not success then
			warn("[HipHub Loader Error] Failed to load " .. file .. ": " .. tostring(err))
		end
		task.wait(0.12)
	end
	debugLog("HipHub BXI Suite initialization complete!")
end

local success, err = pcall(loadAll)
if not success then
	warn("[HipHub Loader Boot Error]: " .. tostring(err))
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "HipHub Loader Error",
			Text = tostring(err),
			Duration = 10,
		})
	end)
end
