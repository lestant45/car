-- ⚙️ HipHub DE -- Settings & Config Persistence
-- Driving Empire (Place ID: 9694510481)
-- Must load BEFORE ui.lua; populates _G.HipHubConfig

local success, err = pcall(function()
	local HttpService = game:GetService("HttpService")

	local CONFIG_PATH = "HipHub/de_config.json"

	local DEFAULT_CONFIG = {
		farm = {
			autoCollectCash = false,
			autoBankRob = false,
			autoDelivery = false,
			collectDelay = 0.3,
			targetEarnM = 0,
			targetEarnEnabled = false,
		},
		vehicle = {
			speedMultiplier = 1.0,
			godMode = false,
			infiniteNitro = false,
			noDamage = false,
			noclip = false,
		},
		esp = {
			playerEsp = false,
			carEsp = false,
			cashEsp = false,
			showDistance = true,
			showName = true,
		},
		misc = {
			antiAfk = true,
			webhookUrl = "",
			webhookEnabled = false,
			fpsBooster = false,
		},
	}

	-- Merge defaults with existing _G.HipHubConfig
	_G.HipHubConfig = _G.HipHubConfig or {}
	for section, defaults in pairs(DEFAULT_CONFIG) do
		if not _G.HipHubConfig[section] then
			_G.HipHubConfig[section] = {}
		end
		for k, v in pairs(defaults) do
			if _G.HipHubConfig[section][k] == nil then
				_G.HipHubConfig[section][k] = v
			end
		end
	end

	------------------------------------------------
	-- 💾 SAVE CONFIG
	------------------------------------------------
	local function saveConfig()
		if not writefile then return end
		pcall(function()
			if not isfolder or not isfolder("HipHub") then
				if makefolder then makefolder("HipHub") end
			end
			writefile(CONFIG_PATH, HttpService:JSONEncode(_G.HipHubConfig))
		end)
	end

	------------------------------------------------
	-- 📂 LOAD CONFIG
	------------------------------------------------
	local function loadConfig()
		if not readfile then return end
		pcall(function()
			if isfile and isfile(CONFIG_PATH) then
				local raw = readfile(CONFIG_PATH)
				local data = HttpService:JSONDecode(raw)
				if type(data) == "table" then
					for section, vals in pairs(data) do
						if type(vals) == "table" then
							_G.HipHubConfig[section] = _G.HipHubConfig[section] or {}
							for k, v in pairs(vals) do
								_G.HipHubConfig[section][k] = v
							end
						end
					end
				end
			end
		end)
	end

	-- Load persisted config on boot
	loadConfig()

	-- Expose on _G.HipHubUI when it exists
	local function attachToUI()
		if _G.HipHubUI then
			_G.HipHubUI.saveConfig = saveConfig
			_G.HipHubUI.loadConfig = loadConfig
		end
	end
	pcall(attachToUI)

	print("[HipHub DE Settings] Config loaded.")
end)

if not success then
	warn("[HipHub DE Settings Error]:", err)
end
