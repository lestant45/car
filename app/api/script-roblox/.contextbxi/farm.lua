-- [[ Protected by DX-SR | ID: acc25f90-3e25-4820-be79-7ba66807a2ed ]] --
if not game:IsLoaded() then game.Loaded:Wait() end

local player, VU = game:GetService("Players").LocalPlayer, game:GetService("VirtualUser")

for _, c in getconnections(player.Idled) do
	pcall(c.Disable, c)
	pcall(c.Disconnect, c)
end

local con = player.Idled:Connect(function()
	VU:CaptureController()
	VU:ClickButton2(Vector2.zero)
end)

local unantiidle = function()
	if con then
		con:Disconnect()
		con = nil
	end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local TWEEN_SPEED = 100
local isWaitingInZone = false
local isEventRunning = false
local ARRIVE_DELAY = 60
local selectedBus = "Jetbus_3_RM _SHD"
local timePara = nil
local countdownPara = nil
local termCountdownPara = nil
local checkpointPara = nil
local earningPara = nil
local AT_HASH = game:GetService("HttpService"):GenerateGUID(false)
local USE_ANTI_TAMPER = true

local function formatCurrency(amount)
    local formatted = tostring(math.floor(amount))
    while true do  
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then
            break
        end
    end
    return "Rp. " .. formatted
end

local function prepareVehicle()
    Remotes.SpawnCar:FireServer(selectedBus)
    task.wait(2)

    local spawnedFolder = workspace:FindFirstChild("SpawnedVehicles")
    if spawnedFolder then
        local bus = nil
        
        for _, veh in ipairs(spawnedFolder:GetChildren()) do
            local ownerAttr = veh:GetAttribute("Owner")
            local ownerVal = veh:FindFirstChild("Owner")
            if (ownerAttr and tostring(ownerAttr) == LocalPlayer.Name) or (ownerVal and tostring(ownerVal.Value) == LocalPlayer.Name) or veh.Name:find(LocalPlayer.Name) then
                bus = veh
                break
            end
        end

        if not bus then
            local vehicles = spawnedFolder:GetChildren()
            bus = vehicles[#vehicles]
        end

        if bus then
            local seat = bus:FindFirstChild("DriveSeat", true)
            if seat then
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                end
                task.wait(0.3)
                local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true) or bus:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and fireproximityprompt then
                    fireproximityprompt(prompt)
                end
            end
        end
    end
end

local function getPart(name, folderName)
    local folder = workspace:WaitForChild(folderName, 5)
    if not folder then return nil end
    local part = folder:FindFirstChild(name, true)
    if not part then
        task.wait(0.3)
        part = folder:FindFirstChild(name, true)
    end
    return part
end

