-- CAB Loader
-- Run this script in your executor. It will load and run the main UI script from your workspace.

local FILE_NAME = "ui.lua"

local function debugLog(message)
	-- print("[Loader] " .. tostring(message))
end

local function loadScript()
	if not readfile then
		error("Your executor does not support 'readfile'. Please run the main script directly.")
	end

	-- Check if the file exists (if isfile is supported by the executor)
	if isfile and not isfile(FILE_NAME) then
		error("Could not find '" ..
		FILE_NAME .. "' in your executor's workspace folder. Please make sure the file is placed there.")
	end

	debugLog("Loading " .. FILE_NAME .. "...")
	local content = readfile(FILE_NAME)

	local func, err = loadstring(content, "@" .. FILE_NAME)
	if not func then
		error("Failed to compile " .. FILE_NAME .. ": " .. tostring(err))
	end

	debugLog("Executing " .. FILE_NAME .. "...")
	task.spawn(func)
	debugLog("Successfully executed!")
end

local success, err = pcall(loadScript)
if not success then
	-- warn("[Loader Error] " .. tostring(err))

	-- Attempt to show a notification in-game if possible
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Loader Error",
			Text = tostring(err),
			Duration = 10,
		})
	end)
end
