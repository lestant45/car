-- 💣 CAB Shop Tab Module
-- Shop features (Auto Buy Bomb)
-- Loaded by ui.lua via _G.HipHubUI shared references

local function initShop()
	local refs = _G.HipHubUI
	if not refs then
		return
	end

	local TweenService = refs.TweenService
	local UserInputService = refs.UserInputService
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = game:GetService("Players").LocalPlayer

	local COLORS = refs.COLORS or {}
	local toggleOnColor = COLORS.toggleOn or Color3.fromRGB(0, 180, 230)
	local toggleOffColor = COLORS.toggleOff or Color3.fromRGB(40, 46, 70)

	local shopFrameContent = (refs.tabs and refs.tabs["Shop"] and refs.tabs["Shop"].Frame) or refs.shopFrameContent
	if not shopFrameContent then
		return
	end

	refs.applyListLayout(shopFrameContent, 10)

	------------------------------------------------
	-- ⚙️ SHOP STATES & CONFIG
	------------------------------------------------
	local autoBuyBombEnabled = false
	local autoBuyBombSelection = "ClassicBomb"
	local isBuying = false

	local bombOptions = {
		"All",
		"ClassicBomb",
		"WindBomb",
		"IceBomb",
		"FireBomb",
		"ThunderBomb",
		"PoisonBomb",
		"TimeBomb",
		"AgonyBomb"
	}

	-- Core Remote Function for Purchasing Bombs
	local function buyBomb(bombType)
		if isBuying then return end
		isBuying = true

		pcall(function()
			local rems = ReplicatedStorage:FindFirstChild("Remotes")
			local bombRem = rems and rems:FindFirstChild("BombBuyRequest")
			if not bombRem then return end

			if bombType == "All" then
				local allBombs = {
					"ClassicBomb",
					"WindBomb",
					"IceBomb",
					"FireBomb",
					"ThunderBomb",
					"PoisonBomb",
					"TimeBomb",
					"AgonyBomb"
				}
				for _, bName in ipairs(allBombs) do
					pcall(function()
						bombRem:InvokeServer(bName)
					end)
					task.wait(0.2)
				end
			else
				pcall(function()
					bombRem:InvokeServer(bombType)
				end)
			end
		end)

		isBuying = false
	end

	------------------------------------------------
	-- 💣 AUTO BUY BOMB CATEGORY SECTION
	------------------------------------------------
	local isSectionExpanded = false

	local bombCard = Instance.new("Frame")
	bombCard.Size = UDim2.new(1, 0, 0, 36)
	bombCard.BackgroundColor3 = COLORS.glassCard
	bombCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
	bombCard.BorderSizePixel = 0
	bombCard.ClipsDescendants = true
	bombCard.LayoutOrder = 1
	bombCard.Parent = shopFrameContent

	refs.applyGlass(bombCard, {
		corner = refs.CORNER.medium,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.7
	})

	-- Expandable Header Click Button
	local headerBtn = Instance.new("TextButton")
	headerBtn.Size = UDim2.new(1, 0, 0, 36)
	headerBtn.BackgroundTransparency = 0.999
	headerBtn.Text = ""
	headerBtn.ZIndex = 10
	headerBtn.Active = true
	headerBtn.Parent = bombCard

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 3, 0, 18)
	accentBar.Position = UDim2.new(0, 12, 0, 9)
	accentBar.BackgroundColor3 = COLORS.accentCyan
	accentBar.BorderSizePixel = 0
	accentBar.Parent = headerBtn

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 2)
	accentCorner.Parent = accentBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 24, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Auto Buy Bomb"
	titleLabel.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = headerBtn

	local chevronLabel = Instance.new("TextLabel")
	chevronLabel.Size = UDim2.new(0, 24, 1, 0)
	chevronLabel.Position = UDim2.new(1, -30, 0, 0)
	chevronLabel.BackgroundTransparency = 1
	chevronLabel.Text = ">"
	chevronLabel.TextColor3 = COLORS.accentCyan
	chevronLabel.Font = Enum.Font.GothamBold
	chevronLabel.TextSize = 13
	chevronLabel.Parent = headerBtn

	-- Content Container inside Auto Buy Bomb Card
	local contentContainer = Instance.new("Frame")
	contentContainer.Size = UDim2.new(1, -24, 0, 125)
	contentContainer.Position = UDim2.new(0, 12, 0, 42)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = bombCard

	refs.applyListLayout(contentContainer, 6)

	local function updateShopTabCanvas()
		if shopFrameContent:IsA("ScrollingFrame") then
			local layout = shopFrameContent:FindFirstChildOfClass("UIListLayout")
			if layout then
				shopFrameContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
			end
		end
	end

	headerBtn.MouseButton1Click:Connect(function()
		isSectionExpanded = not isSectionExpanded
		chevronLabel.Text = isSectionExpanded and "v" or ">"
		local targetHeight = isSectionExpanded and 175 or 36

		local tween = TweenService:Create(bombCard,
			TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, targetHeight)
		})
		tween:Play()
		tween.Completed:Connect(updateShopTabCanvas)
		updateShopTabCanvas()
	end)

	-- 1. Auto Buy Bomb Toggle
	local abbRow, abbTrack, abbThumb = refs.createGlassToggle(contentContainer, "Auto Buy Bomb", 1)
	local updateAutoBuyBombVisuals = function()
		if autoBuyBombEnabled then
			TweenService:Create(abbTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(abbThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
		else
			TweenService:Create(abbTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(abbThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
		end
	end
	updateAutoBuyBombVisuals()

	abbTrack.MouseButton1Click:Connect(function()
		autoBuyBombEnabled = not autoBuyBombEnabled
		updateAutoBuyBombVisuals()
		if refs.saveConfig then pcall(refs.saveConfig) end
	end)

	-- 2. Select Bomb Dropdown
	local bombCardDrop, bombDropBtn, bombDropLabel, bombMenuFrame, bombSearchBox, bombScrollFrame = refs.createGlassDropdown(
		contentContainer, "Select Bomb", autoBuyBombSelection, 2
	)
	bombCardDrop.Size = UDim2.new(1, 0, 0, 32)

	refs.registerDropdownMenu(bombDropBtn, bombMenuFrame)
	local bombBinder = refs.bindDropdown(
		bombDropBtn, bombMenuFrame, bombSearchBox, bombScrollFrame, bombOptions,
		function(opt)
			return autoBuyBombSelection == opt
		end,
		function(opt)
			autoBuyBombSelection = opt
		end,
		function()
			bombDropLabel.Text = autoBuyBombSelection
		end
	)

	local function updateBombSelectionVisuals()
		bombDropLabel.Text = autoBuyBombSelection
		bombBinder.updateOptionVisuals()
	end

	-- 3. Action Button: Buy Selected Bomb Now
	local buyActionBtn = Instance.new("TextButton")
	buyActionBtn.Size = UDim2.new(1, 0, 0, 32)
	buyActionBtn.BackgroundColor3 = COLORS.accentCyan
	buyActionBtn.BackgroundTransparency = 0.15
	buyActionBtn.Text = "⚡ Buy Selected Bomb Now"
	buyActionBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	buyActionBtn.Font = Enum.Font.GothamBold
	buyActionBtn.TextSize = 11
	buyActionBtn.LayoutOrder = 3
	buyActionBtn.Parent = contentContainer

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = refs.CORNER.small
	buyCorner.Parent = buyActionBtn

	buyActionBtn.MouseButton1Click:Connect(function()
		task.spawn(function()
			buyBomb(autoBuyBombSelection)
		end)
	end)

	-- Auto Buy Loop
	task.spawn(function()
		while true do
			task.wait(1.5)
			if autoBuyBombEnabled then
				pcall(function()
					buyBomb(autoBuyBombSelection)
				end)
			end
		end
	end)

	------------------------------------------------
	-- 📤 EXPOSE STATE TO _G
	------------------------------------------------
	_G.HipHubShop = {
		getState = function()
			return {
				autoBuyBombEnabled = autoBuyBombEnabled,
				autoBuyBombSelection = autoBuyBombSelection,
			}
		end,
		setState = function(s)
			if not s then return end
			if s.autoBuyBombEnabled ~= nil then
				autoBuyBombEnabled = (s.autoBuyBombEnabled == true)
				updateAutoBuyBombVisuals()
			end
			if s.autoBuyBombSelection ~= nil then
				autoBuyBombSelection = tostring(s.autoBuyBombSelection)
				updateBombSelectionVisuals()
			end
		end
	}
end

-- Initialize Shop module
task.spawn(function()
	task.wait(0.2)
	pcall(initShop)
end)
