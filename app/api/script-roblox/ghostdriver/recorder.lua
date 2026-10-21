-- 🛣️ HipHub Ghost Driver — Highway Dual-Lane Path Recorder
-- Purpose: Records high-density Left Lane and Right Lane coordinates
-- Data is stored in _G.HipHub_RecordedLanes, clipboard, and workspace file

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- Initialize Global Storage
_G.HipHub_RecordedLanes = _G.HipHub_RecordedLanes or {
	left = {},
	right = {}
}

local recordingMode = "NONE" -- "LEFT", "RIGHT", "NONE"
local RECORD_INTERVAL_STUDS = 12.0 -- Record 1 point every 12 studs of vehicle movement
local lastLeftPos = nil
local lastRightPos = nil

-- Helper to get vehicle seat position
local function getCarPosition()
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart and hum.SeatPart.Parent then
		return hum.SeatPart.Position
	end
	if char:FindFirstChild("HumanoidRootPart") then
		return char.HumanoidRootPart.Position
	end
	return nil
end

-- Clean previous GUI if exists
local existing = (gethui and gethui():FindFirstChild("HipHub_LaneRecorder")) or player.PlayerGui:FindFirstChild("HipHub_LaneRecorder")
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HipHub_LaneRecorder"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")

-- Main Draggable Frame
local frame = Instance.new("Frame")
frame.Name = "RecorderFrame"
frame.Size = UDim2.new(0, 320, 0, 260)
frame.Position = UDim2.new(0.02, 0, 0.35, 0)
frame.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(45, 120, 255)
stroke.Thickness = 1.2
stroke.Parent = frame

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Text = "🛣️ HIGHWAY LANE RECORDER"
title.TextColor3 = Color3.fromRGB(240, 245, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Live Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 22)
statusLabel.Position = UDim2.new(0, 10, 0, 36)
statusLabel.BackgroundTransparency = 0.4
statusLabel.BackgroundColor3 = Color3.fromRGB(25, 30, 48)
statusLabel.Text = "STATUS: STANDBY (IDLE)"
statusLabel.TextColor3 = Color3.fromRGB(180, 195, 220)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 11
statusLabel.Parent = frame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

-- Counter Stats
local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(1, -20, 0, 24)
counterLabel.Position = UDim2.new(0, 10, 0, 62)
counterLabel.BackgroundTransparency = 1
counterLabel.Text = "Left Lane: 0 pts  |  Right Lane: 0 pts"
counterLabel.TextColor3 = Color3.fromRGB(0, 230, 255)
counterLabel.Font = Enum.Font.GothamBold
counterLabel.TextSize = 12
counterLabel.Parent = frame

local function updateCounterDisplay()
	local lCount = #_G.HipHub_RecordedLanes.left
	local rCount = #_G.HipHub_RecordedLanes.right
	counterLabel.Text = string.format("Left Lane: %d pts  |  Right Lane: %d pts", lCount, rCount)
end
updateCounterDisplay()

-- Helper function to make buttons
local function createBtn(text, color, posY, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 30)
	btn.Position = UDim2.new(0, 10, 0, posY)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.AutoButtonColor = true
	btn.Parent = frame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.Activated:Connect(onClick)
	return btn
end

-- Buttons
createBtn("🔴 RECORD LAJUR KIRI (LEFT)", Color3.fromRGB(180, 40, 60), 92, function()
	recordingMode = "LEFT"
	statusLabel.Text = "STATUS: 🔴 RECORDING LEFT LANE..."
	statusLabel.TextColor3 = Color3.fromRGB(255, 100, 120)
	lastLeftPos = getCarPosition()
	if lastLeftPos then
		table.insert(_G.HipHub_RecordedLanes.left, {
			x = math.floor(lastLeftPos.X * 10) / 10,
			y = math.floor(lastLeftPos.Y * 10) / 10,
			z = math.floor(lastLeftPos.Z * 10) / 10
		})
		updateCounterDisplay()
	end
end)

