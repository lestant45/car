--[[
    🧠 BRAINROT AUTO-CATCHER (OPTIMIZED V2)
    An advanced client-side automation script for catching brainrots.
    Includes level & rarity filtering and a recycled UI pool for 0% lag.
    
    Instructions:
    - Run this script inside any Roblox Executor (e.g., Solara, Wave, Electron, etc.)
    - Press [Insert] to toggle menu visibility.
--]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Locate Remotes
local BrainrotDir = ReplicatedStorage:WaitForChild("Brainrot")
local RotChillerDir = BrainrotDir:WaitForChild("RotChiller")
local ServerDir = RotChillerDir:WaitForChild("Server")

local CatchRequest = ServerDir:WaitForChild("CatchRequest")
local GetInitialContainerStates = ServerDir:WaitForChild("GetInitialContainerStates")
local UpdateEvent = ServerDir:WaitForChild("Update")

-- Require Core module for rarity checks if accessible
local Core = nil
pcall(function()
    Core = require(game.ReplicatedStorage.Brainrot.Core)
end)

-- State Variables
local containers = {}
local activeRots = {}
local caughtCount = 0
local battlesStarted = 0
local autoCatchEnabled = false
local catchDelay = 1.0
local safeModeEnabled = true
local uiNeedsUpdate = false
local currentlyCatching = nil
local catchRot -- Forward declaration

-- Filters State
local minLevelFilter = 1
local rarityNames = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"}
local selectedRarityIndex = 1

-- Helpers
local function countTable(t)
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end
    return c
end

local function getRotRarity(name)
    if Core and Core.Species and Core.Species[name] then
        local species = Core.Species[name]
        if species.Rarity then
            if typeof(species.Rarity) == "table" and species.Rarity.Name then
                return species.Rarity.Name
            elseif typeof(species.Rarity) == "string" then
                return species.Rarity
            elseif typeof(species.Rarity) == "table" and species.Rarity.Value then
                local valueMap = {[1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythical"}
                return valueMap[species.Rarity.Value] or tostring(species.Rarity.Value)
            end
        end
        if species.RarityValue then
            local valueMap = {[1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythical"}
            return valueMap[species.RarityValue] or tostring(species.RarityValue)
        end
    end
    return "Common"
end

local function matchesRarityFilter(rotName)
    local filter = rarityNames[selectedRarityIndex]
    if filter == "All" then return true end
    
    local rotRarity = getRotRarity(rotName)
    local rLower = string.lower(tostring(rotRarity))
    local fLower = string.lower(filter)
    
    if rLower == fLower then
        return true
    end
    
    -- Check numeric match fallback
    local rarityValueMap = {
        common = 1,
        uncommon = 2,
        rare = 3,
        epic = 4,
        legendary = 5,
        mythical = 6
    }
    local mappedValue = rarityValueMap[fLower]
    if mappedValue and Core and Core.Species and Core.Species[rotName] then
        local species = Core.Species[rotName]
        if species.Rarity and species.Rarity.Value == mappedValue then
            return true
        end
    end
    
    return false
end

-- Async Staff / Admin Caching to completely eliminate yielding lag
local staffCache = {}
local function cachePlayerStaff(player)
    if player == LocalPlayer then return end
    
    local isStaff = false
    if player.UserId == game.CreatorId then
        isStaff = true
    else
        task.spawn(function()
            local success, inGroup = pcall(function()
                return player:IsInGroup(1200769)
            end)
            if success and inGroup then
                staffCache[player] = true
            end
        end)
    end
    staffCache[player] = isStaff
end

-- Initialize staff cache
for _, player in ipairs(Players:GetPlayers()) do
    cachePlayerStaff(player)
end
Players.PlayerAdded:Connect(cachePlayerStaff)
Players.PlayerRemoving:Connect(function(player)
    staffCache[player] = nil
end)

-- UI Cleanup if script re-runs
local function cleanupExistingUI()
    local parent = nil
    pcall(function() parent = CoreGui end)
    if not parent then parent = PlayerGui end
    local existing = parent:FindFirstChild("BrainrotCatcherGui")
    if existing then
        existing:Destroy()
    end
end
cleanupExistingUI()

-- Create UI Parent
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotCatcherGui"
screenGui.ResetOnSpawn = false
local uiParent = nil
pcall(function() uiParent = CoreGui end)
if not uiParent then uiParent = PlayerGui end
screenGui.Parent = uiParent

-- Design Main Frame (Dark Cyber Glassmorphism)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 380)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = screenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Premium Gradient Border
local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.5
UIStroke.Color = Color3.fromRGB(138, 43, 226) -- Accent Purple
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainFrame

local BorderGradient = Instance.new("UIGradient")
BorderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 180, 216)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
})
BorderGradient.Parent = UIStroke

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local HeaderCover = Instance.new("Frame")
HeaderCover.Name = "HeaderCover"
HeaderCover.Size = UDim2.new(1, 0, 0, 10)
HeaderCover.Position = UDim2.new(0, 0, 1, -10)
HeaderCover.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
HeaderCover.BorderSizePixel = 0
HeaderCover.Parent = Header

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🧠 BRAINROT AUTO-CATCHER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end)
CloseBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Top Panel (Stats / Toggles)
local TopPanel = Instance.new("Frame")
TopPanel.Name = "TopPanel"
TopPanel.Size = UDim2.new(1, -30, 0, 70)
TopPanel.Position = UDim2.new(0, 15, 0, 50)
TopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
TopPanel.BorderSizePixel = 0
TopPanel.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopPanel

