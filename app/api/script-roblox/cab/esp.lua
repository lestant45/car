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
	}

	local updateCrystalEspVisuals, updateDroppedCrystalEspVisuals, updateDroppedRuneEspVisuals, updatePlayerEspVisuals, updateDropdownVisuals

	if refs.addTab then
		local espTabFrame = refs.addTab("ESP", "👁️", 3)
		refs.applyListLayout(espTabFrame, 10)

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
		espSub.Text = "Real-time world text labels for crystals, dropped items, and players."
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
		menuFrame.Size = UDim2.new(1, -24, 0, 185)
		menuFrame.Position = UDim2.new(0, 12, 0, 44)
		menuFrame.BackgroundTransparency = 1
		menuFrame.Visible = false
		menuFrame.Parent = filterCard

		refs.applyListLayout(menuFrame, 4)

		local rarities = {
			"All",
			"T1 (Common)",
			"T2 (Uncommon)",
			"T3 (Rare)",
			"T4 (Epic)",
			"T5 (Legendary)",
			"T6 (Mythical)"
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
			itemBtn.Size = UDim2.new(1, 0, 0, 22)
			itemBtn.BackgroundColor3 = (state.selectedCrystalRarity == rName) and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
			itemBtn.BackgroundTransparency = 0.2
			itemBtn.Text = rName
			itemBtn.TextColor3 = (state.selectedCrystalRarity == rName) and COLORS.accentCyan or COLORS.textSecondary
			itemBtn.Font = Enum.Font.GothamMedium
			itemBtn.TextSize = 11
			itemBtn.Parent = menuFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 4)
			itemCorner.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				state.selectedCrystalRarity = rName
				isOpen = false
				menuFrame.Visible = false
				TweenService:Create(filterCard, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 44) }):Play()
				updateDropdownVisuals()
				if saveConfig then pcall(saveConfig) end
			end)
		end

		dropBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			menuFrame.Visible = isOpen
			local targetHeight = isOpen and (44 + 195) or 44
			TweenService:Create(filterCard, TweenInfo.new(0.25, Enum.EasingStyle.Quart), { Size = UDim2.new(1, 0, 0, targetHeight) }):Play()
			updateDropdownVisuals()
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
		if string.find(nameLower, "_t6") or string.find(nameLower, "t6") or string.find(nameLower, "mythical") then
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

		local filterMap = {
			["t1"] = {"_t1", "t1", "common"},
			["t1 (common)"] = {"_t1", "t1", "common"},
			["common"] = {"_t1", "t1", "common"},

			["t2"] = {"_t2", "t2", "uncommon"},
			["t2 (uncommon)"] = {"_t2", "t2", "uncommon"},
			["uncommon"] = {"_t2", "t2", "uncommon"},

			["t3"] = {"_t3", "t3", "rare"},
			["t3 (rare)"] = {"_t3", "t3", "rare"},
			["rare"] = {"_t3", "t3", "rare"},

			["t4"] = {"_t4", "t4", "epic"},
			["t4 (epic)"] = {"_t4", "t4", "epic"},
			["epic"] = {"_t4", "t4", "epic"},

			["t5"] = {"_t5", "t5", "legendary"},
			["t5 (legendary)"] = {"_t5", "t5", "legendary"},
			["legendary"] = {"_t5", "t5", "legendary"},

			["t6"] = {"_t6", "t6", "mythical"},
			["t6 (mythical)"] = {"_t6", "t6", "mythical"},
			["mythical"] = {"_t6", "t6", "mythical"},
		}

		local keywords = filterMap[string.lower(filter)]
		if keywords then
			for _, kw in ipairs(keywords) do
				if string.find(nameLower, kw, 1, true) then
					return true
				end
			end
		else
			if string.find(nameLower, string.lower(filter), 1, true) then
				return true
			end
		end

		local attr = crystalObj:GetAttribute("Rarity") or crystalObj:GetAttribute("Tier") or crystalObj:GetAttribute("rarity") or crystalObj:GetAttribute("tier")
		if attr then
			local attrStr = string.lower(tostring(attr))
			if string.find(attrStr, string.lower(filter), 1, true) then
				return true
			end
		end

		return false
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

	local function buildStaticEspTemplate(obj, category)
		if category == "player" then
			local displayName = obj.Name
			if obj:IsA("Model") then
				local pl = Players:GetPlayerFromCharacter(obj)
				if pl then displayName = pl.DisplayName or pl.Name end
			end
			return string.format("<font color='#8c78ff'><b>👤 %s</b></font> <font color='#a0b0d0'>[%%dm]</font>", displayName)
		elseif category == "dropped_rune" then
			return string.format("<font color='#ffaa00'><b>%s</b></font> <font color='#a0b0d0'>[%%dm]</font>", obj.Name)
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
				T1 = "Common", T2 = "Uncommon", T3 = "Rare", T4 = "Epic", T5 = "Legendary", T6 = "Mythical"
			}
			rarityStr = tierMap[tier] or tier
			displayName = "Crystal"
		elseif string.find(nameLower, "_t%d") then
			local tier = string.match(name, "T%d+") or ""
			local tierMap = {
				T1 = "Common", T2 = "Uncommon", T3 = "Rare", T4 = "Epic", T5 = "Legendary", T6 = "Mythical"
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

		-- 5. Weight / Mass & Distance Template
		local weight = obj:GetAttribute("Weight") or obj:GetAttribute("kg") or obj:GetAttribute("Mass")
		local weightLine = ""
		if weight then
			weightLine = string.format("<font color='#e0f0ff'>%.1f kg</font> <font color='#a0b0d0'>[%%dm]</font>", tonumber(weight) or 0)
		else
			weightLine = "<font color='#e0f0ff'>[%%dm]</font>"
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
		billboard.MaxDistance = 1200
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

		local staticTemplate = buildStaticEspTemplate(obj, category)

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
		label.Text = string.format(staticTemplate, 0)
		label.Parent = card

		activeESPs[obj] = {
			billboard = billboard,
			textLabel = label,
			targetPart = targetPart,
			category = category,
			textFormat = staticTemplate,
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
					if crystalMatchesRarity(crystalObj) then
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
					if crystalMatchesRarity(dcObj) then
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

	-- High-performance 10Hz Heartbeat loop (Zero CPU lag)
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
						data.textLabel.Text = string.format(data.textFormat, distInt)
					end
				end
			end
		end

		-- 2. Periodic folder scanning (runs every 1.5s)
		if now - lastScanTime >= 1.5 then
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

			if updateCrystalEspVisuals then updateCrystalEspVisuals() end
			if updateDroppedCrystalEspVisuals then updateDroppedCrystalEspVisuals() end
			if updateDroppedRuneEspVisuals then updateDroppedRuneEspVisuals() end
			if updatePlayerEspVisuals then updatePlayerEspVisuals() end
			if updateDropdownVisuals then updateDropdownVisuals() end

			pcall(scanAllObjects)
		end,
		updateVisuals = function()
			if updateCrystalEspVisuals then updateCrystalEspVisuals() end
			if updateDroppedCrystalEspVisuals then updateDroppedCrystalEspVisuals() end
			if updateDroppedRuneEspVisuals then updateDroppedRuneEspVisuals() end
			if updatePlayerEspVisuals then updatePlayerEspVisuals() end
			if updateDropdownVisuals then updateDropdownVisuals() end

			pcall(scanAllObjects)
		end
	}
end

-- Initialize ESP module
pcall(initESP)
