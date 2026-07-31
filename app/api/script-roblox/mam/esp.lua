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
		boulderEspEnabled = false,
		droppedCrystalEspEnabled = false,
		droppedRuneEspEnabled = false,
		playerEspEnabled = false,
		selectedCrystalRarityFilters = { ["All"] = true },
		selectedCrystalSizeFilters = { ["All"] = true },
		selectedBoulderRarityFilters = { ["All"] = true },
	}

	local BOULDER_CONFIG = {
		Mossite = {
			rarity = "Common",
			color = "#d0d0d0",
			minPickaxeId = "TitaniumSpike",
			swingsAtGate = 240,
		},
		Voltite = {
			rarity = "Uncommon",
			color = "#55ff55",
			minPickaxeId = "CelestialApex",
			swingsAtGate = 400,
		},
		Gildrite = {
			rarity = "Rare",
			color = "#00c8ff",
			minPickaxeId = "EclipseFang",
			swingsAtGate = 600,
		},
		Rimeveil = {
			rarity = "Epic",
			color = "#aa00ff",
			minPickaxeId = "Voidreign",
			swingsAtGate = 910,
		},
		Nocturnite = {
			rarity = "Legendary",
			color = "#ffaa00",
			minPickaxeId = "TheTerminus",
			swingsAtGate = 1440,
		}
	}

	local updateCrystalEspVisuals, updateBoulderEspVisuals, updateDroppedCrystalEspVisuals, updateDroppedRuneEspVisuals, updatePlayerEspVisuals, updateDropdownVisuals, updateSizeDropdownVisuals, updateBoulderDropdownVisuals



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

		-- Collapsible Filter Section
		local filterSection = refs.createCollapsibleSection(espTabFrame, "Filters", 3)
		refs.applyPadding(filterSection.Content, 2, 2, 2, 2)

		-- 🔽 Crystal Rarity Filter Dropdown Card
		local filterCard, filterBtn, filterLabel, filterMenu, filterSearch, filterScroll = refs.createGlassDropdown(
			filterSection.Content, "Crystal Rarity Filter", (state.selectedCrystalRarity or "All"), 1
		)

		local rarities = {
			"All",
			"Common",
			"Uncommon",
			"Rare",
			"Epic",
			"Legendary",
			"Mythical"
		}
		refs.registerDropdownMenu(filterBtn, filterMenu)

		local function getSelectedCrystalRarityLabelText()
			if not state.selectedCrystalRarityFilters or state.selectedCrystalRarityFilters["All"] or next(state.selectedCrystalRarityFilters) == nil then
				return "All"
			end
			local list = {}
			for _, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }) do
				if state.selectedCrystalRarityFilters[r] then table.insert(list, r) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local rarityBinder = refs.bindDropdown(
			filterBtn, filterMenu, filterSearch, filterScroll, rarities,
			function(opt)
				return state.selectedCrystalRarityFilters and state.selectedCrystalRarityFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					state.selectedCrystalRarityFilters = { ["All"] = true }
				else
					state.selectedCrystalRarityFilters["All"] = nil
					state.selectedCrystalRarityFilters[opt] = not state.selectedCrystalRarityFilters[opt]
					local hasAny = false
					for _, v in pairs(state.selectedCrystalRarityFilters) do
						if v then hasAny = true break end
					end
					if not hasAny then state.selectedCrystalRarityFilters["All"] = true end
				end
				if _G.HipHubESP and _G.HipHubESP.updateVisuals then _G.HipHubESP.updateVisuals() end
			end,
			function()
				filterLabel.Text = getSelectedCrystalRarityLabelText()
			end
		)

		updateDropdownVisuals = function()
			filterLabel.Text = getSelectedCrystalRarityLabelText()
			rarityBinder.updateOptionVisuals()
		end

		-- 🔽 Crystal Size Filter Dropdown Card
		local sizeFilterCard, sizeDropBtn, sizeDropLabel, sizeMenuFrame, sizeSearch, sizeScroll = refs.createGlassDropdown(
			filterSection.Content, "Crystal Size Filter", "All", 2
		)

		local sizes = {
			"All",
			"Small",
			"Medium",
			"Large",
			"Titan",
			"Colossal"
		}
		refs.registerDropdownMenu(sizeDropBtn, sizeMenuFrame)

		local function getSelectedCrystalSizeLabelText()
			if not state.selectedCrystalSizeFilters or state.selectedCrystalSizeFilters["All"] or next(state.selectedCrystalSizeFilters) == nil then
				return "All"
			end
			local list = {}
			for _, s in ipairs({ "Small", "Medium", "Large", "Titan", "Colossal" }) do
				if state.selectedCrystalSizeFilters[s] then table.insert(list, s) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local sizeBinder = refs.bindDropdown(
			sizeDropBtn, sizeMenuFrame, sizeSearch, sizeScroll, sizes,
			function(opt)
				return state.selectedCrystalSizeFilters and state.selectedCrystalSizeFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					state.selectedCrystalSizeFilters = { ["All"] = true }
				else
					state.selectedCrystalSizeFilters["All"] = nil
					state.selectedCrystalSizeFilters[opt] = not state.selectedCrystalSizeFilters[opt]
					local hasAny = false
					for _, v in pairs(state.selectedCrystalSizeFilters) do
						if v then hasAny = true break end
					end
					if not hasAny then state.selectedCrystalSizeFilters["All"] = true end
				end
				if _G.HipHubESP and _G.HipHubESP.updateVisuals then _G.HipHubESP.updateVisuals() end
			end,
			function()
				sizeDropLabel.Text = getSelectedCrystalSizeLabelText()
			end
		)

		updateSizeDropdownVisuals = function()
			sizeDropLabel.Text = getSelectedCrystalSizeLabelText()
			sizeBinder.updateOptionVisuals()
		end

		-- 🔽 Boulder Rarity Filter Dropdown Card
		local bFilterCard, bFilterBtn, bFilterLabel, bFilterMenu, bFilterSearch, bFilterScroll = refs.createGlassDropdown(
			filterSection.Content, "Boulder Rarity Filter", "All", 3
		)

		local boulderRarities = {
			"All",
			"Common",
			"Uncommon",
			"Rare",
			"Epic",
			"Legendary"
		}
		refs.registerDropdownMenu(bFilterBtn, bFilterMenu)

		local function getSelectedBoulderRarityLabelText()
			if not state.selectedBoulderRarityFilters or state.selectedBoulderRarityFilters["All"] or next(state.selectedBoulderRarityFilters) == nil then
				return "All"
			end
			local list = {}
			for _, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary" }) do
				if state.selectedBoulderRarityFilters[r] then table.insert(list, r) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local bRarityBinder = refs.bindDropdown(
			bFilterBtn, bFilterMenu, bFilterSearch, bFilterScroll, boulderRarities,
			function(opt)
				return state.selectedBoulderRarityFilters and state.selectedBoulderRarityFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					state.selectedBoulderRarityFilters = { ["All"] = true }
				else
					state.selectedBoulderRarityFilters["All"] = nil
					state.selectedBoulderRarityFilters[opt] = not state.selectedBoulderRarityFilters[opt]
					local hasAny = false
					for _, v in pairs(state.selectedBoulderRarityFilters) do
						if v then hasAny = true break end
					end
					if not hasAny then state.selectedBoulderRarityFilters["All"] = true end
				end
				if _G.HipHubESP and _G.HipHubESP.updateVisuals then _G.HipHubESP.updateVisuals() end
			end,
			function()
				bFilterLabel.Text = getSelectedBoulderRarityLabelText()
			end
		)

		updateBoulderDropdownVisuals = function()
			bFilterLabel.Text = getSelectedBoulderRarityLabelText()
			bRarityBinder.updateOptionVisuals()
		end

		-- Collapsible Toggles Section
		local toggleSection = refs.createCollapsibleSection(espTabFrame, "Toggles", 5)
		refs.applyPadding(toggleSection.Content, 2, 2, 2, 2)

		-- Toggles Card
		local togglesCard = Instance.new("Frame")
		togglesCard.Size = UDim2.new(1, 0, 0, 215)
		togglesCard.BackgroundColor3 = COLORS.glassCard
		togglesCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		togglesCard.BorderSizePixel = 0
		togglesCard.Parent = toggleSection.Content

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
			if _G.HipHubESP and _G.HipHubESP.updateVisuals then pcall(_G.HipHubESP.updateVisuals) end
			if saveConfig then pcall(saveConfig) end
		end)

		-- 2. Boulder ESP Toggle
		local bRow, bTrack, bThumb = refs.createGlassToggle(togglesCard, "Boulder ESP", 2)
		updateBoulderEspVisuals = function()
			if state.boulderEspEnabled then
				TweenService:Create(bTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(bThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(bTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(bThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		bTrack.MouseButton1Click:Connect(function()
			state.boulderEspEnabled = not state.boulderEspEnabled
			updateBoulderEspVisuals()
			if _G.HipHubESP and _G.HipHubESP.updateVisuals then pcall(_G.HipHubESP.updateVisuals) end
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
			if _G.HipHubESP and _G.HipHubESP.updateVisuals then pcall(_G.HipHubESP.updateVisuals) end
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
			if _G.HipHubESP and _G.HipHubESP.updateVisuals then pcall(_G.HipHubESP.updateVisuals) end
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
			if _G.HipHubESP and _G.HipHubESP.updateVisuals then pcall(_G.HipHubESP.updateVisuals) end
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
			local firstPart = obj:FindFirstChildWhichIsA("BasePart")
			if firstPart then return firstPart end
			for _, desc in ipairs(obj:GetDescendants()) do
				if desc:IsA("BasePart") then
					return desc
				end
			end
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
		local filters = state.selectedCrystalRarityFilters or { ["All"] = true }
		if filters["All"] or next(filters) == nil then return true end

		local nameLower = string.lower(crystalObj.Name)
		local attr = crystalObj:GetAttribute("Rarity") or crystalObj:GetAttribute("Tier") or crystalObj:GetAttribute("rarity") or crystalObj:GetAttribute("tier")
		local attrStr = attr and string.lower(tostring(attr)) or ""

		local filterMap = {
			["common"] = {"_t1", "t1", "common"},
			["uncommon"] = {"_t2", "t2", "uncommon"},
			["rare"] = {"_t3", "t3", "rare"},
			["epic"] = {"_t4", "t4", "epic"},
			["legendary"] = {"_t5", "t5", "legendary"},
			["mythic"] = {"_t6", "t6", "mythical", "mythic"},
			["mythical"] = {"_t6", "t6", "mythical", "mythic"},
		}

		for r, isSel in pairs(filters) do
			if isSel == true then
				local filterLower = string.lower(tostring(r))
				local keywords = filterMap[filterLower]
				if keywords then
					for _, kw in ipairs(keywords) do
						if string.find(nameLower, kw, 1, true) then return true end
					end
				end
				if string.find(nameLower, filterLower, 1, true) then return true end
				if attrStr ~= "" then
					if string.find(attrStr, filterLower, 1, true) then return true end
					if keywords then
						for _, kw in ipairs(keywords) do
							if string.find(attrStr, kw, 1, true) then return true end
						end
					end
				end
			end
		end

		return false
	end

	local function crystalMatchesSize(crystalObj)
		local filters = state.selectedCrystalSizeFilters or { ["All"] = true }
		if filters["All"] or next(filters) == nil then return true end

		local nameLower = string.lower(crystalObj.Name)
		local attr = crystalObj:GetAttribute("Size") or crystalObj:GetAttribute("Category") or crystalObj:GetAttribute("size") or crystalObj:GetAttribute("category")
		local attrStr = attr and string.lower(tostring(attr)) or ""

		local sizeVec = nil
		if crystalObj:IsA("BasePart") then
			sizeVec = crystalObj.Size
		elseif crystalObj:IsA("Model") then
			local primary = crystalObj.PrimaryPart or crystalObj:FindFirstChildWhichIsA("BasePart")
			if primary then sizeVec = primary.Size end
		end

		for s, isSel in pairs(filters) do
			if isSel == true then
				local filterLower = string.lower(tostring(s))
				if string.find(nameLower, filterLower, 1, true) then return true end
				if attrStr ~= "" and string.find(attrStr, filterLower, 1, true) then return true end

				if sizeVec then
					local maxDim = math.max(sizeVec.X, sizeVec.Y, sizeVec.Z)
					if filterLower == "colossal" and maxDim >= 12 then return true
					elseif filterLower == "titan" and (maxDim >= 7 and maxDim < 12) then return true
					elseif filterLower == "large" and (maxDim >= 4.5 and maxDim < 7) then return true
					elseif filterLower == "medium" and (maxDim >= 1.8 and maxDim < 4.5) then return true
					elseif filterLower == "small" and maxDim < 1.8 then return true
					end
				end
			end
		end

		return false
	end

	local function crystalMatchesFilters(crystalObj)
		return crystalMatchesRarity(crystalObj) and crystalMatchesSize(crystalObj)
	end

	local function boulderMatchesRarity(boulderObj)
		local filters = state.selectedBoulderRarityFilters or { ["All"] = true }
		if filters["All"] or next(filters) == nil then return true end

		local nameLower = string.lower(boulderObj.Name)
		local parentLower = boulderObj.Parent and string.lower(boulderObj.Parent.Name) or ""
		local attr = boulderObj:GetAttribute("Rarity") or boulderObj:GetAttribute("rarity")
			or (boulderObj.Parent and (boulderObj.Parent:GetAttribute("Rarity") or boulderObj.Parent:GetAttribute("rarity")))
		local attrStr = attr and string.lower(tostring(attr)) or ""

		for r, isSel in pairs(filters) do
			if isSel == true then
				local filterLower = string.lower(tostring(r))
				for bName, bData in pairs(BOULDER_CONFIG) do
					local bNameLower = string.lower(bName)
					if string.find(nameLower, bNameLower, 1, true) or string.find(parentLower, bNameLower, 1, true) then
						if string.lower(bData.rarity) == filterLower then
							return true
						end
					end
				end
				if attrStr == filterLower then return true end
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

	local function buildObjectEspDetails(obj, category, distanceMeters)
		if category == "player" then
			local displayName = obj.Name
			if obj:IsA("Model") then
				local pl = Players:GetPlayerFromCharacter(obj)
				if pl then displayName = pl.DisplayName or pl.Name end
			end
			return string.format("<font color='#8c78ff'><b>👤 %s</b></font> <font color='#a0b0d0'>[%dm]</font>", displayName, distanceMeters or 0)
		elseif category == "dropped_rune" then
			local displayName = obj.Name
			if not string.find(string.lower(displayName), "rune", 1, true) then
				displayName = displayName .. " Rune"
			end
			return string.format("<font color='#ffaa00'><b>📜 %s</b></font>\n<font color='#ffcc00'>[RUNE]</font> <font color='#e0f0ff'>[%dm]</font>", displayName, distanceMeters or 0)
		elseif category == "boulder" then
			local name = obj.Name
			local nameLower = string.lower(name)
			local bData = nil
			local matchedName = name

			for bName, cfg in pairs(BOULDER_CONFIG) do
				if string.find(nameLower, string.lower(bName), 1, true) then
					bData = cfg
					matchedName = bName
					break
				end
			end

			local rarityStr = bData and bData.rarity or (obj:GetAttribute("Rarity") or "Common")
			local colorHex = bData and bData.color or getCrystalAccentColor(rarityStr)
			local minPick = bData and bData.minPickaxeId or "Pickaxe"
			local swings = bData and bData.swingsAtGate or "?"

			local hpVal = obj:GetAttribute("Health") or obj:GetAttribute("HP") or obj:GetAttribute("Swings")
			local maxHp = obj:GetAttribute("MaxHealth") or obj:GetAttribute("MaxHP") or swings

			local displayTitle = string.find(string.lower(matchedName), "boulder", 1, true) and matchedName or (matchedName .. " Boulder")
			local titleLine = string.format("<font color='%s'><b>%s</b></font> <b>%s</b>", colorHex, rarityStr, displayTitle)
			local subLine = string.format("<font color='#a0b5d0'>Req: %s</font>", minPick)
			local separatorLine = "<font color='#405075'>___________________________</font>"

			local hpStr = ""
			if hpVal then
				hpStr = string.format("\n<font color='#00ff66'>HP: %s/%s</font>", tostring(hpVal), tostring(maxHp))
			else
				hpStr = string.format("\n<font color='#ffcc00'>Swings: %s</font>", tostring(swings))
			end

			local distLine = string.format("<font color='#e0f0ff'>[%dm]</font>", distanceMeters or 0)

			return titleLine .. "\n" .. subLine .. hpStr .. "\n" .. separatorLine .. "\n" .. distLine
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

		local isCardCategory = (category == "crystal" or category == "dropped_crystal" or category == "boulder" or category == "dropped_rune")
		local bWidth = (category == "dropped_rune") and 160 or (isCardCategory and 190 or 150)
		local bHeight = (category == "dropped_rune") and 48 or (isCardCategory and 95 or 28)

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
		-- 1. Crystal ESP Scan (Scans all mountain folders & descendants for unmined crystals inside rocks)
		if state.crystalEspEnabled then
			local things = workspace:FindFirstChild("Things")
			local foldersToScan = {
				workspace:FindFirstChild("Crystals"),
				things and things:FindFirstChild("Crystals"),
				workspace:FindFirstChild("FrozenCaves"),
				workspace:FindFirstChild("CaveZones"),
				workspace:FindFirstChild("Rocks"),
				workspace:FindFirstChild("Nodes"),
				things and things:FindFirstChild("MountainZones"),
			}

			local scanned = {}
			for _, folder in ipairs(foldersToScan) do
				if folder then
					for _, crystalObj in ipairs(folder:GetDescendants()) do
						if not scanned[crystalObj] and (crystalObj:IsA("BasePart") or crystalObj:IsA("Model")) and not crystalObj:IsA("Accessory") then
							local nameLower = string.lower(crystalObj.Name)
							if string.find(nameLower, "crystal") or string.find(nameLower, "_t") or string.find(nameLower, "t%d") or crystalObj:GetAttribute("Rarity") or crystalObj:GetAttribute("Tier") then
								scanned[crystalObj] = true
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
				for _, dcObj in ipairs(dcFolder:GetDescendants()) do
					if dcObj:IsA("BasePart") or dcObj:IsA("Model") then
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
			end
		else
			clearCategoryESP("dropped_crystal")
		end

		-- 3. Dropped Rune ESP Scan (workspace.DroppedRunes, workspace.Runes & direct workspace children)
		if state.droppedRuneEspEnabled then
			local drFolder = workspace:FindFirstChild("DroppedRunes") or workspace:FindFirstChild("Runes")
			if drFolder then
				for _, drObj in ipairs(drFolder:GetChildren()) do
					if not activeESPs[drObj] then
						createBillboardForObject(drObj, drObj.Name, "dropped_rune", "#ffaa00")
					end
				end
			end
			for _, child in ipairs(workspace:GetChildren()) do
				if child:IsA("Model") or child:IsA("BasePart") then
					local cNameLower = string.lower(child.Name)
					local isRuneObj = string.find(cNameLower, "rune", 1, true) ~= nil
						or string.find(cNameLower, "luck", 1, true) ~= nil
						or string.find(cNameLower, "haste", 1, true) ~= nil
						or string.find(cNameLower, "storm", 1, true) ~= nil
						or string.find(cNameLower, "weight", 1, true) ~= nil
						or string.find(cNameLower, "fortune", 1, true) ~= nil
						or string.find(cNameLower, "detonation", 1, true) ~= nil
						or string.find(cNameLower, "preservation", 1, true) ~= nil
						or string.find(cNameLower, "warmth", 1, true) ~= nil
						or string.find(cNameLower, "excavator", 1, true) ~= nil
						or string.find(cNameLower, "colossus", 1, true) ~= nil

					if isRuneObj then
						if not activeESPs[child] then
							createBillboardForObject(child, child.Name, "dropped_rune", "#ffaa00")
						end
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

		-- 5. Boulder ESP Scan (Ultra-Lightweight & Fast)
		if state.boulderEspEnabled then
			local mountainDeco = workspace:FindFirstChild("MountainDecorations")
			local primaryBouldersFolder = mountainDeco and mountainDeco:FindFirstChild("Boulders")
			local things = workspace:FindFirstChild("Things")

			local targetFolders = {
				primaryBouldersFolder,
				workspace:FindFirstChild("Boulders"),
				workspace:FindFirstChild("RenderedBoulders"),
				workspace:FindFirstChild("ActiveBoulders"),
				things and things:FindFirstChild("Boulders"),
			}

			local scannedBoulders = {}
			for _, folder in ipairs(targetFolders) do
				if folder then
					for _, topObj in ipairs(folder:GetChildren()) do
						if topObj:IsA("Model") or topObj:IsA("BasePart") then
							if not scannedBoulders[topObj] then
								scannedBoulders[topObj] = true

								local nameLower = string.lower(topObj.Name)
								local isBoulder = BOULDER_CONFIG[topObj.Name] ~= nil
									or string.find(nameLower, "boulder", 1, true)
									or string.find(nameLower, "mossite", 1, true)
									or string.find(nameLower, "voltite", 1, true)
									or string.find(nameLower, "gildrite", 1, true)
									or string.find(nameLower, "rimeveil", 1, true)
									or string.find(nameLower, "nocturnite", 1, true)

								if isBoulder then
									if boulderMatchesRarity(topObj) then
										if not activeESPs[topObj] then
											local boulderData = BOULDER_CONFIG[topObj.Name]
											if not boulderData then
												for bName, bData in pairs(BOULDER_CONFIG) do
													if string.find(nameLower, string.lower(bName), 1, true) then
														boulderData = bData
														break
													end
												end
											end
											local colorHex = boulderData and boulderData.color or "#00c8ff"
											createBillboardForObject(topObj, topObj.Name, "boulder", colorHex)
										end
									else
										removeBillboardForObject(topObj)
									end
								end
							end
						end
					end
				end
			end
		else
			clearCategoryESP("boulder")
		end
	end

	-- Event-driven Workspace & Folder Listeners (Instant ESP updates without 1s polling spikes)
	local function hookFolderEvents(folder, category, isCrystal)
		if not folder then return end
		if category == "boulder" then
			folder.ChildAdded:Connect(function(child)
				if state.boulderEspEnabled and (child:IsA("Model") or child:IsA("BasePart")) then
					if boulderMatchesRarity(child) then
						local boulderData = BOULDER_CONFIG[child.Name]
						if not boulderData then
							local nameLower = string.lower(child.Name)
							for bName, bData in pairs(BOULDER_CONFIG) do
								if string.find(nameLower, string.lower(bName), 1, true) then
									boulderData = bData
									break
								end
							end
						end
						local colorHex = boulderData and boulderData.color or "#00c8ff"
						createBillboardForObject(child, child.Name, "boulder", colorHex)
					end
				end
			end)

			folder.ChildRemoved:Connect(function(child)
				removeBillboardForObject(child)
			end)
			return
		end

		folder.DescendantAdded:Connect(function(child)
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

		folder.DescendantRemoving:Connect(function(child)
			removeBillboardForObject(child)
		end)
	end

	task.spawn(function()
		local things = workspace:WaitForChild("Things", 5)
		local mountainDeco = workspace:FindFirstChild("MountainDecorations") or workspace:WaitForChild("MountainDecorations", 3)

		local crystalsFolder = workspace:FindFirstChild("Crystals") or (things and things:FindFirstChild("Crystals"))
		if crystalsFolder then hookFolderEvents(crystalsFolder, "crystal", true) end

		local frozenCaves = workspace:FindFirstChild("FrozenCaves")
		if frozenCaves then hookFolderEvents(frozenCaves, "crystal", true) end

		local caveZones = workspace:FindFirstChild("CaveZones")
		if caveZones then hookFolderEvents(caveZones, "crystal", true) end

		local bFolder = (mountainDeco and mountainDeco:FindFirstChild("Boulders")) 
			or workspace:FindFirstChild("Boulders") 
			or workspace:FindFirstChild("RenderedBoulders") 
			or workspace:FindFirstChild("ActiveBoulders") 
			or (things and (things:FindFirstChild("Boulders") or things:FindFirstChild("RenderedBoulders")))
		if bFolder then hookFolderEvents(bFolder, "boulder", false) end

		local dcFolder = workspace:WaitForChild("DroppedCrystals", 5)
		if dcFolder then hookFolderEvents(dcFolder, "dropped_crystal", true) end

		local drFolder = workspace:WaitForChild("DroppedRunes", 5)
		if drFolder then hookFolderEvents(drFolder, "dropped_rune", false) end

		workspace.ChildAdded:Connect(function(child)
			if state.droppedRuneEspEnabled then
				local cNameLower = string.lower(child.Name)
				local isRuneObj = string.find(cNameLower, "rune", 1, true) ~= nil
					or string.find(cNameLower, "luck", 1, true) ~= nil
					or string.find(cNameLower, "haste", 1, true) ~= nil
					or string.find(cNameLower, "storm", 1, true) ~= nil
					or string.find(cNameLower, "weight", 1, true) ~= nil
					or string.find(cNameLower, "fortune", 1, true) ~= nil
					or string.find(cNameLower, "detonation", 1, true) ~= nil
					or string.find(cNameLower, "preservation", 1, true) ~= nil
					or string.find(cNameLower, "warmth", 1, true) ~= nil
					or string.find(cNameLower, "excavator", 1, true) ~= nil
					or string.find(cNameLower, "colossus", 1, true) ~= nil

				if isRuneObj then
					createBillboardForObject(child, child.Name, "dropped_rune", "#ffaa00")
				end
			end
		end)
		workspace.ChildRemoved:Connect(function(child)
			removeBillboardForObject(child)
		end)

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
			if newState.boulderEspEnabled ~= nil then state.boulderEspEnabled = (newState.boulderEspEnabled == true) end
			if newState.droppedCrystalEspEnabled ~= nil then state.droppedCrystalEspEnabled = (newState.droppedCrystalEspEnabled == true) end
			if newState.droppedRuneEspEnabled ~= nil then state.droppedRuneEspEnabled = (newState.droppedRuneEspEnabled == true) end
			if newState.playerEspEnabled ~= nil then state.playerEspEnabled = (newState.playerEspEnabled == true) end
			if newState.selectedCrystalRarityFilters ~= nil then state.selectedCrystalRarityFilters = newState.selectedCrystalRarityFilters end
			if newState.selectedCrystalSizeFilters ~= nil then state.selectedCrystalSizeFilters = newState.selectedCrystalSizeFilters end
			if newState.selectedBoulderRarityFilters ~= nil then state.selectedBoulderRarityFilters = newState.selectedBoulderRarityFilters end

			if updateCrystalEspVisuals then updateCrystalEspVisuals() end
			if updateBoulderEspVisuals then updateBoulderEspVisuals() end
			if updateDroppedCrystalEspVisuals then updateDroppedCrystalEspVisuals() end
			if updateDroppedRuneEspVisuals then updateDroppedRuneEspVisuals() end
			if updatePlayerEspVisuals then updatePlayerEspVisuals() end
			if updateDropdownVisuals then updateDropdownVisuals() end
			if updateSizeDropdownVisuals then updateSizeDropdownVisuals() end
			if updateBoulderDropdownVisuals then updateBoulderDropdownVisuals() end

			pcall(scanAllObjects)
		end,
		updateVisuals = function()
			if updateCrystalEspVisuals then updateCrystalEspVisuals() end
			if updateBoulderEspVisuals then updateBoulderEspVisuals() end
			if updateDroppedCrystalEspVisuals then updateDroppedCrystalEspVisuals() end
			if updateDroppedRuneEspVisuals then updateDroppedRuneEspVisuals() end
			if updatePlayerEspVisuals then updatePlayerEspVisuals() end
			if updateDropdownVisuals then updateDropdownVisuals() end
			if updateSizeDropdownVisuals then updateSizeDropdownVisuals() end
			if updateBoulderDropdownVisuals then updateBoulderDropdownVisuals() end

			pcall(scanAllObjects)
		end
	}
end

-- Initialize ESP module
pcall(initESP)