createBtn("🔵 RECORD LAJUR KANAN (RIGHT)", Color3.fromRGB(30, 110, 220), 126, function()
	recordingMode = "RIGHT"
	statusLabel.Text = "STATUS: 🔵 RECORDING RIGHT LANE..."
	statusLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
	lastRightPos = getCarPosition()
	if lastRightPos then
		table.insert(_G.HipHub_RecordedLanes.right, {
			x = math.floor(lastRightPos.X * 10) / 10,
			y = math.floor(lastRightPos.Y * 10) / 10,
			z = math.floor(lastRightPos.Z * 10) / 10
		})
		updateCounterDisplay()
	end
end)

createBtn("⏹️ STOP RECORDING (PAUSE)", Color3.fromRGB(80, 85, 100), 160, function()
	recordingMode = "NONE"
	statusLabel.Text = "STATUS: ⏹️ PAUSED / STANDBY"
	statusLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
end)

createBtn("📋 EXPORT / COPY DATA", Color3.fromRGB(35, 140, 85), 194, function()
	recordingMode = "NONE"
	statusLabel.Text = "STATUS: SAVING & COPYING..."
	local exportData = {
		totalLeft = #_G.HipHub_RecordedLanes.left,
		totalRight = #_G.HipHub_RecordedLanes.right,
		lanes = _G.HipHub_RecordedLanes
	}
	local json = HttpService:JSONEncode(exportData)
	
	if setclipboard then
		setclipboard(json)
	end
	if writefile then
		pcall(function()
			writefile("hiphub_ghostdriver_lanes.json", json)
		end)
	end

	statusLabel.Text = "STATUS: ✅ COPIED TO CLIPBOARD!"
	statusLabel.TextColor3 = Color3.fromRGB(80, 255, 160)
	task.delay(3, function()
		if recordingMode == "NONE" then
			statusLabel.Text = "STATUS: STANDBY (IDLE)"
			statusLabel.TextColor3 = Color3.fromRGB(180, 195, 220)
		end
	end)
end)

-- Clear Data Button
local btnClear = Instance.new("TextButton")
btnClear.Size = UDim2.new(1, -20, 0, 22)
btnClear.Position = UDim2.new(0, 10, 0, 228)
btnClear.BackgroundColor3 = Color3.fromRGB(40, 20, 25)
btnClear.BackgroundTransparency = 0.3
btnClear.Text = "🗑️ Reset / Clear All Points"
btnClear.TextColor3 = Color3.fromRGB(255, 120, 120)
btnClear.Font = Enum.Font.Gotham
btnClear.TextSize = 10
btnClear.Parent = frame

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 4)
clearCorner.Parent = btnClear

btnClear.Activated:Connect(function()
	recordingMode = "NONE"
	_G.HipHub_RecordedLanes = { left = {}, right = {} }
	updateCounterDisplay()
	statusLabel.Text = "STATUS: DATA CLEARED"
	statusLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
end)

-- Background Tracking Loop (Distance-based sampling)
RunService.Heartbeat:Connect(function()
	if recordingMode == "NONE" then return end

	local currentPos = getCarPosition()
	if not currentPos then return end

	if recordingMode == "LEFT" then
		if not lastLeftPos or (currentPos - lastLeftPos).Magnitude >= RECORD_INTERVAL_STUDS then
			lastLeftPos = currentPos
			table.insert(_G.HipHub_RecordedLanes.left, {
				x = math.floor(currentPos.X * 10) / 10,
				y = math.floor(currentPos.Y * 10) / 10,
				z = math.floor(currentPos.Z * 10) / 10
			})
			updateCounterDisplay()
		end
	elseif recordingMode == "RIGHT" then
		if not lastRightPos or (currentPos - lastRightPos).Magnitude >= RECORD_INTERVAL_STUDS then
			lastRightPos = currentPos
			table.insert(_G.HipHub_RecordedLanes.right, {
				x = math.floor(currentPos.X * 10) / 10,
				y = math.floor(currentPos.Y * 10) / 10,
				z = math.floor(currentPos.Z * 10) / 10
			})
			updateCounterDisplay()
		end
	end
end)

print("[HipHub] Highway Lane Recorder Loaded Successfully!")
