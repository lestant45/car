-- 👁️ HipHub DDS — Visual Enhancements, ESP & Lighting Utilities
-- Drag Drive Simulator (Place ID: 131378148336503)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Visuals"].content
	local Players = game:GetService("Players")
	local Lighting = game:GetService("Lighting")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer

	local Config = _G.HipHubConfig and _G.HipHubConfig.visuals or {
		playerEsp = false,
		jobEsp = false,
		fullBright = false,
		noFog = false
	}

	------------------------------------------------
	-- 🧍 PLAYER ESP ENGINE
	------------------------------------------------
	local playerEspFolder = Instance.new("Folder")
	playerEspFolder.Name = "HipHub_PlayerESP"
	playerEspFolder.Parent = workspace

	local espConnections = {}

	local function createPlayerEsp(targetPlr)
		if targetPlr == player then return end

		local function onChar(char)
			local head = char:WaitForChild("Head", 5)
			local root = char:WaitForChild("HumanoidRootPart", 5)
			if not (head and root) then return end

			local bb = Instance.new("BillboardGui")
			bb.Name = "ESP_" .. targetPlr.Name
			bb.Adornee = head
			bb.Size = UDim2.new(0, 140, 0, 40)
			bb.StudsOffset = Vector3.new(0, 2, 0)
			bb.AlwaysOnTop = true
			bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 0, 18)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = targetPlr.DisplayName .. " (@" .. targetPlr.Name .. ")"
			nameLabel.TextColor3 = targetPlr.TeamColor and targetPlr.TeamColor.Color or Color3.fromRGB(0, 210, 255)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 11
			nameLabel.Parent = bb

			local distLabel = Instance.new("TextLabel")
			distLabel.Size = UDim2.new(1, 0, 0, 14)
			distLabel.Position = UDim2.new(0, 0, 0, 18)
			distLabel.BackgroundTransparency = 1
			distLabel.Text = "0m"
			distLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			distLabel.Font = Enum.Font.Gotham
			distLabel.TextSize = 10
			distLabel.Parent = bb

			bb.Parent = playerEspFolder

			local distConn = RunService.RenderStepped:Connect(function()
				if not Config.playerEsp or not char or not char.Parent then
					bb.Enabled = false
					return
				end

				local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if myRoot and root then
					bb.Enabled = true
					local dist = math.floor((myRoot.Position - root.Position).Magnitude)
					distLabel.Text = tostring(dist) .. " studs [" .. tostring(targetPlr.Team and targetPlr.Team.Name or "No Team") .. "]"
				end
			end)

			table.insert(espConnections, distConn)
		end

		if targetPlr.Character then
			task.spawn(onChar, targetPlr.Character)
		end
		targetPlr.CharacterAdded:Connect(onChar)
	end

	local function togglePlayerEsp(state)
		Config.playerEsp = state
		if not state then
			playerEspFolder:ClearAllChildren()
			for _, conn in ipairs(espConnections) do
				conn:Disconnect()
			end
			table.clear(espConnections)
		else
			for _, p in ipairs(Players:GetPlayers()) do
				createPlayerEsp(p)
			end
		end
	end

	Players.PlayerAdded:Connect(function(p)
		if Config.playerEsp then
			createPlayerEsp(p)
		end
	end)

	------------------------------------------------
	-- 💡 WORLD LIGHTING ENHANCEMENTS
	------------------------------------------------
	local origAmbient = Lighting.Ambient
	local origOutdoorAmbient = Lighting.OutdoorAmbient
	local origFogEnd = Lighting.FogEnd
	local origBrightness = Lighting.Brightness

	local function toggleFullBright(state)
		Config.fullBright = state
		if state then
			Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
			Lighting.Brightness = 2
		else
			Lighting.Ambient = origAmbient
			Lighting.OutdoorAmbient = origOutdoorAmbient
			Lighting.Brightness = origBrightness
		end
	end

	local function toggleNoFog(state)
		Config.noFog = state
		if state then
			Lighting.FogEnd = 100000
		else
			Lighting.FogEnd = origFogEnd
		end
	end

	------------------------------------------------
	-- 🖼️ UI COMPONENTS IN VISUALS TAB
	------------------------------------------------
	UI.AddSection(tab, "ESP & Player Tracking")
	UI.AddToggle(tab, "Player ESP", "Shows names, teams, and distances for all players", Config.playerEsp, function(state)
		togglePlayerEsp(state)
	end)

	UI.AddSection(tab, "World & Lighting Controls")
	UI.AddToggle(tab, "FullBright (Night Vision)", "Maximizes world ambient brightness to see clearly in darkness", Config.fullBright, function(state)
		toggleFullBright(state)
	end)

	UI.AddToggle(tab, "No Fog / Clear Vision", "Removes atmospheric fog and distance blurring", Config.noFog, function(state)
		toggleNoFog(state)
	end)

	UI.AddSlider(tab, "Time of Day (Hours)", 0, 24, 14, function(val)
		Lighting.ClockTime = val
	end)

	UI.AddSection(tab, "Graphics & FPS Booster")
	UI.AddButton(tab, "Boost FPS (Remove Low Value Textures)", "Boost FPS", function()
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("Decal") or v:IsA("Texture") then
					v.Transparency = 1
				elseif v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then
					v.Enabled = false
				end
			end
			UI.Notify("FPS Boosted", "Disabled decals, textures & particle emitters.", 3, "success")
		end)
	end)
end)

if not success then
	warn("[HipHub DDS Visuals Error]:", err)
end