local function moveTo(targetPart)
    if not targetPart then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    local targetModel = char

    if hum and hum.SeatPart then
        local veh = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if veh then
            targetModel = veh
        end
    end

    local rootPart = targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart")
    if not rootPart then return end

    local startCFrame = targetModel:GetPivot()
    local targetCFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
    local distance = (targetCFrame.Position - startCFrame.Position).Magnitude
    local duration = math.max(distance / TWEEN_SPEED, 0.1)

    local originalCollisions = {}
    for _, part in ipairs(targetModel:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
        end
    end

    local wasAnchored = rootPart.Anchored
    rootPart.Anchored = true

    local noclipConnection = RunService.Stepped:Connect(function()
        for part in pairs(originalCollisions) do
            if part and part.Parent then
                part.CanCollide = false
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)

    local elapsed = 0
    while elapsed < duration do
        if not isEventRunning then break end
        local dt = RunService.Heartbeat:Wait()
        elapsed = elapsed + dt
        local alpha = math.min(elapsed / duration, 1)
        targetModel:PivotTo(startCFrame:Lerp(targetCFrame, alpha))
    end

    targetModel:PivotTo(targetCFrame)
    noclipConnection:Disconnect()

    for part, canCollide in pairs(originalCollisions) do
        if part and part.Parent then
            part.CanCollide = canCollide
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end

    task.wait(0.8)

    if not isWaitingInZone then
        targetModel:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
        task.wait(0.2)
    end

    rootPart.Anchored = wasAnchored
end

local function startJob()
    local triggers = CollectionService:GetTagged("BusJobTrigger")
    local terminalId = nil

    for _, trigger in ipairs(triggers) do
        local id = trigger:GetAttribute("TerminalId")
        if id then
            terminalId = id
            break
        end
    end

    if not terminalId then return false end

    local routes = Remotes.GetAvailableBusRoutes:InvokeServer(terminalId)
    if type(routes) ~= "table" then return false end

    local bestRouteId = nil
    local maxReward = -1

    for id, info in pairs(routes) do
        if type(info) == "table" and info.Reward and info.Reward > maxReward then
            maxReward = info.Reward
            bestRouteId = id
        end
    end

    if not bestRouteId then return false end

    local res = Remotes.StartBusJob:InvokeServer(bestRouteId, terminalId)
    if type(res) == "table" and res.success and res.nextCheckpointPartName then
        local part = getPart(res.nextCheckpointPartName, "Checkpoints")
        if part then moveTo(part) end
    end
    return true
end

Remotes:WaitForChild("BusJobUpdate").OnClientEvent:Connect(function(action, data)
    if not isEventRunning then return end
    
    if action == "StartCheckpointWait" then
        isWaitingInZone = true
        return
    end

    if action == "JobSuccess" or action == "JobCancelled" then
        isWaitingInZone = false
        task.wait(1)
        if isEventRunning then startJob() end
        return
    end

    if type(data) ~= "table" then return end

    local isFinal = (action == "FinalDestination" or data.isFinalDestination)
    local targetName = isFinal and data.endTriggerPartName or (data.nextCheckpointPartName or data.checkpointPartName)
    local folder = isFinal and "BusJobEndTriggers" or "Checkpoints"

    if targetName then
        task.spawn(function()
            isWaitingInZone = false
            if isFinal then
                local waitStart = os.clock()
                while isEventRunning do
                    local elapsed = os.clock() - waitStart
                    local remaining = ARRIVE_DELAY - elapsed
                    if remaining <= 0 then break end
                    
                    local secs = math.floor(remaining)
                    local ms = math.floor((remaining - secs) * 1000)
                    if countdownPara then 
                        countdownPara:SetDesc(string.format("Arrive in : %02d:%03d", secs, ms))
                    end
                    task.wait(0.05)
                end
                if countdownPara then countdownPara:SetDesc("Arrive in : 00:000") end
            end
            if not isEventRunning then return end
            local part = getPart(targetName, folder)
            if part then moveTo(part) end
        end)
    end
end)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Bus Autofarm",
    Icon = "bus", 
    Author = "DX-SR Hub",
    Folder = "DX-SR",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.V,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false
})

