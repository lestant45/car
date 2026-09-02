-- 🌐 HipHub — Liquid Glass Futuristic UI Base (Bus X Indonesia / BXI)
-- Place ID: 137806249434874 (Jawa Barat)
-- Pure UI Layout Base & Component Library
-- Theme: Glassmorphism with Cyber Neon Cyan-Emerald & Bus Transit Gold accents

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
	local HttpService = game:GetService("HttpService")

	player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- 🎨 DESIGN TOKENS
	------------------------------------------------
	local COLORS = {
		glassPrimary  = Color3.fromRGB(11, 15, 26),
		glassSurface  = Color3.fromRGB(16, 22, 38),
		glassCard     = Color3.fromRGB(22, 30, 52),
		glassHover    = Color3.fromRGB(30, 42, 70),
		glassActive   = Color3.fromRGB(38, 52, 86),
		accentCyan    = Color3.fromRGB(0, 220, 255),
		accentEmerald = Color3.fromRGB(0, 230, 140),
		accentGold    = Color3.fromRGB(255, 185, 45),
		accentViolet  = Color3.fromRGB(140, 95, 255),
		accentGlow    = Color3.fromRGB(0, 200, 255),
		accentMuted   = Color3.fromRGB(45, 60, 100),
		toggleOn      = Color3.fromRGB(0, 215, 255),
		toggleOff     = Color3.fromRGB(36, 44, 70),
		textPrimary   = Color3.fromRGB(235, 245, 255),
		textSecondary = Color3.fromRGB(145, 165, 200),
		textMuted     = Color3.fromRGB(90, 105, 140),
		textWhite     = Color3.fromRGB(255, 255, 255),
		borderGlass   = Color3.fromRGB(48, 65, 110),
		borderGlow    = Color3.fromRGB(0, 200, 255),
		shadow        = Color3.fromRGB(2, 4, 10),
		successGreen  = Color3.fromRGB(46, 204, 113),
		warningYellow = Color3.fromRGB(241, 196, 15),
		dangerRed     = Color3.fromRGB(231, 76, 60)
	}

	local TRANSPARENCY = {
		glassMain    = 0.04,
		glassSurface = 0.08,
		glassCard    = 0.10,
		glassSidebar = 0.06,
		glassTopBar  = 0.04,
		border       = 0.50,
		borderGlow   = 0.30,
	}

	local CORNER = {
		large  = UDim.new(0, 14),
		medium = UDim.new(0, 10),
		small  = UDim.new(0, 6),
		pill   = UDim.new(1, 0),
	}

	------------------------------------------------
	-- 🧹 CLEANUP EXISTING INSTANCES
	------------------------------------------------
	local oldGui = player.PlayerGui:FindFirstChild("HipHub_BXI") or player.PlayerGui:FindFirstChild("HipHub")
	if oldGui then
		oldGui:Destroy()
	end

	------------------------------------------------
	-- 🛠️ HELPER FUNCTIONS
	------------------------------------------------
	local function applyGlass(frame, opts)
		opts = opts or {}
		frame.BackgroundColor3 = opts.color or COLORS.glassSurface
		frame.BackgroundTransparency = opts.transparency or TRANSPARENCY.glassSurface
		frame.BorderSizePixel = 0

		local corner = Instance.new("UICorner")
		corner.CornerRadius = opts.corner or CORNER.medium
		corner.Parent = frame

		if opts.stroke ~= false then
			local stroke = Instance.new("UIStroke")
			stroke.Color = opts.strokeColor or COLORS.borderGlass
			stroke.Transparency = opts.strokeTransparency or TRANSPARENCY.border
			stroke.Thickness = opts.strokeThickness or 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = frame
		end
	end

	local function addGradient(instance, col1, col2, rot)
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, col1),
			ColorSequenceKeypoint.new(1, col2)
		})
		grad.Rotation = rot or 90
		grad.Parent = instance
		return grad
	end

	------------------------------------------------
	-- 🖥️ SCREEN GUI SETUP
	------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_BXI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
			gui.Parent = game:GetService("CoreGui")
		elseif gethui then
			gui.Parent = gethui()
		else
			gui.Parent = player:WaitForChild("PlayerGui")
		end
	end)

	if not gui.Parent then
		gui.Parent = player:WaitForChild("PlayerGui")
	end

	------------------------------------------------
	-- 👥 SHADOW GLOW FRAME
	------------------------------------------------
	local shadowFrame = Instance.new("Frame")
	shadowFrame.Name = "ShadowFrame"
	shadowFrame.Size = UDim2.new(0, 680, 0, 470)
	shadowFrame.Position = UDim2.new(0.5, -340, 0.5, -235)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.4
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 1
	shadowFrame.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 18)
	shadowCorner.Parent = shadowFrame

	local shadowStroke = Instance.new("UIStroke")
	shadowStroke.Color = COLORS.borderGlow
	shadowStroke.Transparency = 0.8
	shadowStroke.Thickness = 6
	shadowStroke.Parent = shadowFrame

	------------------------------------------------
	-- 📦 MAIN CONTAINER FRAME
	------------------------------------------------
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 670, 0, 460)
	mainFrame.Position = UDim2.new(0.5, -335, 0.5, -230)
	mainFrame.ClipsDescendants = true
	mainFrame.ZIndex = 2
	applyGlass(mainFrame, {
		color = COLORS.glassPrimary,
		transparency = TRANSPARENCY.glassMain,
		corner = CORNER.large,
		strokeColor = COLORS.borderGlass,
		strokeTransparency = 0.4,
		strokeThickness = 1.2
	})
	mainFrame.Parent = gui

	local function syncShadow()
		shadowFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 5,
			mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 5
		)
		shadowFrame.Size = UDim2.new(
			mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 10,
			mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 10
		)
		shadowFrame.Visible = mainFrame.Visible
	end

	------------------------------------------------
	-- 🔝 TOP BAR (HEADER)
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 44)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.ZIndex = 3
	applyGlass(topBar, {
		color = COLORS.glassSurface,
		transparency = TRANSPARENCY.glassTopBar,
		corner = CORNER.large,
		stroke = false
	})
	topBar.Parent = mainFrame

	-- Top decorative glow line
	local topGlow = Instance.new("Frame")
	topGlow.Size = UDim2.new(1, 0, 0, 2)
	topGlow.Position = UDim2.new(0, 1, 1, -2)
	topGlow.BorderSizePixel = 0
	topGlow.ZIndex = 4
	topGlow.Parent = topBar
	addGradient(topGlow, COLORS.accentCyan, COLORS.accentEmerald, 0)

	-- Logo / Title Text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0, 260, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🚌 <font color=\"#00E68C\"><b>HipHub</b></font> <font color=\"#00DCFF\">BXI</font> <font color=\"#91A5C8\"><font size=\"11\">v2.0</font></font>"
	titleLabel.RichText = true
	titleLabel.TextColor3 = COLORS.textPrimary
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 4
	titleLabel.Parent = topBar

	-- Game badge tag
	local badge = Instance.new("TextLabel")
	badge.Name = "GameBadge"
	badge.Size = UDim2.new(0, 100, 0, 22)
	badge.Position = UDim2.new(0, 190, 0.5, -11)
	badge.BackgroundColor3 = COLORS.glassCard
	badge.BackgroundTransparency = 0.2
	badge.Text = "JAWA BARAT"
	badge.TextColor3 = COLORS.accentGold
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.ZIndex = 4
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = CORNER.small
	badgeCorner.Parent = badge
	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = COLORS.accentGold
	badgeStroke.Transparency = 0.6
	badgeStroke.Thickness = 1
	badgeStroke.Parent = badge
	badge.Parent = topBar

	-- Window Control Buttons Container
	local windowControls = Instance.new("Frame")
	windowControls.Name = "WindowControls"
	windowControls.Size = UDim2.new(0, 95, 1, 0)
	windowControls.Position = UDim2.new(1, -100, 0, 0)
	windowControls.BackgroundTransparency = 1
	windowControls.ZIndex = 4
	windowControls.Parent = topBar

	local function createWinBtn(name, text, col, xPos)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 26, 0, 26)
		btn.Position = UDim2.new(0, xPos, 0.5, -13)
		btn.BackgroundColor3 = COLORS.glassCard
		btn.BackgroundTransparency = 0.3
		btn.Text = text
		btn.TextColor3 = col
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.AutoButtonColor = false
		btn.ZIndex = 5

		local corner = Instance.new("UICorner")
		corner.CornerRadius = CORNER.small
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = col
		stroke.Transparency = 0.7
		stroke.Thickness = 1
		stroke.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundTransparency = 0.05,
				BackgroundColor3 = col,
				TextColor3 = COLORS.textWhite
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundTransparency = 0.3,
				BackgroundColor3 = COLORS.glassCard,
				TextColor3 = col
			}):Play()
		end)

		btn.Parent = windowControls
		return btn
	end

	local minimizeButton = createWinBtn("MinimizeBtn", "—", COLORS.accentGold, 0)
	local fullscreenButton = createWinBtn("FullscreenBtn", "□", COLORS.accentCyan, 32)
	local closeButton = createWinBtn("CloseBtn", "✕", COLORS.dangerRed, 64)

	------------------------------------------------
	-- 📑 SIDEBAR (NAVIGATION TABS)
	------------------------------------------------
	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 155, 1, -54)
	sidebar.Position = UDim2.new(0, 8, 0, 48)
	sidebar.ScrollBarThickness = 2
	sidebar.ScrollBarImageColor3 = COLORS.accentCyan
	sidebar.ScrollBarImageTransparency = 0.7
	sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.ZIndex = 3
	applyGlass(sidebar, {
		color = COLORS.glassSurface,
		transparency = TRANSPARENCY.glassSidebar,
		corner = CORNER.medium,
		strokeColor = COLORS.borderGlass,
		strokeTransparency = 0.6
	})
	sidebar.Parent = mainFrame

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.FillDirection = Enum.FillDirection.Vertical
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Padding = UDim.new(0, 6)
	sidebarLayout.Parent = sidebar

	local sidebarPadding = Instance.new("UIPadding")
	sidebarPadding.PaddingTop = UDim.new(0, 8)
	sidebarPadding.PaddingBottom = UDim.new(0, 8)
	sidebarPadding.PaddingLeft = UDim.new(0, 6)
	sidebarPadding.PaddingRight = UDim.new(0, 6)
	sidebarPadding.Parent = sidebar

	------------------------------------------------
	-- 📄 CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -175, 1, -54)
	contentArea.Position = UDim2.new(0, 167, 0, 48)
	contentArea.ClipsDescendants = true
	contentArea.ZIndex = 3
	applyGlass(contentArea, {
		color = COLORS.glassSurface,
		transparency = TRANSPARENCY.glassSidebar,
		corner = CORNER.medium,
		strokeColor = COLORS.borderGlass,
		strokeTransparency = 0.6
	})
	contentArea.Parent = mainFrame

	------------------------------------------------
	-- 📑 TAB MANAGEMENT SYSTEM
	------------------------------------------------
	local tabs = {}
	local activeTab = nil

	local function selectTab(tabName)
		if activeTab == tabName then return end
		local target = tabs[tabName]
		if not target then return end

		for name, tabData in pairs(tabs) do
			local isCurrent = (name == tabName)
			tabData.content.Visible = isCurrent

			if isCurrent then
				TweenService:Create(tabData.button, TweenInfo.new(0.2), {
					BackgroundColor3 = COLORS.accentCyan,
					BackgroundTransparency = 0.15
				}):Play()
				tabData.title.TextColor3 = COLORS.textWhite
				tabData.icon.TextColor3 = COLORS.textWhite
				if tabData.indicator then
					tabData.indicator.Visible = true
				end
			else
				TweenService:Create(tabData.button, TweenInfo.new(0.2), {
					BackgroundColor3 = COLORS.glassCard,
					BackgroundTransparency = 0.6
				}):Play()
				tabData.title.TextColor3 = COLORS.textSecondary
				tabData.icon.TextColor3 = COLORS.accentCyan
				if tabData.indicator then
					tabData.indicator.Visible = false
				end
			end
		end

		activeTab = tabName
	end

	local function addTab(name, iconText, layoutOrder)
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. name
		tabBtn.Size = UDim2.new(1, 0, 0, 36)
		tabBtn.BackgroundColor3 = COLORS.glassCard
		tabBtn.BackgroundTransparency = 0.6
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.LayoutOrder = layoutOrder or (#sidebar:GetChildren())
		tabBtn.ZIndex = 4

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = CORNER.small
		tabCorner.Parent = tabBtn

		local tabStroke = Instance.new("UIStroke")
		tabStroke.Color = COLORS.borderGlass
		tabStroke.Transparency = 0.7
		tabStroke.Thickness = 1
		tabStroke.Parent = tabBtn

		-- Active indicator bar
		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.new(0, 3, 0.7, 0)
		indicator.Position = UDim2.new(0, 4, 0.15, 0)
		indicator.BackgroundColor3 = COLORS.accentEmerald
		indicator.BorderSizePixel = 0
		indicator.Visible = false
		indicator.ZIndex = 5
		local indCorner = Instance.new("UICorner")
		indCorner.CornerRadius = CORNER.pill
		indCorner.Parent = indicator
		indicator.Parent = tabBtn

		-- Icon Label
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 24, 1, 0)
		icon.Position = UDim2.new(0, 10, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = iconText or "📌"
		icon.TextColor3 = COLORS.accentCyan
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = 14
		icon.ZIndex = 5
		icon.Parent = tabBtn

		-- Title Label
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -40, 1, 0)
		title.Position = UDim2.new(0, 36, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = name
		title.TextColor3 = COLORS.textSecondary
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 12
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 5
		title.Parent = tabBtn

		-- Scrollable Content Frame for this Tab
		local tabContent = Instance.new("ScrollingFrame")
		tabContent.Name = "Content_" .. name
		tabContent.Size = UDim2.new(1, 0, 1, 0)
		tabContent.Position = UDim2.new(0, 0, 0, 0)
		tabContent.BackgroundTransparency = 1
		tabContent.ScrollBarThickness = 3
		tabContent.ScrollBarImageColor3 = COLORS.accentCyan
		tabContent.ScrollBarImageTransparency = 0.5
		tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabContent.Visible = false
		tabContent.ZIndex = 4
		tabContent.Parent = contentArea

		local contentLayout = Instance.new("UIListLayout")
		contentLayout.FillDirection = Enum.FillDirection.Vertical
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		contentLayout.Padding = UDim.new(0, 8)
		contentLayout.Parent = tabContent

		local contentPadding = Instance.new("UIPadding")
		contentPadding.PaddingTop = UDim.new(0, 10)
		contentPadding.PaddingBottom = UDim.new(0, 14)
		contentPadding.PaddingLeft = UDim.new(0, 12)
		contentPadding.PaddingRight = UDim.new(0, 12)
		contentPadding.Parent = tabContent

		tabBtn.MouseEnter:Connect(function()
			if activeTab ~= name then
				TweenService:Create(tabBtn, TweenInfo.new(0.15), {
					BackgroundTransparency = 0.35,
					BackgroundColor3 = COLORS.glassHover
				}):Play()
				title.TextColor3 = COLORS.textPrimary
			end
		end)

		tabBtn.MouseLeave:Connect(function()
			if activeTab ~= name then
				TweenService:Create(tabBtn, TweenInfo.new(0.15), {
					BackgroundTransparency = 0.6,
					BackgroundColor3 = COLORS.glassCard
				}):Play()
				title.TextColor3 = COLORS.textSecondary
			end
		end)

		tabBtn.MouseButton1Click:Connect(function()
			selectTab(name)
		end)

		tabBtn.Parent = sidebar

		tabs[name] = {
			button = tabBtn,
			title = title,
			icon = icon,
			indicator = indicator,
			content = tabContent
		}

		return tabContent
	end

	------------------------------------------------
	-- 🧩 UI COMPONENT BUILDERS
	------------------------------------------------

	-- Section Header
	local function addSection(parent, titleText)
		local sectionFrame = Instance.new("Frame")
		sectionFrame.Name = "Section_" .. tostring(titleText)
		sectionFrame.Size = UDim2.new(1, 0, 0, 26)
		sectionFrame.BackgroundTransparency = 1
		sectionFrame.ZIndex = 5

		local secLabel = Instance.new("TextLabel")
		secLabel.Size = UDim2.new(1, -20, 1, 0)
		secLabel.Position = UDim2.new(0, 2, 0, 0)
		secLabel.BackgroundTransparency = 1
		secLabel.Text = string.upper(tostring(titleText))
		secLabel.TextColor3 = COLORS.accentCyan
		secLabel.Font = Enum.Font.GothamBold
		secLabel.TextSize = 11
		secLabel.TextXAlignment = Enum.TextXAlignment.Left
		secLabel.ZIndex = 5
		secLabel.Parent = sectionFrame

		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 1, -1)
		line.BackgroundColor3 = COLORS.borderGlass
		line.BackgroundTransparency = 0.5
		line.BorderSizePixel = 0
		line.ZIndex = 5
		line.Parent = sectionFrame

		sectionFrame.Parent = parent
		return sectionFrame
	end

	-- Toggle Switch Component
	local function addToggle(parent, text, defaultState, callback)
		local state = defaultState or false

		local toggleCard = Instance.new("Frame")
		toggleCard.Name = "Toggle_" .. tostring(text)
		toggleCard.Size = UDim2.new(1, 0, 0, 40)
		toggleCard.ZIndex = 5
		applyGlass(toggleCard, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.small,
			strokeColor = COLORS.borderGlass,
			strokeTransparency = 0.6
		})

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -65, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = COLORS.textPrimary
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = toggleCard

		local switchTrack = Instance.new("Frame")
		switchTrack.Name = "SwitchTrack"
		switchTrack.Size = UDim2.new(0, 42, 0, 22)
		switchTrack.Position = UDim2.new(1, -54, 0.5, -11)
		switchTrack.BackgroundColor3 = state and COLORS.toggleOn or COLORS.toggleOff
		switchTrack.BorderSizePixel = 0
		switchTrack.ZIndex = 6

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = switchTrack

		local switchKnob = Instance.new("Frame")
		switchKnob.Name = "Knob"
		switchKnob.Size = UDim2.new(0, 18, 0, 18)
		switchKnob.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
		switchKnob.BackgroundColor3 = COLORS.textWhite
		switchKnob.BorderSizePixel = 0
		switchKnob.ZIndex = 7
		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = CORNER.pill
		knobCorner.Parent = switchKnob
		switchKnob.Parent = switchTrack
		switchTrack.Parent = toggleCard

		local triggerBtn = Instance.new("TextButton")
		triggerBtn.Size = UDim2.new(1, 0, 1, 0)
		triggerBtn.BackgroundTransparency = 1
		triggerBtn.Text = ""
		triggerBtn.ZIndex = 8
		triggerBtn.Parent = toggleCard

		local function updateVisual(s)
			local targetTrackCol = s and COLORS.toggleOn or COLORS.toggleOff
			local targetKnobPos = s and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)

			TweenService:Create(switchTrack, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				BackgroundColor3 = targetTrackCol
			}):Play()
			TweenService:Create(switchKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = targetKnobPos
			}):Play()
		end

		triggerBtn.MouseButton1Click:Connect(function()
			state = not state
			updateVisual(state)
			if callback then
				task.spawn(callback, state)
			end
		end)

		toggleCard.Parent = parent

		return {
			card = toggleCard,
			Set = function(newState)
				state = newState
				updateVisual(state)
				if callback then task.spawn(callback, state) end
			end,
			Get = function() return state end
		}
	end

	-- Slider Component
	local function addSlider(parent, text, minVal, maxVal, defaultVal, callback, unit)
		minVal = minVal or 0
		maxVal = maxVal or 100
		defaultVal = math.clamp(defaultVal or minVal, minVal, maxVal)
		unit = unit or ""
		local currentVal = defaultVal

		local sliderCard = Instance.new("Frame")
		sliderCard.Name = "Slider_" .. tostring(text)
		sliderCard.Size = UDim2.new(1, 0, 0, 52)
		sliderCard.ZIndex = 5
		applyGlass(sliderCard, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.small,
			strokeColor = COLORS.borderGlass,
			strokeTransparency = 0.6
		})

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.7, 0, 0, 20)
		label.Position = UDim2.new(0, 12, 0, 6)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = COLORS.textPrimary
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = sliderCard

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0.3, -24, 0, 20)
		valueLabel.Position = UDim2.new(0.7, 12, 0, 6)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(currentVal) .. " " .. unit
		valueLabel.TextColor3 = COLORS.accentCyan
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 12
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.ZIndex = 6
		valueLabel.Parent = sliderCard

		local barTrack = Instance.new("Frame")
		barTrack.Name = "Track"
		barTrack.Size = UDim2.new(1, -24, 0, 8)
		barTrack.Position = UDim2.new(0, 12, 0, 32)
		barTrack.BackgroundColor3 = COLORS.glassSurface
		barTrack.BorderSizePixel = 0
		barTrack.ZIndex = 6
		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = barTrack

		local barFill = Instance.new("Frame")
		barFill.Name = "Fill"
		local pct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
		barFill.Size = UDim2.new(pct, 0, 1, 0)
		barFill.BackgroundColor3 = COLORS.accentCyan
		barFill.BorderSizePixel = 0
		barFill.ZIndex = 7
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = CORNER.pill
		fillCorner.Parent = barFill
		addGradient(barFill, COLORS.accentCyan, COLORS.accentEmerald, 0)
		barFill.Parent = barTrack

		local sliderBtn = Instance.new("TextButton")
		sliderBtn.Size = UDim2.new(1, 0, 1, 0)
		sliderBtn.BackgroundTransparency = 1
		sliderBtn.Text = ""
		sliderBtn.ZIndex = 8
		sliderBtn.Parent = barTrack

		local sliding = false

		local function updateSlider(inputX)
			local trackAbsPos = barTrack.AbsolutePosition.X
			local trackAbsSize = barTrack.AbsoluteSize.X
			local relativeX = math.clamp(inputX - trackAbsPos, 0, trackAbsSize)
			local newPct = relativeX / trackAbsSize
			local rawVal = minVal + (maxVal - minVal) * newPct
			currentVal = math.floor(rawVal * 10) / 10

			barFill.Size = UDim2.new(newPct, 0, 1, 0)
			valueLabel.Text = tostring(currentVal) .. " " .. unit

			if callback then
				task.spawn(callback, currentVal)
			end
		end

		sliderBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = true
				updateSlider(input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateSlider(input.Position.X)
			end
		end)

		barTrack.Parent = sliderCard
		sliderCard.Parent = parent

		return {
			card = sliderCard,
			Set = function(newVal)
				currentVal = math.clamp(newVal, minVal, maxVal)
				local newPct = (currentVal - minVal) / (maxVal - minVal)
				barFill.Size = UDim2.new(newPct, 0, 1, 0)
				valueLabel.Text = tostring(currentVal) .. " " .. unit
				if callback then task.spawn(callback, currentVal) end
			end,
			Get = function() return currentVal end
		}
	end

	-- Button Component
	local function addButton(parent, text, callback, colorType)
		local col = COLORS.accentCyan
		if colorType == "danger" then col = COLORS.dangerRed
		elseif colorType == "success" then col = COLORS.successGreen
		elseif colorType == "warning" then col = COLORS.accentGold end

		local btn = Instance.new("TextButton")
		btn.Name = "Btn_" .. tostring(text)
		btn.Size = UDim2.new(1, 0, 0, 36)
		btn.BackgroundColor3 = COLORS.glassCard
		btn.BackgroundTransparency = 0.2
		btn.Text = text
		btn.TextColor3 = col
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.AutoButtonColor = false
		btn.ZIndex = 5

		local corner = Instance.new("UICorner")
		corner.CornerRadius = CORNER.small
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = col
		stroke.Transparency = 0.6
		stroke.Thickness = 1
		stroke.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = col,
				TextColor3 = COLORS.textWhite,
				BackgroundTransparency = 0.1
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = COLORS.glassCard,
				TextColor3 = col,
				BackgroundTransparency = 0.2
			}):Play()
		end)

		btn.MouseButton1Click:Connect(function()
			if callback then
				task.spawn(callback)
			end
		end)

		btn.Parent = parent
		return btn
	end

	-- Dropdown Component
	local function addDropdown(parent, text, options, defaultVal, callback)
		options = options or {}
		local selected = defaultVal or options[1] or "None"
		local isOpen = false

		local dropdownCard = Instance.new("Frame")
		dropdownCard.Name = "Dropdown_" .. tostring(text)
		dropdownCard.Size = UDim2.new(1, 0, 0, 42)
		dropdownCard.ClipsDescendants = true
		dropdownCard.ZIndex = 6
		applyGlass(dropdownCard, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.small,
			strokeColor = COLORS.borderGlass,
			strokeTransparency = 0.6
		})

		local headerBtn = Instance.new("TextButton")
		headerBtn.Size = UDim2.new(1, 0, 0, 42)
		headerBtn.BackgroundTransparency = 1
		headerBtn.Text = ""
		headerBtn.ZIndex = 7
		headerBtn.Parent = dropdownCard

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.4, 0, 1, 0)
		title.Position = UDim2.new(0, 12, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = text
		title.TextColor3 = COLORS.textPrimary
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 12
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 7
		title.Parent = dropdownCard

		local selLabel = Instance.new("TextLabel")
		selLabel.Size = UDim2.new(0.6, -40, 1, 0)
		selLabel.Position = UDim2.new(0.4, 0, 0, 0)
		selLabel.BackgroundTransparency = 1
		selLabel.Text = tostring(selected)
		selLabel.TextColor3 = COLORS.accentCyan
		selLabel.Font = Enum.Font.GothamBold
		selLabel.TextSize = 11
		selLabel.TextXAlignment = Enum.TextXAlignment.Right
		selLabel.ZIndex = 7
		selLabel.Parent = dropdownCard

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 20, 1, 0)
		arrow.Position = UDim2.new(1, -26, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▼"
		arrow.TextColor3 = COLORS.textSecondary
		arrow.Font = Enum.Font.Gotham
		arrow.TextSize = 10
		arrow.ZIndex = 7
		arrow.Parent = dropdownCard

		local listContainer = Instance.new("Frame")
		listContainer.Size = UDim2.new(1, -16, 0, #options * 28 + 6)
		listContainer.Position = UDim2.new(0, 8, 0, 44)
		listContainer.BackgroundColor3 = COLORS.glassSurface
		listContainer.BackgroundTransparency = 0.2
		listContainer.ZIndex = 8
		local listCorner = Instance.new("UICorner")
		listCorner.CornerRadius = CORNER.small
		listCorner.Parent = listContainer

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.Padding = UDim.new(0, 2)
		listLayout.Parent = listContainer

		local function toggleOpen()
			isOpen = not isOpen
			local targetH = isOpen and (48 + #options * 28 + 8) or 42
			arrow.Text = isOpen and "▲" or "▼"
			TweenService:Create(dropdownCard, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetH)
			}):Play()
		end

		headerBtn.MouseButton1Click:Connect(toggleOpen)

		local function populateOptions(newOpts)
			for _, child in ipairs(listContainer:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			for _, opt in ipairs(newOpts) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, 0, 0, 26)
				optBtn.BackgroundTransparency = 1
				optBtn.Text = "  " .. tostring(opt)
				optBtn.TextColor3 = (opt == selected) and COLORS.accentCyan or COLORS.textSecondary
				optBtn.Font = (opt == selected) and Enum.Font.GothamBold or Enum.Font.Gotham
				optBtn.TextSize = 11
				optBtn.TextXAlignment = Enum.TextXAlignment.Left
				optBtn.ZIndex = 9

				optBtn.MouseEnter:Connect(function()
					optBtn.BackgroundTransparency = 0.7
					optBtn.BackgroundColor3 = COLORS.glassHover
				end)
				optBtn.MouseLeave:Connect(function()
					optBtn.BackgroundTransparency = 1
				end)

				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					selLabel.Text = tostring(selected)
					toggleOpen()
					populateOptions(newOpts)
					if callback then task.spawn(callback, selected) end
				end)

				optBtn.Parent = listContainer
			end
		end

		populateOptions(options)
		listContainer.Parent = dropdownCard
		dropdownCard.Parent = parent

		return {
			card = dropdownCard,
			Set = function(val)
				selected = val
				selLabel.Text = tostring(val)
				populateOptions(options)
				if callback then task.spawn(callback, selected) end
			end,
			Refresh = function(newOpts)
				options = newOpts or {}
				populateOptions(options)
			end,
			Get = function() return selected end
		}
	end

	-- Textbox Input Component
	local function addTextbox(parent, text, placeholder, defaultVal, callback)
		local boxCard = Instance.new("Frame")
		boxCard.Name = "Input_" .. tostring(text)
		boxCard.Size = UDim2.new(1, 0, 0, 42)
		boxCard.ZIndex = 5
		applyGlass(boxCard, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.small,
			strokeColor = COLORS.borderGlass,
			strokeTransparency = 0.6
		})

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.4, 0, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = COLORS.textPrimary
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = boxCard

		local textBox = Instance.new("TextBox")
		textBox.Size = UDim2.new(0.55, 0, 0, 26)
		textBox.Position = UDim2.new(0.45, -8, 0.5, -13)
		textBox.BackgroundColor3 = COLORS.glassSurface
		textBox.BackgroundTransparency = 0.3
		textBox.Text = tostring(defaultVal or "")
		textBox.PlaceholderText = placeholder or "Type here..."
		textBox.PlaceholderColor3 = COLORS.textMuted
		textBox.TextColor3 = COLORS.accentCyan
		textBox.Font = Enum.Font.Gotham
		textBox.TextSize = 11
		textBox.ClearTextOnFocus = false
		textBox.ZIndex = 6

		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = CORNER.small
		boxCorner.Parent = textBox

		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = COLORS.borderGlass
		boxStroke.Transparency = 0.7
		boxStroke.Thickness = 1
		boxStroke.Parent = textBox

		textBox.FocusLost:Connect(function(enterPressed)
			if callback then
				task.spawn(callback, textBox.Text, enterPressed)
			end
		end)

		textBox.Parent = boxCard
		boxCard.Parent = parent

		return {
			card = boxCard,
			Set = function(val) textBox.Text = tostring(val or "") end,
			Get = function() return textBox.Text end
		}
	end

	-- Label / Status Text Component
	local function addLabel(parent, text, colorType)
		local col = COLORS.textSecondary
		if colorType == "success" then col = COLORS.successGreen
		elseif colorType == "warning" then col = COLORS.warningYellow
		elseif colorType == "cyan" then col = COLORS.accentCyan
		elseif colorType == "gold" then col = COLORS.accentGold end

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 22)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = col
		label.Font = Enum.Font.Gotham
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 5
		label.Parent = parent

		return {
			label = label,
			Set = function(newText) label.Text = newText end
		}
	end

	-- Rich Stats Card Component (for Farm Dashboard)
	local function addStatsCard(parent, titleText, initialValue, iconText)
		local card = Instance.new("Frame")
		card.Name = "Stat_" .. tostring(titleText)
		card.Size = UDim2.new(0.48, 0, 0, 54)
		card.ZIndex = 5
		applyGlass(card, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.small,
			strokeColor = COLORS.borderGlass,
			strokeTransparency = 0.6
		})

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 28, 1, 0)
		iconLabel.Position = UDim2.new(0, 8, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = iconText or "📊"
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextSize = 16
		iconLabel.ZIndex = 6
		iconLabel.Parent = card

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -40, 0, 18)
		title.Position = UDim2.new(0, 36, 0, 6)
		title.BackgroundTransparency = 1
		title.Text = string.upper(tostring(titleText))
		title.TextColor3 = COLORS.textMuted
		title.Font = Enum.Font.GothamBold
		title.TextSize = 9
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 6
		title.Parent = card

		local valLabel = Instance.new("TextLabel")
		valLabel.Size = UDim2.new(1, -40, 0, 22)
		valLabel.Position = UDim2.new(0, 36, 0, 24)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = tostring(initialValue or "0")
		valLabel.TextColor3 = COLORS.accentEmerald
		valLabel.Font = Enum.Font.GothamBold
		valLabel.TextSize = 13
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.ZIndex = 6
		valLabel.Parent = card

		card.Parent = parent
		return {
			card = card,
			Set = function(v) valLabel.Text = tostring(v) end
		}
	end

	------------------------------------------------
	-- 🔔 NOTIFICATION SYSTEM
	------------------------------------------------
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "NotificationContainer"
	notifContainer.Size = UDim2.new(0, 280, 1, -20)
	notifContainer.Position = UDim2.new(1, -290, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 10
	notifContainer.Parent = gui

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.FillDirection = Enum.FillDirection.Vertical
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.Padding = UDim.new(0, 6)
	notifLayout.Parent = notifContainer

	local function notify(title, message, duration, notifType)
		duration = duration or 3
		local strokeColor = COLORS.accentCyan
		if notifType == "danger" then strokeColor = COLORS.dangerRed
		elseif notifType == "success" then strokeColor = COLORS.successGreen
		elseif notifType == "warning" then strokeColor = COLORS.warningYellow end

		local notifFrame = Instance.new("Frame")
		notifFrame.Size = UDim2.new(1, 0, 0, 56)
		notifFrame.ZIndex = 11
		applyGlass(notifFrame, {
			color = COLORS.glassPrimary,
			transparency = 0.05,
			corner = CORNER.medium,
			strokeColor = strokeColor,
			strokeThickness = 1.2
		})

		local notifTitle = Instance.new("TextLabel")
		notifTitle.Size = UDim2.new(1, -20, 0, 20)
		notifTitle.Position = UDim2.new(0, 10, 0, 6)
		notifTitle.BackgroundTransparency = 1
		notifTitle.Text = title
		notifTitle.TextColor3 = COLORS.textWhite
		notifTitle.Font = Enum.Font.GothamBold
		notifTitle.TextSize = 12
		notifTitle.TextXAlignment = Enum.TextXAlignment.Left
		notifTitle.ZIndex = 12
		notifTitle.Parent = notifFrame

		local notifDesc = Instance.new("TextLabel")
		notifDesc.Size = UDim2.new(1, -20, 0, 24)
		notifDesc.Position = UDim2.new(0, 10, 0, 26)
		notifDesc.BackgroundTransparency = 1
		notifDesc.Text = message
		notifDesc.TextColor3 = COLORS.textSecondary
		notifDesc.Font = Enum.Font.Gotham
		notifDesc.TextSize = 10
		notifDesc.TextXAlignment = Enum.TextXAlignment.Left
		notifDesc.TextWrapped = true
		notifDesc.ZIndex = 12
		notifDesc.Parent = notifFrame

		notifFrame.Parent = notifContainer

		task.delay(duration, function()
			if notifFrame and notifFrame.Parent then
				TweenService:Create(notifFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				task.wait(0.3)
				notifFrame:Destroy()
			end
		end)
	end

	------------------------------------------------
	-- 🪟 INITIALIZE CORE TABS
	------------------------------------------------
	addTab("Main", "🏠", 1)
	addTab("Farm", "💰", 2)
	addTab("Vehicle", "🚌", 3)
	addTab("Teleport", "📍", 4)
	addTab("Visuals", "👁️", 5)
	addTab("Settings", "⚙️", 6)

	selectTab("Main")

	------------------------------------------------
	-- 🌐 EXPORT GLOBAL UI API
	------------------------------------------------
	_G.HipHubUI = {
		gui = gui,
		mainFrame = mainFrame,
		shadowFrame = shadowFrame,
		topBar = topBar,
		sidebar = sidebar,
		closeButton = closeButton,
		minimizeButton = minimizeButton,
		fullscreenButton = fullscreenButton,
		contentArea = contentArea,
		tabs = tabs,
		COLORS = COLORS,
		TRANSPARENCY = TRANSPARENCY,
		CORNER = CORNER,
		UserInputService = UserInputService,
		TweenService = TweenService,
		RunService = RunService,
		SelectTab = selectTab,
		AddTab = addTab,
		AddSection = addSection,
		AddToggle = addToggle,
		AddSlider = addSlider,
		AddDropdown = addDropdown,
		AddButton = addButton,
		AddTextbox = addTextbox,
		AddLabel = addLabel,
		AddStatsCard = addStatsCard,
		Notify = notify,
		SyncShadow = syncShadow
	}

	notify("HipHub BXI Loaded", "Selamat datang " .. player.DisplayName .. "!", 3, "success")
end)

if not success then
	warn("[HipHub BXI UI Error]:", err)
end
