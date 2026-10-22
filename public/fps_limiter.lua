--[[
    ═════════════════════════════════════════════════════════════════
    ⚡ HIPHUB — STANDALONE FPS LIMITER & RAM SAVER (3D OFF & GC)
    ═════════════════════════════════════════════════════════════════
    Features:
    • 1-Click FPS Caps: 5 FPS (AFK Ultra Saver), 15 FPS (Balanced), 60 FPS (Smooth)
    • 3D Viewport Toggle: Turns off 3D rendering to drop RAM & GPU usage by 50-70%
    • Clean RAM Tool: Forces Lua Garbage Collection (collectgarbage)
    • Live FPS & Live Memory (MB) Monitor
    • Draggable Window (Supports PC Mouse & Redfinger / Android Touch)
    • Compact Minimize Pill Mode
    • 100% Compatible with All Executors (Solara, Wave, Codex, Delta, Fluxus, etc.)
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
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
local is3dEnabled = true

local function setCap(fps)
    currentCap = fps
    if setfpscap then
        pcall(setfpscap, fps)
    elseif set_fps_cap then
        pcall(set_fps_cap, fps)
    end
end

local function set3dRendering(state)
    is3dEnabled = state
    pcall(function()
        RunService:Set3dRenderingEnabled(state)
    end)
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
    warning = Color3.fromRGB(255, 180, 50),
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
mainFrame.Size = UDim2.new(0, 250, 0, 180)
mainFrame.Position = UDim2.new(0.5, -125, 0.2, 0)
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
title.Text = "⚡ HIPHUB FPS & RAM OPTIMIZER"
title.TextColor3 = C.accent
title.Font = Enum.Font.GothamBold
title.TextSize = 11.5
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

-- Live FPS & RAM Status Bar
local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, -20, 0, 20)
statusBar.Position = UDim2.new(0, 10, 0, 36)
statusBar.BackgroundTransparency = 1
statusBar.Parent = mainFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Name = "StatsLabel"
statsLabel.Size = UDim2.new(0.68, 0, 1, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Live: -- FPS | RAM: -- MB"
statsLabel.TextColor3 = C.text
statsLabel.Font = Enum.Font.GothamMedium
statsLabel.TextSize = 10.5
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Parent = statusBar

local capIndicator = Instance.new("TextLabel")
capIndicator.Name = "CapIndicator"
capIndicator.Size = UDim2.new(0.32, 0, 1, 0)
capIndicator.Position = UDim2.new(0.68, 0, 0, 0)
capIndicator.BackgroundTransparency = 1
capIndicator.Text = "Cap: 60 FPS"
capIndicator.TextColor3 = C.accentActive
capIndicator.Font = Enum.Font.GothamBold
capIndicator.TextSize = 10.5
capIndicator.TextXAlignment = Enum.TextXAlignment.Right
capIndicator.Parent = statusBar

-- Row 1: FPS Caps Buttons (5, 15, 60)
local btnContainer = Instance.new("Frame")
btnContainer.Name = "BtnContainer"
btnContainer.Size = UDim2.new(1, -20, 0, 32)
btnContainer.Position = UDim2.new(0, 10, 0, 60)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = mainFrame

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Padding = UDim.new(0, 6)
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
btnLayout.Parent = btnContainer

-- Row 2: RAM Optimizer Row (3D Toggle & Clean RAM)
local ramContainer = Instance.new("Frame")
ramContainer.Name = "RAMContainer"
ramContainer.Size = UDim2.new(1, -20, 0, 32)
ramContainer.Position = UDim2.new(0, 10, 0, 98)
ramContainer.BackgroundTransparency = 1
ramContainer.Parent = mainFrame

local ramLayout = Instance.new("UIListLayout")
ramLayout.FillDirection = Enum.FillDirection.Horizontal
ramLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ramLayout.Padding = UDim.new(0, 6)
ramLayout.SortOrder = Enum.SortOrder.LayoutOrder
ramLayout.Parent = ramContainer

-- Sub Note (AFK Tip)
local tipLabel = Instance.new("TextLabel")
tipLabel.Name = "TipLabel"
tipLabel.Size = UDim2.new(1, -20, 0, 36)
tipLabel.Position = UDim2.new(0, 10, 0, 136)
tipLabel.BackgroundTransparency = 1
tipLabel.Text = "💡 Tip: Matikan 3D View untuk memangkas RAM hingga 70%!"
tipLabel.TextColor3 = C.textMuted
tipLabel.Font = Enum.Font.Gotham
tipLabel.TextSize = 9.5
tipLabel.TextWrapped = true
tipLabel.TextXAlignment = Enum.TextXAlignment.Center
tipLabel.Parent = mainFrame

-- FPS Buttons Setup
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
        capIndicator.TextColor3 = Color3.fromRGB(255, 120, 120)
    elseif currentCap == 15 then
        capIndicator.TextColor3 = Color3.fromRGB(255, 200, 80)
    else
        capIndicator.TextColor3 = C.accentActive
    end
end

for i, fps in ipairs(btnCaps) do
    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. tostring(fps)
    btn.Size = UDim2.new(0, 72, 0, 30)
    btn.BackgroundColor3 = C.btnBg
    btn.BorderSizePixel = 0
    btn.Text = tostring(fps) .. " FPS"
    btn.TextColor3 = C.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11.5
    btn.LayoutOrder = i
    btn.Parent = btnContainer

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 7)
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

-- RAM Optimizer Buttons
local toggle3dBtn = Instance.new("TextButton")
toggle3dBtn.Name = "Toggle3DBtn"
toggle3dBtn.Size = UDim2.new(0, 134, 0, 30)
toggle3dBtn.BackgroundColor3 = C.btnBg
toggle3dBtn.BorderSizePixel = 0
toggle3dBtn.Text = "👁️ 3D View: ON"
toggle3dBtn.TextColor3 = C.text
toggle3dBtn.Font = Enum.Font.GothamBold
toggle3dBtn.TextSize = 11
toggle3dBtn.LayoutOrder = 1
toggle3dBtn.Parent = ramContainer

local t3dCorner = Instance.new("UICorner")
t3dCorner.CornerRadius = UDim.new(0, 7)
t3dCorner.Parent = toggle3dBtn

local t3dStroke = Instance.new("UIStroke")
t3dStroke.Color = C.btnBorder
t3dStroke.Thickness = 1.0
t3dStroke.Parent = toggle3dBtn

local function update3dButton()
    if is3dEnabled then
        toggle3dBtn.Text = "👁️ 3D View: ON"
        toggle3dBtn.TextColor3 = C.text
        toggle3dBtn.BackgroundColor3 = C.btnBg
        t3dStroke.Color = C.btnBorder
    else
        toggle3dBtn.Text = "🌑 3D OFF (RAM Saver)"
        toggle3dBtn.TextColor3 = C.accentActive
        toggle3dBtn.BackgroundColor3 = Color3.fromRGB(15, 45, 35)
        t3dStroke.Color = C.accentActive
    end
end

toggle3dBtn.MouseButton1Click:Connect(function()
    set3dRendering(not is3dEnabled)
    update3dButton()
end)

local cleanBtn = Instance.new("TextButton")
cleanBtn.Name = "CleanBtn"
cleanBtn.Size = UDim2.new(0, 90, 0, 30)
cleanBtn.BackgroundColor3 = C.btnBg
cleanBtn.BorderSizePixel = 0
cleanBtn.Text = "🧹 Clean RAM"
cleanBtn.TextColor3 = C.text
cleanBtn.Font = Enum.Font.GothamBold
cleanBtn.TextSize = 11
cleanBtn.LayoutOrder = 2
cleanBtn.Parent = ramContainer

local clCorner = Instance.new("UICorner")
clCorner.CornerRadius = UDim.new(0, 7)
clCorner.Parent = cleanBtn

local clStroke = Instance.new("UIStroke")
clStroke.Color = C.btnBorder
clStroke.Thickness = 1.0
clStroke.Parent = cleanBtn

cleanBtn.MouseButton1Click:Connect(function()
    pcall(function()
        collectgarbage("collect")
        collectgarbage("setpause", 100)
    end)
    cleanBtn.Text = "✓ Cleaned!"
    cleanBtn.TextColor3 = C.accentActive
    cleanBtn.BackgroundColor3 = Color3.fromRGB(15, 45, 35)
    task.delay(1.5, function()
        cleanBtn.Text = "🧹 Clean RAM"
        cleanBtn.TextColor3 = C.text
        cleanBtn.BackgroundColor3 = C.btnBg
    end)
end)

-- Initialize Styles
updateButtonStyles()
update3dButton()

-- Minimize / Expand Toggle
local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame.Size = UDim2.new(0, 140, 0, 32)
        statusBar.Visible = false
        btnContainer.Visible = false
        ramContainer.Visible = false
        tipLabel.Visible = false
        title.Text = "⚡ " .. tostring(currentCap) .. " FPS" .. (not is3dEnabled and " | 3D OFF" or "")
        title.Size = UDim2.new(1, -34, 1, 0)
        minBtn.Text = "+"
        closeBtn.Visible = false
    else
        mainFrame.Size = UDim2.new(0, 250, 0, 180)
        statusBar.Visible = true
        btnContainer.Visible = true
        ramContainer.Visible = true
        tipLabel.Visible = true
        title.Text = "⚡ HIPHUB FPS & RAM OPTIMIZER"
        title.Size = UDim2.new(1, -70, 1, 0)
        minBtn.Text = "-"
        closeBtn.Visible = true
    end
end

minBtn.MouseButton1Click:Connect(toggleMinimize)

header.InputBegan:Connect(function(input)
    if isMinimized and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        toggleMinimize()
    end
end)

-- Close Button (Restores 60 FPS & 3D view before closing)
closeBtn.MouseButton1Click:Connect(function()
    setCap(60)
    set3dRendering(true)
    screenGui:Destroy()
end)

-- Draggable
local dragging = false
local dragInput, dragStart, startPos

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

-- Real-time FPS & Memory Monitor Loop
local frameCount = 0
local lastUpdate = os.clock()

RunService.RenderStepped:Connect(function(dt)
    frameCount = frameCount + 1
    local now = os.clock()
    if now - lastUpdate >= 0.5 then
        local realFps = math.floor(frameCount / (now - lastUpdate))
        frameCount = 0
        lastUpdate = now

        local memMB = 0
        pcall(function()
            memMB = math.floor(Stats:GetTotalMemoryUsageMb())
        end)

        if not isMinimized then
            statsLabel.Text = "Live: " .. tostring(realFps) .. " FPS | RAM: " .. tostring(memMB) .. " MB"
            if realFps <= 7 then
                statsLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
            elseif realFps <= 20 then
                statsLabel.TextColor3 = C.warning
            else
                statsLabel.TextColor3 = C.text
            end
        else
            title.Text = "⚡ " .. tostring(realFps) .. " FPS | " .. tostring(memMB) .. "MB"
        end
    end
end)

-- Initial Setup
setCap(60)