local TopStroke = Instance.new("UIStroke")
TopStroke.Thickness = 1
TopStroke.Color = Color3.fromRGB(45, 45, 55)
TopStroke.Parent = TopPanel

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.Size = UDim2.new(0.6, 0, 1, 0)
StatsLabel.Position = UDim2.new(0, 12, 0, 0)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "Status: <font color='#ff4d4d'>Inactive</font>\nCaught: 0 | Battles: 0"
StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatsLabel.TextSize = 12
StatsLabel.RichText = true
StatsLabel.Font = Enum.Font.GothamMedium
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.LineHeight = 1.3
StatsLabel.Parent = TopPanel

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 120, 0, 35)
ToggleBtn.Position = UDim2.new(1, -130, 0.5, -17.5)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 77, 77)
ToggleBtn.Text = "START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = TopPanel

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

-- Left Settings & Filters Panel
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Size = UDim2.new(0, 180, 0, 235)
SettingsPanel.Position = UDim2.new(0, 15, 0, 130)
SettingsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
SettingsPanel.BorderSizePixel = 0
SettingsPanel.Parent = MainFrame

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 8)
SettingsCorner.Parent = SettingsPanel

local SettingsStroke = Instance.new("UIStroke")
SettingsStroke.Thickness = 1
SettingsStroke.Color = Color3.fromRGB(45, 45, 55)
SettingsStroke.Parent = SettingsPanel

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Name = "SettingsTitle"
SettingsTitle.Size = UDim2.new(1, 0, 0, 25)
SettingsTitle.Position = UDim2.new(0, 0, 0, 5)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "🔧 FILTERS & CONFIG"
SettingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsTitle.TextSize = 11
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.Parent = SettingsPanel

-- Delay Input
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Name = "DelayLabel"
DelayLabel.Size = UDim2.new(1, -20, 0, 15)
DelayLabel.Position = UDim2.new(0, 10, 0, 35)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Catch Delay (seconds):"
DelayLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
DelayLabel.TextSize = 10
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = SettingsPanel

local DelayInput = Instance.new("TextBox")
DelayInput.Name = "DelayInput"
DelayInput.Size = UDim2.new(1, -20, 0, 22)
DelayInput.Position = UDim2.new(0, 10, 0, 50)
DelayInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
DelayInput.Text = "1.0"
DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayInput.TextSize = 12
DelayInput.Font = Enum.Font.GothamBold
DelayInput.Parent = SettingsPanel

local DelayCorner = Instance.new("UICorner")
DelayCorner.CornerRadius = UDim.new(0, 4)
DelayCorner.Parent = DelayInput

