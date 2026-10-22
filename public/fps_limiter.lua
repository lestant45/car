--[[
    ═════════════════════════════════════════════════════════════════
    ⚡ HIPHUB — STANDALONE FPS LIMITER & BATTERY SAVER
    ═════════════════════════════════════════════════════════════════
    Features:
    • 1-Click FPS Caps: 5 FPS (AFK Ultra Saver), 15 FPS (Balanced), 60 FPS (Smooth)
    • Draggable Window (Supports PC Mouse & Redfinger / Android Touch)
    • Compact Minimize Pill Mode
    • Real-time Live FPS Monitor
    • 100% Compatible with All Executors (Solara, Wave, Codex, Delta, Fluxus, etc.)
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Cleanup previous instance
local guiName = "HipHub_FPSLimiter_GUI"
local targetParent = (gethui and gethui()) or (game:GetService("CoreGui")) or (player:WaitForChild("PlayerGui"))

pcall(function()
    local old = targetParent:FindFirstChild(guiName)
    if old then old:Destroy() end
    local oldP = player:WaitForChild("PlayerGui"):FindFirstChild(guiName)
    if oldP then oldP:Destroy() end
end)

-- State
local currentCap = 60
local isMinimized = false

local function setCap(fps)
    currentCap = fps
    if setfpscap then
        pcall(setfpscap, fps)
    elseif set_fps_cap then
        pcall(set_fps_cap, fps)
    end
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = targetParent

-- Colors & Styling
local C = {
    bg = Color3.fromRGB(15, 18, 26),
    header = Color3.fromRGB(22, 27, 40),
    accent = Color3.fromRGB(0, 220, 255),
    accentActive = Color3.fromRGB(0, 255, 170),
    text = Color3.fromRGB(240, 245, 255),
    textMuted = Color3.fromRGB(130, 145, 170),
    btnBg = Color3.fromRGB(26, 32, 48),
    btnBorder = Color3.fromRGB(40, 50, 75),
    btnActiveBg = Color3.fromRGB(18, 45, 60),
    btnActiveBorder = Color3.fromRGB(0, 220, 255),
    danger = Color3.fromRGB(255, 80, 80)
}

-- Main Window Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 240, 0, 138)
mainFrame.Position = UDim2.new(0.5, -120, 0.2, 0)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = C.btnBorder
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

-- Header Bar (Draggable Area)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = C.header
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

-- Fix bottom corners of header
local headerFiller = Instance.new("Frame")
headerFiller.Size = UDim2.new(1, 0, 0, 8)
headerFiller.Position = UDim2.new(0, 0, 1, -8)
headerFiller.BackgroundColor3 = C.header
headerFiller.BorderSizePixel = 0
headerFiller.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ HIPHUB FPS CAP"
title.TextColor3 = C.accent
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Window Controls (Minimize & Close)
local minBtn = Instance.new("TextButton")
minBtn.Name = "MinBtn"
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -52, 0.5, -11)
minBtn.BackgroundColor3 = C.btnBg
minBtn.Text = "-"
minBtn.TextColor3 = C.text
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.Parent = header
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -26, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 25)
closeBtn.Text = "X"
closeBtn.TextColor3 = C.danger
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.Parent = header
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Live FPS & Status Bar
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -20, 0, 22)
statusBar.Position = UDim2.new(0, 10, 0, 38)
statusBar.BackgroundTransparency = 1
statusBar.Parent = mainFrame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPSLabel"
fpsLabel.Size = UDim2.new(0.6, 0, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "Live: -- FPS"
fpsLabel.TextColor3 = C.text
fpsLabel.Font = Enum.Font.GothamMedium
fpsLabel.TextSize = 11
fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
fpsLabel.Parent = statusBar

local capIndicator = Instance.new("TextLabel")
capIndicator.Name = "CapIndicator"
capIndicator.Size = UDim2.new(0.4, 0, 1, 0)
capIndicator.Position = UDim2.new(0.6, 0, 0, 0)
capIndicator.BackgroundTransparency = 1
capIndicator.Text = "Cap: 60 FPS"
capIndicator.TextColor3 = C.accentActive
capIndicator.Font = Enum.Font.GothamBold
capIndicator.TextSize = 11
capIndicator.TextXAlignment = Enum.TextXAlignment.Right
capIndicator.Parent = statusBar

-- Button Container
local btnContainer = Instance.new("Frame")
btnContainer.Name = "BtnContainer"
btnContainer.Size = UDim2.new(1, -20, 0, 38)
btnContainer.Position = UDim2.new(0, 10, 0, 66)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = mainFrame

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Padding = UDim.new(0, 8)
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
btnLayout.Parent = btnContainer

-- Sub Note (AFK Tip)
local tipLabel = Instance.new("TextLabel")
tipLabel.Name = "TipLabel"
tipLabel.Size = UDim2.new(1, -20, 0, 20)
tipLabel.Position = UDim2.new(0, 10, 0, 110)
tipLabel.BackgroundTransparency = 1
tipLabel.Text = "5 FPS: Ultra Hemat RAM & Baterai Redfinger"
tipLabel.TextColor3 = C.textMuted
tipLabel.Font = Enum.Font.Gotham
tipLabel.TextSize = 9.5
tipLabel.TextXAlignment = Enum.TextXAlignment.Center
tipLabel.Parent = mainFrame

-- Button Creation Helper
local buttons = {}
local btnCaps = { 5, 15, 60 }

local function updateButtonStyles()
    capIndicator.Text = "Cap: " .. tostring(currentCap) .. " FPS"
    for fps, btnData in pairs(buttons) do
        local isActive = (fps == currentCap)
        btnData.btn.BackgroundColor3 = isActive and C.btnActiveBg or C.btnBg
        btnData.btn.TextColor3 = isActive and C.accent or C.text
        btnData.stroke.Color = isActive and C.btnActiveBorder or C.btnBorder
        btnData.stroke.Thickness = isActive and 1.4 or 1.0
    end
    if currentCap == 5 then
        tipLabel.Text = "5 FPS: Mode Ekstrem Hemat RAM (Redfinger/AFK)"
        capIndicator.TextColor3 = Color3.fromRGB(255, 120, 120)
    elseif currentCap == 15 then
        tipLabel.Text = "15 FPS: Mode Hemat Seimbang (Background AFK)"
        capIndicator.TextColor3 = Color3.fromRGB(255, 200, 80)
    else
        tipLabel.Text = "60 FPS: Mode Normal & Smooth Gameplay"
        capIndicator.TextColor3 = C.accentActive
    end
end

for i, fps in ipairs(btnCaps) do
    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. tostring(fps)
    btn.Size = UDim2.new(0, 68, 0, 36)
    btn.BackgroundColor3 = C.btnBg
    btn.BorderSizePixel = 0
    btn.Text = tostring(fps) .. " FPS"
    btn.TextColor3 = C.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.LayoutOrder = i
    btn.Parent = btnContainer

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 8)
    bCorner.Parent = btn

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = C.btnBorder
    bStroke.Thickness = 1.0
    bStroke.Parent = btn

    buttons[fps] = { btn = btn, stroke = bStroke }

    btn.MouseButton1Click:Connect(function()
        setCap(fps)
        updateButtonStyles()
    end)
