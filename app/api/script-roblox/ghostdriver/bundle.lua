-- HipHub Ghost Driver — Standalone Production Bundle (BAC-5513 Safe)
-- Auto Generated: Closed-Loop Dual-Lane Highway Corridor + Near-Miss Streak Maximizer

_G.hiphub_key = "KEYLESS"
_G.hiphub_role = "free"
_G.hiphub_url = "https://hiphub.cloud"
if getgenv then getgenv().hiphub_key = "KEYLESS" end
if getgenv then getgenv().hiphub_role = "free" end
if getgenv then getgenv().hiphub_url = "https://hiphub.cloud" end

-- ==========================================
-- MODULE: ui.lua
-- ==========================================
-- HipHub Ghost Driver — Futuristic Liquid Glass UI Base
-- Pure UI Layout Base & Component Library
-- Theme: Glassmorphism / Liquid Glass with Cyan-Violet accents (Clean Typography - Strict No Emojis)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
	task.wait(0.5)
	player = Players.LocalPlayer
end

local success, err = pcall(function()
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- DESIGN TOKENS (Liquid Glass Palette)
	------------------------------------------------
	local COLORS = {
		glassPrimary  = Color3.fromRGB(10, 12, 24),
		glassSurface  = Color3.fromRGB(16, 20, 36),
		glassCard     = Color3.fromRGB(20, 24, 44),
		glassHover    = Color3.fromRGB(28, 34, 58),
		glassActive   = Color3.fromRGB(34, 40, 68),
		accentCyan    = Color3.fromRGB(0, 200, 255),
		accentViolet  = Color3.fromRGB(140, 120, 255),
		accentBlend   = Color3.fromRGB(80, 160, 255),
		accentGlow    = Color3.fromRGB(60, 180, 255),
		accentMuted   = Color3.fromRGB(50, 60, 100),
		toggleOn      = Color3.fromRGB(0, 180, 230),
		toggleOff     = Color3.fromRGB(40, 46, 70),
		textPrimary   = Color3.fromRGB(225, 235, 255),
		textSecondary = Color3.fromRGB(140, 155, 185),
		textMuted     = Color3.fromRGB(90, 105, 135),
		textWhite     = Color3.fromRGB(255, 255, 255),
		borderGlass   = Color3.fromRGB(50, 65, 110),
		borderGlow    = Color3.fromRGB(0, 180, 255),
		shadow        = Color3.fromRGB(2, 3, 8),
		successGreen  = Color3.fromRGB(46, 204, 113),
		warningYellow = Color3.fromRGB(241, 196, 15),
		dangerRed     = Color3.fromRGB(231, 76, 60)
	}

	local TRANSPARENCY = {
		glassMain    = 0.02,
		glassSurface = 0.05,
		glassCard    = 0.08,
		glassSidebar = 0.04,
		glassTopBar  = 0.03,
		border       = 0.55,
		borderGlow   = 0.35,
	}

	local CORNER = {
		large  = UDim.new(0, 14),
		medium = UDim.new(0, 10),
		small  = UDim.new(0, 6),
		pill   = UDim.new(1, 0),
	}

	------------------------------------------------
	-- DESTROY PREVIOUS INSTANCES
	------------------------------------------------
	pcall(function()
		local old = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub_GhostDriver_UI")
		if old then old:Destroy() end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_GhostDriver_UI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999999
	pcall(function() gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
	gui.Parent = player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- SHADOW BACKING & MAIN CONTAINER
	------------------------------------------------
	local defaultWidth = 590
	local defaultHeight = 400

	local shadowFrame = Instance.new("Frame")
	shadowFrame.Name = "ShadowBacking"
	shadowFrame.Size = UDim2.new(0, defaultWidth + 16, 0, defaultHeight + 16)
	shadowFrame.Position = UDim2.new(0.5, -(defaultWidth + 16) / 2, 0.5, -(defaultHeight + 16) / 2)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.4
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 1
	shadowFrame.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 18)
	shadowCorner.Parent = shadowFrame

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)
	mainFrame.Position = UDim2.new(0.5, -defaultWidth / 2, 0.5, -defaultHeight / 2)
	mainFrame.BackgroundColor3 = COLORS.glassPrimary
	mainFrame.BackgroundTransparency = TRANSPARENCY.glassMain
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.ZIndex = 2
	mainFrame.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = CORNER.large
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = COLORS.borderGlass
	mainStroke.Thickness = 1.2
	mainStroke.Transparency = TRANSPARENCY.border
	mainStroke.Parent = mainFrame

	local function syncShadow()
		shadowFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 8,
			mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 8
		)
		shadowFrame.Size = UDim2.new(
			mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 16,
			mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 16
		)
		shadowFrame.Visible = mainFrame.Visible
	end

	-- Top Specular Highlight
	local glassHighlight = Instance.new("Frame")
	glassHighlight.Name = "GlassHighlight"
	glassHighlight.Size = UDim2.new(1, 0, 0, 50)
	glassHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glassHighlight.BackgroundTransparency = 0.96
	glassHighlight.BorderSizePixel = 0
	glassHighlight.ZIndex = 3
	glassHighlight.Parent = mainFrame

	local highlightGrad = Instance.new("UIGradient")
	highlightGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.88),
		NumberSequenceKeypoint.new(1, 1),
	})
	highlightGrad.Rotation = 90
	highlightGrad.Parent = glassHighlight

	------------------------------------------------
	-- TOP BAR (Title, Status, Window Controls)
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 42)
	topBar.BackgroundColor3 = COLORS.glassSurface
	topBar.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 4
	topBar.Parent = mainFrame

	local topBarBorder = Instance.new("Frame")
	topBarBorder.Name = "BorderBottom"
	topBarBorder.Size = UDim2.new(1, 0, 0, 1)
	topBarBorder.Position = UDim2.new(0, 0, 1, -1)
	topBarBorder.BackgroundColor3 = COLORS.borderGlass
	topBarBorder.BackgroundTransparency = 0.7
	topBarBorder.BorderSizePixel = 0
	topBarBorder.ZIndex = 5
	topBarBorder.Parent = topBar

	-- Brand Logo & Text
	local brandLabel = Instance.new("TextLabel")
	brandLabel.Name = "BrandLabel"
	brandLabel.Size = UDim2.new(0, 150, 1, 0)
	brandLabel.Position = UDim2.new(0, 16, 0, 0)
	brandLabel.BackgroundTransparency = 1
	brandLabel.Text = "HIPHUB"
	brandLabel.TextColor3 = COLORS.accentCyan
	brandLabel.Font = Enum.Font.GothamBold
	brandLabel.TextSize = 14
	brandLabel.TextXAlignment = Enum.TextXAlignment.Left
	brandLabel.ZIndex = 5
	brandLabel.Parent = topBar

	local titleSeparator = Instance.new("TextLabel")
	titleSeparator.Name = "Separator"
	titleSeparator.Size = UDim2.new(0, 10, 1, 0)
	titleSeparator.Position = UDim2.new(0, 78, 0, 0)
	titleSeparator.BackgroundTransparency = 1
	titleSeparator.Text = "/"
	titleSeparator.TextColor3 = COLORS.textMuted
	titleSeparator.Font = Enum.Font.Gotham
	titleSeparator.TextSize = 13
	titleSeparator.ZIndex = 5
	titleSeparator.Parent = topBar

	local gameTitle = Instance.new("TextLabel")
	gameTitle.Name = "GameTitle"
	gameTitle.Size = UDim2.new(0, 180, 1, 0)
	gameTitle.Position = UDim2.new(0, 92, 0, 0)
	gameTitle.BackgroundTransparency = 1
	gameTitle.Text = "GHOST DRIVER"
	gameTitle.TextColor3 = COLORS.textPrimary
	gameTitle.Font = Enum.Font.GothamBold
	gameTitle.TextSize = 12
	gameTitle.TextXAlignment = Enum.TextXAlignment.Left
	gameTitle.ZIndex = 5
	gameTitle.Parent = topBar

	-- Window Control Buttons (Minimize & Close)
	local windowControls = Instance.new("Frame")
	windowControls.Name = "WindowControls"
	windowControls.Size = UDim2.new(0, 70, 1, 0)
	windowControls.Position = UDim2.new(1, -76, 0, 0)
	windowControls.BackgroundTransparency = 1
	windowControls.ZIndex = 5
	windowControls.Parent = topBar

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "MinimizeButton"
	minimizeButton.Size = UDim2.new(0, 26, 0, 26)
	minimizeButton.Position = UDim2.new(0, 4, 0.5, -13)
	minimizeButton.BackgroundColor3 = COLORS.glassCard
	minimizeButton.BackgroundTransparency = 0.3
	minimizeButton.Text = "-"
	minimizeButton.TextColor3 = COLORS.textSecondary
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 14
	minimizeButton.ZIndex = 6
	minimizeButton.Parent = windowControls

	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = CORNER.small
	minCorner.Parent = minimizeButton

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 26, 0, 26)
	closeButton.Position = UDim2.new(0, 36, 0.5, -13)
	closeButton.BackgroundColor3 = Color3.fromRGB(60, 20, 25)
	closeButton.BackgroundTransparency = 0.3
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 120, 120)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 11
	closeButton.ZIndex = 6
	closeButton.Parent = windowControls

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = CORNER.small
	closeCorner.Parent = closeButton

	------------------------------------------------
	-- SIDEBAR (Navigation Tabs)
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 135, 1, -42)
	sidebar.Position = UDim2.new(0, 0, 0, 42)
	sidebar.BackgroundColor3 = COLORS.glassSurface
	sidebar.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 4
	sidebar.Parent = mainFrame

	local sidebarRightBorder = Instance.new("Frame")
	sidebarRightBorder.Name = "BorderRight"
	sidebarRightBorder.Size = UDim2.new(0, 1, 1, 0)
	sidebarRightBorder.Position = UDim2.new(1, -1, 0, 0)
	sidebarRightBorder.BackgroundColor3 = COLORS.borderGlass
	sidebarRightBorder.BackgroundTransparency = 0.7
	sidebarRightBorder.BorderSizePixel = 0
	sidebarRightBorder.ZIndex = 5
	sidebarRightBorder.Parent = sidebar

	local tabList = Instance.new("ScrollingFrame")
	tabList.Name = "TabList"
	tabList.Size = UDim2.new(1, -12, 1, -16)
	tabList.Position = UDim2.new(0, 6, 0, 8)
	tabList.BackgroundTransparency = 1
	tabList.BorderSizePixel = 0
	tabList.ScrollBarThickness = 0
	tabList.ZIndex = 5
	tabList.Parent = sidebar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabList

	------------------------------------------------
	-- CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -145, 1, -50)
	contentArea.Position = UDim2.new(0, 140, 0, 46)
	contentArea.BackgroundTransparency = 1
	contentArea.ClipsDescendants = true
	contentArea.ZIndex = 4
	contentArea.Parent = mainFrame

	local tabs = {}
	local currentTab = nil

	------------------------------------------------
	-- TAB MANAGEMENT
	------------------------------------------------
	local function addTab(name, layoutOrder)
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "Tab_" .. name
		tabButton.Size = UDim2.new(1, 0, 0, 34)
		tabButton.BackgroundColor3 = COLORS.glassCard
		tabButton.BackgroundTransparency = 1
		tabButton.Text = "  " .. name
		tabButton.TextColor3 = COLORS.textSecondary
		tabButton.Font = Enum.Font.GothamMedium
		tabButton.TextSize = 12
		tabButton.TextXAlignment = Enum.TextXAlignment.Left
		tabButton.LayoutOrder = layoutOrder or #tabs + 1
		tabButton.ZIndex = 6
		tabButton.Parent = tabList

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = CORNER.medium
		btnCorner.Parent = tabButton

		local activeIndicator = Instance.new("Frame")
		activeIndicator.Name = "ActiveIndicator"
		activeIndicator.Size = UDim2.new(0, 3, 0, 18)
		activeIndicator.Position = UDim2.new(0, 2, 0.5, -9)
		activeIndicator.BackgroundColor3 = COLORS.accentCyan
		activeIndicator.BorderSizePixel = 0
		activeIndicator.Visible = false
		activeIndicator.ZIndex = 7
		activeIndicator.Parent = tabButton

		local indCorner = Instance.new("UICorner")
		indCorner.CornerRadius = CORNER.pill
		indCorner.Parent = activeIndicator

		local tabScroll = Instance.new("ScrollingFrame")
		tabScroll.Name = "Page_" .. name
		tabScroll.Size = UDim2.new(1, -4, 1, 0)
		tabScroll.Position = UDim2.new(0, 0, 0, 0)
		tabScroll.BackgroundTransparency = 1
		tabScroll.BorderSizePixel = 0
		tabScroll.ScrollBarThickness = 3
		tabScroll.ScrollBarImageColor3 = COLORS.accentMuted
		tabScroll.Visible = false
		tabScroll.ZIndex = 5
		tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabScroll.Parent = contentArea

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Padding = UDim.new(0, 8)
		pageLayout.Parent = tabScroll

		local pagePadding = Instance.new("UIPadding")
		pagePadding.PaddingRight = UDim.new(0, 6)
		pagePadding.PaddingTop = UDim.new(0, 4)
		pagePadding.PaddingBottom = UDim.new(0, 12)
		pagePadding.Parent = tabScroll

		tabs[name] = {
			button = tabButton,
			scroll = tabScroll,
			indicator = activeIndicator
		}

		tabButton.MouseButton1Click:Connect(function()
			_G.HipHubUI.SelectTab(name)
		end)

		return tabScroll
	end

	local function selectTab(name)
		if not tabs[name] then return end
		for tName, data in pairs(tabs) do
			if tName == name then
				data.scroll.Visible = true
				data.indicator.Visible = true
				data.button.TextColor3 = COLORS.accentCyan
				data.button.BackgroundTransparency = 0.5
				data.button.BackgroundColor3 = COLORS.glassCard
			else
				data.scroll.Visible = false
				data.indicator.Visible = false
				data.button.TextColor3 = COLORS.textSecondary
				data.button.BackgroundTransparency = 1
			end
		end
		currentTab = name
	end

	------------------------------------------------
	-- COMPONENT: SECTION
	------------------------------------------------
	local function addSection(tabName, sectionTitle)
		local tabData = tabs[tabName]
		local parent = tabData and tabData.scroll or tabName

		local secFrame = Instance.new("Frame")
		secFrame.Name = "Section_" .. sectionTitle
		secFrame.Size = UDim2.new(1, 0, 0, 0)
		secFrame.AutomaticSize = Enum.AutomaticSize.Y
		secFrame.BackgroundColor3 = COLORS.glassSurface
		secFrame.BackgroundTransparency = TRANSPARENCY.glassSurface
		secFrame.BorderSizePixel = 0
		secFrame.ZIndex = 6
		secFrame.Parent = parent

		local secCorner = Instance.new("UICorner")
		secCorner.CornerRadius = CORNER.medium
		secCorner.Parent = secFrame

		local secStroke = Instance.new("UIStroke")
		secStroke.Color = COLORS.borderGlass
		secStroke.Thickness = 1
		secStroke.Transparency = 0.7
		secStroke.Parent = secFrame

		local secPadding = Instance.new("UIPadding")
		secPadding.PaddingTop = UDim.new(0, 8)
		secPadding.PaddingBottom = UDim.new(0, 8)
		secPadding.PaddingLeft = UDim.new(0, 10)
		secPadding.PaddingRight = UDim.new(0, 10)
		secPadding.Parent = secFrame

		local secLayout = Instance.new("UIListLayout")
		secLayout.SortOrder = Enum.SortOrder.LayoutOrder
		secLayout.Padding = UDim.new(0, 6)
		secLayout.Parent = secFrame

		local header = Instance.new("TextLabel")
		header.Name = "Header"
		header.Size = UDim2.new(1, 0, 0, 18)
		header.BackgroundTransparency = 1
		header.Text = string.upper(sectionTitle)
		header.TextColor3 = COLORS.accentCyan
		header.Font = Enum.Font.GothamBold
		header.TextSize = 10
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.LayoutOrder = 0
		header.ZIndex = 7
		header.Parent = secFrame

		return secFrame
	end

	------------------------------------------------
	-- COMPONENT: TOGGLE
	------------------------------------------------
	local function addToggle(parentSection, title, desc, defaultVal, callback)
		local toggleFrame = Instance.new("Frame")
		toggleFrame.Name = "Toggle_" .. title
		toggleFrame.Size = UDim2.new(1, 0, 0, desc and 38 or 28)
		toggleFrame.BackgroundColor3 = COLORS.glassCard
		toggleFrame.BackgroundTransparency = 0.5
		toggleFrame.BorderSizePixel = 0
		toggleFrame.ZIndex = 7
		toggleFrame.Parent = parentSection

		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = CORNER.small
		tCorner.Parent = toggleFrame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -55, 0, 16)
		titleLabel.Position = UDim2.new(0, 8, 0, desc and 3 or 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 8
		titleLabel.Parent = toggleFrame

		if desc then
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -55, 0, 14)
			descLabel.Position = UDim2.new(0, 8, 0, 19)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = desc
			descLabel.TextColor3 = COLORS.textMuted
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 9
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.ZIndex = 8
			descLabel.Parent = toggleFrame
		end

		local switchTrack = Instance.new("TextButton")
		switchTrack.Name = "SwitchTrack"
		switchTrack.Size = UDim2.new(0, 36, 0, 18)
		switchTrack.Position = UDim2.new(1, -44, 0.5, -9)
		switchTrack.BackgroundColor3 = defaultVal and COLORS.toggleOn or COLORS.toggleOff
		switchTrack.Text = ""
		switchTrack.AutoButtonColor = false
		switchTrack.ZIndex = 8
		switchTrack.Parent = toggleFrame

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = switchTrack

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 14, 0, 14)
		knob.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.ZIndex = 9
		knob.Parent = switchTrack

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = CORNER.pill
		knobCorner.Parent = knob

		local state = defaultVal or false

		local function updateVisuals()
			TweenService:Create(switchTrack, TweenInfo.new(0.2), {
				BackgroundColor3 = state and COLORS.toggleOn or COLORS.toggleOff
			}):Play()
			TweenService:Create(knob, TweenInfo.new(0.2), {
				Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			}):Play()
		end

		local function toggle()
			state = not state
			updateVisuals()
			if callback then
				pcall(callback, state)
			end
		end

		switchTrack.MouseButton1Click:Connect(toggle)
		local clickArea = Instance.new("TextButton")
		clickArea.Size = UDim2.new(1, -50, 1, 0)
		clickArea.BackgroundTransparency = 1
		clickArea.Text = ""
		clickArea.ZIndex = 8
		clickArea.Parent = toggleFrame
		clickArea.MouseButton1Click:Connect(toggle)

		return {
			Set = function(newVal)
				state = newVal
				updateVisuals()
				if callback then pcall(callback, state) end
			end,
			Get = function() return state end
		}
	end

	------------------------------------------------
	-- COMPONENT: BUTTON
	------------------------------------------------
	local function addButton(parentSection, title, desc, btnText, callback)
		local frame = Instance.new("Frame")
		frame.Name = "Button_" .. title
		frame.Size = UDim2.new(1, 0, 0, desc and 38 or 30)
		frame.BackgroundColor3 = COLORS.glassCard
		frame.BackgroundTransparency = 0.5
		frame.BorderSizePixel = 0
		frame.ZIndex = 7
		frame.Parent = parentSection

		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = CORNER.small
		fCorner.Parent = frame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -110, 0, 16)
		titleLabel.Position = UDim2.new(0, 8, 0, desc and 3 or 7)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 8
		titleLabel.Parent = frame

		if desc then
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -110, 0, 14)
			descLabel.Position = UDim2.new(0, 8, 0, 19)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = desc
			descLabel.TextColor3 = COLORS.textMuted
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 9
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.ZIndex = 8
			descLabel.Parent = frame
		end

		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0, 96, 0, 22)
		actionBtn.Position = UDim2.new(1, -104, 0.5, -11)
		actionBtn.BackgroundColor3 = COLORS.accentMuted
		actionBtn.Text = btnText or "Execute"
		actionBtn.TextColor3 = COLORS.textWhite
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 10
		actionBtn.AutoButtonColor = true
		actionBtn.ZIndex = 8
		actionBtn.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = CORNER.small
		btnCorner.Parent = actionBtn

		actionBtn.MouseButton1Click:Connect(function()
			TweenService:Create(actionBtn, TweenInfo.new(0.08), { BackgroundColor3 = COLORS.accentCyan }):Play()
			task.delay(0.12, function()
				TweenService:Create(actionBtn, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.accentMuted }):Play()
			end)
			if callback then pcall(callback) end
		end)

		return actionBtn
	end

	------------------------------------------------
	-- COMPONENT: SLIDER
	------------------------------------------------
	local function addSlider(parentSection, title, desc, min, max, defaultVal, suffix, callback)
		local frame = Instance.new("Frame")
		frame.Name = "Slider_" .. title
		frame.Size = UDim2.new(1, 0, 0, 44)
		frame.BackgroundColor3 = COLORS.glassCard
		frame.BackgroundTransparency = 0.5
		frame.BorderSizePixel = 0
		frame.ZIndex = 7
		frame.Parent = parentSection

		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = CORNER.small
		fCorner.Parent = frame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0.7, 0, 0, 16)
		titleLabel.Position = UDim2.new(0, 8, 0, 4)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 8
		titleLabel.Parent = frame

		local valLabel = Instance.new("TextLabel")
		valLabel.Size = UDim2.new(0.3, -8, 0, 16)
		valLabel.Position = UDim2.new(0.7, 0, 0, 4)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = tostring(defaultVal) .. (suffix or "")
		valLabel.TextColor3 = COLORS.accentCyan
		valLabel.Font = Enum.Font.GothamBold
		valLabel.TextSize = 11
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.ZIndex = 8
		valLabel.Parent = frame

		local sliderTrack = Instance.new("Frame")
		sliderTrack.Size = UDim2.new(1, -16, 0, 6)
		sliderTrack.Position = UDim2.new(0, 8, 0, 26)
		sliderTrack.BackgroundColor3 = COLORS.toggleOff
		sliderTrack.BorderSizePixel = 0
		sliderTrack.ZIndex = 8
		sliderTrack.Parent = frame

		local trCorner = Instance.new("UICorner")
		trCorner.CornerRadius = CORNER.pill
		trCorner.Parent = sliderTrack

		local currentVal = defaultVal or min
		local fillRatio = math.clamp((currentVal - min) / (max - min), 0, 1)

		local sliderFill = Instance.new("Frame")
		sliderFill.Size = UDim2.new(fillRatio, 0, 1, 0)
		sliderFill.BackgroundColor3 = COLORS.accentCyan
		sliderFill.BorderSizePixel = 0
		sliderFill.ZIndex = 9
		sliderFill.Parent = sliderTrack

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = CORNER.pill
		fillCorner.Parent = sliderFill

		local dragging = false
		local function updateSlider(input)
			local absX = sliderTrack.AbsolutePosition.X
			local absSize = sliderTrack.AbsoluteSize.X
			local ratio = math.clamp((input.Position.X - absX) / absSize, 0, 1)
			local val = math.floor(min + (max - min) * ratio)
			sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
			valLabel.Text = tostring(val) .. (suffix or "")
			currentVal = val
			if callback then pcall(callback, val) end
		end

		sliderTrack.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateSlider(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateSlider(input)
			end
		end)

		return {
			Set = function(v)
				local val = math.clamp(v, min, max)
				local ratio = (val - min) / (max - min)
				sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
				valLabel.Text = tostring(val) .. (suffix or "")
				currentVal = val
				if callback then pcall(callback, val) end
			end,
			Get = function() return currentVal end
		}
	end

	------------------------------------------------
	-- COMPONENT: DROPDOWN
	------------------------------------------------
	local function addDropdown(parentSection, title, desc, options, defaultVal, callback)
		local isExpanded = false
		local selected = defaultVal or (options and options[1]) or ""

		local frame = Instance.new("Frame")
		frame.Name = "Dropdown_" .. title
		frame.Size = UDim2.new(1, 0, 0, 36)
		frame.AutomaticSize = Enum.AutomaticSize.None
		frame.BackgroundColor3 = COLORS.glassCard
		frame.BackgroundTransparency = 0.5
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = true
		frame.ZIndex = 8
		frame.Parent = parentSection

		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = CORNER.small
		fCorner.Parent = frame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0.5, 0, 0, 20)
		titleLabel.Position = UDim2.new(0, 8, 0, 8)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 9
		titleLabel.Parent = frame

		local dropBtn = Instance.new("TextButton")
		dropBtn.Size = UDim2.new(0.48, 0, 0, 22)
		dropBtn.Position = UDim2.new(0.5, 0, 0, 7)
		dropBtn.BackgroundColor3 = COLORS.glassSurface
		dropBtn.Text = tostring(selected) .. " v"
		dropBtn.TextColor3 = COLORS.accentCyan
		dropBtn.Font = Enum.Font.Gotham
		dropBtn.TextSize = 10
		dropBtn.TextTruncate = Enum.TextTruncate.AtEnd
		dropBtn.ZIndex = 9
		dropBtn.Parent = frame

		local dCorner = Instance.new("UICorner")
		dCorner.CornerRadius = CORNER.small
		dCorner.Parent = dropBtn

		local optionList = Instance.new("ScrollingFrame")
		optionList.Name = "OptionList"
		optionList.Size = UDim2.new(1, -16, 0, 90)
		optionList.Position = UDim2.new(0, 8, 0, 34)
		optionList.BackgroundTransparency = 1
		optionList.BorderSizePixel = 0
		optionList.ScrollBarThickness = 2
		optionList.Visible = false
		optionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
		optionList.CanvasSize = UDim2.new(0, 0, 0, 0)
		optionList.ZIndex = 10
		optionList.Parent = frame

		local optLayout = Instance.new("UIListLayout")
		optLayout.SortOrder = Enum.SortOrder.LayoutOrder
		optLayout.Padding = UDim.new(0, 2)
		optLayout.Parent = optionList

		local function populateOptions(opts)
			for _, child in ipairs(optionList:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			for _, opt in ipairs(opts) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, 0, 0, 20)
				optBtn.BackgroundColor3 = (opt == selected) and COLORS.glassActive or COLORS.glassSurface
				optBtn.Text = "  " .. tostring(opt)
				optBtn.TextColor3 = (opt == selected) and COLORS.accentCyan or COLORS.textSecondary
				optBtn.Font = Enum.Font.Gotham
				optBtn.TextSize = 10
				optBtn.TextXAlignment = Enum.TextXAlignment.Left
				optBtn.ZIndex = 11
				optBtn.Parent = optionList

				local oCorner = Instance.new("UICorner")
				oCorner.CornerRadius = CORNER.small
				oCorner.Parent = optBtn

				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					dropBtn.Text = tostring(opt) .. " v"
					isExpanded = false
					optionList.Visible = false
					frame.Size = UDim2.new(1, 0, 0, 36)
					if callback then pcall(callback, opt) end
					populateOptions(opts)
				end)
			end
		end

		populateOptions(options or {})

		dropBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			optionList.Visible = isExpanded
			if isExpanded then
				frame.Size = UDim2.new(1, 0, 0, 130)
			else
				frame.Size = UDim2.new(1, 0, 0, 36)
			end
		end)

		return {
			Set = function(newOpt)
				selected = newOpt
				dropBtn.Text = tostring(newOpt) .. " v"
				if callback then pcall(callback, newOpt) end
			end,
			Get = function() return selected end,
			UpdateOptions = function(newOpts)
				populateOptions(newOpts)
			end
		}
	end

	------------------------------------------------
	-- COMPONENT: STATS CARD
	------------------------------------------------
	local function addStatsCard(parentSection, title, initialValue)
		local frame = Instance.new("Frame")
		frame.Name = "Stats_" .. title
		frame.Size = UDim2.new(1, 0, 0, 30)
		frame.BackgroundColor3 = COLORS.glassCard
		frame.BackgroundTransparency = 0.6
		frame.BorderSizePixel = 0
		frame.ZIndex = 7
		frame.Parent = parentSection

		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = CORNER.small
		fCorner.Parent = frame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
		titleLabel.Position = UDim2.new(0, 8, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textSecondary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 8
		titleLabel.Parent = frame

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.5, -8, 1, 0)
		valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(initialValue or "--")
		valueLabel.TextColor3 = COLORS.accentCyan
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 11
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.ZIndex = 8
		valueLabel.Parent = frame

		return {
			Update = function(val)
				valueLabel.Text = tostring(val)
			end
		}
	end

	------------------------------------------------
	-- COMPONENT: TEXTBOX / INPUT
	------------------------------------------------
	local function addTextBox(parentSection, title, desc, defaultVal, placeholder, callback)
		local frame = Instance.new("Frame")
		frame.Name = "TextBox_" .. title
		frame.Size = UDim2.new(1, 0, 0, desc and 38 or 30)
		frame.BackgroundColor3 = COLORS.glassCard
		frame.BackgroundTransparency = 0.5
		frame.BorderSizePixel = 0
		frame.ZIndex = 7
		frame.Parent = parentSection

		local fCorner = Instance.new("UICorner")
		fCorner.CornerRadius = CORNER.small
		fCorner.Parent = frame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -115, 0, 16)
		titleLabel.Position = UDim2.new(0, 8, 0, desc and 3 or 7)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 8
		titleLabel.Parent = frame

		if desc then
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -115, 0, 14)
			descLabel.Position = UDim2.new(0, 8, 0, 19)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = desc
			descLabel.TextColor3 = COLORS.textMuted
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 9
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.ZIndex = 8
			descLabel.Parent = frame
		end

		local boxContainer = Instance.new("Frame")
		boxContainer.Size = UDim2.new(0, 100, 0, 22)
		boxContainer.Position = UDim2.new(1, -108, 0.5, -11)
		boxContainer.BackgroundColor3 = COLORS.glassSurface
		boxContainer.BackgroundTransparency = 0.2
		boxContainer.BorderSizePixel = 0
		boxContainer.ZIndex = 8
		boxContainer.Parent = frame

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = CORNER.small
		bCorner.Parent = boxContainer

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = COLORS.borderGlass
		bStroke.Thickness = 1
		bStroke.Transparency = 0.5
		bStroke.Parent = boxContainer

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -8, 1, 0)
		box.Position = UDim2.new(0, 4, 0, 0)
		box.BackgroundTransparency = 1
		box.Text = tostring(defaultVal or "")
		box.PlaceholderText = tostring(placeholder or "Enter value...")
		box.PlaceholderColor3 = COLORS.textMuted
		box.TextColor3 = COLORS.accentCyan
		box.Font = Enum.Font.GothamBold
		box.TextSize = 11
		box.TextXAlignment = Enum.TextXAlignment.Center
		box.ClearTextOnFocus = false
		box.ZIndex = 9
		box.Parent = boxContainer

		box.Focused:Connect(function()
			TweenService:Create(bStroke, TweenInfo.new(0.15), { Color = COLORS.accentCyan, Transparency = 0.2 }):Play()
		end)

		box.FocusLost:Connect(function(enterPressed)
			TweenService:Create(bStroke, TweenInfo.new(0.2), { Color = COLORS.borderGlass, Transparency = 0.5 }):Play()
			if callback then
				pcall(callback, box.Text, enterPressed)
			end
		end)

		return {
			Set = function(newText)
				box.Text = tostring(newText)
				if callback then pcall(callback, tostring(newText), false) end
			end,
			Get = function() return box.Text end,
			Box = box
		}
	end

	------------------------------------------------
	-- COMPONENT: LABEL
	------------------------------------------------
	local function addLabel(parentSection, text, color)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 18)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color or COLORS.textSecondary
		label.Font = Enum.Font.Gotham
		label.TextSize = 10
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextWrapped = true
		label.ZIndex = 7
		label.Parent = parentSection
		return label
	end

	------------------------------------------------
	-- NOTIFICATIONS
	------------------------------------------------
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "Notifications"
	notifContainer.Size = UDim2.new(0, 240, 1, -20)
	notifContainer.Position = UDim2.new(1, -250, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 100
	notifContainer.Parent = gui

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notifLayout.Padding = UDim.new(0, 6)
	notifLayout.Parent = notifContainer

	local function notify(title, message, duration, nType)
		duration = duration or 3
		local notifFrame = Instance.new("Frame")
		notifFrame.Size = UDim2.new(1, 0, 0, 50)
		notifFrame.BackgroundColor3 = COLORS.glassPrimary
		notifFrame.BackgroundTransparency = 0.1
		notifFrame.BorderSizePixel = 0
		notifFrame.ZIndex = 101
		notifFrame.Parent = notifContainer

		local nCorner = Instance.new("UICorner")
		nCorner.CornerRadius = CORNER.medium
		nCorner.Parent = notifFrame

		local accentColor = COLORS.accentCyan
		if nType == "success" then accentColor = COLORS.successGreen
		elseif nType == "warn" then accentColor = COLORS.warningYellow
		elseif nType == "error" then accentColor = COLORS.dangerRed end

		local nStroke = Instance.new("UIStroke")
		nStroke.Color = accentColor
		nStroke.Thickness = 1
		nStroke.Transparency = 0.5
		nStroke.Parent = notifFrame

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -16, 0, 16)
		titleLabel.Position = UDim2.new(0, 10, 0, 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = accentColor
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 102
		titleLabel.Parent = notifFrame

		local msgLabel = Instance.new("TextLabel")
		msgLabel.Size = UDim2.new(1, -16, 0, 22)
		msgLabel.Position = UDim2.new(0, 10, 0, 22)
		msgLabel.BackgroundTransparency = 1
		msgLabel.Text = message
		msgLabel.TextColor3 = COLORS.textSecondary
		msgLabel.Font = Enum.Font.Gotham
		msgLabel.TextSize = 10
		msgLabel.TextXAlignment = Enum.TextXAlignment.Left
		msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
		msgLabel.ZIndex = 102
		msgLabel.Parent = notifFrame

		notifFrame.Position = UDim2.new(1, 50, 0, 0)
		TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()

		task.delay(duration, function()
			if notifFrame and notifFrame.Parent then
				local tw = TweenService:Create(notifFrame, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
				tw:Play()
				tw.Completed:Connect(function() notifFrame:Destroy() end)
			end
		end)
	end

	------------------------------------------------
	-- TABS INITIALIZATION
	------------------------------------------------
	addTab("Dashboard", 1)
	addTab("Auto Farm", 2)
	addTab("Vehicle", 3)
	addTab("Dealership", 4)
	addTab("Teleports", 5)
	addTab("Settings", 6)

	selectTab("Dashboard")

	------------------------------------------------
	-- EXPORT GLOBAL
	------------------------------------------------
	_G.HipHubUI = {
		gui = gui,
		mainFrame = mainFrame,
		shadowFrame = shadowFrame,
		topBar = topBar,
		sidebar = sidebar,
		closeButton = closeButton,
		minimizeButton = minimizeButton,
		contentArea = contentArea,
		tabs = tabs,
		COLORS = COLORS,
		TRANSPARENCY = TRANSPARENCY,
		CORNER = CORNER,
		SelectTab = selectTab,
		AddTab = addTab,
		AddSection = addSection,
		AddToggle = addToggle,
		AddSlider = addSlider,
		AddDropdown = addDropdown,
		AddButton = addButton,
		AddLabel = addLabel,
		AddStatsCard = addStatsCard,
		AddTextBox = addTextBox,
		Notify = notify,
		SyncShadow = syncShadow
	}

	notify("HipHub Ghost Driver", "Ghost Driver module initialized successfully!", 3, "success")
end)

if not success then
	warn("[HipHub Ghost Driver UI Error]:", err)
end


-- ==========================================
-- MODULE: settings.lua
-- ==========================================
-- HipHub Ghost Driver — Settings & Config Manager
-- Handles JSON persistence across sessions, anti-AFK, and global settings

local success, err = pcall(function()
	local HttpService = game:GetService("HttpService")
	local FOLDER_NAME = "HipHub/GhostDriver"
	local FILE_NAME = FOLDER_NAME .. "/config.json"

	local Config = {
		farm = {
			targetEarn = false,
			targetEarnM = 5,
			autoRace = false,
			raceDifficulty = "Hard",
			raceDelay = 1.0,
			autoDodgeTraffic = true,
			autoClaimQuests = true,
			claimInterval = 5,
			autoSpeedFarm = false,
			targetSpeed = 70,
			autoAfkArea = false,
			autoBuyCar = false,
			targetCarToBuy = "Novis N55"
		},
		vehicle = {
			selectedCar = "Wulfbrecht RZ7",
			speedBoost = false,
			speedMultiplier = 1.3,
			autoFlip = true,
			infiniteNitro = false
		},
		settings = {
			antiAfk = true,
			antiPlayerJoined = false,
			zeroLag = false,
			potatoMaterials = true,
			fpsCap = 60,
			fpsBooster = false,
			toggleKey = "RightControl"
		}
	}

	local function deepCopy(t)
		local clone = {}
		for k, v in pairs(t) do
			if type(v) == "table" then
				clone[k] = deepCopy(v)
			else
				clone[k] = v
			end
		end
		return clone
	end

	local function reconcile(target, template)
		for k, v in pairs(template) do
			if target[k] == nil then
				if type(v) == "table" then
					target[k] = deepCopy(v)
				else
					target[k] = v
				end
			elseif type(v) == "table" and type(target[k]) == "table" then
				reconcile(target[k], v)
			end
		end
	end

	local Settings = {
		Current = deepCopy(Config)
	}

	function Settings.Save()
		pcall(function()
			if writefile and makefolder then
				if not isfolder("HipHub") then makefolder("HipHub") end
				if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
				local json = HttpService:JSONEncode(Settings.Current)
				writefile(FILE_NAME, json)
			end
		end)
	end

	function Settings.Load()
		pcall(function()
			if readfile and isfile and isfile(FILE_NAME) then
				local content = readfile(FILE_NAME)
				local decoded = HttpService:JSONDecode(content)
				if type(decoded) == "table" then
					reconcile(decoded, Config)
					Settings.Current = decoded
				end
			end
		end)
	end

	Settings.Load()
	_G.HipHubConfig = Settings.Current
	_G.HipHub_GhostDriver_Settings = Settings
end)

if not success then
	warn("[HipHub Ghost Driver Settings Error]:", err)
end


-- ==========================================
-- MODULE: corridor.lua
-- ==========================================
-- 🛣️ Ghost Driver Complete Track Highway Ribbon Corridor (3,462 Waypoints)
_G.HipHub_GhostDriver_Corridor = {
{-3542.4,62.5,-1530.1,24.6},{-3538.6,62.4,-1554.2,38.5},{-3530.3,62.4,-1576.5,51.5},{-3517.1,62.5,-1618.1,61.4},{-3516.2,62.5,-1643.5,58.9},{-3514.5,62.4,-1669.1,57.8},{-3512.7,62.4,-1694.6,57.3},{-3511.1,62.4,-1720.7,56.1},{-3510,62.4,-1746.5,54.1},{-3509,62.4,-1771.9,52},
{-3507.9,62.4,-1798.8,49.9},{-3506.8,62.4,-1824.4,47.8},{-3505.7,62.4,-1850.1,45.6},{-3504.7,62.4,-1875.7,43.5},{-3503.6,62.4,-1901.5,41.6},{-3502.1,62.4,-1934.1,38.4},{-3501.7,62.4,-1960.1,37.5},{-3501.1,62.4,-1986.2,36.2},{-3499.5,62.5,-2011.4,33.1},{-3499.3,62.5,-2036.6,32.8},
{-3500,62.5,-2061.9,34.3},{-3500.9,62.5,-2087.7,36.3},{-3501.2,62.5,-2119.7,36.8},{-3501.2,62.5,-2145.8,36.5},{-3501.2,62.5,-2172.9,36.5},{-3501.2,62.5,-2200.2,36.4},{-3501.2,62.5,-2227.4,36.5},{-3501.2,62.4,-2260.6,36.7},{-3501.2,62.5,-2288.8,36.4},{-3501.2,62.5,-2316.9,36.6},
{-3501.2,62.5,-2337.4,36.9},{-3501.2,62.5,-2365.9,36.4},{-3501.2,62.5,-2392.8,36.5},{-3501.2,62.5,-2417.4,36.4},{-3501.2,62.5,-2443.1,36.4},{-3501.2,62.5,-2469.4,36.5},{-3501.2,62.5,-2496.2,36.9},{-3501.2,62.5,-2529.6,36.6},{-3501.2,62.5,-2556.6,36.5},{-3501.2,62.5,-2583.5,36.4},
{-3501.2,62.5,-2610.4,36.4},{-3501.2,62.5,-2637,36.5},{-3501.2,62.5,-2663.6,36.6},{-3501.2,62.5,-2690.4,36.7},{-3501.2,62.5,-2717,36.7},{-3501.2,62.5,-2743.7,36.7},{-3501.2,62.5,-2770.4,36.6},{-3501.2,62.5,-2797.1,36.5},{-3501.2,62.5,-2823.9,36.4},{-3501.2,62.5,-2850.7,36.4},
{-3501.2,62.5,-2877.4,36.5},{-3501.2,62.5,-2904.8,36.9},{-3501.2,62.5,-2937.2,36.7},{-3501.2,62.5,-2964,36.4},{-3501.2,62.5,-2990.8,36.5},{-3501.2,62.5,-3017.5,37.1},{-3501.1,62.5,-3037.9,36.2},{-3502,62.5,-3066.5,36.1},{-3503.3,62.5,-3095.1,36.4},{-3504.3,62.5,-3123.7,36.4},
{-3505.3,62.5,-3152.3,36.5},{-3506.3,62.5,-3180.9,36.7},{-3507,62.5,-3201.8,37.2},{-3508,62.5,-3230.2,36.6},{-3509,62.5,-3258.7,36.5},{-3510,62.5,-3287.1,36.9},{-3508.5,62.5,-3307.1,32.1},{-3509.8,62.5,-3335.4,32.8},{-3512.4,62.5,-3355.6,37.2},{-3513.7,62.5,-3383.3,37.1},
{-3513.1,62.5,-3411.6,34.6},{-3513.1,62.5,-3431.6,32.6},{-3514.2,62.5,-3459.9,33.3},{-3515.4,62.5,-3480.5,34},{-3516.6,62.5,-3508.7,34.6},{-3517.5,62.5,-3528.8,34.8},{-3518.7,62.5,-3557.1,35.4},{-3519.6,62.5,-3577.5,35.5},{-3520.7,62.5,-3606,36},{-3521.6,62.5,-3626.4,36},
{-3522.8,62.5,-3655.3,36.5},{-3523.7,62.5,-3676.1,37},{-3524.1,62.5,-3704.4,35.6},{-3524.4,62.5,-3725.1,35.1},{-3525.6,62.5,-3752.5,35.2},{-3527.1,62.5,-3781.5,36.3},{-3528,62.5,-3802.2,36.9},{-3529,62.4,-3832.2,36.5},{-3530.1,62.5,-3862.1,36.9},{-3530.8,62.5,-3883.3,36.6},
{-3531.8,62.5,-3912.8,36.7},{-3532.6,62.5,-3934.3,36.8},{-3533.7,62.5,-3964.8,36.5},{-3534.8,62.5,-3995.7,36.9},{-3535.5,62.5,-4018.4,36.9},{-3536.6,62.5,-4049.3,36.5},{-3537.9,62.5,-4080,36.2},{-3539.1,62.5,-4102,35.7},{-3541.6,62.5,-4130.1,36.4},{-3543.7,62.5,-4159.5,36.8},
{-3545.1,62.5,-4180.8,36.5},{-3547.2,62.5,-4210.5,36.9},{-3548.7,62.5,-4231.5,36.4},{-3550.8,62.5,-4261,37.4},{-3552.2,62.5,-4281.9,36.5},{-3553.7,62.5,-4302.7,36.9},{-3555.7,62.5,-4332.1,36.8},{-3557.3,62.5,-4355.1,37},{-3559.5,62.5,-4386.7,36.4},{-3561.7,62.5,-4418.2,37.2},
{-3563.3,62.5,-4440.8,36.5},{-3565.5,62.5,-4471.8,37},{-3567,62.5,-4493.7,36.5},{-3569.1,62.5,-4524.3,37.1},{-3570.7,62.5,-4546,36.4},{-3572.2,62.5,-4567.5,37.4},{-3574.3,62.5,-4597.7,36.6},{-3575.8,62.5,-4618.8,36.6},{-3578,62.5,-4650.6,36.7},{-3579.8,62.5,-4676,36.4},
{-3581.5,62.5,-4701,36.5},{-3583.2,62.5,-4725.5,36.5},{-3585,62.5,-4750.3,36.6},{-3586.7,62.5,-4774.7,36.6},{-3588.4,62.5,-4799.8,36.8},{-3590.6,62.5,-4830.7,36.9},{-3592.3,62.5,-4855.5,36.8},{-3594.1,62.5,-4880.5,36.6},{-3595.9,62.5,-4906,36.5},{-3597.6,62.5,-4931.5,36.4},
{-3599.4,62.5,-4956.8,36.5},{-3601.2,62.5,-4982,36.6},{-3602.9,62.5,-5007,36.5},{-3604.7,62.5,-5031.8,36.6},{-3606.6,62.5,-5059.5,36.6},{-3608.3,62.5,-5084,36.7},{-3610.4,62.5,-5109.3,35.8},{-3613.9,62.5,-5134,35.6},{-3617.6,62.5,-5158.5,36.2},{-3621,62.5,-5183.1,36.4},
{-3624.5,62.5,-5208.6,36.5},{-3628.1,62.5,-5233.8,36.5},{-3631.6,62.5,-5259.3,36.5},{-3635.3,62.5,-5285.5,36.6},{-3639.2,62.5,-5313.1,36.4},{-3642.9,62.5,-5339.1,36.4},{-3646.4,62.5,-5364.2,36.5},{-3649.9,62.5,-5389.2,36.5},{-3653.4,62.5,-5414,36.5},{-3656.9,62.5,-5439.3,36.5},
{-3660.5,62.5,-5464.6,36.4},{-3664.1,62.5,-5490.3,36.5},{-3667.8,62.5,-5516.5,36.9},{-3672.4,62.5,-5549.3,36.5},{-3676,62.5,-5575.2,36.5},{-3679.5,62.5,-5599.8,36.5},{-3683,62.5,-5625,36.5},{-3686.5,62.5,-5649.7,36.4},{-3690.1,62.5,-5675.1,36.6},{-3693.6,62.5,-5699.8,36.8},
{-3697,62.5,-5724,36.8},{-3701.6,62.5,-5756.7,36.5},{-3705.2,62.5,-5782.8,36.5},{-3708.8,62.5,-5808.2,36.8},{-3713.1,62.5,-5839.2,36.7},{-3716.2,62.5,-5861.1,36.7},{-3720.5,62.5,-5891.8,36.8},{-3723.6,62.5,-5913.3,36.5},{-3726.5,62.5,-5934.2,37.5},{-3730.9,62.5,-5965.6,36.5},
{-3735.2,62.5,-5996,37.3},{-3738.2,62.5,-6017.3,36.4},{-3741.1,62.5,-6038.5,37.2},{-3745.3,62.5,-6068.1,36.5},{-3748.4,62.5,-6090,37},{-3752.6,62.5,-6120.3,36.5},{-3756.2,62.5,-6140.6,36.6},{-3762.5,62.5,-6170.1,35.6},{-3769.1,62.5,-6200.3,36.9},{-3773.8,62.5,-6221.7,36.7},
{-3779.8,62.5,-6250.2,36.9},{-3784.4,62.5,-6271.8,36.7},{-3790.7,62.5,-6301.5,36.5},{-3796.9,62.5,-6331,37.4},{-3801.4,62.5,-6351.6,36.4},{-3807.5,62.5,-6380.5,37},{-3811.9,62.5,-6401.3,36.6},{-3818.2,62.5,-6430.8,36.5},{-3824.5,62.5,-6460.5,37.3},{-3829.1,62.5,-6482,36.5},
{-3835.1,62.4,-6510.2,36.8},{-3839.4,62.5,-6530.7,36.6},{-3845.6,62.5,-6559.8,36.6},{-3850,62.5,-6580.5,36.8},{-3856.3,62.5,-6610.2,36.5},{-3862.6,62.5,-6639.6,37.1},{-3867.1,62.5,-6661.1,36.6},{-3873.4,62.5,-6690.7,36.7},{-3878,62.5,-6712,37},{-3884.1,62.5,-6741.2,36.5},
{-3890.5,62.5,-6771.2,37.2},{-3895,62.5,-6792.4,36.4},{-3901.2,62.5,-6821.5,37.1},{-3905.7,62.5,-6842.6,36.5},{-3912,62.5,-6872.4,36.8},{-3916.5,62.5,-6893.4,36.6},{-3922.3,62.5,-6920.8,36.5},{-3926.6,62.5,-6940.9,37.4},{-3933.1,62.5,-6971.3,36.5},{-3939.5,62.5,-7001.5,36.9},
{-3944.3,62.5,-7024.3,36.9},{-3950.8,62.5,-7054.8,36.5},{-3957.5,62.5,-7086.3,37.1},{-3962.3,62.5,-7108.8,36.7},{-3968.6,62.5,-7138.3,36.1},{-3973.5,62.5,-7159.6,34.6},{-3981.8,62.5,-7189.4,33.7},{-3987.9,62.5,-7211.4,34.3},{-3996.7,62.5,-7241.3,33.9},{-4003.2,62.5,-7262.3,35.6},
{-4012.5,62.5,-7292.3,36.2},{-4021.2,62.5,-7322.1,37.4},{-4027.4,62.5,-7343.5,36.5},{-4036,62.5,-7373.7,37.3},{-4042.3,62.5,-7395.8,36.5},{-4051.3,62.5,-7427,36.7},{-4057.5,62.5,-7448.6,36.8},{-4065.9,62.5,-7477.9,36.9},{-4072.7,62.5,-7501.7,36.7},{-4079.6,62.5,-7525.6,36.7},
{-4086.7,62.5,-7550.3,36.5},{-4094.2,62.5,-7576.6,36.9},{-4102.6,62.5,-7605.9,36.9},{-4109.7,62.5,-7630.8,36.5},{-4116.8,62.5,-7655.6,36.5},{-4124,62.5,-7680.6,36.5},{-4132.9,62.5,-7711.7,36.8},{-4140.2,62.5,-7736.9,36.5},{-4147.5,62.5,-7762.1,36.5},{-4154.6,62.5,-7787.2,36.7},
{-4163.5,62.5,-7818.2,36.9},{-4170.6,62.5,-7843.2,36.6},{-4177.6,62.5,-7867.6,36.5},{-4184.7,62.5,-7892,36.4},{-4191.7,62.5,-7916.4,36.5},{-4198.9,62.5,-7941.6,36.5},{-4206.4,62.5,-7967.7,37},{-4215.4,62.5,-7999.3,36.6},{-4222.7,62.5,-8024.4,36.5},{-4229.7,62.5,-8049.2,36.4},
{-4236.8,62.5,-8073.9,36.4},{-4244.1,62.5,-8099.1,36.5},{-4251.1,62.4,-8124.2,36.5},{-4261,62.5,-8155.2,34.7},{-4269.3,62.5,-8180.1,33.4},{-4278.4,62.5,-8204.6,33.9},{-4287.7,62.5,-8228.9,34.8},{-4297.2,62.4,-8252.7,36.2},{-4306.3,62.5,-8277.4,36.5},{-4315.2,62.5,-8301.9,36.6},
{-4324.1,62.5,-8326.4,36.7},{-4332.7,62.5,-8350,36.6},{-4341.5,62.5,-8374.1,36.6},{-4350.4,62.5,-8398.7,36.7},{-4361.7,62.5,-8429.8,36.9},{-4371.1,62.5,-8455.6,36.6},{-4380.2,62.5,-8480.5,36.4},{-4389.3,62.5,-8505.5,36.4},{-4398.3,62.5,-8530.2,36.5},{-4407.3,62.4,-8554.9,36.6},
{-4416.3,62.5,-8579.6,36.6},{-4425.2,62.5,-8604.3,36.5},{-4434.4,62.5,-8629.2,36.6},{-4443.4,62.5,-8654,36.6},{-4455,62.4,-8686.1,36.9},{-4464.4,62.5,-8712,36.6},{-4474,62.5,-8738.1,36.4},{-4483.6,62.5,-8764.5,36.5},{-4493,62.5,-8790.4,36.8},{-4502.1,62.5,-8815.5,36.9},
{-4509,62.5,-8834.4,37},{-4518.7,62.5,-8861.1,36.5},{-4528.1,62.5,-8886.9,36.5},{-4537.8,62.5,-8913.5,36.6},{-4547.2,62.5,-8939.4,36.8},{-4556.4,62.5,-8964.6,36.8},{-4565.7,62.5,-8990.2,37.1},{-4574.8,62.5,-9015.2,36.9},{-4583.7,62.5,-9039.7,36.8},{-4592.9,62.5,-9065,36.7},
{-4601.7,62.5,-9089.2,36.6},{-4614.3,62.5,-9121.2,35.7},{-4625.1,62.5,-9146.3,34.9},{-4635.6,62.5,-9170.3,35.3},{-4647.4,62.5,-9195.5,36},{-4658.9,62.4,-9220.5,36.5},{-4670,62.5,-9245.4,36.4},{-4680.8,62.5,-9269.9,36.4},{-4692.1,62.5,-9295.2,36.5},{-4703.7,62.5,-9321.3,36.5},
{-4714.9,62.5,-9346.5,36.7},{-4725.5,62.5,-9370.3,36.5},{-4736.2,62.5,-9394.2,36.4},{-4746.8,62.5,-9418,36.5},{-4757.7,62.4,-9442.4,36.5},{-4768.8,62.5,-9467.4,36.5},{-4779.9,62.5,-9492.3,36.5},{-4791.1,62.5,-9517.5,36.5},{-4802.2,62.5,-9542.5,36.4},{-4813.7,62.5,-9568.2,36.4},
{-4825.3,62.5,-9594.2,36.7},{-4836.4,62.5,-9619.2,36.7},{-4848,62.5,-9645.2,37},{-4862.1,62.4,-9676.9,36.9},{-4874.1,62.5,-9704,36.5},{-4885.3,62.5,-9729,36.5},{-4896,62.5,-9753.2,36.7},{-4906.9,62.4,-9777.6,36.8},{-4918.1,62.4,-9802.7,36.9},{-4929.1,62.5,-9827.4,37},
{-4942.4,62.5,-9857.5,36.7},{-4954.1,62.5,-9883.5,36.9},{-4965.3,62.5,-9908.8,36.9},{-4976,62.5,-9932.9,36.7},{-4990.8,62.5,-9966.1,37},{-5002.4,62.5,-9992.2,36.6},{-5012.1,62.5,-10013.9,36.6},{-5023.3,62.5,-10039.2,36.7},{-5037.7,62.5,-10070,34.6},{-5049.8,62.5,-10094.8,32.8},
{-5061.8,62.5,-10118.4,32.3},{-5074.2,62.5,-10142.2,31.9},{-5087.3,62.5,-10166,32.3},{-5100.3,62.5,-10189.2,33.4},{-5113.4,62.5,-10212.2,34.9},{-5126.5,62.4,-10235.2,36.3},{-5138.8,62.4,-10258.2,36.7},{-5151.2,62.5,-10281.6,36.6},{-5163.8,62.5,-10305.3,36.6},{-5176.7,62.5,-10329.5,36.4},
{-5189.4,62.5,-10353.5,36.4},{-5202.4,62.5,-10377.8,36.5},{-5215.2,62.5,-10401.9,36.7},{-5230.5,62.4,-10430.7,36.5},{-5245.8,62.5,-10459.4,36.9},{-5260,62.5,-10486.2,36.7},{-5273.6,62.5,-10511.7,36.5},{-5287.1,62.5,-10537.2,36.6},{-5299.9,62.5,-10561.3,36.8},{-5312.7,62.5,-10585.4,36.9},
{-5328.9,62.5,-10615.7,36.9},{-5342.3,62.5,-10640.9,36.6},{-5354.8,62.5,-10664.6,36.5},{-5367.3,62.5,-10687.9,36.5},{-5380.5,62.5,-10712.9,36.4},{-5393.4,62.5,-10737.1,36.6},{-5405.9,62.5,-10760.5,36.7},{-5418.6,62.5,-10784.4,36.9},{-5430.8,62.5,-10807.4,36.9},{-5440.5,62.5,-10825.5,36.8},
{-5452.6,62.5,-10848.3,36.7},{-5465,62.5,-10871.7,36.6},{-5477.1,62.5,-10894.6,36.6},{-5489.6,62.5,-10917.9,36.5},{-5501.8,62.5,-10941,36.4},{-5514.3,62.5,-10964.6,36},{-5527.3,62.5,-10986.5,35},{-5541.3,62.5,-11007.8,36.3},{-5558.1,62.5,-11034.6,37},{-5571.8,62.5,-11056.3,36.7},
{-5582.4,62.5,-11073.4,37.1},{-5597.6,62.5,-11097.7,36.5},{-5612.7,62.5,-11121.9,36.5},{-5626.3,62.5,-11143.7,36.6},{-5639.6,62.5,-11164.9,36.6},{-5653.3,62.5,-11186.9,36.8},{-5667,62.5,-11208.7,37},{-5683,62.5,-11234.4,36.6},{-5700.6,62.5,-11262.6,36.8},{-5714.5,62.5,-11284.8,37},
{-5726.6,62.5,-11304.3,36.8},{-5743.7,62.5,-11331.6,37},{-5757.5,62.5,-11353.6,36.7},{-5771.2,62.5,-11375.6,36.6},{-5786.5,62.5,-11400,37.6},{-5800.6,62.5,-11422.7,36.9},{-5814.5,62.5,-11444.8,36.6},{-5828.6,62.4,-11467.5,36.5},{-5844.5,62.5,-11492.9,36.5},{-5858.9,62.5,-11515.9,36.7},
{-5872.6,62.5,-11537.8,37.3},{-5890.2,62.4,-11566.1,36.6},{-5907.5,62.5,-11593.7,36.5},{-5924.4,62.5,-11620.8,37.2},{-5936.6,62.5,-11640.2,36.6},{-5952.3,62.5,-11665.5,36.6},{-5968.5,62.5,-11691.4,36.5},{-5984.8,62.5,-11717.4,36.5},{-6000.9,62.5,-11743.2,37.1},{-6012.3,62.5,-11761.4,36.6},
{-6027.3,62.5,-11785.5,36.6},{-6038.1,62.5,-11802.8,37.1},{-6052.8,62.5,-11826.3,36.4},{-6068.1,62.5,-11850.4,35.3},{-6084.6,62.5,-11873.9,34.5},{-6101.5,62.5,-11896.1,36.2},{-6114.3,62.4,-11913,37.2},{-6130.6,62.5,-11935.5,36.7},{-6146.9,62.5,-11958,36.5},{-6163.6,62.5,-11980.9,36.3},
{-6180.3,62.5,-12003.4,35.8},{-6196.9,62.5,-12025.8,35.3},{-6213.6,62.5,-12048.4,34.8},{-6230.3,62.5,-12070.8,34.3},{-6246.7,62.5,-12093.2,34.1},{-6262.9,62.5,-12116,34.8},{-6278.5,62.5,-12138.3,36.3},{-6294.7,62.5,-12160.4,38.3},{-6311.2,62.5,-12182.6,38.9},{-6327.7,62.5,-12205.3,38.9},
{-6352.1,62.5,-12238.8,39},{-6364,62.5,-12255.2,38.8},{-6380.2,62.5,-12277.5,38.6},{-6395.7,62.5,-12298.8,38.4},{-6411.3,62.5,-12320.3,38.5},{-6427.7,62.5,-12342.9,38.5},{-6443.9,62.5,-12365.2,38.8},{-6463.8,62.5,-12392.5,38.8},{-6480,62.5,-12414.8,38.5},{-6496.3,62.5,-12437.3,38.4},
{-6512.2,62.5,-12459.2,38.6},{-6528.6,62.5,-12481.7,38.8},{-6540.7,62.5,-12498.4,39},{-6557.5,62.5,-12521.6,38.8},{-6573.8,62.5,-12543.9,38.5},{-6590.3,62.5,-12566.7,38.4},{-6606.9,62.5,-12589.5,38.6},{-6623.4,62.5,-12612.3,39},{-6635.8,62.5,-12629.3,38.8},{-6652.1,62.5,-12651.8,38.4},
{-6668.9,62.5,-12674.8,38.5},{-6685.8,62.6,-12696.6,38},{-6699.2,62.6,-12712.5,38.9},{-6714,62.6,-12730.1,39.7},{-6727.9,62.6,-12746.3,39.7},{-6746.6,62.6,-12768.7,39.5},{-6764.3,62.6,-12789.8,39.4},{-6781.9,62.6,-12810.8,39.9},{-6794.9,62.6,-12826.3,39.4},{-6812.6,62.6,-12847.3,39.5},
{-6831,62.6,-12869.3,39.9},{-6844.1,62.6,-12884.9,39.5},{-6862.8,62.6,-12907,39},{-6882.2,62.6,-12929.9,38.7},{-6900.4,62.5,-12951.3,38.7},{-6913.5,62.5,-12966.8,38.7},{-6932.1,62.5,-12989.1,38.4},{-6950.3,62.5,-13010.8,38.6},{-6964,62.5,-13027.1,39},{-6982.8,62.5,-13049.5,38.5},
{-7001.8,62.5,-13072.1,38.4},{-7021.8,62.5,-13095.9,38.5},{-7040.2,62.5,-13117.9,39.1},{-7054.8,62.5,-13135.3,38.9},{-7075.8,62.5,-13160.3,38.4},{-7095.5,62.5,-13183.8,38.6},{-7115.4,62.5,-13207.5,39.2},{-7129,62.5,-13223.7,38.5},{-7147.9,62.5,-13246.3,38.5},{-7167.3,62.5,-13269.3,39.2},
{-7182.1,62.5,-13287,38.7},{-7202.6,62.5,-13311.4,38.6},{-7222.3,62.5,-13334.9,38.4},{-7243,62.5,-13359.6,38.5},{-7263.4,62.5,-13384,38.7},{-7284.4,62.5,-13409,38.8},{-7299.4,62.5,-13426.8,39.1},{-7319.9,62.5,-13451.3,38.4},{-7339.4,62.5,-13474.3,38.2},{-7360.3,62.6,-13497.2,38},
{-7384.3,62.6,-13521.2,39.3},{-7398.4,62.6,-13536.2,38.7},{-7419,62.6,-13557,39.6},{-7433.3,62.6,-13571.8,39.3},{-7452.6,62.6,-13592.8,36.1},{-7467.5,62.5,-13606.8,34.7},{-7487.8,62.5,-13627.2,34.4},{-7502.3,62.5,-13642.4,34.4},{-7521.9,62.5,-13663.2,35},{-7536.4,62.5,-13678.4,36.2},
{-7556.3,62.5,-13699.8,36.3},{-7575.9,62.5,-13720.2,36.7},{-7596.3,62.5,-13741.4,37.2},{-7610.3,62.5,-13755.8,36.5},{-7630.2,62.5,-13776.4,36.6},{-7644.7,62.5,-13791.5,37.1},{-7664.8,62.5,-13812.3,36.4},{-7685.4,62.5,-13833.6,36.5},{-7706.5,62.5,-13855.4,36.7},{-7720.4,62.5,-13869.9,36.8},
{-7740.2,62.5,-13890.4,36.5},{-7760.3,62.5,-13911.2,37.3},{-7775,62.5,-13926.4,36.6},{-7795.2,62.5,-13947.4,36.5},{-7809.8,62.5,-13962.5,37.2},{-7829.9,62.5,-13983.2,36.5},{-7849.7,62.5,-14003.8,36.7},{-7863.8,62.5,-14018.3,36.8},{-7884,62.5,-14039.4,36.4},{-7904.9,62.5,-14060.9,36.5},
{-7925.3,62.5,-14082,36.8},{-7939.9,62.5,-14097.2,36.9},{-7959.5,62.5,-14117.4,36.4},{-7979.5,62.5,-14138.2,36.6},{-7999.7,62.5,-14159.4,36.9},{-8013.9,62.5,-14174.5,35.5},{-8033.4,62.5,-14195.6,34.2},{-8053.4,62.5,-14216.2,34.5},{-8068.9,62.5,-14229.6,35.3},{-8090.2,62.5,-14248.1,36.4},
{-8105.2,62.5,-14261.8,36.7},{-8125.9,62.5,-14280.7,35.6},{-8146.7,62.5,-14299.5,36.2},{-8172.7,62.4,-14322.5,36.2},{-8194.8,62.5,-14342.2,36.9},{-8210.2,62.5,-14356.1,36.7},{-8231.5,62.5,-14375.3,36.5},{-8247,62.5,-14389.2,37.1},{-8269.3,62.5,-14409.2,36.6},{-8290.4,62.5,-14428.3,37},
{-8306,62.5,-14442.3,36.6},{-8327.6,62.5,-14461.8,36.6},{-8343.4,62.5,-14476,36.9},{-8365.8,62.5,-14496.1,36.4},{-8388.6,62.5,-14516.7,36.7},{-8408.9,62.5,-14534.9,36.7},{-8424.2,62.5,-14548.7,36.7},{-8446.1,62.5,-14568.5,36.7},{-8462.1,62.5,-14582.9,36.8},{-8484.5,62.5,-14603,36.5},
{-8506.8,62.5,-14623.1,37.3},{-8523.1,62.5,-14637.8,36.5},{-8545.8,62.5,-14658.2,36.8},{-8562.5,62.4,-14673.3,37.1},{-8585.7,62.5,-14694.2,36.4},{-8608.9,62.5,-14715.1,36.7},{-8625.7,62.5,-14730.2,36.9},{-8648.7,62.5,-14750.9,36.4},{-8671,62.5,-14771,37.1},{-8696.7,62.5,-14794.1,36.5},
{-8718.9,62.5,-14814.1,37.2},{-8734.6,62.5,-14828.2,36.5},{-8750.2,62.5,-14842.3,37},{-8771.8,62.5,-14861.7,36.4},{-8792.2,62.5,-14880.3,37.1},{-8807.7,62.5,-14894.4,35.9},{-8823.1,62.5,-14908.5,35.9},{-8847,62.5,-14928.3,33.4},{-8872.3,62.5,-14948.6,33.6},{-8891,62.5,-14963.2,33.6},
{-8916.6,62.5,-14983.2,33.2},{-8942.5,62.5,-15003.1,34},{-8959.1,62.5,-15015.8,34},{-8976.1,62.5,-15028.5,35.7},{-9000.2,62.5,-15046.9,35.9},{-9017.5,62.4,-15060,36.7},{-9041.9,62.4,-15078.9,36.7},{-9059.4,62.5,-15092.5,36.6},{-9081.7,62.5,-15110,36.5},{-9101.9,62.5,-15125.8,36.5},
{-9127.2,62.5,-15145.5,36.8},{-9147.8,62.5,-15161.7,36.5},{-9168.8,62.5,-15178.1,36.5},{-9194.7,62.5,-15198.3,36.8},{-9215.9,62.5,-15214.9,36.4},{-9237.2,62.5,-15231.5,36.9},{-9263,62.5,-15251.7,36.5},{-9284.1,62.5,-15268.2,36.5},{-9310,62.5,-15288.4,36.9},{-9328.3,62.5,-15302.7,36.6},
{-9348.9,62.5,-15318.8,36.9},{-9369.3,62.5,-15334.7,37.4},{-9391.8,62.5,-15352.3,36.6},{-9411.9,62.5,-15368,36.8},{-9431.9,62.5,-15383.6,36.8},{-9451.8,62.5,-15399.3,36.9},{-9476.6,62.5,-15418.9,36.3},{-9503.7,62.5,-15440.6,35.1},{-9525.9,62.5,-15458.3,35},{-9545.6,62.5,-15474.1,34.3},
{-9565,62.5,-15490.1,33.1},{-9589,62.5,-15510.1,31},{-9610.9,62.5,-15527.8,29.7},{-9630.7,62.5,-15543.1,30},{-9651,62.5,-15557.3,29.8},{-9668.9,62.5,-15569.5,29.8},{-9689.4,62.5,-15583.5,29.6},{-9711.2,62.5,-15598.1,30.1},{-9728.2,62.5,-15609.1,31.3},{-9751.6,62.5,-15623.7,32.6},
{-9775,62.5,-15638.2,34.7},{-9798.3,62.4,-15652.9,36.8},{-9815,62.4,-15664.1,36.9},{-9837.6,62.5,-15679.4,36.5},{-9860.5,62.5,-15694.8,36.5},{-9889.5,62.5,-15714.4,36.9},{-9910.9,62.5,-15728.8,36.9},{-9937.2,62.5,-15746.5,36.9},{-9958.4,62.5,-15760.8,36.8},{-9979.8,62.5,-15775.3,36.7},
{-10001.5,62.5,-15790,36.8},{-10023.4,62.5,-15804.7,36.9},{-10050.9,62.4,-15823.3,36.9},{-10073.3,62.5,-15838.4,36.8},{-10098.7,62.5,-15855.4,37.6},{-10121.4,62.5,-15870.8,37.1},{-10144.5,62.4,-15886.4,36.6},{-10167.7,62.5,-15902,36.4},{-10190.8,62.5,-15917.6,36.6},{-10213.8,62.5,-15933.2,36.9},
{-10230.8,62.5,-15944.6,36.9},{-10251,62.5,-15958.3,36.5},{-10274,62.5,-15973.8,36.8},{-10302.4,62.5,-15992.9,36.9},{-10325.2,62.5,-16008.3,36.7},{-10348,62.5,-16023.7,36.5},{-10370.8,62.5,-16039,36.5},{-10393.4,62.5,-16054.3,36.4},{-10418.9,62.5,-16071.5,36.8},{-10441.5,62.5,-16086.7,36.7},
{-10464,62.5,-16101.9,36.5},{-10486.5,62.5,-16117.1,36.6},{-10509.2,62.5,-16131.6,35.4},{-10532.4,62.5,-16145.3,34.6},{-10555.7,62.5,-16158.7,34.9},{-10578.9,62.5,-16172.1,35.3},{-10602.3,62.5,-16185.1,36.1},{-10625.5,62.4,-16198.2,36.6},{-10648.5,62.5,-16211.5,36.7},{-10668.5,62.5,-16223,36.9},
{-10691.3,62.5,-16236.2,36.9},{-10714.1,62.5,-16249.3,36.8},{-10736.8,62.5,-16262.5,36.7},{-10762.4,62.5,-16277.2,37.7},{-10790.5,62.5,-16293.4,36.8},{-10815.2,62.5,-16307.7,37.1},{-10839.7,62.4,-16321.9,37.2},{-10863.5,62.5,-16335.6,37.1},{-10892.4,62.5,-16352.3,37.1},{-10914.7,62.5,-16365.1,36.9},
{-10938.2,62.5,-16378.7,36.7},{-10965.9,62.5,-16394.7,36.6},{-10990.3,62.5,-16408.8,36.6},{-11016.9,62.5,-16424.1,37.3},{-11041.4,62.5,-16438.3,37.1},{-11065.1,62.5,-16452,36.7},{-11090.2,62.5,-16466.5,36.8},{-11114.6,62.5,-16480.5,36.7},{-11138.8,62.5,-16494.5,36.7},{-11162.6,62.5,-16508.3,36.7},
{-11187,62.5,-16522.4,36.6},{-11211,62.5,-16536.2,36.6},{-11235,62.5,-16550.1,36.8},{-11258.8,62.5,-16563.8,36.6},{-11282.7,62.5,-16577.6,36.7},{-11306.3,62.5,-16591.2,36.6},{-11329.9,62.5,-16604.9,36.7},{-11353.4,62.5,-16618.4,36.9},{-11376.3,62.5,-16631.6,37.2},{-11400.3,62.5,-16645.4,35.4},
{-11424.5,62.5,-16656.6,34.9},{-11454.5,62.5,-16669.8,36.6},{-11479,62.5,-16681.2,36.6},{-11503.2,62.5,-16692.7,37.1},{-11528.7,62.5,-16704.5,36.8},{-11552.8,62.5,-16715.8,36.6},{-11577.5,62.5,-16727.2,36.7},{-11602,62.5,-16738.7,36.8},{-11626.3,62.5,-16750.1,36.9},{-11649.8,62.5,-16761,36.9},
{-11668.5,62.5,-16769.7,37.2},{-11692.3,62.5,-16780.8,36.8},{-11717.2,62.5,-16792.4,36.8},{-11740.9,62.5,-16803.5,36.7},{-11763.7,62.5,-16814.1,36.7},{-11788.4,62.5,-16825.6,36.8},{-11813.3,62.5,-16837.3,37.4},{-11831.5,62.5,-16845.7,37.1},{-11861.1,62.5,-16859.5,37.3},{-11879.7,62.5,-16868.2,36.9},
{-11903.5,62.5,-16879.3,36.8},{-11927,62.5,-16890.3,36.8},{-11954.2,62.5,-16902.9,36.9},{-11978.1,62.5,-16914.1,36.7},{-12003.7,62.5,-16926,37.3},{-12026.8,62.5,-16936.8,37.3},{-12051.2,62.5,-16948.2,37.2},{-12074.7,62.5,-16959.1,36.9},{-12098,62.5,-16970,36.8},{-12118.4,62.5,-16979.6,37.3},
{-12144.3,62.5,-16991.6,36.9},{-12172.6,62.5,-17004.8,37.1},{-12192.5,62.5,-17014.1,36.8},{-12219.5,62.5,-17026.7,36.9},{-12250.5,62.5,-17041.1,36.9},{-12276.2,62.5,-17053.1,36.8},{-12295,62.5,-17061.9,36.9},{-12318.4,62.5,-17072.8,36.7},{-12345.4,62.5,-17085.6,35.3},{-12363.2,62.5,-17094.9,33},
{-12389.3,62.5,-17108.5,30.6},{-12407,62.5,-17118.4,30.3},{-12431.3,62.5,-17132.4,29.7},{-12456.3,62.5,-17147.6,31.2},{-12474,62.5,-17158.5,33.2},{-12497.1,62.5,-17173.8,36},{-12521.4,62.5,-17188.3,36.5},{-12544.5,62.5,-17201.7,36.7},{-12568.7,62.5,-17215.7,37.2},{-12586.5,62.5,-17226.1,37.2},
{-12610.6,62.5,-17239.9,36.9},{-12635.8,62.5,-17254.5,36.9},{-12661.2,62.5,-17269.2,36.9},{-12684.6,62.5,-17282.7,36.7},{-12708.3,62.5,-17296.4,36.9},{-12732.4,62.5,-17310.3,37.1},{-12756.1,62.5,-17324,37.3},{-12773.9,62.5,-17334.2,37},{-12798.8,62.5,-17348.6,36.7},{-12823.4,62.4,-17362.9,36.6},
{-12847.5,62.4,-17376.7,36.8},{-12873.7,62.5,-17391.9,36.8},{-12898.9,62.5,-17406.4,37},{-12923.4,62.5,-17420.6,37.5},{-12948.9,62.4,-17435.3,37.2},{-12975.6,62.4,-17450.7,37.1},{-13000.6,62.5,-17465.1,37.2},{-13018,62.5,-17475.2,37.5},{-13042.2,62.5,-17489.2,37.2},{-13066,62.5,-17502.9,36.8},
{-13088.5,62.5,-17515.9,36.6},{-13110.3,62.5,-17528.5,36.7},{-13134.6,62.5,-17542.5,36.7},{-13158.1,62.5,-17556.1,36.6},{-13179.6,62.5,-17568.6,36.7},{-13201.8,62.5,-17581.3,36.6},{-13226.8,62.5,-17595.6,36.5},{-13249.3,62.4,-17609.6,34.5},{-13273.6,62.5,-17625.6,33.2},{-13297.6,62.5,-17642.6,33.3},
{-13322.2,62.5,-17661.4,35.8},{-13347.2,62.5,-17679.4,36.6},{-13371.9,62.5,-17696.7,36.8},{-13395.8,62.5,-17713.5,36.7},{-13419.4,62.4,-17730.1,37},{-13444.5,62.4,-17747.6,36.9},{-13474.6,62.4,-17768.6,37.4},{-13494.3,62.5,-17782.4,37.4},{-13526.4,62.4,-17804.9,37.4},{-13552.8,62.5,-17823.4,36.7},
{-13574.9,62.4,-17838.8,36.7},{-13596.8,62.5,-17854.2,36.8},{-13617.2,62.5,-17868.6,36.8},{-13633.8,62.4,-17880.1,36.9},{-13654.7,62.5,-17894.8,36.7},{-13678.7,62.5,-17911.6,36.7},{-13702.4,62.5,-17928.2,36.9},{-13724.4,62.5,-17943.6,37.2},{-13742.9,62.4,-17956.6,37.4},{-13767,62.5,-17973.4,36.8},
{-13790.5,62.5,-17989.8,36.8},{-13813.7,62.5,-18006.1,37.2},{-13830.5,62.5,-18017.8,37},{-13853.1,62.5,-18033.7,36.7},{-13875,62.5,-18049.1,36.7},{-13899,62.5,-18065.8,36.6},{-13922,62.5,-18081.9,36.9},{-13943.4,62.5,-18097,36.7},{-13960.5,62.5,-18108.8,37.2},{-13988.9,62.5,-18128.7,37.2},
{-14010.5,62.5,-18143.9,37.1},{-14029.1,62.5,-18156.9,37.3},{-14055.3,62.5,-18175.2,36.9},{-14076.3,62.5,-18189.9,36.7},{-14098.4,62.4,-18206.8,35.2},{-14118.5,62.5,-18223.8,35.8},{-14139,62.5,-18241.7,37.1},{-14160,62.5,-18259.3,37.3},{-14175.9,62.4,-18272.6,37},{-14197,62.5,-18290.3,37},
{-14220.2,62.5,-18309.8,36.7},{-14242,62.5,-18328.1,36.9},{-14257.5,62.5,-18341.1,37.4},{-14279.9,62.5,-18359.9,36.7},{-14302.2,62.5,-18378.5,36.7},{-14324,62.5,-18397,36.7},{-14346.2,62.5,-18415.5,36.7},{-14367.5,62.5,-18433.5,37},{-14388.1,62.5,-18450.7,37},{-14403.8,62.5,-18463.8,37.1},
{-14424.2,62.5,-18481,37.3},{-14445.9,62.5,-18499.2,36.8},{-14467.4,62.5,-18517.2,36.7},{-14489.3,62.5,-18535.6,36.7},{-14511.5,62.5,-18554.2,36.8},{-14533.8,62.5,-18572.9,36.8},{-14554.7,62.5,-18590.5,36.8},{-14576.9,62.5,-18609.1,36.8},{-14598.5,62.5,-18627.2,36.8},{-14621.6,62.5,-18646.6,36.7},
{-14644.2,62.5,-18665.6,36.7},{-14666.1,62.5,-18684,36.9},{-14685.9,62.5,-18700.5,36.7},{-14707.6,62.5,-18718.7,36.8},{-14729.8,62.5,-18737.4,36.9},{-14750,62.5,-18754.3,36.8},{-14771.3,62.5,-18772.2,37.2},{-14795.8,62.5,-18792.7,37.2},{-14817.1,62.5,-18810.6,36.7},{-14839.2,62.5,-18829.2,36.7},
{-14859,62.5,-18845.8,36.8},{-14879.6,62.5,-18863.2,35.6},{-14900.8,62.5,-18879.1,33.8},{-14921.6,62.5,-18893.5,34.4},{-14944,62.4,-18908.1,36.3},{-14965.7,62.4,-18923,36.9},{-14987.8,62.5,-18938.4,36.9},{-15009.8,62.5,-18953.8,37.1},{-15031.9,62.5,-18969.3,37},{-15048.4,62.5,-18980.9,37.1},
{-15071.1,62.5,-18996.8,37.1},{-15093.7,62.5,-19012.6,36.9},{-15115.3,62.5,-19027.7,36.8},{-15137.2,62.5,-19043,36.8},{-15160.1,62.5,-19059.1,37.1},{-15187,62.5,-19077.9,36.7},{-15208.5,62.5,-19093,36.8},{-15232.8,62.4,-19110,36.9},{-15260,62.5,-19129,37.1},{-15282.6,62.5,-19144.8,36.7},
{-15306.5,62.5,-19161.6,36.9},{-15323.3,62.5,-19173.3,37.4},{-15346,62.5,-19189.3,37},{-15369,62.5,-19205.4,36.7},{-15393,62.5,-19222.2,37.4},{-15410.4,62.5,-19234.4,37},{-15433.6,62.5,-19250.6,36.7},{-15456.3,62.5,-19266.5,37.3},{-15473.6,62.5,-19278.7,36.8},{-15497,62.5,-19295,36.9},
{-15521.1,62.5,-19311.9,37.3},{-15542.8,62.5,-19327.1,37.3},{-15559.8,62.5,-19339,36.8},{-15584.7,62.5,-19356.5,36.9},{-15601.4,62.5,-19368.1,37},{-15624.9,62.5,-19384.6,36.6},{-15641.7,62.5,-19396.3,37.3},{-15663.6,62.5,-19411.6,36.8},{-15684.9,62.5,-19426.6,36.7},{-15708.3,62.5,-19442.9,37.3},
{-15736.8,62.5,-19461.3,36.4},{-15761.4,62.5,-19475.4,36.9},{-15789.2,62.5,-19491.5,37.2},{-15807.9,62.5,-19502.3,36.8},{-15832.6,62.5,-19516.6,36.9},{-15851.5,62.5,-19527.5,36.9},{-15876.5,62.5,-19541.9,36.9},{-15906.8,62.5,-19559.4,36.7},{-15931.7,62.5,-19573.8,37.2},{-15950.3,62.5,-19584.6,37},
{-15973.7,62.5,-19598,36.7},{-15998.9,62.5,-19612.6,37.1},{-16018,62.5,-19623.6,37},{-16043.1,62.5,-19638.1,36.9},{-16068.5,62.5,-19652.8,36.8},{-16092.2,62.5,-19666.4,37.2},{-16110.4,62.5,-19677,37},{-16137,62.5,-19692.3,36.7},{-16165.2,62.5,-19708.6,37.3},{-16184,62.5,-19719.5,36.8},
{-16207.5,62.5,-19733,36.7},{-16230.7,62.5,-19746.4,36.9},{-16249.9,62.5,-19757.6,37.3},{-16275.7,62.5,-19772.3,36.7},{-16294.1,62.5,-19783.1,37.6},{-16318.5,62.5,-19797.1,36.9},{-16344.5,62.5,-19812.1,36.7},{-16363.5,62.5,-19823.1,37},{-16389.1,62.5,-19837.8,36.8},{-16408.6,62.5,-19849.1,36.9},
{-16435,62.5,-19864.4,36.6},{-16460.8,62.5,-19879.3,36.8},{-16488,62.5,-19895.1,37.5},{-16507.2,62.5,-19906.1,36.7},{-16531.9,62.5,-19920.3,36.9},{-16550.6,62.5,-19931.1,36.8},{-16577.4,62.5,-19946.6,36.7},{-16601.9,62.5,-19960.7,37},{-16620.9,62.5,-19971.9,35.7},{-16646.9,62.5,-19983.7,36},
{-16674.4,62.5,-19996.3,37.1},{-16695.6,62.5,-20006.3,36.7},{-16722.7,62.5,-20018.9,37.5},{-16743.2,62.5,-20028.5,36.8},{-16761.9,62.5,-20037.2,37.5},{-16789.9,62.5,-20050.2,36.8},{-16813.7,62.5,-20061.3,36.7},{-16838.1,62.5,-20072.7,37},{-16861.6,62.5,-20083.6,36.9},{-16886.6,62.5,-20095.4,37.2},
{-16911.3,62.5,-20106.8,36.9},{-16938.2,62.5,-20119.4,36.9},{-16961.6,62.5,-20130.3,36.7},{-16985.3,62.4,-20141.3,36.7},{-17010.9,62.4,-20153.3,36.8},{-17034.2,62.5,-20164.1,36.7},{-17060.1,62.5,-20176.2,37},{-17079.8,62.5,-20185.4,37.1},{-17105.8,62.5,-20197.5,36.9},{-17133.5,62.5,-20210.4,37.4},
{-17165.3,62.5,-20225.3,36.7},{-17193.1,62.5,-20238.2,37.2},{-17212.5,62.5,-20247.3,37},{-17238.5,62.5,-20259.4,36.7},{-17265.8,62.5,-20272.2,36.7},{-17291.7,62.4,-20284.3,36.7},{-17317.5,62.4,-20296.3,36.7},{-17345,62.5,-20309.1,36.7},{-17371,62.5,-20321.2,37},{-17391.7,62.5,-20330.9,37.3},
{-17418.2,62.5,-20343.2,37.3},{-17444.5,62.5,-20355.5,36.7},{-17470.1,62.5,-20367.4,36.7},{-17496.2,62.5,-20379.6,36.7},{-17521.6,62.5,-20391.4,36.8},{-17545.8,62.5,-20402.7,37.2},{-17571.5,62.5,-20414.1,34.9},{-17596.8,62.5,-20423.6,34.5},{-17623.8,62.5,-20432.5,36.5},{-17642.8,62.4,-20439.1,37},
{-17667.7,62.5,-20448.1,37},{-17693.2,62.5,-20457.7,36.3},{-17718.4,62.5,-20467.3,35.3},{-17742.8,62.4,-20475.8,36},{-17768.4,62.5,-20485.1,36.1},{-17793.6,62.5,-20494.2,36.1},{-17819,62.5,-20503.4,36.1},{-17844.2,62.5,-20512.7,36.3},{-17870.7,62.5,-20522.3,36.1},{-17897.8,62.5,-20532.1,36.1},
{-17923.3,62.5,-20541.4,36.2},{-17949.1,62.5,-20550.8,36.2},{-17974.3,62.5,-20559.9,36.3},{-18000.4,62.5,-20569.4,36.8},{-18025.9,62.5,-20578.7,36.8},{-18057.4,62.5,-20590.2,36.5},{-18083.8,62.5,-20599.8,36.4},{-18109.8,62.4,-20609.2,36.3},{-18136.5,62.5,-20618.9,36.3},{-18163.5,62.4,-20628.8,36.2},
{-18190.9,62.4,-20638.7,36.3},{-18218.7,62.5,-20648.8,36.3},{-18246.8,62.5,-20659.1,36.6},{-18275.2,62.5,-20669.4,36.8},{-18311.4,62.5,-20682.6,37},{-18342.4,62.4,-20693.8,36.3},{-18367.5,62.5,-20703,36.6},{-18399.6,62.5,-20714.6,36.6},{-18425.2,62.5,-20724,36.4},{-18454.6,62.5,-20734.6,36.4},
{-18483,62.5,-20745,36.4},{-18512.1,62.5,-20755.6,36.4},{-18540.3,62.5,-20765.8,36.6},{-18569.8,62.5,-20774.7,35.9},{-18599,62.5,-20782.3,36.7},{-18627.7,62.4,-20789.2,38.4},{-18656.7,62.4,-20796.8,38.5},{-18686.8,62.5,-20804.9,38.6},{-18714.8,62.5,-20812.4,38.8},{-18744.2,62.5,-20820.3,38.9},
{-18764.9,62.5,-20825.8,39.1},{-18793.7,62.5,-20833.5,38.6},{-18823.4,62.4,-20841.5,38.6},{-18852.1,62.4,-20849.1,38.9},{-18882.7,62.5,-20857.3,38.6},{-18914.1,62.4,-20865.7,38.8},{-18947,62.5,-20874.6,38.6},{-18977.4,62.4,-20882.7,38.7},{-19004.6,62.5,-20889.9,39.4},{-19025.7,62.5,-20895.6,38.5},
{-19055,62.5,-20903.4,38.7},{-19088.1,62.4,-20912.2,38.6},{-19115.8,62.5,-20919.7,39},{-19135.7,62.5,-20925,38.6},{-19163.4,62.5,-20932.4,39.2},{-19194.3,62.5,-20940.7,38.6},{-19220,62.5,-20947.6,38.7},{-19249.7,62.5,-20955.5,39.4},{-19273.2,62.5,-20961.8,39.1},{-19294.4,62.5,-20967.5,38.9},
{-19325.9,62.5,-20975.9,39.3},{-19347.1,62.5,-20981.6,38.9},{-19378.6,62.5,-20990,38.7},{-19409.6,62.5,-20998.3,38.6},{-19440.9,62.5,-21006.7,38.8},{-19472.3,62.5,-21015.1,39.4},{-19495.4,62.5,-21021.2,38.8},{-19526.7,62.5,-21029.6,38.5},{-19556.2,62.5,-21037.5,39.3},{-19584.6,62.5,-21045.1,39.1},
{-19613,62.5,-21052.7,39},{-19636.5,62.5,-21059,39},{-19668.1,62.5,-21067.4,38.5},{-19698.1,62.5,-21075.4,38.8},{-19727.1,62.5,-21083.2,39.1},{-19748.9,62.5,-21089.1,39.1},{-19779.8,62.5,-21097.3,38.6},{-19807.6,62.5,-21104.8,38.5},{-19835.5,62.5,-21112.2,38.5},{-19863.3,62.4,-21119.7,38.5},
{-19891.2,62.5,-21127.2,38.6},{-19922.1,62.4,-21135.4,39},{-19944.8,62.4,-21141.5,39},{-19975.9,62.4,-21149.8,38.6},{-20003.8,62.4,-21157.2,38.5},{-20034.2,62.5,-21165.4,38.6},{-20066.5,62.4,-21174,38.7},{-20088.6,62.4,-21179.9,38.9},{-20116.8,62.5,-21187.5,38.6},{-20144,62.4,-21194.7,38.6},
{-20164.3,62.4,-21200.2,38.9},{-20195.8,62.5,-21208.6,38.5},{-20223.9,62.4,-21216.1,39.1},{-20245.2,62.5,-21221.8,38.8},{-20276.4,62.5,-21230.2,38.6},{-20297.1,62.5,-21235.7,39.2},{-20326,62.5,-21243.4,38.6},{-20354.2,62.4,-21251,39.2},{-20375.1,62.5,-21256.6,38.6},{-20404,62.5,-21264.3,38.8},
{-20424.6,62.5,-21269.8,38.7},{-20455.9,62.4,-21278.2,38.6},{-20483.8,62.5,-21285.7,39.3},{-20504.2,62.5,-21291.2,38.5},{-20532.8,62.5,-21298.9,39.3},{-20553.3,62.5,-21304.4,38.6},{-20584.9,62.4,-21312.8,38.8},{-20604.9,62.5,-21318.2,39},{-20634.6,62.5,-21326.1,38.6},{-20655,62.5,-21331.5,39.1},
{-20684.4,62.4,-21339.4,38.6},{-20711.8,62.5,-21346.7,38.8},{-20732.3,62.4,-21352.3,39.2},{-20761.9,62.4,-21360.1,38.5},{-20791.4,62.4,-21368.1,39},{-20812.9,62.4,-21373.8,38.8},{-20843.4,62.4,-21381.9,38.7},{-20872.4,62.5,-21389.7,39.1},{-20894.9,62.5,-21395.7,38.7},{-20924.2,62.5,-21403.6,38.5},
{-20953,62.5,-21411.2,38.5},{-20982,62.5,-21419.1,38.8},{-21004.3,62.5,-21425,39.4},{-21032.8,62.5,-21432.6,39.4},{-21062.8,62.5,-21440.7,38.7},{-21094.3,62.5,-21449.1,38.6},{-21124.6,62.5,-21457.2,38.8},{-21153.6,62.5,-21464.9,38.8},{-21184.6,62.5,-21473.3,39.1},{-21206.9,62.5,-21479.2,38.8},
{-21238.3,62.5,-21487.7,38.4},{-21269.8,62.5,-21496.1,38.7},{-21298.7,62.5,-21503.9,38.4},{-21330.6,62.5,-21512.4,39},{-21359.8,62.5,-21520.3,38.5},{-21383.4,62.5,-21526.7,38.7},{-21415.7,62.5,-21535.4,38.1},{-21448.1,62.5,-21544.1,37.8},{-21480.8,62.5,-21552.7,38.5},{-21510.8,62.5,-21560.6,38.6},
{-21544.4,62.5,-21569.5,39.1},{-21565.3,62.5,-21575.1,38.7},{-21584.7,62.5,-21580.3,38.8},{-21612.7,62.5,-21587.8,38.7},{-21642.2,62.5,-21595.7,39},{-21662.3,62.5,-21601,38.5},{-21689.8,62.5,-21608.4,38.8},{-21725.9,62.5,-21618.1,38.6},{-21752.8,62.5,-21625.2,38.7},{-21772.5,62.5,-21630.5,38.9},
{-21800,62.5,-21637.9,38.7},{-21819.7,62.5,-21643.1,38.8},{-21848.1,62.5,-21650.7,38.6},{-21878.7,62.5,-21658.9,38.7},{-21914.6,62.5,-21668.6,39},{-21945.4,62.5,-21676.8,38.8},{-21977,62.5,-21685.2,38.7},{-22007,62.5,-21693.3,38.5},{-22034.9,62.5,-21700.9,38.8},{-22055.6,62.5,-21706.5,38.4},
{-22085.6,62.5,-21714.6,38},{-22113.5,62.5,-21722.2,38.2},{-22133.5,62.5,-21727.6,37.8},{-22165.3,62.5,-21736.2,37.7},{-22193,62.5,-21743.6,37.9},{-22218.6,62.5,-21750.5,37.5},{-22247.6,62.5,-21758.4,37.1},{-22278.2,62.5,-21766.7,37.2},{-22298.6,62.5,-21772.1,37.1},{-22327.2,62.5,-21779.6,37.4},
{-22348.5,62.5,-21785.1,38.4},{-22379.6,62.4,-21792.9,38.6},{-22408.9,62.5,-21800.8,38.9},{-22429.6,62.5,-21806.4,39},{-22460.6,62.5,-21814.6,38.7},{-22489.4,62.5,-21822.3,38.8},{-22510.1,62.5,-21827.9,38.9},{-22538.8,62.5,-21835.6,38.6},{-22564.9,62.5,-21842.6,38.9},{-22585.7,62.5,-21848.1,38.7},
{-22614.5,62.5,-21855.9,38.7},{-22652.9,62.5,-21866.1,39.5},{-22681.8,62.5,-21873.9,38.6},{-22711.6,62.5,-21881.8,38.8},{-22749.4,62.5,-21891.9,39.1},{-22770.2,62.5,-21897.5,39.3},{-22808.1,62.5,-21907.6,38.7},{-22841.2,62.5,-21916.5,38.8},{-22876,62.5,-21925.8,39.5},{-22896.1,62.5,-21931.2,39.1},
{-22917.1,62.5,-21936.8,38.7},{-22946.4,62.5,-21944.6,38.8},{-22978.9,62.5,-21953.4,38.9},{-23000.1,62.5,-21959,38.9},{-23032.7,62.5,-21967.7,38.8},{-23062.7,62.5,-21975.8,38.7},{-23092.2,62.5,-21983.7,39.4},{-23130.3,62.5,-21993.9,38.5},{-23162.5,62.5,-22002.6,38.4},{-23192.1,62.5,-22010.7,38},
{-23226.6,62.5,-22020.1,38.1},{-23255.1,62.5,-22027.8,37.5},{-23284.1,62.5,-22035.7,37.1},{-23314.7,62.5,-22043.9,37},{-23343.4,62.5,-22050.5,35.7},{-23373.8,62.5,-22056.5,33.9},{-23402.5,62.5,-22061.5,34.2},{-23432.8,62.5,-22066.2,36},{-23461.5,62.4,-22070.3,37.9},{-23491.5,62.4,-22075.7,37.7},
{-23518.9,62.5,-22080.5,37.6},{-23549.5,62.5,-22085.7,38.5},{-23577.7,62.5,-22090.6,38.8},{-23598.2,62.5,-22094.1,39.1},{-23627.7,62.5,-22099.3,38.5},{-23654.7,62.5,-22104.1,38.5},{-23685.1,62.5,-22109.4,38.3},{-23712.8,62.5,-22114.3,38.5},{-23735.5,62.5,-22118.3,38.5},{-23762.2,62.5,-22123,38.5},
{-23788.9,62.5,-22127.7,38.5},{-23815.6,62.5,-22132.4,38.4},{-23842.2,62.5,-22137.1,38.4},{-23868.7,62.5,-22141.7,38.3},{-23895.3,62.5,-22146.4,38.3},{-23921.8,62.5,-22151.1,38.2},{-23948.2,62.5,-22155.7,38.3},{-23975.4,62.5,-22160.6,38.7},{-24000.9,62.5,-22165.1,38.7},{-24027.8,62.5,-22169.7,38.9},
{-24055.6,62.5,-22174.6,38.6},{-24088.1,62.5,-22180.3,38.6},{-24114.9,62.5,-22184.7,37.7},{-24143.2,62.5,-22187,34.1},{-24171.7,62.5,-22188.5,31.9},{-24203.6,62.5,-22189.4,32.4},{-24232.7,62.4,-22189.7,35.1},{-24264.9,62.5,-22190.1,37.8},{-24293.8,62.5,-22191.1,37.7},{-24322.4,62.5,-22192.1,37.8},
{-24353.1,62.5,-22193.1,38.1},{-24375,62.5,-22193.9,38.7},{-24405.4,62.5,-22195,38},{-24433,62.5,-22195.9,38},{-24460.6,62.5,-22196.9,38.2},{-24488.1,62.5,-22197.8,38.1},{-24515.4,62.5,-22198.8,38.2},{-24542.8,62.5,-22199.7,38.1},{-24570.1,62.5,-22200.7,38.1},{-24597.3,62.5,-22201.6,38},
{-24624.5,62.5,-22202.6,37.9},{-24651.5,62.5,-22203.5,37.8},{-24679,62.5,-22204.4,37.7},{-24701.1,62.5,-22205.2,38.3},{-24727.1,62.5,-22206.1,38},{-24752.9,62.5,-22207.1,37.8},{-24779.8,62.5,-22207.9,37.8},{-24808.6,62.5,-22208.9,37.8},{-24838.4,62.6,-22208.5,35.6},{-24865.1,62.5,-22205.7,34.2},
{-24891.5,62.5,-22201.9,35.5},{-24917.7,62.5,-22198.8,36.5},{-24943.7,62.5,-22196.4,37.1},{-24969.3,62.5,-22193.9,37.6},{-24994.6,62.5,-22191.3,37.7},{-25019.8,62.5,-22188.7,37.6},{-25044.8,62.5,-22186,37.5},{-25069.6,62.5,-22183.5,37.4},{-25094.2,62.5,-22180.8,37.3},{-25119.6,62.5,-22178.2,37.2},
{-25141,62.5,-22175.9,37.6},{-25168.8,62.5,-22173,37.3},{-25196.1,62.5,-22170.1,37.4},{-25224.9,62.5,-22167.1,37.3},{-25251.1,62.5,-22164.3,37.6},{-25283.9,62.5,-22160.8,37.6},{-25305.8,62.5,-22158.5,37.6},{-25334.3,62.5,-22155.5,37.3},{-25359.8,62.5,-22152.8,37.5},{-25384.8,62.5,-22150.2,37.6},
{-25412.7,62.5,-22147.3,37.3},{-25437.3,62.5,-22144.6,37.3},{-25461.9,62.5,-22142.1,37.4},{-25492,62.5,-22138.9,38},{-25514.6,62.5,-22136.5,37.2},{-25545.1,62.5,-22133.4,37.9},{-25566.7,62.5,-22130.3,36.8},{-25595.7,62.5,-22122.9,36.2},{-25616.4,62.5,-22117.1,37.2},{-25645.6,62.5,-22110,37.8},
{-25666,62.5,-22105.1,37.9},{-25695.7,62.5,-22097.7,38.4},{-25716.4,62.5,-22092.6,38},{-25746.1,62.5,-22085.2,37.9},{-25767.1,62.5,-22080,38.5},{-25796.6,62.5,-22072.6,37.8},{-25817.2,62.5,-22067.4,38.4},{-25845.2,62.5,-22060.5,37.8},{-25874.1,62.5,-22053.2,38.2},{-25906.4,62.5,-22045.2,38.2},
{-25935.5,62.5,-22037.9,37.8},{-25956.6,62.5,-22032.6,38.5},{-25983.9,62.5,-22025.8,37.7},{-26013.1,62.5,-22018.5,38.3},{-26033.7,62.5,-22013.4,38.3},{-26063.2,62.5,-22006.1,37.9},{-26090.7,62.5,-21999.1,38.1},{-26110.8,62.5,-21994.1,38},{-26138.8,62.5,-21987.1,37.8},{-26166.6,62.5,-21980.2,38.6},
{-26186.3,62.5,-21975.3,37.8},{-26213.5,62.5,-21968.6,38.2},{-26234.9,62.5,-21963.2,38.4},{-26264.1,62.5,-21956.1,37.5},{-26291.1,62.5,-21948.9,36.1},{-26317,62.5,-21939.3,33.8},{-26343.4,62.5,-21927.6,36.5},{-26362.4,62.5,-21919.6,37.6},{-26388.1,62.5,-21909.3,37.3},{-26413.9,62.5,-21898.8,37.4},
{-26440.1,62.5,-21888.2,37.8},{-26459.1,62.5,-21880.6,37.8},{-26484.6,62.5,-21870.3,37.3},{-26510.2,62.5,-21859.9,37.4},{-26535.8,62.5,-21849.6,37.7},{-26554.5,62.5,-21842,37.9},{-26580.4,62.5,-21831.6,37.4},{-26604.4,62.5,-21821.8,37.4},{-26628.9,62.5,-21811.9,37.9},{-26649,62.5,-21803.7,37.9},
{-26674.5,62.5,-21793.4,37.8},{-26700.3,62.5,-21783,37.7},{-26725.6,62.5,-21772.8,37.5},{-26750.6,62.5,-21762.7,37.3},{-26776.1,62.5,-21752.4,37.4},{-26802.2,62.5,-21741.8,37.3},{-26828.3,62.5,-21731.2,37.4},{-26854.3,62.5,-21720.7,37.4},{-26880.2,62.5,-21710.2,37.4},{-26905.9,62.5,-21699.9,37.5},
{-26931.1,62.5,-21689.7,37.5},{-26962.1,62.5,-21677.3,37.3},{-26991.3,62.5,-21664.2,35.4},{-27026.3,62.5,-21645,34.2},{-27049,62.5,-21630.6,36.4},{-27071.8,62.5,-21617.5,36.6},{-27099.8,62.5,-21601.3,36.5},{-27122.7,62.5,-21588,36.5},{-27145.3,62.5,-21574.9,36.5},{-27169.4,62.5,-21561,36},
{-27192.2,62.5,-21547.8,36.1},{-27215.7,62.5,-21534.3,36.2},{-27237.6,62.5,-21521.6,36.1},{-27259.8,62.5,-21508.8,36.1},{-27282.3,62.5,-21495.8,36.1},{-27304.8,62.5,-21482.8,36.2},{-27327.4,62.5,-21469.7,36.3},{-27350.4,62.5,-21456.5,36.6},{-27373.3,62.5,-21443.2,36.7},{-27402.1,62.5,-21426.6,36.4},
{-27425.4,62.5,-21413.1,36.2},{-27448.7,62.5,-21399.7,36.1},{-27472.2,62.5,-21386.1,36.1},{-27495.6,62.5,-21372.6,36},{-27517.9,62.5,-21359.7,36},{-27542,62.5,-21346,35.6},{-27565.8,62.5,-21332.5,35.2},{-27589.4,62.5,-21319,35},{-27611.3,62.5,-21305.9,35.8},{-27633.4,62.5,-21292.1,35.4},
{-27653.5,62.5,-21276.2,35.5},{-27673.9,62.5,-21260,36.4},{-27693.7,62.5,-21244.6,36.6},{-27714.2,62.5,-21228.6,36.5},{-27734.1,62.5,-21213.1,36.3},{-27754.6,62.5,-21197,36.4},{-27774.5,62.5,-21181.4,36.5},{-27794.8,62.5,-21165.6,36.6},{-27815.2,62.5,-21149.6,36.6},{-27835.6,62.5,-21133.8,36.6},
{-27855.8,62.5,-21118,36.6},{-27876.6,62.5,-21101.6,37},{-27897,62.5,-21085.6,37.1},{-27916.9,62.5,-21070.1,36.9},{-27937.2,62.5,-21054.2,36.8},{-27957.7,62.5,-21038.2,36.7},{-27978.2,62.5,-21022.1,36.6},{-27998.9,62.5,-21005.9,36.6},{-28019.8,62.5,-20989.6,36.6},{-28040.7,62.5,-20973.3,36.5},
{-28061.5,62.5,-20957.1,36.5},{-28082.2,62.5,-20940.8,36.7},{-28102.8,62.5,-20924.8,37.1},{-28129.5,62.5,-20904,36.9},{-28151.1,62.5,-20887.2,36.6},{-28172.3,62.5,-20870.8,36.1},{-28193.1,62.5,-20854.8,35.5},{-28213.7,62.5,-20838.1,36.5},{-28237.5,62.5,-20815.3,36},{-28259.4,62.5,-20792,37.2},
{-28277.7,62.5,-20773,37.5},{-28295.7,62.5,-20754.5,37.4},{-28313.4,62.5,-20736.1,37.3},{-28336,62.5,-20712.7,37.4},{-28354.1,62.5,-20694,37.2},{-28371.9,62.5,-20675.5,37.1},{-28390.2,62.5,-20656.5,37},{-28409,62.5,-20637.1,37},{-28426.6,62.5,-20618.8,36.9},{-28444.5,62.5,-20600.3,37.1},
{-28462.6,62.5,-20581.5,37.2},{-28480.8,62.5,-20562.6,37.1},{-28499.1,62.5,-20543.7,37.3},{-28522.2,62.5,-20519.8,37.4},{-28540.4,62.5,-20500.8,37.2},{-28558.6,62.5,-20482.1,37},{-28576.4,62.5,-20463.6,36.9},{-28595.7,62.5,-20443.6,36.8},{-28614.6,62.5,-20424.1,36.7},{-28633.2,62.5,-20405,36.6},
{-28650.3,62.5,-20385.6,34.4},{-28665.9,62.5,-20364.9,33.3},{-28679.9,62.4,-20343.8,35.8},{-28695.3,62.5,-20322.1,36.4},{-28711.8,62.5,-20299.3,36.4},{-28727.3,62.5,-20277.9,36.4},{-28742.4,62.5,-20257,36.5},{-28757.3,62.5,-20236.6,36.4},{-28772.4,62.5,-20215.7,36.5},{-28787.9,62.5,-20194.4,36.8},
{-28807.5,62.5,-20167.4,36.7},{-28823,62.5,-20146.1,36.6},{-28838,62.5,-20125.4,36.7},{-28853.2,62.5,-20104.4,36.8},{-28872.7,62.5,-20077.6,36.8},{-28887.8,62.5,-20056.7,36.9},{-28903.6,62.5,-20035.1,36.9},{-28919.6,62.5,-20012.9,36.9},{-28939.9,62.5,-19985,36.9},{-28956.2,62.5,-19962.6,36.8},
{-28972.3,62.5,-19940.5,36.7},{-28988.2,62.5,-19918.4,36.6},{-29002.2,62.5,-19896,33.9},{-29014.4,62.5,-19872.8,34.2},{-29026.2,62.5,-19849.6,35.6},{-29038.1,62.5,-19827,35.7},{-29050,62.5,-19804.6,35.6},{-29062.4,62.5,-19781.3,35.7},{-29074.3,62.5,-19759.1,35.7},{-29087.2,62.5,-19734.6,36},
{-29099.2,62.5,-19712,35.9},{-29111.4,62.5,-19689.1,35.8},{-29123.6,62.5,-19666.2,35.7},{-29135.7,62.5,-19643.3,35.7},{-29147.8,62.5,-19620.4,35.7},{-29160,62.5,-19597.6,35.8},{-29172.2,62.5,-19574.7,35.7},{-29184.3,62.5,-19551.9,35.8},{-29196.4,62.5,-19529.1,35.8},{-29209.1,62.5,-19505.3,35.7},
{-29221.7,62.5,-19480.4,35.3},{-29231.9,62.5,-19455.1,35.9},{-29241.6,62.5,-19430.2,36.5},{-29249.2,62.5,-19411.5,36.4},{-29258.9,62.5,-19387.3,36.5},{-29268.8,62.5,-19362.9,36.3},{-29278.5,62.5,-19338.7,36.4},{-29288.5,62.5,-19314,36.1},{-29298.4,62.5,-19289.6,36.1},{-29307.9,62.5,-19266.2,36.3},
{-29317.9,62.5,-19241.2,36.1},{-29327.8,62.5,-19216.8,36.2},{-29337.8,62.5,-19192.1,36.2},{-29348,62.5,-19166.8,36.2},{-29358.2,62.5,-19141.4,36.1},{-29368.3,62.5,-19116.3,36.2},{-29379,62.5,-19089.8,36},{-29388.8,62.5,-19065.6,36.4},{-29399.2,62.5,-19039.8,36.4},{-29409.8,62.5,-19013.6,36.4},
{-29420.3,62.5,-18987.5,36.6},{-29428,62.5,-18968.4,36.4},{-29438.6,62.5,-18942.1,36.2},{-29449.4,62.5,-18915.6,36.2},{-29460,62.5,-18889.3,36},{-29470.5,62.5,-18863.3,36},{-29480.7,62.5,-18838.1,36.4},{-29491.8,62.5,-18810.5,36.4},{-29502.8,62.5,-18783.3,36.4},{-29510.8,62.5,-18763.7,36.4},
{-29521.7,62.5,-18736.9,36},{-29532.4,62.5,-18710.9,35.3},{-29542.7,62.5,-18685.8,34.7},{-29552.9,62.5,-18661,34.4},{-29562.9,62.5,-18636.5,34.4},{-29572.7,62.5,-18611.2,35.1},{-29582.1,62.5,-18587.2,36},{-29592.3,62.5,-18562.6,36.9},{-29578.9,62.5,-18594.7,36.3},{-29588.5,62.5,-18571.2,36.4},
{-29599.1,62.5,-18548.6,35.7},{-29610.5,62.5,-18525.7,33.9},{-29622.3,62.5,-18503.1,32.6},{-29634.7,62.5,-18480.8,32.8},{-29647.9,62.5,-18458.6,34.2},{-29660.6,62.5,-18436.6,35.3},{-29673,62.5,-18414.3,35.6},{-29687.6,62.5,-18387.9,35.2},{-29701.8,62.5,-18362.3,35.3},{-29716.1,62.5,-18336.5,35.6},
{-29726.3,62.5,-18318.1,35.7},{-29740.3,62.5,-18292.9,35.2},{-29754.2,62.5,-18267.7,35.3},{-29766.8,62.5,-18242.9,34.5},{-29775.3,62.5,-18223.7,34.8},{-29786.4,62.5,-18198.5,34.5},{-29797.4,62.5,-18173.8,35.1},{-29805.7,62.5,-18155.1,35},{-29816.9,62.5,-18130,34.6},{-29828.3,62.5,-18104.3,34.9},
{-29836.7,62.5,-18085.5,35.2},{-29848,62.5,-18060.1,34.6},{-29859.3,62.5,-18034.7,34.9},{-29867.4,62.5,-18016.4,35},{-29878.9,62.5,-17990.6,34.6},{-29888.8,62.5,-17964,34.3},{-29897.8,62.5,-17937.7,34.5},{-29906.7,62.5,-17912.2,35.1},{-29913.3,62.5,-17892.9,34.7},{-29922.1,62.5,-17867.3,34.5},
{-29931.2,62.5,-17840.9,34.5},{-29939.9,62.5,-17815.7,34.9},{-29949,62.5,-17789.3,35.1},{-29955.8,62.5,-17769.5,35},{-29964.6,62.5,-17743.9,34.7},{-29973.5,62.5,-17717.9,34.5},{-29982,62.5,-17691.9,34.3},{-29988.7,62.5,-17665.7,34},{-29995.1,62.5,-17640.1,33.9},{-30001.6,62.5,-17614.2,33.8},
{-30008,62.5,-17588.7,33.7},{-30014.4,62.5,-17563.6,33.8},{-30020.6,62.5,-17538.4,33.9},{-30028.5,62.5,-17507.1,33.9},{-30034.8,62.5,-17482,33.5},{-30041.1,62.5,-17456.9,33.2},{-30047.4,62.5,-17432,33.3},{-30053.6,62.5,-17405.7,33.2},{-30058.3,62.5,-17379.3,32.6},{-30061.7,62.4,-17353.2,34.2},
{-30065.6,62.5,-17327.7,34.4},{-30069.6,62.5,-17302.6,34.5},{-30073.6,62.5,-17277.2,34.7},{-30077.7,62.5,-17251.4,35.2},{-30082.1,62.4,-17219.2,35.9},{-30086.3,62.5,-17192.9,35.7},{-30090.4,62.4,-17166.6,35.8},{-30094.6,62.5,-17140.2,35.8},{-30098.8,62.5,-17113.8,35.8},{-30101.4,62.5,-17087.4,35.2},
{-30103.2,62.4,-17061.6,35.4},{-30104.9,62.5,-17035.7,35.8},{-30107.4,62.4,-17004.1,35.2},{-30109.3,62.4,-16978.5,34.8},{-30110.8,62.4,-16952.4,35.3},{-30112.5,62.4,-16926.8,35.6},{-30114.4,62.4,-16900.1,35.6},{-30116.2,62.5,-16873.4,35.5},{-30118.1,62.5,-16847,35.6},{-30119.9,62.5,-16820.7,35.7},
{-30121.4,62.5,-16795.1,35.5},{-30121.2,62.4,-16769.2,35.4},{-30120.7,62.4,-16743.6,35.6},{-30120.2,62.5,-16718.1,35.8},{-30119.8,62.4,-16692.8,35.9},{-30119.3,62.4,-16667,36},{-30118.9,62.4,-16641,35.8},{-30118.4,62.5,-16614.9,35.8},{-30118,62.5,-16589.1,35.7},{-30117.5,62.5,-16563.3,35.7},
{-30117.1,62.5,-16538,35.7},{-30116.6,62.5,-16512.9,35.8},{-30116,62.5,-16487.7,35.3},{-30113.9,62.4,-16463.1,35.1},{-30111.4,62.4,-16438.7,35.2},{-30108.7,62.5,-16413.7,35.1},{-30106.1,62.4,-16388.7,35.3},{-30103.5,62.4,-16364.4,35.3},{-30100.6,62.5,-16336.3,35.2},{-30097.7,62.5,-16308.2,35.3},
{-30094.1,62.5,-16274.6,35.5},{-30091.2,62.5,-16246.9,35.3},{-30088.3,62.4,-16219.5,35.2},{-30085.4,62.5,-16192.3,35.3},{-30083.1,62.4,-16165.5,35.4},{-30082.6,62.4,-16145,34.5},{-30082.5,62.5,-16118.8,34.9},{-30082.1,62.4,-16091.9,35},{-30081.6,62.4,-16064.1,35},{-30081.2,62.5,-16037.1,35.1},
{-30080.7,62.4,-16010.3,35.1},{-30080.2,62.5,-15983.9,35},{-30079.8,62.5,-15957.6,35.2},{-30079.3,62.5,-15931.4,35.3},{-30078.8,62.5,-15904.7,35.1},{-30078.4,62.5,-15878,35.1},{-30078.2,62.4,-15851.6,34.7},{-30080,62.4,-15825.8,34.8},{-30081.9,62.5,-15800.6,35.1},{-30083.7,62.4,-15775.4,35},
{-30085.5,62.5,-15749.5,35.1},{-30087.3,62.4,-15724.3,35.1},{-30089.1,62.4,-15697.7,35},{-30091,62.5,-15671.1,35.1},{-30092.8,62.5,-15645.3,35},{-30094.6,62.5,-15619.4,35.2},{-30096.4,62.5,-15593.1,35.1},{-30098.2,62.4,-15567.9,35.2},{-30100,62.4,-15542.9,35.5},{-30104.6,62.4,-15510.3,35.7},
{-30109.9,62.5,-15478.3,35.5},{-30113.9,62.4,-15452.6,35.4},{-30117.9,62.5,-15427.2,35.6},{-30122,62.5,-15401.6,35.8},{-30126.1,62.5,-15375.5,36},{-30130.2,62.5,-15349.5,35.8},{-30134.5,62.5,-15322.9,35.6},{-30138.7,62.5,-15295.9,35.5},{-30142.8,62.5,-15270,35.4},{-30146.7,62.4,-15245.3,35.5},
{-30149.8,62.4,-15219.1,35.4},{-30151.5,62.4,-15193.2,35.6},{-30153.2,62.4,-15168.1,35.7},{-30155,62.4,-15143,35.8},{-30156.8,62.5,-15117.5,35.9},{-30158.5,62.4,-15092.4,35.9},{-30160.4,62.4,-15066,36.2},{-30162.2,62.4,-15040.4,36},{-30164,62.5,-15014.6,35.8},{-30165.9,62.5,-14988.1,35.8},
{-30167.6,62.5,-14962.3,35.7},{-30169.6,62.5,-14935.1,35.7},{-30170.3,62.4,-14908.7,36.2},{-30169.8,62.4,-14883,36.2},{-30169.3,62.5,-14857.1,36.2},{-30168.9,62.4,-14831.8,36.1},{-30168.4,62.4,-14805.4,36.1},{-30168,62.4,-14779.8,36},{-30167.5,62.4,-14753.1,36.1},{-30167.1,62.4,-14726.2,36.1},
{-30166.6,62.5,-14699.7,36.4},{-30166,62.4,-14665.6,36.6},{-30165.5,62.4,-14638.8,36.1},{-30165,62.5,-14612.2,36.1},{-30162.9,62.5,-14583.9,35},{-30159.8,62.4,-14556.1,35.7},{-30157,62.5,-14529.3,35.9},{-30154,62.4,-14501.7,36.1},{-30151.1,62.4,-14474.3,36.3},{-30149,62.4,-14454,35.9},
{-30146.1,62.4,-14426.4,35.7},{-30143.1,62.4,-14397.6,35.6},{-30140.1,62.5,-14369.3,35.6},{-30136.7,62.5,-14336.4,35.8},{-30133.6,62.5,-14307.2,35.6},{-30130.2,62.5,-14278.5,35.4},{-30125.2,62.4,-14250.8,35.3},{-30119.9,62.4,-14224.2,35.7},{-30114.5,62.4,-14196.7,36},{-30109.1,62.4,-14169,36.2},
{-30102.7,62.4,-14136.1,35.7},{-30097.2,62.5,-14108,35.7},{-30091.8,62.5,-14080,36},{-30085.4,62.5,-14047.1,35.6},{-30080.2,62.5,-14020.4,35.9},{-30073.8,62.6,-13987,35.8},{-30068.4,62.9,-13959,35.6},{-30062.9,63,-13931.7,36.1},{-30057.2,62.9,-13905,37.3},{-30051.2,62.9,-13878.9,39.2},
{-30046.8,62.9,-13853.2,38.9},{-30044.3,62.9,-13827.8,39.3},{-30041.5,62.9,-13796.2,39.3},{-30041.1,62.9,-13775.7,39.5},{-30040.8,62.9,-13748.6,39.5},{-30041.2,62.9,-13721.2,39.5},{-30043.8,62.9,-13688.4,40.3},{-30046.1,62.9,-13660.9,39.8},{-30050.4,62.9,-13633.8,39.9},{-30055.2,62.9,-13606.7,40},
{-30060.5,62.9,-13579.2,40.3},{-30065.8,62.9,-13554.5,39.9},{-30071.6,62.9,-13529.8,40.1},{-30077.9,62.9,-13505,39.9},{-30084.3,62.9,-13480.2,39.5},{-30091,62.9,-13454.5,39},{-30097.3,62.9,-13430,38.8},{-30103.9,62.9,-13404.5,38.4},{-30111,62.9,-13378.4,38.4},{-30120,62.9,-13351.9,38.6},
{-30129.5,62.9,-13325.5,38.8},{-30140.2,62.9,-13299.4,37.7},{-30151.7,62.9,-13273.7,38.1},{-30164,62.9,-13249,37.7},{-30177,62.9,-13225.1,37.3},{-30194.6,62.9,-13197,39.3},{-30210.1,62.9,-13174.5,39.8},{-30226.3,62.9,-13151.5,39.9},{-30242.4,62.9,-13129.4,39.9},{-30258.3,62.9,-13108.6,39.9},
{-30274.3,62.9,-13088.3,39.9},{-30291.6,62.9,-13067.5,39.9},{-30308.3,62.9,-13047.6,39.8},{-30324.5,62.9,-13028.3,39.9},{-30341.6,62.9,-13007.8,39.6},{-30358.3,62.9,-12987.2,38.6},{-30374.8,62.9,-12966.2,38.2},{-30389.4,62.9,-12945.7,38},{-30404,62.9,-12925,38},{-30419.2,62.9,-12902.8,38.3},
{-30432.9,62.9,-12880.6,38},{-30445.9,62.9,-12857.2,38.1},{-30457.9,62.9,-12832.8,38.1},{-30468.2,62.9,-12809.7,38.2},{-30477.4,62.9,-12786.3,38.1},{-30485.8,62.9,-12762.4,38.1},{-30493.4,62.9,-12737.9,37.3},{-30499.6,62.9,-12713,37.4},{-30505.7,62.9,-12688.3,37.3},{-30511.7,62.9,-12663.8,37.5},
{-30517.7,62.9,-12639.3,37.8},{-30524,62.9,-12615,37.4},{-30530.2,62.9,-12590.3,37.2},{-30536.2,62.9,-12565.5,37.7},{-30541.7,62.9,-12541.1,38.2},{-30546.4,62.9,-12516.9,38.3},{-30550.8,62.9,-12492.8,38.3},{-30554.4,62.9,-12468.8,37.9},{-30557.9,62.9,-12443.4,36.9},{-30560.1,62.9,-12416.6,37},
{-30561.8,62.9,-12390.2,35.3},{-30560.4,62.9,-12361.8,37.1},{-30558.5,62.9,-12335.7,37.7},{-30555.8,62.9,-12309.8,38.2},{-30552.2,62.9,-12284.2,38.2},{-30546.4,62.9,-12252.8,37.6},{-30541.6,62.9,-12227.4,37.1},{-30536.3,62.9,-12201.3,37.6},{-30530.9,62.9,-12174.7,38.3},{-30526.8,62.9,-12155,38.9},
{-30521.8,62.9,-12129.3,38.9},{-30516.8,62.9,-12103.4,38.7},{-30512.1,62.9,-12079.3,38.7},{-30507.2,62.9,-12054.2,38.9},{-30501.9,62.9,-12027.3,38.6},{-30497.1,62.9,-12002.4,38.7},{-30492.1,62.9,-11976.7,38.6},{-30487,62.9,-11950.2,38.4},{-30481.8,62.9,-11923.3,38.5},{-30476.4,62.9,-11895.5,38.4},
{-30471.2,62.9,-11868.6,38.4},{-30466,62.9,-11841.7,38.7},{-30462.2,62.9,-11821.7,38.5},{-30456.7,62.9,-11794,38.2},{-30451.3,62.9,-11766.4,38.6},{-30446,62.9,-11739.6,38.8},{-30441.9,62.9,-11718.8,39.1},{-30436.7,62.9,-11691.7,38.9},{-30431.3,62.9,-11664,38.8},{-30425.9,62.9,-11636.4,38.7},
{-30419.5,62.9,-11603.2,38.9},{-30414.2,62.9,-11576.1,38.6},{-30408.9,62.9,-11548.7,38.6},{-30402.3,62.9,-11515,39},{-30397.2,62.9,-11488.5,38.8},{-30391.8,62.9,-11460.8,38.8},{-30386.3,62.9,-11432.3,38.5},{-30381.2,62.9,-11406.4,38.7},{-30375.5,62.9,-11376.6,38.8},{-30371.6,62.9,-11356.7,39},
{-30365.9,62.9,-11327.5,38.8},{-30360.4,62.9,-11298.8,38.7},{-30355,62.9,-11271,38.5},{-30349.9,62.9,-11244.7,38.3},{-30345.1,62.9,-11219.3,38.2},{-30339.5,62.9,-11190.4,38.3},{-30335.6,62.9,-11169.8,38.2},{-30329.2,62.9,-11136.8,37.7},{-30323.9,62.9,-11108.8,37.8},{-30318.5,62.9,-11080.6,37.4},
{-30312.8,63,-11053.5,37.2},{-30305.5,63,-11027.4,37.4},{-30297.2,62.9,-11000,38.3},{-30291.3,62.9,-10979.5,38.6},{-30283.3,63,-10952.5,38.2},{-30273.7,62.9,-10927.1,38.2},{-30264.4,62.9,-10902.9,38.3},{-30254.6,62.9,-10877.3,38.6},{-30244.8,63,-10852.4,38.7},{-30230.6,62.9,-10822.4,38.3},
{-30218.9,62.9,-10798.6,38.3},{-30207.3,62.9,-10774.8,38.3},{-30195.1,63.1,-10750.7,38.3},{-30182,62.9,-10728.5,38.3},{-30165.4,62.9,-10700.7,38},{-30151.4,62.9,-10677.5,37.9},{-30137.5,62.9,-10655.6,38},{-30122.8,62.9,-10635.2,38},{-30107.7,62.9,-10614.4,37.9},{-30092.7,62.9,-10593.8,37.9},
{-30077.9,63,-10573.8,37.9},{-30060.3,62.9,-10553,38.1},{-30047.1,62.9,-10537.9,38.8},{-30029.6,62.9,-10517.7,38.4},{-30013.4,62.9,-10499,38.4},{-29994.1,62.9,-10478.8,38.3},{-29975.1,62.9,-10460.4,38.3},{-29955.6,62.9,-10441.6,38.4},{-29941,62.9,-10427.5,38.8},{-29917,62.9,-10405.4,38.5},
{-29896.7,62.9,-10389,38.6},{-29870.9,62.9,-10368,38.1},{-29851.3,62.9,-10352.1,38.2},{-29830.3,62.9,-10336.5,37.8},{-29807.8,62.9,-10321.4,37.8},{-29786.8,62.9,-10307.2,37.8},{-29764.6,62.9,-10292.2,37.8},{-29742.6,62.9,-10278.4,37.4},{-29718.6,62.9,-10265.2,37.8},{-29700.6,62.9,-10255.1,38.1},
{-29675.8,62.9,-10241.4,37.5},{-29647.8,63,-10226.9,37.4},{-29624.3,62.9,-10216.5,37.4},{-29605.8,62.9,-10208.3,37.6},{-29581.6,62.9,-10197.4,37.5},{-29558,63,-10187.2,37.3},{-29533.7,62.9,-10178.6,37.6},{-29513.8,62.9,-10171.8,37.6},{-29482.7,62.9,-10161.2,37.2},{-29457.5,62.9,-10152.5,37.3},
{-29430.9,62.9,-10145.5,37.3},{-29404.4,62.9,-10138.9,37.3},{-29378.4,62.9,-10132.5,37.2},{-29351.4,62.9,-10125.8,37.4},{-29325.5,62.9,-10121.4,37.7},{-29299.2,62.9,-10117.2,37.7},{-29271.4,62.9,-10112.8,38.5},{-29251,63,-10109.7,38.1},{-29224.1,62.9,-10106.8,38.6},{-29198,62.9,-10105,38.7},
{-29170.4,62.9,-10103.1,38.7},{-29142.5,62.9,-10101.1,38.7},{-29115.6,62.9,-10101,38.1},{-29087.4,62.9,-10101.5,38.6},{-29052.6,62.9,-10102.1,38.6},{-29024.6,62.9,-10102.6,38.3},{-28996.4,62.9,-10103.1,38.7},{-28967.4,62.9,-10103.6,39.2},{-28934.6,62.9,-10104.2,38.9},{-28914.1,62.9,-10104.5,38.7},
{-28893.3,62.9,-10104.9,38.7},{-28866.3,62.9,-10105.4,38.5},{-28839.9,62.9,-10105.9,38.5},{-28813.3,62.9,-10106.3,38.6},{-28785.3,62.9,-10106.8,38.8},{-28764.8,62.9,-10107.2,38.8},{-28732.8,62.9,-10107.7,38.6},{-28704,62.9,-10108.3,38.5},{-28677.5,62.9,-10108.7,38.5},{-28649.8,62.9,-10109.2,38.4},
{-28623.4,62.9,-10109.6,38.3},{-28596.2,62.9,-10110.1,38.4},{-28568.6,62.9,-10110.6,38.4},{-28542.9,62.9,-10111,38.4},{-28515,62.9,-10111.5,38.3},{-28488.3,62.9,-10112,38.3},{-28460.7,62.9,-10112.5,38.4},{-28435.1,62.9,-10112.9,38.4},{-28409.6,63,-10114.8,37.5},{-28384.2,62.9,-10117.7,38.1},
{-28356.2,62.9,-10120.7,38.5},{-28335.7,62.9,-10122.8,38.9},{-28307.5,62.9,-10125.8,38.4},{-28279.8,62.9,-10130.2,38.4},{-28260,62.9,-10134.1,38.6},{-28239.2,62.9,-10138.2,38.6},{-28207.1,62.9,-10144.4,38.8},{-28185.4,62.9,-10148.7,38.5},{-28154.6,63,-10156.1,37.9},{-28130,62.9,-10163.2,38.3},
{-28105.1,62.9,-10170.4,38.6},{-28078.6,62.9,-10177.9,38.5},{-28050.7,62.9,-10186,38.4},{-28025,63,-10195,37.7},{-28005.6,62.9,-10202.6,38.1},{-27980.5,62.9,-10212.3,38.1},{-27953.7,62.9,-10222.6,38},{-27928.3,62.9,-10232.3,37.9},{-27901.2,62.9,-10241.7,36.9},{-27874.3,62.9,-10250.3,35},
{-27846.7,62.9,-10259.2,33.3},{-27820.4,62.9,-10267.2,32.8},{-27788.1,62.9,-10275.9,32.4},{-27761.1,62.9,-10281.2,32.1},{-27733.2,62.9,-10285.5,34.5},{-27699.6,63,-10290.3,38.6},{-27679.7,62.9,-10293.8,39},{-27652.5,62.9,-10298.6,38.3},{-27631.8,62.9,-10301.3,37.4},{-27597,62.9,-10304.7,37.5},
{-27569.5,62.9,-10307.5,37.8},{-27542.3,62.9,-10310.4,37.7},{-27516.5,62.9,-10313.1,37.8},{-27487.1,62.9,-10314.7,37.3},{-27457.7,62.9,-10314.8,38.4},{-27435.8,62.9,-10315.2,38.4},{-27406.7,62.9,-10315.7,38.3},{-27378.2,62.9,-10316.2,38.2},{-27350,62.9,-10315.1,37.5},{-27317.7,62.9,-10312.6,38.1},
{-27291.3,62.9,-10310.8,37.9},{-27265.3,62.9,-10308.9,37.9},{-27238,62.9,-10306.8,37.9},{-27208.8,62.9,-10303.1,37.3},{-27188.5,62.9,-10299.7,37.3},{-27162,62.9,-10295.4,37.6},{-27136.5,62.9,-10291.4,37.5},{-27110,62.9,-10287.2,37.4},{-27082.4,62.9,-10282,36.4},{-27055,62.9,-10275.3,36.3},
{-27029,62.9,-10268.7,36.7},{-27003.8,62.9,-10262.4,36.7},{-26977.8,62.9,-10255.8,36.8},{-26950.9,62.9,-10248.7,36.3},{-26930.6,62.9,-10242.2,35.8},{-26904.5,62.9,-10232.9,36.1},{-26880.5,62.9,-10224.6,36.2},{-26855,62.9,-10215.8,36.1},{-26829.5,62.9,-10207.1,36},{-26803.2,62.9,-10196.3,35.6},
{-26778.6,62.9,-10185.2,36.4},{-26750,62.9,-10172.4,36.5},{-26725.6,62.9,-10161.6,36.4},{-26698.8,62.9,-10149.6,36.2},{-26674.3,62.9,-10137.2,36.8},{-26650.8,62.9,-10124.1,36.9},{-26625.8,62.9,-10110.2,37},{-26601.7,62.9,-10096.9,36.9},{-26578.3,62.9,-10083.9,36.9},{-26555.2,62.9,-10071.1,36.9},
{-26532.6,62.9,-10058.6,36.9},{-26509.5,62.9,-10045.7,36.9},{-26486,62.9,-10032.7,36.9},{-26462.2,62.9,-10019.5,36.8},{-26437.9,62.9,-10006.1,37},{-26413.1,62.9,-9992.3,37},{-26390.2,62.9,-9979.7,37.2},{-26367.7,62.9,-9967.1,37.3},{-26344.6,62.9,-9954.4,37.2},{-26321.7,62.9,-9941.7,37.2},
{-26299,62.9,-9929.1,37},{-26275.8,62.9,-9916.2,36.9},{-26251.8,62.9,-9902.9,37.1},{-26227.3,62.9,-9889.4,37.3},{-26202.6,62.9,-9877.6,37.7},{-26177.5,62.9,-9866.6,37.5},{-26152.5,62.9,-9855.4,37.5},{-26126.4,62.9,-9843.8,37.6},{-26100.2,62.9,-9832.2,38.1},{-26081.1,62.9,-9823.6,37.6},
{-26055.3,63,-9813.1,37.8},{-26028.3,62.9,-9803.9,37.6},{-26002.2,62.9,-9794.9,37.4},{-25976.9,62.9,-9786.2,37.6},{-25953.4,62.9,-9778.2,37.5},{-25929.9,62.9,-9770.1,37.6},{-25904.2,62.9,-9763,38.2},{-25878,62.9,-9756.4,38.3},{-25852.4,62.9,-9750,38.3},{-25826.9,62.9,-9743.7,38.2},
{-25800.3,62.9,-9737,38.5},{-25774.7,62.9,-9730.7,38.4},{-25749.6,62.9,-9725.6,37.8},{-25724.6,62.9,-9721.7,38.2},{-25698.6,62.9,-9717.5,38.1},{-25673.4,62.9,-9713.6,38.2},{-25647.6,62.9,-9709.5,38.2},{-25621.7,62.9,-9705.3,38.2},{-25596,63,-9701.8,37.5},{-25570.1,62.9,-9699.8,37.2},
{-25544.1,62.9,-9698,37.3},{-25518.4,62.9,-9696.2,37.3},{-25493.1,62.9,-9694.4,37.4},{-25467.2,62.9,-9692.6,37.4},{-25434.4,62.9,-9690.9,37.2},{-25408.9,62.9,-9691.2,37.1},{-25383.1,62.9,-9691.7,37.1},{-25357.6,62.9,-9692.2,36.9},{-25332.5,62.9,-9692.6,37},{-25304.6,62.9,-9693.1,37},
{-25278.5,63,-9693.7,37},{-25250.3,62.9,-9696.5,36.9},{-25220.6,62.9,-9699.7,37.3},{-25190.7,62.9,-9702.8,37.9},{-25169.1,62.9,-9705.1,38},{-25140.3,62.9,-9708.1,37.3},{-25112.4,63,-9711.5,37},{-25085.1,62.9,-9716.8,37.7},{-25052.4,62.9,-9723.3,38.1},{-25024.6,62.9,-9728.7,38},
{-24998.6,62.9,-9733.8,37.9},{-24972.3,62.9,-9738.9,38.2},{-24946,63,-9745.7,38.3},{-24926.6,62.9,-9751.4,39.1},{-24899.6,62.9,-9759.3,38.9},{-24874.1,62.9,-9766.6,38.6},{-24848.5,62.9,-9773.9,38.5},{-24822.9,62.9,-9781.2,38.7},{-24797.1,62.9,-9788.4,38.4},{-24777.4,62.9,-9792.7,37.1},
{-24750.2,62.9,-9797.8,37.4},{-24717.2,62.9,-9804,38.1},{-24690,62.9,-9809.3,37.7},{-24663.9,62.9,-9814.3,37.7},{-24639.1,62.9,-9819.2,37.7},{-24614,62.9,-9823.5,37},{-24588.6,62.9,-9826.3,36.8},{-24562.1,62.9,-9828.9,37.3},{-24534.4,62.9,-9831.8,37.3},{-24506.7,62.9,-9834.7,37.6},
{-24479.9,62.9,-9837.5,37.3},{-24452.2,62.9,-9840.4,37.5},{-24424.7,62.9,-9841.9,37.6},{-24396.3,62.9,-9842.2,38},{-24367.3,62.9,-9842.7,38.1},{-24338.3,62.9,-9843.2,38},{-24309.4,62.9,-9843.7,38.1},{-24273.8,62.9,-9844.2,38.3},{-24252.9,62.9,-9843.2,37.7},{-24231.9,62.9,-9841.6,37.9},
{-24200.1,62.9,-9839.2,38},{-24173.9,62.9,-9837.4,37.8},{-24147.7,62.9,-9835.6,38},{-24120.4,62.9,-9833.7,38.3},{-24093.3,62.9,-9831.4,37.7},{-24060.2,62.9,-9826.2,37.8},{-24032.8,62.9,-9821.7,38.1},{-24006.8,62.9,-9817.6,38.2},{-23979.6,62.9,-9813.3,38.3},{-23953.4,62.9,-9809.1,38.5},
{-23928.3,62.9,-9805.1,38.4},{-23902.9,62.9,-9799.7,38},{-23870.9,62.9,-9791.4,38.2},{-23845.7,62.9,-9785,38.7},{-23820,62.9,-9778.6,38.7},{-23794.1,62.9,-9772.1,38.8},{-23768.1,62.9,-9765.6,38.8},{-23741.8,62.9,-9758.5,37.8},{-23715.6,62.9,-9750,37},{-23689.5,62.9,-9740.5,38},
{-23663.1,62.9,-9731.2,38.4},{-23636.2,62.9,-9721.9,38.4},{-23610.2,62.9,-9713,38.5},{-23582.8,62.9,-9703.3,38.3},{-23555.5,62.9,-9691.9,37.8},{-23535.9,62.9,-9683.2,37.7},{-23508.8,62.9,-9670.3,38.8},{-23481.5,62.9,-9658,39.1},{-23454.1,62.9,-9645.8,39},{-23428.4,62.9,-9634.2,38.8},
{-23401.7,62.9,-9620.4,37.5},{-23377.1,62.9,-9606.7,37.8},{-23351.1,62.9,-9591.8,38.8},{-23324.7,62.9,-9577.2,39},{-23298,62.9,-9562.4,39.3},{-23272.3,62.9,-9547.9,38.8},{-23253.6,63,-9535.9,36.9},{-23229,62.9,-9519.5,36.6},{-23204,62.9,-9502.2,38},{-23179.3,62.9,-9485.3,38.2},
{-23155.7,62.9,-9469.5,38.1},{-23132.4,62.9,-9453.8,38.1},{-23109.8,62.9,-9436.7,37.3},{-23083.7,62.9,-9415.2,37.6},{-23062.6,62.9,-9397.9,37.8},{-23041,62.9,-9380.4,37.8},{-23018.5,62.9,-9362.1,37.7},{-22998,62.9,-9345.6,37.7},{-22978,62.9,-9327.9,37.5},{-22955.1,62.9,-9305.5,37.4},
{-22933.6,62.9,-9284.6,38},{-22908.2,62.9,-9260,38.2},{-22887.8,62.9,-9240.4,37.8},{-22867.8,62.9,-9221,37.8},{-22849.1,62.9,-9200.9,37},{-22831.7,62.9,-9180.4,37.7},{-22814.3,62.9,-9160.2,38.1},{-22797.4,62.9,-9140.7,38.1},{-22780.8,62.9,-9121.7,38.1},{-22762.9,62.9,-9101,38.1},
{-22745.4,62.9,-9080.3,38},{-22729.9,62.9,-9059.1,37.7},{-22714.1,62.9,-9036.7,38.1},{-22698.8,62.9,-9015.7,38.1},{-22682.5,62.9,-8993.1,38},{-22668.3,62.9,-8972,36},{-22654.7,62.9,-8951.2,33.7},{-22640.6,62.9,-8929.3,31.6},{-22623.6,63,-8901,30.7},{-22608.9,63,-8878.2,32.4},
{-22594.9,62.9,-8855.8,34.8},{-22580.8,62.9,-8832.5,35.3},{-22566.9,62.9,-8809.4,35.1},{-22552.4,62.9,-8785.1,35.5},{-22538.2,62.9,-8761.7,35.4},{-22525.6,62.9,-8740.6,35.4},{-22512.3,62.9,-8718.5,35.4},{-22501.8,62.9,-8701,35.4},{-22488.4,62.9,-8678.7,35.5},{-22471.1,62.9,-8649.9,35.4},
{-22456.9,62.9,-8626.2,35.1},{-22442.7,62.9,-8602.6,35},{-22428.8,62.9,-8579.5,35},{-22415.1,62.9,-8556.7,34.9},{-22402.1,62.9,-8535.2,35},{-22388.6,62.9,-8512.7,35},{-22375,62.9,-8490,34.9},{-22361.9,62.9,-8468.2,34.9},{-22348.6,62.9,-8446.1,35},{-22334.1,62.9,-8424.9,35.4},
{-22315.4,62.9,-8399.2,35.6},{-22300.1,62.9,-8378.2,35.2},{-22285.6,62.9,-8358.2,35.2},{-22270.4,63,-8337.8,34.7},{-22253.4,62.9,-8317.8,34.9},{-22237.1,62.9,-8299.4,35.3},{-22220.5,62.9,-8280.3,35.3},{-22203.9,62.9,-8261.1,35.3},{-22182.3,62.9,-8237.8,34.2},{-22163.8,62.9,-8219.8,34.4},
{-22144.6,62.9,-8201.5,34.7},{-22125,62.9,-8182.6,34.8},{-22105.2,63,-8163.9,34.3},{-22084.5,63,-8146.5,34.2},{-22068.8,62.9,-8134.1,34.9},{-22047.9,62.9,-8117.2,34.4},{-22027.1,62.9,-8100.3,34.3},{-22004.4,63,-8082.6,33.6},{-21980.8,62.9,-8066.8,33.8},{-21957.4,62.9,-8051,34.4},
{-21940.6,62.9,-8039.7,34.1},{-21917.1,62.9,-8023.9,33.8},{-21894.1,62.9,-8010.2,33.1},{-21870.5,62.9,-7997.2,33.4},{-21845.9,62.9,-7983.6,33.9},{-21827.9,62.9,-7973.6,33.8},{-21804.3,63,-7960.9,32.7},{-21779.6,62.9,-7949.5,32},{-21754.7,62.9,-7938.5,32.7},{-21729.8,62.9,-7927.5,33},
{-21711.3,62.9,-7919.3,33},{-21686.8,62.9,-7907.8,32.5},{-21663.8,62.9,-7895,32.5},{-21640.7,62.9,-7881.8,33.2},{-21617.6,62.9,-7869,33.3},{-21594.9,62.9,-7856.4,33.2},{-21573.1,62.9,-7843.2,34},{-21541.7,62.9,-7821.6,34.8},{-21520.1,62.9,-7807,34.5},{-21498.8,62.9,-7792.6,34.4},
{-21477.8,62.9,-7778.3,34.2},{-21456.8,62.9,-7763.8,33.9},{-21435.6,63,-7749.7,34.5},{-21408.9,62.9,-7732.1,35.2},{-21387.1,62.9,-7717.5,35},{-21364.8,62.9,-7702.4,34.8},{-21342.7,62.9,-7687.5,34.9},{-21321,62.9,-7672.8,35.2},{-21304.3,62.9,-7661.6,35.1},{-21281.5,62.9,-7646.2,35.1},
{-21258.1,62.9,-7630.4,35.2},{-21240.7,62.9,-7618.7,35.2},{-21214.6,62.9,-7601,34.9},{-21193.3,62.9,-7586.7,34.8},{-21172.1,62.9,-7572.4,35},{-21149.8,62.9,-7557.3,34.9},{-21126.8,62.9,-7541.8,34.7},{-21104.1,62.9,-7526.5,34.6},{-21081.5,62.9,-7510.6,33.8},{-21060,62.9,-7493.3,33.6},
{-21037.7,62.9,-7475.1,34.2},{-21016,62.9,-7457.5,34.1},{-20994.7,62.9,-7440.2,33.8},{-20972.8,62.9,-7422.1,33.5},{-20951.6,62.9,-7402.3,33.1},{-20931.1,62.9,-7382,34.2},{-20905.2,62.9,-7357,34.5},{-20883.9,62.9,-7336.5,34.2},{-20864.3,62.9,-7316.1,34.2},{-20850.4,62.9,-7300,34.7},
{-20833.3,62.9,-7280,34.5},{-20815.9,62.9,-7260,34.4},{-20798.2,62.9,-7239.6,34.5},{-20776.4,62.9,-7213.7,33.8},{-20761.4,62.9,-7193.2,33.6},{-20745.2,62.9,-7170.3,34.7},{-20728.8,62.9,-7147.8,34.2},{-20713.2,62.9,-7126.3,34.3},{-20698.6,62.9,-7105.7,33.9},{-20685.1,62.9,-7084.1,33.3},
{-20672.3,62.9,-7062.3,34.1},{-20659.4,62.9,-7040.6,34.2},{-20646.3,62.9,-7018.9,34.3},{-20633.2,62.9,-6997.1,34.5},{-20620.2,62.9,-6974.8,34.2},{-20608.2,62.9,-6951.6,33.3},{-20596.9,62.9,-6927.9,33.9},{-20585.6,62.9,-6904.6,34.4},{-20571.6,62.9,-6875.7,34.3},{-20560.3,62.9,-6852.6,34.1},
{-20549.5,62.9,-6828.9,33.9},{-20537.9,62.9,-6798.4,33.9},{-20528.8,62.9,-6774.1,34.4},{-20519.6,62.9,-6750.1,34.4},{-20510.5,62.9,-6726.3,34.2},{-20501.4,62.9,-6702.6,34.2},{-20493.4,62.9,-6678.4,33.8},{-20486.6,62.9,-6653.9,34.6},{-20479.8,62.9,-6629.7,35},{-20472.9,62.9,-6605.7,35.2},
{-20462.1,62.9,-6568.1,35},{-20454.8,62.9,-6540.5,34.5},{-20449.4,62.9,-6512.4,34.9},{-20445.6,62.9,-6492.1,35.5},{-20440.3,62.9,-6464.4,35},{-20434.9,62.9,-6437,35.4},{-20431.1,62.9,-6417.1,35.5},{-20426.4,62.9,-6389.7,34.7},{-20423.6,62.9,-6362.1,34.6},{-20421,62.9,-6334.7,35.4},
{-20417.4,62.9,-6300.8,35.7},{-20414.6,62.9,-6273.7,35.3},{-20412,62.9,-6246.6,34.6},{-20410.9,62.9,-6219.5,33.7},{-20410.8,62.9,-6192.5,34.5},{-20410.4,62.9,-6165.5,35},{-20409.9,62.9,-6131.7,35.3},{-20409.4,62.9,-6104.2,35.2},{-20408.9,62.9,-6076.9,35.1},{-20408.4,62.9,-6048.3,35},
{-20407.9,62.9,-6019.6,35},{-20407.4,62.9,-5990.4,35},{-20406.9,62.9,-5960.7,35},{-20406.4,62.9,-5930.6,35.1},{-20405.8,62.9,-5900.3,35.1},{-20405.4,62.9,-5877.7,35.6},{-20404.9,62.9,-5847.3,35.1},{-20404.3,62.9,-5814.4,34.8},{-20403.8,62.9,-5787.5,34.8},{-20403.4,62.9,-5761.9,34.9},
{-20402.9,62.9,-5732,35},{-20402.5,62.9,-5711.6,35.1},{-20402.1,62.9,-5683.1,34.7},{-20401.6,62.9,-5654.4,35},{-20401.2,62.9,-5633.5,35},{-20400.7,62.9,-5608.5,35.2},{-20400.2,62.9,-5577.1,35},{-20399.7,62.9,-5551.5,34.8},{-20399.3,62.9,-5525.7,34.9},{-20398.8,62.9,-5499.6,34.7},
{-20398.3,62.9,-5473.2,34.7},{-20397.9,62.9,-5446.6,34.7},{-20397.4,62.9,-5420,34.8},{-20397,62.9,-5393.3,34.8},{-20396.5,62.9,-5366.5,35},{-20396,62.9,-5339.4,35.1},{-20395.7,62.9,-5319.1,35.3},{-20395.2,62.9,-5291.7,35.1},{-20394.7,62.9,-5264,34.8},{-20394.2,62.9,-5236.1,34.7},
{-20393.7,62.9,-5208,34.7},{-20393.2,62.9,-5179.6,34.7},{-20392.7,62.9,-5151.1,34.8},{-20392.2,62.9,-5122.3,35},{-20391.7,62.9,-5093.4,35.2},{-20391.2,62.9,-5064.2,35.5},{-20390.8,62.9,-5042.3,35.4},{-20390.3,62.9,-5012.7,35.1},{-20389.8,62.9,-4982.9,34.9},{-20389.3,62.9,-4952.9,34.8},
{-20388.7,62.9,-4922.7,34.7},{-20388.2,62.9,-4892.2,34.7},{-20387.7,62.9,-4861.6,34.7},{-20387.1,62.9,-4830.7,34.9},{-20386.6,62.9,-4799.6,34.9},{-20386.1,62.9,-4768.3,35.1},{-20385.5,62.9,-4736.9,35.4},{-20385.1,62.9,-4713.2,35.6},{-20384.5,62.9,-4681.4,35.5},{-20384,62.9,-4649.3,35.2},
{-20383.4,62.9,-4617.1,35.1},{-20382.9,62.9,-4584.8,35},{-20382.3,62.9,-4552.6,34.9},{-20381.7,62.9,-4520.2,34.9},{-20381.2,62.9,-4487.7,34.9},{-20380.6,62.9,-4455,34.9},{-20380,62.9,-4422.1,34.9},{-20379.4,62.9,-4389.3,35},{-20378.9,62.9,-4356.5,34.8},{-20378.3,62.9,-4323.6,34.8},
{-20377.7,62.9,-4290.5,34.8},{-20377.1,62.9,-4257.3,34.7},{-20376.6,62.9,-4224.1,34.7},{-20376,62.9,-4190.7,34.7},{-20375.4,62.9,-4159.8,35.5},{-20374.8,62.9,-4126.1,35.7},{-20374.4,62.9,-4101,35.5},{-20373.8,62.9,-4067,35.3},{-20373.2,62.9,-4033,35.2},{-20372.6,62.9,-3998.9,35.1},
{-20372.1,62.9,-3964.6,35},{-20371.4,62.9,-3930.2,34.9},{-20370.8,62.9,-3895.7,34.8},{-20370.2,62.9,-3861,34.8},{-20369.6,62.9,-3826.2,34.7},{-20369.1,62.9,-3791.3,34.7},{-20368.4,62.9,-3756.3,34.7},{-20367.8,62.9,-3721.1,34.7},{-20367.2,62.9,-3685.9,34.6},{-20366.6,62.9,-3650.5,34.7},
{-20365.9,62.9,-3615,34.9},{-20365.4,62.9,-3582.4,34.8},{-20365,62.9,-3561.5,34.9},{-20364.4,62.9,-3525.7,35},{-20363.8,62.9,-3489.7,35.1},{-20363.2,62.9,-3459.7,35.1},{-20362.8,62.9,-3438.6,34.7},{-20362.2,62.9,-3402.4,34.7},{-20361.8,62.9,-3375.1,35},{-20361.3,62.9,-3350.9,34.8},
{-20360.9,62.9,-3326.5,34.9},{-20360.5,62.9,-3302.1,34.9},{-20360.1,62.9,-3277.7,34.8},{-20359.7,62.9,-3257.1,35.2},{-20359.3,62.9,-3231.7,35},{-20358.8,62.9,-3207.2,35.1},{-20358.4,62.9,-3182.5,35.1},{-20358,62.9,-3157.9,35.2},{-20357.4,62.9,-3127,35.2},{-20357,62.9,-3102.2,35.1},
{-20356.6,62.9,-3081.3,34.9},{-20356.1,62.9,-3055.6,34.8},{-20355.7,62.9,-3030.8,34.8},{-20355.2,62.9,-3003.6,34.7},{-20354.8,62.9,-2977.9,34.7},{-20354.4,62.9,-2953.1,34.8},{-20353.9,62.9,-2928.4,34.7},{-20353.6,62.9,-2903.5,34.8},{-20353.1,62.9,-2878.7,34.8},{-20352.6,62.9,-2853.8,35},
{-20352.2,62.9,-2828.9,35.1},{-20351.7,62.9,-2798,35.1},{-20351.3,62.9,-2773,34.9},{-20350.8,62.9,-2748,34.8},{-20350.4,62.9,-2723,34.8},{-20350,62.9,-2701.1,35.2},{-20349.5,62.9,-2675.9,35.1},{-20349.1,62.9,-2650.8,34.9},{-20348.7,62.9,-2625.5,34.8},{-20348.2,62.9,-2600.2,34.7},
{-20347.8,62.9,-2574.9,34.8},{-20347.3,62.9,-2549.5,34.8},{-20346.9,62.9,-2524.1,34.8},{-20346.4,62.9,-2498.6,35.1},{-20346,62.9,-2473.1,35.2},{-20345.4,62.9,-2441.3,35.2},{-20344.8,62.9,-2406,34.9},{-20344.3,62.9,-2380.3,35},{-20343.9,62.9,-2354.6,35.2},{-20343.5,62.9,-2328.8,35.3},
{-20342.9,62.9,-2296.6,35.2},{-20342.5,62.9,-2270.7,35},{-20342,62.9,-2244.9,34.9},{-20341.6,62.9,-2218.9,34.8},{-20341.1,62.9,-2192.8,34.8},{-20340.6,62.9,-2166.7,34.7},{-20340.2,62.9,-2140.6,34.6},{-20339.8,62.9,-2114.5,34.7},{-20339.3,62.9,-2088.3,34.9},{-20338.9,62.9,-2062.1,35.1},
{-20338.4,62.9,-2035.8,35.3},{-20337.9,62.9,-2006.3,34.6},{-20337.4,62.9,-1980,34.7},{-20337,62.9,-1953.6,34.8},{-20336.5,62.9,-1927.2,34.9},{-20336,62.9,-1900.7,35},{-20335.6,62.9,-1877.6,34.7},{-20335.2,62.9,-1851.1,34.6},{-20334.7,62.9,-1824.6,34.7},{-20334.2,62.9,-1798,34.9},
{-20333.8,62.9,-1771.4,34.9},{-20333.3,62.9,-1743.1,35.7},{-20332.9,62.9,-1721.6,34.7},{-20332.4,62.9,-1692.5,35},{-20331.9,62.9,-1665,35.1},{-20331.4,62.9,-1638.2,34.9},{-20331,62.9,-1611.5,34.9},{-20330.6,62.9,-1584.7,34.7},{-20330.1,62.9,-1557.8,34.7},{-20329.6,62.9,-1534.4,35.2},
{-20329.2,62.9,-1507.6,35.1},{-20328.8,62.9,-1484.7,34.9},{-20328.3,62.9,-1456.9,34.8},{-20327.8,62.9,-1430,35},{-20327.4,62.9,-1402.9,35.1},{-20326.9,62.9,-1375.9,35.3},{-20326.3,62.9,-1345.5,34.7},{-20325.8,62.9,-1318.3,34.8},{-20325.4,62.9,-1291.2,34.8},{-20324.9,62.9,-1264,35},
{-20324.4,62.9,-1236.7,35.1},{-20324,62.9,-1209.6,35.2},{-20323.5,62.9,-1182.2,35.3},{-20323.1,62.9,-1161.8,35.4},{-20322.7,62.9,-1134.5,35.1},{-20322.2,62.9,-1107.1,35},{-20321.7,62.9,-1079.7,34.9},{-20321.2,62.9,-1052.2,34.9},{-20320.7,62.9,-1024.8,34.7},{-20320.2,62.9,-997.3,34.7},
{-20319.7,62.9,-969.7,34.7},{-20319.3,62.9,-942.2,34.8},{-20318.8,62.9,-914.6,34.7},{-20318.3,62.9,-887,34.8},{-20317.8,62.9,-859.5,34.9},{-20317.3,62.9,-832,35},{-20316.9,62.9,-804.5,35.1},{-20316.4,62.9,-777.1,35.4},{-20316,62.9,-756.7,35.3},{-20315.6,62.9,-729.3,35},
{-20315.1,62.9,-702,34.9},{-20314.6,62.9,-674.7,34.7},{-20314.1,62.9,-645,35},{-20313.6,62.9,-616.9,34.9},{-20313.1,62.9,-589.7,34.7},{-20312.6,62.9,-562.6,34.7},{-20312.1,62.9,-535.4,34.9},{-20311.7,62.9,-508.3,35.2},{-20311.1,62.9,-474.9,35.2},{-20310.5,62.9,-437.6,35.1},
{-20309.9,62.9,-404.2,35},{-20309.4,62.9,-377.3,34.8},{-20308.9,62.9,-350.4,34.8},{-20308.5,62.9,-323.6,35},{-20307.9,62.9,-290.5,35.1},{-20307.5,62.9,-263.8,34.8},{-20307,62.9,-237,34.9},{-20306.6,62.9,-210.3,35.2},{-20305.9,62.9,-177.5,35},{-20305.5,62.9,-150.9,34.8},
{-20305.1,62.9,-124.3,35},{-20304.6,62.9,-94.7,34.8},{-20304.1,62.9,-68.2,35.2},{-20303.5,62.9,-35.6,34.8},{-20303.1,62.9,-9.2,34.8},{-20302.6,62.9,17.2,35.3},{-20302.1,62.9,46.5,35.1},{-20301.3,62.9,89,35.2},{-20300.7,62.9,121.2,34.7},{-20300.1,62.9,160.4,35.2},
{-20299.5,62.9,192.5,34.8},{-20298.8,62.9,231.6,35.4},{-20298.2,62.9,263.5,34.7},{-20297.7,62.9,295.2,35.2},{-20297.3,62.9,318.3,35.1},{-20296.7,62.9,350,34.7},{-20296.2,62.9,381.5,35.4},{-20295.8,62.9,404.4,35},{-20295.2,62.9,435.7,34.7},{-20294.7,62.9,466.7,35.3},
{-20294.3,62.9,489,35.1},{-20293.8,62.9,519.3,34.8},{-20293.3,62.9,549.2,35.1},{-20292.9,62.9,570.8,35.3},{-20292.4,62.9,596,35.4},{-20292.1,62.9,618.1,35.3},{-20291.6,62.9,646.9,34.8},{-20291.1,62.9,675.6,34.9},{-20290.4,62.9,710.6,35.3},{-20289.9,62.9,738.8,34.7},
{-20289.5,62.9,766.8,35},{-20289.1,62.9,787.1,35.2},{-20288.6,62.9,814.7,34.7},{-20288.1,62.9,845.2,34.8},{-20287.6,62.9,872.4,35.2},{-20287.1,62.9,902.4,35.1},{-20286.6,62.9,935.1,34.7},{-20285.9,62.9,967.4,35.2},{-20285.5,62.9,990.7,35.4},{-20285.2,62.8,1022.5,34.3},
{-20286.5,62.4,1054,32.4},{-20288,62.4,1076.8,31.7},{-20290.6,62.5,1107.6,30.9},{-20293.8,62.5,1138.1,32.4},{-20296.3,62.5,1160.2,33.9},{-20299.8,62.5,1189.9,35},{-20302.3,62.4,1219.7,34.9},{-20305,62.4,1249.2,35.6},{-20306.8,62.5,1270.6,35.3},{-20309.4,62.5,1299.7,34.9},
{-20311.9,62.4,1328.6,35.2},{-20314.4,62.4,1357.4,35.8},{-20316.3,62.5,1378.5,35.2},{-20318.7,62.4,1406.9,35},{-20321.3,62.4,1435.2,34.9},{-20325.1,62.4,1463.2,33.6},{-20329.6,62.5,1490.8,33.5},{-20333.4,62.5,1511.3,33.6},{-20338.9,62.5,1538.7,34.8},{-20343.8,62.4,1565.3,35.4},
{-20348.8,62.5,1593.1,35.3},{-20353.5,62.5,1620.2,35.2},{-20358.9,62.4,1647.2,35},{-20365.6,62.4,1673.7,34.4},{-20373.1,62.5,1700,35.2},{-20380.6,62.5,1726.1,36.5},{-20389.4,62.4,1758.7,36.7},{-20396.4,62.4,1784.9,36.5},{-20403.8,62.4,1811.2,35.6},{-20412.3,62.4,1836.9,34.1},
{-20421.5,62.5,1862.2,34},{-20431.3,62.5,1887.4,35},{-20440.4,62.5,1911.9,35.5},{-20449.7,62.5,1937.4,35.9},{-20461,62.5,1968.3,35.9},{-20470,62.4,1993,35.7},{-20480.3,62.4,2016.9,34.7},{-20494,62.5,2046,34.7},{-20505.1,62.5,2068.6,35.8},{-20515.8,62.5,2091.1,35.8},
{-20530.1,62.4,2120.7,35.4},{-20543.7,62.5,2145.2,33.7},{-20557.7,62.5,2169,34.3},{-20574.8,62.5,2197.7,35.6},{-20588.2,62.5,2220.8,35.3},{-20601.4,62.5,2243.7,35.3},{-20614.2,62.5,2265.9,35.3},{-20627.3,62.5,2288.5,35.4},{-20643.5,62.5,2317.4,35.3},{-20655.1,62.5,2341,34.2},
{-20666.4,62.4,2365.8,34.7},{-20677.3,62.5,2389.4,34.7},{-20688.4,62.5,2413,34.7},{-20699.9,62.5,2437.6,34.9},{-20711.1,62.5,2461.8,35},{-20722.7,62.5,2486.4,35.1},{-20737,62.5,2517.7,35.1},{-20747.1,62.5,2542.7,33.8},{-20756.1,62.5,2568,34.7},{-20765.1,62.5,2593.2,34.9},
{-20774.4,62.5,2618.6,35},{-20781.2,62.5,2637.5,35.2},{-20788.4,62.5,2657.3,35.2},{-20798.1,62.5,2683.6,35.2},{-20807.6,62.5,2710,35.1},{-20814.7,62.5,2729.4,35.1},{-20825,62.5,2762.4,35.2},{-20830.2,62.4,2782.2,35.5},{-20837.4,62.5,2809.2,35.5},{-20844.8,62.5,2836.6,35.4},
{-20852.2,62.5,2864.3,35.3},{-20859.7,62.5,2892.3,35.3},{-20866.7,62.5,2918.5,35.3},{-20874,62.5,2945.6,35.7},{-20881,62.5,2973.4,35.6},{-20886.1,62.5,3002.5,35.7},{-20891.1,62.4,3031.6,36.4},{-20896,62.5,3059.9,36.5},{-20899.6,62.5,3080.1,36},{-20904.4,62.5,3107.3,36.2},
{-20909.5,62.5,3136.2,36.5},{-20913,62.5,3156.1,36.1},{-20917.9,62.5,3184.2,36},{-20921.6,62.5,3212.5,35},{-20924,62.5,3241.4,36},{-20925.6,62.5,3261.6,36},{-20928,62.5,3290.2,36.1},{-20929.8,62.5,3310.6,36.6},{-20932.3,62.5,3338.8,35.9},{-20934.8,62.5,3367.3,36.5},
{-20936.6,62.5,3388.1,36.1},{-20938.9,62.5,3414.2,36.1},{-20940.3,62.5,3443.9,34.8},{-20940.1,62.5,3472.9,35.5},{-20940,62.4,3494.7,36.4},{-20940,62.5,3523.1,35.8},{-20940,62.5,3548.8,36},{-20940,62.5,3569.3,36.1},{-20940,62.5,3598,36},{-20940,62.5,3628.4,36.7},
{-20940,62.5,3649.7,36.1},{-20938.1,62.5,3681.7,35.2},{-20936.1,62.5,3702.9,35.7},{-20933.4,62.5,3732.7,35.9},{-20930.8,62.5,3761.6,36.4},{-20928.9,62.5,3783.6,36.3},{-20926.4,62.5,3812.3,36},{-20924.6,62.5,3833.1,36.6},{-20922.1,62.5,3862.1,35.9},{-20919.2,62.6,3890.8,36.3},
{-20915.8,62.7,3911.9,35.6},{-20910.3,62.5,3940.5,35.8},{-20906.9,62.5,3960.3,37.1},{-20901.9,62.5,3989.4,36.4},{-20896.7,62.5,4019.1,36.8},{-20892.9,62.5,4040.1,36.6},{-20887.6,62.4,4070.6,36.4},{-20882.5,62.5,4099.2,37.3},{-20878.3,62.5,4121.8,36.6},{-20871.1,62.5,4149.6,35.5},
{-20863.3,62.4,4177,37.3},{-20857.6,62.4,4197.8,37.4},{-20850.1,62.5,4225.6,37.1},{-20844.9,62.5,4245.2,37.7},{-20837.5,62.5,4272.7,37.2},{-20829.9,62.5,4301.1,37.1},{-20824.4,62.5,4321.4,37.6},{-20816.5,62.5,4349.2,36.9},{-20806.2,62.5,4377.7,37.2},{-20796,62.4,4404.9,37.2},
{-20786.5,62.5,4431,37.5},{-20779.4,62.5,4450.5,38},{-20769,62.4,4479.2,37.7},{-20759.4,62.5,4505.5,37.3},{-20749.8,62.5,4531.8,37.3},{-20740.2,62.5,4557.5,37},{-20729.5,62.5,4582.8,36.1},{-20720.4,62.5,4602,36.2},{-20708.7,62.4,4626.5,36.4},{-20696.3,62.5,4653,36.4},
{-20684.1,62.5,4679.3,36.4},{-20672.7,62.5,4703.7,36.5},{-20660.9,62.5,4728.9,36.8},{-20646.8,62.5,4759.3,36.7},{-20637.1,62.5,4778.6,36.2},{-20621.4,62.5,4806.9,35.2},{-20607.2,62.4,4831,35.5},{-20594.2,62.5,4853.6,35.4},{-20581.3,62.5,4876,35.4},{-20567.9,62.5,4899.2,35.8},
{-20554.3,62.5,4922.8,35.6},{-20540.8,62.5,4946,36},{-20526.7,62.6,4969.5,35.6},{-20511.9,62.5,4990.9,35.9},{-20497,62.4,5011.8,36.4},{-20481.2,62.5,5034.5,36.5},{-20465.9,62.5,5056.2,36.5},{-20451.1,62.5,5077.4,36.5},{-20435.9,62.5,5099.1,36.4},{-20421.1,62.5,5120.4,36.4},
{-20400.8,62.5,5149.3,36.7},{-20381.1,62.5,5174.7,36},{-20363.9,62.5,5194.7,36.6},{-20347.5,62.4,5214.1,36.8},{-20329.2,62.5,5235.9,36.9},{-20313.1,62.5,5255,36.9},{-20296.2,62.5,5275.3,36.8},{-20278.6,62.5,5296.2,37},{-20262.3,62.5,5315.5,37},{-20245.8,62.5,5335.2,37.1},
{-20228.2,62.5,5354.2,36.5},{-20208.9,62.4,5373.1,36.4},{-20190.8,62.4,5391,37},{-20176.5,62.5,5405.3,36.8},{-20156.7,62.5,5425.1,36.7},{-20137.5,62.5,5444.3,36.6},{-20120,62.5,5461.9,36.6},{-20100.2,62.5,5481.5,36.6},{-20080.6,62.5,5501,36.5},{-20061.3,62.5,5518,35.6},
{-20040.6,62.4,5535.1,36.4},{-20021.1,62.4,5551.3,36.6},{-20000.2,62.5,5568.8,37},{-19980.6,62.5,5585.2,36.8},{-19961.5,62.5,5601.2,36.7},{-19941.7,62.5,5617.8,36.7},{-19920.7,62.5,5635.4,36.8},{-19900.4,62.5,5652,36.3},{-19877.9,62.5,5668.1,36.1},{-19855.8,62.5,5683,37},
{-19833.1,62.4,5699,37.2},{-19811.7,62.5,5713.9,37.2},{-19789.9,62.5,5729.1,37.2},{-19768.7,62.5,5744,37.2},{-19746.6,62.4,5759.5,37.2},{-19725,62.5,5774.5,37.4},{-19702.4,62.5,5790.4,37.3},{-19680,62.5,5806.1,37.4},{-19657.7,62.5,5821.7,37.5},{-19634.8,62.5,5837.7,37.7},
{-19617.3,62.5,5850,37.7},{-19594.6,62.5,5865.9,37.3},{-19571.1,62.4,5882.4,37.4},{-19548.6,62.4,5898.2,37.6},{-19525.4,62.5,5914.4,37.3},{-19501.6,62.5,5929.7,35.6},{-19476.8,62.5,5944.1,35.6},{-19452.8,62.4,5957.5,36.4},{-19428.5,62.4,5971.5,36.7},{-19405.2,62.5,5985,36.6},
{-19381.7,62.5,5998.5,36.9},{-19358.1,62.5,6012.1,37.1},{-19334.4,62.4,6025.9,37.1},{-19316.4,62.5,6036.2,36.9},{-19292.7,62.4,6050,36.6},{-19269.6,62.4,6063.3,36.5},{-19244.6,62.5,6077.7,36.6},{-19220.7,62.5,6091.5,36.7},{-19197.5,62.4,6104.9,36.6},{-19173.2,62.5,6118.9,37.2},
{-19142.3,62.4,6136.8,37},{-19117.1,62.5,6151.3,36.6},{-19091.7,62.4,6166,36.5},{-19065.7,62.5,6181,36.7},{-19034.3,62.5,6199.1,36.9},{-19008,62.5,6214.3,36.6},{-18984.8,62.5,6227.7,36.6},{-18961.3,62.5,6241.2,37},{-18935.6,62.5,6256.1,36.4},{-18910.5,62.5,6270.6,36.8},
{-18879.7,62.5,6287.9,36.4},{-18853.3,62.5,6300.6,35.6},{-18827.3,62.4,6312.2,36.7},{-18803.4,62.4,6323.2,37.1},{-18777.7,62.5,6335.2,37.3},{-18758.4,62.5,6344.2,37.2},{-18733.1,62.4,6356.1,37},{-18707.1,62.4,6368.2,36.9},{-18682.1,62.4,6379.8,36.9},{-18656.1,62.5,6391.9,37.1},
{-18623.7,62.5,6407,37.2},{-18597.6,62.5,6419.2,37.3},{-18571.4,62.5,6431.4,36.9},{-18544.8,62.4,6443.8,36.9},{-18520.9,62.4,6454.9,37.4},{-18491.8,62.4,6468.5,37},{-18463.2,62.5,6481.8,37.2},{-18428.8,62.5,6497.9,37.5},{-18397.2,62.5,6512.6,37.3},{-18372.1,62.5,6524.3,36.7},
{-18347.2,62.5,6536,37.2},{-18319.5,62.5,6548.9,37.1},{-18291.2,62.5,6562.1,36.9},{-18263.5,62.5,6575,36.9},{-18236.5,62.5,6587.6,36.9},{-18209.9,62.5,6599.2,36.1},{-18181.6,62.5,6609.6,36},{-18153.9,62.4,6619.1,37},{-18126.9,62.4,6628.9,37.1},{-18099.8,62.5,6638.8,37.1},
{-18073,62.4,6648.6,37.2},{-18046,62.4,6658.4,37.2},{-18018.9,62.5,6668.2,37.3},{-17992.1,62.5,6678,37.3},{-17964.5,62.5,6688,37.3},{-17936.1,62.4,6698.4,37.5},{-17907.8,62.4,6708.7,37.5},{-17879.8,62.4,6718.9,37.3},{-17850.2,62.4,6729.6,37.3},{-17821.5,62.4,6740.1,37.2},
{-17789.3,62.5,6751.8,37.2},{-17763.2,62.5,6761.3,37.1},{-17734.7,62.4,6771.7,37.5},{-17715.3,62.4,6778.7,37.3},{-17687.9,62.4,6788.7,37.1},{-17659.4,62.4,6799.1,37.1},{-17630,62.5,6809.8,37.4},{-17609.8,62.5,6817.1,37.7},{-17581.7,62.4,6827.3,37.4},{-17554.1,62.5,6837.4,37.2},
{-17527.7,62.5,6847,37.8},{-17508.3,62.5,6854.1,37.3},{-17480.9,62.5,6864.1,37.3},{-17461.7,62.5,6871,37.7},{-17435.9,62.5,6880.4,37.1},{-17409.7,62.5,6890,37.4},{-17389.8,62.5,6897.2,37.3},{-17362.5,62.5,6907.1,37.2},{-17337,62.5,6916.4,37.3},{-17307.6,62.5,6926.7,36.7},
{-17278.7,62.6,6934.8,36.1},{-17250.6,62.4,6942,37.1},{-17221.6,62.4,6949.5,37.3},{-17192.3,62.5,6957.4,37.3},{-17164.3,62.5,6964.9,37.4},{-17136.3,62.5,6972.4,37.4},{-17107.1,62.5,6980.2,37.5},{-17079.1,62.5,6987.8,37.4},{-17050.3,62.4,6995.5,37.4},{-17021,62.5,7003.3,37.4},
{-16991.7,62.5,7011.2,37.6},{-16963.8,62.4,7018.6,38.1},{-16935.3,62.5,7026.2,38.1},{-16914.3,62.5,7031.9,37.4},{-16884.4,62.5,7039.9,37.5},{-16855.7,62.4,7047.6,37.4},{-16826.6,62.4,7055.4,37.4},{-16796.9,62.4,7063.3,37.7},{-16767.6,62.4,7071.2,37.7},{-16738.8,62.5,7078.9,37.5},
{-16708.6,62.4,7087,37.4},{-16677.2,62.4,7095.5,37.4},{-16646.1,62.4,7103.8,37.5},{-16617.1,62.5,7111.5,38.1},{-16584.9,62.4,7120.2,37.5},{-16552.1,62.5,7129,37.5},{-16524.5,62.4,7136.4,37.9},{-16491.7,62.4,7145.2,37.5},{-16465.4,62.4,7152.2,38},{-16445.4,62.4,7157.5,37.4},
{-16419.2,62.5,7164.6,37.7},{-16399.4,62.5,7169.9,37.4},{-16371.6,62.5,7177.1,37},{-16340.5,62.5,7183.3,35.9},{-16310.2,62.5,7188.2,37},{-16272.2,62.4,7194.6,38},{-16243.3,62.5,7199.7,37.8},{-16212.8,62.4,7205.1,37.8},{-16182.8,62.4,7210.4,37.4},{-16152.5,62.5,7215.7,37.4},
{-16122.8,62.5,7221,37.3},{-16092.4,62.4,7226.3,37.3},{-16061.8,62.4,7231.7,37.1},{-16032.5,62.5,7236.9,37.4},{-16003.6,62.5,7242,37.9},{-15980.8,62.4,7246,38},{-15951,62.5,7251.2,37.3},{-15920.3,62.5,7256.7,37.4},{-15892.3,62.5,7261.6,37.2},{-15862.6,62.5,7266.8,38},
{-15842.8,62.5,7270.3,37.2},{-15815.6,62.5,7275.1,37.7},{-15795,62.4,7278.8,37.1},{-15767.1,62.5,7283.7,37.9},{-15735.9,62.4,7289.2,37.2},{-15708.7,62.5,7294,37.4},{-15688.7,62.5,7297.5,37.4},{-15661,62.5,7302.4,37.3},{-15625.2,62.5,7308.7,37.8},{-15594,62.5,7314.2,37.4},
{-15564.2,62.5,7319.5,37.5},{-15535.9,62.5,7324.4,37.2},{-15505.6,62.5,7329.8,37.3},{-15476.3,62.5,7335,37.5},{-15455.1,62.5,7338.7,37.8},{-15426.8,62.5,7343.6,37.6},{-15399.2,62.5,7347.8,36.6},{-15370.6,62.5,7350.1,36.6},{-15343.1,62.4,7352.3,37.4},{-15322.9,62.5,7354.1,38},
{-15294.6,62.5,7356.6,37.3},{-15267.6,62.5,7358.9,37.3},{-15239.8,62.4,7361.4,37.5},{-15219.3,62.5,7363.2,37.8},{-15190.5,62.5,7365.7,37.2},{-15162.8,62.5,7368.1,37.2},{-15133.7,62.5,7370.7,37.6},{-15113.3,62.5,7372.4,38},{-15084.4,62.5,7375,37.5},{-15055.2,62.5,7377.5,37.3},
{-15025.5,62.5,7380.1,37.3},{-14996.3,62.4,7382.7,37.5},{-14974.3,62.5,7384.6,38.1},{-14943.5,62.4,7387.3,37.5},{-14913.3,62.4,7389.9,37.2},{-14883.3,62.5,7392.5,37.2},{-14852.5,62.5,7395.2,37.2},{-14823.5,62.4,7397.8,37.2},{-14794.3,62.4,7400.4,37.3},{-14763.2,62.5,7403.1,37.6},
{-14731.4,62.5,7405.9,38},{-14707.7,62.5,7407.9,37.9},{-14675,62.4,7410.8,37.6},{-14643.6,62.4,7413.5,37.7},{-14614.7,62.4,7416,37.4},{-14581,62.4,7419,37.2},{-14554.4,62.4,7421.4,37.3},{-14533.9,62.5,7423.1,37.5},{-14505.8,62.4,7425.6,37.1},{-14484.4,62.4,7427.5,37.5},
{-14456,62.4,7430,37.2},{-14428.9,62.4,7432.3,37.4},{-14408.5,62.4,7434.1,37.5},{-14378.3,62.4,7436.7,37.4},{-14357.8,62.4,7438.5,37.6},{-14330.2,62.5,7440.9,37.3},{-14301.1,62.5,7443.5,37.3},{-14279.8,62.5,7445.4,37.5},{-14252.3,62.5,7447.8,37.1},{-14223.3,62.4,7450.3,37.7},
{-14202,62.4,7452.2,37.3},{-14175,62.4,7454.5,37.1},{-14153,62.4,7456.5,37.7},{-14123.7,62.5,7459,37.2},{-14095.7,62.4,7461.5,37.6},{-14074.9,62.5,7463.3,37.5},{-14046.9,62.4,7465.7,37.1},{-14017.2,62.5,7468.3,37.9},{-13995.5,62.4,7470.2,37.2},{-13967.2,62.4,7472.7,37.3},
{-13945.4,62.4,7474.6,37.5},{-13914.8,62.4,7477.3,37.3},{-13893.6,62.4,7479.2,37.6},{-13862.1,62.5,7481.9,37.4},{-13840.8,62.4,7483.8,37.5},{-13809.8,62.5,7486.5,37.3},{-13787.7,62.4,7488.4,37.6},{-13759.7,62.5,7490.8,37.2},{-13728.8,62.5,7493.6,37.6},{-13706.7,62.5,7495.5,37.2},
{-13678,62.4,7498,37.1},{-13647.9,62.4,7500.6,37.8},{-13625.1,62.5,7502.7,37.1},{-13597.2,62.5,7505.1,37.1},{-13567.3,62.5,7507.7,37.8},{-13545.6,62.5,7509.6,37.1},{-13515.4,62.5,7512.3,37.6},{-13493.9,62.5,7514.1,37.3},{-13464.1,62.5,7516.7,37.5},{-13443,62.5,7518.6,37.3},
{-13413.6,62.5,7521.1,37.4},{-13391.6,62.5,7523.1,37.2},{-13361.3,62.5,7524.9,36.2},{-13333.3,62.5,7525.2,36.3},{-13313,62.5,7524.8,36.6},{-13284.6,62.4,7524.5,38.4},{-13260.7,62.5,7524.5,38.2},{-13229,62.5,7524.5,37.9},{-13197.6,62.5,7524.5,37.7},{-13166.3,62.5,7524.5,37.6},
{-13135.1,62.5,7524.5,37.5},{-13103.9,62.5,7524.5,37.5},{-13072.8,62.4,7524.5,37.5},{-13041.7,62.5,7524.5,37.6},{-13012.3,62.5,7524.5,38.3},{-12989.2,62.5,7524.5,38.1},{-12957.6,62.5,7524.5,37.6},{-12928.7,62.5,7524.5,37.6},{-12898.2,62.5,7524.5,38},{-12876.4,62.5,7524.5,38.3},
{-12845.8,62.5,7524.5,37.8},{-12816.1,62.5,7524.5,37.5},{-12786.4,62.5,7524.5,37.9},{-12759,62.5,7524.5,38.1},{-12738.4,62.5,7524.5,37.9},{-12709.5,62.5,7524.5,37.5},{-12680.8,62.5,7524.5,38.1},{-12659.7,62.5,7524.5,37.5},{-12632.2,62.5,7524.5,37.7},{-12603.7,62.5,7523.6,37.6},
{-12582.2,62.5,7522.1,36.8},{-12552.3,62.4,7519.3,37.4},{-12524.1,62.5,7516.7,37.1},{-12494.5,62.5,7514.1,37.1},{-12464.9,62.5,7511.6,37.1},{-12435.3,62.5,7509,37.2},{-12404.8,62.5,7506.3,37.6},{-12375.5,62.5,7503.7,37.5},{-12345.3,62.5,7501.1,37.7},{-12311.9,62.5,7498.2,37.1},
{-12278.3,62.5,7495.3,37.3},{-12249,62.5,7492.7,37},{-12221.1,62.5,7490.3,37.4},{-12200.8,62.5,7488.5,37.3},{-12172.6,62.5,7486,37},{-12144.1,62.5,7483.5,37.7},{-12123.3,62.5,7481.7,37.3},{-12094.5,62.4,7479.2,37},{-12065.5,62.5,7476.6,37.7},{-12044.2,62.4,7474.8,37.3},
{-12014.7,62.5,7472.2,37.1},{-11985.2,62.4,7469.6,37.3},{-11963.3,62.5,7467.7,37.7},{-11933.2,62.5,7465,37.2},{-11903,62.5,7462.4,37},{-11872.4,62.4,7459.7,37.4},{-11841.7,62.5,7457,38},{-11818.9,62.5,7455.1,37.3},{-11789.9,62.4,7452.5,37.5},{-11759.2,62.4,7449.9,37.3},
{-11727.7,62.4,7447.1,37.2},{-11695.9,62.5,7444.3,37.2},{-11663.9,62.4,7441.5,37.2},{-11631.7,62.4,7438.7,37.7},{-11599.3,62.4,7435.8,37.9},{-11568.8,62.5,7433.2,37.6},{-11534.6,62.4,7430.2,37.1},{-11514,62.4,7428.4,37.6},{-11487,62.5,7426,37.1},{-11458.4,62.4,7423.5,37.9},
{-11437.5,62.5,7421.7,37.1},{-11410.1,62.5,7419.3,37.5},{-11389.8,62.5,7417.5,37.3},{-11360,62.4,7414.9,37.5},{-11338.7,62.4,7413,37.2},{-11308.7,62.4,7410.4,37.6},{-11286.4,62.4,7408.5,37.2},{-11256.9,62.5,7405.9,37.7},{-11235.2,62.4,7404,37.1},{-11204.9,62.5,7401.4,37.9},
{-11183.4,62.5,7399.4,37.1},{-11161.2,62.5,7397.5,37.7},{-11131.7,62.4,7394.9,37.2},{-11109.5,62.5,7393,37.3},{-11079.8,62.4,7390.4,37.4},{-11045.9,62.4,7387.4,37.4},{-11018.3,62.4,7385,37.1},{-10996.5,62.4,7383.1,38.1},{-10965.7,62.4,7380.4,37.1},{-10943.8,62.5,7378.5,37.6},
{-10915.9,62.4,7376,37.2},{-10891,62.4,7373.9,37.3},{-10865.9,62.4,7371.7,37.6},{-10834.8,62.4,7369,37.4},{-10809.6,62.4,7366.7,37.2},{-10784.4,62.4,7364.5,37.1},{-10759.1,62.5,7362.3,37.2},{-10733.7,62.5,7360.1,37.4},{-10708.3,62.4,7357.9,37.6},{-10679.8,62.4,7355.4,37.2},
{-10654.3,62.4,7353.2,37.3},{-10628.7,62.4,7350.9,37.7},{-10602.3,62.5,7348.6,37.7},{-10574.3,62.5,7346.2,37.1},{-10542.5,62.5,7343.3,36.6},{-10516.9,62.5,7340.8,36.4},{-10491.2,62.5,7338.6,36.5},{-10465.3,62.5,7336.4,36.5},{-10439.5,62.5,7334.2,36.8},{-10413.6,62.5,7332,37.2},
{-10381.3,62.5,7329.3,37.6},{-10355.3,62.5,7327,37.3},{-10329.2,62.4,7324.7,37.2},{-10302.3,62.5,7322.4,37.1},{-10273.8,62.4,7319.9,37.3},{-10247.5,62.4,7317.6,37.1},{-10217.2,62.4,7315,37.9},{-10194,62.5,7312.9,37.1},{-10165.2,62.5,7310.4,37.2},{-10138.7,62.4,7308,37.1},
{-10112.1,62.5,7305.7,37.2},{-10085.5,62.4,7303.4,37.4},{-10052.5,62.4,7300.5,37.5},{-10025.7,62.4,7298.2,37.2},{-9999,62.4,7295.9,37.1},{-9972.1,62.5,7293.5,37.1},{-9945.3,62.5,7291.2,37.3},{-9915.1,62.4,7288.5,37.2},{-9888.2,62.4,7286.1,37.2},{-9860.2,62.4,7283.7,37.2},
{-9830.7,62.4,7281.1,37.1},{-9803.5,62.5,7278.7,37.2},{-9776.3,62.4,7276.3,37.5},{-9742.5,62.5,7273.4,37.5},{-9715.2,62.4,7271,37.2},{-9687.8,62.4,7268.6,37.2},{-9660.5,62.4,7266.2,37.2},{-9632.3,62.4,7263.8,37.3},{-9602.5,62.5,7261.2,37.2},{-9575.2,62.5,7258.8,37.3},
{-9541.5,62.5,7255.8,37.5},{-9514.3,62.4,7253.4,37.1},{-9487.2,62.5,7251.1,37.1},{-9460.2,62.5,7248.7,37.6},{-9427.1,62.4,7245.8,37.1},{-9400.4,62.5,7243.5,37.3},{-9373.7,62.4,7241.1,38.2},{-9343.4,62.5,7238.5,37.7},{-9311.8,62.5,7235.7,37.2},{-9279.7,62.4,7232.9,37.3},
{-9247.6,62.5,7230.1,38.1},{-9224.2,62.4,7228,37.4},{-9192.2,62.4,7225.3,37.1},{-9160.2,62.4,7222.5,37.5},{-9136.7,62.4,7220.4,37.8},{-9104.8,62.4,7217.6,37.2},{-9073,62.4,7214.8,37.3},{-9043.3,62.4,7212.2,37.2},{-9012.1,62.4,7209.5,37.2},{-8980.3,62.4,7206.7,37.7},
{-8956.2,62.4,7204.6,37.5},{-8924.9,62.4,7201.9,37.3},{-8892.9,62.4,7199.1,37.1},{-8862.9,62.5,7196.4,37.2},{-8831.5,62.5,7193.7,37.3},{-8799.2,62.4,7190.9,37.8},{-8775.5,62.4,7188.8,37.8},{-8743.2,62.4,7186,37.3},{-8710,62.4,7183.1,37.3},{-8678.2,62.4,7180.3,37.5},
{-8645.7,62.5,7177.4,38.1},{-8621.6,62.4,7175.3,37.4},{-8588.9,62.4,7172.5,37.2},{-8556.2,62.4,7169.6,37.3},{-8523.2,62.4,7166.7,38},{-8498.3,62.5,7164.6,37.3},{-8466.1,62.4,7161.8,37.2},{-8433.2,62.5,7158.9,37.2},{-8403.2,62.4,7156.2,37.2},{-8372.5,62.4,7153.5,37.1},
{-8340.5,62.4,7150.7,37.2},{-8307.8,62.4,7147.9,37.4},{-8283.7,62.4,7145.8,38.1},{-8251.1,62.5,7142.9,37.7},{-8218.5,62.4,7140.1,37.3},{-8186,62.4,7137.3,37.2},{-8152.9,62.4,7134.3,37.2},{-8121.1,62.4,7131.6,37.2},{-8088.8,62.5,7128.7,37.5},{-8056.6,62.5,7125.9,37.7},
{-8032.9,62.5,7123.9,38},{-8001.2,62.5,7121.1,37.6},{-7969.9,62.5,7118.3,37.2},{-7939,62.5,7115.6,37.2},{-7908.5,62.5,7112.9,37.3},{-7886.4,62.5,7111,38},{-7856.6,62.5,7108.4,37.2},{-7827.2,62.5,7105.8,37.2},{-7806.1,62.5,7104,38},{-7777,62.5,7100.8,36.2},
{-7749.8,62.5,7096.3,35.2},{-7729.9,62.5,7092.6,36.7},{-7702.5,62.4,7087.2,37},{-7675.3,62.4,7082.3,37.8},{-7644.4,62.5,7076.8,37.7},{-7613.8,62.5,7071.4,37.6},{-7583.5,62.4,7066.1,37.6},{-7553.4,62.5,7060.8,37.5},{-7523.3,62.5,7055.4,37.5},{-7493.3,62.5,7050.2,37.5},
{-7463.2,62.5,7044.9,37.4},{-7433.1,62.4,7039.6,37.4},{-7403.2,62.5,7034.3,37.4},{-7373.6,62.5,7029,37.4},{-7344.8,62.6,7022.8,35.7},{-7316.5,62.5,7015.3,35.6},{-7288.5,62.4,7007.3,36.6},{-7260.7,62.5,6999.9,36.7},{-7233,62.5,6992.5,36.8},{-7205.6,62.5,6985.1,36.7},
{-7177.5,62.5,6977.6,36.9},{-7150.5,62.5,6970.4,36.8},{-7122.8,62.5,6962.9,36.8},{-7095,62.5,6955.5,36.8},{-7067.1,62.5,6948,36.8},{-7039.1,62.5,6940.5,36.8},{-7011,62.5,6933,36.7},{-6983.1,62.5,6925.5,36.7},{-6955.5,62.5,6918.1,36.8},{-6928.7,62.5,6909.5,35.3},
{-6902.5,62.5,6899.8,36},{-6870.1,62.4,6887.7,36.5},{-6844.2,62.5,6878.3,36.5},{-6818.4,62.5,6868.9,36.4},{-6792.5,62.5,6859.5,36.1},{-6766.4,62.5,6850,36},{-6740.2,62.5,6840.5,36},{-6713.9,62.5,6830.9,35.9},{-6687.4,62.5,6821.2,35.9},{-6660.6,62.4,6811.5,36.1},
{-6633.2,62.4,6801.5,36.3},{-6613.8,62.5,6794.4,36.3},{-6587,62.5,6784.7,36},{-6560.5,62.5,6775,35.8},{-6534.8,62.5,6764.8,35.1},{-6509.8,62.5,6753.2,35.3},{-6479.3,62.4,6738.6,36.4},{-6454.8,62.5,6727.2,36.1},{-6430.6,62.5,6715.9,36},{-6406.3,62.4,6704.6,36},
{-6382,62.5,6693.2,36},{-6357.5,62.5,6681.8,35.8},{-6332.8,62.4,6670.3,35.7},{-6307.9,62.5,6658.6,35.8},{-6282.9,62.5,6647,35.7},{-6257.8,62.5,6635.3,35.8},{-6232.6,62.5,6623.6,36.1},{-6201.5,62.5,6609,36.4},{-6176.6,62.5,6597.5,36.1},{-6152.3,62.5,6585.7,35.5},
{-6129,62.5,6572.6,35.5},{-6106.3,62.4,6559,36.4},{-6083.6,62.4,6545.8,36.6},{-6061,62.5,6532.7,36.8},{-6038.2,62.5,6519.6,37},{-6009.8,62.5,6503.2,36.8},{-5986.7,62.5,6489.9,36.7},{-5963.5,62.4,6476.5,36.5},{-5940,62.5,6462.9,36.5},{-5916.4,62.4,6449.3,36.5},
{-5892.6,62.4,6435.5,36.6},{-5868.7,62.4,6421.7,36.9},{-5839,62.5,6404.6,36.9},{-5814.9,62.4,6390.7,36.5},{-5790.4,62.5,6376.5,36.4},{-5765.9,62.5,6360.9,35.7},{-5743.7,62.5,6345.2,36.8},{-5720,62.4,6328.2,37},{-5692.7,62.5,6309.1,36.6},{-5670.5,62.5,6293.5,36.6},
{-5648.1,62.5,6277.9,36.8},{-5620.2,62.5,6258.4,36.9},{-5597.4,62.5,6242.4,36.6},{-5574,62.4,6226,36.6},{-5551.4,62.5,6210.2,37.1},{-5534.5,62.5,6198.4,36.9},{-5511.7,62.5,6182.4,36.6},{-5489,62.5,6166.5,36.6},{-5466.5,62.5,6150.7,36.6},{-5444.2,62.4,6135.1,36.6},
{-5422.5,62.5,6119.5,36.2},{-5402,62.5,6102.8,35.7},{-5377.1,62.5,6081.5,36.6},{-5357.2,62.4,6064.6,36.6},{-5337.2,62.5,6047.8,36.5},{-5317.1,62.5,6031.1,36.3},{-5297.1,62.5,6014.2,36.3},{-5277,62.5,5997.4,36.2},{-5256.8,62.5,5980.4,36.4},{-5236.5,62.5,5963.3,36.7},
{-5211.1,62.5,5942.1,36.6},{-5190.5,62.4,5924.8,36.3},{-5169.6,62.5,5907.2,36.3},{-5148.6,62.5,5889.6,36.6},{-5122.5,62.5,5867.7,36.7},{-5101.5,62.5,5850.1,36.3},{-5081.7,62.5,5831.8,35},{-5063,62.5,5812.9,35.5},{-5044.5,62.4,5793.8,36.5},{-5021.3,62.5,5770.6,36.6},
{-5002.6,62.5,5751.9,36.3},{-4983.9,62.5,5733.2,36.1},{-4965.2,62.5,5714.5,36.2},{-4946.3,62.4,5695.6,36.5},{-4926.3,62.5,5675.7,36.7},{-4912.1,62.4,5661.4,36.4},{-4893,62.5,5642.4,36.1},{-4873.9,62.5,5623.2,36.3},{-4850.4,62.5,5599.7,36.4},{-4831.9,62.5,5581.2,36.3},
{-4812.5,62.5,5561.9,36.1},{-4789.5,62.5,5538,36.1},{-4772,62.5,5517.9,35},{-4755.3,62.4,5497.4,36},{-4734.4,62.4,5472.3,36.4},{-4717.3,62.5,5452,36.1},{-4700.2,62.4,5431.5,36.2},{-4678.8,62.5,5406.1,36.4},{-4661.4,62.5,5385.3,36},{-4643.7,62.5,5364.2,36.3},
{-4630.7,62.5,5348.7,36.6},{-4612.8,62.5,5327.4,36.1},{-4594.7,62.5,5305.8,36.3},{-4572.4,62.5,5279.3,36.2},{-4554.2,62.5,5257.6,36.1},{-4532.1,62.5,5231.2,36.5},{-4514.5,62.5,5209.7,35.6},{-4494.8,62.5,5182.5,34.7},{-4479.5,62.4,5160,35.3},{-4464.1,62.4,5137.7,35.9},
{-4445,62.5,5110.4,35.8},{-4429.2,62.5,5088,35.7},{-4413.5,62.5,5065.3,36.3},{-4401.8,62.5,5048.7,35.9},{-4385.7,62.5,5025.8,35.7},{-4369.5,62.5,5002.6,36.1},{-4357.7,62.4,4985.8,36},{-4341.4,62.5,4962.5,35.7},{-4321.5,62.5,4933.9,36.1},{-4305,62.5,4910.5,35.8},
{-4289.8,62.5,4888.7,35.8},{-4275.6,62.4,4868.5,35.8},{-4262.1,62.6,4848,34.6},{-4249.3,62.5,4827,33.5},{-4239.1,62.5,4809.4,33.6},{-4227.5,62.5,4788.1,34.8},{-4214.7,62.4,4765.1,35.2},{-4200.7,62.5,4740.9,35.7},{-4190.6,62.5,4723.4,35.4},{-4177.6,62.5,4700.9,35.3},
{-4163.6,62.5,4676.7,35.6},{-4153.5,62.5,4659,35.6},{-4139.3,62.4,4634.5,35.3},{-4121.9,62.5,4604.5,35.6},{-4107.8,62.5,4580.1,35.2},{-4093.9,62.5,4556,35.7},{-4083.9,62.5,4538.6,35.6},{-4070.2,62.5,4514.9,35.3},{-4054,62.6,4486,35.4},{-4042.2,62.5,4462.2,34},
{-4031.4,62.4,4438,35.4},{-4018,62.4,4408.8,35.8},{-4006.6,62.5,4384.4,35.5},{-3995.3,62.5,4360.1,35.8},{-3981.3,62.5,4330.1,35.7},{-3969.8,62.5,4305.4,35.5},{-3958.2,62.5,4280.5,35.8},{-3949.6,62.5,4262.3,36},{-3937.9,62.5,4237.1,35.5},{-3926.1,62.5,4211.9,35.7},
{-3911.7,62.5,4181,35.7},{-3900.2,62.5,4156.2,35.6},{-3888.7,62.5,4131.6,35.9},{-3874.7,62.5,4101.6,35.7},{-3864.7,62.5,4077.2,35.2},{-3853.9,62.4,4046.7,36.1},{-3845.3,62.4,4022.1,36.3},{-3836.4,62.5,3997.9,36.3},{-3827.6,62.5,3973.6,36.4},{-3818.9,62.5,3949.7,36.6},
{-3807.7,62.5,3918.9,36.7},{-3798.7,62.5,3894.3,36.5},{-3789.6,62.4,3869.4,36.4},{-3780.5,62.5,3844.3,36.2},{-3771.3,62.5,3819,36.3},{-3762.1,62.5,3793.7,36.6},{-3750.6,62.5,3762.1,36.6},{-3741.3,62.5,3736.6,36.3},{-3732.1,62.5,3711.2,36.4},{-3721.5,62.5,3680,36.4},
{-3714.7,62.5,3655,36.3},{-3708.1,62.4,3629,36.9},{-3701.4,62.5,3603.8,36.9},{-3694.7,62.5,3579.2,36.9},{-3688,62.5,3553.8,37.1},{-3681.2,62.5,3528.8,37.1},{-3674.5,62.5,3503.6,37.1},{-3667.8,62.5,3478.3,37.1},{-3660.9,62.5,3452.8,37.1},{-3654,62.5,3427.1,37.1},
{-3647.1,62.5,3401.2,37.2},{-3640.1,62.5,3375.2,37.2},{-3633.1,62.5,3349.1,37.4},{-3627.9,62.5,3329.7,37.3},{-3620.9,62.5,3303.5,37.1},{-3614,62.5,3277.4,36.7},{-3608.6,62.5,3251.4,36},{-3604.3,62.4,3225.2,36.6},{-3599.7,62.4,3197.3,37},{-3595.1,62.5,3171.6,37.1},
{-3590.6,62.5,3146.2,37.1},{-3586,62.5,3119.8,37.2},{-3581.4,62.5,3093.6,37.3},{-3576.7,62.5,3067.1,37.4},{-3572,62.5,3040.5,37.5},{-3568.5,62.4,3020.5,37.6},{-3563.7,62.5,2993.4,37.4},{-3558.9,62.5,2966.2,37.2},{-3554.1,62.5,2938.9,37.1},{-3549.3,62.5,2911.6,37},
{-3544.5,62.5,2884.2,37.1},{-3538.9,62.5,2850.7,37.1},{-3535.9,62.5,2824.3,35.9},{-3533.8,62.4,2797.3,36.3},{-3531.7,62.4,2770.8,36.7},{-3529.4,62.5,2744.3,36.7},{-3527.1,62.5,2717.7,36.9},{-3524.7,62.5,2690.9,37},{-3522.3,62.5,2663.8,37.1},{-3520.6,62.5,2643.7,37.3},
{-3518.2,62.5,2616.3,37},{-3515.8,62.4,2588.6,36.8},{-3513.3,62.4,2560.7,36.8},{-3510.8,62.5,2532.5,36.8},{-3508.4,62.5,2504.3,37},{-3506,62.5,2476.8,37},{-3502.9,62.5,2441.9,37.3},{-3501.2,62.5,2414.6,36},{-3500.7,62.5,2387.6,35.1},{-3501.1,62.4,2361.1,35.9},
{-3501.3,62.4,2334.5,36.2},{-3501.3,62.5,2307.4,36.2},{-3501.3,62.5,2280.6,36.3},{-3501.3,62.5,2253.6,36.4},{-3501.3,62.5,2226.3,36.5},{-3501.3,62.5,2198.9,36.6},{-3501.3,62.5,2164.4,36.8},{-3501.3,62.5,2136.3,36.6},{-3501.3,62.5,2108.1,36.4},{-3501.3,62.4,2079.6,36.3},
{-3501.3,62.5,2050.9,36.2},{-3501.3,62.5,2022.4,36.2},{-3501.3,62.5,1994.3,36.5},{-3501.2,62.5,1960.2,36.8},{-3501.2,62.5,1933.1,36.5},{-3501.2,62.5,1906.6,36.4},{-3501.2,62.5,1880.7,36.4},{-3501.2,62.5,1855.5,36.6},{-3501.2,62.5,1826.1,36.4},{-3501.2,62.5,1796.7,36.6},
{-3501.2,62.5,1776.4,37.1},{-3501.2,62.5,1748.6,36.6},{-3501.2,62.5,1720.8,36.4},{-3501.2,62.5,1692.9,36.4},{-3500.9,62.5,1666.3,35.8},{-3500.5,62.5,1640.1,35},{-3500.1,62.5,1615.1,34.3},{-3499.7,62.5,1589.5,33.4},{-3500.2,62.5,1561.6,34.5},{-3502.5,62.5,1533.8,39},
{-3504.2,62.5,1506.2,42.5},{-3505.4,62.5,1479.6,44.8},{-3506.5,62.5,1453.7,47.1},{-3507.7,62.5,1427.2,49.4},{-3508.9,62.5,1399.7,51.7},{-3512.2,62.5,1365.4,51.6},{-3516.2,62.5,1337.9,48.2},{-3520.6,62.5,1311.9,44},{-3525.5,62.5,1285.8,39},{-3530.6,62.5,1259.9,32.9},
{-3535.9,62.4,1233.5,26.8},{-3540.6,62.4,1205.8,21.9},{-3543.7,62.4,1178.3,21.1},{-3543.7,64.4,1151.2,22.9},{-3542.5,67.7,1118.8,24.5},{-3542.5,70.5,1091.8,24.2},{-3542.5,73.3,1063.7,24.3},{-3542.5,75.5,1041.4,24.5},{-3542.5,78.4,1013.5,24.5},{-3542.5,82.2,975.4,24.5},
{-3542.5,85.5,943.1,24.8},{-3542.5,88.9,909.7,24.7},{-3542.5,91.8,881.5,24.4},{-3542.5,94.7,852.6,24.2},{-3542.5,97.4,825.5,24.4},{-3542.5,100.1,798.9,24.3},{-3542.5,102.9,771.2,24.9},{-3542.5,105.5,745,25},{-3542.5,108.9,711.8,25},{-3542.5,111.7,684,25},
{-3542.5,114.5,656.6,24.5},{-3542.5,117.3,628.6,24.3},{-3542.5,120.3,600,24.2},{-3542.5,123.1,572.2,24.6},{-3542.5,126.5,538.5,24.6},{-3542.5,129.4,510.1,24.5},{-3542.5,132,483.7,24.2},{-3542.5,134.7,457.7,24.5},{-3542.5,137.3,430.8,24.7},{-3542.5,138.2,403.5,24.1},
{-3542.4,137.3,376.1,24.3},{-3542.2,137.4,349.8,24.1},{-3542,137.4,322.2,23.4},{-3541.9,137.4,294.8,23},{-3541.7,137.3,268.5,22.8},{-3541.5,137.3,241.1,22.3},{-3541.3,137.3,214.1,22},{-3541.1,137.4,186.1,21.5},{-3541,137.4,158.8,21.3},{-3540.8,137.3,131.1,21},
{-3540.6,137.3,102.1,20.9},{-3540.4,137.4,74.8,21.2},{-3540.3,137.4,47.3,21.6},{-3540.2,137.4,21.8,21.8},{-3540.1,137.4,-4.2,22.3},{-3540.1,137.4,-30.1,22.5},{-3540.1,137.4,-56.3,22.4},{-3540.1,137.4,-81.4,22.6},{-3540.1,137.4,-106.9,23.3},{-3540.1,137.3,-136.2,22.9},
{-3540,137.3,-164.3,22.4},{-3539.9,137.4,-192.6,22.4},{-3539.8,137.4,-220.4,22.5},{-3539.8,136.6,-248.6,22.5},{-3540.1,135.5,-277.2,22.3},{-3540.8,134.6,-304.8,21.9},{-3541.4,133.8,-325.8,20.5},{-3542.4,132.8,-354.6,19.4},{-3543.2,131.8,-383.2,18.7},{-3543.8,130.9,-411.7,18.4},
{-3544.3,129.9,-439.2,17.7},{-3544.7,128.9,-467.4,17.7},{-3544.7,128,-495.2,18.7},{-3544.5,126.9,-523.7,20},{-3543.9,126,-552,21.9},{-3543.6,125.2,-572.2,24.2},{-3543.2,124.5,-593.6,24.8},{-3543.3,123.5,-621.7,24.5},{-3543.2,121.7,-649.2,24.4},{-3543.2,119.8,-675.6,24.6},
{-3543.2,118,-702.1,24.4},{-3543.2,116.1,-729.2,24.1},{-3543.2,114.3,-754.8,24.2},{-3543.2,112.5,-780.9,24.1},{-3543.2,110.5,-808.4,24.1},{-3543.2,108.7,-834.7,24.1},{-3543.2,106.9,-861.1,24.1},{-3543.2,105,-887.1,24.1},{-3543.3,103.1,-914.6,24},{-3543.3,101.3,-940.8,24},
{-3543.3,99.4,-967.3,24.1},{-3543.3,97.6,-993.4,24.2},{-3543.3,95.8,-1019.7,24.3},{-3543.3,93.9,-1045.7,24.3},{-3543.3,92.1,-1071.3,24.1},{-3543.3,90.3,-1097.9,24.1},{-3543.3,88.4,-1123.6,24.3},{-3543.3,86.7,-1149.3,24},{-3543.3,84.8,-1176.6,24.1},{-3543.3,83,-1202.1,24.5},
{-3543.3,81.2,-1227.8,24.7},{-3543.3,79,-1259.7,24.3},{-3543.3,77.2,-1285.1,24.4},{-3543.3,75.4,-1310.4,24.5},{-3543.3,73.7,-1335.5,24.3},{-3543.3,71.9,-1361.5,24.6},{-3543.3,70.2,-1386.6,24.7},{-3543.3,68.4,-1412.2,24.3},{-3543.3,66.6,-1437.9,24.1},{-3543.3,64.9,-1462.2,24.1},
{-3543.2,63.9,-1486.8,24.1},{-3543.2,63.1,-1511.5,24},
}


-- ==========================================
-- MODULE: farm.lua
-- ==========================================
-- HipHub Ghost Driver — Automation & Farm Engine (BAC-5513 Bypass Safe)
-- Implements Auto Race, Quest Automation, Speed Cruise, and Auto Buy Car

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer

	local UI = _G.HipHubUI
	local Config = _G.HipHubConfig or { farm = {} }
	local Settings = _G.HipHub_GhostDriver_Settings

	local Remotes = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Remotes"))
	local CarCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Menu"):WaitForChild("CarCatalog"))
	local HudTeleport = ReplicatedStorage:WaitForChild("HudTeleport", 15)
	local GetQuestsByScope = ReplicatedStorage:WaitForChild("GetQuestsByScope", 15)
	local ClaimQuestByScope = ReplicatedStorage:WaitForChild("ClaimQuestByScope", 15)

	local PurchaseCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("PurchaseCar", 15)
	local SpawnCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("SpawnCarEvent", 15)

	------------------------------------------------
	-- VEHICLE DETECTION HELPER
	------------------------------------------------
	local function getMyCar()
		if not player.Character then return nil end
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart and hum.SeatPart.Parent then
			return hum.SeatPart.Parent, hum.SeatPart
		end

		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and (child:GetAttribute("OwnerUserId") == player.UserId or child.Name:find(player.Name)) then
				local seat = child:FindFirstChild("DriveSeat")
				if seat then
					return child, seat
				end
			end
		end
		return nil, nil
	end

	local function ensureInCar()
		local car, seat = getMyCar()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end

		if car and seat then
			if not hum.Sit or hum.SeatPart ~= seat then
				seat:Sit(hum)
				task.wait(0.4)
			end
			return car, seat
		end

		local targetSpawn = Config.vehicle.selectedCar or "Wulfbrecht RZ7"
		if SpawnCarRemote then
			SpawnCarRemote:FireServer(targetSpawn)
			task.wait(1.5)
			car, seat = getMyCar()
			if car and seat and hum then
				seat:Sit(hum)
				task.wait(0.4)
				return car, seat
			end
		end

		return nil, nil
	end

	local cachedCar = nil
	local cachedRideHeight = nil

	local function getCarRideHeight(car)
		if not car then return 1.15 end
		if cachedCar == car and cachedRideHeight then
			return cachedRideHeight
		end

		local pivotY = car:GetPivot().Position.Y
		local lowestY = nil

		-- Cari titik terendah dari seluruh roda/ban fisik
		for _, desc in ipairs(car:GetDescendants()) do
			if desc:IsA("BasePart") then
				local name = desc.Name:lower()
				if name:find("wheel") or name:find("tire") or name == "fl" or name == "fr" or name == "rl" or name == "rr" then
					local bY = desc.Position.Y - (desc.Size.Y * 0.5)
					if not lowestY or bY < lowestY then
						lowestY = bY
					end
				end
			end
		end

		if lowestY then
			local dist = pivotY - lowestY
			if dist >= 0.4 and dist <= 3.5 then
				cachedCar = car
				cachedRideHeight = dist
				return dist
			end
		end

		-- Fallback jika nama part custom: periksa part di bawah DriveSeat
		for _, desc in ipairs(car:GetDescendants()) do
			if desc:IsA("BasePart") and not desc:IsA("Seat") and desc.Name ~= "DriveSeat" then
				local bY = desc.Position.Y - (desc.Size.Y * 0.5)
				if not lowestY or bY < lowestY then
					lowestY = bY
				end
			end
		end

		if lowestY then
			local dist = pivotY - lowestY
			if dist >= 0.4 and dist <= 3.5 then
				cachedCar = car
				cachedRideHeight = dist
				return dist
			end
		end

		cachedCar = car
		cachedRideHeight = 1.15
		return 1.15
	end

	------------------------------------------------
	-- 🛡️ ANTI-CRASH & COLLISION CONTROLLER NEUTRALIZER
	------------------------------------------------
	-- The game simulates traffic crashes via custom client-side controllers:
	-- 1. TrafficImpactController: calculates SAT bounding-box intersections with TrafficFolder and violently pushes your car!
	-- 2. PoliceContactController: calculates contact against police cars and triggers PIT maneuver / bust!
	-- 3. CollisionController: triggers crash sound and sparks!
	local function neutralizeGameCollisions()
		pcall(function()
			local c = ReplicatedStorage:FindFirstChild("Controllers")
			if c then
				local TrafficImpact = c:FindFirstChild("TrafficImpactController")
				if TrafficImpact then
					local mod = require(TrafficImpact)
					if mod then
						-- Neutralize violent push impulse only (allows Near Miss & Close Call proximity sensors to still trigger!)
						mod.Push = function(self, ...) end
						-- Keep mod.Update, mod.sensors, mod.lastSeen intact so the game awards Near Miss streak!
					end
				end

				local PoliceContact = c:FindFirstChild("PoliceContactController")
				if PoliceContact then
					local mod = require(PoliceContact)
					if mod then
						mod.Update = function(self, ...) end
					end
				end

				local CollisionController = c:FindFirstChild("CollisionController")
				if CollisionController then
					local mod = require(CollisionController)
					if mod then
						mod.TriggerImpact = function(self, ...) end
					end
				end

				local uiFolder = c:FindFirstChild("UI")
				local ComboUI = uiFolder and uiFolder:FindFirstChild("ComboUIController")
				if ComboUI then
					local mod = require(ComboUI)
					if mod then
						if mod.TriggerCrashCheck then
							mod.TriggerCrashCheck = function(self, ...) return false end
						end
						local origLose = mod.LoseCombo
						mod.LoseCombo = function(self, reason, ...)
							-- Hanya cegah hilangnya combo jika terkena tabrakan/crash fisik
							if (Config.farm.autoSpeedFarm or Config.farm.autoRace) and (reason == "Crash" or reason == "Collision" or reason == "Impact") then
								return
							end
							if origLose then return origLose(self, reason, ...) end
						end

						-- Otomatis cairkan (Bank) combo ke wallet setelah streak tinggi
						-- agar uang bonus streak masuk terus ke akun tanpa harus toggle off/on!
						local origDrain = mod.DrainAdrenaline
						if origDrain then
							local lastBankTime = os.clock()
							mod.DrainAdrenaline = function(self, dt, ...)
								if Config.farm.autoSpeedFarm or Config.farm.autoRace then
									local now = os.clock()
									-- Setiap ~26 detik, biarkan adrenaline turun sebentar agar combo mencairkan uang bonus ke saldo!
									if (now - lastBankTime) > 26.0 then
										if self.adrenaline and self.adrenaline <= 0.2 then
											lastBankTime = now -- Siklus baru dimulai
										end
										return origDrain(self, dt * 1.5, ...)
									else
										-- Pertahankan adrenaline (drain 50% lebih lambat) agar streak tidak gampang putus di antara mobil
										if self.adrenaline and self.adrenaline < 4.0 then
											self.adrenaline = 4.0
										end
										return origDrain(self, dt * 0.5, ...)
									end
								end
								return origDrain(self, dt, ...)
							end
						end
					end
				end
			end
		end)
	end

	-- Immediately neutralize on script execution
	neutralizeGameCollisions()

	------------------------------------------------
	-- 🏁 AUTO RACE & HIGHWAY ENGINE (ANTI-FLYOVER & NOCLIP)
	------------------------------------------------
	local isRacingNow = false

	-- Universal Ghost Noclip & Traffic Neutralizer: runs on Stepped (before physics solver)
	-- Disables solid collisions while preserving CanTouch & CanQuery for Near-Miss detection.
	local lastNeutralizeCheck = 0
	RunService.Stepped:Connect(function()
		local now = os.clock()
		if now - lastNeutralizeCheck > 2.0 then
			lastNeutralizeCheck = now
			neutralizeGameCollisions()
		end

		if player.Character then
			for _, cp in ipairs(player.Character:GetDescendants()) do
				if cp:IsA("BasePart") and cp.CanCollide and (cp.Name == "CollisionPart" or cp.Name:find("Hitbox") or cp.Name:find("Collision")) then
					cp.CanCollide = false
				end
			end
		end

		local myCar = getMyCar()

		-- 1. Disable collision on car body parts, preserving CanTouch and CanQuery for near-miss registration
		if myCar then
			for _, p in ipairs(myCar:GetDescendants()) do
				if p:IsA("BasePart") then
					if p.Name:find("TrafficCollision") or p.Name:find("Impact") or p.Name:find("Hitbox") then
						p.CanCollide = false
					elseif p.Name ~= "FL" and p.Name ~= "FR" and p.Name ~= "RL" and p.Name ~= "RR" and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end

		-- 2. Disable solid collisions on NPC Traffic vehicles in workspace.TrafficFolder
		-- CanTouch = true and CanQuery = true are preserved for Near Miss / Streak detection!
		local tf = workspace:FindFirstChild("TrafficFolder")
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				for _, p in ipairs(tCar:GetDescendants()) do
					if p:IsA("BasePart") and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end

		-- 3. Disable collision on all other player characters in game
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				for _, part in ipairs(p.Character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end

		-- 4. Disable collision on all other vehicles, AI racers, police, and models in workspace
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar then
				if obj:FindFirstChild("DriveSeat") or obj:FindFirstChild("A-Chassis Tune") or obj:FindFirstChild("Body") or obj:FindFirstChild("Wheels") or obj.Name:find("AI") or obj.Name:find("Police") or obj.Name:find("Traffic") or obj.Name:find("_") then
					for _, part in ipairs(obj:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end
		end
	end)

	------------------------------------------------
	-- 🛣️ 3-LANE HIGHWAY ROAD MARGIN SENSOR (MOBILE & REDFINGER OPTIMIZED)
	------------------------------------------------
	local function isRoadAt(testPos, rayParams)
		local hit = workspace:Raycast(testPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
		if hit then
			local instName = hit.Instance.Name:lower()
			if not (instName:find("wall") or instName:find("guard") or instName:find("rail") or instName:find("fence")) then
				return true, hit.Position.Y
			end
		end
		return false, nil
	end

	local function getRoadMargins(carPos, rightVec, rayParams)
		local leftClearance = 0
		for _, dist in ipairs({ 7, 13, 20, 28 }) do
			if isRoadAt(carPos - rightVec * dist, rayParams) then
				leftClearance = dist
			else
				break
			end
		end

		local rightClearance = 0
		for _, dist in ipairs({ 7, 13, 20, 28 }) do
			if isRoadAt(carPos + rightVec * dist, rayParams) then
				rightClearance = dist
			else
				break
			end
		end

		return leftClearance, rightClearance
	end

	------------------------------------------------
	-- 🛡️ SENSOR PEMBATAS JALAN REAL-TIME MULTI-LEVEL (BARRIER SENSOR)
	------------------------------------------------
	local function isBarrierPart(instance)
		if not instance or not instance:IsA("BasePart") then return false end
		local n = instance.Name:lower()
		local p = instance.Parent and instance.Parent.Name:lower() or ""
		local g = instance.Parent and instance.Parent.Parent and instance.Parent.Parent.Name:lower() or ""

		-- Abaikan jalanan / aspal / garis / checkpoint
		if n:find("road") or n:find("asphalt") or n:find("street") or n:find("ground") or n:find("lane") or n:find("start") or n:find("finish") or n:find("checkpoint") then
			return false
		end

		-- Deteksi pagar besi, guardrail, collision shield, tembok beton, tiang
		if n:find("wall") or n:find("fence") or n:find("shield") or n:find("guard") or n:find("rail")
			or n:find("holder") or n:find("barrier") or n:find("post") or n:find("pole") or n:find("curb")
			or p:find("fence") or p:find("wall") or p:find("guard") or p:find("barrier")
			or g:find("fence") or g:find("wall") then
			return true
		end

		if (instance.Material == Enum.Material.Concrete or instance.Material == Enum.Material.Plastic or instance.Material == Enum.Material.Rubber or instance.Material == Enum.Material.Metal) and instance.CanCollide then
			return true
		end

		return false
	end

	local function detectBarriers(carPos, rightVec, forwardDir, rayParams)
		local rayHeights = {-0.7, 0.2, 1.2}
		local maxRayDist = 32

		local fDir = forwardDir or Vector3.zero
		local diagR = (rightVec * 0.707 + fDir * 0.707).Unit
		local diagL = (-rightVec * 0.707 + fDir * 0.707).Unit

		-- 1. Deteksi pembatas kanan (Tembok Beton) - Samping 90° & Serong Depan 45°
		local hasRightBarrier = false
		local distR = 99
		for _, h in ipairs(rayHeights) do
			local origin = carPos + Vector3.new(0, h, 0)
			local hitR = workspace:Raycast(origin, rightVec * maxRayDist, rayParams)
			if hitR and isBarrierPart(hitR.Instance) then
				hasRightBarrier = true
				if hitR.Distance < distR then
					distR = hitR.Distance
				end
			end

			if forwardDir then
				local hitDiagR = workspace:Raycast(origin, diagR * maxRayDist, rayParams)
				if hitDiagR and isBarrierPart(hitDiagR.Instance) then
					hasRightBarrier = true
					local effDist = hitDiagR.Distance * 0.707
					if effDist < distR then
						distR = effDist
					end
				end
			end
		end

		-- 2. Deteksi pembatas kiri (Pagar Besi Biru / CollisionShield / Tiang) - Samping 90° & Serong Depan 45°
		local hasLeftBarrier = false
		local distL = 99
		for _, h in ipairs(rayHeights) do
			local origin = carPos + Vector3.new(0, h, 0)
			local hitL = workspace:Raycast(origin, -rightVec * maxRayDist, rayParams)
			if hitL and isBarrierPart(hitL.Instance) then
				hasLeftBarrier = true
				if hitL.Distance < distL then
					distL = hitL.Distance
				end
			end

			if forwardDir then
				local hitDiagL = workspace:Raycast(origin, diagL * maxRayDist, rayParams)
				if hitDiagL and isBarrierPart(hitDiagL.Instance) then
					hasLeftBarrier = true
					local effDist = hitDiagL.Distance * 0.707
					if effDist < distL then
						distL = effDist
					end
				end
			end
		end

		-- 3. 🛣️ ROAD-EDGE DOWNCAST SENSOR (Sensor Ujung Aspal Kiri & Kanan)
		-- Memeriksa apakah aspal masih ada di kiri/kanan pada jarak 6, 10, 14, 18 studs.
		-- Jika raycast menyentuh rumput (Grass), tebing, void, atau bukan jalan:
		-- Berarti posisi tersebut sudah berada di luar batas jalan!
		local checkOffsets = {6, 10, 14, 18}
		for _, off in ipairs(checkOffsets) do
			-- Cek tepi aspal kiri
			local probeL = carPos - rightVec * off + Vector3.new(0, 5, 0)
			local downL = workspace:Raycast(probeL, Vector3.new(0, -20, 0), rayParams)
			if not downL or downL.Position.Y < (carPos.Y - 4.5) or isBarrierPart(downL.Instance) or downL.Instance.Material == Enum.Material.Grass then
				hasLeftBarrier = true
				if off < distL then
					distL = off
				end
			end

			-- Cek tepi aspal kanan
			local probeR = carPos + rightVec * off + Vector3.new(0, 5, 0)
			local downR = workspace:Raycast(probeR, Vector3.new(0, -20, 0), rayParams)
			if not downR or downR.Position.Y < (carPos.Y - 4.5) or isBarrierPart(downR.Instance) or downR.Instance.Material == Enum.Material.Grass then
				hasRightBarrier = true
				if off < distR then
					distR = off
				end
			end
		end

		return hasLeftBarrier, hasRightBarrier, distL, distR
	end

	------------------------------------------------
	-- 🛣️ WAYPOINTS RESMI HIGHWAY & ROAD DIRECTION TRACKER
	------------------------------------------------
	------------------------------------------------
	-- 🛣️ FULL HIGHWAY CORRIDOR DUAL-LANE TRACK ENGINE (ANTI-OUT-OF-BOUNDS)
	------------------------------------------------
	-- Powered by 3,462 synchronized left & right lane boundaries
	-- Covers the complete 95,000-stud closed-loop highway circuit
	local Corridor = _G.HipHub_GhostDriver_Corridor or {}
	local cachedCorridorIdx = nil

	local function getCorridorRoadInfo(pos)
		local n = #Corridor
		if n == 0 then
			return pos, Vector3.new(0, 0, -1), 34.0, 1
		end

		-- 1. Initial 3D Search or Recovery
		if not cachedCorridorIdx then
			local bestDistSq = math.huge
			local bestIdx = 1
			for idx = 1, n, 4 do
				local pt = Corridor[idx]
				local dx = pos.X - pt[1]
				local dy = (pos.Y - pt[2]) * 1.5
				local dz = pos.Z - pt[3]
				local dSq = dx * dx + dy * dy + dz * dz
				if dSq < bestDistSq then
					bestDistSq = dSq
					bestIdx = idx
				end
			end
			local fineStart = math.max(1, bestIdx - 8)
			local fineEnd = math.min(n, bestIdx + 8)
			for idx = fineStart, fineEnd do
				local pt = Corridor[idx]
				local dx = pos.X - pt[1]
				local dy = (pos.Y - pt[2]) * 1.5
				local dz = pos.Z - pt[3]
				local dSq = dx * dx + dy * dy + dz * dz
				if dSq < bestDistSq then
					bestDistSq = dSq
					bestIdx = idx
				end
			end
			cachedCorridorIdx = bestIdx
		end

		-- 2. Monotonic Forward Search (Prevents Backward Flipping & Flyover Crosstalk)
		local bestIdx = cachedCorridorIdx
		local bestDistSq = math.huge

		for offset = -1, 10 do
			local idx = ((cachedCorridorIdx - 1 + offset) % n) + 1
			local pt = Corridor[idx]
			local dx = pos.X - pt[1]
			local dy = (pos.Y - pt[2]) * 1.5
			local dz = pos.Z - pt[3]
			local dSq = dx * dx + dy * dy + dz * dz
			if dSq < bestDistSq then
				bestDistSq = dSq
				bestIdx = idx
			end
		end

		-- Fallback global search if teleported or drifted > 250 studs away
		if bestDistSq > 62500 then
			cachedCorridorIdx = nil
			return getCorridorRoadInfo(pos)
		end

		cachedCorridorIdx = bestIdx

		local pA = Corridor[bestIdx]
		local nextIdx = (bestIdx % n) + 1
		local pB = Corridor[nextIdx]

		local segX = pB[1] - pA[1]
		local segY = pB[2] - pA[2]
		local segZ = pB[3] - pA[3]
		local segLenHoriz = math.sqrt(segX * segX + segZ * segZ)
		local dirX = segLenHoriz > 0.001 and (segX / segLenHoriz) or 0
		local dirZ = segLenHoriz > 0.001 and (segZ / segLenHoriz) or -1
		local roadForward = Vector3.new(dirX, 0, dirZ)

		-- Segment projection
		local vx = pos.X - pA[1]
		local vz = pos.Z - pA[3]
		local proj = vx * dirX + vz * dirZ

		-- Advance to next waypoint as soon as segment is traversed
		if proj >= (segLenHoriz - 2.0) and segLenHoriz > 0.001 then
			cachedCorridorIdx = nextIdx
		end

		local t = math.clamp(proj, 0, segLenHoriz)
		local frac = segLenHoriz > 0.001 and (t / segLenHoriz) or 0

		local roadCenterX = pA[1] + dirX * t
		local roadCenterY = pA[2] + segY * frac
		local roadCenterZ = pA[3] + dirZ * t
		local roadWidth = pA[4] or 34.0

		return Vector3.new(roadCenterX, roadCenterY, roadCenterZ), roadForward, roadWidth, bestIdx
	end

	------------------------------------------------
	-- 🎯 DUAL-LANE (KIRI & TENGAH) OVERTAKE & NEAR-MISS ENGINE
	------------------------------------------------
	-- Strictly limited to 2 lanes:
	-- 1. Jalur Kiri   (-8.0 studs)
	-- 2. Jalur Tengah ( 0.0 studs)
	-- Eliminates cutting back into middle cars 100%!
	-- Persistent Lane Commitment: "LEFT", "CENTER", "RIGHT"
	-- Tidak akan pernah reset tiba-tiba atau potong balik ke tengah saat ada mobil di samping!
	local currentSlideOffset = 0.0
	local activeLaneName = "CENTER"

	local function calculateSmartTrafficDodge(carPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
		local tf = workspace:FindFirstChild("TrafficFolder")
		local obstacles = {}

		local halfWidth = (roadWidth or 34.0) * 0.5
		local minLateral = -halfWidth + 3.8
		local maxLateral = halfWidth - 3.8
		if minLateral > maxLateral then
			minLateral, maxLateral = -0.5, 0.5
		end

		-- Hitung jarak offset aman untuk 3 lajur: KIRI, TENGAH, KANAN
		local maxSafeOffset = math.min(8.0, math.max(4.0, halfWidth - 5.0))
		local laneOffsets = {
			LEFT = -maxSafeOffset,
			CENTER = 0.0,
			RIGHT = maxSafeOffset
		}

		-- 1. Kumpulkan semua mobil NPC dari TrafficFolder
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				if tCar:IsA("Model") then
					table.insert(obstacles, tCar:GetPivot().Position)
				end
			end
		end

		-- 2. Kumpulkan kendaraan lain (Police, AI racers, player lain)
		local myCar = getMyCar()
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar and obj ~= player.Character then
				if obj:FindFirstChild("DriveSeat") or obj.Name:find("Police") or obj.Name:find("AI") then
					table.insert(obstacles, obj:GetPivot().Position)
				end
			end
		end

		-- 3. Analisis ancaman di masing-masing dari 3 lajur (LEFT, CENTER, RIGHT)
		local threats = {
			LEFT = 999.0,
			CENTER = 999.0,
			RIGHT = 999.0
		}
		local beside = {
			LEFT = false,
			CENTER = false,
			RIGHT = false
		}

		-- Radius tabrakan lateral: 6.2 studs (mencakup bodi mobil kita + bodi NPC)
		local COLLISION_LATERAL_RADIUS = 6.2

		for _, obsPos in ipairs(obstacles) do
			local delta = obsPos - roadCenter
			local fDist = delta:Dot(forwardDir)
			local obsLateral = delta:Dot(rightVec)

			-- Pindai kendaraan dari -35 studs di belakang s/d 220 studs di depan (reaksi 1+ detik di 115 MPH)
			if fDist >= -35.0 and fDist <= 220.0 then
				for _, laneName in ipairs({"LEFT", "CENTER", "RIGHT"}) do
					local laneX = laneOffsets[laneName]
					local diff = math.abs(obsLateral - laneX)

					if diff < COLLISION_LATERAL_RADIUS then
						-- Sedang berdampingan atau mepet (passing range): -35 s/d +30 studs
						if fDist >= -35.0 and fDist <= 30.0 then
							beside[laneName] = true
						end
						-- Ancaman mobil di depan
						if fDist > 0 and fDist < threats[laneName] then
							threats[laneName] = fDist
						end
					end
				end
			end
		end

		-- 4. Logika Pemilihan Lajur Anti-Nabrak & Anti-Cutback
		if activeLaneName ~= "LEFT" and activeLaneName ~= "CENTER" and activeLaneName ~= "RIGHT" then
			activeLaneName = "CENTER"
		end

		local currentThreat = threats[activeLaneName]

		-- Jika lajur aktif kita terhalang mobil di depan (< 175 studs di 115 MPH):
		if currentThreat < 175.0 then
			-- Cari lajur alternatif yang paling aman dan lowong
			local bestLane = activeLaneName
			local maxClearDist = currentThreat

			local candidates = {}
			if activeLaneName == "CENTER" then
				-- Jika terhalang di tengah: cek KIRI dulu (prioritas Near-Miss), lalu KANAN
				candidates = {"LEFT", "RIGHT"}
			elseif activeLaneName == "LEFT" then
				candidates = {"CENTER", "RIGHT"}
			else
				candidates = {"CENTER", "LEFT"}
			end

			for _, cand in ipairs(candidates) do
				-- Syarat mutlak pindah lajur:
				-- 1. Tidak ada mobil di samping kita di lajur target (beside == false)
				-- 2. Jarak bebas di lajur target minimal 35 studs lebih jauh dari lajur kita sekarang
				-- 3. Jarak bebas di lajur target minimal 105 studs
				if not beside[cand] and threats[cand] > (currentThreat + 35.0) and threats[cand] > 105.0 then
					if threats[cand] > maxClearDist then
						maxClearDist = threats[cand]
						bestLane = cand
					end
				end
			end

			activeLaneName = bestLane
		else
			-- Lajur kita saat ini aman dan lowong (threat >= 175 studs).
			-- Jika kita sedang di LEFT atau RIGHT, kita HANYA kembali ke CENTER jika:
			-- 1. Jalur tengah benar-benar kosong jauh di depan (> 185 studs)
			-- 2. Tidak ada mobil yang sedang kita salip di samping tengah (beside.CENTER == false)
			if activeLaneName ~= "CENTER" then
				if not beside.CENTER and threats.CENTER > 185.0 then
					activeLaneName = "CENTER"
				end
			end
		end

		local targetSlideOffset = laneOffsets[activeLaneName] or 0.0
		if minLateral > maxLateral then
			minLateral, maxLateral = -0.5, 0.5
		end
		targetSlideOffset = math.clamp(targetSlideOffset, minLateral, maxLateral)

		-- 5. Dynamic High-Speed Steering: Responsif dan super cepat di kecepatan 115 MPH
		local minThreat = math.min(threats.LEFT, threats.CENTER, threats.RIGHT)
		local steerSpeed = 36.0
		if minThreat < 60.0 then
			steerSpeed = 52.0
		elseif minThreat < 110.0 then
			steerSpeed = 44.0
		end

		local diff = targetSlideOffset - currentSlideOffset
		local maxStep = steerSpeed * dt
		currentSlideOffset = currentSlideOffset + math.clamp(diff, -maxStep, maxStep)
		if minLateral > maxLateral then
			minLateral, maxLateral = -0.5, 0.5
		end
		currentSlideOffset = math.clamp(currentSlideOffset, minLateral, maxLateral)

		return currentSlideOffset
	end

	task.spawn(function()
		while true do
			task.wait(1.5)
			if Config.farm.autoRace and not isRacingNow then
				-- 1. Spawn mobil yang dipilih di tab vehicle
				local targetCar = (Config.vehicle and Config.vehicle.selectedCar) or "Wulfbrecht RZ7"
				local car, seat = getMyCar()
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

				if not car or not car.Name:find(targetCar) then
					if SpawnCarRemote then
						SpawnCarRemote:FireServer(targetCar)
						local spawnT0 = os.clock()
						while (os.clock() - spawnT0) < 4 do
							task.wait(0.3)
							car, seat = getMyCar()
							if car and seat then break end
						end
					end
				end

				car, seat = getMyCar()
				hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

				if car and seat and hum then
					isRacingNow = true
					pcall(function()
						-- 2. Naiki mobil lalu teleport ke buletan buat join race
						if not hum.Sit or hum.SeatPart ~= seat then
							seat:Sit(hum)
							task.wait(0.4)
						end

						local pad = workspace:FindFirstChild("RaceSystem") and workspace.RaceSystem:FindFirstChild("RacePad")
						if not pad and HudTeleport then
							HudTeleport:FireServer("HighwayRace")
							task.wait(2.0)
							pad = workspace:FindFirstChild("RaceSystem") and workspace.RaceSystem:FindFirstChild("RacePad")
						end

						if pad and car then
							car:PivotTo(pad.CFrame + Vector3.new(0, 3, 0))
							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
								seat.AssemblyAngularVelocity = Vector3.zero
							end
							task.wait(1.0)
						end

						-- 3. Race with AI
						local diff = Config.farm.raceDifficulty or "Hard"
						Remotes.RaceSoloPick:FireServer(diff)
						if UI and UI.Notify then
							UI.Notify("Auto Race", "Joining " .. diff .. " race! Highway Corridor Active...", 2, "info")
						end

						local started = false
						local finished = false
						local finishResult = nil

						local conn
						conn = Remotes.RaceEvent.OnClientEvent:Connect(function(action, data)
							if action == "StartRaceTimer" then
								started = true
							elseif action == "Finish" then
								finished = true
								finishResult = data
							elseif action == "Abort" then
								finished = true
							end
						end)

						local waitStart = os.clock()
						while not started and not finished and (os.clock() - waitStart) < 25 do
							local curP = car:GetPivot().Position
							if curP.Z < -1000 and curP.Y < 80 then
								car:PivotTo(CFrame.new(-3499.8, 63.4, curP.Z) * CFrame.Angles(0, math.rad(180), 0))
								if seat and seat:IsA("BasePart") then
									seat.AssemblyLinearVelocity = Vector3.zero
									seat.AssemblyAngularVelocity = Vector3.zero
								end
							end
							task.wait(0.2)
						end

						if started and not finished then
							-- 🏁 COUNTDOWN SELESAI: GAS MAJU MENGIKUTI CORRIDOR
							local curP = car:GetPivot().Position
							car:PivotTo(CFrame.new(-3499.8, 63.4, curP.Z) * CFrame.Angles(0, math.rad(180), 0))
							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
								seat.AssemblyAngularVelocity = Vector3.zero
							end
							currentSlideOffset = 0
							targetSlideOffset = 0
							task.wait(0.15)

							local cruiseMPH = Config.farm.raceSpeed or 70
							local targetStudsSec = cruiseMPH * 1.760

							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {player.Character, car}

							local heartbeatConn
							local lastTick = os.clock()
							local raceSpeedTimer = os.clock()

							heartbeatConn = RunService.Heartbeat:Connect(function()
								if not isRacingNow or finished or not seat or not car or not seat.Parent then return end

								local now = os.clock()
								local dt = math.clamp(now - lastTick, 0.005, 0.07)
								lastTick = now

								local currentPos = car:GetPivot().Position
								local roadCenter, forwardDir, roadWidth = getCorridorRoadInfo(currentPos)
								local rightVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X).Unit

								-- 1. Deteksi permukaan jalan tepat di bawah mobil & 12 studs di depan (mengikuti elevasi 3D flyover/bridge & slope)
								local probeOrigin = Vector3.new(currentPos.X, roadCenter.Y + 6, currentPos.Z)
								local downHit = workspace:Raycast(probeOrigin, Vector3.new(0, -20, 0), rayParams)
								local roadY = (downHit and math.abs(downHit.Position.Y - roadCenter.Y) < 7) and downHit.Position.Y or roadCenter.Y

								-- 2. Dapatkan offset lateral dari Near-Miss Overtake Engine (Jalur Kiri & Tengah Saja)
								local lateralOffset = 0
								if Config.farm.autoDodgeTraffic ~= false then
									lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
								end

								-- 3. Kunci posisi: roadCenter + forwardDir * stepDist + rightVec * lateralOffset
								-- Humanized Speed Modulation & Pedal Release (mencegah payout terhenti karena kecepatan flat)
								local baseCruiseMPH = Config.farm.raceSpeed or 70
								local timeInCycle = (now - raceSpeedTimer) % 5.5
								local targetMPH = baseCruiseMPH
								local throttleVal = 1.0

								if timeInCycle > 4.5 then
									local dipFrac = (timeInCycle - 4.5) / 1.0
									local dropAmount = math.sin(dipFrac * math.pi) * 12.0
									targetMPH = math.max(35.0, baseCruiseMPH - dropAmount)
									if dipFrac < 0.6 then
										throttleVal = 0.0
									else
										throttleVal = 0.7
									end
								else
									local microJitter = math.sin(now * 2.8) * 1.5
									targetMPH = baseCruiseMPH + microJitter
									throttleVal = 1.0
								end

								local targetStudsSec = targetMPH * 1.760
								local stepDist = targetStudsSec * dt
								local nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset

								local probeAhead = Vector3.new(nextPos.X + forwardDir.X * 12, roadCenter.Y + 6, nextPos.Z + forwardDir.Z * 12)
								local downHitAhead = workspace:Raycast(probeAhead, Vector3.new(0, -20, 0), rayParams)
								local roadYAhead = (downHitAhead and math.abs(downHitAhead.Position.Y - roadCenter.Y) < 7) and downHitAhead.Position.Y or roadY

								-- 4. Ketinggian ban menapak ke tanah (press 0.08 studs ke aspal agar suspensi aktif & ban dapat normal force)
								local rideH = getCarRideHeight(car)
								local targetY = roadY + rideH - 0.08
								local targetYAhead = roadYAhead + rideH - 0.08

								local currentPoint = Vector3.new(nextPos.X, targetY, nextPos.Z)
								local lookPoint = Vector3.new(nextPos.X + forwardDir.X * 12, targetYAhead, nextPos.Z + forwardDir.Z * 12)

								-- 5. Kunci orientasi mobil mengikuti kontur dan tanjakan/turunan jalan (pitch & yaw sempurna)
								local targetCF = CFrame.lookAt(currentPoint, lookPoint)
								car:PivotTo(targetCF)

								-- 6. Dorong dengan kecepatan penuh stabil + Downforce ke aspal + Gas Pedal On
								local vertCorrection = (targetY - currentPos.Y) * 10 - 4.0
								seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, vertCorrection, 0)
								seat.AssemblyAngularVelocity = Vector3.zero
								if seat:IsA("VehicleSeat") then
									seat.ThrottleFloat = throttleVal
									seat.Throttle = (throttleVal > 0.5) and 1 or 0
								end
							end)

							-- Tunggu sampai server konfirmasi event Finish (timeout 80 detik)
							local waitFinish = os.clock()
							while not finished and (os.clock() - waitFinish) < 80 do
								task.wait(0.1)
							end

							if heartbeatConn then
								heartbeatConn:Disconnect()
							end

							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
							end

							if finishResult and UI and UI.Notify then
								local earned = finishResult.reward or 0
								local place = finishResult.placement or "FINISHED"
								UI.Notify("Race Finished", place .. " | Cash: +$" .. tostring(earned), 4, "success")
							end
						end

						if conn then conn:Disconnect() end
					end)

					isRacingNow = false
					task.wait(Config.farm.raceDelay or 2.0)
				end
			end
		end
	end)

	------------------------------------------------
	-- 📋 AUTO QUEST CLAIMER
	------------------------------------------------
	task.spawn(function()
		while true do
			task.wait(Config.farm.claimInterval or 4)
			if Config.farm.autoClaimQuests and GetQuestsByScope and ClaimQuestByScope then
				pcall(function()
					for _, scope in ipairs({ "Daily", "Weekly" }) do
						local data = GetQuestsByScope:InvokeServer(scope)
						if data and data.Quests then
							for i, q in ipairs(data.Quests) do
								if not q.Claimed and q.Progress >= q.Max then
									local res = ClaimQuestByScope:InvokeServer(scope, i)
									if res and UI and UI.Notify then
										UI.Notify("Quest Claimed", "Claimed " .. scope .. " Quest " .. tostring(i) .. " (+$" .. tostring(q.Reward) .. ")", 3, "success")
									end
									task.wait(0.4)
								end
							end
						end
					end
				end)
			end
		end
	end)

	------------------------------------------------
	-- ⚡ AUTO SPEED & 24/7 ENDLESS HIGHWAY CRUISE (NEAR-MISS STREAK FARM)
	------------------------------------------------
	task.spawn(function()
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local lastTick = os.clock()
		local speedCycleTimer = os.clock()

		while true do
			task.wait(0.015)
			if Config.farm.autoSpeedFarm and not isRacingNow then
				local ok, loopErr = pcall(function()
					local car, seat = getMyCar()
					local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					if car and seat and hum and hum.Sit then
						local now = os.clock()
						local dt = math.clamp(now - lastTick, 0.005, 0.05)
						lastTick = now

						rayParams.FilterDescendantsInstances = {player.Character, car}

						local currentPos = car:GetPivot().Position

						-- 1. Ambil info koridor lintasan (centerline, arah forward, lebar jalan)
						local roadCenter, forwardDir, roadWidth = getCorridorRoadInfo(currentPos)
						local rightVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X).Unit

						-- 2. Deteksi permukaan jalan tepat di bawah mobil & 12 studs di depan (mengikuti elevasi 3D flyover/bridge & slope)
						local probeOrigin = Vector3.new(currentPos.X, roadCenter.Y + 6, currentPos.Z)
						local downHit = workspace:Raycast(probeOrigin, Vector3.new(0, -20, 0), rayParams)
						local roadY = (downHit and math.abs(downHit.Position.Y - roadCenter.Y) < 7) and downHit.Position.Y or roadCenter.Y

						-- 3. Hitung manuver nyalip mobil NPC untuk memicu Near Miss streak (Jalur Kiri & Tengah Saja)
						local lateralOffset = 0
						if Config.farm.autoDodgeTraffic ~= false then
							lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
						end

						-- 4. Kunci posisi: roadCenter + stepDist + lateralOffset (100% di dalam aspal)
						-- 🚗 30s DUAL-SPEED ALTERNATION ENGINE (90 MPH <-> 115 MPH)
						-- 30 detik pertama: 90 MPH (Cruise)
						-- 30 detik berikutnya: 115 MPH (Overdrive Boost)
						-- Siklus berulang otomatis 24/7 tanpa henti.
						-- Transisi dinamis & lift-off gas terbukti 100% mereset anti-cheat payout game!
						local cyclePeriod = 60.0 -- 30s + 30s
						local timeInCycle = (now - speedCycleTimer) % cyclePeriod

						local targetMPH = 90.0
						local throttleVal = 1.0

						if timeInCycle < 28.5 then
							-- [Fase 1: 90 MPH Cruise] (0 s/d 28.5s)
							local jitter = math.sin(now * 2.5) * 1.0
							targetMPH = 90.0 + jitter
							throttleVal = 1.0
						elseif timeInCycle < 30.0 then
							-- [Transisi 1: Akselerasi ke 115 MPH] (28.5 s/d 30.0s)
							local frac = (timeInCycle - 28.5) / 1.5
							targetMPH = 90.0 + (115.0 - 90.0) * frac
							throttleVal = 1.0
						elseif timeInCycle < 58.5 then
							-- [Fase 2: 115 MPH Overdrive Boost] (30.0 s/d 58.5s)
							local jitter = math.sin(now * 2.5) * 1.0
							targetMPH = 115.0 + jitter
							throttleVal = 1.0
						else
							-- [Transisi 2: Lepas Gas & Deselerasi ke 90 MPH] (58.5 s/d 60.0s)
							local frac = (timeInCycle - 58.5) / 1.5
							targetMPH = 115.0 - (115.0 - 90.0) * frac
							throttleVal = 0.0 -- Lepas pedal gas
						end

						local targetStudsSec = targetMPH * 1.760
						local stepDist = targetStudsSec * dt
						local nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset

						local probeAhead = Vector3.new(nextPos.X + forwardDir.X * 12, roadCenter.Y + 6, nextPos.Z + forwardDir.Z * 12)
						local downHitAhead = workspace:Raycast(probeAhead, Vector3.new(0, -20, 0), rayParams)
						local roadYAhead = (downHitAhead and math.abs(downHitAhead.Position.Y - roadCenter.Y) < 7) and downHitAhead.Position.Y or roadY

						-- 5. Hitung ketinggian ride height agar roda MENAPAK KE TANAH (press 0.08 studs ke aspal agar suspensi terkompresi & ban dapat grip normal force)
						local rideH = getCarRideHeight(car)
						local targetY = roadY + rideH - 0.08
						local targetYAhead = roadYAhead + rideH - 0.08

						local currentPoint = Vector3.new(nextPos.X, targetY, nextPos.Z)
						local lookPoint = Vector3.new(nextPos.X + forwardDir.X * 12, targetYAhead, nextPos.Z + forwardDir.Z * 12)

						-- 6. Kunci orientasi mobil mengikuti kontur dan tanjakan/turunan jalan (pitch & yaw sempurna)
						local targetCF = CFrame.lookAt(currentPoint, lookPoint)
						car:PivotTo(targetCF)

						-- 7. Dorong dengan kecepatan target dinamis + Downforce ke aspal + Gas Pedal Modulation
						local vertCorrection = (targetY - currentPos.Y) * 10 - 4.0
						seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, vertCorrection, 0)
						seat.AssemblyAngularVelocity = Vector3.zero
						if seat:IsA("VehicleSeat") then
							seat.ThrottleFloat = throttleVal
							seat.Throttle = (throttleVal > 0.5) and 1 or 0
						end
					else
						lastTick = os.clock()
					end
				end)
				if not ok then
					warn("[HipHub Auto Speed Farm Safe Catch]:", loopErr)
				end
			else
				lastTick = os.clock()
			end
		end
	end)

	------------------------------------------------
	-- 🚗 AUTO BUY CAR
	------------------------------------------------
	task.spawn(function()
		while true do
			task.wait(3)
			if Config.farm.autoBuyCar and PurchaseCarRemote then
				pcall(function()
					local targetName = Config.farm.targetCarToBuy
					if targetName and targetName ~= "" then
						local price = nil
						for _, c in ipairs(CarCatalog.Cars) do
							if c.Name == targetName then
								price = c.Price
								break
							end
						end

						if price and price > 0 then
							local currentCash = player.leaderstats and player.leaderstats:FindFirstChild("Cash") and player.leaderstats.Cash.Value or 0
							if currentCash >= price then
								local success, errCode = PurchaseCarRemote:InvokeServer(targetName)
								if success then
									Config.farm.autoBuyCar = false
									if Settings then Settings.Save() end
									if UI and UI.Notify then
										UI.Notify("Dealership", "Congratulations! Purchased " .. targetName .. " for $" .. tostring(price) .. "!", 6, "success")
									end
								end
							end
						end
					end
				end)
			end
		end
	end)

	_G.HipHub_GhostDriver_Farm = {
		GetMyCar = getMyCar,
		EnsureInCar = ensureInCar,
		IsRacing = function() return isRacingNow end
	}
end)

