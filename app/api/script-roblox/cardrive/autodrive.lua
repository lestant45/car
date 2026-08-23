-- 🚗 HipHub CDID — Standalone Auto Drive & Highway Odometer Farm
-- Independent closeable GUI with real vehicle physics driving, Highway loop farming, waypoint cruise, and odometer telemetry

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Cleanup existing instance
if _G.HipHubAutoDriveInstance then
	pcall(function() _G.HipHubAutoDriveInstance:Destroy() end)
end

------------------------------------------------
-- 📊 STATE VARIABLES
------------------------------------------------
local isAutoDriving = false
local currentDriveMode = "Highway" -- "Highway", "Waypoint", "Cruise"
local targetCruiseSpeed = 160 -- studs/s (~160 km/h)
local totalDistanceTraveled = 0 -- in studs
local estimatedEarnings = 0 -- in Rp
local activeWaypoint = nil
local highwayIndex = 1
local startTime = os.clock()
local lastPosition = nil

------------------------------------------------
-- 📍 HIGHWAY & ROAD WAYPOINT PRESETS
------------------------------------------------
local HighwayLoopPoints = {
	Vector3.new(1250.0, 24.5, -2400.0),   -- Main Highway Toll Gate
	Vector3.new(3500.0, 24.5, -5000.0),   -- East Interchange
	Vector3.new(6500.0, 24.0, -7600.0),   -- North Expressway
	Vector3.new(4800.0, 24.0, -7700.0),   -- Monas Straight
	Vector3.new(1800.0, 24.5, -4600.0),   -- BCA Depot Junction
	Vector3.new(-2200.0, 24.5, 1400.0),   -- GBK Southbound
	Vector3.new(-4000.0, 24.5, 4600.0),   -- SiLambat Highway
	Vector3.new(1250.0, 24.5, -2400.0)    -- Loop Return
}

local LandmarkWaypoints = {
	["BCA Main Depot (Koper Spawn)"] = Vector3.new(1781.04, 22.22, -4615.77),
	["Menara BCA / Thamrin"] = Vector3.new(1250, 35, 1450),
	["MRT Blok M BCA Station"] = Vector3.new(-1500, 25, 2100),
	["Monas (Monumen Nasional)"] = Vector3.new(4848.864, 20.502, -7769.96),
	["GBK Stadium Senayan"] = Vector3.new(-2196.127, 23.245, 1482.061),
	["Plaza Senayan Mall"] = Vector3.new(-4141.175, 25.965, 3392.429),
	["Stasiun Gambir"] = Vector3.new(6502.558, 19.901, -7691.016),
	["Spark Senayan Mall"] = Vector3.new(-4016.842, 20.996, -486.268),
	["Mitra Terrace"] = Vector3.new(1348.83, 44.066, 1377.256),
	["SiLambat Logistics HQ"] = Vector3.new(-4023.717, 23.472, 4620.15),
	["Main Highway Toll Gate"] = Vector3.new(1250, 25, -2400),
	["Toyota Showroom"] = Vector3.new(2500, 25, -4500),
	["DIR Supercars"] = Vector3.new(1500, 25, -3900),
	["Porsche Center"] = Vector3.new(3400, 25, -5200)
}

------------------------------------------------
-- 🛡️ ANTI-SINK & DYNAMIC GROUND SAFETY PLATFORM
------------------------------------------------
local function ensureSafetyPlate(pos, size)
	local plate = workspace:FindFirstChild("__SafetyPlate")
	if not plate then
		plate = Instance.new("Part")
		plate.Name = "__SafetyPlate"
		plate.Anchored = true
		plate.CanCollide = true
		plate.Transparency = 1
		plate.Material = Enum.Material.SmoothPlastic
		plate.Color = Color3.fromRGB(0, 255, 128)
		plate.Parent = workspace
	end
	size = size or 45
	local groundY = pos.Y > 20 and (pos.Y - 1.0) or 21.5
	plate.Size = Vector3.new(size, 1, size)
	plate.CFrame = CFrame.new(pos.X, groundY, pos.Z)
	return plate
end

