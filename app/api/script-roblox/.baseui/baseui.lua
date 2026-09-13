-- Liquid Glass Futuristic UI Base
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
		local file = nil
		if isfile then
			if isfile("HipHub/sae/config.json") then
				file = "HipHub/sae/config.json"
			elseif isfile("HipHub/" .. tostring(game.PlaceId) .. "/config.json") then
				file = "HipHub/" .. tostring(game.PlaceId) .. "/config.json"
			elseif isfile("HipHub/config.json") then
				file = "HipHub/config.json"
			elseif isfile("hiphub_config.json") then
				file = "hiphub_config.json"
			end
		end
		if file and isfile(file) and readfile then
			local configData = HttpService:JSONDecode(readfile(file))
			if configData and (configData.misc or configData.fpsBooster ~= nil) then
				local misc = configData.misc or configData
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

	local rarityNames = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

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

	local function createTextBoxRow(labelText, defaultValue)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundColor3 = COLORS.glassSurface
		row.BackgroundTransparency = 0.25
		row.BorderSizePixel = 0

		applyGlass(row, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.45, 0, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = COLORS.textPrimary
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Parent = row

		local input = Instance.new("TextBox")
		input.Size = UDim2.new(0, 140, 0, 24)
		input.Position = UDim2.new(1, -150, 0.5, -12)
		input.BackgroundColor3 = Color3.fromRGB(24, 28, 48)
		input.BackgroundTransparency = 0.2
		input.Text = defaultValue
		input.TextColor3 = COLORS.textWhite
		input.TextSize = 11
		input.Font = Enum.Font.GothamBold
		input.TextTruncate = Enum.TextTruncate.AtEnd
		input.ClearTextOnFocus = false
		input.ZIndex = 3
		input.Active = true
		input.Selectable = true
		input.Parent = row

		local inputCorner = Instance.new("UICorner")
		inputCorner.CornerRadius = CORNER.small
		inputCorner.Parent = input

		local inputStroke = Instance.new("UIStroke")
		inputStroke.Color = COLORS.borderGlass
		inputStroke.Thickness = 1
		inputStroke.Parent = input

		return row, input
	end

	local function createButtonRow(labelText, defaultButtonText)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundColor3 = COLORS.glassSurface
		row.BackgroundTransparency = 0.25
		row.BorderSizePixel = 0

		applyGlass(row, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -175, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = COLORS.textPrimary
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Parent = row

		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 160, 0, 24)
		button.Position = UDim2.new(1, -170, 0.5, -12)
		button.BackgroundColor3 = Color3.fromRGB(24, 28, 48)
		button.BackgroundTransparency = 0.2
		button.BorderSizePixel = 0
		button.Text = ""
		button.ZIndex = 3
		button.Active = true
		button.Selectable = true
		button.Parent = row

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = CORNER.small
		buttonCorner.Parent = button

		local buttonStroke = Instance.new("UIStroke")
		buttonStroke.Color = COLORS.accentCyan
		buttonStroke.Thickness = 1.2
		buttonStroke.Transparency = 0.3
		buttonStroke.Parent = button

		local btnTextLabel = Instance.new("TextLabel")
		btnTextLabel.Name = "ButtonText"
		btnTextLabel.Size = UDim2.new(1, -24, 1, 0)
		btnTextLabel.Position = UDim2.new(0, 8, 0, 0)
		btnTextLabel.BackgroundTransparency = 1
		btnTextLabel.Text = defaultButtonText or "All Eggs"
		btnTextLabel.TextColor3 = COLORS.textWhite
		btnTextLabel.Font = Enum.Font.GothamBold
		btnTextLabel.TextSize = 11
		btnTextLabel.TextXAlignment = Enum.TextXAlignment.Left
		btnTextLabel.TextTruncate = Enum.TextTruncate.AtEnd
		btnTextLabel.ZIndex = 4
		btnTextLabel.Parent = button

		local arrow = Instance.new("TextLabel")
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0, 18, 1, 0)
		arrow.Position = UDim2.new(1, -18, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = "v"
		arrow.TextColor3 = COLORS.accentCyan
		arrow.Font = Enum.Font.GothamBold
		arrow.TextSize = 10
		arrow.ZIndex = 4
		arrow.Parent = button

		local rawButton = button
		local wrapper = setmetatable({}, {
			__index = function(_, k)
				if k == "Text" then
					return btnTextLabel.Text
				end
				local val = rawButton[k]
				if type(val) == "function" then
					return function(_, ...)
						return val(rawButton, ...)
					end
				end
				return val
			end,
			__newindex = function(_, k, v)
				if k == "Text" then
					btnTextLabel.Text = tostring(v)
				else
					rawButton[k] = v
				end
			end
		})

		return row, wrapper
	end

	local function createInputRow(parent, labelText, placeholderText, defaultVal, layoutOrder, onChange)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = COLORS.glassCard
		row.BackgroundTransparency = TRANSPARENCY.glassCard
		row.BorderSizePixel = 0
		row.LayoutOrder = layoutOrder or 0
		row.ZIndex = 2
		row.Parent = parent

		applyGlass(row, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.75,
		})

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
		title.Parent = row

		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(0, 70, 0, 24)
		inputBox.Position = UDim2.new(1, -80, 0.5, -12)
		inputBox.BackgroundColor3 = COLORS.glassSurface
		inputBox.BackgroundTransparency = 0.25
		inputBox.BorderSizePixel = 0
		inputBox.Text = tostring(defaultVal or "")
		inputBox.PlaceholderText = placeholderText or "5"
		inputBox.PlaceholderColor3 = COLORS.textMuted
		inputBox.TextColor3 = COLORS.accentCyan
		inputBox.Font = Enum.Font.GothamBold
		inputBox.TextSize = 12
		inputBox.TextXAlignment = Enum.TextXAlignment.Center
		inputBox.ZIndex = 4
		inputBox.Parent = row

		applyGlass(inputBox, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		if onChange then
			inputBox.FocusLost:Connect(function()
				onChange(inputBox.Text)
			end)
		end

		return row, inputBox
	end

	local function createLogLine(text, color)
		local line                  = Instance.new("TextLabel")
		line.Size                   = UDim2.new(1, -6, 0, 16)
		line.BackgroundTransparency = 1
		line.Text                   = text
		line.TextColor3             = color
		line.Font                   = Enum.Font.Code
		line.TextSize               = 11
		line.TextXAlignment         = Enum.TextXAlignment.Left
		line.TextTruncate           = Enum.TextTruncate.AtEnd
		return line
	end

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
		track.BackgroundColor3 = COLORS.toggleOff
		track.BackgroundTransparency = 0.15
		track.BorderSizePixel = 0
		track.Text = ""
		track.ZIndex = 3
		track.Active = true
		track.Selectable = true
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
		thumb.Active = false
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

	local function createCollapsibleSection(parent, title, layoutOrder, defaultExpanded)
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

		local isCollapsed = not (defaultExpanded == true)
		if not isCollapsed then
			arrow.Rotation = 90
		end

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 0, 0)
		container.BackgroundTransparency = 1
		container.LayoutOrder = layoutOrder + 1
		container.ClipsDescendants = true
		container.Visible = not isCollapsed
		container.Parent = parent

		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, 0, 0, 0)
		content.Position = UDim2.new(0, 0, 0, 0)
		content.BackgroundTransparency = 1
		content.Visible = not isCollapsed
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

		header.MouseButton1Click:Connect(function()
			isCollapsed = not isCollapsed
			container.Visible = true
			content.Visible = true
			local targetRot = isCollapsed and 0 or 90
			local targetH = isCollapsed and 0 or contentLayout.AbsoluteContentSize.Y + 12

			TweenService:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Rotation = targetRot }):Play()
			local tween = TweenService:Create(container,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(1, 0, 0, targetH) })
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

		task.spawn(function()
			task.wait(0.1)
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

	local syncDropdownPosition = function() end
	local function syncShadow()
		shadowFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 6,
			mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 6
		)
		shadowFrame.Size = UDim2.new(
			mainFrame.Size.X.Scale, mainFrame.Size.X.Offset + 12,
			mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset + 12
		)
		pcall(syncDropdownPosition)
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
	closeButton.Text = "X"
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
	addTab("Info", "", 1)
	addTab("Steal", "", 2)
	addTab("Place", "", 3)
	addTab("ESP", "", 4)
	addTab("Misc", "", 5)
	addTab("Webhook", "", 6)
	addTab("Settings", "", 7)

	------------------------------------------------
	-- 📱 MAIN TAB (Welcome & Stats Dashboard)
	------------------------------------------------
	local mainFrameContent = tabs["Info"].Frame
	applyListLayout(mainFrameContent, 10)

	-- Welcome Header Card
	local welcomeCard = Instance.new("Frame")
	welcomeCard.Size = UDim2.new(1, 0, 0, 80)
	welcomeCard.BackgroundColor3 = COLORS.glassCard
	welcomeCard.BackgroundTransparency = TRANSPARENCY.glassCard
	welcomeCard.BorderSizePixel = 0
	welcomeCard.LayoutOrder = 1
	welcomeCard.Parent = mainFrameContent

	applyGlass(welcomeCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7,
		gradient = true,
		gradientRotation = 120
	})

	local wlTitle = Instance.new("TextLabel")
	wlTitle.Size = UDim2.new(1, -24, 0, 30)
	wlTitle.Position = UDim2.new(0, 12, 0, 12)
	wlTitle.BackgroundTransparency = 1
	wlTitle.Text = "Welcome to HipHub, " .. player.DisplayName .. "!"
	wlTitle.TextColor3 = COLORS.textWhite
	wlTitle.Font = Enum.Font.GothamBold
	wlTitle.TextSize = 14
	wlTitle.TextXAlignment = Enum.TextXAlignment.Left
	wlTitle.Parent = welcomeCard

	local wlDesc = Instance.new("TextLabel")
	wlDesc.Size = UDim2.new(1, -24, 0, 30)
	wlDesc.Position = UDim2.new(0, 12, 0, 38)
	wlDesc.BackgroundTransparency = 1
	wlDesc.Text = "Clean UI Base is active and ready!"
	wlDesc.TextColor3 = COLORS.textSecondary
	wlDesc.Font = Enum.Font.Gotham
	wlDesc.TextSize = 11
	wlDesc.TextWrapped = true
	wlDesc.TextXAlignment = Enum.TextXAlignment.Left
	wlDesc.Parent = welcomeCard

	-- Stats grid card
	local statsCard = Instance.new("Frame")
	statsCard.Size = UDim2.new(1, 0, 0, 160)
	statsCard.BackgroundColor3 = COLORS.glassCard
	statsCard.BackgroundTransparency = TRANSPARENCY.glassCard
	statsCard.BorderSizePixel = 0
	statsCard.LayoutOrder = 2
	statsCard.Parent = mainFrameContent

	applyGlass(statsCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	local scTitle = Instance.new("TextLabel")
	scTitle.Size = UDim2.new(1, -24, 0, 26)
	scTitle.Position = UDim2.new(0, 12, 0, 8)
	scTitle.BackgroundTransparency = 1
	scTitle.Text = "SYSTEM STATUS"
	scTitle.TextColor3 = COLORS.accentCyan
	scTitle.Font = Enum.Font.GothamBold
	scTitle.TextSize = 10
	scTitle.TextXAlignment = Enum.TextXAlignment.Left
	scTitle.Parent = statsCard

	local scGrid = Instance.new("Frame")
	scGrid.Size = UDim2.new(1, -24, 1, -40)
	scGrid.Position = UDim2.new(0, 12, 0, 32)
	scGrid.BackgroundTransparency = 1
	scGrid.Parent = statsCard

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -6, 0, 50)
	gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = scGrid

	local function addStatBox(titleText, valueText, order)
		local box = Instance.new("Frame")
		box.BackgroundColor3 = COLORS.glassSurface
		box.BackgroundTransparency = 0.25
		box.BorderSizePixel = 0
		box.LayoutOrder = order
		box.Parent = scGrid

		applyGlass(box,
			{ corner = CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.85 })

		local bTitle = Instance.new("TextLabel")
		bTitle.Size = UDim2.new(1, -16, 0, 18)
		bTitle.Position = UDim2.new(0, 8, 0, 6)
		bTitle.BackgroundTransparency = 1
		bTitle.Text = titleText:upper()
		bTitle.TextColor3 = COLORS.textMuted
		bTitle.Font = Enum.Font.GothamMedium
		bTitle.TextSize = 9
		bTitle.TextXAlignment = Enum.TextXAlignment.Left
		bTitle.Parent = box

		local bVal = Instance.new("TextLabel")
		bVal.Size = UDim2.new(1, -16, 0, 22)
		bVal.Position = UDim2.new(0, 8, 0, 22)
		bVal.BackgroundTransparency = 1
		bVal.Text = valueText
		bVal.TextColor3 = COLORS.textPrimary
		bVal.Font = Enum.Font.GothamBold
		bVal.TextSize = 12
		bVal.TextXAlignment = Enum.TextXAlignment.Left
		bVal.Parent = box

		return bVal
	end

	local executorText = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or
		"Unknown Executor"
	addStatBox("Executor Detected", tostring(executorText), 1)
	addStatBox("Account Tier", (_G.hiphub_role == "premium" and "Premium Access") or "Free Tier", 2)
	local uptimeLabel = addStatBox("Session Uptime", "00:00:00", 3)
	local pingLabel = addStatBox("Ping Time", "Calculating...", 4)

	-- Live Stats Updates
	task.spawn(function()
		local startTime = os.time()
		while statsCard and statsCard.Parent do
			task.wait(1)
			local elapsed = os.time() - startTime
			local hours = math.floor(elapsed / 3600)
			local mins = math.floor((elapsed % 3600) / 60)
			local secs = elapsed % 60
			uptimeLabel.Text = string.format("%02d:%02d:%02d", hours, mins, secs)

			local successPing, pingVal = pcall(function()
				return player:GetNetworkPing() * 1000
			end)
			if successPing then
				pingLabel.Text = string.format("%d ms", math.round(pingVal))
			else
				pingLabel.Text = "N/A"
			end
		end
	end)

	------------------------------------------------
	-- 🥚 STEAL EGG TAB
	------------------------------------------------
	local stealFrame = tabs["Steal"].Frame
	applyListLayout(stealFrame, 10)

	-- Status & Control Card
	local stealControlCard = Instance.new("Frame")
	stealControlCard.Size = UDim2.new(1, 0, 0, 0)
	stealControlCard.AutomaticSize = Enum.AutomaticSize.Y
	stealControlCard.BackgroundColor3 = COLORS.glassCard
	stealControlCard.BackgroundTransparency = TRANSPARENCY.glassCard
	stealControlCard.BorderSizePixel = 0
	stealControlCard.Parent = stealFrame

	applyGlass(stealControlCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7,
		gradient = true,
		gradientRotation = 120
	})
	applyPadding(stealControlCard, 14, 14, 12, 12)

	local stealStatusLabel = Instance.new("TextLabel")
	stealStatusLabel.Size = UDim2.new(1, 0, 0, 0)
	stealStatusLabel.Position = UDim2.new(0, 0, 0, 0)
	stealStatusLabel.AutomaticSize = Enum.AutomaticSize.Y
	stealStatusLabel.BackgroundTransparency = 1
	stealStatusLabel.Text = "Status: <font color='#ff4d4d'>Inactive</font>\nTotal Stolen: 0"
	stealStatusLabel.TextColor3 = COLORS.textSecondary
	stealStatusLabel.TextSize = 12
	stealStatusLabel.RichText = true
	stealStatusLabel.TextWrapped = true
	stealStatusLabel.Font = Enum.Font.GothamMedium
	stealStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	stealStatusLabel.LineHeight = 1.35
	stealStatusLabel.Parent = stealControlCard

	-- Toggles Card
	local stealTogglesCard = Instance.new("Frame")
	stealTogglesCard.Size = UDim2.new(1, 0, 0, 0)
	stealTogglesCard.AutomaticSize = Enum.AutomaticSize.Y
	stealTogglesCard.BackgroundColor3 = COLORS.glassCard
	stealTogglesCard.BackgroundTransparency = TRANSPARENCY.glassCard
	stealTogglesCard.BorderSizePixel = 0
	stealTogglesCard.Parent = stealFrame

	applyGlass(stealTogglesCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	applyListLayout(stealTogglesCard, 8)
	applyPadding(stealTogglesCard, 10, 10, 10, 10)

	local eggFilterRow, eggFilterBtn = createButtonRow("Target Area Filter", "All Eggs")
	eggFilterRow.Size = UDim2.new(1, 0, 0, 36)
	eggFilterRow.Parent = stealTogglesCard

	local rarityFilterRow, rarityFilterBtn = createButtonRow("Target Rarity Filter", "All Rarities")
	rarityFilterRow.Size = UDim2.new(1, 0, 0, 36)
	rarityFilterRow.Parent = stealTogglesCard

	-- Target Value Filter Dropdown Row
	local valueFilterRow, valueFilterBtn = createButtonRow("Target Value Filter", "Off")
	valueFilterRow.Size = UDim2.new(1, 0, 0, 36)
	valueFilterRow.Parent = stealTogglesCard

	-- Value Threshold (M$) Input Row
	local valueInputRow, valueInputBox = createInputRow(stealTogglesCard, "Value Threshold (M$)", "1 (1M$)", "", 4, function(val)
		local num = tonumber(val) or 0
		if _G.HipHubSteal and _G.HipHubSteal.setState then
			_G.HipHubSteal.setState({ valueThreshold = num })
		elseif _G.HipHubStealConfig then
			_G.HipHubStealConfig.valueThreshold = num
		end
		if _G.HipHubUI and _G.HipHubUI.saveConfig then
			pcall(_G.HipHubUI.saveConfig)
		end
	end)
	valueInputRow.Size = UDim2.new(1, 0, 0, 36)

	-- Tween Speed (studs/s) Input Row
	local speedInputRow, speedInputBox = createInputRow(stealTogglesCard, "Tween Speed (Studs/s)", "500", "500", 5, function(val)
		local num = tonumber(val)
		if num and num > 0 then
			if _G.HipHubSteal and _G.HipHubSteal.setTweenSpeed then
				_G.HipHubSteal.setTweenSpeed(num)
			elseif _G.HipHubStealConfig then
				_G.HipHubStealConfig.tweenSpeed = num
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end
	end)
	speedInputRow.Size = UDim2.new(1, 0, 0, 36)

	-- Turbo Mode Toggle
	local turboCard, turboTrack, turboThumb = createGlassToggle(stealTogglesCard, "Turbo Mode", 6)
	turboCard.Size = UDim2.new(1, 0, 0, 36)

	local autoStealCard, autoStealTrack, autoStealThumb = createGlassToggle(stealTogglesCard, "Auto Steal Eggs", 7)
	autoStealCard.Size = UDim2.new(1, 0, 0, 36)

	-- Anti Ragdoll & Fling Toggle
	local antiRagdollCard, arToggleTrack, arToggleThumb = createGlassToggle(stealTogglesCard, "Anti Ragdoll & Fling (Godmode)", 8)
	antiRagdollCard.Size = UDim2.new(1, 0, 0, 36)

	-- Multi-select Egg Area & Rarity Filter Overlay Panels
	local selectedAreas = { ["All Eggs"] = true }
	local selectedRarities = { ["All Rarities"] = true }

	local dropdownDismissArea = Instance.new("TextButton")
	dropdownDismissArea.Size = UDim2.new(1, 0, 1, 0)
	dropdownDismissArea.Position = UDim2.new(0, 0, 0, 0)
	dropdownDismissArea.BackgroundTransparency = 1
	dropdownDismissArea.Text = ""
	dropdownDismissArea.Visible = false
	dropdownDismissArea.ZIndex = 499
	dropdownDismissArea.Parent = mainFrame

	local activeOverlay = nil
	local function closeDropdowns()
		if activeOverlay then
			activeOverlay.Visible = false
		end
		activeOverlay = nil
		dropdownDismissArea.Visible = false
	end

	dropdownDismissArea.MouseButton1Click:Connect(closeDropdowns)

	local function createDropdownMenu(options, defaultSelectedName, onUpdateCallback, isSingleSelect)
		local selectedMap = { [defaultSelectedName] = true }

		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.new(0, 200, 1, -56)
		overlay.Position = UDim2.new(1, -210, 0, 48)
		overlay.BackgroundColor3 = COLORS.glassPrimary
		overlay.BackgroundTransparency = 0.05
		overlay.BorderSizePixel = 0
		overlay.Visible = false
		overlay.ZIndex = 500
		overlay.Parent = mainFrame

		applyGlass(overlay, {
			corner = CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlow,
			strokeThickness = 1.5,
			strokeTransparency = TRANSPARENCY.borderGlow,
			gradient = true,
			gradientRotation = 145,
		})

		local searchBox = Instance.new("TextBox")
		searchBox.Size = UDim2.new(1, -20, 0, 30)
		searchBox.Position = UDim2.new(0, 10, 0, 10)
		searchBox.BackgroundColor3 = COLORS.glassSurface
		searchBox.BackgroundTransparency = 0.25
		searchBox.Text = ""
		searchBox.PlaceholderText = "Search..."
		searchBox.PlaceholderColor3 = COLORS.textMuted
		searchBox.TextColor3 = COLORS.textWhite
		searchBox.Font = Enum.Font.GothamMedium
		searchBox.TextSize = 11
		searchBox.ZIndex = 501
		searchBox.Parent = overlay

		applyGlass(searchBox, {
			corner = CORNER.small,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.85
		})

		local scrollContainer = Instance.new("ScrollingFrame")
		scrollContainer.Size = UDim2.new(1, -16, 1, -56)
		scrollContainer.Position = UDim2.new(0, 8, 0, 48)
		scrollContainer.BackgroundTransparency = 1
		scrollContainer.BorderSizePixel = 0
		scrollContainer.ScrollBarThickness = 3
		scrollContainer.ScrollBarImageColor3 = COLORS.accentCyan
		scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		scrollContainer.ZIndex = 501
		scrollContainer.Parent = overlay

		if isSingleSelect and #options <= 4 then
			searchBox.Visible = false
			scrollContainer.Position = UDim2.new(0, 8, 0, 10)
			scrollContainer.Size = UDim2.new(1, -16, 1, -20)
			overlay.Size = UDim2.new(0, 200, 0, #options * 38 + 20)
		end

		local scrollLayout = Instance.new("UIListLayout")
		scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
		scrollLayout.Padding = UDim.new(0, 4)
		scrollLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		scrollLayout.Parent = scrollContainer

		applyPadding(scrollContainer, 4, 4, 4, 4)

		scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scrollContainer.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 8)
		end)

		local optionRows = {}

		local function getSelectedList()
			local list = {}
			for name, isSel in pairs(selectedMap) do
				if isSel then
					table.insert(list, name)
				end
			end
			if #list == 0 then
				return { defaultSelectedName }
			end
			return list
		end

		local function updateSummary()
			local activeList = getSelectedList()
			local summaryText = ""
			if #activeList == 0 or (#activeList == 1 and activeList[1] == defaultSelectedName) then
				summaryText = defaultSelectedName
			elseif #activeList == #options - 1 and not selectedMap[defaultSelectedName] then
				summaryText = "All Selected"
			else
				summaryText = table.concat(activeList, ", ")
			end

			if onUpdateCallback then
				onUpdateCallback(summaryText, activeList)
			end
		end

		for idx, name in ipairs(options) do
			local card = Instance.new("TextButton")
			card.Size = UDim2.new(1, 0, 0, 32)
			card.BackgroundColor3 = COLORS.glassActive
			card.BackgroundTransparency = selectedMap[name] and 0.15 or 1
			card.BorderSizePixel = 0
			card.Text = ""
			card.LayoutOrder = idx
			card.ZIndex = 502
			card.Parent = scrollContainer

			local cCorner = Instance.new("UICorner")
			cCorner.CornerRadius = CORNER.small
			cCorner.Parent = card

			local indicator = Instance.new("Frame")
			indicator.Size = UDim2.new(0, 3, 0, 16)
			indicator.Position = UDim2.new(0, 4, 0.5, -8)
			indicator.BackgroundColor3 = COLORS.accentCyan
			indicator.BorderSizePixel = 0
			indicator.Visible = selectedMap[name] == true
			indicator.ZIndex = 503
			indicator.Parent = card

			local indCorner = Instance.new("UICorner")
			indCorner.CornerRadius = UDim.new(0, 2)
			indCorner.Parent = indicator

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -16, 1, 0)
			label.Position = UDim2.new(0, 14, 0, 0)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = selectedMap[name] and COLORS.textWhite or COLORS.textSecondary
			label.Font = selectedMap[name] and Enum.Font.GothamBold or Enum.Font.GothamMedium
			label.TextSize = 11
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.ZIndex = 503
			label.Parent = card

			table.insert(optionRows, { Name = name, Card = card, Indicator = indicator, Label = label })

			card.MouseButton1Click:Connect(function()
				if isSingleSelect then
					selectedMap = { [name] = true }
				elseif name == defaultSelectedName then
					selectedMap = { [defaultSelectedName] = true }
				else
					selectedMap[defaultSelectedName] = nil
					selectedMap[name] = not selectedMap[name]

					local anyRemaining = false
					for _, isSel in pairs(selectedMap) do
						if isSel then
							anyRemaining = true
							break
						end
					end
					if not anyRemaining then
						selectedMap[defaultSelectedName] = true
					end
				end

				for _, item in ipairs(optionRows) do
					local isSelected = selectedMap[item.Name] == true
					item.Card.BackgroundTransparency = isSelected and 0.15 or 1
					item.Indicator.Visible = isSelected
					item.Label.TextColor3 = isSelected and COLORS.textWhite or COLORS.textSecondary
					item.Label.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamMedium
				end

				updateSummary()
				if isSingleSelect then
					closeDropdowns()
				end
			end)
		end

		local function setSelectedList(activeList)
			selectedMap = {}
			if type(activeList) == "table" and #activeList > 0 then
				for _, name in ipairs(activeList) do
					selectedMap[name] = true
				end
			else
				selectedMap[defaultSelectedName] = true
			end

			for _, item in ipairs(optionRows) do
				local isSelected = selectedMap[item.Name] == true
				item.Card.BackgroundTransparency = isSelected and 0.15 or 1
				item.Indicator.Visible = isSelected
				item.Label.TextColor3 = isSelected and COLORS.textWhite or COLORS.textSecondary
				item.Label.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamMedium
			end

			updateSummary()
		end

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBox.Text:lower():gsub("%s+", "")
			for _, item in ipairs(optionRows) do
				local cleanName = item.Name:lower():gsub("%s+", "")
				if query == "" or cleanName:find(query, 1, true) ~= nil then
					item.Card.Visible = true
				else
					item.Card.Visible = false
				end
			end
		end)

		return overlay, setSelectedList
	end

	local filterOptions = {
		"All Eggs",
		"Forest",
		"Lake",
		"Desert",
		"Jungle",
		"Snow",
		"Volcano",
		"Abyss Ocean",
		"Prehistoric",
		"Cosmic"
	}

	local rarityOptions = {
		"All Rarities",
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Cosmic",
		"Secret",
		"Eternal",
		"Divine"
	}

	local valueOptions = {
		"Off",
		"Above (>=)",
		"Below (<=)"
	}

	local areaOverlay, setAreaFilter = createDropdownMenu(filterOptions, "All Eggs", function(summaryText, activeList)
		eggFilterBtn.Text = summaryText
		if _G.HipHubSteal and _G.HipHubSteal.setState then
			_G.HipHubSteal.setState({
				selectedEggFilter = summaryText,
				selectedEggFilters = activeList
			})
		elseif _G.HipHubStealConfig then
			_G.HipHubStealConfig.selectedEggFilter = summaryText
			_G.HipHubStealConfig.selectedEggFilters = activeList
		end
		if _G.HipHubUI and _G.HipHubUI.saveConfig then
			pcall(_G.HipHubUI.saveConfig)
		end
	end)

	local rarityOverlay, setRarityFilter = createDropdownMenu(rarityOptions, "All Rarities",
		function(summaryText, activeList)
			rarityFilterBtn.Text = summaryText
			if _G.HipHubSteal and _G.HipHubSteal.setState then
				_G.HipHubSteal.setState({
					selectedRarityFilter = summaryText,
					selectedRarityFilters = activeList
				})
			elseif _G.HipHubStealConfig then
				_G.HipHubStealConfig.selectedRarityFilter = summaryText
				_G.HipHubStealConfig.selectedRarityFilters = activeList
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)

	local valueOverlay, setValueFilter = createDropdownMenu(valueOptions, "Off", function(summaryText, activeList)
		valueFilterBtn.Text = summaryText
		local selectedMode = (type(activeList) == "table" and activeList[1]) or summaryText or "Off"
		if _G.HipHubSteal and _G.HipHubSteal.setState then
			_G.HipHubSteal.setState({
				valueFilterMode = selectedMode
			})
		elseif _G.HipHubStealConfig then
			_G.HipHubStealConfig.valueFilterMode = selectedMode
		end
		if _G.HipHubUI and _G.HipHubUI.saveConfig then
			pcall(_G.HipHubUI.saveConfig)
		end
	end, true)

	eggFilterBtn.MouseButton1Click:Connect(function()
		if activeOverlay == areaOverlay then
			closeDropdowns()
		else
			closeDropdowns()
			activeOverlay = areaOverlay
			areaOverlay.Visible = true
			dropdownDismissArea.Visible = true
		end
	end)

	rarityFilterBtn.MouseButton1Click:Connect(function()
		if activeOverlay == rarityOverlay then
			closeDropdowns()
		else
			closeDropdowns()
			activeOverlay = rarityOverlay
			rarityOverlay.Visible = true
			dropdownDismissArea.Visible = true
		end
	end)

	valueFilterBtn.MouseButton1Click:Connect(function()
		if activeOverlay == valueOverlay then
			closeDropdowns()
		else
			closeDropdowns()
			activeOverlay = valueOverlay
			valueOverlay.Visible = true
			dropdownDismissArea.Visible = true
		end
	end)

	------------------------------------------------
	-- 🪹 PLACE EGG TAB
	------------------------------------------------
	local placeFrame = tabs["Place"].Frame
	applyListLayout(placeFrame, 10)

	-- Status Card
	local placeControlCard = Instance.new("Frame")
	placeControlCard.Size = UDim2.new(1, 0, 0, 0)
	placeControlCard.AutomaticSize = Enum.AutomaticSize.Y
	placeControlCard.BackgroundColor3 = COLORS.glassCard
	placeControlCard.BackgroundTransparency = TRANSPARENCY.glassCard
	placeControlCard.BorderSizePixel = 0
	placeControlCard.Parent = placeFrame

	applyGlass(placeControlCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7,
		gradient = true,
		gradientRotation = 120
	})
	applyPadding(placeControlCard, 14, 14, 12, 12)

	local placeStatusLabel = Instance.new("TextLabel")
	placeStatusLabel.Size = UDim2.new(1, 0, 0, 0)
	placeStatusLabel.Position = UDim2.new(0, 0, 0, 0)
	placeStatusLabel.AutomaticSize = Enum.AutomaticSize.Y
	placeStatusLabel.BackgroundTransparency = 1
	placeStatusLabel.Text = "Status: <font color='#ff4d4d'>Inactive</font>\nTotal Placed: 0"
	placeStatusLabel.TextColor3 = COLORS.textSecondary
	placeStatusLabel.TextSize = 12
	placeStatusLabel.RichText = true
	placeStatusLabel.TextWrapped = true
	placeStatusLabel.Font = Enum.Font.GothamMedium
	placeStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	placeStatusLabel.LineHeight = 1.35
	placeStatusLabel.Parent = placeControlCard

	-- Toggles Card
	local placeTogglesCard = Instance.new("Frame")
	placeTogglesCard.Size = UDim2.new(1, 0, 0, 0)
	placeTogglesCard.AutomaticSize = Enum.AutomaticSize.Y
	placeTogglesCard.BackgroundColor3 = COLORS.glassCard
	placeTogglesCard.BackgroundTransparency = TRANSPARENCY.glassCard
	placeTogglesCard.BorderSizePixel = 0
	placeTogglesCard.Parent = placeFrame

	applyGlass(placeTogglesCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	applyListLayout(placeTogglesCard, 8)
	applyPadding(placeTogglesCard, 10, 10, 10, 10)

	local placeFilterRow, placeFilterBtn = createButtonRow("Target Area Filter", "All Eggs")
	placeFilterRow.Size = UDim2.new(1, 0, 0, 36)
	placeFilterRow.Parent = placeTogglesCard

	-- Separate dropdown instance for Place tab
	local placeAreaOverlay, setPlaceAreaFilter = createDropdownMenu(filterOptions, "All Eggs",
		function(summaryText, activeList)
			placeFilterBtn.Text = summaryText
			if _G.HipHubPlace then
				_G.HipHubPlace.setState({
					selectedAreaFilter = summaryText,
					selectedAreaFilters = activeList
				})
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)

	placeFilterBtn.MouseButton1Click:Connect(function()
		if activeOverlay == placeAreaOverlay then
			closeDropdowns()
		else
			closeDropdowns()
			activeOverlay = placeAreaOverlay
			placeAreaOverlay.Visible = true
			dropdownDismissArea.Visible = true
		end
	end)

	local autoPlaceCard, autoPlaceTrack, autoPlaceThumb = createGlassToggle(placeTogglesCard, "Auto Place Eggs", 3)
	autoPlaceCard.Size = UDim2.new(1, 0, 0, 36)

	local autoHatchCard, autoHatchTrack, autoHatchThumb = createGlassToggle(placeTogglesCard, "Auto Hatch Eggs", 4)
	autoHatchCard.Size = UDim2.new(1, 0, 0, 36)

	------------------------------------------------
	-- 👁️ ESP TAB
	------------------------------------------------
	local espFrame = tabs["ESP"].Frame
	applyListLayout(espFrame, 10)

	-- Status Card
	local espControlCard = Instance.new("Frame")
	espControlCard.Size = UDim2.new(1, 0, 0, 0)
	espControlCard.AutomaticSize = Enum.AutomaticSize.Y
	espControlCard.BackgroundColor3 = COLORS.glassCard
	espControlCard.BackgroundTransparency = TRANSPARENCY.glassCard
	espControlCard.BorderSizePixel = 0
	espControlCard.Parent = espFrame

	applyGlass(espControlCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7,
		gradient = true,
		gradientRotation = 120
	})
	applyPadding(espControlCard, 14, 14, 12, 12)

	local espStatusLabel = Instance.new("TextLabel")
	espStatusLabel.Size = UDim2.new(1, 0, 0, 0)
	espStatusLabel.Position = UDim2.new(0, 0, 0, 0)
	espStatusLabel.AutomaticSize = Enum.AutomaticSize.Y
	espStatusLabel.BackgroundTransparency = 1
	espStatusLabel.Text = "Status: <font color='#ff4d4d'>Disabled</font>\nActive ESP Eggs: 0"
	espStatusLabel.TextColor3 = COLORS.textSecondary
	espStatusLabel.TextSize = 12
	espStatusLabel.RichText = true
	espStatusLabel.TextWrapped = true
	espStatusLabel.Font = Enum.Font.GothamMedium
	espStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	espStatusLabel.LineHeight = 1.35
	espStatusLabel.Parent = espControlCard

	-- Toggles Card
	local espTogglesCard = Instance.new("Frame")
	espTogglesCard.Size = UDim2.new(1, 0, 0, 0)
	espTogglesCard.AutomaticSize = Enum.AutomaticSize.Y
	espTogglesCard.BackgroundColor3 = COLORS.glassCard
	espTogglesCard.BackgroundTransparency = TRANSPARENCY.glassCard
	espTogglesCard.BorderSizePixel = 0
	espTogglesCard.Parent = espFrame

	applyGlass(espTogglesCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	applyListLayout(espTogglesCard, 8)
	applyPadding(espTogglesCard, 10, 10, 10, 10)

	local espFilterRow, espFilterBtn = createButtonRow("Target Location Filter", "All Eggs")
	espFilterRow.Size = UDim2.new(1, 0, 0, 36)
	espFilterRow.Parent = espTogglesCard

	local espScopeRow, espScopeBtn = createButtonRow("Scan Scope Filter", "All Eggs (Wild + Plot)")
	espScopeRow.Size = UDim2.new(1, 0, 0, 36)
	espScopeRow.Parent = espTogglesCard

	local scopeOptions = { "All Eggs (Wild + Plot)", "Wild Eggs Only", "Plot Eggs (Hatching Only)" }
	local espScopeOverlay, setEspScopeFilter = createDropdownMenu(scopeOptions, "All Eggs (Wild + Plot)",
		function(summaryText, activeList)
			espScopeBtn.Text = summaryText
			local scope = "All"
			if summaryText:find("Wild") then
				scope = "Wild"
			elseif summaryText:find("Plot") or summaryText:find("Hatch") then
				scope = "Plot"
			end
			if _G.HipHubESP and _G.HipHubESP.setState then
				_G.HipHubESP.setState({
					scopeMode = scope,
					scopeSummary = summaryText
				})
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)

	espScopeBtn.MouseButton1Click:Connect(function()
		if activeOverlay == espScopeOverlay then
			closeDropdowns()
		else
			closeDropdowns()
			activeOverlay = espScopeOverlay
			espScopeOverlay.Visible = true
			dropdownDismissArea.Visible = true
		end
	end)

	-- Separate dropdown instance for ESP tab
	local espAreaOverlay, setEspAreaFilter = createDropdownMenu(filterOptions, "All Eggs",
		function(summaryText, activeList)
			espFilterBtn.Text = summaryText
			if _G.HipHubESP and _G.HipHubESP.setState then
				_G.HipHubESP.setState({
					selectedLocationFilter = summaryText,
					selectedLocationFilters = activeList
				})
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)

	espFilterBtn.MouseButton1Click:Connect(function()
		if activeOverlay == espAreaOverlay then
			closeDropdowns()
		else
			closeDropdowns()
			activeOverlay = espAreaOverlay
			espAreaOverlay.Visible = true
			dropdownDismissArea.Visible = true
		end
	end)

	local eggEspCard, eggEspTrack, eggEspThumb = createGlassToggle(espTogglesCard, "Enable Egg ESP (Monitor GUI)", 1)
	eggEspCard.Size = UDim2.new(1, 0, 0, 36)

	------------------------------------------------
	-- 🔮 MISC / PERFORMANCE TAB
	------------------------------------------------
	local miscFrame = tabs["Misc"].Frame
	applyListLayout(miscFrame, 10)

	-- Info / Status Card
	local miscControlCard = Instance.new("Frame")
	miscControlCard.Size = UDim2.new(1, 0, 0, 0)
	miscControlCard.AutomaticSize = Enum.AutomaticSize.Y
	miscControlCard.BackgroundColor3 = COLORS.glassCard
	miscControlCard.BackgroundTransparency = TRANSPARENCY.glassCard
	miscControlCard.BorderSizePixel = 0
	miscControlCard.Parent = miscFrame

	applyGlass(miscControlCard, {
		corner = CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7,
		gradient = true,
		gradientRotation = 120
	})
	applyPadding(miscControlCard, 14, 14, 12, 12)

	local miscStatusLabel = Instance.new("TextLabel")
	miscStatusLabel.Size = UDim2.new(1, 0, 0, 0)
	miscStatusLabel.Position = UDim2.new(0, 0, 0, 0)
	miscStatusLabel.AutomaticSize = Enum.AutomaticSize.Y
	miscStatusLabel.BackgroundTransparency = 1
	miscStatusLabel.Text = "Status: <font color='#00e6ff'>Ready</font>\nPerformance Optimizers & Visual Boosters"
	miscStatusLabel.TextColor3 = COLORS.textSecondary
	miscStatusLabel.TextSize = 12
	miscStatusLabel.RichText = true
	miscStatusLabel.TextWrapped = true
	miscStatusLabel.Font = Enum.Font.GothamMedium
	miscStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	miscStatusLabel.LineHeight = 1.35
	miscStatusLabel.Parent = miscControlCard

	-- SECTION 1: ⚡ Performance & Booster
	local perfSection = createCollapsibleSection(miscFrame, "Performance & Booster", 2, false)
	local fpsBoosterCard, fpsToggleTrack, fpsToggleThumb = createGlassToggle(perfSection.Content,
		"FPS Booster (Remove Textures & Lighting)", 1)
	fpsBoosterCard.Size = UDim2.new(1, 0, 0, 36)

	local destroyPetsCard, dpToggleTrack, dpToggleThumb = createGlassToggle(perfSection.Content,
		"Destroy Pets & Treadmills (Purge All)", 2)
	destroyPetsCard.Size = UDim2.new(1, 0, 0, 36)

	-- SECTION 2: 💰 Automation Sell Pets
	local sellSection = createCollapsibleSection(miscFrame, "Automation Sell Pets", 4, false)
	local sellRarityFilterRow, sellRarityFilterBtn = createButtonRow("Auto Sell Rarity Filter", "Common, Uncommon")
	sellRarityFilterRow.Size = UDim2.new(1, 0, 0, 36)
	sellRarityFilterRow.LayoutOrder = 1
	sellRarityFilterRow.Parent = sellSection.Content

	local autoSellCard, autoSellTrack, autoSellThumb = createGlassToggle(sellSection.Content,
		"Auto Sell Pets (By Rarity)", 2)
	autoSellCard.Size = UDim2.new(1, 0, 0, 36)

	-- SECTION 3: 👑 Automation Equip Best Pets
	local equipSection = createCollapsibleSection(miscFrame, "Automation Equip Best Pets", 6, false)
	local autoEquipCard, autoEquipTrack, autoEquipThumb = createGlassToggle(equipSection.Content, "Auto Equip Best Pets",
		1)
	autoEquipCard.Size = UDim2.new(1, 0, 0, 36)

	local equipDelayRow, equipDelayBox = createInputRow(equipSection.Content, "Equip Best Interval (s)", "5", "5", 2,
		function(val)
			local num = tonumber(val) or 5
			if _G.HipHubMisc then
				_G.HipHubMisc.setState({ equipBestInterval = num })
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)
	equipDelayRow.Size = UDim2.new(1, 0, 0, 36)

	-- SECTION 4: 💵 Automation Offline Claim
	local claimSection = createCollapsibleSection(miscFrame, "Automation Offline Claim", 8, false)
	local autoClaimCard, autoClaimTrack, autoClaimThumb = createGlassToggle(claimSection.Content,
		"Auto Collect Offline Claim", 1)
	autoClaimCard.Size = UDim2.new(1, 0, 0, 36)

	-- SECTION 5: 🌐 Automation Server Hop
	local hopSection = createCollapsibleSection(miscFrame, "Automation Server Hop", 10, false)
	local autoHopCard, autoHopTrack, autoHopThumb = createGlassToggle(hopSection.Content,
		"Auto Hop Server", 1)
	autoHopCard.Size = UDim2.new(1, 0, 0, 36)

	local hopIntervalRow, hopIntervalBox = createInputRow(hopSection.Content, "Hop Interval (s)", "60", "60", 2,
		function(val)
			local num = tonumber(val) or 60
			if _G.HipHubMisc then
				_G.HipHubMisc.setState({ hopInterval = num })
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)
	hopIntervalRow.Size = UDim2.new(1, 0, 0, 36)

	local hopVersionRow, hopVersionBox = createInputRow(hopSection.Content, "Target Version (0=Off)", "0", "0", 3,
		function(val)
			local num = tonumber(val) or 0
			if _G.HipHubMisc then
				_G.HipHubMisc.setState({ targetPlaceVersion = num })
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)
	hopVersionRow.Size = UDim2.new(1, 0, 0, 36)

	local hopModeRow, hopModeBtn = createButtonRow("Version Condition", ">= (At Least)")
	hopModeRow.Size = UDim2.new(1, 0, 0, 36)
	hopModeRow.LayoutOrder = 4
	hopModeRow.Parent = hopSection.Content

	local HOP_MODES = { ">= (At Least)", "== (Exact)", "> (Newer)" }
	local currentHopModeIdx = 1

	hopModeBtn.MouseButton1Click:Connect(function()
		currentHopModeIdx = (currentHopModeIdx % #HOP_MODES) + 1
		local selected = HOP_MODES[currentHopModeIdx]
		hopModeBtn.Text = selected
		local comp = ">="
		if selected:find("==") then
			comp = "=="
		elseif selected:find("> %(") then
			comp = ">"
		end
		if _G.HipHubMisc then
			_G.HipHubMisc.setState({ hopVersionCompare = comp })
		end
		if _G.HipHubUI and _G.HipHubUI.saveConfig then
			pcall(_G.HipHubUI.saveConfig)
		end
	end)

	local hopNowRow, hopNowBtn = createButtonRow("Hop Server", "Hop Now")
	hopNowRow.Size = UDim2.new(1, 0, 0, 36)
	hopNowRow.LayoutOrder = 5
	hopNowRow.Parent = hopSection.Content

	local sellRarityOptions = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Cosmic",
		"Secret",
		"Eternal",
		"Divine"
	}

	local sellRarityOverlay, setSellRarityFilter = createDropdownMenu(sellRarityOptions, "Common",
		function(summaryText, activeList)
			sellRarityFilterBtn.Text = summaryText
			if _G.HipHubMisc then
				_G.HipHubMisc.setState({
					selectedSellRarity = summaryText,
					selectedSellRarities = activeList
				})
			end
			if _G.HipHubUI and _G.HipHubUI.saveConfig then
				pcall(_G.HipHubUI.saveConfig)
			end
		end)

	sellRarityFilterBtn.MouseButton1Click:Connect(function()
		if activeOverlay == sellRarityOverlay then
			closeDropdowns()
		else
			closeDropdowns()
			activeOverlay = sellRarityOverlay
			sellRarityOverlay.Visible = true
			dropdownDismissArea.Visible = true
		end
	end)

	------------------------------------------------
	-- 🔗 WEBHOOK TAB
	------------------------------------------------
	local webhookFrame = tabs["Webhook"].Frame
	local webhookLayout = Instance.new("UIListLayout")
	webhookLayout.SortOrder = Enum.SortOrder.LayoutOrder
	webhookLayout.Padding = UDim.new(0, 10)
	webhookLayout.Parent = webhookFrame

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
	credBody.Text =
	"HipHub — V1.0.1\nFuturistic glassmorphic base UI layout for game automations.\nLoaded in a secure sandboxed environment."
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

	st.autoReconnectCard, st.arToggleTrack, st.arToggleThumb = createGlassToggle(settingsFrame,
		"Auto Reconnect (Same Session)", 0)
	st.autoReconnectCard.Size = UDim2.new(1, 0, 0, 42)

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

		-- Main tab specific elements
		mainFrameContent = mainFrameContent,

		-- Webhook tab elements
		webhookFrame = webhookFrame,

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
		autoReconnectCard = st.autoReconnectCard,
		arToggleTrack = st.arToggleTrack,
		arToggleThumb = st.arToggleThumb,
		fpsBoosterCard = st.fpsBoosterCard,
		fpsToggleTrack = st.fpsToggleTrack,
		fpsToggleThumb = st.fpsToggleThumb,
		destroyPetsCard = st.destroyPetsCard,
		dpToggleTrack = st.dpToggleTrack,
		dpToggleThumb = st.dpToggleThumb,
		discordButton = discordButton,

		-- Steal Egg elements
		Steal = {
			tabButton = tabButtons["Steal"],
			tabFrame = stealFrame,
			statusLabel = stealStatusLabel,
			autoStealTrack = autoStealTrack,
			autoStealThumb = autoStealThumb,
			turboCard = turboCard,
			turboTrack = turboTrack,
			turboThumb = turboThumb,
			antiRagdollCard = antiRagdollCard,
			arToggleTrack = arToggleTrack,
			arToggleThumb = arToggleThumb,
			eggFilterBtn = eggFilterBtn,
			rarityFilterBtn = rarityFilterBtn,
			valueFilterRow = valueFilterRow,
			valueFilterBtn = valueFilterBtn,
			valueFilterInput = valueInputBox,
			speedInputRow = speedInputRow,
			speedInput = speedInputBox,
			setAreaFilter = function(list) setAreaFilter(list) end,
			setRarityFilter = function(list) setRarityFilter(list) end,
			setValueFilter = function(list) setValueFilter(list) end,
		},

		-- Place Egg elements
		Place = {
			tabButton = tabButtons["Place"],
			tabFrame = placeFrame,
			statusLabel = placeStatusLabel,
			autoPlaceTrack = autoPlaceTrack,
			autoPlaceThumb = autoPlaceThumb,
			autoHatchTrack = autoHatchTrack,
			autoHatchThumb = autoHatchThumb,
			placeFilterBtn = placeFilterBtn,
			setAreaFilter = function(list) setPlaceAreaFilter(list) end,
		},

		-- ESP elements
		ESP = {
			tabButton = tabButtons["ESP"],
			tabFrame = espFrame,
			statusLabel = espStatusLabel,
			eggEspTrack = eggEspTrack,
			eggEspThumb = eggEspThumb,
			espFilterBtn = espFilterBtn,
			espScopeBtn = espScopeBtn,
			setLocationFilter = function(list) setEspAreaFilter(list) end,
			setScopeFilter = function(list) setEspScopeFilter(list) end,
		},

		-- Misc elements
		Misc = {
			tabButton = tabButtons["Misc"],
			tabFrame = miscFrame,
			statusLabel = miscStatusLabel,
			fpsToggleTrack = fpsToggleTrack,
			fpsToggleThumb = fpsToggleThumb,
			dpToggleTrack = dpToggleTrack,
			dpToggleThumb = dpToggleThumb,
			autoSellTrack = autoSellTrack,
			autoSellThumb = autoSellThumb,
			sellRarityFilterBtn = sellRarityFilterBtn,
			setSellRarityFilter = function(list) setSellRarityFilter(list) end,
			autoEquipTrack = autoEquipTrack,
			autoEquipThumb = autoEquipThumb,
			equipDelayBox = equipDelayBox,
			autoClaimTrack = autoClaimTrack,
			autoClaimThumb = autoClaimThumb,
			autoHopTrack = autoHopTrack,
			autoHopThumb = autoHopThumb,
			hopIntervalBox = hopIntervalBox,
			hopVersionBox = hopVersionBox,
			hopModeBtn = hopModeBtn,
			setHopVersionMode = function(modeStr)
				for i, m in ipairs(HOP_MODES) do
					if m:find(modeStr, 1, true) or (modeStr == ">=" and m:find(">=")) or (modeStr == "==" and m:find("==")) or (modeStr == ">" and m:find("> %(")) then
						currentHopModeIdx = i
						hopModeBtn.Text = m
						break
					end
				end
			end,
			hopNowBtn = hopNowBtn,
		},
		fpsToggleTrack = fpsToggleTrack,
		fpsToggleThumb = fpsToggleThumb,
		dpToggleTrack = dpToggleTrack,
		dpToggleThumb = dpToggleThumb,
		autoSellTrack = autoSellTrack,
		autoSellThumb = autoSellThumb,
		autoEquipTrack = autoEquipTrack,
		autoEquipThumb = autoEquipThumb,
		equipDelayBox = equipDelayBox,
		autoClaimTrack = autoClaimTrack,
		autoClaimThumb = autoClaimThumb,
		autoHopTrack = autoHopTrack,
		autoHopThumb = autoHopThumb,
		hopIntervalBox = hopIntervalBox,
		hopVersionBox = hopVersionBox,
		hopModeBtn = hopModeBtn,
		hopNowBtn = hopNowBtn,

		-- Shadow sync utility
		syncShadow = syncShadow,

		-- Fullscreen icon update utility
		updateFullscreenIcon = updateFullscreenIcon,
	}

	-- Set default tab
	selectTab("Info")
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
