-- 🌐 HipHub — Liquid Glass Futuristic UI Base (Drag Drive Simulator)
-- Pure UI Layout Base & Component Library
-- Theme: Glassmorphism with Cyber Neon Cyan-Violet & Speed Orange accents

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
	task.wait(0.5)
	player = Players.LocalPlayer
end

--=====================================================================
-- 🛡️ ADONIS & GAME ANTI-CHEAT NEUTRALIZER
--=====================================================================
pcall(function()
	local function neutralizeAntiCheat()
		if not (getreg and getgc and isfunctionhooked and hookfunction) then return end
		
		-- 1. Matikan thread Adonis Anti & Plugins
		for _, thread in ipairs(getreg()) do
			if typeof(thread) == "thread" then
				local s, info = pcall(debug.info, thread, 1, "s")
				if s and info and (info:match("%.Core%.Anti") or info:match("%.Plugins%.Anti_Cheat")) then
					pcall(coroutine.close, thread)
				end
			end
		end

		-- 2. Lumpuhkan fungsi Detected di memori Adonis
		local targets = {}
		if filtergc then
			local tables = filtergc("table", { Keys = { "Detected", "RLocked" } }, false)
			for _, tbl in ipairs(tables or {}) do
				if typeof(rawget(tbl, "Detected")) == "function" then
					table.insert(targets, tbl)
				end
			end
		else
			for _, tbl in ipairs(getgc(true)) do
				if typeof(tbl) == "table" and typeof(rawget(tbl, "Detected")) == "function" and rawget(tbl, "RLocked") then
					table.insert(targets, tbl)
				end
			end
		end

		for _, tbl in ipairs(targets) do
			for k, fn in pairs(tbl) do
				if typeof(fn) == "function" and not isfunctionhooked(fn) then
					hookfunction(fn, function(...)
						coroutine.yield(coroutine.running())
						return task.wait(9000000000)
					end)
				end
			end
		end
	end

	neutralizeAntiCheat()
	task.spawn(function()
		while task.wait(5) do
			pcall(neutralizeAntiCheat)
		end
	end)
end)