end

-- Initialize Style
updateButtonStyles()

-- Minimize / Expand Toggle
local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame.Size = UDim2.new(0, 130, 0, 32)
        statusBar.Visible = false
        btnContainer.Visible = false
        tipLabel.Visible = false
        title.Text = "⚡ " .. tostring(currentCap) .. " FPS"
        title.Size = UDim2.new(1, -34, 1, 0)
        minBtn.Text = "+"
        closeBtn.Visible = false
    else
        mainFrame.Size = UDim2.new(0, 240, 0, 138)
        statusBar.Visible = true
        btnContainer.Visible = true
        tipLabel.Visible = true
        title.Text = "⚡ HIPHUB FPS CAP"
        title.Size = UDim2.new(1, -70, 1, 0)
        minBtn.Text = "-"
        closeBtn.Visible = true
    end
end

minBtn.MouseButton1Click:Connect(toggleMinimize)

-- Clicking the header while minimized also restores the window
header.InputBegan:Connect(function(input)
    if isMinimized and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        toggleMinimize()
    end
end)

-- Close Button (Cleans up & restores 60 FPS)
closeBtn.MouseButton1Click:Connect(function()
    setCap(60)
    screenGui:Destroy()
end)

-- Smooth Draggable Mechanism (PC Mouse & Mobile Touch Ready)
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Real-time FPS Calculation Loop
local frameCount = 0
local lastFpsUpdate = os.clock()

RunService.RenderStepped:Connect(function(dt)
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastFpsUpdate >= 0.5 then
        local realFps = math.floor(frameCount / (now - lastFpsUpdate))
        frameCount = 0
        lastFpsUpdate = now

        if not isMinimized then
            fpsLabel.Text = "Live: " .. tostring(realFps) .. " FPS"
            if realFps <= 7 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
            elseif realFps <= 20 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
            else
                fpsLabel.TextColor3 = C.text
            end
        else
            title.Text = "⚡ " .. tostring(realFps) .. " / " .. tostring(currentCap) .. " FPS"
        end
    end
end)

-- Initial Cap set to 60 FPS
setCap(60)