local DelayStroke = Instance.new("UIStroke")
DelayStroke.Thickness = 1
DelayStroke.Color = Color3.fromRGB(55, 55, 65)
DelayStroke.Parent = DelayInput

-- Level Filter Input
local LevelLabel = Instance.new("TextLabel")
LevelLabel.Name = "LevelLabel"
LevelLabel.Size = UDim2.new(1, -20, 0, 15)
LevelLabel.Position = UDim2.new(0, 10, 0, 77)
LevelLabel.BackgroundTransparency = 1
LevelLabel.Text = "Min Level Filter:"
LevelLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
LevelLabel.TextSize = 10
LevelLabel.Font = Enum.Font.Gotham
LevelLabel.TextXAlignment = Enum.TextXAlignment.Left
LevelLabel.Parent = SettingsPanel

local LevelInput = Instance.new("TextBox")
LevelInput.Name = "LevelInput"
LevelInput.Size = UDim2.new(1, -20, 0, 22)
LevelInput.Position = UDim2.new(0, 10, 0, 92)
LevelInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
LevelInput.Text = "1"
LevelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
LevelInput.TextSize = 12
LevelInput.Font = Enum.Font.GothamBold
LevelInput.Parent = SettingsPanel

local LevelCorner = Instance.new("UICorner")
LevelCorner.CornerRadius = UDim.new(0, 4)
LevelCorner.Parent = LevelInput

local LevelStroke = Instance.new("UIStroke")
LevelStroke.Thickness = 1
LevelStroke.Color = Color3.fromRGB(55, 55, 65)
LevelStroke.Parent = LevelInput

-- Rarity Filter Input
local RarityLabel = Instance.new("TextLabel")
RarityLabel.Name = "RarityLabel"
RarityLabel.Size = UDim2.new(1, -20, 0, 15)
RarityLabel.Position = UDim2.new(0, 10, 0, 119)
RarityLabel.BackgroundTransparency = 1
RarityLabel.Text = "Filter by Rarity:"
RarityLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
RarityLabel.TextSize = 10
RarityLabel.Font = Enum.Font.Gotham
RarityLabel.TextXAlignment = Enum.TextXAlignment.Left
RarityLabel.Parent = SettingsPanel

local RarityBtn = Instance.new("TextButton")
RarityBtn.Name = "RarityBtn"
RarityBtn.Size = UDim2.new(1, -20, 0, 22)
RarityBtn.Position = UDim2.new(0, 10, 0, 134)
RarityBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
RarityBtn.Text = "Rarity: All"
RarityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RarityBtn.TextSize = 11
RarityBtn.Font = Enum.Font.GothamBold
RarityBtn.Parent = SettingsPanel

local RarityBtnCorner = Instance.new("UICorner")
RarityBtnCorner.CornerRadius = UDim.new(0, 4)
RarityBtnCorner.Parent = RarityBtn

local RarityBtnStroke = Instance.new("UIStroke")
RarityBtnStroke.Thickness = 1
RarityBtnStroke.Color = Color3.fromRGB(55, 55, 65)
RarityBtnStroke.Parent = RarityBtn

-- Safe Mode Toggle (Anti-Staff)
local SafeToggle = Instance.new("TextButton")
SafeToggle.Name = "SafeToggle"
SafeToggle.Size = UDim2.new(1, -20, 0, 25)
SafeToggle.Position = UDim2.new(0, 10, 0, 165)
SafeToggle.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
SafeToggle.Text = "Anti-Staff: ON"
SafeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SafeToggle.TextSize = 10
SafeToggle.Font = Enum.Font.GothamBold
SafeToggle.Parent = SettingsPanel

local SafeCorner = Instance.new("UICorner")
SafeCorner.CornerRadius = UDim.new(0, 4)
SafeCorner.Parent = SafeToggle

local BindLabel = Instance.new("TextLabel")
BindLabel.Name = "BindLabel"
BindLabel.Size = UDim2.new(1, -20, 0, 35)
BindLabel.Position = UDim2.new(0, 10, 0, 195)
BindLabel.BackgroundTransparency = 1
BindLabel.Text = "Toggle Menu: [Insert]\nPress Insert to hide/show."
BindLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
BindLabel.TextSize = 10
BindLabel.Font = Enum.Font.Gotham
BindLabel.TextXAlignment = Enum.TextXAlignment.Left
BindLabel.Parent = SettingsPanel