local function getSafeGroundCFrame(targetPos)
	local rayParams = RaycastParams.new()
	local car = getPlayerCar()
	local char = player.Character
	rayParams.FilterDescendantsInstances = { car, char, workspace:FindFirstChild("__SafetyPlate") }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local hit = workspace:Raycast(targetPos + Vector3.new(0, 15, 0), Vector3.new(0, -45, 0), rayParams)
	local groundY = hit and hit.Position.Y or (targetPos.Y > 20 and targetPos.Y or 22.5)
	local safeY = math.max(groundY + 2.0, 22.5)

	return CFrame.new(targetPos.X, safeY, targetPos.Z)
end

-- Background Anti-Sink & Anti-Bounce Guardian
task.spawn(function()
	while true do
		pcall(function()
			local car = getPlayerCar()
			if car and car.Parent then
				local seat = getDriveSeat(car)
				local char = player.Character
				local hum = char and char:FindFirstChild("Humanoid")
				if seat and hum and hum.Sit and hum.SeatPart == seat then
					local carPivot = car:GetPivot()
					-- If the car sunk into Map.Base.BAse (Y < 20.5), instantly rescue it to the surface!
					if carPivot.Position.Y < 20.5 then
						local safeCF = getSafeGroundCFrame(carPivot.Position)
						ensureSafetyPlate(safeCF.Position, 50)
						car:PivotTo(safeCF)
						for _, p in ipairs(car:GetDescendants()) do
							if p:IsA("BasePart") then
								p.AssemblyLinearVelocity = Vector3.zero
								p.AssemblyAngularVelocity = Vector3.zero
							end
						end
					end
				end
			end
		end)
		task.wait(0.2)
	end
end)

------------------------------------------------
-- 🚗 VEHICLE & DRIVER HELPERS
------------------------------------------------
local function getPlayerCar()
	local vehicles = workspace:FindFirstChild("Vehicles")
	if not vehicles then return nil end
	return vehicles:FindFirstChild(player.Name .. "sCar") or vehicles:FindFirstChild(player.Name .. "'s Car")
end

local function getDriveSeat(car)
	if not car then return nil end
	return car:FindFirstChild("DriveSeat")
		or car:FindFirstChildOfClass()
		or car:FindFirstChildOfClass()
end

local function enterDriveSeat(car)
	car = car or getPlayerCar()
	if not car then return false end

	-- Ensure vehicle is firmly placed on upper road surface before sitting
	local currentP = car:GetPivot().Position
	if currentP.Y < 21.0 then
		local safeCF = getSafeGroundCFrame(currentP)
		ensureSafetyPlate(safeCF.Position, 40)
		car:PivotTo(safeCF)
	else
		ensureSafetyPlate(currentP, 40)
	end

	local seat = getDriveSeat(car)
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not seat or not hum or not root then return false end

	if hum.Sit and hum.SeatPart == seat then
		return true
	end

	-- Trigger PromptDriveSeat
	local prompt = seat:FindFirstChild("PromptDriveSeat") or seat:FindFirstChildOfClass()
	if prompt then
		pcall(function()
			prompt.Enabled = true
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 40
			if fireproximityprompt then
				fireproximityprompt(prompt)
			elseif prompt.InputHoldBegin then
				prompt:InputHoldBegin()
				task.wait(0.05)
				prompt:InputHoldEnd()
			end
		end)
	end

	-- Fallback Engine Sit
	if not hum.Sit or hum.SeatPart ~= seat then
		pcall(function()
			root.CFrame = seat.CFrame + Vector3.new(0, 1.0, 0)
			seat:Sit(hum)
		end)
	end

	local t0 = os.clock()
	while (not hum.Sit or hum.SeatPart ~= seat) and os.clock() - t0 < 1.2 do
		task.wait(0.08)
	end

	return hum.Sit and hum.SeatPart == seat
end

local function exitDriveSeat()
	local car = getPlayerCar()
	if car then
		safelySettleAndUnanchor(car)
	end
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") and char.Humanoid.Sit then
		char.Humanoid.Sit = false
		pcall(function()
			char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
	if car then
		local p = car:GetPivot().Position
		ensureSafetyPlate(p, 50)
	end
end

------------------------------------------------
-- 🎨 STANDALONE GUI CREATION
------------------------------------------------
local parentGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HipHub_AutoDrive_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui
_G.HipHubAutoDriveInstance = screenGui

-- Main Card Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 360, 0, 480)
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 160, 255)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