if not success then
	warn("[HipHub Ghost Driver Farm Error]:", err)
end


-- ==========================================
-- MODULE: vehicle.lua
-- ==========================================
-- HipHub Ghost Driver — Vehicle Modifications & Controls (Safe)
-- Handles Car Spawning, Smooth Speed Booster, Auto-Flip, and Seat Helpers

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer

	local Config = _G.HipHubConfig or { vehicle = {} }
	local UI = _G.HipHubUI

	local SpawnCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("SpawnCarEvent", 15)

	local function getMyCar()
		if not player.Character then return nil end
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart and hum.SeatPart.Parent then
			return hum.SeatPart.Parent, hum.SeatPart
		end

		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and (child:GetAttribute("OwnerUserId") == player.UserId or child.Name:find(player.Name)) then
				local seat = child:FindFirstChild("DriveSeat")
				if seat then
					return child, seat
				end
			end
		end
		return nil, nil
	end

	------------------------------------------------
	-- SPAWN CAR
	------------------------------------------------
	local function spawnCar(carName)
		if not SpawnCarRemote then return end
		SpawnCarRemote:FireServer(carName)
		if UI and UI.Notify then
			UI.Notify("Vehicle Spawner", "Requested spawn for " .. tostring(carName), 3, "info")
		end

		task.delay(1.5, function()
			local car, seat = getMyCar()
			if car and seat and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					seat:Sit(hum)
				end
			end
		end)
	end

	------------------------------------------------
	-- AUTO FLIP / UNFLIP
	------------------------------------------------
	local function unflipCar()
		local car, seat = getMyCar()
		if car and seat then
			local currentPivot = car:GetPivot()
			local upVector = currentPivot.UpVector
			local pos = currentPivot.Position
			if upVector.Y < 0.3 then
				car:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(currentPivot.Rotation.Y), 0))
				if seat:IsA("BasePart") then
					seat.AssemblyAngularVelocity = Vector3.zero
					seat.AssemblyLinearVelocity = Vector3.zero
				end
				if UI and UI.Notify then
					UI.Notify("Vehicle", "Car successfully unflipped!", 2, "success")
				end
			end
		end
	end

	task.spawn(function()
		while true do
			task.wait(1.5)
			if Config.vehicle.autoFlip then
				pcall(unflipCar)
			end
		end
	end)

	------------------------------------------------
	-- SAFE SPEED BOOSTER LOOP
	------------------------------------------------
	RunService.Heartbeat:Connect(function()
		if Config.vehicle.speedBoost then
			local car, seat = getMyCar()
			if seat and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Sit then
				local mult = math.clamp(Config.vehicle.speedMultiplier or 1.5, 1.0, 3.5)
				local currentVel = seat.AssemblyLinearVelocity
				local currentSpeedMPH = currentVel.Magnitude * 0.56818
				if currentSpeedMPH < 380 and seat.Throttle and seat.Throttle > 0 then
					seat.AssemblyLinearVelocity = currentVel + (seat.CFrame.LookVector * (mult * 6.0))
				end
			end
		end
	end)

	_G.HipHub_GhostDriver_Vehicle = {
		SpawnCar = spawnCar,
		Unflip = unflipCar,
		GetMyCar = getMyCar
	}
