-- HipHub Ghost Driver — Local Loader
-- Loads modular files in dependency order

local MODULE_FILES = {
	"ui.lua",
	"settings.lua",
	"corridor.lua",
	"farm.lua",
	"vehicle.lua",
	"teleport.lua",
	"main.lua"
}

local function debugLog(msg)
	print("[HipHub Ghost Driver Loader] " .. tostring(msg))
end

local function loadScriptFile(fileName)
	if not readfile then
		error("Your executor does not support 'readfile'. Please run bundle.lua directly.")
	end

	if isfile and not isfile(fileName) then
		error("Could not find '" .. fileName .. "' in workspace.")
	end

	debugLog("Loading " .. fileName .. "...")
	local content = readfile(fileName)
	local func, err = loadstring(content, "@" .. fileName)
	if not func then
		error("Failed to compile " .. fileName .. ": " .. tostring(err))
	end

	task.spawn(func)
	debugLog("Executed " .. fileName)
end

for _, file in ipairs(MODULE_FILES) do
	local ok, err = pcall(loadScriptFile, file)
	if not ok then
		warn("[HipHub Loader Error] " .. file .. ": " .. tostring(err))
	end
	task.wait(0.1)
end
