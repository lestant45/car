-- 👁️ CAB ESP Engine & Tab Module
-- Separate file for ESP functionality (Crystals, Dropped Crystals, Dropped Runes, Player ESP)
-- Shares references via _G.HipHubUI and exposes state/functions via _G.HipHubESP

local function initESP()
	local refs = _G.HipHubUI
	if not refs then
		return
	end

	local TweenService = refs.TweenService
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local gui = refs.gui
	local COLORS = refs.COLORS or {}
	local toggleOnColor = COLORS.toggleOn or Color3.fromRGB(0, 180, 230)
	local toggleOffColor = COLORS.toggleOff or Color3.fromRGB(40, 46, 70)
	local saveConfig = refs.saveConfig

	-- ESP persistent states
	local state = {
		crystalEspEnabled = false,
		droppedCrystalEspEnabled = false,
		droppedRuneEspEnabled = false,
		playerEspEnabled = false,
		selectedCrystalRarity = "All",
		selectedCrystalSize = "All",
	}

	local updateCrystalEspVisuals, updateDroppedCrystalEspVisuals, updateDroppedRuneEspVisuals, updatePlayerEspVisuals, updateDropdownVisuals, updateSizeDropdownVisuals

	if refs.addTab then
		local espTabFrame = refs.addTab("ESP", "", 2)
		local tabLayout = refs.applyListLayout(espTabFrame, 10)

		local function updateTabCanvas()
			if espTabFrame:IsA("ScrollingFrame") and tabLayout then
				espTabFrame.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 30)
			end
		end

		if tabLayout then
			tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabCanvas)
		end

		-- ESP Header Card
		local espCard = Instance.new("Frame")
		espCard.Size = UDim2.new(1, 0, 0, 60)
		espCard.BackgroundColor3 = COLORS.glassCard
		espCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		espCard.BorderSizePixel = 0
		espCard.Parent = espTabFrame

		refs.applyGlass(espCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7,
			gradient = true,
			gradientRotation = 120
		})

		local espTitle = Instance.new("TextLabel")
		espTitle.Size = UDim2.new(1, -24, 0, 24)
		espTitle.Position = UDim2.new(0, 12, 0, 8)
		espTitle.BackgroundTransparency = 1
		espTitle.Text = "VISUAL ESP CONTROLS"
		espTitle.TextColor3 = COLORS.accentCyan
		espTitle.Font = Enum.Font.GothamBold
		espTitle.TextSize = 11
		espTitle.TextXAlignment = Enum.TextXAlignment.Left
		espTitle.Parent = espCard

		local espSub = Instance.new("TextLabel")
		espSub.Size = UDim2.new(1, -24, 0, 20)
		espSub.Position = UDim2.new(0, 12, 0, 30)
		espSub.BackgroundTransparency = 1
		espSub.Text = "Real-time detailed world cards for crystals, dropped items, and players."
		espSub.TextColor3 = COLORS.textSecondary
		espSub.Font = Enum.Font.Gotham
		espSub.TextSize = 11
		espSub.TextXAlignment = Enum.TextXAlignment.Left
		espSub.Parent = espCard

		-- 🔽 Crystal Rarity Filter Dropdown Card (Above Toggles)
		local filterCard = Instance.new("Frame")
		filterCard.Size = UDim2.new(1, 0, 0, 44)
		filterCard.BackgroundColor3 = COLORS.glassCard
		filterCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		filterCard.BorderSizePixel = 0
		filterCard.ClipsDescendants = true
		filterCard.Parent = espTabFrame

		refs.applyGlass(filterCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})

		local filterTitle = Instance.new("TextLabel")
		filterTitle.Size = UDim2.new(0.5, 0, 0, 44)
		filterTitle.Position = UDim2.new(0, 12, 0, 0)
		filterTitle.BackgroundTransparency = 1
		filterTitle.Text = "Crystal Rarity Filter"
		filterTitle.TextColor3 = COLORS.textPrimary
		filterTitle.Font = Enum.Font.GothamMedium
		filterTitle.TextSize = 12
		filterTitle.TextXAlignment = Enum.TextXAlignment.Left
		filterTitle.Parent = filterCard

		local dropBtn = Instance.new("TextButton")
		dropBtn.Size = UDim2.new(0, 140, 0, 26)
		dropBtn.Position = UDim2.new(1, -152, 0, 9)
		dropBtn.BackgroundColor3 = Color3.fromRGB(24, 30, 50)
		dropBtn.Text = (state.selectedCrystalRarity or "All") .. "  ▼"
		dropBtn.TextColor3 = COLORS.accentCyan
		dropBtn.Font = Enum.Font.GothamBold
		dropBtn.TextSize = 10
		dropBtn.Parent = filterCard

		local dropCorner = Instance.new("UICorner")
		dropCorner.CornerRadius = refs.CORNER.small
		dropCorner.Parent = dropBtn

		local dropStroke = Instance.new("UIStroke")
		dropStroke.Color = COLORS.borderGlass
		dropStroke.Thickness = 1
		dropStroke.Transparency = 0.5
		dropStroke.Parent = dropBtn

		local menuFrame = Instance.new("Frame")
		menuFrame.Size = UDim2.new(0, 140, 0, 190)
		menuFrame.Position = UDim2.new(1, -152, 0, 40)
		menuFrame.BackgroundTransparency = 1
		menuFrame.Visible = false
		menuFrame.ClipsDescendants = true
		menuFrame.Parent = filterCard

		refs.applyListLayout(menuFrame, 3)

		local rarities = {
			"All",
			"Common",
			"Uncommon",
			"Rare",
			"Epic",
			"Legendary",
			"Mythical"
		}
		local isOpen = false

		updateDropdownVisuals = function()
			dropBtn.Text = (state.selectedCrystalRarity or "All") .. (isOpen and "  ▲" or "  ▼")
			for _, child in ipairs(menuFrame:GetChildren()) do
				if child:IsA("TextButton") then
					local isSel = (child.Text == state.selectedCrystalRarity)
					child.BackgroundColor3 = isSel and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
					child.TextColor3 = isSel and COLORS.accentCyan or COLORS.textSecondary
				end
			end
		end

		for _, rName in ipairs(rarities) do
			local itemBtn = Instance.new("TextButton")
			itemBtn.Size = UDim2.new(1, 0, 0, 24)
			itemBtn.BackgroundColor3 = (state.selectedCrystalRarity == rName) and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
			itemBtn.BackgroundTransparency = 0.15
			itemBtn.Text = rName
			itemBtn.TextColor3 = (state.selectedCrystalRarity == rName) and COLORS.accentCyan or COLORS.textSecondary
			itemBtn.Font = Enum.Font.GothamMedium
			itemBtn.TextSize = 10
			itemBtn.Parent = menuFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 5)
			itemCorner.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				state.selectedCrystalRarity = rName
				isOpen = false
				updateDropdownVisuals()

				local slideTween = TweenService:Create(filterCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 44) })
				slideTween:Play()
				slideTween.Completed:Connect(function()
					if not isOpen then menuFrame.Visible = false end
				end)

				updateTabCanvas()
				if _G.HipHubESP and _G.HipHubESP.updateVisuals then _G.HipHubESP.updateVisuals() end
				if saveConfig then pcall(saveConfig) end
			end)
		end

		dropBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			if isOpen then menuFrame.Visible = true end
			updateDropdownVisuals()

			local targetHeight = isOpen and (44 + 192) or 44
			local slideTween = TweenService:Create(filterCard, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetHeight) })
			slideTween:Play()

			if not isOpen then
				slideTween.Completed:Connect(function()
					if not isOpen then menuFrame.Visible = false end
				end)
			end

			updateTabCanvas()
		end)

		-- 🔽 Crystal Size Filter Dropdown Card (Below Rarity Filter)
		local sizeFilterCard = Instance.new("Frame")
		sizeFilterCard.Size = UDim2.new(1, 0, 0, 44)
		sizeFilterCard.BackgroundColor3 = COLORS.glassCard
		sizeFilterCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		sizeFilterCard.BorderSizePixel = 0
		sizeFilterCard.ClipsDescendants = true
		sizeFilterCard.Parent = espTabFrame

		refs.applyGlass(sizeFilterCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})

		local sizeFilterTitle = Instance.new("TextLabel")
		sizeFilterTitle.Size = UDim2.new(0.5, 0, 0, 44)
		sizeFilterTitle.Position = UDim2.new(0, 12, 0, 0)
		sizeFilterTitle.BackgroundTransparency = 1
		sizeFilterTitle.Text = "Crystal Size Filter"
		sizeFilterTitle.TextColor3 = COLORS.textPrimary
		sizeFilterTitle.Font = Enum.Font.GothamMedium
		sizeFilterTitle.TextSize = 12
		sizeFilterTitle.TextXAlignment = Enum.TextXAlignment.Left
		sizeFilterTitle.Parent = sizeFilterCard

		local sizeDropBtn = Instance.new("TextButton")
		sizeDropBtn.Size = UDim2.new(0, 140, 0, 26)
		sizeDropBtn.Position = UDim2.new(1, -152, 0, 9)
		sizeDropBtn.BackgroundColor3 = Color3.fromRGB(24, 30, 50)
		sizeDropBtn.Text = (state.selectedCrystalSize or "All") .. "  ▼"
		sizeDropBtn.TextColor3 = COLORS.accentCyan
		sizeDropBtn.Font = Enum.Font.GothamBold
		sizeDropBtn.TextSize = 10
		sizeDropBtn.Parent = sizeFilterCard

		local sizeDropCorner = Instance.new("UICorner")
		sizeDropCorner.CornerRadius = refs.CORNER.small
		sizeDropCorner.Parent = sizeDropBtn

		local sizeDropStroke = Instance.new("UIStroke")
		sizeDropStroke.Color = COLORS.borderGlass
		sizeDropStroke.Thickness = 1
		sizeDropStroke.Transparency = 0.5
		sizeDropStroke.Parent = sizeDropBtn

		local sizeMenuFrame = Instance.new("Frame")
		sizeMenuFrame.Size = UDim2.new(0, 140, 0, 165)
		sizeMenuFrame.Position = UDim2.new(1, -152, 0, 40)
		sizeMenuFrame.BackgroundTransparency = 1
		sizeMenuFrame.Visible = false
		sizeMenuFrame.ClipsDescendants = true
		sizeMenuFrame.Parent = sizeFilterCard

		refs.applyListLayout(sizeMenuFrame, 3)

		local sizes = {
			"All",
			"Small",
			"Medium",
			"Large",
			"Titan",
			"Colossal"
		}
		local isSizeOpen = false

		updateSizeDropdownVisuals = function()
			sizeDropBtn.Text = (state.selectedCrystalSize or "All") .. (isSizeOpen and "  ▲" or "  ▼")
			for _, child in ipairs(sizeMenuFrame:GetChildren()) do
				if child:IsA("TextButton") then
					local isSel = (child.Text == state.selectedCrystalSize)
					child.BackgroundColor3 = isSel and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
					child.TextColor3 = isSel and COLORS.accentCyan or COLORS.textSecondary
				end
			end
		end

		for _, sName in ipairs(sizes) do
			local itemBtn = Instance.new("TextButton")
			itemBtn.Size = UDim2.new(1, 0, 0, 24)
			itemBtn.BackgroundColor3 = (state.selectedCrystalSize == sName) and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
			itemBtn.BackgroundTransparency = 0.15
			itemBtn.Text = sName
			itemBtn.TextColor3 = (state.selectedCrystalSize == sName) and COLORS.accentCyan or COLORS.textSecondary
			itemBtn.Font = Enum.Font.GothamMedium
			itemBtn.TextSize = 10
			itemBtn.Parent = sizeMenuFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 5)
			itemCorner.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				state.selectedCrystalSize = sName
				isSizeOpen = false
				updateSizeDropdownVisuals()

				local slideTween = TweenService:Create(sizeFilterCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 44) })
				slideTween:Play()
				slideTween.Completed:Connect(function()
					if not isSizeOpen then sizeMenuFrame.Visible = false end
				end)

				updateTabCanvas()
				if _G.HipHubESP and _G.HipHubESP.updateVisuals then _G.HipHubESP.updateVisuals() end
				if saveConfig then pcall(saveConfig) end
			end)
		end

		sizeDropBtn.MouseButton1Click:Connect(function()
			isSizeOpen = not isSizeOpen
			if isSizeOpen then sizeMenuFrame.Visible = true end
			updateSizeDropdownVisuals()

			local targetHeight = isSizeOpen and (44 + 168) or 44
			local slideTween = TweenService:Create(sizeFilterCard, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetHeight) })
			slideTween:Play()

			if not isSizeOpen then
				slideTween.Completed:Connect(function()
					if not isSizeOpen then sizeMenuFrame.Visible = false end
				end)
			end

			updateTabCanvas()
		end)

		-- Toggles Card
		local togglesCard = Instance.new("Frame")
		togglesCard.Size = UDim2.new(1, 0, 0, 170)
		togglesCard.BackgroundColor3 = COLORS.glassCard
		togglesCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		togglesCard.BorderSizePixel = 0
		togglesCard.Parent = espTabFrame

		refs.applyGlass(togglesCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})
		refs.applyListLayout(togglesCard, 8)
		refs.applyPadding(togglesCard, 10, 10, 10, 10)

		-- 1. Crystal ESP Toggle
		local cRow, cTrack, cThumb = refs.createGlassToggle(togglesCard, "Crystal ESP", 1)
		updateCrystalEspVisuals = function()
			if state.crystalEspEnabled then
				TweenService:Create(cTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(cThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(cTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(cThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		cTrack.MouseButton1Click:Connect(function()
			state.crystalEspEnabled = not state.crystalEspEnabled
			updateCrystalEspVisuals()
			if saveConfig then pcall(saveConfig) end
		end)

		-- 2. Dropped Crystal ESP Toggle
		local dcRow, dcTrack, dcThumb = refs.createGlassToggle(togglesCard, "Dropped Crystal ESP", 2)
		updateDroppedCrystalEspVisuals = function()
			if state.droppedCrystalEspEnabled then
				TweenService:Create(dcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(dcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(dcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(dcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		dcTrack.MouseButton1Click:Connect(function()
			state.droppedCrystalEspEnabled = not state.droppedCrystalEspEnabled
			updateDroppedCrystalEspVisuals()
			if saveConfig then pcall(saveConfig) end
		end)

		-- 3. Dropped Rune ESP Toggle
		local drRow, drTrack, drThumb = refs.createGlassToggle(togglesCard, "Dropped Rune ESP", 3)
		updateDroppedRuneEspVisuals = function()
			if state.droppedRuneEspEnabled then
				TweenService:Create(drTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(drThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(drTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(drThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		drTrack.MouseButton1Click:Connect(function()
			state.droppedRuneEspEnabled = not state.droppedRuneEspEnabled
			updateDroppedRuneEspVisuals()
			if saveConfig then pcall(saveConfig) end
		end)

		-- 4. Player ESP Toggle
		local pRow, pTrack, pThumb = refs.createGlassToggle(togglesCard, "Player ESP", 4)
		updatePlayerEspVisuals = function()
			if state.playerEspEnabled then
				TweenService:Create(pTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(pThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(pTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(pThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		pTrack.MouseButton1Click:Connect(function()
			state.playerEspEnabled = not state.playerEspEnabled
			updatePlayerEspVisuals()
			if saveConfig then pcall(saveConfig) end
		end)

		task.defer(updateTabCanvas)
	end

	-- ESP Billboard Engine
	local espFolder = gui and gui:FindFirstChild("HipHubESP")
	if gui and not espFolder then
		espFolder = Instance.new("Folder")
		espFolder.Name = "HipHubESP"
		espFolder.Parent = gui
	end

	local activeESPs = {}

	local function getTargetPart(obj)
		if not obj then return nil end
		if obj:IsA("BasePart") then
			return obj
		elseif obj:IsA("Model") then
			if obj.PrimaryPart then return obj.PrimaryPart end
			return obj:FindFirstChildWhichIsA("BasePart")
		end
		return nil
	end

	local function getCrystalAccentColor(name)
		local nameLower = string.lower(name)
		if string.find(nameLower, "_t6") or string.find(nameLower, "t6") or string.find(nameLower, "mythic") then
			return "#ff3366"
		elseif string.find(nameLower, "_t5") or string.find(nameLower, "t5") or string.find(nameLower, "legendary") then
			return "#ffaa00"
		elseif string.find(nameLower, "_t4") or string.find(nameLower, "t4") or string.find(nameLower, "epic") then
			return "#aa00ff"
		elseif string.find(nameLower, "_t3") or string.find(nameLower, "t3") or string.find(nameLower, "rare") then
			return "#00c8ff"
		elseif string.find(nameLower, "_t2") or string.find(nameLower, "t2") or string.find(nameLower, "uncommon") then
			return "#55ff55"
		elseif string.find(nameLower, "_t1") or string.find(nameLower, "t1") or string.find(nameLower, "common") then
			return "#d0d0d0"
		end
		return "#00c8ff"
	end

	local function crystalMatchesRarity(crystalObj)
		local filter = state.selectedCrystalRarity or "All"
		if filter == "All" or filter == "" then return true end

		local nameLower = string.lower(crystalObj.Name)
		local filterLower = string.lower(filter)

		local filterMap = {
			["common"] = {"_t1", "t1", "common"},
			["t1 (common)"] = {"_t1", "t1", "common"},
			["t1"] = {"_t1", "t1", "common"},

			["uncommon"] = {"_t2", "t2", "uncommon"},
			["t2 (uncommon)"] = {"_t2", "t2", "uncommon"},
			["t2"] = {"_t2", "t2", "uncommon"},

			["rare"] = {"_t3", "t3", "rare"},
			["t3 (rare)"] = {"_t3", "t3", "rare"},
			["t3"] = {"_t3", "t3", "rare"},

			["epic"] = {"_t4", "t4", "epic"},
			["t4 (epic)"] = {"_t4", "t4", "epic"},
			["t4"] = {"_t4", "t4", "epic"},

			["legendary"] = {"_t5", "t5", "legendary"},
			["t5 (legendary)"] = {"_t5", "t5", "legendary"},
			["t5"] = {"_t5", "t5", "legendary"},

			["mythical"] = {"_t6", "t6", "mythical", "mythic"},
			["mythic"] = {"_t6", "t6", "mythical", "mythic"},
			["t6 (mythical)"] = {"_t6", "t6", "mythical", "mythic"},
			["t6 (mythic)"] = {"_t6", "t6", "mythical", "mythic"},
			["t6"] = {"_t6", "t6", "mythical", "mythic"},
		}

		local keywords = filterMap[filterLower]
		if keywords then
			for _, kw in ipairs(keywords) do
				if string.find(nameLower, kw, 1, true) then
					return true
				end
			end
		end

		if string.find(nameLower, filterLower, 1, true) then
			return true
		end

		local attr = crystalObj:GetAttribute("Rarity") or crystalObj:GetAttribute("Tier") or crystalObj:GetAttribute("rarity") or crystalObj:GetAttribute("tier")
		if attr then
			local attrStr = string.lower(tostring(attr))
			if string.find(attrStr, filterLower, 1, true) then
				return true
			end
			if keywords then
				for _, kw in ipairs(keywords) do
					if string.find(attrStr, kw, 1, true) then
						return true
					end
				end
			end
		end

		return false
	end

	local function crystalMatchesSize(crystalObj)
		local filter = state.selectedCrystalSize or "All"
		if filter == "All" or filter == "" then return true end

		local filterLower = string.lower(filter)
		local nameLower = string.lower(crystalObj.Name)

		if string.find(nameLower, filterLower, 1, true) then
			return true
		end

		local attr = crystalObj:GetAttribute("Size") or crystalObj:GetAttribute("Category") or crystalObj:GetAttribute("size") or crystalObj:GetAttribute("category")
		if attr then
			local attrStr = string.lower(tostring(attr))
			if string.find(attrStr, filterLower, 1, true) then
				return true
			end
		end

		local sizeVec = nil
		if crystalObj:IsA("BasePart") then
			sizeVec = crystalObj.Size
		elseif crystalObj:IsA("Model") then
			local primary = crystalObj.PrimaryPart or crystalObj:FindFirstChildWhichIsA("BasePart")
			if primary then
				sizeVec = primary.Size
			end
		end

		if sizeVec then
			local maxDim = math.max(sizeVec.X, sizeVec.Y, sizeVec.Z)
			if filterLower == "colossal" and maxDim >= 12 then
				return true
			elseif filterLower == "titan" and (maxDim >= 7 and maxDim < 12) then
				return true
			elseif filterLower == "large" and (maxDim >= 4.5 and maxDim < 7) then
				return true
			elseif filterLower == "medium" and (maxDim >= 1.8 and maxDim < 4.5) then
				return true
			elseif filterLower == "small" and maxDim < 1.8 then
				return true
			end
		end

		return false
	end

	local function crystalMatchesFilters(crystalObj)
		return crystalMatchesRarity(crystalObj) and crystalMatchesSize(crystalObj)
	end

	local function formatComma(n)
		local num = tonumber(n)
		if not num then return tostring(n or "") end
		local formatted = tostring(math.floor(num))
		while true do
			local k
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if k == 0 then break end
		end
		return formatted
	end

	local function buildObjectEspDetails(obj, category, distanceMeters)
		if category == "player" then
			local displayName = obj.Name
			if obj:IsA("Model") then
				local pl = Players:GetPlayerFromCharacter(obj)
				if pl then displayName = pl.DisplayName or pl.Name end
			end
			return string.format("<font color='#8c78ff'><b>👤 %s</b></font> <font color='#a0b0d0'>[%dm]</font>", displayName, distanceMeters or 0)
		elseif category == "dropped_rune" then
			return string.format("<font color='#ffaa00'><b>%s</b></font> <font color='#a0b0d0'>[%dm]</font>", obj.Name, distanceMeters or 0)
		end

		local name = obj.Name
		local nameLower = string.lower(name)

		-- 1. Extract Rarity & Display Name
		local colorHex = getCrystalAccentColor(name)
		local rarityStr = ""
		local displayName = name

		if string.find(nameLower, "droppedcrystal_") then
			local tier = string.match(name, "T%d+") or "T2"
			local tierMap = {
				T1 = "Common", T2 = "Uncommon", T3 = "Rare", T4 = "Epic", T5 = "Legendary", T6 = "Mythic"
			}
			rarityStr = tierMap[tier] or tier
			displayName = "Crystal"
		elseif string.find(nameLower, "_t%d") then
			local tier = string.match(name, "T%d+") or ""
			local tierMap = {
				T1 = "Common", T2 = "Uncommon", T3 = "Rare", T4 = "Epic", T5 = "Legendary", T6 = "Mythic"
			}
			rarityStr = tierMap[tier] or tier
			displayName = string.gsub(name, "_T%d+", "")
		end

		local attrRarity = obj:GetAttribute("Rarity") or obj:GetAttribute("rarity")
		if attrRarity then
			rarityStr = tostring(attrRarity)
		end

		-- 2. Mutation check
		local mutationTag = ""
		local hasMutation = obj:FindFirstChild("FrostMutationSurface") or obj:FindFirstChild("Mutation") or obj:GetAttribute("Mutation")
		if hasMutation then
			local mName = typeof(hasMutation) == "string" and hasMutation or "M"
			mutationTag = string.format(" <font color='#00ff66'><b>[%s]</b></font>", mName)
		end

		-- 3. Title line (Rarity + Name + Mutation)
		local titleLine = ""
		if rarityStr ~= "" then
			titleLine = string.format("<font color='%s'><b>%s</b></font> <b>%s</b>%s", colorHex, rarityStr, displayName, mutationTag)
		else
			titleLine = string.format("<font color='%s'><b>%s</b></font>%s", colorHex, displayName, mutationTag)
		end

		-- 4. Sub-header (Size) & Separator
		local sizeVal = obj:GetAttribute("Size") or obj:GetAttribute("Category") or "Medium"
		local subLine = string.format("<font color='#a0b5d0'>%s</font>", tostring(sizeVal))
		local separatorLine = "<font color='#405075'>___________________________</font>"

		-- 5. Weight / Mass & Distance
		local weight = obj:GetAttribute("Weight") or obj:GetAttribute("kg") or obj:GetAttribute("Mass")
		local weightLine = ""
		if weight then
			weightLine = string.format("<font color='#e0f0ff'>%.1f kg</font> <font color='#a0b0d0'>[%dm]</font>", tonumber(weight) or 0, distanceMeters or 0)
		else
			weightLine = string.format("<font color='#e0f0ff'>[%dm]</font>", distanceMeters or 0)
		end

		-- 6. Price / Value
		local price = obj:GetAttribute("Price") or obj:GetAttribute("Value") or obj:GetAttribute("Worth")
		local priceLine = ""
		if price then
			priceLine = string.format("\n<font color='#ffcc00'><b>$%s</b></font>", formatComma(price))
		end

		-- 7. Luck / Stat Bonus
		local luck = obj:GetAttribute("Luck") or obj:GetAttribute("Bonus") or obj:GetAttribute("Stat")
		local luckLine = ""
		if luck then
			local luckVal = tonumber(luck)
			local luckStr = luckVal and string.format("+%.2f%%", luckVal) or tostring(luck)
			luckLine = string.format("\n<font color='#00ff66'><b>Luck: %s</b></font>", luckStr)
		end

		return titleLine .. "\n" .. subLine .. "\n" .. separatorLine .. "\n" .. weightLine .. priceLine .. luckLine
	end

	local function createBillboardForObject(obj, namePrefix, category, accentColorHex)
		if activeESPs[obj] then return end

		local targetPart = getTargetPart(obj)
		if not targetPart then return end

		local isCardCategory = (category == "crystal" or category == "dropped_crystal")
		local bWidth = isCardCategory and 190 or 150
		local bHeight = isCardCategory and 95 or 28

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ESP_" .. tostring(obj.Name)
		billboard.Size = UDim2.new(0, bWidth, 0, bHeight)
		billboard.AlwaysOnTop = true
		billboard.ExtentsOffset = isCardCategory and Vector3.new(0, 3.5, 0) or Vector3.new(0, 2.5, 0)
		billboard.LightInfluence = 0
		billboard.MaxDistance = 2500
		billboard.Adornee = targetPart
		billboard.Parent = espFolder

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 1, 0)
		card.BackgroundColor3 = Color3.fromRGB(10, 14, 26)
		card.BackgroundTransparency = isCardCategory and 0.2 or 0.3
		card.BorderSizePixel = 0
		card.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.borderGlass or Color3.fromRGB(50, 65, 110)
		stroke.Thickness = 1
		stroke.Transparency = 0.4
		stroke.Parent = card

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -12, 1, -8)
		label.Position = UDim2.new(0, 6, 0, 4)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.RichText = true
		label.TextWrapped = true
		label.TextXAlignment = isCardCategory and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
		label.TextYAlignment = isCardCategory and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
		label.Text = buildObjectEspDetails(obj, category, 0)
		label.Parent = card

		activeESPs[obj] = {
			billboard = billboard,
			textLabel = label,
			targetPart = targetPart,
			category = category,
			lastDist = -1
		}
	end

	local function removeBillboardForObject(obj)
		local espData = activeESPs[obj]
		if espData then
			if espData.billboard then
				pcall(function() espData.billboard:Destroy() end)
			end
			activeESPs[obj] = nil
		end
	end

	local function clearCategoryESP(category)
		for obj, data in pairs(activeESPs) do
			if data.category == category then
				removeBillboardForObject(obj)
			end
		end
	end

	local function scanAllObjects()
		-- 1. Crystal ESP Scan (workspace.Things.Crystals or workspace.Crystals)
		if state.crystalEspEnabled then
			local things = workspace:FindFirstChild("Things")
			local crystalsFolder = workspace:FindFirstChild("Crystals") or (things and things:FindFirstChild("Crystals"))
			if crystalsFolder then
				for _, crystalObj in ipairs(crystalsFolder:GetChildren()) do
					if crystalMatchesFilters(crystalObj) then
						if not activeESPs[crystalObj] then
							local colorHex = getCrystalAccentColor(crystalObj.Name)
							createBillboardForObject(crystalObj, crystalObj.Name, "crystal", colorHex)
						end
					else
						removeBillboardForObject(crystalObj)
					end
				end
			end
		else
			clearCategoryESP("crystal")
		end

		-- 2. Dropped Crystal ESP Scan (workspace.DroppedCrystals)
		if state.droppedCrystalEspEnabled then
			local dcFolder = workspace:FindFirstChild("DroppedCrystals")
			if dcFolder then
				for _, dcObj in ipairs(dcFolder:GetChildren()) do
					if crystalMatchesFilters(dcObj) then
						if not activeESPs[dcObj] then
							local colorHex = getCrystalAccentColor(dcObj.Name)
							createBillboardForObject(dcObj, dcObj.Name, "dropped_crystal", colorHex)
						end
					else
						removeBillboardForObject(dcObj)
					end
				end
			end
		else
			clearCategoryESP("dropped_crystal")
		end

		-- 3. Dropped Rune ESP Scan (workspace.DroppedRunes)
		if state.droppedRuneEspEnabled then
			local drFolder = workspace:FindFirstChild("DroppedRunes")
			if drFolder then
				for _, drObj in ipairs(drFolder:GetChildren()) do
					if not activeESPs[drObj] then
						createBillboardForObject(drObj, drObj.Name, "dropped_rune", "#ffaa00")
					end
				end
			end
		else
			clearCategoryESP("dropped_rune")
		end

		-- 4. Player ESP Scan (Players)
		if state.playerEspEnabled then
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character then
					local char = otherPlayer.Character
					if not activeESPs[char] then
						local displayName = otherPlayer.DisplayName or otherPlayer.Name
						createBillboardForObject(char, "👤 " .. displayName, "player", "#8c78ff")
					end
				end
			end
		else
			clearCategoryESP("player")
		end
	end

	-- Event-driven Workspace & Folder Listeners (Instant ESP updates without 1s polling spikes)
	local function hookFolderEvents(folder, category, isCrystal)
		if not folder then return end
		folder.ChildAdded:Connect(function(child)
			if isCrystal then
				if (category == "crystal" and state.crystalEspEnabled) or (category == "dropped_crystal" and state.droppedCrystalEspEnabled) then
					if crystalMatchesFilters(child) then
						local colorHex = getCrystalAccentColor(child.Name)
						createBillboardForObject(child, child.Name, category, colorHex)
					end
				end
			elseif category == "dropped_rune" and state.droppedRuneEspEnabled then
				createBillboardForObject(child, child.Name, "dropped_rune", "#ffaa00")
			end
		end)

		folder.ChildRemoved:Connect(function(child)
			removeBillboardForObject(child)
		end)
	end

	task.spawn(function()
		local things = workspace:WaitForChild("Things", 5)
		local crystalsFolder = workspace:FindFirstChild("Crystals") or (things and things:FindFirstChild("Crystals"))
		if crystalsFolder then hookFolderEvents(crystalsFolder, "crystal", true) end

		local dcFolder = workspace:WaitForChild("DroppedCrystals", 5)
		if dcFolder then hookFolderEvents(dcFolder, "dropped_crystal", true) end

		local drFolder = workspace:WaitForChild("DroppedRunes", 5)
		if drFolder then hookFolderEvents(drFolder, "dropped_rune", false) end

		Players.PlayerAdded:Connect(function(p)
			p.CharacterAdded:Connect(function(char)
				if state.playerEspEnabled then
					local displayName = p.DisplayName or p.Name
					createBillboardForObject(char, "👤 " .. displayName, "player", "#8c78ff")
				end
			end)
		end)
	end)

	-- High-performance 10Hz Heartbeat loop (Zero CPU lag & zero 1-second FPS drops)
	local RunService = game:GetService("RunService")
	local lastScanTime = 0
	local lastUpdateDistTime = 0

	RunService.Heartbeat:Connect(function()
		local now = os.clock()

		-- 1. Fast distance update (runs at 10Hz: every 0.1s)
		if now - lastUpdateDistTime >= 0.1 then
			lastUpdateDistTime = now
			local myChar = player and player.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local myPos = myHrp and myHrp.Position or Vector3.zero

			for obj, data in pairs(activeESPs) do
				if not obj or not obj.Parent or not data.targetPart or not data.targetPart.Parent then
					removeBillboardForObject(obj)
				else
					local distInt = math.floor((myPos - data.targetPart.Position).Magnitude + 0.5)
					if distInt ~= data.lastDist then
						data.lastDist = distInt
						data.textLabel.Text = buildObjectEspDetails(obj, data.category, distInt)
					end
				end
			end
		end

		-- 2. Low-frequency periodic safety scan (runs every 8.0s instead of 1.0s to eliminate FPS drops)
		if now - lastScanTime >= 8.0 then
			lastScanTime = now
			pcall(scanAllObjects)
		end
	end)

	-- Global state and updater interface
	_G.HipHubESP = {
		getState = function()
			return state
		end,
		setState = function(newState)
			if not newState then return end
			if newState.crystalEspEnabled ~= nil then state.crystalEspEnabled = (newState.crystalEspEnabled == true) end
			if newState.droppedCrystalEspEnabled ~= nil then state.droppedCrystalEspEnabled = (newState.droppedCrystalEspEnabled == true) end
			if newState.droppedRuneEspEnabled ~= nil then state.droppedRuneEspEnabled = (newState.droppedRuneEspEnabled == true) end
			if newState.playerEspEnabled ~= nil then state.playerEspEnabled = (newState.playerEspEnabled == true) end
			if newState.selectedCrystalRarity ~= nil then state.selectedCrystalRarity = tostring(newState.selectedCrystalRarity) end
			if newState.selectedCrystalSize ~= nil then state.selectedCrystalSize = tostring(newState.selectedCrystalSize) end

			if updateCrystalEspVisuals then updateCrystalEspVisuals() end
			if updateDroppedCrystalEspVisuals then updateDroppedCrystalEspVisuals() end
			if updateDroppedRuneEspVisuals then updateDroppedRuneEspVisuals() end
			if updatePlayerEspVisuals then updatePlayerEspVisuals() end
			if updateDropdownVisuals then updateDropdownVisuals() end
			if updateSizeDropdownVisuals then updateSizeDropdownVisuals() end

			pcall(scanAllObjects)
		end,
		updateVisuals = function()
			if updateCrystalEspVisuals then updateCrystalEspVisuals() end
			if updateDroppedCrystalEspVisuals then updateDroppedCrystalEspVisuals() end
			if updateDroppedRuneEspVisuals then updateDroppedRuneEspVisuals() end
			if updatePlayerEspVisuals then updatePlayerEspVisuals() end
			if updateDropdownVisuals then updateDropdownVisuals() end
			if updateSizeDropdownVisuals then updateSizeDropdownVisuals() end

			pcall(scanAllObjects)
		end
	}
end

-- Initialize ESP module
pcall(initESP)