-- Right Rots List Panel
local RotsPanel = Instance.new("Frame")
RotsPanel.Name = "RotsPanel"
RotsPanel.Size = UDim2.new(0, 225, 0, 235)
RotsPanel.Position = UDim2.new(0, 210, 0, 130)
RotsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
RotsPanel.BorderSizePixel = 0
RotsPanel.Parent = MainFrame

local RotsCorner = Instance.new("UICorner")
RotsCorner.CornerRadius = UDim.new(0, 8)
RotsCorner.Parent = RotsPanel

local RotsStroke = Instance.new("UIStroke")
RotsStroke.Thickness = 1
RotsStroke.Color = Color3.fromRGB(45, 45, 55)
RotsStroke.Parent = RotsPanel

local RotsTitle = Instance.new("TextLabel")
RotsTitle.Name = "RotsTitle"
RotsTitle.Size = UDim2.new(1, 0, 0, 25)
RotsTitle.Position = UDim2.new(0, 0, 0, 5)
RotsTitle.BackgroundTransparency = 1
RotsTitle.Text = "👾 DETECTED BRAINROTS"
RotsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
RotsTitle.TextSize = 11
RotsTitle.Font = Enum.Font.GothamBold
RotsTitle.Parent = RotsPanel

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Name = "ScrollList"
ScrollList.Size = UDim2.new(1, -10, 1, -35)
ScrollList.Position = UDim2.new(0, 5, 0, 30)
ScrollList.BackgroundTransparency = 1
ScrollList.BorderSizePixel = 0
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.ScrollBarThickness = 4
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
ScrollList.Parent = RotsPanel

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollList

-- Draggable Header Script
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Keybind Menu Toggle
local uiVisible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
    end
end)

-- Optimized Battle Detection with GUI Cache
local battleGuiRef = nil
local function getBattleGui()
    if battleGuiRef and battleGuiRef.Parent then
        return battleGuiRef
    end
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local nameLower = string.lower(gui.Name)
            if string.find(nameLower, "battle") or string.find(nameLower, "combat") or string.find(nameLower, "fight") then
                battleGuiRef = gui
                return gui
            end
        end
    end
    return nil
end

local function isPlayerInBattle()
    local gui = getBattleGui()
    if gui and gui.Enabled then
        return true
    end
    
    local character = LocalPlayer.Character
    if character then
        if character:GetAttribute("InBattle") == true or character:GetAttribute("Battling") == true then
            return true
        end
        if character:FindFirstChild("BattleTag") or character:FindFirstChild("InBattle") then
            return true
        end
    end
    
    return false
end

-- Stats Update UI function
local function updateStats()
    local statusText
    if not autoCatchEnabled then
        statusText = "<font color='#ff4d4d'>Inactive</font>"
    elseif isPlayerInBattle() then
        statusText = "<font color='#ffb84d'>In Battle</font>"
    else
        statusText = "<font color='#4dff4d'>Scanning...</font>"
    end
    StatsLabel.Text = "Status: " .. statusText .. "\nCaught: " .. tostring(caughtCount) .. " | Battles: " .. tostring(battlesStarted)
end

