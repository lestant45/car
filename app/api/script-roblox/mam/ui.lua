-- 🌍 CAB — Liquid Glass Futuristic UI Base
-- Pure UI Layout Base (Logic resides in main.lua)
-- Theme: Glassmorphism / Liquid Glass with Cyan-Violet accents

-- Ensure game is fully loaded first
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
	-- Run pre-loader FPS Booster and optimizations if enabled in config to prevent startup lag
	pcall(function()
		local HttpService = game:GetService("HttpService")
		local file = "HipHub/config.json"
		if isfile and not isfile(file) then
			file = "hiphub_config.json"
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

	-- Wait for PlayerGui to exist
	player:WaitForChild("PlayerGui")

	------------------------------------------------
	-- 🎨 DESIGN TOKENS (Liquid Glass Palette)
	------------------------------------------------
	local COLORS = {
		-- Glass surfaces
		glassPrimary  = Color3.fromRGB(10, 12, 24),
		glassSurface  = Color3.fromRGB(16, 20, 36),
		glassCard     = Color3.fromRGB(20, 24, 44),
		glassHover    = Color3.fromRGB(28, 34, 58),
		glassActive   = Color3.fromRGB(34, 40, 68),
		-- Accent
		accentCyan    = Color3.fromRGB(0, 200, 255),
		accentViolet  = Color3.fromRGB(140, 120, 255),
		accentBlend   = Color3.fromRGB(80, 160, 255),
		accentGlow    = Color3.fromRGB(60, 180, 255),
		accentMuted   = Color3.fromRGB(50, 60, 100),
		-- Toggle
		toggleOn      = Color3.fromRGB(0, 180, 230),
		toggleOff     = Color3.fromRGB(40, 46, 70),
		-- Text
		textPrimary   = Color3.fromRGB(225, 235, 255),
		textSecondary = Color3.fromRGB(140, 155, 185),
		textMuted     = Color3.fromRGB(90, 105, 135),
		textWhite     = Color3.fromRGB(255, 255, 255),
		-- Borders
		borderGlass   = Color3.fromRGB(50, 65, 110),
		borderGlow    = Color3.fromRGB(0, 180, 255),
		-- Shadow
		shadow        = Color3.fromRGB(2, 3, 8),
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
	-- 🧹 REMOVE OLD GUI & BLUR
	------------------------------------------------
	local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("HipHub")
	if oldGui then
		oldGui:Destroy()
	end
	local Lighting = game:GetService("Lighting")
	local oldBlur = Lighting:FindFirstChild("HipHubBlur")
	if oldBlur then
		oldBlur:Destroy()
	end

	------------------------------------------------
	-- 🛠️ HELPERS
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
		layout.Padding = UDim.new(0, padding or 4)
		layout.Parent = parent
		return layout
	end

	local function createCollapsibleSection(parent, title, layoutOrder)
		local header = Instance.new("TextButton")
		header.Size = UDim2.new(1, 0, 0, 36)
		header.BackgroundColor3 = Color3.fromRGB(24, 28, 52)
		header.BackgroundTransparency = 0.08
		header.BorderSizePixel = 0
		header.Text = ""
		header.LayoutOrder = layoutOrder
		header.Parent = parent

		local hCorner = Instance.new("UICorner")
		hCorner.CornerRadius = UDim.new(0, 8)
		hCorner.Parent = header

		local hStroke = Instance.new("UIStroke")
		hStroke.Color = Color3.fromRGB(50, 65, 110)
		hStroke.Thickness = 1
		hStroke.Transparency = 0.55
		hStroke.Parent = header

		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 3, 0, 18)
		accentBar.Position = UDim2.new(0, 6, 0.5, -9)
		accentBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		accentBar.BorderSizePixel = 0
		accentBar.Parent = header

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 2)
		accentCorner.Parent = accentBar

		local hTitle = Instance.new("TextLabel")
		hTitle.Name = "headerTitle"
		hTitle.Size = UDim2.new(1, -50, 1, 0)
		hTitle.Position = UDim2.new(0, 18, 0, 0)
		hTitle.BackgroundTransparency = 1
		hTitle.Text = title
		hTitle.TextColor3 = Color3.fromRGB(225, 235, 255)
		hTitle.Font = Enum.Font.GothamBold
		hTitle.TextSize = 14
		hTitle.TextXAlignment = Enum.TextXAlignment.Left
		hTitle.Parent = header

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 24, 0, 24)
		arrow.Position = UDim2.new(1, -24, 0.5, 0)
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.BackgroundTransparency = 1
		arrow.Text = ">"
		arrow.TextColor3 = Color3.fromRGB(0, 200, 255)
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 14
		arrow.TextXAlignment = Enum.TextXAlignment.Center
		arrow.TextYAlignment = Enum.TextYAlignment.Center
		arrow.Parent = header

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 0)
		container.BackgroundTransparency = 1
		container.LayoutOrder = layoutOrder + 1
		container.ClipsDescendants = true
		container.Visible = false
		container.Parent = parent

		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, 0, 0, 0)
		content.Position = UDim2.new(0, 0, 0, 0)
		content.BackgroundTransparency = 1
		content.Visible = false
		content.Parent = container

		local contentLayout = Instance.new("UIListLayout")
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		contentLayout.Padding = UDim.new(0, 6)
		contentLayout.Parent = content

		local bottomLine = Instance.new("Frame")
		bottomLine.Size = UDim2.new(1, -12, 0, 1)
		bottomLine.Position = UDim2.new(0, 6, 1, -1)
		bottomLine.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		bottomLine.BackgroundTransparency = 1
		bottomLine.BorderSizePixel = 0
		bottomLine.ZIndex = 4
		bottomLine.Parent = header

		local lineGrad = Instance.new("UIGradient")
		lineGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
		})
		lineGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.25),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(0.8, 0.25),
			NumberSequenceKeypoint.new(1, 1)
		})
		lineGrad.Parent = bottomLine

		pcall(function()
			header.MouseEnter:Connect(function()
				TweenService:Create(header, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(30, 36, 64),
				}):Play()
				TweenService:Create(accentBar, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(60, 220, 255),
				}):Play()
				hTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			end)
			header.MouseLeave:Connect(function()
				TweenService:Create(header, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(24, 28, 52),
				}):Play()
				TweenService:Create(accentBar, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(0, 200, 255),
				}):Play()
				hTitle.TextColor3 = Color3.fromRGB(225, 235, 255)
			end)
		end)

		local isCollapsed = true
		header.MouseButton1Click:Connect(function()
			isCollapsed = not isCollapsed
			container.Visible = true
			content.Visible = true
			local targetRot = isCollapsed and 0 or 90
			local targetH = isCollapsed and 0 or contentLayout.AbsoluteContentSize.Y + 12

			TweenService:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = targetRot }):Play()
			local tween = TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetH) })
			tween.Completed:Connect(function()
				if isCollapsed then
					container.Visible = false
					content.Visible = false
				end
			end)
			tween:Play()
		end)

		contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			if not isCollapsed then
				container.Size = UDim2.new(1, 0, 0, contentLayout.AbsoluteContentSize.Y + 12)
			end
		end)

		return {
			Header = header,
			Arrow = arrow,
			Container = container,
			Content = content,
			ContentLayout = contentLayout,
			BottomLine = bottomLine
		}
	end

	------------------------------------------------
	-- 🖥️ UI SETUP
	------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "HipHub"
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
	shadowFrame.Size = UDim2.new(0, 572, 0, 392)
	shadowFrame.Position = UDim2.new(0.5, -286, 0.5, -196)
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
	mainFrame.Size = UDim2.new(0, 560, 0, 380)
	mainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
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

	local glassHighlight = Instance.new("Frame")
	glassHighlight.Size = UDim2.new(1, 0, 0, 60)
	glassHighlight.Position = UDim2.new(0, 0, 0, 0)
	glassHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	glassHighlight.BackgroundTransparency = 0.96
	glassHighlight.BorderSizePixel = 0
	glassHighlight.ZIndex = 0
	glassHighlight.Parent = mainFrame

	local highlightGrad = Instance.new("UIGradient")
	highlightGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.90),
		NumberSequenceKeypoint.new(1, 1),
	})
	highlightGrad.Rotation = 180
	highlightGrad.Parent = glassHighlight

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

	local titleLogo = Instance.new("ImageLabel")
	titleLogo.Size = UDim2.new(0, 24, 0, 24)
	titleLogo.Position = UDim2.new(0, 14, 0.5, -12)
	titleLogo.BackgroundTransparency = 1
	titleLogo.BorderSizePixel = 0
	titleLogo.ZIndex = 3
	titleLogo.Parent = topBar

	local hubTitle = Instance.new("TextLabel")
	hubTitle.Size = UDim2.new(0, 72, 1, 0)
	hubTitle.Position = UDim2.new(0, 46, 0, 0)
	hubTitle.BackgroundTransparency = 1
	hubTitle.Text = "HipHub"
	hubTitle.TextColor3 = COLORS.textWhite
	hubTitle.Font = Enum.Font.GothamBold
	hubTitle.TextSize = 16
	hubTitle.TextXAlignment = Enum.TextXAlignment.Left
	hubTitle.ZIndex = 3
	hubTitle.Parent = topBar

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.new(0, 115, 0, 22)
	badge.Position = UDim2.new(0, 126, 0.5, -11)
	badge.BackgroundColor3 = COLORS.accentViolet
	badge.BackgroundTransparency = 0.25
	badge.Text = "Roblox Script"
	badge.TextColor3 = COLORS.textWhite
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.ZIndex = 3
	badge.Parent = topBar

	pcall(function()
		local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
		if gameName and gameName ~= "" then
			badge.Text = gameName
			local textWidth = gameName:len() * 6.5
			badge.Size = UDim2.new(0, math.clamp(textWidth, 80, 180), 0, 22)
		end
	end)

	applyGlass(badge, {
		corner = CORNER.pill,
		stroke = true,
		strokeColor = COLORS.accentViolet,
		strokeThickness = 1,
		strokeTransparency = 0.5
	})

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

	pcall(function()
		closeButton.MouseEnter:Connect(function()
			TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 80, 80) }):Play()
		end)
		closeButton.MouseLeave:Connect(function()
			TweenService:Create(closeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
		end)
	end)

	local fullscreenButton = Instance.new("TextButton")
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

	local function updateFullscreenIcon(isFullscreen)
		if isFullscreen then
			fsIcon.Size = UDim2.new(0, 8, 0, 8)
			fsIcon.Position = UDim2.new(0.5, -6, 0.5, -2)
			fsIcon2.Visible = true
		else
			fsIcon.Size = UDim2.new(0, 10, 0, 10)
			fsIcon.Position = UDim2.new(0.5, -5, 0.5, -5)
			fsIcon2.Visible = false
		end
	end

	pcall(function()
		fullscreenButton.MouseEnter:Connect(function()
			TweenService:Create(fsIconStroke, TweenInfo.new(0.15), { Color = COLORS.accentCyan }):Play()
			TweenService:Create(fsIcon2Stroke, TweenInfo.new(0.15), { Color = COLORS.accentCyan }):Play()
		end)
		fullscreenButton.MouseLeave:Connect(function()
			TweenService:Create(fsIconStroke, TweenInfo.new(0.15), { Color = COLORS.textSecondary }):Play()
			TweenService:Create(fsIcon2Stroke, TweenInfo.new(0.15), { Color = COLORS.textSecondary }):Play()
		end)
	end)

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Size = UDim2.new(0, 30, 0, 30)
	minimizeButton.Position = UDim2.new(1, -102, 0.5, -15)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "-"
	minimizeButton.TextColor3 = COLORS.textSecondary
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = 16
	minimizeButton.ZIndex = 3
	minimizeButton.Parent = topBar

	pcall(function()
		minimizeButton.MouseEnter:Connect(function()
			TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
		end)
		minimizeButton.MouseLeave:Connect(function()
			TweenService:Create(minimizeButton, TweenInfo.new(0.15), { TextColor3 = COLORS.textSecondary }):Play()
		end)
	end)

	------------------------------------------------
	-- 📂 SIDEBAR (Glass Panel)
	------------------------------------------------
	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, 150, 1, -42)
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

	local sidebarGlow = Instance.new("Frame")
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
	tabContainer.Size = UDim2.new(1, 0, 1, -60)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 2
	tabContainer.Parent = sidebar

	applyListLayout(tabContainer, 3)
	applyPadding(tabContainer, 8, 8, 12, 0)

	local profileCard = Instance.new("Frame")
	profileCard.Size = UDim2.new(1, -16, 0, 44)
	profileCard.Position = UDim2.new(0, 8, 1, -52)
	profileCard.BackgroundColor3 = COLORS.glassCard
	profileCard.BackgroundTransparency = TRANSPARENCY.glassCard
	profileCard.BorderSizePixel = 0
	profileCard.ZIndex = 2
	profileCard.Parent = sidebar

	applyGlass(profileCard,
		{ corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.7 })

	local avatarLabel = Instance.new("ImageLabel")
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

	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Size = UDim2.new(1, -48, 1, 0)
	usernameLabel.Position = UDim2.new(0, 42, 0, 0)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = player.Name
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
	contentArea.Size = UDim2.new(1, -150, 1, -42)
	contentArea.Position = UDim2.new(0, 150, 0, 42)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 1
	contentArea.Parent = mainFrame

	------------------------------------------------
	-- 📑 TAB SYSTEM
	------------------------------------------------
	local tabs = {}
	local activeTab = nil
	local tabButtons = {}

	local function createTabContent(name)
		local frame = Instance.new("ScrollingFrame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		pcall(function()
			frame.ScrollBarThickness = 3
			frame.ScrollBarImageColor3 = COLORS.accentCyan
			frame.ScrollBarImageTransparency = 0.4
		end)
		frame.CanvasSize = UDim2.new(0, 0, 0, 0)
		frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		frame.ClipsDescendants = true
		frame.Visible = false
		frame.ZIndex = 2
		frame.Parent = contentArea

		applyPadding(frame, 16, 16, 16, 16)

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
					pcall(function()
						data.Button.TextColor3 = COLORS.textWhite
					end)
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
					pcall(function()
						data.Button.TextColor3 = COLORS.textSecondary
					end)
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
		button.Size = UDim2.new(1, 0, 0, 30)
		button.BackgroundColor3 = COLORS.glassSurface
		button.BackgroundTransparency = 1
		button.BorderSizePixel = 0
		button.ZIndex = 3

		local textSuccess = pcall(function()
			if iconText and iconText ~= "" then
				button.Text = "   " .. iconText .. "  " .. name
			else
				button.Text = "   " .. name
			end
		end)
		if not textSuccess then
			button.Text = "   " .. name
		end

		button.TextColor3 = COLORS.textSecondary
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 12
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.LayoutOrder = layoutOrder
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

		tabButtons[name] = button

		local contentFrame = createTabContent(name)
		tabs[name] = {
			Frame = contentFrame,
			Button = button,
			Indicator = indicator,
		}

		button.MouseButton1Click:Connect(function()
			selectTab(name)
		end)

		pcall(function()
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
		end)

		return contentFrame
	end

	-- Add Core Tabs
	addTab("Main", "", 1)
	addTab("Misc", "", 50)
	addTab("Settings", "", 99)

	------------------------------------------------
	-- 📱 MAIN TAB
	------------------------------------------------
	local mainFrameContent = tabs["Main"].Frame
	applyListLayout(mainFrameContent, 10)

	------------------------------------------------
	-- 🔄 GLASS TOGGLE HELPER
	------------------------------------------------
	local function createGlassToggle(parent, labelText, layoutOrder)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 32)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 2
		card.Parent = parent

		applyGlass(card,
			{ corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.75 })

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.6, 0, 1, 0)
		title.Position = UDim2.new(0, 12, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = labelText
		title.TextColor3 = COLORS.textPrimary
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 3
		title.Parent = card

		local track = Instance.new("TextButton")
		track.Size = UDim2.new(0, 36, 0, 18)
		track.Position = UDim2.new(1, -46, 0.5, -9)
		track.BackgroundColor3 = COLORS.toggleOn
		track.BackgroundTransparency = 0.15
		track.BorderSizePixel = 0
		track.Text = ""
		track.ZIndex = 3
		track.Parent = card

		local trackCorner = Instance.new("UICorner")
		trackCorner.CornerRadius = CORNER.pill
		trackCorner.Parent = track

		local thumb = Instance.new("Frame")
		thumb.Size = UDim2.new(0, 14, 0, 14)
		thumb.Position = UDim2.new(0, 2, 0.5, -7)
		thumb.BackgroundColor3 = COLORS.textWhite
		thumb.BorderSizePixel = 0
		thumb.ZIndex = 4
		thumb.Parent = track

		local thumbCorner = Instance.new("UICorner")
		thumbCorner.CornerRadius = CORNER.pill
		thumbCorner.Parent = thumb

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.accentCyan
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = track

		return card, track, thumb
	end

	local dropdownsList = {}
	local function closeAllDropdowns()
		for _, dd in ipairs(dropdownsList) do
			dd.isOpen = false
			local m = dd.menu
			local tween = TweenService:Create(m, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 0, 0, 0)
			})
			tween.Completed:Connect(function()
				if not dd.isOpen then m.Visible = false end
			end)
			tween:Play()
		end
	end

	local function registerDropdownMenu(btn, menu)
		local ddData = { btn = btn, menu = menu, isOpen = false }
		table.insert(dropdownsList, ddData)

		btn.MouseButton1Click:Connect(function()
			local isOpen = ddData.isOpen
			closeAllDropdowns()
			if not isOpen then
				ddData.isOpen = true
				menu.Visible = true
				local menuWidth = menu.Size.X.Offset
				if menuWidth <= 0 then menuWidth = 160 end
				TweenService:Create(menu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(1, -menuWidth, 0, 0)
				}):Play()
			end
		end)
	end

	local function bindDropdown(btn, menu, searchBox, scroll, optionsList, getSelectedFunc, setSelectedFunc, updateLabelCallback)
		local optionButtons = {}
		local optionIndicators = {}

		local function updateOptionVisuals()
			for _, opt in ipairs(optionsList) do
				local oBtn = optionButtons[opt]
				local oInd = optionIndicators[opt]
				if oBtn and oInd then
					if getSelectedFunc(opt) then
						oBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
						oBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 68)
						oInd.Visible = true
					else
						oBtn.TextColor3 = COLORS.textSecondary or Color3.fromRGB(140, 155, 185)
						oBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
						oInd.Visible = false
					end
				end
			end
		end

		local function rebuildMenu()
			scroll:ClearAllChildren()
			local listLayout = Instance.new("UIListLayout")
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0, 4)
			listLayout.Parent = scroll

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 8)
			padding.PaddingRight = UDim.new(0, 8)
			padding.PaddingTop = UDim.new(0, 4)
			padding.Parent = scroll

			for i, opt in ipairs(optionsList) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, 0, 0, 26)
				optBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
				optBtn.BorderSizePixel = 0
				optBtn.Text = "     " .. opt
				optBtn.TextColor3 = COLORS.textSecondary or Color3.fromRGB(140, 155, 185)
				optBtn.Font = Enum.Font.GothamMedium
				optBtn.TextSize = 11
				optBtn.TextXAlignment = Enum.TextXAlignment.Left
				optBtn.ZIndex = 102
				optBtn.LayoutOrder = i
				optBtn.Parent = scroll

				local optCorner = Instance.new("UICorner")
				optCorner.CornerRadius = UDim.new(0, 4)
				optCorner.Parent = optBtn

				local leftIndicator = Instance.new("Frame")
				leftIndicator.Size = UDim2.new(0, 3, 0, 14)
				leftIndicator.Position = UDim2.new(0, 3, 0.5, -7)
				leftIndicator.BackgroundColor3 = COLORS.accentCyan or Color3.fromRGB(0, 200, 255)
				leftIndicator.BorderSizePixel = 0
				leftIndicator.Visible = false
				leftIndicator.ZIndex = 103
				leftIndicator.Parent = optBtn

				optionButtons[opt] = optBtn
				optionIndicators[opt] = leftIndicator

				optBtn.MouseButton1Click:Connect(function()
					setSelectedFunc(opt)
					closeAllDropdowns()
					updateOptionVisuals()
					updateLabelCallback()
					if _G.HipHubUI.saveConfig then pcall(_G.HipHubUI.saveConfig) end
				end)
			end
			scroll.CanvasSize = UDim2.new(0, 0, 0, #optionsList * 30 + 10)
		end

		rebuildMenu()
		updateOptionVisuals()

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBox.Text:lower():gsub("%s+", "")
			for _, opt in ipairs(optionsList) do
				local oBtn = optionButtons[opt]
				if oBtn then
					if query == "" or opt:lower():gsub("%s+", ""):find(query, 1, true) then
						oBtn.Visible = true
					else
						oBtn.Visible = false
					end
				end
			end
		end)

		return {
			updateOptionVisuals = updateOptionVisuals,
			rebuildMenu = rebuildMenu
		}
	end

	local function createGlassDropdown(parent, labelText, defaultText, layoutOrder)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 32)
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.ZIndex = 2
		card.Parent = parent

		applyGlass(card,
			{ corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.75 })

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.5, 0, 1, 0)
		title.Position = UDim2.new(0, 12, 0, 0)
		title.BackgroundTransparency = 1
		title.Text = labelText
		title.TextColor3 = COLORS.textSecondary
		title.Font = Enum.Font.GothamMedium
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 3
		title.Parent = card

		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 140, 0, 24)
		button.Position = UDim2.new(1, -150, 0.5, -12)
		button.BackgroundColor3 = COLORS.glassPrimary
		button.BackgroundTransparency = 0.2
		button.BorderSizePixel = 0
		button.Text = ""
		button.ZIndex = 3
		button.Parent = card

		applyGlass(button,
			{ corner = CORNER.small, stroke = true, strokeColor = COLORS.accentCyan, strokeThickness = 1, strokeTransparency = 0.55 })

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -30, 1, 0)
		label.Position = UDim2.new(0, 8, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = defaultText or "Select Options"
		label.TextColor3 = COLORS.textPrimary
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ZIndex = 4
		label.Parent = button

		local arrow = Instance.new("TextLabel")
		arrow.Size = UDim2.new(0, 20, 1, 0)
		arrow.Position = UDim2.new(1, -20, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "v"
		arrow.TextColor3 = COLORS.accentCyan
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 12
		arrow.ZIndex = 4
		arrow.Parent = button

		-- Dropdown Menu Overlay
		local menu = Instance.new("Frame")
		menu.Size = UDim2.new(0, 160, 1, 0)
		menu.Position = UDim2.new(1, 0, 0, 0)
		menu.BackgroundColor3 = COLORS.glassSurface
		menu.BackgroundTransparency = 0.05
		menu.BorderSizePixel = 0
		menu.Visible = false
		menu.ZIndex = 100
		menu.Parent = mainFrame

		applyGlass(menu,
			{ corner = CORNER.medium, stroke = true, strokeColor = COLORS.accentCyan, strokeThickness = 1, strokeTransparency = 0.45, gradient = true, gradientRotation = 180 })

		local search = Instance.new("TextBox")
		search.Size = UDim2.new(1, -16, 0, 28)
		search.Position = UDim2.new(0, 8, 0, 8)
		search.BackgroundColor3 = COLORS.glassPrimary
		search.BackgroundTransparency = 0.15
		search.BorderSizePixel = 0
		search.Text = ""
		search.PlaceholderText = "Search..."
		search.PlaceholderColor3 = COLORS.textMuted
		search.TextColor3 = COLORS.textWhite
		search.Font = Enum.Font.GothamMedium
		search.TextSize = 11
		search.ClearTextOnFocus = false
		search.ZIndex = 101
		search.Parent = menu

		applyGlass(search,
			{ corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.6 })

		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, 0, 1, -44)
		scroll.Position = UDim2.new(0, 0, 0, 44)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		pcall(function()
			scroll.ScrollBarThickness = 3
			scroll.ScrollBarImageColor3 = COLORS.accentCyan
			scroll.ScrollBarImageTransparency = 0.4
		end)
		scroll.ZIndex = 101
		scroll.Parent = menu

		applyListLayout(scroll, 4)
		applyPadding(scroll, 8, 8, 4, 0)

		return card, button, label, menu, search, scroll
	end

	-- Connect click outside to close dropdowns
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = UserInputService:GetMouseLocation()
			local inset = game:GetService("GuiService"):GetGuiInset()
			local actualMousePos = mousePos - inset
			local function inBounds(guiObj)
				if not guiObj or not guiObj.Visible then return false end
				local pos = guiObj.AbsolutePosition
				local size = guiObj.AbsoluteSize
				return actualMousePos.X >= pos.X and actualMousePos.X <= pos.X + size.X and
					actualMousePos.Y >= pos.Y and actualMousePos.Y <= pos.Y + size.Y
			end
			local clickedInsideAny = false
			for _, dd in ipairs(dropdownsList) do
				if dd.isOpen then
					if inBounds(dd.menu) or inBounds(dd.btn) then clickedInsideAny = true end
				end
			end
			if not clickedInsideAny then
				closeAllDropdowns()
			end
		end
	end)

	------------------------------------------------
	-- ⚙️ SETTINGS TAB
	------------------------------------------------
	local settingsFrame = tabs["Settings"].Frame

	local settingsLayout = Instance.new("UIListLayout")
	settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	settingsLayout.Padding = UDim.new(0, 10)
	settingsLayout.Parent = settingsFrame

	-- Credits Card
	local creditsCard = Instance.new("Frame")
	creditsCard.Size = UDim2.new(1, 0, 0, 100)
	creditsCard.BackgroundColor3 = COLORS.glassCard
	creditsCard.BackgroundTransparency = TRANSPARENCY.glassCard
	creditsCard.BorderSizePixel = 0
	creditsCard.ZIndex = 2
	creditsCard.Parent = settingsFrame

	applyGlass(creditsCard,
		{ corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.7, gradient = true, gradientRotation = 120 })

	local credTitle = Instance.new("TextLabel")
	credTitle.Size = UDim2.new(1, -20, 0, 25)
	credTitle.Position = UDim2.new(0, 12, 0, 6)
	credTitle.BackgroundTransparency = 1
	credTitle.Text = "ABOUT SCRIPT"
	credTitle.TextColor3 = COLORS.accentCyan
	credTitle.Font = Enum.Font.GothamBold
	credTitle.TextSize = 10
	credTitle.TextXAlignment = Enum.TextXAlignment.Left
	credTitle.ZIndex = 3
	credTitle.Parent = creditsCard

	local credBody = Instance.new("TextLabel")
	credBody.Size = UDim2.new(1, -24, 0, 60)
	credBody.Position = UDim2.new(0, 12, 0, 30)
	credBody.BackgroundTransparency = 1
	credBody.Text = "HipHub — V1.0.1\nFuturistic glassmorphic base UI layout for game automations.\nLoaded in a secure sandboxed environment."
	credBody.TextColor3 = COLORS.textSecondary
	credBody.Font = Enum.Font.Gotham
	credBody.TextSize = 11
	credBody.TextXAlignment = Enum.TextXAlignment.Left
	credBody.TextYAlignment = Enum.TextYAlignment.Top
	credBody.TextWrapped = true
	credBody.ZIndex = 3
	credBody.Parent = creditsCard

	-- Keybind Card
	local keybindCard = Instance.new("Frame")
	keybindCard.Size = UDim2.new(1, 0, 0, 42)
	keybindCard.BackgroundColor3 = COLORS.glassCard
	keybindCard.BackgroundTransparency = TRANSPARENCY.glassCard
	keybindCard.BorderSizePixel = 0
	keybindCard.ZIndex = 2
	keybindCard.Parent = settingsFrame

	applyGlass(keybindCard,
		{ corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.7 })

	local kbTitle = Instance.new("TextLabel")
	kbTitle.Size = UDim2.new(0.5, 0, 1, 0)
	kbTitle.Position = UDim2.new(0, 12, 0, 0)
	kbTitle.BackgroundTransparency = 1
	kbTitle.Text = "Toggle Menu Keybind"
	kbTitle.TextColor3 = COLORS.textPrimary
	kbTitle.Font = Enum.Font.GothamMedium
	kbTitle.TextSize = 12
	kbTitle.TextXAlignment = Enum.TextXAlignment.Left
	kbTitle.ZIndex = 3
	kbTitle.Parent = keybindCard

	local kbValue = Instance.new("TextLabel")
	kbValue.Size = UDim2.new(0.5, -20, 1, 0)
	kbValue.Position = UDim2.new(0.5, 10, 0, 0)
	kbValue.BackgroundTransparency = 1
	kbValue.Text = "RightShift"
	kbValue.TextColor3 = COLORS.accentCyan
	kbValue.Font = Enum.Font.GothamBold
	kbValue.TextSize = 12
	kbValue.TextXAlignment = Enum.TextXAlignment.Right
	kbValue.ZIndex = 3
	kbValue.Parent = keybindCard

	-- Settings Toggle Cards Table
	local st = {}

	st.antiAfkCard, st.afkToggleTrack, st.afkToggleThumb = createGlassToggle(settingsFrame, "Anti-AFK (Keep Alive)", 0)
	st.antiAfkCard.Size = UDim2.new(1, 0, 0, 42)

	st.touchFlingCard, st.tfToggleTrack, st.tfToggleThumb = createGlassToggle(settingsFrame, "Touch Fling", 0)
	st.touchFlingCard.Size = UDim2.new(1, 0, 0, 42)

	st.antiFlingCard, st.afToggleTrack, st.afToggleThumb = createGlassToggle(settingsFrame, "No-Touch (Anti-Fling)", 0)
	st.antiFlingCard.Size = UDim2.new(1, 0, 0, 42)

	st.noclipCard, st.ncToggleTrack, st.ncToggleThumb = createGlassToggle(settingsFrame, "Noclip (Anti-Clip)", 0)
	st.noclipCard.Size = UDim2.new(1, 0, 0, 42)

	st.startMinimizedCard, st.smToggleTrack, st.smToggleThumb = createGlassToggle(settingsFrame, "Start Minimized", 0)
	st.startMinimizedCard.Size = UDim2.new(1, 0, 0, 42)

	-- Discord Button
	local discordButton = Instance.new("TextButton")
	discordButton.Size = UDim2.new(1, 0, 0, 36)
	discordButton.BackgroundColor3 = COLORS.accentViolet
	discordButton.BackgroundTransparency = 0.15
	discordButton.BorderSizePixel = 0
	discordButton.Text = "Join Discord"
	discordButton.TextColor3 = COLORS.textWhite
	discordButton.Font = Enum.Font.GothamBold
	discordButton.TextSize = 13
	discordButton.ZIndex = 2
	discordButton.Parent = settingsFrame

	applyGlass(discordButton,
		{ corner = CORNER.small, stroke = true, strokeColor = COLORS.accentViolet, strokeThickness = 1, strokeTransparency = 0.4 })

	pcall(function()
		discordButton.MouseEnter:Connect(function()
			TweenService:Create(discordButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
		end)
		discordButton.MouseLeave:Connect(function()
			TweenService:Create(discordButton, TweenInfo.new(0.2), { BackgroundTransparency = 0.15 }):Play()
		end)
	end)

	------------------------------------------------
	-- 🔵 RESTORE BUTTON (Floating Glass Orb)
	------------------------------------------------
	local restoreButton = Instance.new("ImageButton")
	restoreButton.Size = UDim2.new(0, 48, 0, 48)
	restoreButton.Position = UDim2.new(1, -68, 1, -68)
	restoreButton.BackgroundColor3 = COLORS.glassSurface
	restoreButton.BackgroundTransparency = 0.15
	restoreButton.BorderSizePixel = 0
	restoreButton.Visible = false
	restoreButton.ZIndex = 5
	restoreButton.Parent = gui

	local restCorner = Instance.new("UICorner")
	restCorner.CornerRadius = CORNER.pill
	restCorner.Parent = restoreButton

	local restStroke = Instance.new("UIStroke")
	restStroke.Color = COLORS.accentCyan
	restStroke.Thickness = 1.5
	restStroke.Transparency = 0.3
	restStroke.Parent = restoreButton

	local restText = Instance.new("TextLabel")
	restText.Size = UDim2.new(1, 0, 1, 0)
	restText.BackgroundTransparency = 1
	restText.Text = "Hip"
	restText.TextColor3 = COLORS.accentCyan
	restText.Font = Enum.Font.GothamBold
	restText.TextSize = 12
	restText.ZIndex = 6
	restText.Parent = restoreButton

	local function loadLogos()
		local getAsset = getcustomasset or getsynasset
		if getAsset then
			local hasDiskFile = false
			pcall(function()
				if isfile then
					hasDiskFile = isfile("LOGO_H_6.png")
				else
					hasDiskFile = true
				end
			end)

			if hasDiskFile then
				local ok, imgPath = pcall(function() return getAsset("LOGO_H_6.png") end)
				if ok and imgPath and imgPath ~= "" then
					restoreButton.Image = imgPath
					if titleLogo then
						titleLogo.Image = imgPath
					end
					restText.Visible = false
					return true
				end
			end
		end
		return false
	end

	pcall(function()
		local filename = "LOGO_H_6.png"
		local hasFile = false
		if isfile then
			pcall(function() hasFile = isfile(filename) end)
		end

		if not hasFile and writefile then
			task.spawn(function()
				local urls = {
					"https://hiphub.cloud/LOGO_H_6.png",
					"https://raw.githubusercontent.com/muhammadrafihq/gag-2/main/public/LOGO_H_6.png"
				}
				for _, url in ipairs(urls) do
					local ok, body = pcall(function()
						if game.HttpGet then
							return game:HttpGet(url)
						end
						local req = request or http_request or (syn and syn.request) or (http and http.request)
						if req then
							local res = req({ Url = url, Method = "GET" })
							return res and res.Body
						end
					end)

					if ok and body and #body > 0 then
						pcall(function()
							writefile(filename, body)
							task.wait(0.1)
							loadLogos()
						end)
						break
					end
				end
			end)
		end
	end)

	loadLogos()

	task.spawn(function()
		while restoreButton and restoreButton.Parent do
			if restoreButton.Visible then
				TweenService:Create(restStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Transparency = 0.7,
					Color = COLORS.accentViolet,
				}):Play()
				task.wait(1.2)
				if restoreButton and restoreButton.Visible then
					TweenService:Create(restStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{
							Transparency = 0.2,
							Color = COLORS.accentCyan,
						}):Play()
					task.wait(1.2)
				end
			else
				task.wait(0.5)
			end
		end
	end)

	------------------------------------------------
	-- 📐 RESIZE HANDLE
	------------------------------------------------
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Size = UDim2.new(0, 18, 0, 18)
	resizeHandle.Position = UDim2.new(1, -18, 1, -18)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Text = "⋱"
	resizeHandle.TextColor3 = COLORS.textMuted
	resizeHandle.Font = Enum.Font.GothamBold
	resizeHandle.TextSize = 14
	resizeHandle.ZIndex = 5
	resizeHandle.Parent = mainFrame

	pcall(function()
		resizeHandle.MouseEnter:Connect(function()
			TweenService:Create(resizeHandle, TweenInfo.new(0.15), { TextColor3 = COLORS.accentCyan }):Play()
		end)
		resizeHandle.MouseLeave:Connect(function()
			TweenService:Create(resizeHandle, TweenInfo.new(0.15), { TextColor3 = COLORS.textMuted }):Play()
		end)
	end)

	------------------------------------------------
	-- 📤 EXPOSE REFERENCES TO _G
	------------------------------------------------
	_G.HipHubUI = {
		-- Services
		TweenService = TweenService,
		UserInputService = UserInputService,

		-- Design tokens
		COLORS = COLORS,
		TRANSPARENCY = TRANSPARENCY,
		CORNER = CORNER,
		applyGlass = applyGlass,
		applyPadding = applyPadding,
		applyListLayout = applyListLayout,
		createGlassToggle = createGlassToggle,
		createCollapsibleSection = createCollapsibleSection,
		createGlassDropdown = createGlassDropdown,
		registerDropdownMenu = registerDropdownMenu,
		bindDropdown = bindDropdown,
		closeAllDropdowns = closeAllDropdowns,

		-- Main UI containers
		gui = gui,
		mainFrame = mainFrame,
		shadowFrame = shadowFrame,
		topBar = topBar,
		badge = badge,
		closeButton = closeButton,
		minimizeButton = minimizeButton,
		fullscreenButton = fullscreenButton,
		restoreButton = restoreButton,
		resizeHandle = resizeHandle,
		profileCard = profileCard,
		avatarLabel = avatarLabel,
		usernameLabel = usernameLabel,

		-- Tab containers
		tabs = tabs,
		tabButtons = tabButtons,
		selectTab = selectTab,
		addTab = addTab,

		-- Main tab specific elements
		mainFrameContent = mainFrameContent,

		-- Misc tab specific elements
		miscFrameContent = tabs["Misc"] and tabs["Misc"].Frame,

		-- Settings tab elements
		settingsFrame = settingsFrame,
		keybindCard = keybindCard,
		kbValue = kbValue,
		antiAfkCard = st.antiAfkCard,
		afkToggleTrack = st.afkToggleTrack,
		afkToggleThumb = st.afkToggleThumb,
		touchFlingCard = st.touchFlingCard,
		tfToggleTrack = st.tfToggleTrack,
		tfToggleThumb = st.tfToggleThumb,
		antiFlingCard = st.antiFlingCard,
		afToggleTrack = st.afToggleTrack,
		afToggleThumb = st.afToggleThumb,
		noclipCard = st.noclipCard,
		ncToggleTrack = st.ncToggleTrack,
		ncToggleThumb = st.ncToggleThumb,
		startMinimizedCard = st.startMinimizedCard,
		smToggleTrack = st.smToggleTrack,
		smToggleThumb = st.smToggleThumb,
		discordButton = discordButton,

		-- Shadow sync utility
		syncShadow = syncShadow,

		-- Fullscreen icon update utility
		updateFullscreenIcon = updateFullscreenIcon,
	}

	-- Set default tab
	selectTab("Main")
