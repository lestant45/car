-- 👁️ HipHub CDID — Visuals, ESP & Speedometer HUD Suite
-- Handles Car ESP, Player ESP, World Lighting, Weather Clearing, and Cyberpunk Speedometer Overlay

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Config = _G.HipHubConfig or { visuals = {} }
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local player = Players.LocalPlayer

	local carEspActive = Config.visuals.carEsp or false
	local playerEspActive = Config.visuals.playerEsp or false
	local fullbrightActive = Config.visuals.fullbright or false
	local noFogActive = Config.visuals.noFog or false
	local speedometerActive = Config.visuals.speedometer or true

	local carEspFolder = Instance.new("Folder")
	carEspFolder.Name = "HipHub_CarESP"
	carEspFolder.Parent = UI.gui

	local playerEspFolder = Instance.new("Folder")
	playerEspFolder.Name = "HipHub_PlayerESP"
	playerEspFolder.Parent = UI.gui

	------------------------------------------------
	-- 🚗 CAR ESP SYSTEM
	------------------------------------------------
	local function updateCarESP()
		carEspFolder:ClearAllChildren()
		if not carEspActive then return end

		local vehicles = workspace:FindFirstChild("Vehicles")
		if not vehicles then return end

		local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not myRoot then return end

		for _, car in pairs(vehicles:GetChildren()) do
			if car:IsA("Model") and car ~= (workspace.Vehicles:FindFirstChild(player.Name .. "sCar")) then
				local primary = car.PrimaryPart or car:FindFirstChild("DriveSeat") or car:FindFirstChildOfClass("BasePart")
				if primary then
					local dist = math.floor((primary.Position - myRoot.Position).Magnitude)
					if dist < 2000 then
						local bb = Instance.new("BillboardGui")
						bb.Name = car.Name .. "_ESP"
						bb.Adornee = primary
						bb.Size = UDim2.new(0, 140, 0, 40)
						bb.StudsOffset = Vector3.new(0, 3.5, 0)
						bb.AlwaysOnTop = true
						bb.Parent = carEspFolder

						local frame = Instance.new("Frame")
						frame.Size = UDim2.new(1, 0, 1, 0)
						frame.BackgroundColor3 = Color3.fromRGB(10, 14, 28)
						frame.BackgroundTransparency = 0.3
						frame.BorderSizePixel = 0
						frame.Parent = bb

						local corner = Instance.new("UICorner")
						corner.CornerRadius = UDim.new(0, 6)
						corner.Parent = frame

						local stroke = Instance.new("UIStroke")
						stroke.Color = Color3.fromRGB(0, 200, 255)
						stroke.Thickness = 1
						stroke.Transparency = 0.4
						stroke.Parent = frame

						local carName = (car:FindFirstChild("CarData") and car.CarData:FindFirstChild("CarName")) and car.CarData.CarName.Value or car.Name
						local title = Instance.new("TextLabel")
						title.Size = UDim2.new(1, -6, 0, 18)
						title.Position = UDim2.new(0, 3, 0, 2)
						title.BackgroundTransparency = 1
						title.Text = "🚗 " .. carName
						title.TextColor3 = Color3.fromRGB(255, 255, 255)
						title.Font = Enum.Font.GothamBold
						title.TextSize = 10
						title.TextTruncate = Enum.TextTruncate.AtEnd
						title.Parent = frame

						local distLabel = Instance.new("TextLabel")
						distLabel.Size = UDim2.new(1, -6, 0, 16)
						distLabel.Position = UDim2.new(0, 3, 0, 20)
						distLabel.BackgroundTransparency = 1
						distLabel.Text = tostring(dist) .. "m away"
						distLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
						distLabel.Font = Enum.Font.Gotham
						distLabel.TextSize = 9
						distLabel.Parent = frame
					end
				end
			end
		end
	end

	------------------------------------------------
	-- 👤 PLAYER ESP SYSTEM
	------------------------------------------------
	local function updatePlayerESP()
		playerEspFolder:ClearAllChildren()
		if not playerEspActive then return end

		local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not myRoot then return end

		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") then
				local head = p.Character.Head
				local dist = math.floor((head.Position - myRoot.Position).Magnitude)
				if dist < 1500 then
					local bb = Instance.new("BillboardGui")
					bb.Name = p.Name .. "_ESP"
					bb.Adornee = head
					bb.Size = UDim2.new(0, 130, 0, 36)
					bb.StudsOffset = Vector3.new(0, 2.5, 0)
					bb.AlwaysOnTop = true
					bb.Parent = playerEspFolder

					local frame = Instance.new("Frame")
					frame.Size = UDim2.new(1, 0, 1, 0)
					frame.BackgroundColor3 = Color3.fromRGB(15, 10, 30)
					frame.BackgroundTransparency = 0.3
					frame.BorderSizePixel = 0
					frame.Parent = bb

					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 6)
					corner.Parent = frame

					local stroke = Instance.new("UIStroke")
					stroke.Color = Color3.fromRGB(140, 120, 255)
					stroke.Thickness = 1
					stroke.Transparency = 0.4
					stroke.Parent = frame

					local title = Instance.new("TextLabel")
					title.Size = UDim2.new(1, -6, 0, 16)
					title.Position = UDim2.new(0, 3, 0, 2)
					title.BackgroundTransparency = 1
					title.Text = "👤 " .. p.DisplayName
					title.TextColor3 = Color3.fromRGB(255, 255, 255)
					title.Font = Enum.Font.GothamBold
					title.TextSize = 10
					title.TextTruncate = Enum.TextTruncate.AtEnd
					title.Parent = frame

					local sub = Instance.new("TextLabel")
					sub.Size = UDim2.new(1, -6, 0, 14)
					sub.Position = UDim2.new(0, 3, 0, 18)
					sub.BackgroundTransparency = 1
					sub.Text = math.floor(p.Character.Humanoid.Health) .. " HP • " .. tostring(dist) .. "m"
					sub.TextColor3 = Color3.fromRGB(160, 200, 255)
					sub.Font = Enum.Font.Gotham
					sub.TextSize = 9
					sub.Parent = frame
				end
			end
		end
	end

	-- ESP Update loop
	task.spawn(function()
		while true do
			if carEspActive then pcall(updateCarESP) end
			if playerEspActive then pcall(updatePlayerESP) end
			task.wait(1.5)
		end
	end)

	------------------------------------------------
	-- 💡 LIGHTING & FULLBRIGHT
	------------------------------------------------
	local defaultBrightness = Lighting.Brightness
	local defaultClock = Lighting.ClockTime
	local defaultFog = Lighting.FogEnd

	local function applyLightingMods()
		if fullbrightActive then
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.GlobalShadows = false
			Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		end
		if noFogActive then
			Lighting.FogEnd = 9e9
		end
	end

	Lighting.Changed:Connect(function()
		if fullbrightActive or noFogActive then
			applyLightingMods()
		end
	end)

	------------------------------------------------
	-- 🏎️ SPEEDOMETER & TELEMETRY HUD
	------------------------------------------------
	local speedoGui = Instance.new("Frame")
	speedoGui.Name = "HipHub_Speedometer"
	speedoGui.Size = UDim2.new(0, 180, 0, 85)
	speedoGui.Position = UDim2.new(1, -195, 1, -100)
	speedoGui.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
	speedoGui.BackgroundTransparency = 0.15
	speedoGui.BorderSizePixel = 0
	speedoGui.Visible = speedometerActive
	speedoGui.ZIndex = 5
	speedoGui.Parent = UI.gui

	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(0, 10)
	sCorner.Parent = speedoGui

	local sStroke = Instance.new("UIStroke")
	sStroke.Color = Color3.fromRGB(0, 200, 255)
	sStroke.Thickness = 1.2
	sStroke.Transparency = 0.4
	sStroke.Parent = speedoGui

	local speedNumber = Instance.new("TextLabel")
	speedNumber.Size = UDim2.new(0, 90, 0, 36)
	speedNumber.Position = UDim2.new(0, 10, 0, 8)
	speedNumber.BackgroundTransparency = 1
	speedNumber.Text = "0"
	speedNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedNumber.Font = Enum.Font.GothamBold
	speedNumber.TextSize = 28
	speedNumber.TextXAlignment = Enum.TextXAlignment.Left
	speedNumber.ZIndex = 6
	speedNumber.Parent = speedoGui

	local speedUnit = Instance.new("TextLabel")
	speedUnit.Size = UDim2.new(0, 70, 0, 20)
	speedUnit.Position = UDim2.new(0, 95, 0, 20)
	speedUnit.BackgroundTransparency = 1
	speedUnit.Text = "KM/H"
	speedUnit.TextColor3 = Color3.fromRGB(0, 200, 255)
	speedUnit.Font = Enum.Font.GothamBold
	speedUnit.TextSize = 11
	speedUnit.TextXAlignment = Enum.TextXAlignment.Left
	speedUnit.ZIndex = 6
	speedUnit.Parent = speedoGui

	local carModelLabel = Instance.new("TextLabel")
	carModelLabel.Size = UDim2.new(1, -20, 0, 16)
	carModelLabel.Position = UDim2.new(0, 10, 0, 44)
	carModelLabel.BackgroundTransparency = 1
	carModelLabel.Text = "No Vehicle"
	carModelLabel.TextColor3 = Color3.fromRGB(150, 165, 195)
	carModelLabel.Font = Enum.Font.GothamMedium
	carModelLabel.TextSize = 10
	carModelLabel.TextXAlignment = Enum.TextXAlignment.Left
	carModelLabel.TextTruncate = Enum.TextTruncate.AtEnd
	carModelLabel.ZIndex = 6
	carModelLabel.Parent = speedoGui

	local rpmBar = Instance.new("Frame")
	rpmBar.Size = UDim2.new(1, -20, 0, 5)
	rpmBar.Position = UDim2.new(0, 10, 0, 68)
	rpmBar.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
	rpmBar.BorderSizePixel = 0
	rpmBar.ZIndex = 6
	rpmBar.Parent = speedoGui

	local rpmBarCorner = Instance.new("UICorner")
	rpmBarCorner.CornerRadius = UDim.new(1, 0)
	rpmBarCorner.Parent = rpmBar

	local rpmFill = Instance.new("Frame")
	rpmFill.Size = UDim2.new(0, 0, 1, 0)
	rpmFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	rpmFill.BorderSizePixel = 0
	rpmFill.ZIndex = 7
	rpmFill.Parent = rpmBar

	local rpmFillCorner = Instance.new("UICorner")
	rpmFillCorner.CornerRadius = UDim.new(1, 0)
	rpmFillCorner.Parent = rpmFill

	-- Telemetry Update loop
	RunService.RenderStepped:Connect(function()
		if not speedometerActive then return end

		local vehicles = workspace:FindFirstChild("Vehicles")
		local myCar = vehicles and (vehicles:FindFirstChild(player.Name .. "sCar") or vehicles:FindFirstChild(player.Name .. "'s Car"))

		if myCar and myCar:FindFirstChild("DriveSeat") then
			local seat = myCar.DriveSeat
			local speed = math.floor(seat.AssemblyLinearVelocity.Magnitude * 3.6 / 3.571)
			speedNumber.Text = tostring(speed)

			local carName = (myCar:FindFirstChild("CarData") and myCar.CarData:FindFirstChild("CarName")) and myCar.CarData.CarName.Value or myCar.Name
			carModelLabel.Text = carName

			local rpmPct = math.clamp(speed / 200, 0, 1)
			rpmFill.Size = UDim2.new(rpmPct, 0, 1, 0)
			if rpmPct > 0.85 then
				rpmFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			else
				rpmFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
			end
		else
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local speed = math.floor(char.HumanoidRootPart.AssemblyLinearVelocity.Magnitude * 3.6 / 3.571)
				speedNumber.Text = tostring(speed)
				carModelLabel.Text = "On Foot (Character)"
				rpmFill.Size = UDim2.new(math.clamp(speed / 50, 0, 1), 0, 1, 0)
			end
		end
	end)

	------------------------------------------------
	-- 🎨 BUILD VISUALS TAB UI
	------------------------------------------------
	local vFrame = UI.tabs["Visuals"].Frame

	-- ESP Section
	local espSec = UI.AddSection(vFrame, "👁️ ESP & Object Tracers", 1)
	UI.AddToggle(espSec, "Vehicle ESP (Cars & Distance)", carEspActive, function(v)
		carEspActive = v
		Config.visuals.carEsp = v
		if not v then carEspFolder:ClearAllChildren() end
	end, 1)

	UI.AddToggle(espSec, "Player ESP (Names & HP)", playerEspActive, function(v)
		playerEspActive = v
		Config.visuals.playerEsp = v
		if not v then playerEspFolder:ClearAllChildren() end
	end, 2)

	-- Lighting & Atmosphere
	local lightSec = UI.AddSection(vFrame, "☀️ Atmosphere & World Lighting", 2)
	UI.AddToggle(lightSec, "Fullbright (No Shadows / Bright Night)", fullbrightActive, function(v)
		fullbrightActive = v
		Config.visuals.fullbright = v
		if v then applyLightingMods() else Lighting.Brightness = defaultBrightness end
	end, 1)

	UI.AddToggle(lightSec, "Clear Sky / Remove Fog & Heavy Rain", noFogActive, function(v)
		noFogActive = v
		Config.visuals.noFog = v
		if v then applyLightingMods() else Lighting.FogEnd = defaultFog end
	end, 2)

	UI.AddButton(lightSec, "☀️ Set Time to Noon (14:00)", function()
		Lighting.ClockTime = 14
		UI.Notify("Time Changed", "Clock set to 14:00 (Day)", 2, "success")
	end, 3)

	UI.AddButton(lightSec, "🌅 Set Time to Sunset (18:00)", function()
		Lighting.ClockTime = 18
		UI.Notify("Time Changed", "Clock set to 18:00 (Sunset)", 2, "success")
	end, 4)

	UI.AddButton(lightSec, "🌙 Set Time to Midnight (00:00)", function()
		Lighting.ClockTime = 0
		UI.Notify("Time Changed", "Clock set to 00:00 (Night)", 2, "success")
	end, 5)

	-- HUD Overlay
	local hudSec = UI.AddSection(vFrame, "🏎️ Performance HUD & Speedometer", 3)
	UI.AddToggle(hudSec, "Show Digital Speedometer Overlay", speedometerActive, function(v)
		speedometerActive = v
		Config.visuals.speedometer = v
		speedoGui.Visible = v
	end, 1)

	-- Export global visuals API
	_G.HipHubVisuals = {
		SetCarESP = function(v) carEspActive = v if not v then carEspFolder:ClearAllChildren() end end,
		SetPlayerESP = function(v) playerEspActive = v if not v then playerEspFolder:ClearAllChildren() end end,
		SetFullbright = function(v) fullbrightActive = v applyLightingMods() end,
		SetSpeedometer = function(v) speedometerActive = v speedoGui.Visible = v end
	}
end)

if not success then
	warn("[HipHub CDID Visuals Error]:", err)
end