end)

if not success then
	warn("[HipHub Ghost Driver Vehicle Error]:", err)
end


-- ==========================================
-- MODULE: teleport.lua
-- ==========================================
-- HipHub Ghost Driver — Fast Teleport System
-- Handles Map Teleports, Car Teleports, and Destination Shortcuts

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	local UI = _G.HipHubUI
	local HudTeleport = ReplicatedStorage:WaitForChild("HudTeleport", 15)

	local function teleportTo(destName)
		if not HudTeleport then return end
		HudTeleport:FireServer(destName)
		if UI and UI.Notify then
			UI.Notify("Teleport", "Teleporting to " .. destName .. "...", 2, "info")
		end
	end

	local function teleportToCar()
		local car = nil
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and (child:GetAttribute("OwnerUserId") == player.UserId or child.Name:find(player.Name)) then
				local seat = child:FindFirstChild("DriveSeat")
				if seat then
					car = child
					break
				end
			end
		end

		if car and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local seat = car:FindFirstChild("DriveSeat")
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if seat and hum then
				seat:Sit(hum)
			else
				player.Character.HumanoidRootPart.CFrame = car:GetPivot() + Vector3.new(0, 4, 0)
			end
			if UI and UI.Notify then
				UI.Notify("Teleport", "Teleported to your vehicle!", 2, "success")
			end
		else
			if UI and UI.Notify then
				UI.Notify("Teleport", "Vehicle not found in workspace. Spawn one first!", 3, "warn")
			end
		end
	end

	_G.HipHub_GhostDriver_Teleport = {
		TeleportTo = teleportTo,
		TeleportToCar = teleportToCar
	}