local success, err = pcall(function()
	-- Pre-loader optimization check (Ensure 3D rendering is active)
	pcall(function()
		pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(true) end)
		local HttpService = game:GetService("HttpService")
		local file = "HipHub/dds_config.json"
		if isfile and not isfile(file) then
			file = "dds_config.json"
		end
		if isfile and isfile(file) and readfile then
			local configData = HttpService:JSONDecode(readfile(file))
			if configData and configData.misc then
				local misc = configData.misc
				if misc.capFpsEnabled == true then
					if setfpscap then pcall(setfpscap, 15) end
				end
			end
		end
	end)

	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- 🎨 DESIGN TOKENS
	------------------------------------------------
	local COLORS = {
		glassPrimary  = Color3.fromRGB(12, 14, 28),
		glassSurface  = Color3.fromRGB(18, 22, 40),
		glassCard     = Color3.fromRGB(22, 28, 50),
		glassHover    = Color3.fromRGB(30, 38, 66),
		glassActive   = Color3.fromRGB(38, 46, 78),
		accentCyan    = Color3.fromRGB(0, 210, 255),
		accentViolet  = Color3.fromRGB(150, 110, 255),
		accentOrange  = Color3.fromRGB(255, 140, 40),
		accentBlend   = Color3.fromRGB(80, 170, 255),
		accentGlow    = Color3.fromRGB(50, 190, 255),
		accentMuted   = Color3.fromRGB(50, 65, 110),
		toggleOn      = Color3.fromRGB(0, 200, 240),
		toggleOff     = Color3.fromRGB(42, 48, 76),
		textPrimary   = Color3.fromRGB(230, 240, 255),
		textSecondary = Color3.fromRGB(145, 160, 195),
		textMuted     = Color3.fromRGB(95, 110, 145),
		textWhite     = Color3.fromRGB(255, 255, 255),
		borderGlass   = Color3.fromRGB(55, 70, 120),
		borderGlow    = Color3.fromRGB(0, 190, 255),
		shadow        = Color3.fromRGB(2, 4, 10),
		successGreen  = Color3.fromRGB(46, 204, 113),
		warningYellow = Color3.fromRGB(241, 196, 15),
		dangerRed     = Color3.fromRGB(231, 76, 60)
	}

	local TRANSPARENCY = {
		glassMain    = 0.03,
		glassSurface = 0.06,
		glassCard    = 0.08,
		glassSidebar = 0.05,
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
	-- 🧹 CLEANUP EXISTING INSTANCES
	------------------------------------------------
	local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub_DDS") or player.PlayerGui:FindFirstChild("HipHub")
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
		grad.Color = ColorSequence.new(col1, col2)
		grad.Rotation = rot or 45
		grad.Parent = instance
		return grad
	end

	------------------------------------------------
	-- 📱 ROOT SCREEN GUI
	------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_DDS"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 100
	gui.IgnoreGuiInset = true

	local isStudio = RunService:IsStudio()
	if not isStudio and syn and syn.protect_gui then
		syn.protect_gui(gui)
		gui.Parent = game:GetService("CoreGui")
	elseif not isStudio and gethui then
		gui.Parent = gethui()
	else
		gui.Parent = player:WaitForChild("PlayerGui")
	end

	------------------------------------------------
	------------------------------------------------
	-- 🪟 SHADOW & MAIN WINDOW CONTAINER
	------------------------------------------------
	local defaultWidth = 520
	local defaultHeight = 330

	local shadowFrame = Instance.new("Frame")
	shadowFrame.Name = "ShadowFrame"
	shadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shadowFrame.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)
	shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.5
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 1
	shadowFrame.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = CORNER.large
	shadowCorner.Parent = shadowFrame

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	applyGlass(mainFrame, {
		color = COLORS.glassPrimary,
		transparency = TRANSPARENCY.glassMain,
		corner = CORNER.large,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1.2
	})
	mainFrame.ClipsDescendants = true
	mainFrame.ZIndex = 2
	mainFrame.Parent = gui

	-- 📱 Responsive Auto-Scale Engine for Mobile & Redfinger Emulators
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = mainFrame

	local shadowScale = Instance.new("UIScale")
	shadowScale.Parent = shadowFrame

	local function updateScale()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 600)
		local scale = 1.0
		if vp.X < 600 or vp.Y < 400 then
			local scaleX = math.clamp((vp.X - 24) / defaultWidth, 0.50, 1.0)
			local scaleY = math.clamp((vp.Y - 24) / defaultHeight, 0.50, 1.0)
			scale = math.min(scaleX, scaleY)
		end
		uiScale.Scale = scale
		shadowScale.Scale = scale
	end

	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()

	local function syncShadow()
		if shadowFrame and mainFrame then
			shadowFrame.Position = mainFrame.Position + UDim2.new(0, 0, 0, 4)
			shadowFrame.Size = mainFrame.Size
			shadowFrame.Visible = mainFrame.Visible
		end
	end

	-- 📱 Draggable Mobile Floating Toggle Button
	local mobileToggleBtn = Instance.new("ImageButton")
	mobileToggleBtn.Name = "MobileToggleBtn"
	mobileToggleBtn.Size = UDim2.new(0, 40, 0, 40)
	mobileToggleBtn.Position = UDim2.new(0, 15, 0, 50)
	mobileToggleBtn.BackgroundColor3 = COLORS.glassSurface
	mobileToggleBtn.BackgroundTransparency = 0.15
	mobileToggleBtn.BorderSizePixel = 0
	mobileToggleBtn.ZIndex = 25
	mobileToggleBtn.Parent = gui

	local mtCorner = Instance.new("UICorner")
	mtCorner.CornerRadius = UDim.new(1, 0)
	mtCorner.Parent = mobileToggleBtn

	local mtStroke = Instance.new("UIStroke")
	mtStroke.Color = COLORS.accentCyan
	mtStroke.Thickness = 1.5
	mtStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mtStroke.Parent = mobileToggleBtn

	local mtIcon = Instance.new("TextLabel")
	mtIcon.Size = UDim2.new(1, 0, 1, 0)
	mtIcon.BackgroundTransparency = 1
	mtIcon.Text = "🏎️"
	mtIcon.TextSize = 18
	mtIcon.ZIndex = 26
	mtIcon.Parent = mobileToggleBtn

	-- Dragging for mobile toggle button
	local mtDragging, mtDragStart, mtStartPos
	mobileToggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			mtDragging = true
			mtDragStart = input.Position
			mtStartPos = mobileToggleBtn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					mtDragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if mtDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - mtDragStart
			mobileToggleBtn.Position = UDim2.new(
				mtStartPos.X.Scale, mtStartPos.X.Offset + delta.X,
				mtStartPos.Y.Scale, mtStartPos.Y.Offset + delta.Y
			)
		end
	end)

	mobileToggleBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = not mainFrame.Visible
		syncShadow()
		if mainFrame.Visible then
			updateScale()
		end
	end)

	------------------------------------------------
	-- 🔝 TOP BAR (HEADER)
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 38)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	applyGlass(topBar, {
		color = COLORS.glassSurface,
		transparency = TRANSPARENCY.glassTopBar,
		corner = UDim.new(0, 0),
		stroke = false
	})
	topBar.ZIndex = 3
	topBar.Parent = mainFrame

	local topDivider = Instance.new("Frame")
	topDivider.Size = UDim2.new(1, 0, 0, 1)
	topDivider.Position = UDim2.new(0, 0, 1, -1)
	topDivider.BackgroundColor3 = COLORS.borderGlass
	topDivider.BackgroundTransparency = 0.6
	topDivider.BorderSizePixel = 0
	topDivider.ZIndex = 4
	topDivider.Parent = topBar

	local titleLogo = Instance.new("TextLabel")
	titleLogo.Size = UDim2.new(0, 20, 0, 20)
	titleLogo.Position = UDim2.new(0, 10, 0.5, -10)
	titleLogo.BackgroundTransparency = 1
	titleLogo.Text = "🏎️"
	titleLogo.TextSize = 14
	titleLogo.ZIndex = 4
	titleLogo.Parent = topBar

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(0, 200, 1, 0)
	titleText.Position = UDim2.new(0, 34, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "HIPHUB <font color=\"#00D2FF\">DDS</font> <font color=\"#966EFF\">PRO</font>"
	titleText.RichText = true
	titleText.TextColor3 = COLORS.textWhite
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 13
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.ZIndex = 4
	titleText.Parent = topBar

	local windowControls = Instance.new("Frame")
	windowControls.Size = UDim2.new(0, 70, 1, 0)
	windowControls.Position = UDim2.new(1, -75, 0, 0)
	windowControls.BackgroundTransparency = 1
	windowControls.ZIndex = 4
	windowControls.Parent = topBar

	local function createControlBtn(name, icon, posOffset, hoverCol)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 24, 0, 24)
		btn.Position = UDim2.new(0, posOffset, 0.5, -12)
		btn.BackgroundColor3 = COLORS.glassSurface
		btn.BackgroundTransparency = 0.5
		btn.Text = icon
		btn.TextColor3 = COLORS.textSecondary
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 11
		btn.ZIndex = 5
		btn.AutoButtonColor = false
		btn.Parent = windowControls

		local c = Instance.new("UICorner")
		c.CornerRadius = CORNER.small
		c.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.18), {
				BackgroundColor3 = hoverCol or COLORS.glassHover,
				TextColor3 = COLORS.textWhite
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.18), {
				BackgroundColor3 = COLORS.glassSurface,
				TextColor3 = COLORS.textSecondary
			}):Play()
		end)

		return btn
	end

	local minimizeButton = createControlBtn("MinimizeBtn", "—", 5, COLORS.glassHover)
	local closeButton = createControlBtn("CloseBtn", "✕", 38, COLORS.dangerRed)
	local fullscreenButton = minimizeButton

	------------------------------------------------
	-- 📑 SIDEBAR (NAVIGATION TABS)
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 130, 1, -38)
	sidebar.Position = UDim2.new(0, 0, 0, 38)
	applyGlass(sidebar, {
		color = COLORS.glassSurface,
		transparency = TRANSPARENCY.glassSidebar,
		corner = UDim.new(0, 0),
		stroke = false
	})
	sidebar.ZIndex = 3
	sidebar.Parent = mainFrame

	local sideDivider = Instance.new("Frame")
	sideDivider.Size = UDim2.new(0, 1, 1, 0)
	sideDivider.Position = UDim2.new(1, -1, 0, 0)
	sideDivider.BackgroundColor3 = COLORS.borderGlass
	sideDivider.BackgroundTransparency = 0.6
	sideDivider.BorderSizePixel = 0
	sideDivider.ZIndex = 4
	sideDivider.Parent = sidebar

	local tabList = Instance.new("ScrollingFrame")
	tabList.Name = "TabList"
	tabList.Size = UDim2.new(1, -10, 1, -16)
	tabList.Position = UDim2.new(0, 5, 0, 8)
	tabList.BackgroundTransparency = 1
	tabList.BorderSizePixel = 0
	tabList.ScrollBarThickness = 0
	tabList.ZIndex = 4
	tabList.Parent = sidebar

	local tabListLayout = Instance.new("UIListLayout")
	tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabListLayout.Padding = UDim.new(0, 5)
	tabListLayout.Parent = tabList

	------------------------------------------------
	-- 📄 CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -130, 1, -38)
	contentArea.Position = UDim2.new(0, 130, 0, 38)
	contentArea.BackgroundTransparency = 1
	contentArea.ClipsDescendants = true
	contentArea.ZIndex = 3
	contentArea.Parent = mainFrame

	------------------------------------------------
	-- 🗂️ TAB MANAGEMENT SYSTEM
	------------------------------------------------
	local tabs = {}
	local activeTab = nil

	local function selectTab(tabName)
		if activeTab == tabName then return end
		activeTab = tabName

		for name, tabData in pairs(tabs) do
			local isSelected = (name == tabName)
			tabData.content.Visible = isSelected

			if isSelected then
				TweenService:Create(tabData.button, TweenInfo.new(0.2), {
					BackgroundColor3 = COLORS.glassActive,
					BackgroundTransparency = 0.1
				}):Play()
				tabData.btnText.TextColor3 = COLORS.accentCyan
				if tabData.indicator then
					tabData.indicator.Visible = true
					TweenService:Create(tabData.indicator, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
				end
			else
				TweenService:Create(tabData.button, TweenInfo.new(0.2), {
					BackgroundColor3 = COLORS.glassSurface,
					BackgroundTransparency = 0.8
				}):Play()
				tabData.btnText.TextColor3 = COLORS.textSecondary
				if tabData.indicator then
					tabData.indicator.Visible = false
				end
			end
		end
	end

	local function addTab(tabName, icon, layoutOrder)
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "TabBtn_" .. tabName
		tabBtn.Size = UDim2.new(1, 0, 0, 36)
		tabBtn.BackgroundColor3 = COLORS.glassSurface
		tabBtn.BackgroundTransparency = 0.8
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.LayoutOrder = layoutOrder or (#tabList:GetChildren())
		tabBtn.ZIndex = 5
		tabBtn.Parent = tabList

		local c = Instance.new("UICorner")
		c.CornerRadius = CORNER.medium
		c.Parent = tabBtn

		local indicator = Instance.new("Frame")
		indicator.Name = "ActiveIndicator"
		indicator.Size = UDim2.new(0, 3, 0, 20)
		indicator.Position = UDim2.new(0, 2, 0.5, -10)
		indicator.BackgroundColor3 = COLORS.accentCyan
		indicator.BorderSizePixel = 0
		indicator.Visible = false
		indicator.ZIndex = 6
		indicator.Parent = tabBtn

		local indCorner = Instance.new("UICorner")
		indCorner.CornerRadius = CORNER.pill
		indCorner.Parent = indicator

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 24, 1, 0)
		iconLabel.Position = UDim2.new(0, 10, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon or "📁"
		iconLabel.TextSize = 14
		iconLabel.ZIndex = 6
		iconLabel.Parent = tabBtn

		local btnText = Instance.new("TextLabel")
		btnText.Size = UDim2.new(1, -42, 1, 0)
		btnText.Position = UDim2.new(0, 36, 0, 0)
		btnText.BackgroundTransparency = 1
		btnText.Text = tabName
		btnText.TextColor3 = COLORS.textSecondary
		btnText.Font = Enum.Font.GothamMedium
		btnText.TextSize = 12
		btnText.TextXAlignment = Enum.TextXAlignment.Left
		btnText.ZIndex = 6
		btnText.Parent = tabBtn

		local tabScroll = Instance.new("ScrollingFrame")
		tabScroll.Name = "TabContent_" .. tabName
		tabScroll.Size = UDim2.new(1, -20, 1, -20)
		tabScroll.Position = UDim2.new(0, 10, 0, 10)
		tabScroll.BackgroundTransparency = 1
		tabScroll.BorderSizePixel = 0
		tabScroll.ScrollBarThickness = 4
		tabScroll.ScrollBarImageColor3 = COLORS.accentCyan
		tabScroll.ScrollBarImageTransparency = 0.5
		tabScroll.Visible = false
		tabScroll.ZIndex = 4
		tabScroll.Parent = contentArea

		local tabLayout = Instance.new("UIListLayout")
		tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabLayout.Padding = UDim.new(0, 10)
		tabLayout.Parent = tabScroll

		tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 20)
		end)

		tabs[tabName] = {
			button = tabBtn,
			btnText = btnText,
			indicator = indicator,
			content = tabScroll,
			layout = tabLayout
		}

		tabBtn.MouseButton1Click:Connect(function()
			selectTab(tabName)
		end)

		return tabScroll
	end

	------------------------------------------------
	-- 🧱 COMPONENT BUILDERS
	------------------------------------------------
	local function addSection(tab, title)
		local sec = Instance.new("Frame")
		sec.Name = "Section_" .. title
		sec.Size = UDim2.new(1, 0, 0, 26)
		sec.BackgroundTransparency = 1
		sec.ZIndex = 5
		sec.Parent = tab

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = string.upper(title)
		label.TextColor3 = COLORS.accentCyan
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 6
		label.Parent = sec

		local div = Instance.new("Frame")
		div.Size = UDim2.new(1, 0, 0, 1)
		div.Position = UDim2.new(0, 0, 1, -2)
		div.BackgroundColor3 = COLORS.borderGlass
		div.BackgroundTransparency = 0.7
		div.BorderSizePixel = 0
		div.ZIndex = 6
		div.Parent = sec

		return sec
	end

	local function addToggle(tab, title, desc, defaultState, callback)
		local card = Instance.new("Frame")
		card.Name = "ToggleCard_" .. title
		card.Size = UDim2.new(1, 0, 0, desc and 52 or 40)
		applyGlass(card, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.medium
		})
		card.ZIndex = 5
		card.Parent = tab

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -70, 0, 20)
		titleLabel.Position = UDim2.new(0, 12, 0, desc and 8 or 10)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamSemibold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 6
		titleLabel.Parent = card

		if desc then
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -70, 0, 16)
			descLabel.Position = UDim2.new(0, 12, 0, 28)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = desc
			descLabel.TextColor3 = COLORS.textMuted
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 10
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.ZIndex = 6
			descLabel.Parent = card
		end

		local switch = Instance.new("TextButton")
		switch.Name = "Switch"
		switch.Size = UDim2.new(0, 42, 0, 22)
		switch.Position = UDim2.new(1, -54, 0.5, -11)
		switch.BackgroundColor3 = defaultState and COLORS.toggleOn or COLORS.toggleOff
		switch.Text = ""
		switch.AutoButtonColor = false
		switch.ZIndex = 6
		switch.Parent = card

		local swCorner = Instance.new("UICorner")
		swCorner.CornerRadius = CORNER.pill
		swCorner.Parent = switch

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 16, 0, 16)
		knob.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		knob.BackgroundColor3 = COLORS.textWhite
		knob.BorderSizePixel = 0
		knob.ZIndex = 7
		knob.Parent = switch

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = CORNER.pill
		knobCorner.Parent = knob

		local state = defaultState or false

		local function setState(newState)
			if state == newState then return end
			state = newState
			local targetKnobPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
			local targetBgColor = state and COLORS.toggleOn or COLORS.toggleOff

			TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = targetKnobPos }):Play()
			TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = targetBgColor }):Play()

			if callback then
				pcall(callback, state)
			end
		end

		switch.MouseButton1Click:Connect(function()
			setState(not state)
		end)

		return {
			card = card,
			Set = setState,
			Get = function() return state end
		}
	end

	local function addSlider(tab, title, minVal, maxVal, defaultVal, callback)
		local card = Instance.new("Frame")
		card.Name = "SliderCard_" .. title
		card.Size = UDim2.new(1, 0, 0, 56)
		applyGlass(card, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.medium
		})
		card.ZIndex = 5
		card.Parent = tab

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -80, 0, 20)
		titleLabel.Position = UDim2.new(0, 12, 0, 8)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamSemibold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 6
		titleLabel.Parent = card

		local valLabel = Instance.new("TextLabel")
		valLabel.Size = UDim2.new(0, 60, 0, 20)
		valLabel.Position = UDim2.new(1, -72, 0, 8)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = tostring(defaultVal)
		valLabel.TextColor3 = COLORS.accentCyan
		valLabel.Font = Enum.Font.GothamBold
		valLabel.TextSize = 12
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.ZIndex = 6
		valLabel.Parent = card

		local sliderTrack = Instance.new("Frame")
		sliderTrack.Name = "SliderTrack"
		sliderTrack.Size = UDim2.new(1, -24, 0, 6)
		sliderTrack.Position = UDim2.new(0, 12, 0, 36)
		sliderTrack.BackgroundColor3 = COLORS.glassHover
		sliderTrack.BorderSizePixel = 0
		sliderTrack.ZIndex = 6
		sliderTrack.Parent = card

		local trCorner = Instance.new("UICorner")
		trCorner.CornerRadius = CORNER.pill
		trCorner.Parent = sliderTrack

		local initialRatio = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)

		local sliderFill = Instance.new("Frame")
		sliderFill.Name = "SliderFill"
		sliderFill.Size = UDim2.new(initialRatio, 0, 1, 0)
		sliderFill.BackgroundColor3 = COLORS.accentCyan
		sliderFill.BorderSizePixel = 0
		sliderFill.ZIndex = 7
		sliderFill.Parent = sliderTrack

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = CORNER.pill
		fillCorner.Parent = sliderFill

		local currentVal = defaultVal
		local sliding = false

		local function updateFromPos(posX)
			local absWidth = sliderTrack.AbsoluteSize.X
			local absPos = sliderTrack.AbsolutePosition.X
			local ratio = math.clamp((posX - absPos) / absWidth, 0, 1)
			currentVal = math.floor(minVal + (maxVal - minVal) * ratio)
			sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
			valLabel.Text = tostring(currentVal)
			if callback then
				pcall(callback, currentVal)
			end
		end

		sliderTrack.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = true
				updateFromPos(input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromPos(input.Position.X)
			end
		end)

		return {
			card = card,
			Set = function(newVal)
				newVal = math.clamp(newVal, minVal, maxVal)
				currentVal = newVal
				local ratio = (newVal - minVal) / (maxVal - minVal)
				sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
				valLabel.Text = tostring(newVal)
				if callback then pcall(callback, newVal) end
			end,
			Get = function() return currentVal end
		}
	end

	local function addDropdown(tab, title, items, defaultIndex, callback)
		local card = Instance.new("Frame")
		card.Name = "DropdownCard_" .. title
		card.Size = UDim2.new(1, 0, 0, 42)
		applyGlass(card, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.medium
		})
		card.ClipsDescendants = true
		card.ZIndex = 5
		card.Parent = tab

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0, 160, 0, 42)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamSemibold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 6
		titleLabel.Parent = card

		local selectedBtn = Instance.new("TextButton")
		selectedBtn.Name = "SelectedBtn"
		selectedBtn.Size = UDim2.new(1, -180, 0, 28)
		selectedBtn.Position = UDim2.new(0, 170, 0, 7)
		selectedBtn.BackgroundColor3 = COLORS.glassHover
		selectedBtn.BackgroundTransparency = 0.4
		selectedBtn.Text = items[defaultIndex or 1] or "Select..."
		selectedBtn.TextColor3 = COLORS.accentCyan
		selectedBtn.Font = Enum.Font.GothamMedium
		selectedBtn.TextSize = 11
		selectedBtn.AutoButtonColor = false
		selectedBtn.ZIndex = 6
		selectedBtn.Parent = card

		local selCorner = Instance.new("UICorner")
		selCorner.CornerRadius = CORNER.small
		selCorner.Parent = selectedBtn

		local listContainer = Instance.new("Frame")
		listContainer.Name = "ListContainer"
		listContainer.Size = UDim2.new(1, -24, 0, #items * 26)
		listContainer.Position = UDim2.new(0, 12, 0, 44)
		listContainer.BackgroundTransparency = 1
		listContainer.ZIndex = 6
		listContainer.Parent = card

		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 2)
		listLayout.Parent = listContainer

		local isOpen = false
		local selectedItem = items[defaultIndex or 1]

		local function toggleOpen()
			isOpen = not isOpen
			local targetHeight = isOpen and (48 + #items * 28) or 42
			TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			}):Play()
		end

		for i, itemText in ipairs(items) do
			local itemBtn = Instance.new("TextButton")
			itemBtn.Name = "Item_" .. itemText
			itemBtn.Size = UDim2.new(1, 0, 0, 24)
			itemBtn.BackgroundColor3 = COLORS.glassSurface
			itemBtn.BackgroundTransparency = 0.6
			itemBtn.Text = itemText
			itemBtn.TextColor3 = COLORS.textSecondary
			itemBtn.Font = Enum.Font.Gotham
			itemBtn.TextSize = 11
			itemBtn.AutoButtonColor = false
			itemBtn.ZIndex = 7
			itemBtn.Parent = listContainer

			local ic = Instance.new("UICorner")
			ic.CornerRadius = CORNER.small
			ic.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				selectedItem = itemText
				selectedBtn.Text = itemText
				toggleOpen()
				if callback then
					pcall(callback, itemText, i)
				end
			end)
		end

		selectedBtn.MouseButton1Click:Connect(toggleOpen)

		return {
			card = card,
			Get = function() return selectedItem end
		}
	end

	local function addButton(tab, title, btnText, callback)
		local card = Instance.new("Frame")
		card.Name = "ButtonCard_" .. title
		card.Size = UDim2.new(1, 0, 0, 42)
		applyGlass(card, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.medium
		})
		card.ZIndex = 5
		card.Parent = tab

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -120, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamSemibold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 6
		titleLabel.Parent = card

		local actionBtn = Instance.new("TextButton")
		actionBtn.Name = "ActionBtn"
		actionBtn.Size = UDim2.new(0, 100, 0, 28)
		actionBtn.Position = UDim2.new(1, -112, 0.5, -14)
		actionBtn.BackgroundColor3 = COLORS.accentCyan
		actionBtn.BackgroundTransparency = 0.2
		actionBtn.Text = btnText or "Click"
		actionBtn.TextColor3 = COLORS.glassPrimary
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 11
		actionBtn.AutoButtonColor = false
		actionBtn.ZIndex = 6
		actionBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = CORNER.small
		btnCorner.Parent = actionBtn

		actionBtn.MouseButton1Click:Connect(function()
			TweenService:Create(actionBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.4 }):Play()
			task.delay(0.1, function()
				TweenService:Create(actionBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.2 }):Play()
			end)
			if callback then
				pcall(callback)
			end
		end)

		return card
	end

	local function addTextbox(tab, title, placeholder, defaultText, callback)
		if type(defaultText) == "function" and callback == nil then
			callback = defaultText
			defaultText = ""
		end

		local card = Instance.new("Frame")
		card.Name = "TextboxCard_" .. title
		card.Size = UDim2.new(1, 0, 0, 42)
		applyGlass(card, {
			color = COLORS.glassCard,
			transparency = TRANSPARENCY.glassCard,
			corner = CORNER.medium
		})
		card.ZIndex = 5
		card.Parent = tab

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0, 140, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamSemibold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 6
		titleLabel.Parent = card

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -160, 0, 28)
		box.Position = UDim2.new(0, 150, 0.5, -14)
		box.BackgroundColor3 = COLORS.glassHover
		box.BackgroundTransparency = 0.4
		box.PlaceholderText = placeholder or "Type here..."
		box.PlaceholderColor3 = COLORS.textMuted
		box.Text = tostring(defaultText or "")
		box.TextColor3 = COLORS.textWhite
		box.Font = Enum.Font.GothamMedium
		box.TextSize = 11
		box.ClearTextOnFocus = false
		box.ZIndex = 6
		box.Parent = card

		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = CORNER.small
		boxCorner.Parent = box

		box.FocusLost:Connect(function(enterPressed)
			if callback then
				pcall(callback, box.Text, enterPressed)
			end
		end)

		return {
			card = card,
			box = box,
			Get = function() return box.Text end,
			Set = function(t) box.Text = tostring(t) end
		}
	end

	local function addLabel(tab, text, color)
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 0, 20)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color or COLORS.textSecondary
		label.Font = Enum.Font.Gotham
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 5
		label.Parent = tab
		return label
	end

	------------------------------------------------
	-- 🔔 NOTIFICATION SYSTEM
	------------------------------------------------
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "NotifContainer"
	notifContainer.Size = UDim2.new(0, 260, 1, -20)
	notifContainer.Position = UDim2.new(1, -270, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 10
	notifContainer.Parent = gui

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.Padding = UDim.new(0, 8)
	notifLayout.Parent = notifContainer

	local function notify(title, message, duration, statusType)
		duration = duration or 3
		local notifFrame = Instance.new("Frame")
		notifFrame.Size = UDim2.new(1, 0, 0, 56)

		local strokeColor = COLORS.accentCyan
		if statusType == "success" then strokeColor = COLORS.successGreen
		elseif statusType == "warning" then strokeColor = COLORS.warningYellow
		elseif statusType == "danger" then strokeColor = COLORS.dangerRed end

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
	addTab("Vehicle", "🏎️", 3)
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
		Notify = notify,
		SyncShadow = syncShadow
	}

	notify("HipHub DDS Loaded", "Welcome " .. player.DisplayName .. "!", 3, "success")
end)

if not success then
	warn("[HipHub DDS UI Error]:", err)
end