-- Title Bar (Draggable)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -90, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🚗 HipHub AutoDrive"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 16
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(1, -90, 0, 14)
subTitle.Position = UDim2.new(0, 16, 0, 28)
subTitle.BackgroundTransparency = 1
subTitle.Text = "Highway & Odometer Farm Suite"
subTitle.TextColor3 = Color3.fromRGB(0, 180, 255)
subTitle.TextSize = 10
subTitle.Font = Enum.Font.GothamMedium
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.Parent = titleBar

-- Close Button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	isAutoDriving = false
	screenGui:Destroy()
	_G.HipHubAutoDriveInstance = nil
end)

-- Minimize Button (-)
local isMinimized = false
local minBtn = Instance.new("TextButton")
minBtn.Name = "MinButton"
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -72, 0, 10)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 70)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minBtn

minBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = isMinimized and UDim2.new(0, 360, 0, 48) or UDim2.new(0, 360, 0, 480)
	}):Play()
	minBtn.Text = isMinimized and "+" or "−"
end)

-- Make GUI Draggable
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Content ScrollFrame
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 54)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = Color3.fromRGB(0, 160, 255)
content.CanvasSize = UDim2.new(0, 0, 0, 520)
content.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

------------------------------------------------
-- 📟 TELEMETRY CARDS (Speed, Odo, Cash)
------------------------------------------------
local statsCard = Instance.new("Frame")
statsCard.Size = UDim2.new(1, 0, 0, 110)
statsCard.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
statsCard.Parent = content

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 10)
statsCorner.Parent = statsCard

local statsStroke = Instance.new("UIStroke")
statsStroke.Color = Color3.fromRGB(35, 45, 65)
statsStroke.Parent = statsCard

-- Speed Display
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.5, -10, 0, 36)
speedLabel.Position = UDim2.new(0, 12, 0, 8)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "0 km/h"
speedLabel.TextColor3 = Color3.fromRGB(0, 220, 130)
speedLabel.TextSize = 22
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = statsCard

local speedSub = Instance.new("TextLabel")
speedSub.Size = UDim2.new(0.5, -10, 0, 14)
speedSub.Position = UDim2.new(0, 12, 0, 42)
speedSub.BackgroundTransparency = 1
speedSub.Text = "SPEEDOMETER"
speedSub.TextColor3 = Color3.fromRGB(120, 135, 160)
speedSub.TextSize = 10
speedSub.Font = Enum.Font.GothamBold
speedSub.TextXAlignment = Enum.TextXAlignment.Left
speedSub.Parent = statsCard

-- Odometer (Distance) Display
local odoLabel = Instance.new("TextLabel")
odoLabel.Size = UDim2.new(0.5, -10, 0, 36)
odoLabel.Position = UDim2.new(0.5, 0, 0, 8)
odoLabel.BackgroundTransparency = 1
odoLabel.Text = "0.00 km"
odoLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
odoLabel.TextSize = 22
odoLabel.Font = Enum.Font.GothamBold
odoLabel.TextXAlignment = Enum.TextXAlignment.Left
odoLabel.Parent = statsCard

local odoSub = Instance.new("TextLabel")
odoSub.Size = UDim2.new(0.5, -10, 0, 14)
odoSub.Position = UDim2.new(0.5, 0, 0, 42)
odoSub.BackgroundTransparency = 1
odoSub.Text = "ODOMETER (FARMED)"
odoSub.TextColor3 = Color3.fromRGB(120, 135, 160)
odoSub.TextSize = 10
odoSub.Font = Enum.Font.GothamBold
odoSub.TextXAlignment = Enum.TextXAlignment.Left
odoSub.Parent = statsCard

-- Live Status & Earnings Footer
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 20)
statusLabel.Position = UDim2.new(0, 12, 0, 68)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle (Ready to Drive)"
statusLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statsCard

local earnLabel = Instance.new("TextLabel")
earnLabel.Size = UDim2.new(1, -24, 0, 16)
earnLabel.Position = UDim2.new(0, 12, 0, 88)
earnLabel.BackgroundTransparency = 1
earnLabel.Text = "Est. Earnings: Rp 0 | Rate: Rp 4M / 15 min"
earnLabel.TextColor3 = Color3.fromRGB(255, 205, 50)
earnLabel.TextSize = 10
earnLabel.Font = Enum.Font.GothamMedium
earnLabel.TextXAlignment = Enum.TextXAlignment.Left
earnLabel.Parent = statsCard

