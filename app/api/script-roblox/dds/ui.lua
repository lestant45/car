-- Liquid Glass Futuristic UI Base (Drag Drive Simulator)
-- Pure UI Layout Base & Component Library
-- Theme: Glassmorphism / Liquid Glass with Cyan-Violet accents (Clean Typography - No Emojis)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
	task.wait(0.5)
	player = Players.LocalPlayer
end

-- UI Initialization


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
	-- CLEANUP EXISTING INSTANCES
	------------------------------------------------
	local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub_DDS") or player.PlayerGui:FindFirstChild("HipHub")
	if oldGui then
		oldGui:Destroy()
	end

	------------------------------------------------
	-- HELPER FUNCTIONS
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
			if opts.returnStroke then return stroke end
		end

		if opts.gradient then
			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 190, 220)),
			})
			grad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05),
				NumberSequenceKeypoint.new(0.5, 0.12),
				NumberSequenceKeypoint.new(1, 0.03),
			})
			grad.Rotation = opts.gradientRotation or 145
			grad.Parent = frame
		end
	end

	local function applyPadding(parent, l, r, t, b)
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, l or 0)
		p.PaddingRight = UDim.new(0, r or 0)
		p.PaddingTop = UDim.new(0, t or 0)
		p.PaddingBottom = UDim.new(0, b or 0)
		p.Parent = parent
		return p
	end

	local function applyListLayout(parent, padding, sortOrder)
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, padding or 6)
		layout.Parent = parent
		return layout
	end

	------------------------------------------------
	-- ROOT SCREEN GUI
	------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_DDS"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2147483647
	pcall(function()
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.IgnoreGuiInset = true
	end)

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
	-- SHADOW & MAIN WINDOW CONTAINER
	------------------------------------------------
	local defaultWidth = 560
	local defaultHeight = 380

	local shadowFrame = Instance.new("Frame")
	shadowFrame.Name = "ShadowFrame"
	shadowFrame.Size = UDim2.new(0, defaultWidth + 12, 0, defaultHeight + 12)
	shadowFrame.Position = UDim2.new(0.5, -(defaultWidth + 12) / 2, 0.5, -(defaultHeight + 12) / 2)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.45
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 0
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
	mainFrame.ZIndex = 1
	mainFrame.Parent = gui

	applyGlass(mainFrame, {
		corner = CORNER.large,
		stroke = true,
		strokeColor = COLORS.borderGlow,
		strokeThickness = 1.5,
		strokeTransparency = TRANSPARENCY.borderGlow,
		gradient = true,
		gradientRotation = 145,
	})

	local function syncShadow()
		if shadowFrame and mainFrame then
			shadowFrame.Position = UDim2.new(
				mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 6,
				mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 6
			)
			shadowFrame.Size = UDim2.new(
				mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 12,
				mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 12
			)
			shadowFrame.Visible = mainFrame.Visible
		end
	end
	syncShadow()

	-- Breathing glow animation on main window stroke
	local mainStroke = mainFrame:FindFirstChildOfClass("UIStroke")
	if mainStroke then
		task.spawn(function()
			while mainFrame and mainFrame.Parent do
				TweenService:Create(mainStroke, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentViolet
				}):Play()
				task.wait(2.5)
				TweenService:Create(mainStroke, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentCyan
				}):Play()
				task.wait(2.5)
			end
		end)
	end

	-- Specular top highlight reflection
	local glassHighlight = Instance.new("Frame")
	glassHighlight.Name = "GlassHighlight"
	glassHighlight.Size = UDim2.new(1, 0, 0, 60)
	glassHighlight.Position = UDim2.new(0, 0, 0, 0)
	glassHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glassHighlight.BackgroundTransparency = 0.96
	glassHighlight.BorderSizePixel = 0
	glassHighlight.ZIndex = 1
	glassHighlight.Parent = mainFrame

	local highlightGrad = Instance.new("UIGradient")
	highlightGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.90),
		NumberSequenceKeypoint.new(1, 1),
	})
	highlightGrad.Rotation = 180
	highlightGrad.Parent = glassHighlight

	-- Responsive Auto-Scale for Mobile & Tablets
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = mainFrame

	local shadowScale = Instance.new("UIScale")
	shadowScale.Parent = shadowFrame

	local function updateScale()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1000, 600)
		local scale = 1.0
		if vp.X < 620 or vp.Y < 420 then
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

	-- Floating Mobile Toggle Button (Text-only: DDS)
	local mobileToggleBtn = Instance.new("TextButton")
	mobileToggleBtn.Name = "MobileToggleBtn"
	mobileToggleBtn.Size = UDim2.new(0, 44, 0, 44)
	mobileToggleBtn.Position = UDim2.new(0, 15, 0, 50)
	mobileToggleBtn.BackgroundColor3 = COLORS.glassSurface
	mobileToggleBtn.BackgroundTransparency = 0.15
	mobileToggleBtn.BorderSizePixel = 0
	mobileToggleBtn.Text = "DDS"
	mobileToggleBtn.TextColor3 = COLORS.accentCyan
	mobileToggleBtn.Font = Enum.Font.GothamBold
	mobileToggleBtn.TextSize = 13
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
	-- TOP BAR (HEADER)
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 42)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = COLORS.glassSurface
	topBar.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = mainFrame

	applyGlass(topBar, { corner = CORNER.large, stroke = false })

	local topBarCover = Instance.new("Frame")
	topBarCover.Size = UDim2.new(1, 0, 0, 14)
	topBarCover.Position = UDim2.new(0, 0, 1, -14)
	topBarCover.BackgroundColor3 = COLORS.glassSurface
	topBarCover.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBarCover.BorderSizePixel = 0
	topBarCover.ZIndex = 2
	topBarCover.Parent = topBar

	local topBarAccent = Instance.new("Frame")
	topBarAccent.Name = "TopBarAccent"
	topBarAccent.Size = UDim2.new(1, 0, 0, 1)
	topBarAccent.Position = UDim2.new(0, 0, 1, -1)
	topBarAccent.BackgroundColor3 = COLORS.accentCyan
	topBarAccent.BackgroundTransparency = 0.7
	topBarAccent.BorderSizePixel = 0
	topBarAccent.ZIndex = 3
	topBarAccent.Parent = topBar

	local accentGrad = Instance.new("UIGradient")
	accentGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.accentCyan),
		ColorSequenceKeypoint.new(0.5, COLORS.accentViolet),
		ColorSequenceKeypoint.new(1, COLORS.accentCyan),
	})
	accentGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	accentGrad.Parent = topBarAccent

	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size = UDim2.new(0, 68, 1, 0)
	hubTitle.Position = UDim2.new(0, 16, 0, 0)
	hubTitle.BackgroundTransparency = 1
	hubTitle.Text = "HipHub"
	hubTitle.TextColor3 = COLORS.textWhite
	hubTitle.Font = Enum.Font.GothamBold
	hubTitle.TextSize = 16
	hubTitle.TextXAlignment = Enum.TextXAlignment.Left
	hubTitle.ZIndex = 3
	hubTitle.Parent = topBar

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0, 150, 0, 22)
	badge.Position = UDim2.new(0, 88, 0.5, -11)
	badge.BackgroundColor3 = COLORS.accentViolet
	badge.BackgroundTransparency = 0.35
	badge.Text = "Drag Drive Simulator"
	badge.TextColor3 = COLORS.textWhite
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.ZIndex = 3
	badge.Parent = topBar

	applyGlass(badge, {
		corner = CORNER.pill,
		stroke = true,
		strokeColor = COLORS.accentViolet,
		strokeThickness = 1,
		strokeTransparency = 0.5
	})

	-- Window Control Buttons (Close, Fullscreen, Minimize)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseBtn"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -38, 0.5, -15)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "X"
	closeButton.TextColor3 = COLORS.textSecondary
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 13
	closeButton.ZIndex = 3
	closeButton.Parent = topBar

	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 80, 80) }):Play()
	end)
	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
	end)
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		syncShadow()
	end)

	local isFullscreen = false
	local origSize = mainFrame.Size
	local origPos = mainFrame.Position

	local fullscreenButton = Instance.new("TextButton")
	fullscreenButton.Name = "FullscreenBtn"
	fullscreenButton.Size = UDim2.new(0, 30, 0, 30)
	fullscreenButton.Position = UDim2.new(1, -70, 0.5, -15)
	fullscreenButton.BackgroundTransparency = 1
	fullscreenButton.Text = ""
	fullscreenButton.ZIndex = 3
	fullscreenButton.Parent = topBar

	local fsIcon = Instance.new("Frame")
	fsIcon.Size = UDim2.new(0, 10, 0, 10)
	fsIcon.Position = UDim2.new(0.5, -5, 0.5, -5)
	fsIcon.BackgroundTransparency = 1
	fsIcon.BorderSizePixel = 0
	fsIcon.ZIndex = 4
	fsIcon.Parent = fullscreenButton

	local fsIconStroke = Instance.new("UIStroke")
	fsIconStroke.Color = COLORS.textSecondary
	fsIconStroke.Thickness = 1.5
	fsIconStroke.Parent = fsIcon

	local fsIcon2 = Instance.new("Frame")
	fsIcon2.Size = UDim2.new(0, 8, 0, 8)
	fsIcon2.Position = UDim2.new(0.5, -3, 0.5, -7)
	fsIcon2.BackgroundTransparency = 1
	fsIcon2.BorderSizePixel = 0
	fsIcon2.Visible = false
	fsIcon2.ZIndex = 4
	fsIcon2.Parent = fullscreenButton

	local fsIcon2Stroke = Instance.new("UIStroke")
	fsIcon2Stroke.Color = COLORS.textSecondary
	fsIcon2Stroke.Thickness = 1.5
	fsIcon2Stroke.Parent = fsIcon2

	local function updateFullscreenIcon(full)
		if full then
			fsIcon.Size = UDim2.new(0, 8, 0, 8)
			fsIcon.Position = UDim2.new(0.5, -6, 0.5, -2)
			fsIcon2.Visible = true
		else
			fsIcon.Size = UDim2.new(0, 10, 0, 10)
			fsIcon.Position = UDim2.new(0.5, -5, 0.5, -5)
			fsIcon2.Visible = false
		end
	end

	fullscreenButton.MouseEnter:Connect(function()
		TweenService:Create(fsIconStroke, TweenInfo.new(0.15), { Color = COLORS.accentCyan }):Play()
		TweenService:Create(fsIcon2Stroke, TweenInfo.new(0.15), { Color = COLORS.accentCyan }):Play()
	end)
	fullscreenButton.MouseLeave:Connect(function()
		TweenService:Create(fsIconStroke, TweenInfo.new(0.15), { Color = COLORS.textSecondary }):Play()
		TweenService:Create(fsIcon2Stroke, TweenInfo.new(0.15), { Color = COLORS.textSecondary }):Play()
	end)

	fullscreenButton.MouseButton1Click:Connect(function()
		isFullscreen = not isFullscreen
		if isFullscreen then
			origSize = mainFrame.Size
			origPos = mainFrame.Position
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0.95, 0, 0.92, 0),
				Position = UDim2.new(0.025, 0, 0.04, 0)
			}):Play()
		else
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = origSize,
				Position = origPos
			}):Play()
		end
		updateFullscreenIcon(isFullscreen)
		task.delay(0.26, syncShadow)
	end)

	local isMinimized = false
	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "MinimizeBtn"
	minimizeButton.Size = UDim2.new(0, 30, 0, 30)
	minimizeButton.Position = UDim2.new(1, -102, 0.5, -15)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "-"
	minimizeButton.TextColor3 = COLORS.textSecondary
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 16
	minimizeButton.ZIndex = 3
	minimizeButton.Parent = topBar

	minimizeButton.MouseEnter:Connect(function()
		TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
	end)
	minimizeButton.MouseLeave:Connect(function()
		TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
	end)

	local sidebarInstance = nil
	local contentAreaInstance = nil

	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			if sidebarInstance then sidebarInstance.Visible = false end
			if contentAreaInstance then contentAreaInstance.Visible = false end
			TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = UDim2.new(0, defaultWidth, 0, 42) }):Play()
		else
			TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = isFullscreen and UDim2.new(0.95, 0, 0.92, 0) or origSize }):Play()
			task.delay(0.2, function()
				if sidebarInstance then sidebarInstance.Visible = true end
				if contentAreaInstance then contentAreaInstance.Visible = true end
			end)
		end
		task.delay(0.22, syncShadow)
	end)

	-- Window Dragging Handler (PC Mouse + Mobile Touch)
	local dragging, dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					syncShadow()
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
			syncShadow()
		end
	end)

	------------------------------------------------
	-- SIDEBAR (Glass Panel)
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 150, 1, -42)
	sidebar.Position = UDim2.new(0, 0, 0, 42)
	sidebar.BackgroundColor3 = COLORS.glassSurface
	sidebar.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 1
	sidebar.Parent = mainFrame
	sidebarInstance = sidebar

	applyGlass(sidebar, { corner = CORNER.large, stroke = false })

	local sidebarCover = Instance.new("Frame")
	sidebarCover.Size = UDim2.new(0, 14, 1, 0)
	sidebarCover.Position = UDim2.new(1, -14, 0, 0)
	sidebarCover.BackgroundColor3 = COLORS.glassSurface
	sidebarCover.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebarCover.BorderSizePixel = 0
	sidebarCover.ZIndex = 1
	sidebarCover.Parent = sidebar

	local sidebarGlow = Instance.new("Frame")
	sidebarGlow.Name = "SidebarGlow"
	sidebarGlow.Size = UDim2.new(0, 1, 1, -20)
	sidebarGlow.Position = UDim2.new(1, -1, 0, 10)
	sidebarGlow.BackgroundColor3 = COLORS.accentCyan
	sidebarGlow.BackgroundTransparency = 0.78
	sidebarGlow.BorderSizePixel = 0
	sidebarGlow.ZIndex = 2
	sidebarGlow.Parent = sidebar

	local sidebarGlowGrad = Instance.new("UIGradient")
	sidebarGlowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.5),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	sidebarGlowGrad.Rotation = 90
	sidebarGlowGrad.Parent = sidebarGlow

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 1, -60)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 2
	tabContainer.Parent = sidebar

	applyListLayout(tabContainer, 4)
	applyPadding(tabContainer, 8, 8, 12, 0)

	-- Profile Card at Bottom of Sidebar
	local profileCard = Instance.new("Frame")
	profileCard.Name = "ProfileCard"
	profileCard.Size = UDim2.new(1, -16, 0, 44)
	profileCard.Position = UDim2.new(0, 8, 1, -52)
	profileCard.BackgroundColor3 = COLORS.glassCard
	profileCard.BackgroundTransparency = TRANSPARENCY.glassCard
	profileCard.BorderSizePixel = 0
	profileCard.ZIndex = 2
	profileCard.Parent = sidebar

	applyGlass(profileCard, {
		corner = CORNER.small,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	local avatarLabel = Instance.new("ImageLabel")
	avatarLabel.Name = "Avatar"
	avatarLabel.Size = UDim2.new(0, 28, 0, 28)
	avatarLabel.Position = UDim2.new(0, 8, 0.5, -14)
	avatarLabel.BackgroundColor3 = COLORS.glassHover
	avatarLabel.BorderSizePixel = 0
	avatarLabel.ZIndex = 3
	avatarLabel.Parent = profileCard

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = CORNER.pill
	avatarCorner.Parent = avatarLabel

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = COLORS.accentCyan
	avatarStroke.Thickness = 1
	avatarStroke.Transparency = 0.5
	avatarStroke.Parent = avatarLabel

	pcall(function()
		local thumb = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if thumb then avatarLabel.Image = thumb end
	end)

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "Username"
	usernameLabel.Size = UDim2.new(1, -48, 1, 0)
	usernameLabel.Position = UDim2.new(0, 42, 0, 0)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = player.DisplayName or player.Name
	usernameLabel.TextColor3 = COLORS.textPrimary
	usernameLabel.Font = Enum.Font.GothamMedium
	usernameLabel.TextSize = 11
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.ZIndex = 3
	usernameLabel.Parent = profileCard

	------------------------------------------------
	-- CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -150, 1, -42)
	contentArea.Position = UDim2.new(0, 150, 0, 42)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 1
	contentArea.Parent = mainFrame
	contentAreaInstance = contentArea

	------------------------------------------------
	-- TAB SYSTEM (Text-Only - No Emojis)
	------------------------------------------------
	local tabs = {}
	local activeTab = nil

	local function createTabContent(name)
		local frame = Instance.new("ScrollingFrame")
		frame.Name = name .. "TabContent"
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.ScrollBarThickness = 3
		frame.ScrollBarImageColor3 = COLORS.accentCyan
		frame.ScrollBarImageTransparency = 0.4
		frame.CanvasSize = UDim2.new(0, 0, 0, 0)
		frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		frame.ClipsDescendants = true
		frame.Visible = false
		frame.ZIndex = 2
		frame.Parent = contentArea

		applyPadding(frame, 14, 14, 12, 14)
		local listLayout = applyListLayout(frame, 8)

		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			frame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 24)
		end)

		return frame
	end

	local function selectTab(tabName)
		for name, data in pairs(tabs) do
			local frame = data.Frame or data.content
			local btn = data.Button or data.button
			local ind = data.Indicator or data.indicator

			if name == tabName then
				if frame then frame.Visible = true end
				if btn then
					TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = COLORS.glassActive,
						BackgroundTransparency = 0.15,
					}):Play()
					btn.TextColor3 = COLORS.textWhite
				end
				if ind then
					ind.Visible = true
					TweenService:Create(ind, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
						BackgroundTransparency = 0,
					}):Play()
				end
			else
				if frame then frame.Visible = false end
				if btn then
					TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = COLORS.glassSurface,
						BackgroundTransparency = 1,
					}):Play()
					btn.TextColor3 = COLORS.textSecondary
				end
				if ind then
					TweenService:Create(ind, TweenInfo.new(0.15), {
						BackgroundTransparency = 1,
					}):Play()
					task.delay(0.15, function()
						if activeTab ~= name and ind then
							ind.Visible = false
						end
					end)
				end
			end
		end
		activeTab = tabName
	end

	local function addTab(name, iconText, layoutOrder)
		local button = Instance.new("TextButton")
		button.Name = name .. "TabButton"
		button.Size = UDim2.new(1, 0, 0, 32)
		button.BackgroundColor3 = COLORS.glassSurface
		button.BackgroundTransparency = 1
		button.BorderSizePixel = 0
		button.ZIndex = 3
		-- Clean typography without emojis
		button.Text = "    " .. name
		button.TextColor3 = COLORS.textSecondary
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 12
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.LayoutOrder = layoutOrder or 1
		button.Parent = tabContainer

		applyGlass(button, { corner = CORNER.small, stroke = false })

		local indicator = Instance.new("Frame")
		indicator.Name = "ActiveIndicator"
		indicator.Size = UDim2.new(0, 3, 0, 16)
		indicator.Position = UDim2.new(0, 2, 0.5, -8)
		indicator.BackgroundColor3 = COLORS.accentCyan
		indicator.BackgroundTransparency = 1
		indicator.BorderSizePixel = 0
		indicator.Visible = false
		indicator.ZIndex = 4
		indicator.Parent = button

		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0, 2)
		indicatorCorner.Parent = indicator

		local contentFrame = createTabContent(name)

		local tabData = {
			Frame = contentFrame,
			content = contentFrame,
			Button = button,
			button = button,
			Indicator = indicator,
			indicator = indicator,
		}
		tabs[name] = tabData

		button.MouseButton1Click:Connect(function()
			selectTab(name)
		end)

		button.MouseEnter:Connect(function()
			if activeTab ~= name then
				TweenService:Create(button, TweenInfo.new(0.15), {
					BackgroundColor3 = COLORS.glassHover,
					BackgroundTransparency = 0.5,
				}):Play()
			end
		end)
		button.MouseLeave:Connect(function()
			if activeTab ~= name then
				TweenService:Create(button, TweenInfo.new(0.15), {
					BackgroundColor3 = COLORS.glassSurface,
					BackgroundTransparency = 1,
				}):Play()
			end
		end)

		return contentFrame
	end

	------------------------------------------------
	-- COMPONENT BUILDERS (Liquid Glass - Clean UI)
	------------------------------------------------

	-- Section Header
	local function addSection(parent, title, layoutOrder)
		local sectionCard = Instance.new("Frame")
		sectionCard.Name = "Section_" .. tostring(title):gsub("%s+", "")
		sectionCard.Size = UDim2.new(1, 0, 0, 28)
		sectionCard.BackgroundTransparency = 1
		sectionCard.BorderSizePixel = 0
		sectionCard.LayoutOrder = layoutOrder or 0
		sectionCard.ZIndex = 3
		sectionCard.Parent = parent

		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 3, 0, 14)
		accentBar.Position = UDim2.new(0, 2, 0.5, -7)
		accentBar.BackgroundColor3 = COLORS.accentCyan
		accentBar.BorderSizePixel = 0
		accentBar.ZIndex = 4
		accentBar.Parent = sectionCard

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(0, 2)
		barCorner.Parent = accentBar

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -20, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = string.upper(tostring(title))
		titleLabel.TextColor3 = COLORS.accentCyan
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = sectionCard

		local divLine = Instance.new("Frame")
		divLine.Size = UDim2.new(1, -2, 0, 1)
		divLine.Position = UDim2.new(0, 2, 1, -1)
		divLine.BackgroundColor3 = COLORS.borderGlass
		divLine.BackgroundTransparency = 0.75
		divLine.BorderSizePixel = 0
		divLine.ZIndex = 4
		divLine.Parent = sectionCard

		return sectionCard
	end

	-- Toggle Switch Component (Flexible: 4 or 5 parameters)
	local function addToggle(parent, title, arg3, arg4, arg5)
		local desc, defaultState, callback, layoutOrder
		if type(arg3) == "string" then
			desc = arg3
			defaultState = arg4
			callback = arg5
		else
			defaultState = arg3
			callback = arg4
			layoutOrder = arg5
		end
		defaultState = defaultState or false

		local card = Instance.new("Frame")
		card.Name = "ToggleCard_" .. tostring(title)
		card.Size = UDim2.new(1, 0, 0, desc and 48 or 36)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 3
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -65, 0, 18)
		titleLabel.Position = UDim2.new(0, 12, 0, desc and 6 or 9)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.ZIndex = 4
		titleLabel.Parent = card

		if desc and desc ~= "" then
			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -65, 0, 16)
			descLabel.Position = UDim2.new(0, 12, 0, 26)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = desc
			descLabel.TextColor3 = COLORS.textMuted
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 10
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextTruncate = Enum.TextTruncate.AtEnd
			descLabel.ZIndex = 4
			descLabel.Parent = card
		end

		local track = Instance.new("TextButton")
		track.Name = "SwitchTrack"
		track.Size = UDim2.new(0, 38, 0, 20)
		track.Position = UDim2.new(1, -48, 0.5, -10)
		track.BackgroundColor3 = defaultState and COLORS.toggleOn or COLORS.toggleOff
		track.BackgroundTransparency = 0.15
		track.BorderSizePixel = 0
		track.Text = ""
		track.AutoButtonColor = false
		track.ZIndex = 4
		track.Parent = card

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = track

		local trackStroke = Instance.new("UIStroke")
		trackStroke.Color = COLORS.accentCyan
		trackStroke.Thickness = 1
		trackStroke.Transparency = defaultState and 0.4 or 0.8
		trackStroke.Parent = track

		local thumb = Instance.new("Frame")
		thumb.Name = "Thumb"
		thumb.Size = UDim2.new(0, 14, 0, 14)
		thumb.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
		thumb.BackgroundColor3 = COLORS.textWhite
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 5
		thumb.Parent = track

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = CORNER.pill
		thumbCorner.Parent = thumb

		local state = defaultState

		local function setState(newState, force)
			if state == newState and not force then return end
			state = newState
			local targetThumbPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
			local targetBgColor = state and COLORS.toggleOn or COLORS.toggleOff
			local targetStrokeTrans = state and 0.4 or 0.8

			TweenService:Create(thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = targetThumbPos }):Play()
			TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = targetBgColor }):Play()
			TweenService:Create(trackStroke, TweenInfo.new(0.2), { Transparency = targetStrokeTrans }):Play()

			if callback then
				pcall(callback, state)
			end
		end

		track.MouseButton1Click:Connect(function()
			setState(not state)
		end)

		return {
			card = card,
			Set = setState,
			Get = function() return state end
		}
	end

	-- Slider Component
	local function addSlider(parent, title, minVal, maxVal, defaultVal, callback, layoutOrder, suffix)
		suffix = suffix or ""
		defaultVal = defaultVal or minVal

		local card = Instance.new("Frame")
		card.Name = "SliderCard_" .. tostring(title)
		card.Size = UDim2.new(1, 0, 0, 52)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 3
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -90, 0, 20)
		titleLabel.Position = UDim2.new(0, 12, 0, 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = card

		local valBadge = Instance.new("TextLabel")
		valBadge.Size = UDim2.new(0, 70, 0, 18)
		valBadge.Position = UDim2.new(1, -82, 0, 6)
		valBadge.BackgroundColor3 = COLORS.glassSurface
		valBadge.BackgroundTransparency = 0.3
		valBadge.Text = tostring(defaultVal) .. suffix
		valBadge.TextColor3 = COLORS.accentCyan
		valBadge.Font = Enum.Font.GothamBold
		valBadge.TextSize = 11
		valBadge.TextXAlignment = Enum.TextXAlignment.Center
		valBadge.ZIndex = 4
		valBadge.Parent = card

		applyGlass(valBadge, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		local sliderTrack = Instance.new("Frame")
		sliderTrack.Name = "Track"
		sliderTrack.Size = UDim2.new(1, -24, 0, 6)
		sliderTrack.Position = UDim2.new(0, 12, 0, 36)
		sliderTrack.BackgroundColor3 = Color3.fromRGB(30, 36, 60)
		sliderTrack.BorderSizePixel = 0
		sliderTrack.ZIndex = 4
		sliderTrack.Parent = card

		local trCorner = Instance.new("UICorner")
		trCorner.CornerRadius = CORNER.pill
		trCorner.Parent = sliderTrack

		local initialRatio = math.clamp((defaultVal - minVal) / math.max(1, maxVal - minVal), 0, 1)

		local sliderFill = Instance.new("Frame")
		sliderFill.Name = "Fill"
		sliderFill.Size = UDim2.new(initialRatio, 0, 1, 0)
		sliderFill.BackgroundColor3 = COLORS.accentCyan
		sliderFill.BorderSizePixel = 0
		sliderFill.ZIndex = 5
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
			valBadge.Text = tostring(currentVal) .. suffix
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
				local ratio = (newVal - minVal) / math.max(1, maxVal - minVal)
				sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
				valBadge.Text = tostring(newVal) .. suffix
				if callback then pcall(callback, newVal) end
			end,
			Get = function() return currentVal end
		}
	end

	-- Dropdown Component (Interactive Glass Card)
	local function addDropdown(parent, title, items, defaultSelection, callback, layoutOrder)
		local defaultText = "Select..."
		if type(defaultSelection) == "number" then
			defaultText = items[defaultSelection] or items[1] or defaultText
		elseif type(defaultSelection) == "string" then
			defaultText = defaultSelection
		elseif items and items[1] then
			defaultText = items[1]
		end

		local card = Instance.new("Frame")
		card.Name = "DropdownCard_" .. tostring(title)
		card.Size = UDim2.new(1, 0, 0, 38)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 3
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0, 150, 0, 38)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = card

		local selectedBtn = Instance.new("TextButton")
		selectedBtn.Name = "SelectedBtn"
		selectedBtn.Size = UDim2.new(1, -170, 0, 26)
		selectedBtn.Position = UDim2.new(0, 160, 0, 6)
		selectedBtn.BackgroundColor3 = COLORS.glassSurface
		selectedBtn.BackgroundTransparency = 0.25
		selectedBtn.Text = defaultText
		selectedBtn.TextColor3 = COLORS.accentCyan
		selectedBtn.Font = Enum.Font.GothamBold
		selectedBtn.TextSize = 11
		selectedBtn.AutoButtonColor = false
		selectedBtn.ZIndex = 4
		selectedBtn.Parent = card

		applyGlass(selectedBtn, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		local listContainer = Instance.new("ScrollingFrame")
		listContainer.Name = "ListContainer"
		listContainer.Size = UDim2.new(1, -24, 0, 120)
		listContainer.Position = UDim2.new(0, 12, 0, 42)
		listContainer.BackgroundTransparency = 1
		listContainer.BorderSizePixel = 0
		listContainer.ScrollBarThickness = 2
		listContainer.ScrollBarImageColor3 = COLORS.accentCyan
		listContainer.CanvasSize = UDim2.new(0, 0, 0, #items * 26)
		listContainer.ZIndex = 5
		listContainer.Parent = card

		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 3)
		listLayout.Parent = listContainer

		local isOpen = false
		local selectedItem = defaultText

		local function toggleOpen()
			isOpen = not isOpen
			local displayItemsCount = math.min(#items, 5)
			local targetHeight = isOpen and (46 + displayItemsCount * 28) or 38
			listContainer.Size = UDim2.new(1, -24, 0, displayItemsCount * 28)
			listContainer.CanvasSize = UDim2.new(0, 0, 0, #items * 28)

			TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			}):Play()
		end

		local function renderItems(newItems)
			items = newItems or items
			for _, child in ipairs(listContainer:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			for i, itemText in ipairs(items) do
				local itemBtn = Instance.new("TextButton")
				itemBtn.Name = "Item_" .. tostring(itemText)
				itemBtn.Size = UDim2.new(1, -6, 0, 24)
				itemBtn.BackgroundColor3 = COLORS.glassSurface
				itemBtn.BackgroundTransparency = 0.4
				itemBtn.Text = "  " .. tostring(itemText)
				itemBtn.TextColor3 = (tostring(itemText) == selectedItem) and COLORS.accentCyan or COLORS.textSecondary
				itemBtn.Font = Enum.Font.Gotham
				itemBtn.TextSize = 11
				itemBtn.TextXAlignment = Enum.TextXAlignment.Left
				itemBtn.AutoButtonColor = false
				itemBtn.ZIndex = 6
				itemBtn.Parent = listContainer

				local ic = Instance.new("UICorner")
				ic.CornerRadius = CORNER.small
				ic.Parent = itemBtn

				itemBtn.MouseButton1Click:Connect(function()
					selectedItem = tostring(itemText)
					selectedBtn.Text = selectedItem
					toggleOpen()
					if callback then
						pcall(callback, selectedItem, i)
					end
				end)
			end
		end
		renderItems(items)

		selectedBtn.MouseButton1Click:Connect(toggleOpen)

		return {
			card = card,
			Get = function() return selectedItem end,
			Refresh = function(newItems)
				renderItems(newItems)
			end
		}
	end

	-- Button Component (Flexible: 3 to 5 parameters)
	local function addButton(parent, arg2, arg3, arg4, arg5)
		local title, btnText, callback, layoutOrder
		if type(arg3) == "function" then
			title = arg2
			btnText = arg2
			callback = arg3
			layoutOrder = arg4
		else
			title = arg2
			btnText = arg3 or "Execute"
			callback = arg4
			layoutOrder = arg5
		end

		local card = Instance.new("Frame")
		card.Name = "ButtonCard_" .. tostring(title)
		card.Size = UDim2.new(1, 0, 0, 36)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 3
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -120, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.ZIndex = 4
		titleLabel.Parent = card

		local actionBtn = Instance.new("TextButton")
		actionBtn.Name = "ActionBtn"
		actionBtn.Size = UDim2.new(0, 100, 0, 24)
		actionBtn.Position = UDim2.new(1, -110, 0.5, -12)
		actionBtn.BackgroundColor3 = COLORS.accentCyan
		actionBtn.BackgroundTransparency = 0.15
		actionBtn.Text = btnText
		actionBtn.TextColor3 = Color3.fromRGB(10, 14, 26)
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 11
		actionBtn.AutoButtonColor = false
		actionBtn.ZIndex = 4
		actionBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = CORNER.small
		btnCorner.Parent = actionBtn

		actionBtn.MouseButton1Click:Connect(function()
			TweenService:Create(actionBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.4 }):Play()
			task.delay(0.1, function()
				TweenService:Create(actionBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.15 }):Play()
			end)
			if callback then
				pcall(callback)
			end
		end)

		return card
	end

	-- Textbox Input Component
	local function addTextbox(parent, title, placeholder, defaultText, callback, layoutOrder)
		if type(defaultText) == "function" and callback == nil then
			callback = defaultText
			defaultText = ""
		end

		local card = Instance.new("Frame")
		card.Name = "TextboxCard_" .. tostring(title)
		card.Size = UDim2.new(1, 0, 0, 36)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 3
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0, 150, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = card

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -170, 0, 24)
		box.Position = UDim2.new(0, 160, 0.5, -12)
		box.BackgroundColor3 = COLORS.glassSurface
		box.BackgroundTransparency = 0.3
		box.PlaceholderText = placeholder or "Type here..."
		box.PlaceholderColor3 = COLORS.textMuted
		box.Text = tostring(defaultText or "")
		box.TextColor3 = COLORS.textWhite
		box.Font = Enum.Font.Gotham
		box.TextSize = 11
		box.ClearTextOnFocus = false
		box.ZIndex = 4
		box.Parent = card

		applyGlass(box, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		box.FocusLost:Connect(function(enterPressed)
			if callback then
				pcall(callback, box.Text, enterPressed)
			end
		end)

		return card
	end

	-- Label / Status Text Component
	local function addLabel(parent, text, arg3, arg4)
		local col = COLORS.textSecondary
		local layoutOrder = 0

		if typeof(arg3) == "Color3" then
			col = arg3
			layoutOrder = arg4 or 0
		elseif type(arg3) == "string" then
			if arg3 == "success" then col = COLORS.successGreen
			elseif arg3 == "warning" then col = COLORS.warningYellow
			elseif arg3 == "danger" then col = COLORS.dangerRed
			elseif arg3 == "cyan" then col = COLORS.accentCyan end
			layoutOrder = arg4 or 0
		elseif type(arg3) == "number" then
			layoutOrder = arg3
			if typeof(arg4) == "Color3" then col = arg4 end
		end

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 20)
		label.BackgroundTransparency = 1
		label.Text = tostring(text)
		label.TextColor3 = col
		label.Font = Enum.Font.Gotham
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = layoutOrder
		label.ZIndex = 4
		label.Parent = parent

		return {
			label = label,
			Set = function(newText) label.Text = tostring(newText) end
		}
	end

	-- Stats Card Component (Clean Text - No Emojis)
	local function addStatsCard(parent, titleText, initialValue)
		local card = Instance.new("Frame")
		card.Name = "Stat_" .. tostring(titleText)
		card.Size = UDim2.new(0.48, 0, 0, 48)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.ZIndex = 3
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -16, 0, 16)
		title.Position = UDim2.new(0, 10, 0, 6)
		title.BackgroundTransparency = 1
		title.Text = string.upper(tostring(titleText))
		title.TextColor3 = COLORS.textMuted
		title.Font = Enum.Font.GothamBold
		title.TextSize = 9
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 4
		title.Parent = card

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(1, -16, 0, 20)
		val.Position = UDim2.new(0, 10, 0, 22)
		val.BackgroundTransparency = 1
		val.Text = tostring(initialValue or "0")
		val.TextColor3 = COLORS.accentCyan
		val.Font = Enum.Font.GothamBold
		val.TextSize = 13
		val.TextXAlignment = Enum.TextXAlignment.Left
		val.ZIndex = 4
		val.Parent = card

		return {
			card = card,
			valueLabel = val,
			Set = function(newVal) val.Text = tostring(newVal) end
		}
	end

	------------------------------------------------
	-- TOAST NOTIFICATION ENGINE (Clean Text - No Emojis)
	------------------------------------------------
	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "NotificationContainer"
	notifContainer.Size = UDim2.new(0, 260, 1, -40)
	notifContainer.Position = UDim2.new(1, -275, 0, 20)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 100
	notifContainer.Parent = gui

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.Padding = UDim.new(0, 8)
	notifLayout.Parent = notifContainer

	local function notify(title, message, duration, nType)
		duration = duration or 3
		nType = nType or "info"

		local accentCol = COLORS.accentCyan
		local typeTag = "[INFO]"
		if nType == "success" then
			accentCol = COLORS.successGreen
			typeTag = "[OK]"
		elseif nType == "warning" then
			accentCol = COLORS.warningYellow
			typeTag = "[WARN]"
		elseif nType == "error" then
			accentCol = COLORS.dangerRed
			typeTag = "[FAIL]"
		end

		local notifFrame = Instance.new("Frame")
		notifFrame.Size = UDim2.new(1, 0, 0, 52)
		notifFrame.BackgroundColor3 = COLORS.glassPrimary
		notifFrame.BackgroundTransparency = 0.05
		notifFrame.BorderSizePixel = 0
		notifFrame.ZIndex = 101
		notifFrame.Parent = notifContainer

		applyGlass(notifFrame, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = accentCol,
			strokeThickness = 1.2,
			strokeTransparency = 0.4
		})

		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.new(0, 48, 0, 18)
		tagLabel.Position = UDim2.new(0, 10, 0, 8)
		tagLabel.BackgroundColor3 = accentCol
		tagLabel.BackgroundTransparency = 0.2
		tagLabel.Text = typeTag
		tagLabel.TextColor3 = Color3.fromRGB(10, 14, 26)
		tagLabel.Font = Enum.Font.GothamBold
		tagLabel.TextSize = 9
		tagLabel.ZIndex = 102
		tagLabel.Parent = notifFrame

		local tagCorner = Instance.new("UICorner")
		tagCorner.CornerRadius = CORNER.small
		tagCorner.Parent = tagLabel

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -70, 0, 18)
		titleLabel.Position = UDim2.new(0, 64, 0, 8)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textWhite
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		titleLabel.ZIndex = 102
		titleLabel.Parent = notifFrame

		local msgLabel = Instance.new("TextLabel")
		msgLabel.Size = UDim2.new(1, -20, 0, 18)
		msgLabel.Position = UDim2.new(0, 10, 0, 28)
		msgLabel.BackgroundTransparency = 1
		msgLabel.Text = message
		msgLabel.TextColor3 = COLORS.textSecondary
		msgLabel.Font = Enum.Font.Gotham
		msgLabel.TextSize = 10
		msgLabel.TextXAlignment = Enum.TextXAlignment.Left
		msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
		msgLabel.ZIndex = 102
		msgLabel.Parent = notifFrame

		notifFrame.Position = UDim2.new(1, 40, 0, 0)
		TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()

		task.delay(duration, function()
			if notifFrame and notifFrame.Parent then
				local tw = TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
					BackgroundTransparency = 1
				})
				tw:Play()
				tw.Completed:Connect(function()
					notifFrame:Destroy()
				end)
			end
		end)
	end

	------------------------------------------------
	-- INITIALIZE CORE TABS (Clean Text - No Emojis)
	------------------------------------------------
	addTab("Main", "", 1)
	addTab("Farm", "", 2)
	addTab("Vehicle", "", 3)
	addTab("Teleport", "", 4)
	addTab("Visuals", "", 5)
	addTab("Settings", "", 6)

	selectTab("Main")

	------------------------------------------------
	-- EXPORT GLOBAL UI API
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

	notify("HipHub DDS", "Loaded successfully. Welcome " .. player.DisplayName .. "!", 3, "success")
end)

if not success then
	warn("[HipHub DDS UI Error]:", err)
end