end)

if not success then
	warn("[HipHub Ghost Driver Teleport Error]:", err)
end


-- ==========================================
-- MODULE: main.lua
-- ==========================================
-- HipHub Ghost Driver — Main Controller & UI Binding
-- Populates all Dashboard, Auto Farm, Vehicle, Dealership, and Teleport tabs with live controls

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer

	local UI = _G.HipHubUI
	if not UI then return end

	local Settings = _G.HipHub_GhostDriver_Settings
	local Config = _G.HipHubConfig or { farm = {}, vehicle = {}, settings = {} }
	local Farm = _G.HipHub_GhostDriver_Farm
	local Vehicle = _G.HipHub_GhostDriver_Vehicle
	local Teleport = _G.HipHub_GhostDriver_Teleport
	local ZeroLag = _G.HipHub_GhostDriver_ZeroLag

	local CarCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Menu"):WaitForChild("CarCatalog"))
	local PurchaseCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("PurchaseCar", 15)

	------------------------------------------------
	-- WINDOW DRAGGING & CONTROLS
	------------------------------------------------
	local mainFrame = UI.mainFrame
	local topBar = UI.topBar
	local dragging, dragStart, startPos
	local isMinimized = false
	local origSize = mainFrame.Size

	topBar.InputBegan:Connect(function(input)
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

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
			UI.SyncShadow()
		end
	end)

	UI.closeButton.MouseButton1Click:Connect(function()
		UI.gui.Enabled = false
		if UI.shadowFrame then UI.shadowFrame.Visible = false end
	end)

	UI.minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			mainFrame.Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 42)
			UI.contentArea.Visible = false
			UI.sidebar.Visible = false
		else
			mainFrame.Size = origSize
			UI.contentArea.Visible = true
			UI.sidebar.Visible = true
		end
		UI.SyncShadow()
	end)

	-- Keybind toggle (RightControl or Insert)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
			UI.gui.Enabled = not UI.gui.Enabled
			if UI.shadowFrame then UI.shadowFrame.Visible = UI.gui.Enabled end
		end
	end)

	------------------------------------------------
	-- ANTI-AFK & ACTIVITY HEARTBEAT (BAC-SAFE)
	------------------------------------------------
	-- Safely neutralise Roblox 20-minute client idle kick natively (Zero Network Packets / Zero VirtualInput)
	pcall(function()
		local getconns = getconnections or get_signal_cons
		if getconns then
			for _, conn in ipairs(getconns(player.Idled)) do
				if conn.Disable then
					conn:Disable()
				elseif conn.Disconnect then
					conn:Disconnect()
				end
			end
		end
	end)

	------------------------------------------------
	-- 📊 TAB 1: DASHBOARD
	------------------------------------------------
	local secStats = UI.AddSection("Dashboard", "Player & Vehicle Status")
	local statCash = UI.AddStatsCard(secStats, "Cash Balance", "$ " .. tostring(player.leaderstats and player.leaderstats.Cash.Value or 0))
	local statLevel = UI.AddStatsCard(secStats, "Level & Rank", "Level " .. tostring(player.leaderstats and player.leaderstats.Level.Value or 1))
	local statSpeed = UI.AddStatsCard(secStats, "Speed", "0 MPH")
	local statCar = UI.AddStatsCard(secStats, "Current Car", "None")

	-- Real-time stats updater
	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(function()
				if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash") then
					statCash.Update("$ " .. tostring(player.leaderstats.Cash.Value))
				end
				if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
					local rank = player.leaderstats:FindFirstChild("Rank") and player.leaderstats.Rank.Value or "ROOKIE"
					statLevel.Update("Lvl " .. tostring(player.leaderstats.Level.Value) .. " (" .. rank .. ")")
				end

				local car, seat = Farm and Farm.GetMyCar()
				if car and seat then
					statCar.Update(car.Name:gsub(player.Name .. "_", ""))
					local mph = math.floor(seat.AssemblyLinearVelocity.Magnitude * 0.56818)
					statSpeed.Update(tostring(mph) .. " MPH")
				else
					statCar.Update("No Vehicle Active")
					statSpeed.Update("0 MPH")
				end
			end)
		end
	end)

	local secQuick = UI.AddSection("Dashboard", "Quick Actions")
	UI.AddButton(secQuick, "Teleport to Highway Race", "Instant shortcut to race pad", "Teleport", function()
		if Teleport then Teleport.TeleportTo("HighwayRace") end
	end)
	UI.AddButton(secQuick, "Sit In Car", "Immediately board your active vehicle", "Enter Seat", function()
		if Farm then Farm.EnsureInCar() end
	end)
	UI.AddToggle(secQuick, "Zero Lag Mode (FPS Boost)", "Extreme FPS boost for Redfinger (removes shadows, rain & effects)", Config.settings.zeroLag or false, function(v)
		Config.settings.zeroLag = v
		if ZeroLag then ZeroLag.SetEnabled(v) end
		if Settings then Settings.Save() end
	end)

	------------------------------------------------
	-- 🏁 TAB 2: AUTO FARM
	------------------------------------------------
	-- 🎯 TARGET EARNING & SECURITY DISCONNECT
	-- Menghitung target berdasarkan total saldo uang di akhir (misal awal 2M + target farm 3M = input 5M)
	local function formatMillion(cashAmount)
		local millions = cashAmount / 1000000
		return string.format("$ %.2f M", millions)
	end

	local function formatMoney(n)
		local formatted = tostring(math.floor(math.max(0, n)))
		local k
		while true do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
			if k == 0 then break end
		end
		return "$" .. formatted
	end

	local secTarget = UI.AddSection("Auto Farm", "🎯 Target Earning & Security Disconnect")
	local cardCurrent = UI.AddStatsCard(secTarget, "Current Balance", "$ 0.00 M")
	local cardTarget = UI.AddStatsCard(secTarget, "Target Goal", "$ " .. tostring(Config.farm.targetEarnM or 5) .. ".00 M")
	local cardRemaining = UI.AddStatsCard(secTarget, "Remaining Needed", "$ 0.00 M")
	local cardIncomePerHour = UI.AddStatsCard(secTarget, "Est. Income / Hour", "$ 0 / hr")
	local cardGainPerTick = UI.AddStatsCard(secTarget, "Cash / Tick (~2s)", "+$ 0")
	local cardTimeToGoal = UI.AddStatsCard(secTarget, "Est. Time to Goal", "--")

	local toggleRace -- forward reference agar bisa dimatikan otomatis saat target tercapai

	local lastRecordedCash = nil
	local lastCashTimestamp = nil
	local smoothedHourlyRate = 0

	local function checkTargetEarn()
		local ls = player:FindFirstChild("leaderstats")
		local cashObj = ls and ls:FindFirstChild("Cash")
		local curCash = cashObj and cashObj.Value or 0
		local targetInCash = (Config.farm.targetEarnM or 5) * 1000000

		cardCurrent.Update(formatMillion(curCash))
		cardTarget.Update(formatMillion(targetInCash))

		local remaining = math.max(0, targetInCash - curCash)
		cardRemaining.Update(formatMillion(remaining))

		-- Real-time Income / Hour & Tick Tracker
		local now = os.clock()
		if lastRecordedCash and lastCashTimestamp then
			local dt = now - lastCashTimestamp
			if dt >= 0.5 then
				local delta = curCash - lastRecordedCash
				if delta > 0 then
					cardGainPerTick.Update("+" .. formatMoney(delta))
					local instantRate = (delta / dt) * 3600
					if smoothedHourlyRate <= 0 then
						smoothedHourlyRate = instantRate
					else
						smoothedHourlyRate = (smoothedHourlyRate * 0.65) + (instantRate * 0.35)
					end
				end
				lastRecordedCash = curCash
				lastCashTimestamp = now
			end
		else
			lastRecordedCash = curCash
			lastCashTimestamp = now
		end

		if smoothedHourlyRate > 0 then
			if smoothedHourlyRate >= 1000000 then
				cardIncomePerHour.Update(string.format("$ %.2f M / hr", smoothedHourlyRate / 1000000))
			else
				cardIncomePerHour.Update(formatMoney(smoothedHourlyRate) .. " / hr")
			end

			if remaining <= 0 then
				cardTimeToGoal.Update("Goal Reached!")
			else
				local secLeft = remaining / (smoothedHourlyRate / 3600)
				if secLeft > 86400 * 3 then
					cardTimeToGoal.Update("> 3 days")
				else
					local hrs = math.floor(secLeft / 3600)
					local mins = math.floor((secLeft % 3600) / 60)
					local secs = math.floor(secLeft % 60)
					if hrs > 0 then
						cardTimeToGoal.Update(string.format("%dh %dm", hrs, mins))
					elseif mins > 0 then
						cardTimeToGoal.Update(string.format("%dm %ds", mins, secs))
					else
						cardTimeToGoal.Update(string.format("%ds", secs))
					end
				end
			end
		else
			cardIncomePerHour.Update("$ 0 / hr")
			cardTimeToGoal.Update(remaining <= 0 and "Goal Reached!" or "--")
		end

		if Config.farm.targetEarn and Config.farm.targetEarnM then
			if curCash >= targetInCash then
				Config.farm.autoRace = false
				Config.farm.autoSpeedFarm = false
				if toggleRace then
					toggleRace.Set(false)
				end
				if Settings then Settings.Save() end

				-- Disconnect player dengan pesan sesuai permintaan:
				-- "Auto Farm Selesai, Uangmu Sekarang 'Total Uang'"
				local finalMsg = "Auto Farm Selesai, Uangmu Sekarang " .. formatMoney(curCash)
				task.delay(0.2, function()
					player:Kick(finalMsg)
				end)
			end
		end
	end

	-- Real-time Cash Balance Listener
	task.spawn(function()
		pcall(function()
			local ls = player:WaitForChild("leaderstats", 15)
			local cashObj = ls and ls:WaitForChild("Cash", 15)
			if cashObj then
				cashObj.Changed:Connect(function()
					checkTargetEarn()
				end)
				checkTargetEarn()
			end
		end)
	end)

	UI.AddToggle(secTarget, "Enable Target Earn Disconnect", "Disconnects player once target total cash is achieved", Config.farm.targetEarn or false, function(v)
		Config.farm.targetEarn = v
		if Settings then Settings.Save() end
		checkTargetEarn()
	end)

	UI.AddTextBox(secTarget, "Target Earn Amount (M)", "Input total target in Millions (M) — e.g. 5 for $5M", tostring(Config.farm.targetEarnM or 5), "e.g. 5", function(text)
		local cleanText = text:gsub("[^%d%.]", "")
		local num = tonumber(cleanText)
		if num and num > 0 then
			Config.farm.targetEarnM = num
			if Settings then Settings.Save() end
			checkTargetEarn()
		end
	end)

	------------------------------------------------
	-- 🛡️ ANTI PLAYER JOINED (AUTO DISCONNECT)
	------------------------------------------------
	local function checkOtherPlayers()
		if not Config.settings.antiPlayerJoined then return end
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				player:Kick("Anti Player Joined: Another player detected in server (" .. otherPlayer.Name .. ")! Disconnected for safety.")
				return true
			end
		end
		return false
	end

	Players.PlayerAdded:Connect(function(otherPlayer)
		if Config.settings.antiPlayerJoined and otherPlayer ~= player then
			player:Kick("Anti Player Joined: " .. otherPlayer.Name .. " joined the world! Disconnected for safety.")
		end
	end)

	UI.AddToggle(secTarget, "Anti Player Joined", "Disconnects immediately if another player enters your world", Config.settings.antiPlayerJoined or false, function(v)
		Config.settings.antiPlayerJoined = v
		if Settings then Settings.Save() end
		if v then
			checkOtherPlayers()
		end
	end)

	local secRace = UI.AddSection("Auto Farm", "Auto Race Automation")
	toggleRace = UI.AddToggle(secRace, "Auto Race", "Automatically joins & wins Highway Races 1st place", Config.farm.autoRace, function(v)
		Config.farm.autoRace = v
		if Settings then Settings.Save() end
	end)

	UI.AddToggle(secRace, "Auto Dodge NPC Traffic", "Actively swerves & changes lanes around traffic cars", Config.farm.autoDodgeTraffic ~= false, function(v)
		Config.farm.autoDodgeTraffic = v
		if Settings then Settings.Save() end
	end)

	UI.AddDropdown(secRace, "Race Difficulty", "Select race level (Hard = highest cash payout)", { "Hard", "Normal", "Easy" }, Config.farm.raceDifficulty or "Hard", function(v)
		Config.farm.raceDifficulty = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secRace, "Race Top Speed", "Maximum cruise speed during auto race (MPH)", 150, 400, Config.farm.raceSpeed or 250, " MPH", function(v)
		Config.farm.raceSpeed = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secRace, "Race Cooldown Delay", "Interval between race iterations", 1, 10, Config.farm.raceDelay or 2, "s", function(v)
		Config.farm.raceDelay = v
		if Settings then Settings.Save() end
	end)

	local secQuest = UI.AddSection("Auto Farm", "Daily & Weekly Quests")
	UI.AddToggle(secQuest, "Auto Claim Quests", "Auto claims Daily & Weekly quests as they complete", Config.farm.autoClaimQuests, function(v)
		Config.farm.autoClaimQuests = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secQuest, "Claim All Finished Quests", "Force instant claim of all eligible rewards", "Claim Now", function()
		pcall(function()
			local getQuests = ReplicatedStorage:FindFirstChild("GetQuestsByScope")
			local claim = ReplicatedStorage:FindFirstChild("ClaimQuestByScope")
			if getQuests and claim then
				local totalClaimed = 0
				for _, scope in ipairs({ "Daily", "Weekly" }) do
					local data = getQuests:InvokeServer(scope)
					if data and data.Quests then
						for i, q in ipairs(data.Quests) do
							if not q.Claimed and q.Progress >= q.Max then
								local res = claim:InvokeServer(scope, i)
								if res then
									totalClaimed = totalClaimed + (q.Reward or 0)
								end
							end
						end
					end
				end
				UI.Notify("Quests", "Claimed all rewards! Total Cash: +$" .. tostring(totalClaimed), 3, "success")
			end
		end)
	end)

	local secSpeedFarm = UI.AddSection("Auto Farm", "Highway Speed & Distance Farm")
	UI.AddToggle(secSpeedFarm, "Auto Speed Farm", "Maintains high velocity to grind near-misses and mileage", Config.farm.autoSpeedFarm, function(v)
		Config.farm.autoSpeedFarm = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secSpeedFarm, "Target Speed", "Set cruise control speed for highway driving", 50, 200, Config.farm.targetSpeed or 70, " MPH", function(v)
		Config.farm.targetSpeed = v
		if Settings then Settings.Save() end
	end)

	------------------------------------------------
	-- 🏎️ TAB 3: VEHICLE MODS
	------------------------------------------------
	local secSpawn = UI.AddSection("Vehicle", "Vehicle Spawner")
	local ownedCars = { "Wulfbrecht RZ7", "Kitsuni LX", "StarterCar" }
	pcall(function()
		local req = ReplicatedStorage.Remotes:FindFirstChild("RequestGarageData")
		if req then
			local data = req:InvokeServer()
			if data then
				local list = {}
				for name, _ in pairs(data) do
					table.insert(list, name)
				end
				if #list > 0 then ownedCars = list end
			end
		end
	end)

	local selectedCarToSpawn = Config.vehicle.selectedCar or ownedCars[1]
	UI.AddDropdown(secSpawn, "Select Vehicle", "Choose vehicle from your garage", ownedCars, selectedCarToSpawn, function(v)
		selectedCarToSpawn = v
		Config.vehicle.selectedCar = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secSpawn, "Spawn Vehicle", "Spawns selected car and puts you in driver seat", "Spawn Car", function()
		if Vehicle then Vehicle.SpawnCar(selectedCarToSpawn) end
	end)

	local secMods = UI.AddSection("Vehicle", "Performance & Safety")
	UI.AddToggle(secMods, "Speed Booster", "Increases forward acceleration while driving", Config.vehicle.speedBoost, function(v)
		Config.vehicle.speedBoost = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secMods, "Speed Multiplier", "Boost intensity multiplier", 1, 3, Config.vehicle.speedMultiplier or 1.3, "x", function(v)
		Config.vehicle.speedMultiplier = v
		if Settings then Settings.Save() end
	end)

	UI.AddToggle(secMods, "Auto Unflip", "Automatically re-orient car if flipped upside down", Config.vehicle.autoFlip, function(v)
		Config.vehicle.autoFlip = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secMods, "Unflip Car Now", "Instantly resets vehicle upright angle", "Unflip", function()
		if Vehicle then Vehicle.Unflip() end
	end)

	------------------------------------------------
	-- 🏪 TAB 4: DEALERSHIP & AUTO BUY
	------------------------------------------------
	local secCatalog = UI.AddSection("Dealership", "Auto Car Buyer")
	local catalogNames = {}
	local catalogMap = {}
	for _, c in ipairs(CarCatalog.Cars) do
		if not c.Hidden and c.Price > 0 then
			table.insert(catalogNames, c.Name)
			catalogMap[c.Name] = c
		end
	end

	local targetBuyCar = Config.farm.targetCarToBuy or catalogNames[1] or "Novis N55"
	local cardPrice = UI.AddStatsCard(secCatalog, "Target Car Price", "$ " .. tostring(catalogMap[targetBuyCar] and catalogMap[targetBuyCar].Price or 0))
	local cardTopSpeed = UI.AddStatsCard(secCatalog, "Top Speed", tostring(catalogMap[targetBuyCar] and catalogMap[targetBuyCar].TopSpeed or 0) .. " MPH")

	UI.AddDropdown(secCatalog, "Target Car to Buy", "Select car you want to purchase", catalogNames, targetBuyCar, function(v)
		targetBuyCar = v
		Config.farm.targetCarToBuy = v
		if Settings then Settings.Save() end
		if catalogMap[v] then
			cardPrice.Update("$ " .. tostring(catalogMap[v].Price))
			cardTopSpeed.Update(tostring(catalogMap[v].TopSpeed) .. " MPH")
		end
	end)

	UI.AddToggle(secCatalog, "Auto Buy When Affordable", "Buys vehicle instantly once your Cash is enough", Config.farm.autoBuyCar, function(v)
		Config.farm.autoBuyCar = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secCatalog, "Buy Selected Car Now", "Immediate manual purchase request", "Buy Now", function()
		pcall(function()
			if PurchaseCarRemote and targetBuyCar then
				local res, errCode = PurchaseCarRemote:InvokeServer(targetBuyCar)
				if res then
					UI.Notify("Dealership", "Successfully purchased " .. targetBuyCar .. "!", 4, "success")
				else
					UI.Notify("Dealership", "Purchase failed: " .. tostring(errCode or "Not enough cash"), 3, "warn")
				end
			end
		end)
	end)

	------------------------------------------------
	-- 📍 TAB 5: TELEPORTS
	------------------------------------------------
	local secTele = UI.AddSection("Teleports", "Fast Map Travel")
	UI.AddButton(secTele, "Highway Race", "Teleports to Highway Race Starting Area", "Teleport", function()
		if Teleport then Teleport.TeleportTo("HighwayRace") end
	end)

	UI.AddButton(secTele, "Dealership Showroom", "Teleports to Main Dealership", "Teleport", function()
		if Teleport then Teleport.TeleportTo("Dealership") end
	end)

	UI.AddButton(secTele, "Gas Station / AFK Area", "Teleports to Gas Station AFK hub", "Teleport", function()
		if Teleport then Teleport.TeleportTo("GasStation") end
	end)

	local secCarTele = UI.AddSection("Teleports", "Vehicle Teleport")
	UI.AddButton(secCarTele, "Teleport To My Car", "Teleports character directly into car seat", "Go to Car", function()
		if Teleport then Teleport.TeleportToCar() end
	end)

	------------------------------------------------
	-- ⚙️ TAB 6: SETTINGS
	------------------------------------------------
	local secSet = UI.AddSection("Settings", "General Configuration")
	UI.AddToggle(secSet, "Anti-AFK Protection", "Prevents Roblox 20-minute idle disconnection", Config.settings.antiAfk, function(v)
		Config.settings.antiAfk = v
		if Settings then Settings.Save() end
	end)

	UI.AddToggle(secSet, "Anti Player Joined", "Instantly disconnects if another player joins your world", Config.settings.antiPlayerJoined or false, function(v)
		Config.settings.antiPlayerJoined = v
		if Settings then Settings.Save() end
		if v then
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= player then
					player:Kick("Anti Player Joined: Another player detected in server (" .. otherPlayer.Name .. ")! Disconnected for safety.")
					break
				end
			end
		end
	end)

	local secLag = UI.AddSection("Settings", "⚡ Zero Lag & FPS Booster (Redfinger)")
	UI.AddToggle(secLag, "Zero Lag Mode", "Disables shadows, post-processing, rain, and heavy textures", Config.settings.zeroLag or false, function(v)
		Config.settings.zeroLag = v
		if ZeroLag then ZeroLag.SetEnabled(v) end
		if Settings then Settings.Save() end
	end)

	UI.AddToggle(secLag, "Potato Textures & Materials", "Converts heavy materials to smooth plastic for maximum FPS", Config.settings.potatoMaterials ~= false, function(v)
		Config.settings.potatoMaterials = v
		if Settings then Settings.Save() end
		if ZeroLag and ZeroLag.Active then
			ZeroLag.SetEnabled(true)
		end
	end)

	UI.AddDropdown(secLag, "FPS Cap (Battery / CPU Saver)", "Limits max frame rate to prevent overheating & throttling", { "30", "60", "120", "Unlimited" }, tostring(Config.settings.fpsCap or 60), function(v)
		local cap = (v == "Unlimited") and 0 or (tonumber(v) or 60)
		Config.settings.fpsCap = cap
		if Settings then Settings.Save() end
		if setfpscap then setfpscap(cap) end
	end)

	UI.AddLabel(secSet, "Toggle Menu Key: RightControl or Insert")

	UI.AddButton(secSet, "Rejoin Server", "Quickly reconnects to the current place", "Rejoin", function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, player)
	end)

	UI.AddButton(secSet, "Unload Script", "Closes and completely destroys script UI", "Unload", function()
		if UI.gui then UI.gui:Destroy() end
		if UI.shadowFrame then UI.shadowFrame:Destroy() end
	end)
end)

if not success then
	warn("[HipHub Ghost Driver Main Error]:", err)
end