-- Safe search to locate Brainrot model in Workspace
local function findRotModelInWorkspace(rot)
    -- 1. Try searching for an instance named exactly after the rot ID
    local success, found = pcall(function()
        return workspace:FindFirstChild(rot.ID, true)
    end)
    if success and found then return found end
    
    -- 2. Try searching for an instance named exactly after the container ID
    success, found = pcall(function()
        return workspace:FindFirstChild(rot.ContainerID, true)
    end)
    if success and found then return found end
    
    -- 3. Try to find a model named after the species name close to the container
    local container = containers[rot.ContainerID]
    local containerPos = container and container.CFrame and container.CFrame.Position
    if containerPos and rot.Name then
        local closestModel = nil
        local closestDist = 50
        
        local searchSuccess, children = pcall(function() return workspace:GetChildren() end)
        if searchSuccess and children then
            for _, child in ipairs(children) do
                if child:IsA("Model") and string.lower(child.Name) == string.lower(rot.Name) then
                    local primary = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        local dist = (primary.Position - containerPos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestModel = child
                        end
                    end
                end
            end
        end
        if closestModel then return closestModel end
    end
    
    return nil
end

-- Safe Helper to find actual Brainrot CFrame (Model or Container fallback)
local function getRotCFrame(rot)
    local model = findRotModelInWorkspace(rot)
    if model then
        local success, pivot = pcall(function()
            if model:IsA("Model") then
                return model:GetPivot()
            elseif model:IsA("BasePart") then
                return model.CFrame
            end
        end)
        if success and pivot then return pivot end
    end
    
    local container = containers[rot.ContainerID]
    if container then
        if container.CFrame then
            return container.CFrame
        end
        -- Workspace search fallback: search if there's an instance named after the container ID
        local success, foundInstance = pcall(function()
            return workspace:FindFirstChild(rot.ContainerID, true)
        end)
        if success and foundInstance then
            if foundInstance:IsA("BasePart") then
                container.CFrame = foundInstance.CFrame
                return foundInstance.CFrame
            elseif foundInstance:IsA("Model") then
                local pivot = foundInstance:GetPivot()
                container.CFrame = pivot
                return pivot
            end
        end
    end
    return nil
end

-- Teleport Helper to pass server distance checks & trigger Touch event
local function teleportToRot(rot)
    print(string.format("[Teleport Debug] Targeting: %s (ID: %s)", tostring(rot.Name), tostring(rot.ID)))
    print(string.format("[Teleport Debug] rot.RotInstance: %s (Type: %s)", tostring(rot.RotInstance), typeof(rot.RotInstance)))
    if rot.RotInstance and typeof(rot.RotInstance) == "Instance" then
        print(string.format("[Teleport Debug] rot.RotInstance Parent: %s", tostring(rot.RotInstance.Parent)))
    end
    
    local cframe = getRotCFrame(rot)
    print(string.format("[Teleport Debug] Resolved CFrame: %s", tostring(cframe)))
    
    if cframe then
        local character = LocalPlayer.Character
        print(string.format("[Teleport Debug] Character: %s", tostring(character)))
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        print(string.format("[Teleport Debug] HumanoidRootPart: %s", tostring(hrp)))
        
        if hrp then
            print("[Teleport Debug] Teleporting player to target position...")
            hrp.CFrame = cframe + Vector3.new(0, 2.5, 0)
            task.wait(0.25) -- Wait to let physics/touch register
        else
            warn("[Teleport Debug] Failed to teleport: HumanoidRootPart not found!")
        end
    else
        warn("[Teleport Debug] Failed to teleport: CFrame resolved to nil!")
    end
end

-- Sync Rot Tables logic
local function addRot(containerId, rotData, fallbackId)
    local rotId = rotData and (rotData.ID or fallbackId)
    if not rotId then return end

    if not containers[containerId] then
        containers[containerId] = {
            ID = containerId,
            Rots = {}
        }
    end
    
    local name = "Unknown"
    local level = 1
    if rotData.RotInstance then
        if typeof(rotData.RotInstance) == "table" then
            name = rotData.RotInstance.Name or "Unknown"
            level = tonumber(rotData.RotInstance.Level) or 1
        elseif typeof(rotData.RotInstance) == "Instance" then
            name = rotData.RotInstance.Name or "Unknown"
            local success, lv = pcall(function()
                return rotData.RotInstance:GetAttribute("Level") or rotData.RotInstance.Level
            end)
            if success and lv then
                if typeof(lv) == "Instance" and lv:IsA("ValueObject") then
                    level = lv.Value
                else
                    level = tonumber(lv) or 1
                end
            end
        end
    end
    
    local rarity = getRotRarity(name)
    
    local rot = {
        ID = rotId,
        Seed = rotData.Seed,
        RotInstance = rotData.RotInstance,
        DespawnTime = rotData.DespawnTime,
        ContainerID = containerId,
        Name = name,
        Level = level,
        Rarity = rarity
    }
    
    containers[containerId].Rots[rotId] = rot
    activeRots[rotId] = rot
end

local function removeRot(containerId, rotDataOrId)
    local rotId = typeof(rotDataOrId) == "table" and rotDataOrId.ID or rotDataOrId
    if not rotId then return end

    if containers[containerId] and containers[containerId].Rots[rotId] then
        containers[containerId].Rots[rotId] = nil
    end
    activeRots[rotId] = nil
end

-- Render the List of Detected Rots (Optimized with dynamic recycling and reference caching)
local uiRowsCache = {} -- Contains elements: { row = Frame, infoLabel = TextLabel, catchBtn = TextButton, associatedRot = nil }

local function updateUIList()
    if not screenGui.Parent then return end
    
    local character = LocalPlayer.Character
    local playerPos = character and character.PrimaryPart and character.PrimaryPart.Position or Vector3.zero
    
    -- Filter and collect candidates
    local sortedList = {}
    for rotId, rot in pairs(activeRots) do
        local rotLevel = rot.Level or 1
        local rotName = rot.Name or ""
        
        if rotLevel >= minLevelFilter and matchesRarityFilter(rotName) then
            local container = containers[rot.ContainerID]
            local dist = 999999
            if container and container.CFrame then
                dist = (playerPos - container.CFrame.Position).Magnitude
            end
            table.insert(sortedList, {
                rot = rot,
                distance = dist
            })
        end
    end
    
    -- Sort by distance
    table.sort(sortedList, function(a, b)
        return a.distance < b.distance
    end)
    
    local contentHeight = 0
    for i, itemData in ipairs(sortedList) do
        local rot = itemData.rot
        local distance = itemData.distance
        
        -- Get or create UI elements from pool (Recycling)
        local cache = uiRowsCache[i]
        if not cache then
            local row = Instance.new("Frame")
            row.Name = "RotRow_" .. i
            row.Size = UDim2.new(1, -8, 0, 32)
            row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            row.BorderSizePixel = 0
            
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 4)
            rowCorner.Parent = row
            
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Name = "Info"
            infoLabel.Size = UDim2.new(0.7, 0, 1, 0)
            infoLabel.Position = UDim2.new(0, 8, 0, 0)
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
            infoLabel.TextSize = 10
            infoLabel.Font = Enum.Font.GothamMedium
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.Parent = row
            
            local catchBtn = Instance.new("TextButton")
            catchBtn.Name = "CatchBtn"
            catchBtn.Size = UDim2.new(0.24, 0, 0.75, 0)
            catchBtn.Position = UDim2.new(0.74, 0, 0.125, 0)
            catchBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
            catchBtn.Text = "CATCH"
            catchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            catchBtn.TextSize = 8
            catchBtn.Font = Enum.Font.GothamBold
            catchBtn.Parent = row
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = catchBtn
            
            row.Parent = ScrollList
            
            -- Create cache entry
            cache = {
                row = row,
                infoLabel = infoLabel,
                catchBtn = catchBtn,
                associatedRot = nil
            }
            
            -- Bind persistent event handler
            catchBtn.MouseButton1Click:Connect(function()
                local currentRot = cache.associatedRot
                if not currentRot or currentlyCatching then return end
                
                catchBtn.Text = "..."
                catchBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                
                local success = catchRot(currentRot)
                
                if success then
                    catchBtn.Text = "OK"
                    catchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                else
                    catchBtn.Text = "FAIL"
                    catchBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                    task.delay(1.5, function()
                        -- Check if the row is still showing the same rot
                        if cache.associatedRot == currentRot then
                            catchBtn.Text = "CATCH"
                            catchBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
                        end
                    end)
                end
            end)
            
            uiRowsCache[i] = cache
        end
        
        -- Assign current rot and update UI
        cache.associatedRot = rot
        cache.row.Visible = true
        
        local nameStr = rot.Name or "Unknown"
        local lvStr = rot.Level and tostring(rot.Level) or "?"
        local distStr = distance < 999999 and (string.format("%.0f", distance) .. "m") or "N/A"
        local rarityStr = rot.Rarity or "Common"
        
        cache.infoLabel.Text = string.format("%s (Lv. %s) [%s]\nDist: %s", nameStr, lvStr, rarityStr, distStr)
        
        -- Reset button aesthetics if not currently showing status
        if cache.catchBtn.Text ~= "..." and cache.catchBtn.Text ~= "FAIL" and cache.catchBtn.Text ~= "OK" then
            cache.catchBtn.Text = "CATCH"
            cache.catchBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
        end
        
        contentHeight = contentHeight + 36
    end
    
    -- Hide unused rows
    for i = #sortedList + 1, #uiRowsCache do
        uiRowsCache[i].associatedRot = nil
        uiRowsCache[i].row.Visible = false
    end
    
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