Window:Tag({
    Title = "v1.2A",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

Window:Tag({
    Title = "DX-SR Hub",
    Icon = "text-cursor",
    Color = Color3.fromHex("#1E3A8A"),
    Radius = 13,
})

local VirtualInputManager = game:GetService("VirtualInputManager")
Window:EditOpenButton({
    Title = "Open UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local Tab = Window:Tab({
    Title = "Farm",
    Icon = "sprout",
})

Tab:Section({ Title = "Autofarm bus" })

local ownedBuses = {"Jetbus_3_RM _SHD"}
pcall(function()
    local pData = LocalPlayer:FindFirstChild("PlayerData")
    if pData then
        local ownedCars = pData:FindFirstChild("OwnedCars")
        if ownedCars then
            local cars = ownedCars:GetChildren()
            if #cars > 0 then
                ownedBuses = {}
                for _, car in ipairs(cars) do
                    table.insert(ownedBuses, car.Name)
                end
            end
        end
    end
end)

Tab:Dropdown({
    Title = "Select Bus",
    Desc = "Pilih bus yang ingin di spawn",
    Multi = false,
    Value = ownedBuses[1] or "Jetbus_3_RM _SHD",
    Values = ownedBuses,
    Callback = function(option)
        selectedBus = option
    end
})

Tab:Toggle({
    Title = "Start/stop farm",
    Desc = "Mulai atau hentikan auto farm bus",
    Default = false,
    Callback = function(state)
        isEventRunning = state
        if USE_ANTI_TAMPER then
            pcall(function()
                RunService:Set3dRenderingEnabled(not state)
                local coreGui = game:GetService("CoreGui")
                local blackScreen = coreGui:FindFirstChild(AT_HASH)
                
                if state then
                    if not blackScreen then
                        blackScreen = Instance.new("ScreenGui")
                        blackScreen.Name = AT_HASH
                        blackScreen.DisplayOrder = -2147483648
                        blackScreen.IgnoreGuiInset = true
                        
                        local frame = Instance.new("Frame")
                        frame.Size = UDim2.new(1, 0, 1, 0)
                        frame.BackgroundColor3 = Color3.new(0, 0, 0)
                        frame.BorderSizePixel = 0
                        frame.Active = true
                        frame.Parent = blackScreen
                        
                        local text = Instance.new("TextLabel")
                        text.Size = UDim2.new(1, 0, 1, 0)
                        text.BackgroundTransparency = 1
                        text.Text = "Autofarm running\nCPU Saver Enabled"
                        text.TextColor3 = Color3.new(1, 1, 1)
                        text.TextSize = 24
                        text.Font = Enum.Font.GothamBold
                        text.Parent = frame
                        
                        if syn and syn.protect_gui then
                            syn.protect_gui(blackScreen)
                        end
                        blackScreen.Parent = coreGui
                    end
                    blackScreen.Enabled = true
                else
                    if blackScreen then
                        blackScreen.Enabled = false
                    end
                end
            end)
        else
            pcall(function()
                RunService:Set3dRenderingEnabled(true)
                local coreGui = game:GetService("CoreGui")
                local blackScreen = coreGui:FindFirstChild(AT_HASH)
                if blackScreen then blackScreen.Enabled = false end
            end)
        end
        
        if state then
            task.spawn(function()
                prepareVehicle()
                if not isEventRunning then return end
                task.wait(1)
                if not isEventRunning then return end
                startJob()
            end)
        else
            isWaitingInZone = false
            if countdownPara then countdownPara:SetDesc("Arrive in : 00:000") end
        end
    end
})

Tab:Section({ Title = "Information" })

earningPara = Tab:Paragraph({
    Title = "Total earning",
    Desc = "Rp. 0",
})

timePara = Tab:Paragraph({
    Title = "Status",
    Desc = "Time Elapsed: 00:00:00",
})

countdownPara = Tab:Paragraph({
    Title = "Final dest:",
    Desc = "Arrive in: 00:000",
})

termCountdownPara = Tab:Paragraph({
    Title = "Terminal Arrive",
    Desc = "Wait time: 00:000",
})

checkpointPara = Tab:Paragraph({
    Title = "Checkpoint Info",
    Desc = "Searching...",
})

task.spawn(function()
    local startTime = os.time()
    local lastTimeUpdate = 0
    
    local totalEarning = 0
    local lastUang = -1
    
    task.spawn(function()
        local pData = LocalPlayer:WaitForChild("PlayerData", 10)
        if pData then
            local uang = pData:WaitForChild("Uang", 5)
            if uang then
                lastUang = uang.Value
                uang.Changed:Connect(function(newVal)
                    if isEventRunning and lastUang ~= -1 and newVal > lastUang then
                        totalEarning = totalEarning + (newVal - lastUang)
                        if earningPara then
                            earningPara:SetDesc(formatCurrency(totalEarning))
                        end
                    end
                    lastUang = newVal
                end)
            end
        end
    end)
    
    while task.wait(0.2) do
        if isEventRunning and timePara then
            local currentTime = os.time()
            if currentTime - lastTimeUpdate >= 1 then
                local diff = currentTime - startTime
                local h = math.floor(diff / 3600)
                local m = math.floor((diff % 3600) / 60)
                local s = diff % 60
                timePara:SetDesc(string.format("Time Elapsed: %02d:%02d:%02d", h, m, s))
                lastTimeUpdate = currentTime
            end
            
            -- Read UI
            local cpFound = false
            local infoFound = false
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            if pGui then
                local busGui = pGui:FindFirstChild("BusJobGUI")
                local statusFrame = busGui and busGui:FindFirstChild("JobStatusFrame")
                if statusFrame then
                    -- Checkpoint
                    local cpLabel = statusFrame:FindFirstChild("CheckpointLabel")
                    if cpLabel and cpLabel:IsA("TextLabel") then
                        local current, max = cpLabel.Text:match("(%d+)%s*/%s*(%d+)")
                        if current and max then
                            if current == max then
                                if checkpointPara then checkpointPara:SetDesc("Last checkpoint") end
                            else
                                if checkpointPara then checkpointPara:SetDesc("Checkpoint: " .. current .. " / " .. max) end
                            end
                            cpFound = true
                        end
                    end
                    
                    -- Terminal Arrive Countdown (InfoLabel)
                    local infoLabel = statusFrame:FindFirstChild("InfoLabel")
                    if infoLabel and infoLabel:IsA("TextLabel") and infoLabel.Visible then
                        if termCountdownPara then
                            termCountdownPara:SetDesc(infoLabel.Text)
                        end
                        infoFound = true
                    end
                end
            end
            
            if not cpFound and checkpointPara then
                checkpointPara:SetDesc("Searching...")
            end
            if not infoFound and termCountdownPara then
                termCountdownPara:SetDesc("Wait time: 00:000")
            end
            
        elseif not isEventRunning then
            startTime = os.time()
            if timePara then timePara:SetDesc("Time Elapsed: 00:00:00") end
            if checkpointPara then checkpointPara:SetDesc("Searching...") end
            if termCountdownPara then termCountdownPara:SetDesc("Wait time: 00:000") end
        end
    end
end)

-- ==================== CONFIGURATION TAB ====================
local ConfigTab = Window:Tab({
    Title = "Configuration",
    Icon = "settings"
})

-- Theme Section
local ThemeSection = ConfigTab:Section({
    Title = "Theme"
})

local themeList = {}
pcall(function()
    local themes = WindUI:GetThemes()
    if themes then
        for k, v in pairs(themes) do
            if type(v) == "string" then
                table.insert(themeList, v)
            elseif type(k) == "string" then
                table.insert(themeList, k)
            end
        end
    end
end)

if #themeList == 0 then
    themeList = {
        "Dark", "Light", "Rose", "Plant", "Red", "Indigo", 
        "Sky", "Violet", "Amber", "Emerald", "Midnight", 
        "Crimson", "Monokai Pro", "Cotton Candy", "Mellowsi", "Rainbow"
    }
end

ConfigTab:Dropdown({
    Title = "Select Theme",
    Desc = "Choose UI Theme",
    Multi = false,
    Flag = "SelectedTheme",
    Value = WindUI:GetCurrentTheme() or "Dark",
    Values = themeList,
    Callback = function(option)
        pcall(function()
            WindUI:SetTheme(option)
        end)
    end
})

-- Config Manager Section
local ConfigManagerSection = ConfigTab:Section({
    Title = "Config Manager"
})

local selectedConfig = ""
local configNameInput = ""

local function getConfigList()
    local list = {}
    pcall(function()
        local configs = Window.ConfigManager:AllConfigs()
        if configs then
            for _, name in ipairs(configs) do
                table.insert(list, name)
            end
        end
    end)
    return list
end

local configDropdown = ConfigTab:Dropdown({
    Title = "Select Config",
    Desc = "Choose saved config",
    Multi = false,
    Value = "",
    Values = getConfigList(),
    Callback = function(option)
        selectedConfig = option
    end
})

ConfigTab:Input({
    Title = "Config Name",
    Desc = "New config name",
    PlaceholderText = "Enter config name...",
    Callback = function(text)
        configNameInput = text
    end
})

ConfigTab:Button({
    Title = "Save Config",
    Desc = "Save current settings to new config",
    Callback = function()
        if configNameInput == "" then
            WindUI:Notify({Title = "Config", Content = "Enter config name first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(configNameInput)
            cfg:Save()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. configNameInput .. "' saved successfully!", Duration = 3})
        pcall(function() configDropdown:Refresh(getConfigList()) end)
    end
})

ConfigTab:Button({
    Title = "Load Config",
    Desc = "Load selected config",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:Load()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. selectedConfig .. "' loaded successfully!", Duration = 3})
    end
})