end)

if not success then
	warn("HipHub UI Init Error: " .. tostring(err))
	local errGui = Instance.new("ScreenGui")
	errGui.Name = "HipHubError"
	errGui.ResetOnSpawn = false
	errGui.DisplayOrder = 2147483647

	pcall(function()
		errGui.Parent = player:WaitForChild("PlayerGui")

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0, 480, 0, 160)
		frame.Position = UDim2.new(0.5, -240, 0.5, -80)
		frame.BackgroundColor3 = Color3.fromRGB(16, 8, 8)
		frame.BackgroundTransparency = 0.1
		frame.BorderSizePixel = 0
		frame.Parent = errGui

		local errCorner = Instance.new("UICorner")
		errCorner.CornerRadius = UDim.new(0, 14)
		errCorner.Parent = frame

		local errStroke = Instance.new("UIStroke")
		errStroke.Color = Color3.fromRGB(255, 60, 60)
		errStroke.Thickness = 1
		errStroke.Transparency = 0.5
		errStroke.Parent = frame

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -20, 0, 30)
		title.Position = UDim2.new(0, 10, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = "HipHub UI Init Error"
		title.TextColor3 = Color3.fromRGB(255, 80, 80)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = frame

		local body = Instance.new("TextLabel")
		body.Size = UDim2.new(1, -20, 1, -50)
		body.Position = UDim2.new(0, 10, 0, 40)
		body.BackgroundTransparency = 1
		body.Text = tostring(err)
		body.TextColor3 = Color3.fromRGB(200, 180, 180)
		body.Font = Enum.Font.Gotham
		body.TextSize = 12
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.Parent = frame
	end)
end
