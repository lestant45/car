-- 👁️ HipHub BXI — Visuals, 3D ESP & Lighting System
-- Bus X Indonesia (Place ID: 137806249434874)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Visuals"].content
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local TweenService = game:GetService("TweenService")
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	local Config = _G.HipHubConfig and _G.HipHubConfig.visuals or {
		checkpointEsp = true,
		terminalEsp = true,
		playerEsp = false,
		vehicleEsp = false,
		fullBright = false,
		customFov = 70,
		speedometerHud = true
	}

	------------------------------------------------
	-- 💡 FULLBRIGHT & LIGHTING MODS
	------------------------------------------------
	local origAmbient = Lighting.Ambient
	local origOutdoor = Lighting.OutdoorAmbient
	local origBrightness = Lighting.Brightness
	local origFogEnd = Lighting.FogEnd
	local fullbrightConn = nil

	local function toggleFullbright(state)
		Config.fullBright = state
		if fullbrightConn then
			fullbrightConn:Disconnect()
			fullbrightConn = nil
		end

		if state then
			fullbrightConn = RunService.RenderStepped:Connect(function()
				Lighting.Ambient = Color3.fromRGB(255, 255, 255)
				Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
				Lighting.Brightness = 2
				Lighting.FogEnd = 1000000
				Lighting.GlobalShadows = false
			end)
			UI.Notify("Fullbright Active", "Map lighting fully illuminated.", 2, "success")
		else
			Lighting.Ambient = origAmbient
			Lighting.OutdoorAmbient = origOutdoor
			Lighting.Brightness = origBrightness
			Lighting.FogEnd = origFogEnd
			Lighting.GlobalShadows = true
			UI.Notify("Fullbright Disabled", "Default lighting restored.", 2, "warning")
		end
	end

	------------------------------------------------
	-- 🏁 CHECKPOINT & TERMINAL 3D ESP SYSTEM
	------------------------------------------------
	local espFolder = Instance.new("Folder")
	espFolder.Name = "HipHub_BXI_ESP"
	pcall(function() espFolder.Parent = workspace.CurrentCamera end)

	local checkpointBillboards = {}
	local terminalBillboards = {}

	local function createBillboard(adornee, text, color, tag)
		if not adornee or not adornee:IsA("BasePart") then return end

		local bb = Instance.new("BillboardGui")
		bb.Name = "ESP_" .. tostring(tag or adornee.Name)
		bb.Adornee = adornee
		bb.Size = UDim2.new(0, 160, 0, 42)
		bb.StudsOffset = Vector3.new(0, 4.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 15000
		bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
		frame.BackgroundTransparency = 0.25
		frame.BorderSizePixel = 0

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = color or Color3.fromRGB(0, 220, 255)
		stroke.Thickness = 1.5
		stroke.Parent = frame

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -8, 0, 20)
		title.Position = UDim2.new(0, 4, 0, 2)
		title.BackgroundTransparency = 1
		title.Text = text
		title.TextColor3 = color or Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 11
		title.Parent = frame

		local dist = Instance.new("TextLabel")
		dist.Name = "Dist"
		dist.Size = UDim2.new(1, -8, 0, 16)
		dist.Position = UDim2.new(0, 4, 0, 22)
		dist.BackgroundTransparency = 1
		dist.Text = "0m"
		dist.TextColor3 = Color3.fromRGB(160, 180, 210)
		dist.Font = Enum.Font.Gotham
		dist.TextSize = 10
		dist.Parent = frame

		frame.Parent = bb
		bb.Parent = espFolder
		return bb
	end

	-- Checkpoints ESP Toggle
	local checkpointEspActive = false
	local cpUpdateConn = nil

	local function toggleCheckpointEsp(state)
		checkpointEspActive = state
		Config.checkpointEsp = state

		if not state then
			for _, bb in pairs(checkpointBillboards) do
				if bb and bb.Parent then bb:Destroy() end
			end
			checkpointBillboards = {}
			if cpUpdateConn then cpUpdateConn:Disconnect(); cpUpdateConn = nil end
			return
		end

		local function refreshCPs()
			for _, bb in pairs(checkpointBillboards) do
				if bb and bb.Parent then bb:Destroy() end
			end
			checkpointBillboards = {}

			if workspace:FindFirstChild("Checkpoints") then
				for _, cp in ipairs(workspace.Checkpoints:GetDescendants()) do
					if cp:IsA("BasePart") then
						local bb = createBillboard(cp, "🚩 " .. cp.Name, Color3.fromRGB(0, 220, 255), "CP")
						if bb then table.insert(checkpointBillboards, { gui = bb, part = cp }) end
					end
				end
			end
		end

		refreshCPs()

		if cpUpdateConn then cpUpdateConn:Disconnect() end
		cpUpdateConn = RunService.Heartbeat:Connect(function()
			if not checkpointEspActive then return end
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			for _, item in ipairs(checkpointBillboards) do
				if item.gui and item.part and item.part.Parent then
					local distM = math.floor((root.Position - item.part.Position).Magnitude * 0.28)
					local distLabel = item.gui:FindFirstChild("Dist", true)
					if distLabel then
						distLabel.Text = string.format("%d m", distM)
					end
				end
			end
		end)
	end

	-- Terminals ESP Toggle
	local terminalEspActive = false
	local termUpdateConn = nil

	local function toggleTerminalEsp(state)
		terminalEspActive = state
		Config.terminalEsp = state

		if not state then
			for _, bb in pairs(terminalBillboards) do
				if bb and bb.Parent then bb:Destroy() end
			end
			terminalBillboards = {}
			if termUpdateConn then termUpdateConn:Disconnect(); termUpdateConn = nil end
			return
		end

		local TERMINAL_LOCATIONS = {
			{ name = "Terminal Baranangsiang", pos = Vector3.new(22771.8, 294.8, -39584.0) },
			{ name = "Terminal Kp. Rambutan", pos = Vector3.new(27536.3, 130.2, -3746.7) },
			{ name = "Terminal Harjamukti Cirebon", pos = Vector3.new(-24211.4, -205.2, 34271.9) },
			{ name = "Terminal Cikampek", pos = Vector3.new(-2888.9, -135.3, 28219.4) }
		}

		for _, term in ipairs(TERMINAL_LOCATIONS) do
			local p = Instance.new("Part")
			p.Name = "ESP_Term_" .. term.name
			p.Anchored = true
			p.CanCollide = false
			p.Transparency = 1
			p.Position = term.pos
			p.Parent = espFolder

			local bb = createBillboard(p, "🚌 " .. term.name, Color3.fromRGB(0, 230, 140), "Terminal")
			if bb then table.insert(terminalBillboards, { gui = bb, part = p }) end
		end

		if termUpdateConn then termUpdateConn:Disconnect() end
		termUpdateConn = RunService.Heartbeat:Connect(function()
			if not terminalEspActive then return end
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			for _, item in ipairs(terminalBillboards) do
				if item.gui and item.part and item.part.Parent then
					local distM = math.floor((root.Position - item.part.Position).Magnitude * 0.28)
					local distLabel = item.gui:FindFirstChild("Dist", true)
					if distLabel then
						distLabel.Text = string.format("%d m", distM)
					end
				end
			end
		end)
	end

	------------------------------------------------
	-- 👥 PLAYER & VEHICLE ESP
	------------------------------------------------
	local playerEspActive = false
	local playerEspObjects = {}

	local function togglePlayerEsp(state)
		playerEspActive = state
		Config.playerEsp = state

		for _, obj in pairs(playerEspObjects) do
			if obj and obj.Parent then obj:Destroy() end
		end
		playerEspObjects = {}
	end

	RunService.RenderStepped:Connect(function()
		if not playerEspActive then return end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = p.Character.HumanoidRootPart
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if not playerEspObjects[p] then
					local bb = Instance.new("BillboardGui")
					bb.Name = "ESP_" .. p.Name
					bb.Adornee = hrp
					bb.Size = UDim2.new(0, 120, 0, 32)
					bb.StudsOffset = Vector3.new(0, 3, 0)
					bb.AlwaysOnTop = true
					bb.MaxDistance = 5000

					local lbl = Instance.new("TextLabel")
					lbl.Size = UDim2.new(1, 0, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.Text = p.DisplayName .. "\n[" .. (hum and math.floor(hum.Health) or "100") .. " HP]"
					lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
					lbl.Font = Enum.Font.GothamBold
					lbl.TextSize = 11
					lbl.Parent = bb

					bb.Parent = espFolder
					playerEspObjects[p] = bb
				else
					local lbl = playerEspObjects[p]:FindFirstChildOfClass("TextLabel")
					if lbl then
						local distM = math.floor((camera.CFrame.Position - hrp.Position).Magnitude * 0.28)
						lbl.Text = p.DisplayName .. " (" .. distM .. "m)\n[" .. (hum and math.floor(hum.Health) or "0") .. " HP]"
					end
				end
			else
				if playerEspObjects[p] then
					playerEspObjects[p]:Destroy()
					playerEspObjects[p] = nil
				end
			end
		end
	end)

	------------------------------------------------
	-- 🚀 SPEEDOMETER HUD
	------------------------------------------------
	local speedoFrame = Instance.new("Frame")
	speedoFrame.Name = "HipHub_Speedometer"
	speedoFrame.Size = UDim2.new(0, 150, 0, 70)
	speedoFrame.Position = UDim2.new(0.5, -75, 1, -120)
	speedoFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
	speedoFrame.BackgroundTransparency = 0.15
	speedoFrame.ZIndex = 20
	speedoFrame.Visible = Config.speedometerHud

	local spCorner = Instance.new("UICorner")
	spCorner.CornerRadius = UDim.new(0, 12)
	spCorner.Parent = speedoFrame

	local spStroke = Instance.new("UIStroke")
	spStroke.Color = Color3.fromRGB(0, 220, 255)
	spStroke.Thickness = 1.5
	spStroke.Parent = speedoFrame

	local spValue = Instance.new("TextLabel")
	spValue.Size = UDim2.new(1, 0, 0, 38)
	spValue.Position = UDim2.new(0, 0, 0, 4)
	spValue.BackgroundTransparency = 1
	spValue.Text = "0"
	spValue.TextColor3 = Color3.fromRGB(0, 230, 140)
	spValue.Font = Enum.Font.GothamBold
	spValue.TextSize = 30
	spValue.ZIndex = 21
	spValue.Parent = speedoFrame

	local spUnit = Instance.new("TextLabel")
	spUnit.Size = UDim2.new(1, 0, 0, 18)
	spUnit.Position = UDim2.new(0, 0, 0, 44)
	spUnit.BackgroundTransparency = 1
	spUnit.Text = "KM / H"
	spUnit.TextColor3 = Color3.fromRGB(150, 175, 210)
	spUnit.Font = Enum.Font.GothamBold
	spUnit.TextSize = 10
	spUnit.ZIndex = 21
	spUnit.Parent = speedoFrame

	speedoFrame.Parent = UI.gui

	RunService.RenderStepped:Connect(function()
		if not speedoFrame.Visible then return end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart

		local curSpeed = 0
		if seat and seat:IsA("BasePart") then
			curSpeed = math.floor(seat.AssemblyLinearVelocity.Magnitude * 3.6 / 3.571)
		elseif char and char:FindFirstChild("HumanoidRootPart") then
			curSpeed = math.floor(char.HumanoidRootPart.AssemblyLinearVelocity.Magnitude * 3.6 / 3.571)
		end

		spValue.Text = tostring(curSpeed)
		if curSpeed > 140 then
			spValue.TextColor3 = Color3.fromRGB(255, 100, 100)
		elseif curSpeed > 80 then
			spValue.TextColor3 = Color3.fromRGB(255, 200, 50)
		else
			spValue.TextColor3 = Color3.fromRGB(0, 230, 140)
		end
	end)

	------------------------------------------------
	-- 🎨 VISUALS UI BUILDER
	------------------------------------------------

	-- 1. Navigation & ESP
	UI.AddSection(tab, "ESP & Navigation Highlights")

	UI.AddToggle(tab, "Checkpoints 3D ESP (With Distance)", Config.checkpointEsp, function(state)
		toggleCheckpointEsp(state)
	end)

	UI.AddToggle(tab, "Terminals 3D ESP", Config.terminalEsp, function(state)
		toggleTerminalEsp(state)
	end)

	UI.AddToggle(tab, "Player ESP (Names & Health)", Config.playerEsp, function(state)
		togglePlayerEsp(state)
	end)

	-- 2. HUD & Overlay
	UI.AddSection(tab, "HUD & Custom Display")

	UI.AddToggle(tab, "Digital Speedometer HUD", Config.speedometerHud, function(state)
		Config.speedometerHud = state
		speedoFrame.Visible = state
	end)

	-- 3. Lighting & Camera
	UI.AddSection(tab, "Camera & Map Lighting")

	UI.AddToggle(tab, "Fullbright Mode (Permanent Daylight)", Config.fullBright, function(state)
		toggleFullbright(state)
	end)

	UI.AddSlider(tab, "Field of View (FOV)", 50, 120, camera.FieldOfView, function(val)
		Config.customFov = val
		camera.FieldOfView = val
	end, "°")

	UI.AddSlider(tab, "Time of Day (ClockTime)", 0, 24, Lighting.ClockTime, function(val)
		Lighting.ClockTime = val
	end, "Hrs")
end)

if not success then
	warn("[HipHub BXI Visuals Error]:", err)
end
