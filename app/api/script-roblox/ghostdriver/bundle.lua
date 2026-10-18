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
		Notify = notify,
		SyncShadow = syncShadow
	}

	notify("HipHub Ghost Driver", "Ghost Driver module initialized successfully!", 3, "success")
end)

if not success then
	warn("[HipHub Ghost Driver UI Error]:", err)
end


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
			targetSpeed = 180,
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


-- HipHub Ghost Driver — Zero Lag & FPS Booster Engine (Redfinger & Low-End Devices)
-- Extreme performance enhancements: strips rain particles, post-processing, heavy textures, and disables shadows

local success, err = pcall(function()
	local Lighting = game:GetService("Lighting")
	local Config = _G.HipHubConfig or { settings = {} }
	local UI = _G.HipHubUI

	local ZeroLag = {
		Active = false,
		Connections = {}
	}

	-- 1. Optimasi Lighting & Post-Processing (Matikan Bayangan & Efek Berat)
	local function optimizeLighting()
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			Lighting.Brightness = 1

			for _, effect in ipairs(Lighting:GetChildren()) do
				if effect:IsA("PostProcessEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
					or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("Atmosphere") then
					effect.Enabled = false
				end
			end
		end)
	end

	-- 2. Bersihkan Rain Particles (Pembunuh FPS nomor 1 di Ghost Driver!)
	local function cleanRain()
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v.Name:find("Rain") or v.Name:find("Emitter") then
					if v:IsA("ParticleEmitter") then
						v.Enabled = false
					elseif v:IsA("BasePart") and v.Name:find("Rain") then
						v.Transparency = 1
					end
				end
			end
		end)
	end

	-- 3. Strip Part Material, Textures, and Shadows (Potato Mode)
	local function stripPart(obj)
		if not ZeroLag.Active then return end
		pcall(function()
			if obj:IsA("BasePart") then
				obj.CastShadow = false
				if Config.settings.potatoMaterials ~= false then
					obj.Material = Enum.Material.SmoothPlastic
					obj.Reflectance = 0
				end
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				if Config.settings.potatoMaterials ~= false then
					obj.Transparency = 1
				end
			elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
				obj.Enabled = false
			end
		end)
	end

	-- 4. Apply ke seluruh Workspace
	local function applyPotatoWorkspace()
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				stripPart(v)
			end
		end)
	end

	-- 5. Set FPS Cap & Quality Level
	local function applyRenderSettings()
		pcall(function()
			if setfpscap then
				local cap = Config.settings.fpsCap or 60
				setfpscap(cap)
			end
			if settings and settings().Rendering then
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end
		end)
	end

	-- 6. Enable / Disable Zero Lag Mode
	function ZeroLag.SetEnabled(state)
		ZeroLag.Active = state
		Config.settings.zeroLag = state
		if _G.HipHub_GhostDriver_Settings then
			_G.HipHub_GhostDriver_Settings.Save()
		end

		if state then
			optimizeLighting()
			cleanRain()
			applyPotatoWorkspace()
			applyRenderSettings()

			-- Listener untuk part/mobil baru spawn
			if not ZeroLag.Connections["DescendantAdded"] then
				ZeroLag.Connections["DescendantAdded"] = workspace.DescendantAdded:Connect(function(child)
					if ZeroLag.Active then
						task.defer(function()
							stripPart(child)
						end)
					end
				end)
			end

			-- Periodic loop untuk memastikan rain & lighting tetap mati saat teleport antar map
			if not ZeroLag.Connections["LoopRunning"] then
				ZeroLag.Connections["LoopRunning"] = true
				task.spawn(function()
					while ZeroLag.Active do
						cleanRain()
						optimizeLighting()
						task.wait(4)
					end
					ZeroLag.Connections["LoopRunning"] = nil
				end)
			end

			if UI and UI.Notify then
				UI.Notify("Zero Lag Mode", "FPS Boost activated! Shadows, rain & heavy textures stripped.", 3, "success")
			end
		else
			if ZeroLag.Connections["DescendantAdded"] then
				ZeroLag.Connections["DescendantAdded"]:Disconnect()
				ZeroLag.Connections["DescendantAdded"] = nil
			end
			pcall(function()
				Lighting.GlobalShadows = true
				for _, effect in ipairs(Lighting:GetChildren()) do
					if effect:IsA("PostProcessEffect") then
						effect.Enabled = true
					end
				end
			end)
			if UI and UI.Notify then
				UI.Notify("Zero Lag Mode", "Normal graphics restored.", 3, "info")
			end
		end
	end

	-- Auto-start jika di config sudah true
	if Config.settings.zeroLag then
		task.delay(1, function()
			ZeroLag.SetEnabled(true)
		end)
	end

	_G.HipHub_GhostDriver_ZeroLag = ZeroLag
