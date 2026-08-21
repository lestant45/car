-- 🌐 HipHub — Liquid Glass Futuristic UI Base (Car Driving Indonesia)
-- Pure UI Layout Base & Component Library
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
	-- Pre-loader optimization check
	pcall(function()
		local HttpService = game:GetService("HttpService")
		local file = "HipHub/cdid_config.json"
		if isfile and not isfile(file) then
			file = "cdid_config.json"
		end
		if isfile and isfile(file) and readfile then
			local configData = HttpService:JSONDecode(readfile(file))
			if configData and configData.misc then
				local misc = configData.misc
				if misc.blackScreenEnabled == true then
					pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(false) end)
				end
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
	-- 🧹 CLEANUP EXISTING INSTANCES
	------------------------------------------------
	local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub_CDID") or player.PlayerGui:FindFirstChild("HipHub")
	if oldGui then
		oldGui:Destroy()
	end

	------------------------------------------------
	-- 🛠️ HELPER FUNCTIONS
	------------------------------------------------
	local function applyGlass(frame, opts)
		opts = opts or {}
		local corner = Instance.new("UICorner")
		corner.CornerRadius = opts.corner or CORNER.medium
		corner.Parent = frame

		if opts.stroke then
			local stroke = Instance.new("UIStroke")
			stroke.Color = opts.strokeColor or COLORS.borderGlass
			stroke.Thickness = opts.strokeThickness or 1
			stroke.Transparency = opts.strokeTransparency or TRANSPARENCY.border
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
			grad.Rotation = opts.gradientRotation or 135
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
	end

	local function applyListLayout(parent, padding, sortOrder)
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, padding or 6)
		layout.Parent = parent
		return layout
	end

	------------------------------------------------
	-- 🖥️ GUI ROOT SETUP
	------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub_CDID"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2147483647
	pcall(function()
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end)
	gui.Parent = player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- 🌑 SHADOW BACKING
	------------------------------------------------
	local shadowFrame = Instance.new("Frame")
	shadowFrame.Size = UDim2.new(0, 622, 0, 422)
	shadowFrame.Position = UDim2.new(0.5, -311, 0.5, -211)
	shadowFrame.BackgroundColor3 = COLORS.shadow
	shadowFrame.BackgroundTransparency = 0.45
	shadowFrame.BorderSizePixel = 0
	shadowFrame.ZIndex = 0
	shadowFrame.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 18)
	shadowCorner.Parent = shadowFrame

	------------------------------------------------
	-- 🖼️ MAIN FRAME (Glass Panel)
	------------------------------------------------
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 610, 0, 410)
	mainFrame.Position = UDim2.new(0.5, -305, 0.5, -205)
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
		shadowFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 6,
			mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 6
		)
		shadowFrame.Size = UDim2.new(
			mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 12,
			mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 12
		)
	end
	syncShadow()

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

	------------------------------------------------
	-- 📌 TOP BAR
	------------------------------------------------
	local topBar = Instance.new("Frame")
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
	topBarAccent.Size = UDim2.new(1, 0, 0, 1)
	topBarAccent.Position = UDim2.new(0, 0, 1, -1)
	topBarAccent.BackgroundColor3 = COLORS.accentCyan
	topBarAccent.BackgroundTransparency = 0.7
	topBarAccent.BorderSizePixel = 0
	topBarAccent.ZIndex = 3
	topBarAccent.Parent = topBar

	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size = UDim2.new(0, 80, 1, 0)
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
	badge.Size = UDim2.new(0, 175, 0, 22)
	badge.Position = UDim2.new(0, 86, 0.5, -11)
	badge.BackgroundColor3 = COLORS.accentViolet
	badge.BackgroundTransparency = 0.25
	badge.Text = "Car Driving Indonesia"
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

	-- Window action buttons
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -38, 0.5, -15)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "✕"
	closeButton.TextColor3 = COLORS.textSecondary
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 14
	closeButton.ZIndex = 3
	closeButton.Parent = topBar

	local fullscreenButton = Instance.new("TextButton")
	fullscreenButton.Size = UDim2.new(0, 30, 0, 30)
	fullscreenButton.Position = UDim2.new(1, -70, 0.5, -15)
	fullscreenButton.BackgroundTransparency = 1
	fullscreenButton.Text = "🗖"
	fullscreenButton.TextColor3 = COLORS.textSecondary
	fullscreenButton.Font = Enum.Font.GothamBold
	fullscreenButton.TextSize = 14
	fullscreenButton.ZIndex = 3
	fullscreenButton.Parent = topBar

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Size = UDim2.new(0, 30, 0, 30)
	minimizeButton.Position = UDim2.new(1, -102, 0.5, -15)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "—"
	minimizeButton.TextColor3 = COLORS.textSecondary
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 14
	minimizeButton.ZIndex = 3
	minimizeButton.Parent = topBar

	pcall(function()
		closeButton.MouseEnter:Connect(function()
			TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 80, 80) }):Play()
		end)
		closeButton.MouseLeave:Connect(function()
			TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
		end)
		minimizeButton.MouseEnter:Connect(function()
			TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
		end)
		minimizeButton.MouseLeave:Connect(function()
			TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
		end)
	end)

	------------------------------------------------
	-- 📂 SIDEBAR
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 145, 1, -42)
	sidebar.Position = UDim2.new(0, 0, 0, 42)
	sidebar.BackgroundColor3 = COLORS.glassSurface
	sidebar.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 1
	sidebar.Parent = mainFrame

	applyGlass(sidebar, { corner = CORNER.large })

	local sidebarCover = Instance.new("Frame")
	sidebarCover.Size = UDim2.new(0, 14, 1, 0)
	sidebarCover.Position = UDim2.new(1, -14, 0, 0)
	sidebarCover.BackgroundColor3 = COLORS.glassSurface
	sidebarCover.BackgroundTransparency = TRANSPARENCY.glassSidebar
	sidebarCover.BorderSizePixel = 0
	sidebarCover.ZIndex = 1
	sidebarCover.Parent = sidebar

	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, 0, 1, -54)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 2
	tabContainer.Parent = sidebar

	applyListLayout(tabContainer, 3)
	applyPadding(tabContainer, 6, 6, 8, 0)

	-- Profile Card
	local profileCard = Instance.new("Frame")
	profileCard.Size = UDim2.new(1, -12, 0, 42)
	profileCard.Position = UDim2.new(0, 6, 1, -48)
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
	avatarLabel.Size = UDim2.new(0, 28, 0, 28)
	avatarLabel.Position = UDim2.new(0, 6, 0.5, -14)
	avatarLabel.BackgroundColor3 = COLORS.glassHover
	avatarLabel.BorderSizePixel = 0
	avatarLabel.ZIndex = 3
	avatarLabel.Parent = profileCard

	pcall(function()
		local content = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		avatarLabel.Image = content
	end)

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = CORNER.pill
	avatarCorner.Parent = avatarLabel

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Size = UDim2.new(1, -42, 1, 0)
	usernameLabel.Position = UDim2.new(0, 38, 0, 0)
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
	-- 🖥️ CONTENT AREA
	------------------------------------------------
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -145, 1, -42)
	contentArea.Position = UDim2.new(0, 145, 0, 42)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 1
	contentArea.Parent = mainFrame

	------------------------------------------------
	-- 📑 TAB MANAGEMENT SYSTEM
	------------------------------------------------
	local tabs = {}
	local activeTab = nil

	local function createTabContent(name)
		local frame = Instance.new("ScrollingFrame")
		frame.Name = name .. "TabContent"
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.ScrollBarThickness = 4
		frame.ScrollBarImageColor3 = COLORS.accentCyan
		frame.ScrollBarImageTransparency = 0.4
		frame.CanvasSize = UDim2.new(0, 0, 0, 0)
		frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		frame.ClipsDescendants = true
		frame.Visible = false
		frame.ZIndex = 2
		frame.Parent = contentArea

		applyPadding(frame, 12, 12, 12, 12)
		applyListLayout(frame, 8)

		return frame
	end

	local function selectTab(tabName)
		for name, data in pairs(tabs) do
			if name == tabName then
				data.Frame.Visible = true
				if data.Button then
					TweenService:Create(data.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = COLORS.glassActive,
						BackgroundTransparency = 0.15,
					}):Play()
					data.Button.TextColor3 = COLORS.textWhite
				end
				if data.Indicator then
					data.Indicator.Visible = true
					TweenService:Create(data.Indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
						BackgroundTransparency = 0,
					}):Play()
				end
			else
				data.Frame.Visible = false
				if data.Button then
					TweenService:Create(data.Button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = COLORS.glassSurface,
						BackgroundTransparency = 1,
					}):Play()
					data.Button.TextColor3 = COLORS.textSecondary
				end
				if data.Indicator then
					TweenService:Create(data.Indicator, TweenInfo.new(0.15), {
						BackgroundTransparency = 1,
					}):Play()
					task.delay(0.15, function()
						if activeTab ~= name and data.Indicator then
							data.Indicator.Visible = false
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
		button.Text = "  " .. (iconText and (iconText .. " ") or "") .. name
		button.TextColor3 = COLORS.textSecondary
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 12
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.LayoutOrder = layoutOrder or 1
		button.Parent = tabContainer

		applyGlass(button, { corner = CORNER.small })

		local indicator = Instance.new("Frame")
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
		tabs[name] = {
			Frame = contentFrame,
			Button = button,
			Indicator = indicator,
		}

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
	-- 📦 COMPONENT BUILDERS
	------------------------------------------------
	local function addSection(parent, title, layoutOrder)
		local sectionCard = Instance.new("Frame")
		sectionCard.Name = title:gsub("%s+", "") .. "Section"
		sectionCard.Size = UDim2.new(1, 0, 0, 32)
		sectionCard.AutomaticSize = Enum.AutomaticSize.Y
		sectionCard.BackgroundColor3 = COLORS.glassCard
		sectionCard.BackgroundTransparency = TRANSPARENCY.glassCard
		sectionCard.BorderSizePixel = 0
		sectionCard.LayoutOrder = layoutOrder or 1
		sectionCard.Parent = parent

		applyGlass(sectionCard, {
			corner = CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75,
		})

		applyPadding(sectionCard, 10, 10, 8, 10)
		local layout = applyListLayout(sectionCard, 6)

		local header = Instance.new("Frame")
		header.Size = UDim2.new(1, 0, 0, 22)
		header.BackgroundTransparency = 1
		header.LayoutOrder = 0
		header.Parent = sectionCard

		local accentLine = Instance.new("Frame")
		accentLine.Size = UDim2.new(0, 3, 0, 14)
		accentLine.Position = UDim2.new(0, 0, 0.5, -7)
		accentLine.BackgroundColor3 = COLORS.accentCyan
		accentLine.BorderSizePixel = 0
		accentLine.Parent = header

		local lineCorner = Instance.new("UICorner")
		lineCorner.CornerRadius = UDim.new(0, 2)
		lineCorner.Parent = accentLine

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -12, 1, 0)
		titleLabel.Position = UDim2.new(0, 10, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = title
		titleLabel.TextColor3 = COLORS.textWhite
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Parent = header

		return sectionCard
	end

	local function addToggle(parent, labelText, defaultValue, callback, layoutOrder)
		local toggleFrame = Instance.new("Frame")
		toggleFrame.Size = UDim2.new(1, 0, 0, 32)
		toggleFrame.BackgroundColor3 = COLORS.glassSurface
		toggleFrame.BackgroundTransparency = 0.4
		toggleFrame.BorderSizePixel = 0
		toggleFrame.LayoutOrder = layoutOrder or 1
		toggleFrame.Parent = parent

		applyGlass(toggleFrame, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.85 })

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -55, 1, 0)
		text.Position = UDim2.new(0, 10, 0, 0)
		text.BackgroundTransparency = 1
		text.Text = labelText
		text.TextColor3 = COLORS.textPrimary
		text.Font = Enum.Font.Gotham
		text.TextSize = 11
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Parent = toggleFrame

		local switch = Instance.new("TextButton")
		switch.Size = UDim2.new(0, 36, 0, 18)
		switch.Position = UDim2.new(1, -44, 0.5, -9)
		switch.BackgroundColor3 = defaultValue and COLORS.toggleOn or COLORS.toggleOff
		switch.BorderSizePixel = 0
		switch.Text = ""
		switch.Parent = toggleFrame

		local switchCorner = Instance.new("UICorner")
		switchCorner.CornerRadius = CORNER.pill
		switchCorner.Parent = switch

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 14, 0, 14)
		knob.Position = defaultValue and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		knob.BackgroundColor3 = COLORS.textWhite
		knob.BorderSizePixel = 0
		knob.Parent = switch

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = CORNER.pill
		knobCorner.Parent = knob

		local state = defaultValue or false

		local function setState(newState, skipCallback)
			state = newState
			local targetColor = state and COLORS.toggleOn or COLORS.toggleOff
			local targetPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)

			TweenService:Create(switch, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
			TweenService:Create(knob, TweenInfo.new(0.2), { Position = targetPos }):Play()

			if not skipCallback and callback then
				task.spawn(callback, state)
			end
		end

		switch.MouseButton1Click:Connect(function()
			setState(not state)
		end)

		local fullButton = Instance.new("TextButton")
		fullButton.Size = UDim2.new(1, -50, 1, 0)
		fullButton.BackgroundTransparency = 1
		fullButton.Text = ""
		fullButton.Parent = toggleFrame
		fullButton.MouseButton1Click:Connect(function()
			setState(not state)
		end)

		return {
			Frame = toggleFrame,
			Set = setState,
			Get = function() return state end
		}
	end

	local function addSlider(parent, labelText, minVal, maxVal, defaultVal, callback, layoutOrder, unit)
		unit = unit or ""
		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(1, 0, 0, 44)
		sliderFrame.BackgroundColor3 = COLORS.glassSurface
		sliderFrame.BackgroundTransparency = 0.4
		sliderFrame.BorderSizePixel = 0
		sliderFrame.LayoutOrder = layoutOrder or 1
		sliderFrame.Parent = parent

		applyGlass(sliderFrame, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.85 })

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -70, 0, 20)
		text.Position = UDim2.new(0, 10, 0, 4)
		text.BackgroundTransparency = 1
		text.Text = labelText
		text.TextColor3 = COLORS.textPrimary
		text.Font = Enum.Font.Gotham
		text.TextSize = 11
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Parent = sliderFrame

		local valLabel = Instance.new("TextLabel")
		valLabel.Size = UDim2.new(0, 60, 0, 20)
		valLabel.Position = UDim2.new(1, -70, 0, 4)
		valLabel.BackgroundTransparency = 1
		valLabel.Text = tostring(defaultVal) .. unit
		valLabel.TextColor3 = COLORS.accentCyan
		valLabel.Font = Enum.Font.GothamBold
		valLabel.TextSize = 11
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.Parent = sliderFrame

		local barBg = Instance.new("TextButton")
		barBg.Size = UDim2.new(1, -20, 0, 8)
		barBg.Position = UDim2.new(0, 10, 0, 28)
		barBg.BackgroundColor3 = Color3.fromRGB(30, 36, 56)
		barBg.BorderSizePixel = 0
		barBg.Text = ""
		barBg.Parent = sliderFrame

		local barBgCorner = Instance.new("UICorner")
		barBgCorner.CornerRadius = CORNER.pill
		barBgCorner.Parent = barBg

		local fill = Instance.new("Frame")
		local initPct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
		fill.Size = UDim2.new(initPct, 0, 1, 0)
		fill.BackgroundColor3 = COLORS.accentCyan
		fill.BorderSizePixel = 0
		fill.Parent = barBg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = CORNER.pill
		fillCorner.Parent = fill

		local fillGrad = Instance.new("UIGradient")
		fillGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.accentCyan),
			ColorSequenceKeypoint.new(1, COLORS.accentViolet)
		})
		fillGrad.Parent = fill

		local currentVal = defaultVal
		local sliding = false

		local function updateSlider(input)
			local absPos = barBg.AbsolutePosition.X
			local absSize = barBg.AbsoluteSize.X
			local relX = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
			local rawVal = minVal + (maxVal - minVal) * relX
			local formattedVal = (maxVal - minVal <= 20 and maxVal - minVal ~= math.floor(maxVal - minVal)) and math.floor(rawVal * 10) / 10 or math.floor(rawVal)
			currentVal = formattedVal
			fill.Size = UDim2.new(relX, 0, 1, 0)
			valLabel.Text = tostring(formattedVal) .. unit

			if callback then
				task.spawn(callback, formattedVal)
			end
		end

		barBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = true
				updateSlider(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateSlider(input)
			end
		end)

		return {
			Frame = sliderFrame,
			Set = function(val)
				val = math.clamp(val, minVal, maxVal)
				currentVal = val
				local pct = (val - minVal) / (maxVal - minVal)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				valLabel.Text = tostring(val) .. unit
				if callback then task.spawn(callback, val) end
			end,
			Get = function() return currentVal end
		}
	end

	local function addDropdown(parent, labelText, options, defaultOption, callback, layoutOrder)
		local dropFrame = Instance.new("Frame")
		dropFrame.Size = UDim2.new(1, 0, 0, 34)
		dropFrame.BackgroundColor3 = COLORS.glassSurface
		dropFrame.BackgroundTransparency = 0.4
		dropFrame.BorderSizePixel = 0
		dropFrame.ClipsDescendants = true
		dropFrame.LayoutOrder = layoutOrder or 1
		dropFrame.Parent = parent

		applyGlass(dropFrame, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.85 })

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(0.45, 0, 0, 34)
		text.Position = UDim2.new(0, 10, 0, 0)
		text.BackgroundTransparency = 1
		text.Text = labelText
		text.TextColor3 = COLORS.textPrimary
		text.Font = Enum.Font.Gotham
		text.TextSize = 11
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Parent = dropFrame

		local selectButton = Instance.new("TextButton")
		selectButton.Size = UDim2.new(0.5, 0, 0, 24)
		selectButton.Position = UDim2.new(0.48, 0, 0, 5)
		selectButton.BackgroundColor3 = COLORS.glassCard
		selectButton.BorderSizePixel = 0
		selectButton.Text = (defaultOption or (options[1] or "Select...")) .. "  ▼"
		selectButton.TextColor3 = COLORS.accentCyan
		selectButton.Font = Enum.Font.GothamBold
		selectButton.TextSize = 10
		selectButton.Parent = dropFrame

		applyGlass(selectButton, { corner = CORNER.small })

		local optList = Instance.new("Frame")
		optList.Size = UDim2.new(1, -20, 0, #options * 24)
		optList.Position = UDim2.new(0, 10, 0, 38)
		optList.BackgroundTransparency = 1
		optList.Parent = dropFrame

		local optLayout = applyListLayout(optList, 3)

		local isOpen = false
		local selected = defaultOption or options[1]

		local function refreshOptions(newOptions)
			options = newOptions
			for _, child in pairs(optList:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			optList.Size = UDim2.new(1, -20, 0, #options * 24)

			for _, opt in ipairs(options) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, 0, 0, 22)
				optBtn.BackgroundColor3 = COLORS.glassHover
				optBtn.BackgroundTransparency = 0.5
				optBtn.BorderSizePixel = 0
				optBtn.Text = tostring(opt)
				optBtn.TextColor3 = (opt == selected) and COLORS.accentCyan or COLORS.textSecondary
				optBtn.Font = Enum.Font.Gotham
				optBtn.TextSize = 10
				optBtn.Parent = optList

				applyGlass(optBtn, { corner = CORNER.small })

				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					selectButton.Text = tostring(opt) .. "  ▼"
					isOpen = false
					TweenService:Create(dropFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 34) }):Play()
					if callback then task.spawn(callback, selected) end
				end)
			end
		end

		refreshOptions(options)

		selectButton.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			local targetH = isOpen and (42 + #options * 26) or 34
			selectButton.Text = tostring(selected) .. (isOpen and "  ▲" or "  ▼")
			TweenService:Create(dropFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, targetH) }):Play()
		end)

		return {
			Frame = dropFrame,
			Set = function(val)
				selected = val
				selectButton.Text = tostring(val) .. "  ▼"
				if callback then task.spawn(callback, val) end
			end,
			Get = function() return selected end,
			Refresh = refreshOptions
		}
	end

	local function addButton(parent, labelText, callback, layoutOrder, colorOverride)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundColor3 = colorOverride or COLORS.glassActive
		btn.BackgroundTransparency = 0.2
		btn.BorderSizePixel = 0
		btn.Text = labelText
		btn.TextColor3 = COLORS.textWhite
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.LayoutOrder = layoutOrder or 1
		btn.Parent = parent

		applyGlass(btn, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.6
		})

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 }):Play()
		end)

		btn.MouseButton1Click:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { TextSize = 9 }):Play()
			task.delay(0.1, function()
				TweenService:Create(btn, TweenInfo.new(0.1), { TextSize = 11 }):Play()
			end)
			if callback then task.spawn(callback) end
		end)

		return btn
	end

	local function addTextbox(parent, labelText, defaultText, callback, layoutOrder)
		local tbFrame = Instance.new("Frame")
		tbFrame.Size = UDim2.new(1, 0, 0, 34)
		tbFrame.BackgroundColor3 = COLORS.glassSurface
		tbFrame.BackgroundTransparency = 0.4
		tbFrame.BorderSizePixel = 0
		tbFrame.LayoutOrder = layoutOrder or 1
		tbFrame.Parent = parent

		applyGlass(tbFrame, { corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.85 })

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(0.45, 0, 1, 0)
		text.Position = UDim2.new(0, 10, 0, 0)
		text.BackgroundTransparency = 1
		text.Text = labelText
		text.TextColor3 = COLORS.textPrimary
		text.Font = Enum.Font.Gotham
		text.TextSize = 11
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Parent = tbFrame

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.5, 0, 0, 24)
		box.Position = UDim2.new(0.48, 0, 0.5, -12)
		box.BackgroundColor3 = COLORS.glassCard
		box.BorderSizePixel = 0
		box.Text = defaultText or ""
		box.PlaceholderText = "Type here..."
		box.TextColor3 = COLORS.accentCyan
		box.PlaceholderColor3 = COLORS.textMuted
		box.Font = Enum.Font.Gotham
		box.TextSize = 10
		box.ClearTextOnFocus = false
		box.Parent = tbFrame

		applyGlass(box, { corner = CORNER.small })

		box.FocusLost:Connect(function(enterPressed)
			if callback then task.spawn(callback, box.Text, enterPressed) end
		end)

		box:GetPropertyChangedSignal("Text"):Connect(function()
			if callback then task.spawn(callback, box.Text, false) end
		end)

		return {
			Frame = tbFrame,
			Get = function() return box.Text end,
			Set = function(str) box.Text = tostring(str) end
		}
	end

	local function addLabel(parent, labelText, layoutOrder, color)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 20)
		lbl.BackgroundTransparency = 1
		lbl.Text = labelText
		lbl.TextColor3 = color or COLORS.textSecondary
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextWrapped = true
		lbl.LayoutOrder = layoutOrder or 1
		lbl.Parent = parent
		return lbl
	end

	------------------------------------------------
	-- 🔔 NOTIFICATION SYSTEM
	------------------------------------------------
	local notifContainer = Instance.new("Frame")
	notifContainer.Size = UDim2.new(0, 260, 1, -40)
	notifContainer.Position = UDim2.new(1, -270, 0, 20)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 10
	notifContainer.Parent = gui

	local notifLayout = applyListLayout(notifContainer, 8, Enum.SortOrder.LayoutOrder)
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local function notify(title, message, duration, notifType)
		duration = duration or 3
		local notifFrame = Instance.new("Frame")
		notifFrame.Size = UDim2.new(1, 0, 0, 56)
		notifFrame.BackgroundColor3 = COLORS.glassPrimary
		notifFrame.BackgroundTransparency = 0.1
		notifFrame.BorderSizePixel = 0
		notifFrame.ZIndex = 11
		notifFrame.Parent = notifContainer

		local strokeColor = COLORS.borderGlow
		if notifType == "success" then strokeColor = COLORS.successGreen
		elseif notifType == "warning" then strokeColor = COLORS.warningYellow
		elseif notifType == "error" then strokeColor = COLORS.dangerRed end

		applyGlass(notifFrame, {
			corner = CORNER.medium,
			stroke = true,
			strokeColor = strokeColor,
			strokeThickness = 1.2,
			strokeTransparency = 0.3
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

		task.delay(duration, function()
			if notifFrame and notifFrame.Parent then
				TweenService:Create(notifFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				task.wait(0.3)
				notifFrame:Destroy()
			end
		end)
	end

	------------------------------------------------
	-- 🪟 CREATE INITIAL CORE TABS
	------------------------------------------------
	addTab("Main", "🏠", 1)
	addTab("Farm", "💰", 2)
	addTab("Vehicle", "🚗", 3)
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
		closeButton = closeButton,
		minimizeButton = minimizeButton,
		fullscreenButton = fullscreenButton,
		sidebar = sidebar,
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

	notify("HipHub CDID Loaded", "Welcome " .. player.DisplayName .. "!", 3, "success")
end)

if not success then
	warn("[HipHub CDID UI Error]:", err)
end