------------------------------------------------
-- 🚀 AUTO DRIVE TOGGLE BUTTON
------------------------------------------------
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 0, 46)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
toggleBtn.Text = "▶ START AUTO DRIVE"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 15
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = content

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10)
toggleCorner.Parent = toggleBtn

------------------------------------------------
-- ⚡ CRUISE SPEED CONTROLS
------------------------------------------------
local speedControlCard = Instance.new("Frame")
speedControlCard.Size = UDim2.new(1, 0, 0, 75)
speedControlCard.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
speedControlCard.Parent = content

local speedCtrlCorner = Instance.new("UICorner")
speedCtrlCorner.CornerRadius = UDim.new(0, 10)
speedCtrlCorner.Parent = speedControlCard

local speedCtrlTitle = Instance.new("TextLabel")
speedCtrlTitle.Size = UDim2.new(1, -20, 0, 20)
speedCtrlTitle.Position = UDim2.new(0, 10, 0, 8)
speedCtrlTitle.BackgroundTransparency = 1
speedCtrlTitle.Text = "Target Cruise Speed: 160 km/h"
speedCtrlTitle.TextColor3 = Color3.fromRGB(220, 230, 245)
speedCtrlTitle.TextSize = 12
speedCtrlTitle.Font = Enum.Font.GothamBold
speedCtrlTitle.TextXAlignment = Enum.TextXAlignment.Left
speedCtrlTitle.Parent = speedControlCard

local speedBtnContainer = Instance.new("Frame")
speedBtnContainer.Size = UDim2.new(1, -20, 0, 32)
speedBtnContainer.Position = UDim2.new(0, 10, 0, 34)
speedBtnContainer.BackgroundTransparency = 1
speedBtnContainer.Parent = speedControlCard

local speedOptions = { 100, 130, 160, 200, 240 }
for i, spd in ipairs(speedOptions) do
	local spdBtn = Instance.new("TextButton")
	spdBtn.Size = UDim2.new(0.18, 0, 1, 0)
	spdBtn.Position = UDim2.new((i - 1) * 0.205, 0, 0, 0)
	spdBtn.BackgroundColor3 = (targetCruiseSpeed == spd) and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(30, 37, 52)
	spdBtn.Text = tostring(spd)
	spdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	spdBtn.TextSize = 12
	spdBtn.Font = Enum.Font.GothamBold
	spdBtn.Parent = speedBtnContainer

	local spdCorner = Instance.new("UICorner")
	spdCorner.CornerRadius = UDim.new(0, 6)
	spdCorner.Parent = spdBtn

	spdBtn.MouseButton1Click:Connect(function()
		targetCruiseSpeed = spd
		speedCtrlTitle.Text = string.format("Target Cruise Speed: %d km/h", spd)
		for _, b in ipairs(speedBtnContainer:GetChildren()) do
			if b:IsA("TextButton") then
				b.BackgroundColor3 = (b.Text == tostring(spd)) and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(30, 37, 52)
			end
		end
	end)
end

------------------------------------------------
-- 🛣️ DRIVE MODE SELECTOR
------------------------------------------------
local modeCard = Instance.new("Frame")
modeCard.Size = UDim2.new(1, 0, 0, 80)
modeCard.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
modeCard.Parent = content

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 10)
modeCorner.Parent = modeCard

local modeTitle = Instance.new("TextLabel")
modeTitle.Size = UDim2.new(1, -20, 0, 20)
modeTitle.Position = UDim2.new(0, 10, 0, 8)
modeTitle.BackgroundTransparency = 1
modeTitle.Text = "Drive Mode"
modeTitle.TextColor3 = Color3.fromRGB(220, 230, 245)
modeTitle.TextSize = 12
modeTitle.Font = Enum.Font.GothamBold
modeTitle.TextXAlignment = Enum.TextXAlignment.Left
modeTitle.Parent = modeCard

local modeContainer = Instance.new("Frame")
modeContainer.Size = UDim2.new(1, -20, 0, 36)
modeContainer.Position = UDim2.new(0, 10, 0, 34)
modeContainer.BackgroundTransparency = 1
modeContainer.Parent = modeCard