ConfigTab:Button({
    Title = "Rewrite Config",
    Desc = "Overwrite selected config with current settings",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:Save()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. selectedConfig .. "' overwritten successfully!", Duration = 3})
    end
})

ConfigTab:Button({
    Title = "Delete Config",
    Desc = "Delete selected config",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:Delete()
        end)
        WindUI:Notify({Title = "Config", Content = "Config '" .. selectedConfig .. "' deleted successfully!", Duration = 3})
        selectedConfig = ""
        pcall(function() configDropdown:Refresh(getConfigList()) end)
    end
})

ConfigTab:Button({
    Title = "Set Auto Load",
    Desc = "Automatically load selected config on start",
    Callback = function()
        if selectedConfig == "" or selectedConfig == "--" then
            WindUI:Notify({Title = "Config", Content = "Select config first!", Duration = 3})
            return
        end
        pcall(function()
            local cfg = Window.ConfigManager:CreateConfig(selectedConfig)
            cfg:SetAutoLoad(true)
            cfg:Save()
        end)
        WindUI:Notify({Title = "Config", Content = "Auto load set to '" .. selectedConfig .. "'!", Duration = 3})
    end
})

-- Manual bulletproof AutoLoad parsing
pcall(function()
    local HttpService = game:GetService("HttpService")
    local configs = Window.ConfigManager:AllConfigs()
    if configs and readfile and isfile then
        for _, name in pairs(configs) do
            local path = "WindUI/DX-SR/config/" .. name .. ".json"
            if isfile(path) then
                local success, data = pcall(function()
                    return HttpService:JSONDecode(readfile(path))
                end)
                if success and type(data) == "table" and data.__autoload then
                    local cfg = Window.ConfigManager:CreateConfig(name)
                    cfg:Load()
                end
            end
        end
    end
end)

WindUI:Popup({
    Title = "Update log",
    Icon = "info",
    Content = "Reduce speed for safety.",
    Buttons = {
        {
            Title = "Continue",
            Icon = "arrow-right",
            Callback = function() end,
            Variant = "Primary",
        }
    }
})