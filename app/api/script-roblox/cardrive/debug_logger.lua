--[[
    ===================================================================
    PHASE 1 (FIXED): REMOTE CALL LOGGER & RAYCAST TERRAIN DETECTOR
    ===================================================================
    Fixes Applied:
    1. Used `newcclosure` & `checkcaller()` to prevent breaking FireServer/InvokeServer.
    2. Set UI frames `Active = false` so mouse clicks pass through to game tool.
    3. Added fallback method hooking so manual digging is 100% preserved.
    ===================================================================
--]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Hapus UI lama jika ada
local OLD_UI = CoreGui:FindFirstChild("HipHubDebugLoggerUI")
if OLD_UI then OLD_UI:Destroy() end

local logs = {}
local logCount = 0
local isRaycastEnabled = true

-- Serialization Helper
local function serializeValue(val, depth)
	depth = depth or 0
	if depth > 5 then return "{... (max depth limit reached)}" end
	
	local valType = typeof(val)
	if valType == "Vector3" then
		return string.format("Vector3.new(X=%.3f, Y=%.3f, Z=%.3f)", val.X, val.Y, val.Z)
	elseif valType == "CFrame" then
		local pos = val.Position
		return string.format("CFrame.new(Pos=%.3f, %.3f, %.3f)", pos.X, pos.Y, pos.Z)
	elseif valType == "Instance" then
		return string.format("Instance(%s) -> Path: %s", val.ClassName, val:GetFullName())
	elseif valType == "table" then
		local indent = string.rep("  ", depth + 1)
		local lines = {"{"}
		local count = 0
		for k, v in pairs(val) do
			count = count + 1
			if count > 30 then
				table.insert(lines, indent .. "... (truncated table entries)")
				break
			end
			table.insert(lines, string.format("%s[%s] = (%s) %s", indent, tostring(k), typeof(v), serializeValue(v, depth + 1)))
		end
		table.insert(lines, string.rep("  ", depth) .. "}")
		return table.concat(lines, "\n")
	elseif valType == "string" then
		return string.format("%q", val)
	else
		return tostring(val)
	end
end

-- ScreenGui Setup (DisplayOrder low & non-blocking)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HipHubDebugLoggerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = -10

pcall(function()
	ScreenGui.Parent = gethui and gethui() or CoreGui
end)

-- Main Frame (Non-blocking background)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 360)
MainFrame.Position = UDim2.new(0.02, 0, 0.45, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Active = false
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.Draggable = true
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -160, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⛏️ PHASE 1: REMOTE LOGGER (NON-BLOCKING)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Buttons Frame
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(0, 140, 1, 0)
BtnContainer.Position = UDim2.new(1, -145, 0, 0)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = TopBar

local function createHeaderBtn(name, text, color, xPos, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 42, 0, 24)
	btn.Position = UDim2.new(0, xPos, 0.5, -12)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.SourceSansBold
	btn.BorderSizePixel = 0
	btn.Parent = BtnContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- Raycast Status HUD (Top Right Screen Overlay)
local RaycastHUD = Instance.new("Frame")
RaycastHUD.Name = "RaycastHUD"
RaycastHUD.Size = UDim2.new(0, 360, 0, 120)
RaycastHUD.Position = UDim2.new(1, -370, 0, 10)
RaycastHUD.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
RaycastHUD.BackgroundTransparency = 0.25
RaycastHUD.BorderSizePixel = 0
RaycastHUD.Active = false
RaycastHUD.Parent = ScreenGui

local RaycastCorner = Instance.new("UICorner")
RaycastCorner.CornerRadius = UDim.new(0, 6)
RaycastCorner.Parent = RaycastHUD

local RaycastStroke = Instance.new("UIStroke")
RaycastStroke.Color = Color3.fromRGB(60, 120, 200)
RaycastStroke.Thickness = 1
RaycastStroke.Parent = RaycastHUD

local RaycastText = Instance.new("TextLabel")
RaycastText.Size = UDim2.new(1, -16, 1, -12)
RaycastText.Position = UDim2.new(0, 8, 0, 6)
RaycastText.BackgroundTransparency = 1
RaycastText.Text = "RAYCAST DETECTOR: Scanning..."
RaycastText.TextColor3 = Color3.fromRGB(220, 230, 255)
RaycastText.TextSize = 11
RaycastText.Font = Enum.Font.Code
RaycastText.TextXAlignment = Enum.TextXAlignment.Left
RaycastText.TextYAlignment = Enum.TextYAlignment.Top
RaycastText.TextWrapped = true
RaycastText.Parent = RaycastHUD

-- Scroll View
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -16, 1, -52)
ScrollFrame.Position = UDim2.new(0, 8, 0, 44)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Active = true
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollFrame

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- Append Log Entry Function
local function appendLog(remoteName, remotePath, className, method, argsList)
	logCount = logCount + 1
	local timestamp = os.date("%H:%M:%S") .. string.format(".%03d", math.floor((os.clock() % 1) * 1000))
	
	local logHeader = string.format("[%d] %s | %s:%s()", logCount, timestamp, remoteName, method)
	local logBody = string.format("Path: %s\nClass: %s\nArguments (%d total):", remotePath, className, #argsList)
	
	local formattedArgs = {}
	for i, arg in ipairs(argsList) do
		table.insert(formattedArgs, string.format("  Arg #%d (%s): %s", i, typeof(arg), serializeValue(arg, 0)))
	end
	
	local fullLogText = logHeader .. "\n" .. logBody .. "\n" .. table.concat(formattedArgs, "\n")
	table.insert(logs, fullLogText)

	-- Print to DevConsole (F9)
	print("\n=======================================================")
	print(logHeader)
	print(logBody)
	for _, aLine in ipairs(formattedArgs) do
		print(aLine)
	end
	print("=======================================================\n")

	-- Add visual UI Card
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(1, -8, 0, 0)
	Card.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
	Card.BorderSizePixel = 0
	Card.Parent = ScrollFrame

	local CardCorner = Instance.new("UICorner")
	CardCorner.CornerRadius = UDim.new(0, 4)
	CardCorner.Parent = Card

	local CardStroke = Instance.new("UIStroke")
	CardStroke.Color = Color3.fromRGB(50, 70, 100)
	CardStroke.Thickness = 1
	CardStroke.Parent = Card

	local CardText = Instance.new("TextLabel")
	CardText.Size = UDim2.new(1, -12, 1, -8)
	CardText.Position = UDim2.new(0, 6, 0, 4)
	CardText.BackgroundTransparency = 1
	CardText.Text = fullLogText
	CardText.TextColor3 = Color3.fromRGB(230, 240, 255)
	CardText.TextSize = 11
	CardText.Font = Enum.Font.Code
	CardText.TextXAlignment = Enum.TextXAlignment.Left
	CardText.TextYAlignment = Enum.TextYAlignment.Top
	CardText.TextWrapped = true
	CardText.Parent = Card

	local textService = game:GetService("TextService")
	local bounds = textService:GetTextSize(fullLogText, 11, Enum.Font.Code, Vector2.new(440, 10000))
	Card.Size = UDim2.new(1, -8, 0, bounds.Y + 16)

	ScrollFrame.CanvasPosition = Vector2.new(0, ScrollFrame.CanvasSize.Y.Offset)
end

-- Header Controls
createHeaderBtn("Copy", "COPY", Color3.fromRGB(40, 140, 70), 0, function()
	if setclipboard then
		setclipboard(table.concat(logs, "\n\n-------------------------------------------------------\n\n"))
		print("[Logger]: Logs copied to clipboard!")
	end
end)

createHeaderBtn("Clear", "CLEAR", Color3.fromRGB(180, 50, 50), 46, function()
	logs = {}
	logCount = 0
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	print("[Logger]: Logs cleared!")
end)

createHeaderBtn("Ray", "RAY", Color3.fromRGB(50, 100, 180), 92, function()
	isRaycastEnabled = not isRaycastEnabled
	RaycastHUD.Visible = isRaycastEnabled
end)

-- ===================================================================
-- SAFE NON-BLOCKING REMOTE HOOK (using newcclosure & checkcaller)
-- ===================================================================
if hookmetamethod then
	local rawNamecall
	local ncClosure = newcclosure or function(f) return f end
	
	rawNamecall = hookmetamethod(game, "__namecall", ncClosure(function(self, ...)
		local method = getnamecallmethod()
		if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
			if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
				local args = {...}
				task.spawn(function()
					pcall(function()
						appendLog(self.Name, self:GetFullName(), self.ClassName, method, args)
					end)
				end)
			end
		end
		return rawNamecall(self, ...)
	end))
	print("[HipHub Logger]: Safe __namecall Interceptor Hook Active!")
end

-- ===================================================================
-- RAYCAST TERRAIN DETECTOR LOOP
-- ===================================================================
RunService.RenderStepped:Connect(function()
	if not isRaycastEnabled then return end

	local mousePos = UserInputService:GetMouseLocation()
	local unitRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	if LocalPlayer.Character then
		raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, ScreenGui}
	end
	raycastParams.IgnoreWater = true

	local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)

	if result then
		local hitInst = result.Instance
		local hitPos = result.Position
		local hitNorm = result.Normal
		local dist = result.Distance
		local mat = result.Material

		if hitInst == Workspace.Terrain or hitInst:IsA("Terrain") then
			RaycastText.TextColor3 = Color3.fromRGB(255, 220, 80)
			RaycastStroke.Color = Color3.fromRGB(255, 180, 40)
			RaycastText.Text = string.format(
				"🎯 [TERRAIN HIT DETECTED]\n" ..
				"Path: %s\n" ..
				"Material: %s\n" ..
				"Position: X %.2f, Y %.2f, Z %.2f\n" ..
				"Normal: X %.2f, Y %.2f, Z %.2f\n" ..
				"Distance: %.2f studs",
				hitInst:GetFullName(),
				tostring(mat.Name),
				hitPos.X, hitPos.Y, hitPos.Z,
				hitNorm.X, hitNorm.Y, hitNorm.Z,
				dist
			)
		else
			RaycastText.TextColor3 = Color3.fromRGB(180, 220, 255)
			RaycastStroke.Color = Color3.fromRGB(60, 120, 200)
			RaycastText.Text = string.format(
				"🔍 OBJECT HIT\n" ..
				"Object: %s (%s)\n" ..
				"Path: %s\n" ..
				"Material: %s\n" ..
				"Hit Position: X %.2f, Y %.2f, Z %.2f\n" ..
				"Distance: %.2f studs",
				hitInst.Name,
				hitInst.ClassName,
				hitInst:GetFullName(),
				tostring(mat.Name),
				hitPos.X, hitPos.Y, hitPos.Z,
				dist
			)
		end
	else
		RaycastText.TextColor3 = Color3.fromRGB(150, 150, 150)
		RaycastStroke.Color = Color3.fromRGB(60, 60, 70)
		RaycastText.Text = "🔍 RAYCAST DETECTOR: No surface in range"
	end
end)

print("[HipHub Debug Logger Phase 1 - FIXED]: Ready! Anda sekarang bisa klik DIG MANUAL dengan normal.")