end)

if not success then
	warn("[HipHub Ghost Driver ZeroLag Error]:", err)
end


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
			if not c then return end

			local TrafficImpact = c:FindFirstChild("TrafficImpactController")
			if TrafficImpact then
				local mod = require(TrafficImpact)
				if mod then
					mod.Push = function(self, ...) end
					mod.Update = function(self, ...) end
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
		end)
	end

	-- Immediately neutralize on script execution
	neutralizeGameCollisions()

	------------------------------------------------
	-- 🏁 AUTO RACE & HIGHWAY ENGINE (ANTI-FLYOVER & NOCLIP)
	------------------------------------------------
	local isRacingNow = false

	-- Universal Ghost Noclip & Traffic Neutralizer: runs on Stepped (before physics solver)
	-- Completely eliminates collisions with NPC traffic cars, AI racers, police, and players
	RunService.Stepped:Connect(function()
		neutralizeGameCollisions()

		local myCar = getMyCar()

		-- 1. Disable collision on all non-wheel parts of our own car (body, hood, seat, bumpers)
		if myCar then
			for _, p in ipairs(myCar:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "FL" and p.Name ~= "FR" and p.Name ~= "RL" and p.Name ~= "RR" and p.CanCollide then
					p.CanCollide = false
				end
			end
		end

		-- 2. Disable collision on all NPC Traffic vehicles in workspace.TrafficFolder
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
		if hit and hit.Position.Y <= 95 then
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
	-- 🚗 SENSOR DODGE PINTAR BERBASIS PEMBATAS JALAN
	------------------------------------------------
	-- Aturan Mutlak:
	-- 1. Jika di KIRI ada pembatas besi (distL < 16 studs)  -> DILARANG KERAS DODGE KE KIRI! WAJIB DODGE KE KANAN!
	-- 2. Jika di KANAN ada pembatas beton (distR < 16 studs)-> DILARANG KERAS DODGE KE KANAN! WAJIB DODGE KE KIRI!
	-- 3. Jika kedua sisi bebas                             -> Bebas pilih sisi yang lapang menjauhi rintangan!
	local currentDodgeDir = 0

	local function calculateBarrierAwareDodge(carPos, forwardDir, rightVec, rayParams, myCar)
		local tf = workspace:FindFirstChild("TrafficFolder")
		local obstacles = {}
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				if tCar:IsA("Model") then table.insert(obstacles, tCar) end
			end
		end

		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar and (obj:FindFirstChild("DriveSeat") or obj.Name:find("AI") or obj.Name:find("Police")) then
				table.insert(obstacles, obj)
			end
		end

		-- Cari rintangan terdekat di koridor depan kita
		local nearestObs = nil
		local nearestDist = 160
		local nearestLDist = 0

		for _, obs in ipairs(obstacles) do
			local oPivot = obs:GetPivot()
			local oPos = oPivot.Position
			local delta = oPos - carPos
			local fDist = delta:Dot(forwardDir)

			-- Koridor bahaya di depan mobil (8 sampai 150 studs)
			if fDist > 8 and fDist < nearestDist then
				local lDist = delta:Dot(rightVec)
				if math.abs(lDist) < 7.5 then
					nearestDist = fDist
					nearestLDist = lDist
					nearestObs = obs
				end
			end
		end

		local hasLeftBarrier, hasRightBarrier, distL, distR = detectBarriers(carPos, rightVec, forwardDir, rayParams)

		if not nearestObs then
			currentDodgeDir = 0
			return 0
		end

		local leftBlocked = hasLeftBarrier and (distL < 16.0)
		local rightBlocked = hasRightBarrier and (distR < 16.0)

		-- Ada rintangan di depan! Putuskan arah dodge berdasarkan posisi pembatas jalan:
		if leftBlocked and not rightBlocked then
			-- 🛑 Pagar besi ada di sebelah KIRI -> WAJIB DODGE KE KANAN (+1)! DILARANG KERAS KE KIRI!
			currentDodgeDir = 1
		elseif rightBlocked and not leftBlocked then
			-- 🛑 Pembatas beton ada di sebelah KANAN -> WAJIB DODGE KE KIRI (-1)! DILARANG KERAS KE KANAN!
			currentDodgeDir = -1
		elseif not leftBlocked and not rightBlocked then
			-- 🚗 Kedua sisi lapang -> Dodge menjauhi posisi rintangan
			currentDodgeDir = (nearestLDist >= 0) and -1 or 1
		else
			currentDodgeDir = 0
		end

		-- Hard safeguard jarak mepet:
		if currentDodgeDir > 0 and distR < 7.5 then
			currentDodgeDir = -1
		end
		if currentDodgeDir < 0 and distL < 7.5 then
			currentDodgeDir = 1
		end

		local urgency = math.clamp((150 - nearestDist) / 90, 0.5, 1.0)
		return currentDodgeDir * urgency * 0.18
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
							UI.Notify("Auto Race", "Joining " .. diff .. " race! Staying strictly on lower highway...", 2, "info")
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
							-- Selama countdown 3 detik, posisikan mobil stabil di tengah jalur (X = -3499.8, Y = 63.4)
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
							-- 🏁 COUNTDOWN 3 DETIK SELESAI!
							-- Posisikan mobil tepat di posisi awal tengah jalur (X = -3499.8, Y = 63.4) sebelum gas ke depan!
							local curP = car:GetPivot().Position
							car:PivotTo(CFrame.new(-3499.8, 63.4, curP.Z) * CFrame.Angles(0, math.rad(180), 0))
							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
								seat.AssemblyAngularVelocity = Vector3.zero
							end
							activeLane = 0
							task.wait(0.15)

							-- Waypoints Resmi Highway: Titik tengah jalan raya (dead center)
							local waypoints = {
								Vector3.new(-3499.8, 63.4, -1882.2), -- Posisi awal tengah jalur
								Vector3.new(-3499.8, 62.2, -2300.0), -- Jalan tol tengah
								Vector3.new(-3499.8, 62.2, -2900.0), -- Jalan tol tengah
								Vector3.new(-3499.8, 62.2, -3500.0), -- Menuju Checkpoint 6
								Vector3.new(-3505.0, 79.4, -3922.6), -- Checkpoint 6 tengah
								Vector3.new(-3516.0, 62.2, -4128.2), -- Checkpoint 7 tengah
								Vector3.new(-3530.0, 61.3, -4459.7), -- Checkpoint 8 tengah
								Vector3.new(-3555.0, 61.3, -4829.8), -- Checkpoint 9 tengah
								Vector3.new(-3595.0, 61.3, -5242.1), -- Checkpoint 10 tengah
								Vector3.new(-3660.0, 61.3, -5714.0), -- Checkpoint 11 tengah
								Vector3.new(-3760.0, 61.5, -6322.1), -- Checkpoint 12 tengah
								Vector3.new(-3820.0, 61.5, -6600.0), -- Tikungan highway 1
								Vector3.new(-4070.0, 61.5, -7606.0), -- Tikungan highway 2
								Vector3.new(-4389.0, 62.2, -8593.0), -- Tikungan highway 3
								Vector3.new(-4580.0, 62.2, -9070.0), -- Tikungan highway 3.5
								Vector3.new(-4776.0, 62.2, -9555.0), -- Tikungan highway 4 (Awal 56% Progress)
								Vector3.new(-4980.0, 62.2, -9950.0), -- Tikungan highway 4.3 (Halus Kurva 56%)
								Vector3.new(-5210.0, 62.2, -10350.0),-- Tikungan highway 4.6 (Halus Kurva 56%)
								Vector3.new(-5451.0, 62.2, -10750.0),-- Highway strip 5
								Vector3.new(-5850.0, 62.2, -11350.0),-- Highway strip 5.5
								Vector3.new(-6301.0, 62.2, -12000.0),-- Highway strip 6
								Vector3.new(-6780.0, 72.0, -12650.0),-- Highway strip 6.5
								Vector3.new(-7300.0, 81.6, -13300.0),-- Highway strip 7
								Vector3.new(-7820.0, 72.0, -13900.0),-- Highway strip 7.5
								Vector3.new(-8382.0, 62.2, -14500.0),-- Menuju garis finish
								Vector3.new(-9742.0, 62.2, -15626.9),-- RaceFinishLine
								Vector3.new(-10200.0, 62.2, -16000.0),-- Tembus garis finish +450 studs
								Vector3.new(-10800.0, 62.2, -16500.0) -- Tembus garis finish +1000 studs
							}

							local currentWpIndex = 1
							local cruiseMPH = math.clamp(Config.farm.raceSpeed or 340, 150, 480)
							local targetStudsSec = cruiseMPH * 1.760

							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {player.Character, car}

							-- Real-time road tracking & lane keeping loop with 3-Lane Smooth Dodge
							local heartbeatConn
							local smoothDodge = 0
							local smoothLateral = 0
							local lastTick = os.clock()

							heartbeatConn = RunService.Heartbeat:Connect(function()
								if not isRacingNow or finished or not seat or not car or not seat.Parent then return end

								local now = os.clock()
								local dt = math.clamp(now - lastTick, 0.005, 0.07)
								lastTick = now

								local currentPos = car:GetPivot().Position
								local targetPos = waypoints[currentWpIndex] or waypoints[#waypoints]
								local deltaTarget = targetPos - currentPos
								local distToTarget = Vector2.new(deltaTarget.X, deltaTarget.Z).Magnitude

								-- Arah pergerakan makro
								local macroDir
								if currentWpIndex >= #waypoints and distToTarget < 100 then
									macroDir = Vector3.new(-0.768, 0, -0.640).Unit
								else
									macroDir = Vector3.new(deltaTarget.X, 0, deltaTarget.Z).Unit
								end

								-- Maju ke checkpoint berikutnya kalau sudah dekat (<120 studs) atau sudah terlewati
								local isPassed = deltaTarget:Dot(macroDir) < -15
								if (distToTarget < 120 or isPassed) and currentWpIndex < #waypoints then
									currentWpIndex = currentWpIndex + 1
									targetPos = waypoints[currentWpIndex]
									deltaTarget = targetPos - currentPos
								end

								-- 1. Deteksi permukaan jalan tepat di bawah mobil
								local downHit = workspace:Raycast(currentPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
								local roadY = (downHit and downHit.Position.Y <= 95) and downHit.Position.Y or 62.5

								-- 2. Deteksi arah jalan di depan: probe lurus dulu, hanya probe sudut jika di depan melenceng
								local bestDir = macroDir
								local probeOrigin = currentPos + macroDir * 35 + Vector3.new(0, 10, 0)
								local hitAhead = workspace:Raycast(probeOrigin, Vector3.new(0, -45, 0), rayParams)
								if not (hitAhead and hitAhead.Position.Y <= 95) then
									local probeAngles = {8, -8, 16, -16}
									for _, deg in ipairs(probeAngles) do
										local testDir = (CFrame.Angles(0, math.rad(deg), 0) * macroDir).Unit
										local pHit = workspace:Raycast(currentPos + testDir * 35 + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
										if pHit and pHit.Position.Y <= 95 and not (pHit.Instance.Name:lower():find("wall") or pHit.Instance.Name:lower():find("guard") or pHit.Instance.Name:lower():find("rail")) then
											bestDir = testDir
											break
										end
									end
								end

								-- 3. Barrier-Aware Traffic Dodge & Lane Keeping
								local rightVec = Vector3.new(-bestDir.Z, 0, bestDir.X).Unit

								local targetDodge = 0
								if Config.farm.autoDodgeTraffic ~= false then
									targetDodge = calculateBarrierAwareDodge(currentPos, bestDir, rightVec, rayParams, car)
								end

								-- Deteksi pembatas jalan real-time (Samping 90°, Serong 45°, & Downcast Tepi Aspal)
								local _, _, distL, distR = detectBarriers(currentPos, rightVec, bestDir, rayParams)

								-- 🛡️ ACTIVE HIGHWAY CENTERING (Jaga Mobil Selalu di Koridor Aspal)
								local centeringForce = 0
								if distL < 16.0 then
									centeringForce = math.clamp((16.0 - distL) * 0.035, 0.04, 0.25)
								elseif distR < 16.0 then
									centeringForce = -math.clamp((16.0 - distR) * 0.035, 0.04, 0.25)
								end

								-- Transisi kemudi halus menggabungkan traffic dodge + highway centering
								smoothDodge = smoothDodge + (targetDodge + centeringForce - smoothDodge) * math.clamp(dt * 7.0, 0.06, 0.35)

								-- Emergency barrier safety clamp & active repulsion:
								-- Jika mendekati pagar besi di kiri (< 9.0 studs), dilarang keras belok kiri dan paksa stir ke kanan!
								-- Jika mendekati tembok beton di kanan (< 9.0 studs), dilarang keras belok kanan dan paksa stir ke kiri!
								if distL < 9.0 then
									local pushRight = math.clamp((9.0 - distL) * 0.05, 0.08, 0.28)
									smoothDodge = math.max(smoothDodge, pushRight)
								elseif distR < 9.0 then
									local pushLeft = -math.clamp((9.0 - distR) * 0.05, 0.08, 0.28)
									smoothDodge = math.min(smoothDodge, pushLeft)
								end

								local finalHeading = (bestDir + rightVec * smoothDodge).Unit

								-- 4. Kunci orientasi mobil & dorong maju framerate-independent (Anti-Lag Redfinger)
								local targetY = roadY + 2.0
								local stepDist = targetStudsSec * dt
								local nextPos = currentPos + finalHeading * stepDist

								-- 🛡️ HARD PHYSICAL CUSHION CLAMP (Anti-Nembus Pagar Besi & Tembok Beton)
								local _, _, nextDistL, nextDistR = detectBarriers(nextPos, rightVec, bestDir, rayParams)
								if nextDistL < 5.0 then
									nextPos = nextPos + rightVec * (5.0 - nextDistL)
								elseif nextDistR < 5.0 then
									nextPos = nextPos - rightVec * (5.0 - nextDistR)
								end

								local lookAtPos = nextPos + finalHeading * 10
								local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, targetY, nextPos.Z), Vector3.new(lookAtPos.X, targetY, lookAtPos.Z))
								local smoothCF = car:GetPivot():Lerp(targetCF, math.clamp(dt * 14.0, 0.18, 0.75))
								car:PivotTo(smoothCF)

								-- 5. Dorong dengan kecepatan penuh stabil mengikuti arah halus mobil + Gas Pedal On
								seat.AssemblyLinearVelocity = finalHeading * targetStudsSec + Vector3.new(0, (targetY - currentPos.Y) * 6, 0)
								seat.AssemblyAngularVelocity = Vector3.zero
								if seat:IsA("VehicleSeat") then
									seat.ThrottleFloat = 1.0
									seat.Throttle = 1
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
	-- ⚡ AUTO SPEED & COMBO HIGHWAY CRUISE (SMART TRAFFIC DODGE)
	------------------------------------------------
	task.spawn(function()
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local smoothDodge = 0
		local smoothLateral = 0
		local lastTick = os.clock()

		while true do
			task.wait(0.02)
			if Config.farm.autoSpeedFarm and not isRacingNow then
				local car, seat = getMyCar()
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if car and seat and hum and hum.Sit then
					local now = os.clock()
					local dt = math.clamp(now - lastTick, 0.005, 0.05)
					lastTick = now

					rayParams.FilterDescendantsInstances = {player.Character, car}

					local currentPos = car:GetPivot().Position
					local currentLook = seat.CFrame.LookVector
					local macroDir = Vector3.new(currentLook.X, 0, currentLook.Z).Unit
					local rightVec = Vector3.new(-macroDir.Z, 0, macroDir.X).Unit

					-- 1. Deteksi permukaan jalan tepat di bawah mobil
					local downHit = workspace:Raycast(currentPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
					local roadY = (downHit and downHit.Position.Y <= 95) and downHit.Position.Y or 62.5

					-- 2. Deteksi arah jalan ke depan (probe lurus dulu, hanya probe sudut jika di depan melenceng)
					local bestDir = macroDir
					local probeOrigin = currentPos + macroDir * 35 + Vector3.new(0, 10, 0)
					local hitAhead = workspace:Raycast(probeOrigin, Vector3.new(0, -45, 0), rayParams)
					if not (hitAhead and hitAhead.Position.Y <= 95) then
						local probeAngles = {8, -8, 16, -16}
						for _, deg in ipairs(probeAngles) do
							local testDir = (CFrame.Angles(0, math.rad(deg), 0) * macroDir).Unit
							local pHit = workspace:Raycast(currentPos + testDir * 35 + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
							if pHit and pHit.Position.Y <= 95 and not (pHit.Instance.Name:lower():find("wall") or pHit.Instance.Name:lower():find("guard") or pHit.Instance.Name:lower():find("rail")) then
								bestDir = testDir
								break
							end
						end
					end

					-- 3. Barrier-Aware Traffic Dodge & Lane Keeping
					local targetDodge = 0
					if Config.farm.autoDodgeTraffic ~= false then
						targetDodge = calculateBarrierAwareDodge(currentPos, bestDir, rightVec, rayParams, car)
					end

					-- Deteksi pembatas jalan real-time (Samping 90°, Serong 45°, & Downcast Tepi Aspal)
					local _, _, distL, distR = detectBarriers(currentPos, rightVec, bestDir, rayParams)

					-- 🛡️ ACTIVE HIGHWAY CENTERING (Jaga Mobil Selalu di Koridor Aspal)
					local centeringForce = 0
					if distL < 16.0 then
						centeringForce = math.clamp((16.0 - distL) * 0.035, 0.04, 0.25)
					elseif distR < 16.0 then
						centeringForce = -math.clamp((16.0 - distR) * 0.035, 0.04, 0.25)
					end

					-- Transisi kemudi halus menggabungkan traffic dodge + highway centering
					smoothDodge = smoothDodge + (targetDodge + centeringForce - smoothDodge) * math.clamp(dt * 7.0, 0.06, 0.35)

					-- Emergency barrier safety clamp & active repulsion:
					-- Jika mendekati pagar besi di kiri (< 9.0 studs), dilarang keras belok kiri dan paksa stir ke kanan!
					-- Jika mendekati tembok beton di kanan (< 9.0 studs), dilarang keras belok kanan dan paksa stir ke kiri!
					if distL < 9.0 then
						local pushRight = math.clamp((9.0 - distL) * 0.05, 0.08, 0.28)
						smoothDodge = math.max(smoothDodge, pushRight)
					elseif distR < 9.0 then
						local pushLeft = -math.clamp((9.0 - distR) * 0.05, 0.08, 0.28)
						smoothDodge = math.min(smoothDodge, pushLeft)
					end

					local finalHeading = (bestDir + rightVec * smoothDodge).Unit

					-- 4. Kunci orientasi mobil & dorong maju framerate-independent (Anti-Lag Redfinger)
					local targetY = roadY + 2.0
					local targetMPH = math.clamp(Config.farm.targetSpeed or 240, 50, 380)
					local targetStudsSec = targetMPH * 1.760
					local stepDist = targetStudsSec * dt
					local nextPos = currentPos + finalHeading * stepDist

					-- 🛡️ HARD PHYSICAL CUSHION CLAMP (Anti-Nembus Pagar Besi & Tembok Beton)
					local _, _, nextDistL, nextDistR = detectBarriers(nextPos, rightVec, bestDir, rayParams)
					if nextDistL < 5.0 then
						nextPos = nextPos + rightVec * (5.0 - nextDistL)
					elseif nextDistR < 5.0 then
						nextPos = nextPos - rightVec * (5.0 - nextDistR)
					end

					local lookAtPos = nextPos + finalHeading * 10
					local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, targetY, nextPos.Z), Vector3.new(lookAtPos.X, targetY, lookAtPos.Z))
					local smoothCF = car:GetPivot():Lerp(targetCF, math.clamp(dt * 14.0, 0.18, 0.75))
					car:PivotTo(smoothCF)

					-- 5. Dorong dengan kecepatan target konstan + Gas Pedal On
					seat.AssemblyLinearVelocity = finalHeading * targetStudsSec + Vector3.new(0, (targetY - currentPos.Y) * 6, 0)
					seat.AssemblyAngularVelocity = Vector3.zero
					if seat:IsA("VehicleSeat") then
						seat.ThrottleFloat = 1.0
						seat.Throttle = 1
					end
				else
					lastTick = os.clock()
					smoothDodge = 0
					smoothLateral = 0
				end
			else
				lastTick = os.clock()
				smoothDodge = 0
				smoothLateral = 0
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
	-- Safely neutralise Roblox 20-minute client idle kick without VirtualUser
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

	-- Keep-Alive Loop: Satisfies Ghost Driver's AC6 and Activity Bot Check remotes
	-- Completely undetectable because it mimics legit client InputHeartbeat
	task.spawn(function()
		while true do
			task.wait(4)
			if Config.settings.antiAfk ~= false then
				pcall(function()
					local ac6 = ReplicatedStorage:FindFirstChild("AC6Shared")
					if ac6 and ac6:FindFirstChild("Remotes") and ac6.Remotes:FindFirstChild("InputHeartbeat") then
						ac6.Remotes.InputHeartbeat:FireServer()
					end
				end)
				pcall(function()
					local remotes = require(ReplicatedStorage.Packages.Remotes)
					if remotes and remotes.InputHeartbeat then
						remotes.InputHeartbeat:FireServer()
					end
				end)
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
	-- 🎯 TARGET EARN & SESSION REVENUE TRACKER
	-- Menghitung MURNI uang masuk yang didapatkan selama sesi, bukan saldo total saat ini!
	local sessionEarnedCash = 0
	local lastRecordedCash = nil

	local function formatMillion(cashAmount)
		local millions = cashAmount / 1000000
		return string.format("$ %.2f M", millions)
	end

	local secTarget = UI.AddSection("Auto Farm", "🎯 Target Earn & Session Revenue")
	local cardEarned = UI.AddStatsCard(secTarget, "Session Earned (Uang Masuk)", "$ 0.00 M")
	local cardTarget = UI.AddStatsCard(secTarget, "Target Goal", "$ " .. tostring(Config.farm.targetEarnM or 5) .. ".00 M")

	local toggleRace -- forward reference agar bisa dimatikan otomatis saat target tercapai

	local function checkTargetEarn()
		if Config.farm.targetEarn and Config.farm.targetEarnM then
			local targetInCash = (Config.farm.targetEarnM or 5) * 1000000
			if sessionEarnedCash >= targetInCash then
				Config.farm.autoRace = false
				Config.farm.autoSpeedFarm = false
				if toggleRace then
					toggleRace.Set(false)
				end
				if Settings then Settings.Save() end

				if UI and UI.Notify then
					UI.Notify("🎯 Target Earn Reached!", "Earned " .. formatMillion(sessionEarnedCash) .. "! Auto Race stopped.", 6, "success")
				end
			end
		end
	end

	-- Listener Uang Masuk Murni (Gross Inflow)
	task.spawn(function()
		pcall(function()
			local ls = player:WaitForChild("leaderstats", 10)
			local cashObj = ls and ls:WaitForChild("Cash", 10)
			if cashObj then
				lastRecordedCash = cashObj.Value
				cashObj.Changed:Connect(function(newVal)
					if lastRecordedCash ~= nil then
						local delta = newVal - lastRecordedCash
						if delta > 0 then
							-- Uang masuk murni (dari race, quest, speed, dll.)
							sessionEarnedCash = sessionEarnedCash + delta
							cardEarned.Update(formatMillion(sessionEarnedCash))
							checkTargetEarn()
						end
					end
					lastRecordedCash = newVal
				end)
			end
		end)
	end)

	UI.AddToggle(secTarget, "Enable Target Earn Stop", "Automatically stops Auto Race once target revenue is reached", Config.farm.targetEarn or false, function(v)
		Config.farm.targetEarn = v
		if Settings then Settings.Save() end
		checkTargetEarn()
	end)

	UI.AddSlider(secTarget, "Target Earn Amount", "Set revenue goal in Millions (M)", 1, 100, Config.farm.targetEarnM or 5, " M", function(v)
		Config.farm.targetEarnM = v
		cardTarget.Update("$ " .. tostring(v) .. ".00 M")
		if Settings then Settings.Save() end
		checkTargetEarn()
	end)

	UI.AddButton(secTarget, "Reset Earned Counter", "Resets session revenue back to $ 0.00 M", "Reset Counter", function()
		sessionEarnedCash = 0
		cardEarned.Update("$ 0.00 M")
		if UI and UI.Notify then
			UI.Notify("Target Earn", "Session earned counter reset to $ 0.00 M", 3, "info")
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

	UI.AddSlider(secSpeedFarm, "Target Speed", "Set cruise control speed for highway driving", 100, 260, Config.farm.targetSpeed or 180, " MPH", function(v)
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