-- Catch Logic (Lock-protected hybrid touch & remote fallback)
catchRot = function(rot)
    if not rot or currentlyCatching then return false end
    currentlyCatching = rot
    
    print("[Auto-Catcher] Attempting to catch: " .. tostring(rot.Name))
    
    -- 1. Teleport onto the rot to trigger physical touch naturally
    teleportToRot(rot)
    
    -- 2. Wait up to 3 seconds for the native battle to start
    local startTime = os.clock()
    local joined = false
    while os.clock() - startTime < 3 do
        if isPlayerInBattle() then
            joined = true
            break
        end
        task.wait(0.1)
    end
    
    if joined then
        battlesStarted = battlesStarted + 1
        caughtCount = caughtCount + 1
        print("[Auto-Catcher] Joined battle via physical touch: " .. tostring(rot.Name))
        updateStats()
        currentlyCatching = nil
        return true
    end
    
    -- 3. Fallback: Invoke the remote if touch did not trigger battle within 3 seconds
    print("[Auto-Catcher] Touch did not trigger battle within timeout. Invoking CatchRequest remote...")
    local success, result = pcall(function()
        return CatchRequest:InvokeServer(rot.ContainerID, rot.ID)
    end)
    
    -- Wait a moment to see if battle starts from remote invocation
    task.wait(0.5)
    
    if isPlayerInBattle() or (success and result ~= nil) then
        battlesStarted = battlesStarted + 1
        caughtCount = caughtCount + 1
        print("[Auto-Catcher] Joined battle via Remote fallback: " .. tostring(rot.Name))
        updateStats()
        currentlyCatching = nil
        return true
    end
    
    print("[Auto-Catcher] Failed to catch " .. tostring(rot.Name))
    currentlyCatching = nil
    return false