local modes = {
	{ name = "Highway", label = "🛣️ Highway Loop" },
	{ name = "Waypoint", label = "📍 Waypoints" },
	{ name = "Cruise", label = "⚡ Free Cruise" }
}

for i, m in ipairs(modes) do
	local mBtn = Instance.new("TextButton")
	mBtn.Size = UDim2.new(0.31, 0, 1, 0)
	mBtn.Position = UDim2.new((i - 1) * 0.345, 0, 0, 0)
	mBtn.BackgroundColor3 = (currentDriveMode == m.name) and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(30, 37, 52)
	mBtn.Text = m.label
	mBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	mBtn.TextSize = 10
	mBtn.Font = Enum.Font.GothamBold
	mBtn.Parent = modeContainer

	local mCorner = Instance.new("UICorner")
	mCorner.CornerRadius = UDim.new(0, 6)
	mCorner.Parent = mBtn

	mBtn.MouseButton1Click:Connect(function()
		currentDriveMode = m.name
		for _, b in ipairs(modeContainer:GetChildren()) do
			if b:IsA("TextButton") then
				b.BackgroundColor3 = (b.Text == m.label) and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(30, 37, 52)
			end
		end
		statusLabel.Text = "Mode Switched: " .. m.label
	end)
end

local isSettling = false
local function safelySettleAndUnanchor(car)
	if not car or isSettling then return end
	isSettling = true
	pcall(function()
		local root = car.PrimaryPart or getDriveSeat(car)
		if root then
			local currentPos = root.Position
			local currentRot = car:GetPivot().Rotation
			local rayParams = RaycastParams.new()
			local mapBase = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Base")
			local safetyPlate = workspace:FindFirstChild("__SafetyPlate")
			rayParams.FilterDescendantsInstances = { car, player.Character, mapBase, safetyPlate }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local hit = workspace:Raycast(currentPos + Vector3.new(0, 15, 0), Vector3.new(0, -80, 0), rayParams)
			local surfaceY = hit and hit.Position.Y or (currentPos.Y > 21.0 and currentPos.Y or 22.2)
			local groundY = math.max(surfaceY + 2.2, 22.2)

			-- Create solid parking plate under the vehicle so it never sinks into Map.Base.BAse
			ensureSafetyPlate(Vector3.new(currentPos.X, groundY - 2.2, currentPos.Z), 50)

			-- Smooth gentle descent to ground level (over ~0.25s)
			local startY = currentPos.Y
			local tDown = os.clock()
			while os.clock() - tDown < 0.25 do
				local a = math.clamp((os.clock() - tDown) / 0.25, 0, 1)
				local easedA = -(math.cos(math.pi * a) - 1) / 2
				local curY = startY + (groundY - startY) * easedA
				car:PivotTo(CFrame.new(currentPos.X, curY, currentPos.Z) * currentRot)
				RunService.Heartbeat:Wait()
			end
			car:PivotTo(CFrame.new(currentPos.X, groundY, currentPos.Z) * currentRot)
		end

		-- Zero out velocities and unanchor smoothly
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				part.Anchored = false
			end
		end

		-- Restore wheel collision ONLY on outer wheels, NEVER on internal suspension parts (base, arm, weight)
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				local name = part.Name:lower()
				if name:find("wheel") or name == "fl" or name == "fr" or name == "rl" or name == "rr" then
					part.CanCollide = true
				elseif name == "base" or name:find("arm") or name:find("weight") or name:find("spindle") or name:find("hub") or name:find("steer") then
					part.CanCollide = false
				end
			end
		end

		-- Apply brakes on A-Chassis
		local pgui = player:FindFirstChild("PlayerGui")
		local aValues = pgui and pgui:FindFirstChild("A-Chassis Interface") and pgui["A-Chassis Interface"]:FindFirstChild("Values")
		if aValues then
			if aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 0 end
			if aValues:FindFirstChild("Brake") then aValues.Brake.Value = 1 end
			if aValues:FindFirstChild("PBrake") then aValues.PBrake.Value = true end
		end
		local seat = getDriveSeat(car)
		if seat and seat:IsA("VehicleSeat") then
			seat.Throttle = 0
			seat.ThrottleFloat = 0
		end
	end)
	isSettling = false
end

