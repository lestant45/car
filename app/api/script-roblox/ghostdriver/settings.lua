-- HipHub Ghost Driver — Settings & Config Manager
-- Handles JSON persistence across sessions, anti-AFK, and global settings

local success, err = pcall(function()
	local HttpService = game:GetService("HttpService")
	local FOLDER_NAME = "HipHub/GhostDriver"
	local FILE_NAME = FOLDER_NAME .. "/config.json"

	local Config = {
		farm = {
			autoRace = false,
			raceDifficulty = "Hard",
			raceDelay = 1.0,
			autoDodgeTraffic = true,
			autoClaimQuests = true,
			claimInterval = 5,
			autoSpeedFarm = false,
			targetSpeed = 180,
			autoAfkArea = false,
			autoBuyCar = false,
			targetCarToBuy = "Novis N55"
		},
		vehicle = {
			selectedCar = "Wulfbrecht RZ7",
			speedBoost = false,
			speedMultiplier = 1.3,
			autoFlip = true,
			infiniteNitro = false
		},
		settings = {
			antiAfk = true,
			zeroLag = false,
			potatoMaterials = true,
			fpsCap = 60,
			fpsBooster = false,
			toggleKey = "RightControl"
		}
	}

	local function deepCopy(t)
		local clone = {}
		for k, v in pairs(t) do
			if type(v) == "table" then
				clone[k] = deepCopy(v)
			else
				clone[k] = v
			end
		end
		return clone
	end

	local function reconcile(target, template)
		for k, v in pairs(template) do
			if target[k] == nil then
				if type(v) == "table" then
					target[k] = deepCopy(v)
				else
					target[k] = v
				end
			elseif type(v) == "table" and type(target[k]) == "table" then
				reconcile(target[k], v)
			end
		end
	end

	local Settings = {
		Current = deepCopy(Config)
	}

	function Settings.Save()
		pcall(function()
			if writefile and makefolder then
				if not isfolder("HipHub") then makefolder("HipHub") end
				if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
				local json = HttpService:JSONEncode(Settings.Current)
				writefile(FILE_NAME, json)
			end
		end)
	end

	function Settings.Load()
		pcall(function()
			if readfile and isfile and isfile(FILE_NAME) then
				local content = readfile(FILE_NAME)
				local decoded = HttpService:JSONDecode(content)
				if type(decoded) == "table" then
					reconcile(decoded, Config)
					Settings.Current = decoded
				end
			end
		end)
	end

	Settings.Load()
	_G.HipHubConfig = Settings.Current
	_G.HipHub_GhostDriver_Settings = Settings
end)

if not success then
	warn("[HipHub Ghost Driver Settings Error]:", err)
end