end

-- Load Initial Map State
local function loadInitialState()
    local success, result = pcall(function()
        return GetInitialContainerStates:InvokeServer()
    end)
    
    if success and result and result.Containers then
        for containerId, containerData in pairs(result.Containers) do
            containers[containerId] = {
                ID = containerId,
                CFrame = containerData.CFrame,
                Size = containerData.Size,
                World = containerData.World,
                Tags = containerData.Tags,
                Rots = {}
            }
            if containerData.Rots then
                for rotId, rotData in pairs(containerData.Rots) do
                    addRot(containerId, rotData, rotId)
                end
            end
        end
        print("[Auto-Catcher] Initialized. Detected " .. tostring(countTable(activeRots)) .. " brainrots on the map.")
        updateUIList()
    else
        warn("[Auto-Catcher] Failed to load initial state. Retrying in 3 seconds...")
        task.delay(3, loadInitialState)
    end
end
loadInitialState()

-- Listen to Spawns / Despawns / Encounters
UpdateEvent.OnClientEvent:Connect(function(updates)
    for _, update in ipairs(updates) do
        if update.Type == "Spawn" then
            addRot(update.Container, update.Rot, update.Rot and update.Rot.ID)
        elseif update.Type == "Despawn" or update.Type == "Encounter" then
            removeRot(update.Container, update.Rot)
        end
    end
    uiNeedsUpdate = true
end)

-- Auto-Cleanup Despawned Rots Local Timer
task.spawn(function()
    while true do
        task.wait(1)
        local now = os.clock()
        local changed = false
        for rotId, rot in pairs(activeRots) do
            if now > rot.DespawnTime then
                removeRot(rot.ContainerID, rotId)
                changed = true
            end
        end
        if changed then
            uiNeedsUpdate = true
        end
    end
end)