------------------------------------------------
-- 🛑 EMERGENCY BRAKE BUTTON
------------------------------------------------
local eBrakeBtn = Instance.new("TextButton")
eBrakeBtn.Size = UDim2.new(1, 0, 0, 36)
eBrakeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
eBrakeBtn.Text = "🛑 EMERGENCY BRAKE & STOP"
eBrakeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
eBrakeBtn.TextSize = 13
eBrakeBtn.Font = Enum.Font.GothamBold
eBrakeBtn.Parent = content

local eBrakeCorner = Instance.new("UICorner")
eBrakeCorner.CornerRadius = UDim.new(0, 8)
eBrakeCorner.Parent = eBrakeBtn

eBrakeBtn.MouseButton1Click:Connect(function()
	isAutoDriving = false
	toggleBtn.Text = "▶ START AUTO DRIVE"
	toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
	statusLabel.Text = "🛑 Emergency Brake Applied (Stopped)"

	local car = getPlayerCar()
	if car then
		safelySettleAndUnanchor(car)
	end
end)

------------------------------------------------
-- ⚙️ CORE AUTO DRIVE DRIVING LOOP
------------------------------------------------
toggleBtn.MouseButton1Click:Connect(function()
	isAutoDriving = not isAutoDriving

	if isAutoDriving then
		toggleBtn.Text = "⏹ STOP AUTO DRIVE"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		statusLabel.Text = "🚗 Initializing Driver Seat & Engine..."

		task.spawn(function()
			local car = getPlayerCar()
			if not car then
				statusLabel.Text = "⚠️ Please spawn a car first!"
				isAutoDriving = false
				toggleBtn.Text = "▶ START AUTO DRIVE"
				toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
				return
			end

			-- Enter Driver Seat
			enterDriveSeat(car)
			task.wait(0.3)

			local seat = getDriveSeat(car)
			if not seat then
				statusLabel.Text = "⚠️ Driver seat not found!"
				isAutoDriving = false
				return
			end

			while isAutoDriving do
				car = getPlayerCar() or car
				if not car or not car.Parent then break end

				-- Determine Next Destination Target Point
				local targetPos = nil
				if currentDriveMode == "Highway" then
					targetPos = HighwayLoopPoints[highwayIndex]
				elseif currentDriveMode == "Waypoint" then
					targetPos = activeWaypoint or HighwayLoopPoints[1]
				elseif currentDriveMode == "Cruise" then
					targetPos = car:GetPivot().Position + (car:GetPivot().LookVector * 500)
				end

				if not targetPos then break end

				local startCF = car:GetPivot()
				local startP = startCF.Position
				local destP = targetPos
				local dist = (startP - destP).Magnitude

				if dist < 30 then
					-- Reached waypoint, advance to next in loop
					if currentDriveMode == "Highway" then
						highwayIndex = (highwayIndex % #HighwayLoopPoints) + 1
					end
					task.wait(0.1)
				else
					-- Calculate safe cruise elevation (rises +12 studs to clear variable ground/hills cleanly)
					local cruiseAlt = math.max(startP.Y, destP.Y) + 12.0
					local speed = targetCruiseSpeed
					local duration = math.clamp(dist / speed, 0.5, 40.0)

					-- Engage A-Chassis throttle & handbrake
					local pgui = player:FindFirstChild("PlayerGui")
					local aChassisGui = pgui and pgui:FindFirstChild("A-Chassis Interface")
					local aValues = aChassisGui and aChassisGui:FindFirstChild("Values")
					if aChassisGui and aChassisGui:FindFirstChild("IsOn") then aChassisGui.IsOn.Value = true end
					if aValues then
						if aValues:FindFirstChild("PBrake") then aValues.PBrake.Value = false end
						if aValues:FindFirstChild("Brake") then aValues.Brake.Value = 0 end
						if aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 1 end
					end
					if seat:IsA("VehicleSeat") then
						seat.Throttle = 1
						seat.ThrottleFloat = 1
					end

					-- Ghost mode: Disable collision on body/wheels during travel to prevent wall compression flings
					local anchoredParts = {}
					for _, part in ipairs(car:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
							if not part.Anchored then
								table.insert(anchoredParts, part)
								part.Anchored = true
							end
						end
					end

					local t0 = os.clock()
					local conn
					local finished = false

					local rawDir = (destP - startP)
					local moveDir = rawDir.Magnitude > 0.1 and rawDir.Unit or Vector3.new(0, 0, -1)
					local flatLook = Vector3.new(moveDir.X, 0, moveDir.Z).Magnitude > 0.05 and Vector3.new(moveDir.X, 0, moveDir.Z).Unit or moveDir

					conn = RunService.Heartbeat:Connect(function()
						if not isAutoDriving then
							if conn then conn:Disconnect() end
							finished = true
							return
						end

						local elapsed = os.clock() - t0
						local alpha = math.clamp(elapsed / duration, 0, 1)

						-- 3-Phase Altitude Cruise: Rise up (+12 Y) -> Cruise -> Smooth landing descent
						local curX = startP.X + (destP.X - startP.X) * alpha
						local curZ = startP.Z + (destP.Z - startP.Z) * alpha
						local curY
						if alpha < 0.12 then
							-- Smooth lift-off
							local liftA = alpha / 0.12
							curY = startP.Y + (cruiseAlt - startP.Y) * liftA
						elseif alpha <= 0.88 then
							-- High altitude cruise
							curY = cruiseAlt
						else
							-- Gentle landing descent
							local landA = (alpha - 0.88) / 0.12
							curY = cruiseAlt + (destP.Y - cruiseAlt) * landA
						end
						local curPos = Vector3.new(curX, curY, curZ)

						local remainingDist = (destP - curPos).Magnitude
						statusLabel.Text = string.format("Cruising: %d km/h | Dest: %.0f stud", speed, remainingDist)

						local currentCF = CFrame.lookAt(curPos, curPos + flatLook)

						pcall(function()
							car:PivotTo(currentCF)

							-- Keep collision off during drive
							for _, part in ipairs(car:GetDescendants()) do
								if part:IsA("BasePart") then
									part.CanCollide = false
								end
							end

							-- Keep player seated
							local char = player.Character
							local hum = char and char:FindFirstChild("Humanoid")
							local root = char and char:FindFirstChild("HumanoidRootPart")
							if root and seat and (not hum or not hum.Sit or not hum.SeatPart) then
								root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
								if hum then hum.Sit = true; seat:Sit(hum) end
							end
						end)

						if alpha >= 1 then
							finished = true
							if conn then conn:Disconnect() end
						end
					end)

					while not finished and isAutoDriving do
						task.wait(0.02)
					end
					if conn then pcall(function() conn:Disconnect() end) end

					-- Settle & Unanchor smoothly on the road with clear collision restoration
					safelySettleAndUnanchor(car)

					if currentDriveMode == "Highway" then
						highwayIndex = (highwayIndex % #HighwayLoopPoints) + 1
					end
				end
				task.wait(0.05)
			end
		end)
	else
		toggleBtn.Text = "▶ START AUTO DRIVE"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
		statusLabel.Text = "Status: Idle (Stopped)"
		local car = getPlayerCar()
		if car then
			safelySettleAndUnanchor(car)
		end
	end
end)

------------------------------------------------
-- 📈 REAL-TIME TELEMETRY TRACKER (Speed & Odometer)
------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not screenGui or not screenGui.Parent then return end

	local car = getPlayerCar()
	if car then
		local curPos = car:GetPivot().Position
		if lastPosition then
			local delta = (curPos - lastPosition).Magnitude
			if delta > 0.05 and delta < 200 then
				totalDistanceTraveled = totalDistanceTraveled + delta
				estimatedEarnings = estimatedEarnings + (delta * 1.8) -- CDID distance payout estimate
			end
		end
		lastPosition = curPos

		-- Update Telemetry UI
		local km = totalDistanceTraveled / 3000 -- ~3000 studs per km in Roblox
		odoLabel.Text = string.format("%.2f km", km)
		earnLabel.Text = string.format("Est. Earnings: Rp %s | Distance: %.0f studs", tostring(math.floor(estimatedEarnings)), totalDistanceTraveled)

		local seat = getDriveSeat(car)
		if seat then
			local spd = math.floor(seat.AssemblyLinearVelocity.Magnitude * 1.2)
			speedLabel.Text = string.format("%d km/h", isAutoDriving and targetCruiseSpeed or spd)
		end
	end
end)

print("[HipHub] AutoDrive & Highway Farm Standalone GUI Loaded Successfully!")
