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
