-- HipHub TR Legacy — Liquid Glass Futuristic UI Base
-- Pure UI Layout Base & Component Suite
-- Theme: Glassmorphism / Liquid Glass with Cyan-Violet accents

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
	-- CLEANUP EXISTING INSTANCES
	------------------------------------------------
	local parentGui = (gethui and gethui()) or game:GetService("CoreGui") or player:WaitForChild("PlayerGui")
	local oldGui = parentGui:FindFirstChild("HipHub_TRLegacy") or parentGui:FindFirstChild("HipHub")
	if oldGui then
		pcall(function() oldGui:Destroy() end)
	end

	------------------------------------------------
	-- ️ HELPER FUNCTIONS
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
				ColorSequenceKeypoint.new(0, opts.gradColor1 or COLORS.glassSurface),
				ColorSequenceKeypoint.new(1, opts.gradColor2 or COLORS.glassCard),
			})
			grad.Rotation = opts.gradientRotation or 45
			grad.Parent = frame
		end
	end

	local function applyListLayout(parent, padding, sortOrder)
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, padding or 6)
		layout.Parent = parent
		return layout
	end

	local function applyPadding(parent, top, bottom, left, right)
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, top or 8)
		pad.PaddingBottom = UDim.new(0, bottom or 8)
		pad.PaddingLeft = UDim.new(0, left or 10)
		pad.PaddingRight = UDim.new(0, right or 10)
		pad.Parent = parent
		return pad
	end

	local function sanitizeText(str)
		if type(str) ~= "string" then return tostring(str or "") end
		return str
	end

	local function resolveLayoutOrder(parent, explicitOrder)
		if explicitOrder then return explicitOrder end
		local count = 0
		for _, c in ipairs(parent:GetChildren()) do
			if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
				count = count + 1
			end
		end
		return count + 1
	end

	------------------------------------------------
	-- ️ GUI SETUP
	------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_TRLegacy"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2147483647
	pcall(function() gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
	gui.Parent = parentGui

	local defaultWidth = 580
	local defaultHeight = 400

	-- Shadow Backing
	local shadowFrame = Instance.new("Frame")
	shadowFrame.Name = "ShadowBacking"
	shadowFrame.Size = UDim2.new(0, defaultWidth + 16, 0, defaultHeight + 16)
	shadowFrame.Position = UDim2.new(0.5, -(defaultWidth + 16) / 2, 0.5, -(defaultHeight + 16) / 2)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.45
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 0
	shadowFrame.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 18)
	shadowCorner.Parent = shadowFrame

	-- Main Panel
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)
	mainFrame.Position = UDim2.new(0.5, -defaultWidth / 2, 0.5, -defaultHeight / 2)
	mainFrame.BackgroundColor3 = COLORS.glassPrimary
	mainFrame.BackgroundTransparency = TRANSPARENCY.glassMain
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
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
		if not shadowFrame or not mainFrame then return end
		shadowFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 8,
			mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 8
		)
		shadowFrame.Size = UDim2.new(
			mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 16,
			mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 16
		)
	end
	syncShadow()

	-- Animated Border Accent
	local mainStroke = mainFrame:FindFirstChildOfClass("UIStroke")
	if mainStroke then
		task.spawn(function()
			while mainFrame and mainFrame.Parent do
				TweenService:Create(mainStroke, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentViolet
				}):Play()
				task.wait(2.8)
				TweenService:Create(mainStroke, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Color = COLORS.accentCyan
				}):Play()
				task.wait(2.8)
			end
		end)
	end

	------------------------------------------------
	-- TOP BAR
	------------------------------------------------
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 42)
	topBar.BackgroundColor3 = COLORS.glassSurface
	topBar.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 2
	topBar.Parent = mainFrame

	applyGlass(topBar, { corner = CORNER.large })

	local topBarCover = Instance.new("Frame")
	topBarCover.Size = UDim2.new(1, 0, 0, 14)
	topBarCover.Position = UDim2.new(0, 0, 1, -14)
	topBarCover.BackgroundColor3 = COLORS.glassSurface
	topBarCover.BackgroundTransparency = TRANSPARENCY.glassTopBar
	topBarCover.BorderSizePixel = 0
	topBarCover.ZIndex = 2
	topBarCover.Parent = topBar

	local topBarAccent = Instance.new("Frame")
	topBarAccent.Size = UDim2.new(1, -24, 0, 1)
	topBarAccent.Position = UDim2.new(0, 12, 1, -1)
	topBarAccent.BackgroundColor3 = COLORS.accentCyan
	topBarAccent.BackgroundTransparency = 0.5
	topBarAccent.BorderSizePixel = 0
	topBarAccent.ZIndex = 3
	topBarAccent.Parent = topBar

	local accentGrad = Instance.new("UIGradient")
	accentGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.accentCyan),
		ColorSequenceKeypoint.new(0.5, COLORS.accentViolet),
		ColorSequenceKeypoint.new(1, COLORS.accentCyan),
	})
	accentGrad.Parent = topBarAccent

	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size = UDim2.new(0, 72, 1, 0)
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
	badge.Size = UDim2.new(0, 95, 0, 20)
	badge.Position = UDim2.new(0, 88, 0.5, -10)
	badge.BackgroundColor3 = COLORS.accentViolet
	badge.BackgroundTransparency = 0.35
	badge.Text = "TR Legacy"
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
		shadowFrame.Visible = false
	end)

	local isFullscreen = false
	local origSize = mainFrame.Size
	local origPos = mainFrame.Position

	local fullscreenButton = Instance.new("TextButton")
	fullscreenButton.Name = "FullscreenBtn"
	fullscreenButton.Size = UDim2.new(0, 30, 0, 30)
	fullscreenButton.Position = UDim2.new(1, -70, 0.5, -15)
	fullscreenButton.BackgroundTransparency = 1
	fullscreenButton.Text = "□"
	fullscreenButton.TextColor3 = COLORS.textSecondary
	fullscreenButton.Font = Enum.Font.GothamBold
	fullscreenButton.TextSize = 14
	fullscreenButton.ZIndex = 3
	fullscreenButton.Parent = topBar

	fullscreenButton.MouseEnter:Connect(function()
		TweenService:Create(fullscreenButton, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
	end)
	fullscreenButton.MouseLeave:Connect(function()
		TweenService:Create(fullscreenButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
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
	-- SIDEBAR
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 140, 1, -42)
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

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 1, -62)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 2
	tabContainer.Parent = sidebar

	applyListLayout(tabContainer, 3)
	applyPadding(tabContainer, 8, 8, 8, 8)

	-- Profile Mini-Card at bottom of sidebar
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
		strokeTransparency = 0.75
	})

	local avatarLabel = Instance.new("ImageLabel")
	avatarLabel.Size = UDim2.new(0, 26, 0, 26)
	avatarLabel.Position = UDim2.new(0, 6, 0.5, -13)
	avatarLabel.BackgroundColor3 = COLORS.glassHover
	avatarLabel.BorderSizePixel = 0
	avatarLabel.ZIndex = 3
	avatarLabel.Parent = profileCard

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = CORNER.pill
	avatarCorner.Parent = avatarLabel

	pcall(function()
		local thumb = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if thumb then avatarLabel.Image = thumb end
	end)

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "Username"
	usernameLabel.Size = UDim2.new(1, -40, 1, 0)
	usernameLabel.Position = UDim2.new(0, 36, 0, 0)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = player.DisplayName or player.Name
	usernameLabel.TextColor3 = COLORS.textPrimary
	usernameLabel.Font = Enum.Font.GothamMedium
	usernameLabel.TextSize = 10
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.ZIndex = 3
	usernameLabel.Parent = profileCard

	------------------------------------------------
	-- ️ CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -140, 1, -42)
	contentArea.Position = UDim2.new(0, 140, 0, 42)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 1
	contentArea.Parent = mainFrame
	contentAreaInstance = contentArea

	------------------------------------------------
	-- TAB SYSTEM
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

		applyPadding(frame, 12, 12, 12, 12)
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
		button.Size = UDim2.new(1, 0, 0, 30)
		button.BackgroundColor3 = COLORS.glassSurface
		button.BackgroundTransparency = 1
		button.BorderSizePixel = 0
		button.ZIndex = 3
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
	-- COMPONENT BUILDERS
	------------------------------------------------

	-- Section Header & Container
	local function addSection(parent, title, layoutOrder)
		local cleanTitle = sanitizeText(title)

		local sectionContainer = Instance.new("Frame")
		sectionContainer.Name = "Section_" .. cleanTitle:gsub("%s+", "")
		sectionContainer.Size = UDim2.new(1, 0, 0, 0)
		sectionContainer.AutomaticSize = Enum.AutomaticSize.Y
		sectionContainer.BackgroundTransparency = 1
		sectionContainer.BorderSizePixel = 0
		sectionContainer.LayoutOrder = resolveLayoutOrder(parent, layoutOrder)
		sectionContainer.ZIndex = 3
		sectionContainer.Parent = parent

		applyListLayout(sectionContainer, 6, Enum.SortOrder.LayoutOrder)
		applyPadding(sectionContainer, 0, 0, 2, 6)

		local headerFrame = Instance.new("Frame")
		headerFrame.Name = "SectionHeader"
		headerFrame.Size = UDim2.new(1, 0, 0, 24)
		headerFrame.BackgroundTransparency = 1
		headerFrame.BorderSizePixel = 0
		headerFrame.LayoutOrder = -9999
		headerFrame.ZIndex = 4
		headerFrame.Parent = sectionContainer

		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 3, 0, 14)
		accentBar.Position = UDim2.new(0, 2, 0.5, -7)
		accentBar.BackgroundColor3 = COLORS.accentCyan
		accentBar.BorderSizePixel = 0
		accentBar.ZIndex = 4
		accentBar.Parent = headerFrame

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 2)
		accentCorner.Parent = accentBar

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -20, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = cleanTitle
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = headerFrame

		return sectionContainer
	end

	-- Toggle Switch
	local function addToggle(parent, label, default, callback, layoutOrder)
		local cleanLabel = sanitizeText(label)
		local state = default or false

		local container = Instance.new("TextButton")
		container.Name = "Toggle_" .. cleanLabel:gsub("%s+", "")
		container.Size = UDim2.new(1, 0, 0, 36)
		container.BackgroundColor3 = COLORS.glassCard
		container.BackgroundTransparency = TRANSPARENCY.glassCard
		container.BorderSizePixel = 0
		container.Text = ""
		container.AutoButtonColor = false
		container.LayoutOrder = resolveLayoutOrder(parent, layoutOrder)
		container.ZIndex = 3
		container.Parent = parent

		applyGlass(container, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -64, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = cleanLabel
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = container

		local track = Instance.new("Frame")
		track.Size = UDim2.new(0, 38, 0, 20)
		track.Position = UDim2.new(1, -48, 0.5, -10)
		track.BackgroundColor3 = state and COLORS.toggleOn or COLORS.toggleOff
		track.BorderSizePixel = 0
		track.ZIndex = 4
		track.Parent = container

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = track

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.new(0, 16, 0, 16)
		thumb.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
		thumb.BackgroundColor3 = COLORS.textWhite
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 5
		thumb.Parent = track

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = CORNER.pill
		thumbCorner.Parent = thumb

		local function updateToggle(anim)
			local dur = anim and 0.18 or 0
			local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
			local targetTrackCol = state and COLORS.toggleOn or COLORS.toggleOff
			if dur > 0 then
				TweenService:Create(thumb, TweenInfo.new(dur, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
				TweenService:Create(track, TweenInfo.new(dur, Enum.EasingStyle.Quad), { BackgroundColor3 = targetTrackCol }):Play()
			else
				thumb.Position = targetPos
				track.BackgroundColor3 = targetTrackCol
			end
		end

		local function setVal(newVal)
			state = newVal
			updateToggle(true)
			if callback then
				pcall(callback, state)
			end
		end

		container.MouseButton1Click:Connect(function()
			setVal(not state)
		end)

		local proxy = setmetatable({
			container = container,
			Get = function() return state end,
			Set = function(newVal)
				state = newVal
				updateToggle(true)
				if callback then pcall(callback, state) end
			end
		}, {
			__index = function(t, k) return container[k] end,
			__newindex = function(t, k, v) container[k] = v end
		})

		return proxy
	end

	-- Slider Control (Universal Flexible Signature + Large Click/Drag Hitbox)
	local function addSlider(parent, label, minVal, maxVal, defaultVal, arg6, arg7, arg8, arg9)
		local cleanLabel = sanitizeText(label)
		minVal = minVal or 0
		maxVal = maxVal or 100

		-- Resolve arguments flexibly:
		local callback = nil
		local step = 1
		local unit = ""
		local layoutOrder = nil

		if type(arg6) == "function" then
			callback = arg6
			step = (type(arg7) == "number" and arg7 > 0) and arg7 or 1
			unit = type(arg8) == "string" and arg8 or ""
			layoutOrder = type(arg9) == "number" and arg9 or nil
		elseif type(arg7) == "function" then
			step = (type(arg6) == "number" and arg6 > 0) and arg6 or 1
			callback = arg7
			unit = type(arg8) == "string" and arg8 or ""
			layoutOrder = type(arg9) == "number" and arg9 or nil
		elseif type(arg8) == "function" then
			step = (type(arg6) == "number" and arg6 > 0) and arg6 or 1
			unit = type(arg7) == "string" and arg7 or ""
			callback = arg8
			layoutOrder = type(arg9) == "number" and arg9 or nil
		else
			step = (type(arg6) == "number" and arg6 > 0) and arg6 or 1
			unit = type(arg7) == "string" and arg7 or ""
			layoutOrder = type(arg8) == "number" and arg8 or nil
		end

		local current = math.clamp(defaultVal or minVal, minVal, maxVal)

		local container = Instance.new("Frame")
		container.Name = "Slider_" .. cleanLabel:gsub("%s+", "")
		container.Size = UDim2.new(1, 0, 0, 50)
		container.BackgroundColor3 = COLORS.glassCard
		container.BackgroundTransparency = TRANSPARENCY.glassCard
		container.BorderSizePixel = 0
		container.LayoutOrder = resolveLayoutOrder(parent, layoutOrder)
		container.ZIndex = 3
		container.Parent = parent

		applyGlass(container, {
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
		titleLabel.Text = cleanLabel
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = container

		local valBadge = Instance.new("TextLabel")
		valBadge.Size = UDim2.new(0, 76, 0, 18)
		valBadge.Position = UDim2.new(1, -88, 0, 6)
		valBadge.BackgroundColor3 = COLORS.glassSurface
		valBadge.BackgroundTransparency = 0.3
		valBadge.Text = tostring(current) .. unit
		valBadge.TextColor3 = COLORS.accentCyan
		valBadge.Font = Enum.Font.GothamBold
		valBadge.TextSize = 11
		valBadge.TextXAlignment = Enum.TextXAlignment.Center
		valBadge.ZIndex = 4
		valBadge.Parent = container

		applyGlass(valBadge, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		local track = Instance.new("Frame")
		track.Name = "SliderTrack"
		track.Size = UDim2.new(1, -24, 0, 6)
		track.Position = UDim2.new(0, 12, 0, 33)
		track.BackgroundColor3 = COLORS.glassHover
		track.BorderSizePixel = 0
		track.ZIndex = 4
		track.Parent = container

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = track

		local fill = Instance.new("Frame")
		fill.Name = "SliderFill"
		local pct = math.clamp((current - minVal) / math.max(1, maxVal - minVal), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		fill.BackgroundColor3 = COLORS.accentCyan
		fill.BorderSizePixel = 0
		fill.ZIndex = 5
		fill.Parent = track

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = CORNER.pill
		fillCorner.Parent = fill

		local thumb = Instance.new("Frame")
		thumb.Name = "SliderThumb"
		thumb.Size = UDim2.new(0, 14, 0, 14)
		thumb.Position = UDim2.new(pct, -7, 0.5, -7)
		thumb.BackgroundColor3 = COLORS.textWhite
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 6
		thumb.Parent = track

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = CORNER.pill
		thumbCorner.Parent = thumb

		-- Large interactive click/drag button across the entire track area
		local hitButton = Instance.new("TextButton")
		hitButton.Name = "SliderHitArea"
		hitButton.Size = UDim2.new(1, 0, 1, 20)
		hitButton.Position = UDim2.new(0, 0, 0, -10)
		hitButton.BackgroundTransparency = 1
		hitButton.Text = ""
		hitButton.AutoButtonColor = false
		hitButton.ZIndex = 8
		hitButton.Active = true
		hitButton.Parent = track

		local dragging = false

		local function updateFromPos(posX)
			local absPos = track.AbsolutePosition.X
			local absSize = track.AbsoluteSize.X
			if absSize <= 0 then return end
			local ratio = math.clamp((posX - absPos) / absSize, 0, 1)
			local rawVal = minVal + (maxVal - minVal) * ratio
			local stepped
			if step and step > 0 then
				stepped = math.floor((rawVal / step) + 0.5) * step
			else
				stepped = rawVal
			end
			current = math.clamp(stepped, minVal, maxVal)

			local fillRatio = (current - minVal) / math.max(1, maxVal - minVal)
			fill.Size = UDim2.new(fillRatio, 0, 1, 0)
			thumb.Position = UDim2.new(fillRatio, -7, 0.5, -7)
			valBadge.Text = tostring(current) .. unit

			if callback then
				pcall(callback, current)
			end
		end

		hitButton.MouseButton1Down:Connect(function()
			dragging = true
			local mousePos = UserInputService:GetMouseLocation()
			updateFromPos(mousePos.X)
		end)

		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromPos(input.Position.X)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		local proxy = setmetatable({
			container = container,
			card = container,
			Get = function() return current end,
			Set = function(val)
				current = math.clamp(val, minVal, maxVal)
				local fillRatio = (current - minVal) / math.max(1, maxVal - minVal)
				fill.Size = UDim2.new(fillRatio, 0, 1, 0)
				thumb.Position = UDim2.new(fillRatio, -7, 0.5, -7)
				valBadge.Text = tostring(current) .. unit
				if callback then pcall(callback, current) end
			end
		}, {
			__index = function(t, k) return container[k] end,
			__newindex = function(t, k, v) container[k] = v end
		})

		return proxy
	end

	-- Dropdown Selector (with Interactive Search Bar & Dynamic Filtering)
	local function addDropdown(parent, label, options, default, callback, layoutOrder)
		local cleanLabel = sanitizeText(label)
		options = options or {}
		local selected = default or (options[1] or "")
		local isOpen = false
		local currentFilter = ""

		local container = Instance.new("Frame")
		container.Name = "Dropdown_" .. cleanLabel:gsub("%s+", "")
		container.Size = UDim2.new(1, 0, 0, 36)
		container.BackgroundColor3 = COLORS.glassCard
		container.BackgroundTransparency = TRANSPARENCY.glassCard
		container.BorderSizePixel = 0
		container.ClipsDescendants = true
		container.LayoutOrder = resolveLayoutOrder(parent, layoutOrder)
		container.ZIndex = 10
		container.Parent = parent

		applyGlass(container, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75
		})

		local headerBtn = Instance.new("TextButton")
		headerBtn.Size = UDim2.new(1, 0, 0, 36)
		headerBtn.BackgroundTransparency = 1
		headerBtn.Text = ""
		headerBtn.ZIndex = 11
		headerBtn.Parent = container

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(0.42, 0, 1, 0)
		titleLabel.Position = UDim2.new(0, 12, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = cleanLabel
		titleLabel.TextColor3 = COLORS.textPrimary
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 12
		titleLabel.Parent = headerBtn

		local selectedLabel = Instance.new("TextLabel")
		selectedLabel.Size = UDim2.new(0.53, -40, 1, 0)
		selectedLabel.Position = UDim2.new(0.42, 0, 0, 0)
		selectedLabel.BackgroundTransparency = 1
		selectedLabel.Text = tostring(selected)
		selectedLabel.TextColor3 = COLORS.accentCyan
		selectedLabel.Font = Enum.Font.GothamBold
		selectedLabel.TextSize = 11
		selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
		selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
		selectedLabel.ZIndex = 12
		selectedLabel.Parent = headerBtn

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 20, 1, 0)
		arrow.Position = UDim2.new(1, -26, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "▼"
		arrow.TextColor3 = COLORS.textSecondary
		arrow.Font = Enum.Font.Gotham
		arrow.TextSize = 9
		arrow.ZIndex = 12
		arrow.Parent = headerBtn

		-- Search Bar Container
		local searchFrame = Instance.new("Frame")
		searchFrame.Size = UDim2.new(1, -12, 0, 28)
		searchFrame.Position = UDim2.new(0, 6, 0, 38)
		searchFrame.BackgroundColor3 = COLORS.glassSurface
		searchFrame.BackgroundTransparency = 0.2
		searchFrame.BorderSizePixel = 0
		searchFrame.Visible = false
		searchFrame.ZIndex = 14
		searchFrame.Parent = container

		applyGlass(searchFrame, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.accentBlend,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})

		local searchBox = Instance.new("TextBox")
		searchBox.Size = UDim2.new(1, -12, 1, 0)
		searchBox.Position = UDim2.new(0, 6, 0, 0)
		searchBox.BackgroundTransparency = 1
		searchBox.Text = ""
		searchBox.PlaceholderText = "Cari nama motor..."
		searchBox.PlaceholderColor3 = COLORS.textMuted
		searchBox.TextColor3 = COLORS.textWhite
		searchBox.Font = Enum.Font.GothamMedium
		searchBox.TextSize = 10
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.ClearTextOnFocus = false
		searchBox.ZIndex = 15
		searchBox.Parent = searchFrame

		local optionsFrame = Instance.new("ScrollingFrame")
		optionsFrame.Size = UDim2.new(1, -12, 0, 140)
		optionsFrame.Position = UDim2.new(0, 6, 0, 70)
		optionsFrame.BackgroundColor3 = COLORS.glassSurface
		optionsFrame.BackgroundTransparency = 0.1
		optionsFrame.BorderSizePixel = 0
		optionsFrame.ScrollBarThickness = 3
		optionsFrame.ScrollBarImageColor3 = COLORS.accentCyan
		optionsFrame.Visible = false
		optionsFrame.ZIndex = 15
		optionsFrame.Parent = container

		applyGlass(optionsFrame, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.accentCyan,
			strokeThickness = 1,
			strokeTransparency = 0.5
		})
		applyListLayout(optionsFrame, 2)
		applyPadding(optionsFrame, 4, 4, 4, 4)

		local function rebuildOptions(filter)
			filter = filter or currentFilter or ""
			currentFilter = filter
			local lowerFilter = filter:lower()

			for _, c in ipairs(optionsFrame:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end

			local matchCount = 0
			for _, opt in ipairs(options) do
				local strOpt = tostring(opt)
				if lowerFilter == "" or strOpt:lower():find(lowerFilter, 1, true) then
					matchCount = matchCount + 1
					local optBtn = Instance.new("TextButton")
					optBtn.Size = UDim2.new(1, 0, 0, 26)
					optBtn.BackgroundColor3 = opt == selected and COLORS.glassActive or COLORS.glassCard
					optBtn.BackgroundTransparency = opt == selected and 0.2 or 0.6
					optBtn.Text = "  " .. strOpt
					optBtn.TextColor3 = opt == selected and COLORS.accentCyan or COLORS.textPrimary
					optBtn.Font = Enum.Font.GothamMedium
					optBtn.TextSize = 10
					optBtn.TextXAlignment = Enum.TextXAlignment.Left
					optBtn.TextTruncate = Enum.TextTruncate.AtEnd
					optBtn.ZIndex = 16
					optBtn.Parent = optionsFrame

					local optCorner = Instance.new("UICorner")
					optCorner.CornerRadius = CORNER.small
					optCorner.Parent = optBtn

					optBtn.MouseButton1Click:Connect(function()
						selected = opt
						selectedLabel.Text = strOpt
						isOpen = false
						searchFrame.Visible = false
						optionsFrame.Visible = false
						container.Size = UDim2.new(1, 0, 0, 36)
						arrow.Text = "▼"
						if callback then
							pcall(callback, selected)
						end
					end)
				end
			end
			optionsFrame.CanvasSize = UDim2.new(0, 0, 0, matchCount * 28 + 8)
		end

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			rebuildOptions(searchBox.Text)
		end)

		rebuildOptions()

		headerBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			if isOpen then
				searchBox.Text = ""
				rebuildOptions("")
				searchFrame.Visible = true
				optionsFrame.Visible = true
				container.Size = UDim2.new(1, 0, 0, 218)
				arrow.Text = "▲"
			else
				searchFrame.Visible = false
				optionsFrame.Visible = false
				container.Size = UDim2.new(1, 0, 0, 36)
				arrow.Text = "▼"
			end
		end)

		local proxy = setmetatable({
			container = container,
			Get = function() return selected end,
			Set = function(val)
				selected = val
				selectedLabel.Text = tostring(val)
				if callback then pcall(callback, val) end
			end,
			SetOptions = function(newOpts)
				options = newOpts or {}
				rebuildOptions()
			end
		}, {
			__index = function(t, k) return container[k] end,
			__newindex = function(t, k, v) container[k] = v end
		})

		return proxy
	end

	-- Push Button
	local function addButton(parent, text, callback, layoutOrder, style)
		local cleanText = sanitizeText(text)
		local btnBg = COLORS.glassCard
		local btnFg = COLORS.textWhite
		local strokeCol = COLORS.accentCyan
		local strokeTrans = 0.55
		local bgTrans = 0.2

		if style == "primary" then
			btnBg = COLORS.glassHover
			btnFg = COLORS.textWhite
			strokeCol = COLORS.accentCyan
			strokeTrans = 0.35
			bgTrans = 0.1
		elseif style == "secondary" then
			btnBg = COLORS.glassCard
			btnFg = COLORS.textWhite
			strokeCol = COLORS.borderGlass
			strokeTrans = 0.75
			bgTrans = 0.25
		elseif style == "danger" then
			btnBg = COLORS.dangerRed
			btnFg = COLORS.textWhite
			strokeCol = COLORS.dangerRed
			strokeTrans = 0.4
			bgTrans = 0.15
		elseif style == "success" then
			btnBg = COLORS.successGreen
			btnFg = COLORS.textWhite
			strokeCol = COLORS.successGreen
			strokeTrans = 0.4
			bgTrans = 0.15
		else
			btnBg = COLORS.glassCard
			btnFg = COLORS.textWhite
			strokeCol = COLORS.borderGlass
			strokeTrans = 0.65
			bgTrans = 0.2
		end

		local button = Instance.new("TextButton")
		button.Name = "Btn_" .. cleanText:gsub("%s+", "")
		button.Size = UDim2.new(1, 0, 0, 32)
		button.BackgroundColor3 = btnBg
		button.BackgroundTransparency = bgTrans
		button.Text = cleanText
		button.TextColor3 = COLORS.textWhite
		button.Font = Enum.Font.GothamBold
		button.TextSize = 11
		button.LayoutOrder = resolveLayoutOrder(parent, layoutOrder)
		button.ZIndex = 3
		button.Parent = parent

		applyGlass(button, {
			corner = CORNER.small,
			color = btnBg,
			transparency = bgTrans,
			stroke = true,
			strokeColor = strokeCol,
			strokeThickness = 1,
			strokeTransparency = strokeTrans
		})

		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = COLORS.glassHover, BackgroundTransparency = 0.1 }):Play()
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = btnBg, BackgroundTransparency = bgTrans }):Play()
		end)

		button.MouseButton1Click:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.08), { BackgroundTransparency = 0.4 }):Play()
			task.delay(0.1, function()
				if button and button.Parent then
					TweenService:Create(button, TweenInfo.new(0.12), { BackgroundTransparency = bgTrans }):Play()
				end
			end)
			if callback then
				pcall(callback)
			end
		end)

		return button
	end

	-- Text Label Item
	local function addLabel(parent, text, color, layoutOrder)
		local cleanText = sanitizeText(text)

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 0, 20)
		label.BackgroundTransparency = 1
		label.Text = cleanText
		label.TextColor3 = color or COLORS.textSecondary
		label.Font = Enum.Font.Gotham
		label.TextSize = 10
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextWrapped = true
		label.LayoutOrder = resolveLayoutOrder(parent, layoutOrder)
		label.ZIndex = 3
		label.Parent = parent

		return label
	end

	-- Status Display Card
	local function addStatsCard(parent, title, initialValue, layoutOrder)
		local cleanTitle = sanitizeText(title)

		local card = Instance.new("Frame")
		card.Name = "StatCard_" .. cleanTitle:gsub("%s+", "")
		card.Size = UDim2.new(1, 0, 0, 44)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = resolveLayoutOrder(parent, layoutOrder)
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
		titleLabel.Size = UDim2.new(1, -16, 0, 16)
		titleLabel.Position = UDim2.new(0, 10, 0, 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = string.upper(cleanTitle)
		titleLabel.TextColor3 = COLORS.textMuted
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 9
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 4
		titleLabel.Parent = card

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(1, -16, 0, 20)
		val.Position = UDim2.new(0, 10, 0, 20)
		val.BackgroundTransparency = 1
		val.Text = sanitizeText(tostring(initialValue or "0"))
		val.TextColor3 = COLORS.accentCyan
		val.Font = Enum.Font.GothamBold
		val.TextSize = 12
		val.TextXAlignment = Enum.TextXAlignment.Left
		val.ZIndex = 4
		val.Parent = card

		local proxy = setmetatable({
			card = card,
			valueLabel = val,
			Set = function(newVal) val.Text = sanitizeText(tostring(newVal)) end
		}, {
			__index = function(t, k) return card[k] end,
			__newindex = function(t, k, v) card[k] = v end
		})

		return proxy
	end

	------------------------------------------------
	-- TOAST NOTIFICATIONS
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
		title = sanitizeText(title)
		message = sanitizeText(message)
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
		notifFrame.Size = UDim2.new(1, 0, 0, 50)
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
		tagLabel.Size = UDim2.new(0, 44, 0, 16)
		tagLabel.Position = UDim2.new(0, 8, 0, 7)
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
		titleLabel.Size = UDim2.new(1, -66, 0, 16)
		titleLabel.Position = UDim2.new(0, 58, 0, 7)
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
		msgLabel.Size = UDim2.new(1, -16, 0, 18)
		msgLabel.Position = UDim2.new(0, 8, 0, 26)
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
		TweenService:Create(notifFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()

		task.delay(duration, function()
			if notifFrame and notifFrame.Parent then
				local tw = TweenService:Create(notifFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
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
	-- REGISTER CORE TABS
	------------------------------------------------
	addTab("Main", "", 1)
	addTab("Farm", "", 2)
	addTab("Vehicle", "", 3)
	addTab("Teleport", "", 4)
	addTab("Visuals", "", 5)
	addTab("Settings", "", 6)

	selectTab("Main")

	local TabsProxy = setmetatable({}, {
		__index = function(_, k)
			local t = tabs[k]
			return t and (t.Frame or t)
		end
	})

	------------------------------------------------
	-- EXPORT GLOBAL UI API
	------------------------------------------------
	_G.HipHubUI = {
		gui = gui,
		mainFrame = mainFrame,
		MainFrame = mainFrame,
		shadowFrame = shadowFrame,
		topBar = topBar,
		sidebar = sidebar,
		closeButton = closeButton,
		minimizeButton = minimizeButton,
		fullscreenButton = fullscreenButton,
		contentArea = contentArea,
		tabs = tabs,
		Tabs = TabsProxy,
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
		AddLabel = addLabel,
		AddStatsCard = addStatsCard,
		Notify = notify,
		SyncShadow = syncShadow
	}

	notify("HipHub TR Legacy", "Loaded successfully. Welcome " .. player.DisplayName .. "!", 3, "success")
end)

if not success then
	warn("[HipHub TR Legacy UI Error]:", err)
end