-- Toggles & Input Focus Event Binding
DelayInput.FocusLost:Connect(function()
    local val = tonumber(DelayInput.Text)
    if val and val >= 0.1 then
        catchDelay = val
    else
        DelayInput.Text = tostring(catchDelay)
    end
end)

LevelInput.FocusLost:Connect(function()
    local val = tonumber(LevelInput.Text)
    if val and val >= 1 then
        minLevelFilter = math.floor(val)
    else
        LevelInput.Text = tostring(minLevelFilter)
    end
    uiNeedsUpdate = true
end)

RarityBtn.MouseButton1Click:Connect(function()
    selectedRarityIndex = selectedRarityIndex + 1
    if selectedRarityIndex > #rarityNames then
        selectedRarityIndex = 1
    end
    RarityBtn.Text = "Rarity: " .. rarityNames[selectedRarityIndex]
    uiNeedsUpdate = true
end)

SafeToggle.MouseButton1Click:Connect(function()
    safeModeEnabled = not safeModeEnabled
    if safeModeEnabled then
        SafeToggle.Text = "Anti-Staff: ON"
        SafeToggle.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    else
        SafeToggle.Text = "Anti-Staff: OFF"
        SafeToggle.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    end
end)

local function toggleAutoCatch()
    autoCatchEnabled = not autoCatchEnabled
    if autoCatchEnabled then
        ToggleBtn.Text = "STOP"
        TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(46, 204, 113)}):Play()
    else
        ToggleBtn.Text = "START"
        TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(231, 76, 60)}):Play()
    end
    updateStats()
end
ToggleBtn.MouseButton1Click:Connect(toggleAutoCatch)

-- Throttled UI & Distance Update Loop (Runs every 0.5s to prevent FPS lag, checks player movement)
local lastPlayerPos = Vector3.zero
task.spawn(function()
    while true do
        task.wait(0.5)
        if not screenGui.Parent then
            break
        end
        local character = LocalPlayer.Character
        local playerPos = character and character.PrimaryPart and character.PrimaryPart.Position or Vector3.zero
        local moved = (playerPos - lastPlayerPos).Magnitude > 1.5
        
        if autoCatchEnabled or uiNeedsUpdate or moved then
            updateUIList()
            updateStats()
            uiNeedsUpdate = false
            lastPlayerPos = playerPos
        end
    end
end)

-- Auto-Catching Execution Loop (Optimized using cached level and name properties)
task.spawn(function()
    while true do
        task.wait(0.2)
        
        if not autoCatchEnabled then
            continue
        end
        
        if isPlayerInBattle() or currentlyCatching then
            task.wait(0.5)
            continue
        end
        
        -- Admin / Staff Safety check (optimized reading cached table)
        if safeModeEnabled then
            local adminFound = false
            for _, player in ipairs(Players:GetPlayers()) do
                if staffCache[player] then
                    adminFound = true
                    break
                end
            end
            if adminFound then
                print("[Auto-Catcher] Staff/Admin detected! Pausing auto-catcher.")
                task.wait(5)
                continue
            end
        end
        
        -- Find closest target passing filters
        local character = LocalPlayer.Character
        local playerPos = character and character.PrimaryPart and character.PrimaryPart.Position
        if not playerPos then
            continue
        end
        
        local closestRot = nil
        local minDistance = 999999
        
        for rotId, rot in pairs(activeRots) do
            local rotLevel = rot.Level or 1
            local rotName = rot.Name or ""
            
            if rotLevel >= minLevelFilter and matchesRarityFilter(rotName) then
                local container = containers[rot.ContainerID]
                if container and container.CFrame then
                    local dist = (playerPos - container.CFrame.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestRot = rot
                    end
                end
            end
        end
        
        if closestRot then
            local success = catchRot(closestRot)
            if success then
                task.wait(catchDelay)
            end
        end
    end
end)

print("[Auto-Catcher] Optimized script loaded successfully. Press Insert to hide the menu.")