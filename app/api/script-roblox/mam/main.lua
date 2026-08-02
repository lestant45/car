-- 🧠 CAB Main Window Controller
-- Core UI wire logic (dragging, resizing, closing, minimizing, keybind toggle, and config persistence)

local success, err = pcall(function()
	local refs = _G.HipHubUI
	if not refs then
		return
	end

	local COLORS = refs.COLORS or {
		textWhite = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(150, 160, 190),
		glassActive = Color3.fromRGB(34, 40, 68),
		glassSurface = Color3.fromRGB(16, 20, 36),
		accentCyan = Color3.fromRGB(0, 200, 255),
	}

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = refs.UserInputService
	local TweenService = refs.TweenService
	local player = Players.LocalPlayer

	-- UI References
	local gui = refs.gui
	local mainFrame = refs.mainFrame
	local shadowFrame = refs.shadowFrame
	local topBar = refs.topBar
	local closeButton = refs.closeButton
	local minimizeButton = refs.minimizeButton
	local fullscreenButton = refs.fullscreenButton
	local restoreButton = refs.restoreButton
	local resizeHandle = refs.resizeHandle
	local avatarLabel = refs.avatarLabel
	local selectTab = refs.selectTab
	local syncShadow = refs.syncShadow
	local kbValue = refs.kbValue

	-- Design tokens
	local toggleOnColor = COLORS.toggleOn or Color3.fromRGB(0, 180, 230)
	local toggleOffColor = COLORS.toggleOff or Color3.fromRGB(40, 46, 70)

	local saveConfig

	-- Catcher persistent states
	local catchDelay = 1.0
	local safeModeEnabled = true
	local minLevelFilter = 1
	local selectedRarityIndex = 1

	------------------------------------------------
	-- 🖼️ DRAGGING FUNCTIONALITY
	------------------------------------------------
	local dragging, dragInput, dragStart, startPos
	local function updateDrag(input)
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		if syncShadow then pcall(syncShadow) end
	end

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then updateDrag(input) end
	end)

	------------------------------------------------
	-- ⬜ FULLSCREEN TOGGLE
	------------------------------------------------
	local isFullscreen = false
	local windowedSize = mainFrame.Size
	local windowedPos = mainFrame.Position

	if fullscreenButton then
		fullscreenButton.MouseButton1Click:Connect(function()
			isFullscreen = not isFullscreen
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

			if isFullscreen then
				-- Save windowed state
				windowedSize = mainFrame.Size
				windowedPos = mainFrame.Position

				TweenService:Create(mainFrame, tweenInfo, {
					Size = UDim2.new(1, 0, 1, 0),
					Position = UDim2.new(0, 0, 0, 0),
				}):Play()

				if shadowFrame then
					TweenService:Create(shadowFrame, tweenInfo, {
						Size = UDim2.new(1, 12, 1, 12),
						Position = UDim2.new(0, -6, 0, -6),
					}):Play()
				end

				if refs.updateFullscreenIcon then
					pcall(refs.updateFullscreenIcon, true)
				else
					fullscreenButton.Text = "❐"
				end
				if resizeHandle then resizeHandle.Visible = false end
			else
				TweenService:Create(mainFrame, tweenInfo, {
					Size = windowedSize,
					Position = windowedPos,
				}):Play()

				if shadowFrame then
					TweenService:Create(shadowFrame, tweenInfo, {
						Size = UDim2.new(windowedSize.X.Scale, windowedSize.X.Offset + 12, windowedSize.Y.Scale,
							windowedSize.Y.Offset + 12),
						Position = UDim2.new(windowedPos.X.Scale, windowedPos.X.Offset - 6, windowedPos.Y.Scale,
							windowedPos.Y.Offset - 6),
					}):Play()
				end

				if refs.updateFullscreenIcon then
					pcall(refs.updateFullscreenIcon, false)
				else
					fullscreenButton.Text = "⬜"
				end
				if resizeHandle then resizeHandle.Visible = true end
			end
		end)
	end

	------------------------------------------------
	-- 📐 RESIZE HANDLE DRAG
	------------------------------------------------
	if resizeHandle then
		local resizing = false
		local resizeDragStart, resizeStartSize
		local MIN_W, MIN_H = 400, 280

		resizeHandle.InputBegan:Connect(function(input)
			if isFullscreen then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				resizeDragStart = input.Position
				resizeStartSize = mainFrame.Size
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then resizing = false end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - resizeDragStart
				local newW = math.max(MIN_W, resizeStartSize.X.Offset + delta.X)
				local newH = math.max(MIN_H, resizeStartSize.Y.Offset + delta.Y)
				mainFrame.Size = UDim2.new(0, newW, 0, newH)
				if syncShadow then pcall(syncShadow) end
			end
		end)
	end

	------------------------------------------------
	-- 🔽 MINIMIZE / RESTORE CONTROLS
	------------------------------------------------
	local function minimizeUI(instant)
		if instant then
			mainFrame.Visible = false
			if shadowFrame then shadowFrame.Visible = false end
			restoreButton.Visible = true
		else
			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
			if shadowFrame then TweenService:Create(shadowFrame, tweenInfo, { BackgroundTransparency = 1 }):Play() end
			task.delay(0.2, function()
				mainFrame.Visible = false
				if shadowFrame then shadowFrame.Visible = false end
				mainFrame.BackgroundTransparency = 0.08
				if shadowFrame then shadowFrame.BackgroundTransparency = 0.45 end
				restoreButton.Visible = true
			end)
		end
	end
	refs.minimizeUI = minimizeUI

	minimizeButton.MouseButton1Click:Connect(function()
		minimizeUI(false)
	end)

	restoreButton.MouseButton1Click:Connect(function()
		restoreButton.Visible = false
		mainFrame.Visible = true
		if shadowFrame then shadowFrame.Visible = true end
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		mainFrame.BackgroundTransparency = 0.6
		TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 0.08 }):Play()
	end)

	------------------------------------------------
	-- ⌨️ KEYBIND TOGGLE
	------------------------------------------------
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local currentKeyText = (kbValue and kbValue.Text) or "RightShift"
		local successKey, currentKeyCode = pcall(function()
			return Enum.KeyCode[currentKeyText]
		end)
		if not successKey or not currentKeyCode then
			currentKeyCode = Enum.KeyCode.RightShift
		end

		if input.KeyCode == currentKeyCode then
			if restoreButton.Visible then
				restoreButton.Visible = false
				mainFrame.Visible = true
				if shadowFrame then shadowFrame.Visible = true end
			else
				mainFrame.Visible = not mainFrame.Visible
				if shadowFrame then shadowFrame.Visible = mainFrame.Visible end
			end
		end
	end)

	------------------------------------------------
	-- ✕ CLOSE BUTTON
	------------------------------------------------
	closeButton.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	task.spawn(function()
		local successThumbnail, thumbContent = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize
			.Size48x48)
		end)
		if successThumbnail then avatarLabel.Image = thumbContent end
	end)



	------------------------------------------------
	-- ⛏️ MINING CATEGORY SECTION (MAIN TAB)
	------------------------------------------------
	local mainFrameContent = refs.mainFrameContent or (refs.tabs and refs.tabs["Main"] and refs.tabs["Main"].Frame)
	local setMiningState = nil

	if mainFrameContent then
		local isExpanded = false

		local miningCard = Instance.new("Frame")
		miningCard.Size = UDim2.new(1, 0, 0, 36)
		miningCard.BackgroundColor3 = COLORS.glassCard
		miningCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		miningCard.BorderSizePixel = 0
		miningCard.ClipsDescendants = true
		miningCard.LayoutOrder = 1
		miningCard.Parent = mainFrameContent

		refs.applyGlass(miningCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})

		-- Expandable Header Click Button (Picture 1 & 2 style)
		local headerBtn = Instance.new("TextButton")
		headerBtn.Size = UDim2.new(1, 0, 0, 36)
		headerBtn.BackgroundTransparency = 1
		headerBtn.Text = ""
		headerBtn.Parent = miningCard

		local accentBar = Instance.new("Frame")
		accentBar.Size = UDim2.new(0, 3, 0, 18)
		accentBar.Position = UDim2.new(0, 12, 0, 9)
		accentBar.BackgroundColor3 = COLORS.accentCyan
		accentBar.BorderSizePixel = 0
		accentBar.Parent = headerBtn

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(0, 2)
		accentCorner.Parent = accentBar

		local miningTitle = Instance.new("TextLabel")
		miningTitle.Size = UDim2.new(1, -60, 1, 0)
		miningTitle.Position = UDim2.new(0, 24, 0, 0)
		miningTitle.BackgroundTransparency = 1
		miningTitle.Text = "Bypass Gamepass"
		miningTitle.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
		miningTitle.Font = Enum.Font.GothamBold
		miningTitle.TextSize = 13
		miningTitle.TextXAlignment = Enum.TextXAlignment.Left
		miningTitle.Parent = headerBtn

		local chevronLabel = Instance.new("TextLabel")
		chevronLabel.Size = UDim2.new(0, 24, 1, 0)
		chevronLabel.Position = UDim2.new(1, -30, 0, 0)
		chevronLabel.BackgroundTransparency = 1
		chevronLabel.Text = ">"
		chevronLabel.TextColor3 = COLORS.accentCyan
		chevronLabel.Font = Enum.Font.GothamBold
		chevronLabel.TextSize = 13
		chevronLabel.Parent = headerBtn

		-- Toggles Container inside Mining Card
		local toggleContainer = Instance.new("Frame")
		toggleContainer.Size = UDim2.new(1, -24, 0, 115)
		toggleContainer.Position = UDim2.new(0, 12, 0, 42)
		toggleContainer.BackgroundTransparency = 1
		toggleContainer.Parent = miningCard

		refs.applyListLayout(toggleContainer, 6)

		local function updateMainTabCanvas()
			if mainFrameContent:IsA("ScrollingFrame") then
				local layout = mainFrameContent:FindFirstChildOfClass("UIListLayout")
				if layout then
					mainFrameContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
				end
			end
		end

		headerBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			chevronLabel.Text = isExpanded and "v" or ">"
			local targetHeight = isExpanded and 165 or 36

			local tween = TweenService:Create(miningCard,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			})
			tween:Play()
			tween.Completed:Connect(updateMainTabCanvas)
			updateMainTabCanvas()
		end)

		-- Mining Persistent States
		local antiFallEnabled = false
		local instantMineEnabled = false
		local instantPickupEnabled = false

		-- 1. Anti-Fall Toggle
		local afRow, afTrack, afThumb = refs.createGlassToggle(toggleContainer, "Anti-Fall", 1)
		local updateAntiFallVisuals = function()
			if antiFallEnabled then
				TweenService:Create(afTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(afThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

		-- 2. Instant Mine Toggle
		local imRow, imTrack, imThumb = refs.createGlassToggle(toggleContainer, "Instant Mine", 2)
		local updateInstantMineVisuals = function()
			if instantMineEnabled then
				TweenService:Create(imTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(imThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(imTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(imThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

		-- 3. Instant Pickup Toggle
		local ipRow, ipTrack, ipThumb = refs.createGlassToggle(toggleContainer, "Instant Pickup", 3)
		local updateInstantPickupVisuals = function()
			if instantPickupEnabled then
				TweenService:Create(ipTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(ipThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(ipTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(ipThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

		updateAntiFallVisuals()
		updateInstantMineVisuals()
		updateInstantPickupVisuals()

		-- 🛡️ Anti-Fall Engine Logic
		local function disableRagdoll()
			if not antiFallEnabled then return end
			pcall(function()
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local rsPkg = ReplicatedStorage:FindFirstChild("RagdollSystemPackage")
				local rsMod = rsPkg and rsPkg:FindFirstChild("RagdollSystem")
				if rsMod then
					local RagdollSystem = require(rsMod)
					if RagdollSystem then
						local ragdoll = RagdollSystem:getLocalRagdoll()
						if ragdoll and ragdoll:isRagdolled() then
							pcall(function() ragdoll:deactivateRagdollPhysics() end)
							pcall(function() RagdollSystem.Remotes.DeactivateRagdoll:FireServer() end)
						end
					end
				end
			end)
		end

		task.spawn(function()
			while true do
				task.wait(0.15)
				if antiFallEnabled then
					disableRagdoll()
				end
			end
		end)

		afTrack.MouseButton1Click:Connect(function()
			antiFallEnabled = not antiFallEnabled
			updateAntiFallVisuals()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		-- ⛏️ Instant Mine Engine Logic
		local hookedMineFolders = {}
		local crystalLocations = {
			{ parent = "Things", child = "Crystals" },
			{ parent = nil,      child = "DroppedCrystals" },
			{ parent = nil,      child = "Crystals" }
		}

		local function updateMinePrompt(prompt)
			if not prompt or not prompt:IsA("ProximityPrompt") then return end
			local orig = prompt:GetAttribute("IMC_OrigHold")
			if typeof(orig) ~= "number" then
				prompt:SetAttribute("IMC_OrigHold", prompt.HoldDuration)
				orig = prompt.HoldDuration
			end
			if instantMineEnabled then
				prompt.HoldDuration = 0
			else
				prompt.HoldDuration = orig or 0.5
			end
		end

		local function updateMineFolder(folder)
			if not folder then return end
			for _, desc in ipairs(folder:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					updateMinePrompt(desc)
				end
			end
		end

		local function hookMineFolder(folder)
			if not folder or hookedMineFolders[folder] then
				if folder then updateMineFolder(folder) end
				return
			end
			hookedMineFolders[folder] = true
			updateMineFolder(folder)
			folder.DescendantAdded:Connect(function(desc)
				if desc:IsA("ProximityPrompt") then
					updateMinePrompt(desc)
				end
			end)
		end

		local function findAndHookMineFolders()
			local Workspace = game:GetService("Workspace")
			for _, loc in ipairs(crystalLocations) do
				local pInst = Workspace
				if loc.parent then
					pInst = Workspace:FindFirstChild(loc.parent)
				end
				if pInst then
					local f = pInst:FindFirstChild(loc.child)
					if f then hookMineFolder(f) end
				end
			end
		end

		local function applyInstantMineState()
			findAndHookMineFolders()
			for folder in pairs(hookedMineFolders) do
				if folder and folder.Parent then
					updateMineFolder(folder)
				end
			end
		end

		imTrack.MouseButton1Click:Connect(function()
			instantMineEnabled = not instantMineEnabled
			updateInstantMineVisuals()
			applyInstantMineState()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		-- 🤲 Instant Pickup Engine Logic
		local function isCrystalPickupPrompt(prompt)
			if not prompt or not prompt:IsA("ProximityPrompt") then return false end
			local objText = prompt.ObjectText or ""
			if objText == "Crystal" or string.find(string.lower(objText), "crystal", 1, true) then
				return true
			end
			local curr = prompt.Parent
			local Workspace = game:GetService("Workspace")
			while curr and curr ~= Workspace do
				if string.find(string.lower(curr.Name), "crystal", 1, true) then
					return true
				end
				curr = curr.Parent
			end
			return false
		end

		local function patchPickupPrompt(instance)
			if not instance or not instance:IsA("ProximityPrompt") or not isCrystalPickupPrompt(instance) then return end
			local orig = instance:GetAttribute("OriginalHoldDuration")
			if typeof(orig) ~= "number" then
				instance:SetAttribute("OriginalHoldDuration", instance.HoldDuration)
				orig = instance.HoldDuration
			end
			if instantPickupEnabled then
				instance.HoldDuration = 0
			else
				instance.HoldDuration = orig or 0.5
			end
		end

		local function updateAllPickupPrompts()
			local Workspace = game:GetService("Workspace")
			for _, desc in ipairs(Workspace:GetDescendants()) do
				patchPickupPrompt(desc)
			end
		end

		game:GetService("Workspace").DescendantAdded:Connect(function(desc)
			if desc:IsA("ProximityPrompt") then
				patchPickupPrompt(desc)
			end
		end)

		ipTrack.MouseButton1Click:Connect(function()
			instantPickupEnabled = not instantPickupEnabled
			updateInstantPickupVisuals()
			updateAllPickupPrompts()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		setMiningState = function(s)
			if not s then return end
			if s.antiFallEnabled ~= nil then
				antiFallEnabled = (s.antiFallEnabled == true)
				updateAntiFallVisuals()
			end
			if s.instantMineEnabled ~= nil then
				instantMineEnabled = (s.instantMineEnabled == true)
				updateInstantMineVisuals()
				applyInstantMineState()
			end
			if s.instantPickupEnabled ~= nil then
				instantPickupEnabled = (s.instantPickupEnabled == true)
				updateInstantPickupVisuals()
				updateAllPickupPrompts()
			end
		end

		_G.HipHubMining = {
			getState = function()
				return {
					antiFallEnabled = antiFallEnabled,
					instantMineEnabled = instantMineEnabled,
					instantPickupEnabled = instantPickupEnabled,
				}
			end,
			setState = setMiningState
		}

		------------------------------------------------
		-- 💰 AUTOMATION SELL CATEGORY SECTION (MAIN TAB)
		------------------------------------------------
		local function getShopCFrame()
			-- Exact shop coordinates from user screenshot
			return CFrame.new(-41.420551300048883, 29.296977996826172, 1066.813232421875)
		end

		local isSellExpanded = false
		local autoSellEnabled = false
		local isSelling = false
		local isBackpackFull = nil
		local tweenToTargetCFrame = nil

		------------------------------------------------
		-- 💰 AUTOMATION SELL CATEGORY SECTION
		------------------------------------------------
		do
			local sellCard = Instance.new("Frame")
		sellCard.Size = UDim2.new(1, 0, 0, 36)
		sellCard.BackgroundColor3 = COLORS.glassCard
		sellCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		sellCard.BorderSizePixel = 0
		sellCard.ClipsDescendants = true
		sellCard.LayoutOrder = 2
		sellCard.Parent = mainFrameContent

		refs.applyGlass(sellCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})

		-- Expandable Header Click Button
		local sellHeaderBtn = Instance.new("TextButton")
		sellHeaderBtn.Size = UDim2.new(1, 0, 0, 36)
		sellHeaderBtn.BackgroundTransparency = 0.999
		sellHeaderBtn.Text = ""
		sellHeaderBtn.ZIndex = 10
		sellHeaderBtn.Active = true
		sellHeaderBtn.Parent = sellCard

		local sellAccentBar = Instance.new("Frame")
		sellAccentBar.Size = UDim2.new(0, 3, 0, 18)
		sellAccentBar.Position = UDim2.new(0, 12, 0, 9)
		sellAccentBar.BackgroundColor3 = COLORS.accentCyan
		sellAccentBar.BorderSizePixel = 0
		sellAccentBar.Parent = sellHeaderBtn

		local sellAccentCorner = Instance.new("UICorner")
		sellAccentCorner.CornerRadius = UDim.new(0, 2)
		sellAccentCorner.Parent = sellAccentBar

		local sellTitle = Instance.new("TextLabel")
		sellTitle.Size = UDim2.new(1, -60, 1, 0)
		sellTitle.Position = UDim2.new(0, 24, 0, 0)
		sellTitle.BackgroundTransparency = 1
		sellTitle.Text = "Automation Sell"
		sellTitle.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
		sellTitle.Font = Enum.Font.GothamBold
		sellTitle.TextSize = 13
		sellTitle.TextXAlignment = Enum.TextXAlignment.Left
		sellTitle.Parent = sellHeaderBtn

		local sellChevronLabel = Instance.new("TextLabel")
		sellChevronLabel.Size = UDim2.new(0, 24, 1, 0)
		sellChevronLabel.Position = UDim2.new(1, -30, 0, 0)
		sellChevronLabel.BackgroundTransparency = 1
		sellChevronLabel.Text = ">"
		sellChevronLabel.TextColor3 = COLORS.accentCyan
		sellChevronLabel.Font = Enum.Font.GothamBold
		sellChevronLabel.TextSize = 13
		sellChevronLabel.Parent = sellHeaderBtn

		-- Content Container inside Automation Sell Card
		local sellContentContainer = Instance.new("Frame")
		sellContentContainer.Size = UDim2.new(1, -24, 0, 180)
		sellContentContainer.Position = UDim2.new(0, 12, 0, 42)
		sellContentContainer.BackgroundTransparency = 1
		sellContentContainer.Parent = sellCard

		refs.applyListLayout(sellContentContainer, 6)

		local function toggleSellSection()
			isSellExpanded = not isSellExpanded
			sellChevronLabel.Text = isSellExpanded and "v" or ">"
			local targetHeight = isSellExpanded and 225 or 36

			local tween = TweenService:Create(sellCard,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			})
			tween:Play()
			tween.Completed:Connect(updateMainTabCanvas)
			updateMainTabCanvas()
		end

		sellHeaderBtn.MouseButton1Click:Connect(toggleSellSection)

		-- Helper to get Shop / Sell location CFrame in Mine Mountain
		local function getShopCFrame()
			-- 1. Check for Shop / Sell NPC / Merchant / Base in workspace
			local shopObj = workspace:FindFirstChild("Shop") or workspace:FindFirstChild("Sell") or workspace:FindFirstChild("Merchant") or workspace:FindFirstChild("Base") or workspace:FindFirstChild("SpawnLocation")
			if not shopObj then
				local npcs = workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("Npcs")
				if npcs then
					shopObj = npcs:FindFirstChild("Sell") or npcs:FindFirstChild("Shop") or npcs:FindFirstChild("Merchant") or npcs:FindFirstChildWhichIsA("Model")
				end
			end

			if shopObj then
				if shopObj:IsA("BasePart") then
					return shopObj.CFrame + Vector3.new(0, 3, 0)
				elseif shopObj:IsA("Model") then
					local primary = shopObj.PrimaryPart or shopObj:FindFirstChildWhichIsA("BasePart", true)
					if primary then
						return primary.CFrame + Vector3.new(0, 3, 0)
					end
				end
			end

			-- 2. Check SpawnLocation anywhere in workspace
			for _, child in ipairs(workspace:GetChildren()) do
				if child:IsA("SpawnLocation") or string.find(string.lower(child.Name), "spawn", 1, true) then
					return child.CFrame + Vector3.new(0, 3, 0)
				end
			end

			-- 3. Fixed Shop CFrame fallback in Mine Mountain
			return CFrame.new(-41.4205513, 29.296978, 1066.81323)
		end

		-- Helper to check if tool matches sell rarity and size filters
		local function matchesSellFilter(tool)
			if not tool or not tool:IsA("Tool") then return false end

			-- 1. Check Rarity Filter
			local matchesRarity = false
			local hasAnyRarity = false
			if type(autoSellRarityFilters) == "table" then
				for r, isSel in pairs(autoSellRarityFilters) do
					if isSel == true then hasAnyRarity = true break end
				end
			end

			if not hasAnyRarity or autoSellRarityFilters["All"] == true then
				matchesRarity = true
			else
				local tName = string.lower(tool.Name)
				local attrStr = ""
				pcall(function()
					for aName, aVal in pairs(tool:GetAttributes()) do
						attrStr = attrStr .. " " .. string.lower(tostring(aName)) .. " " .. string.lower(tostring(aVal))
					end
				end)
				local text = tName .. " " .. attrStr
				local filterMap = {
					["common"] = { "_t1", "t1", "common", "tier1", "tier 1" },
					["uncommon"] = { "_t2", "t2", "uncommon", "tier2", "tier 2" },
					["rare"] = { "_t3", "t3", "rare", "tier3", "tier 3" },
					["epic"] = { "_t4", "t4", "epic", "tier4", "tier 4" },
					["legendary"] = { "_t5", "t5", "legendary", "tier5", "tier 5" },
					["mythical"] = { "_t6", "t6", "mythical", "mythic", "tier6", "tier 6" },
				}
				for selRarity, isSel in pairs(autoSellRarityFilters) do
					if isSel == true then
						local rLower = string.lower(tostring(selRarity))
						local kws = filterMap[rLower]
						if kws then
							for _, kw in ipairs(kws) do
								if string.find(text, kw, 1, true) then matchesRarity = true break end
							end
						end
						if string.find(text, rLower, 1, true) then matchesRarity = true end
						if matchesRarity then break end
					end
				end
			end

			-- 2. Check Size Filter
			local matchesSize = false
			local hasAnySize = false
			if type(autoSellSizeFilters) == "table" then
				for s, isSel in pairs(autoSellSizeFilters) do
					if isSel == true then hasAnySize = true break end
				end
			end

			if not hasAnySize or autoSellSizeFilters["All"] == true then
				matchesSize = true
			else
				local wKg = tool:GetAttribute("WeightKg") or tool:GetAttribute("Weight")
				local tName = string.lower(tool.Name)
				for selSize, isSel in pairs(autoSellSizeFilters) do
					if isSel == true then
						local sLower = string.lower(tostring(selSize))
						if string.find(tName, sLower, 1, true) then
							matchesSize = true
							break
						elseif sLower == "behemoth" and wKg and wKg >= 25000 then matchesSize = true break
						elseif sLower == "leviathan" and wKg and wKg >= 8000 and wKg < 25000 then matchesSize = true break
						elseif sLower == "titan" and wKg and wKg >= 3000 and wKg < 8000 then matchesSize = true break
						elseif sLower == "colossal" and wKg and wKg >= 1000 and wKg < 3000 then matchesSize = true break
						elseif sLower == "giant" and wKg and wKg >= 200 and wKg < 1000 then matchesSize = true break
						elseif sLower == "extra large" and wKg and wKg >= 90 and wKg < 200 then matchesSize = true break
						elseif sLower == "large" and wKg and wKg >= 30 and wKg < 90 then matchesSize = true break
						elseif sLower == "medium" and wKg and wKg >= 8 and wKg < 30 then matchesSize = true break
						elseif sLower == "small" and wKg and wKg < 8 then matchesSize = true break
						end
					end
				end
			end

			return matchesRarity and matchesSize
		end

		-- Sell Execution Logic (Tween to Shop, Fire Remotes & Prompts, Return via Direct Tween)
		local function executeSellAllTeleport()
			if isSelling then return end
			isSelling = true

			local myChar = player and player.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myHrp then
				isSelling = false
				return
			end

			local lastCFrame = myHrp.CFrame
			local shopCFrame = getShopCFrame()

			if shopCFrame then
				-- Attach hover flight during sell travel
				local flyHold = myHrp:FindFirstChild("HipHubFarmFly")
				if not flyHold then
					flyHold = Instance.new("BodyVelocity")
					flyHold.Name = "HipHubFarmFly"
					flyHold.MaxForce = Vector3.new(9e9, 9e9, 9e9)
					flyHold.Velocity = Vector3.zero
					flyHold.Parent = myHrp
				end

				-- Smooth travel to shop
				local distToShop = (myHrp.Position - shopCFrame.Position).Magnitude
				if distToShop > 5 then
					local duration = math.clamp(distToShop / 350, 0.15, 3.0)
					local tweenToShop = TweenService:Create(myHrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = shopCFrame })
					tweenToShop:Play()
					tweenToShop.Completed:Wait()
				end
				myHrp.CFrame = shopCFrame
				pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)
				task.wait(0.2)
			end

			local function triggerSellAllRemotes()
				pcall(function()
					local rems = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
						or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
						or game:GetService("ReplicatedStorage")
					if rems then
						local goHomeRem = rems:FindFirstChild("GoHome")
						if goHomeRem then pcall(function() goHomeRem:FireServer("sell") end) end

						local sellRem = rems:FindFirstChild("SellRequest") or rems:FindFirstChild("SellAll") or rems:FindFirstChild("Sell")
						if sellRem then
							pcall(function() sellRem:FireServer("all") end)
							pcall(function() sellRem:FireServer("All") end)
							pcall(function() sellRem:FireServer(true) end)
							pcall(function() sellRem:FireServer() end)
						end
					end

					-- Scan and fire sell for each individual tool in backpack/character
					local sellTools = {}
					local function scanCont(cont)
						if not cont then return end
						for _, child in ipairs(cont:GetChildren()) do
							if child:IsA("Tool") then
								table.insert(sellTools, child)
							end
						end
					end
					local p = player or game:GetService("Players").LocalPlayer
					if p then
						scanCont(p:FindFirstChildOfClass("Backpack") or p:FindFirstChild("Backpack"))
						scanCont(p.Character)
					end

					if rems then
						local sellRem = rems:FindFirstChild("SellRequest") or rems:FindFirstChild("SellItem") or rems:FindFirstChild("Sell")
						for _, tool in ipairs(sellTools) do
							if sellRem then
								pcall(function() sellRem:FireServer(tool) end)
							end
						end
					end
				end)

				-- Fire any nearby ProximityPrompts at Shop NPC
				pcall(function()
					if myHrp then
						for _, desc in ipairs(workspace:GetDescendants()) do
							if desc:IsA("ProximityPrompt") and desc.Parent then
								local part = desc.Parent:IsA("BasePart") and desc.Parent or desc.Parent:FindFirstChildWhichIsA("BasePart", true)
								if part and (part.Position - myHrp.Position).Magnitude <= 30 then
									desc.HoldDuration = 0
									if fireproximityprompt then fireproximityprompt(desc) end
								end
							end
						end
					end
				end)
			end

			-- Fire sell triggers repeatedly for 1.2 seconds to ensure 100% processing
			for _ = 1, 4 do
				triggerSellAllRemotes()
				task.wait(0.25)
			end

			-- ALWAYS GUARANTEE RETURN TO LAST MINING POSITION
			if myHrp and myHrp.Parent and lastCFrame then
				local distBack = (myHrp.Position - lastCFrame.Position).Magnitude
				if distBack > 5 then
					local durationBack = math.clamp(distBack / 350, 0.15, 3.0)
					local tweenBack = TweenService:Create(myHrp, TweenInfo.new(durationBack, Enum.EasingStyle.Linear), { CFrame = lastCFrame })
					tweenBack:Play()
					tweenBack.Completed:Wait()
				end
				myHrp.CFrame = lastCFrame
				pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)
			end

			isSelling = false
		end

		-- 1. Action Button: Sell All Items
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(1, 0, 0, 32)
		actionBtn.BackgroundColor3 = Color3.fromRGB(24, 30, 50)
		actionBtn.BackgroundTransparency = 0.2
		actionBtn.Text = "⚡ Sell All Items (Teleport & Return)"
		actionBtn.TextColor3 = COLORS.accentCyan
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 11
		actionBtn.LayoutOrder = 1
		actionBtn.Parent = sellContentContainer

		local actionCorner = Instance.new("UICorner")
		actionCorner.CornerRadius = refs.CORNER.small
		actionCorner.Parent = actionBtn

		local actionStroke = Instance.new("UIStroke")
		actionStroke.Color = COLORS.borderGlass
		actionStroke.Thickness = 1
		actionStroke.Transparency = 0.5
		actionStroke.Parent = actionBtn

		actionBtn.MouseButton1Click:Connect(function()
			task.spawn(executeSellAllTeleport)
		end)

		-- 2. Toggle: Auto Sell All
		local autoSellRarityFilters = { ["All"] = true }
		local autoSellSizeFilters = { ["All"] = true }

		local asRow, asTrack, asThumb = refs.createGlassToggle(sellContentContainer, "Auto Sell All", 2)
		local updateAutoSellVisuals = function()
			if autoSellEnabled then
				TweenService:Create(asTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(asThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(asTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(asThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoSellVisuals()

		asTrack.MouseButton1Click:Connect(function()
			autoSellEnabled = not autoSellEnabled
			updateAutoSellVisuals()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		-- 3. Sell Rarity Filter Dropdown
		local asRarCard, asRarDropBtn, asRarDropLabel, asRarMenuFrame, asRarSearch, asRarScroll = refs.createGlassDropdown(
			sellContentContainer, "Sell Rarity Filter", "All", 3
		)
		asRarCard.Size = UDim2.new(1, 0, 0, 32)

		local function getSelectedSellRarityLabelText()
			if autoSellRarityFilters["All"] or next(autoSellRarityFilters) == nil then
				return "All"
			end
			local list = {}
			for _, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }) do
				if autoSellRarityFilters[r] then table.insert(list, r) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local asRarities = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }
		refs.registerDropdownMenu(asRarDropBtn, asRarMenuFrame)
		local asRarityBinder = refs.bindDropdown(
			asRarDropBtn, asRarMenuFrame, asRarSearch, asRarScroll, asRarities,
			function(opt)
				return autoSellRarityFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					autoSellRarityFilters = { ["All"] = true }
				else
					autoSellRarityFilters["All"] = nil
					autoSellRarityFilters[opt] = not autoSellRarityFilters[opt]
					local hasAny = false
					for _, v in pairs(autoSellRarityFilters) do
						if v then hasAny = true break end
					end
					if not hasAny then autoSellRarityFilters["All"] = true end
				end
			end,
			function()
				asRarDropLabel.Text = getSelectedSellRarityLabelText()
			end
		)

		local function updateAsRarityVisuals()
			asRarDropLabel.Text = getSelectedSellRarityLabelText()
			asRarityBinder.updateOptionVisuals()
		end

		-- 4. Sell Size Filter Dropdown
		local asSzCard, asSzDropBtn, asSzDropLabel, asSzMenuFrame, asSzSearch, asSzScroll = refs.createGlassDropdown(
			sellContentContainer, "Sell Size Filter", "All", 4
		)
		asSzCard.Size = UDim2.new(1, 0, 0, 32)

		local function getSelectedSellSizeLabelText()
			if autoSellSizeFilters["All"] or next(autoSellSizeFilters) == nil then
				return "All"
			end
			local list = {}
			for _, s in ipairs({ "Small", "Medium", "Large", "Extra Large", "Giant", "Colossal", "Titan", "Leviathan", "Behemoth" }) do
				if autoSellSizeFilters[s] then table.insert(list, s) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local asSizes = { "All", "Small", "Medium", "Large", "Extra Large", "Giant", "Colossal", "Titan", "Leviathan", "Behemoth" }
		refs.registerDropdownMenu(asSzDropBtn, asSzMenuFrame)
		local asSizeBinder = refs.bindDropdown(
			asSzDropBtn, asSzMenuFrame, asSzSearch, asSzScroll, asSizes,
			function(opt)
				return autoSellSizeFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					autoSellSizeFilters = { ["All"] = true }
				else
					autoSellSizeFilters["All"] = nil
					autoSellSizeFilters[opt] = not autoSellSizeFilters[opt]
					local hasAny = false
					for _, v in pairs(autoSellSizeFilters) do
						if v then hasAny = true break end
					end
					if not hasAny then autoSellSizeFilters["All"] = true end
				end
			end,
			function()
				asSzDropLabel.Text = getSelectedSellSizeLabelText()
			end
		)

		local function updateAsSizeVisuals()
			asSzDropLabel.Text = getSelectedSellSizeLabelText()
			asSizeBinder.updateOptionVisuals()
		end

		-- Expand Automation Sell card container height to accommodate new filters
		sellContentContainer.Size = UDim2.new(1, -24, 0, 180)

		-- Auto Sell Loop
		task.spawn(function()
			while true do
				task.wait(15)
				if autoSellEnabled then
					pcall(executeSellAllTeleport)
				end
			end
		end)

			_G.HipHubAutomationSell = {
				getState = function()
					return {
						autoSellEnabled = autoSellEnabled,
						autoSellRarityFilters = autoSellRarityFilters,
						autoSellSizeFilters = autoSellSizeFilters,
					}
				end,
				setState = function(s)
					if not s then return end
					if s.autoSellEnabled ~= nil then
						autoSellEnabled = (s.autoSellEnabled == true)
						updateAutoSellVisuals()
					end
					if s.autoSellRarityFilters ~= nil then
						if type(s.autoSellRarityFilters) == "table" then
							autoSellRarityFilters = s.autoSellRarityFilters
						elseif type(s.autoSellRarityFilters) == "string" then
							autoSellRarityFilters = { [s.autoSellRarityFilters] = true }
						end
						updateAsRarityVisuals()
					end
					if s.autoSellSizeFilters ~= nil then
						if type(s.autoSellSizeFilters) == "table" then
							autoSellSizeFilters = s.autoSellSizeFilters
						elseif type(s.autoSellSizeFilters) == "string" then
							autoSellSizeFilters = { [s.autoSellSizeFilters] = true }
						end
						updateAsSizeVisuals()
					end
				end
			}
		end

		------------------------------------------------
		-- ⭐️ AUTOMATION FAVORITE CATEGORY SECTION
		------------------------------------------------
		do
			local isFavCategoryExpanded = false
		local autoFavoriteEnabled = false
		local autoFavRarityFilters = { ["All"] = true }
		local autoFavSizeFilters = { ["All"] = true }

		local favCategoryCard = Instance.new("Frame")
		favCategoryCard.Size = UDim2.new(1, 0, 0, 36)
		favCategoryCard.BackgroundColor3 = COLORS.glassCard
		favCategoryCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		favCategoryCard.BorderSizePixel = 0
		favCategoryCard.ClipsDescendants = true
		favCategoryCard.LayoutOrder = 3
		favCategoryCard.Parent = mainFrameContent

		refs.applyGlass(favCategoryCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})

		-- Expandable Header Click Button
		local favHeaderBtn = Instance.new("TextButton")
		favHeaderBtn.Size = UDim2.new(1, 0, 0, 36)
		favHeaderBtn.BackgroundTransparency = 1
		favHeaderBtn.Text = ""
		favHeaderBtn.Parent = favCategoryCard

		local favAccentBar = Instance.new("Frame")
		favAccentBar.Size = UDim2.new(0, 3, 0, 18)
		favAccentBar.Position = UDim2.new(0, 12, 0, 9)
		favAccentBar.BackgroundColor3 = COLORS.accentCyan
		favAccentBar.BorderSizePixel = 0
		favAccentBar.Parent = favHeaderBtn

		local favAccentCorner = Instance.new("UICorner")
		favAccentCorner.CornerRadius = UDim.new(0, 2)
		favAccentCorner.Parent = favAccentBar

		local favTitle = Instance.new("TextLabel")
		favTitle.Size = UDim2.new(1, -60, 1, 0)
		favTitle.Position = UDim2.new(0, 24, 0, 0)
		favTitle.BackgroundTransparency = 1
		favTitle.Text = "Automation Favorite"
		favTitle.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
		favTitle.Font = Enum.Font.GothamBold
		favTitle.TextSize = 13
		favTitle.TextXAlignment = Enum.TextXAlignment.Left
		favTitle.Parent = favHeaderBtn

		local favChevronLabel = Instance.new("TextLabel")
		favChevronLabel.Size = UDim2.new(0, 24, 1, 0)
		favChevronLabel.Position = UDim2.new(1, -30, 0, 0)
		favChevronLabel.BackgroundTransparency = 1
		favChevronLabel.Text = ">"
		favChevronLabel.TextColor3 = COLORS.accentCyan
		favChevronLabel.Font = Enum.Font.GothamBold
		favChevronLabel.TextSize = 13
		favChevronLabel.Parent = favHeaderBtn

		-- Content Container inside Automation Favorite Card
		local favContentContainer = Instance.new("Frame")
		favContentContainer.Size = UDim2.new(1, -24, 0, 230)
		favContentContainer.Position = UDim2.new(0, 12, 0, 42)
		favContentContainer.BackgroundTransparency = 1
		favContentContainer.Parent = favCategoryCard

		refs.applyListLayout(favContentContainer, 6)

		favHeaderBtn.MouseButton1Click:Connect(function()
			isFavCategoryExpanded = not isFavCategoryExpanded
			favChevronLabel.Text = isFavCategoryExpanded and "v" or ">"
			local targetHeight = isFavCategoryExpanded and 275 or 36
			local tween = TweenService:Create(favCategoryCard,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			})
			tween:Play()
			tween.Completed:Connect(updateMainTabCanvas)
			updateMainTabCanvas()
		end)

		-- 1. Toggle: Auto Favorite Crystals
		local afRow, afTrack, afThumb = refs.createGlassToggle(favContentContainer, "Auto Favorite Crystals", 1)
		local updateAutoFavVisuals = function()
			if autoFavoriteEnabled then
				TweenService:Create(afTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(afThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoFavVisuals()

		afTrack.MouseButton1Click:Connect(function()
			autoFavoriteEnabled = not autoFavoriteEnabled
			updateAutoFavVisuals()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		-- 2. Favorite Rarity Filter Dropdown
		local favRarCard, favRarDropBtn, favRarDropLabel, favRarMenuFrame, favRarSearch, favRarScroll = refs.createGlassDropdown(
			favContentContainer, "Favorite Rarity Filter", "All", 2
		)
		favRarCard.Size = UDim2.new(1, 0, 0, 32)

		local function getSelectedFavRarityLabelText()
			if autoFavRarityFilters["All"] or next(autoFavRarityFilters) == nil then
				return "All"
			end
			local list = {}
			for _, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }) do
				if autoFavRarityFilters[r] then table.insert(list, r) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local favRarities = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }
		refs.registerDropdownMenu(favRarDropBtn, favRarMenuFrame)
		local favRarityBinder = refs.bindDropdown(
			favRarDropBtn, favRarMenuFrame, favRarSearch, favRarScroll, favRarities,
			function(opt)
				return autoFavRarityFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					autoFavRarityFilters = { ["All"] = true }
				else
					autoFavRarityFilters["All"] = nil
					autoFavRarityFilters[opt] = not autoFavRarityFilters[opt]
					local hasAny = false
					for _, v in pairs(autoFavRarityFilters) do
						if v then hasAny = true break end
					end
					if not hasAny then autoFavRarityFilters["All"] = true end
				end
			end,
			function()
				favRarDropLabel.Text = getSelectedFavRarityLabelText()
			end
		)

		local function updateFavRarityVisuals()
			favRarDropLabel.Text = getSelectedFavRarityLabelText()
			favRarityBinder.updateOptionVisuals()
		end

		-- 3. Favorite Size Filter Dropdown
		local favSzCard, favSzDropBtn, favSzDropLabel, favSzMenuFrame, favSzSearch, favSzScroll = refs.createGlassDropdown(
			favContentContainer, "Favorite Size Filter", "All", 3
		)
		favSzCard.Size = UDim2.new(1, 0, 0, 32)

		local function getSelectedFavSizeLabelText()
			if autoFavSizeFilters["All"] or next(autoFavSizeFilters) == nil then
				return "All"
			end
			local list = {}
			for _, s in ipairs({ "Small", "Medium", "Large", "Extra Large", "Giant", "Colossal", "Titan", "Leviathan", "Behemoth" }) do
				if autoFavSizeFilters[s] then table.insert(list, s) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local favSizes = { "All", "Small", "Medium", "Large", "Extra Large", "Giant", "Colossal", "Titan", "Leviathan", "Behemoth" }
		refs.registerDropdownMenu(favSzDropBtn, favSzMenuFrame)
		local favSizeBinder = refs.bindDropdown(
			favSzDropBtn, favSzMenuFrame, favSzSearch, favSzScroll, favSizes,
			function(opt)
				return autoFavSizeFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					autoFavSizeFilters = { ["All"] = true }
				else
					autoFavSizeFilters["All"] = nil
					autoFavSizeFilters[opt] = not autoFavSizeFilters[opt]
					local hasAny = false
					for _, v in pairs(autoFavSizeFilters) do
						if v then hasAny = true break end
					end
					if not hasAny then autoFavSizeFilters["All"] = true end
				end
			end,
			function()
				favSzDropLabel.Text = getSelectedFavSizeLabelText()
			end
		)

		local function updateFavSizeVisuals()
			favSzDropLabel.Text = getSelectedFavSizeLabelText()
			favSizeBinder.updateOptionVisuals()
		end

		-- Action Buttons Row Container
		local favBtnsRow = Instance.new("Frame")
		favBtnsRow.Size = UDim2.new(1, 0, 0, 32)
		favBtnsRow.BackgroundTransparency = 1
		favBtnsRow.LayoutOrder = 4
		favBtnsRow.Parent = favContentContainer

		local favActionBtn = Instance.new("TextButton")
		favActionBtn.Size = UDim2.new(0.485, 0, 1, 0)
		favActionBtn.Position = UDim2.new(0, 0, 0, 0)
		favActionBtn.BackgroundColor3 = COLORS.accentCyan
		favActionBtn.BackgroundTransparency = 0.15
		favActionBtn.Text = "★ Favorite Matching"
		favActionBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
		favActionBtn.Font = Enum.Font.GothamBold
		favActionBtn.TextSize = 10
		favActionBtn.Parent = favBtnsRow

		local favActionCorner = Instance.new("UICorner")
		favActionCorner.CornerRadius = refs.CORNER.small
		favActionCorner.Parent = favActionBtn

		local unfavActionBtn = Instance.new("TextButton")
		unfavActionBtn.Size = UDim2.new(0.485, 0, 1, 0)
		unfavActionBtn.Position = UDim2.new(0.515, 0, 0, 0)
		unfavActionBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
		unfavActionBtn.BackgroundTransparency = 0.15
		unfavActionBtn.Text = "☆ Unfavorite Matching"
		unfavActionBtn.TextColor3 = COLORS.textWhite
		unfavActionBtn.Font = Enum.Font.GothamBold
		unfavActionBtn.TextSize = 10
		unfavActionBtn.Parent = favBtnsRow

		local unfavActionCorner = Instance.new("UICorner")
		unfavActionCorner.CornerRadius = refs.CORNER.small
		unfavActionCorner.Parent = unfavActionBtn

		-- Core Favorite / Unfavorite Remote Execution Logic
		local function executeFavoriteCrystals(isFavState)
			local p = player or game:GetService("Players").LocalPlayer
			if not p then return end

			local rems = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
			local favRem = rems and rems:FindFirstChild("ToggleFavorite")
			if not favRem then return end

			local function matchesFavFilters(tool)
				if not tool or not tool:IsA("Tool") then return false end

				-- Check Rarity
				local matchesR = false
				if autoFavRarityFilters["All"] or next(autoFavRarityFilters) == nil then
					matchesR = true
				else
					local tName = string.lower(tool.Name)
					local attrStr = ""
					pcall(function()
						for aName, aVal in pairs(tool:GetAttributes()) do
							attrStr = attrStr .. " " .. string.lower(tostring(aName)) .. " " .. string.lower(tostring(aVal))
						end
					end)
					local text = tName .. " " .. attrStr

					local filterMap = {
						["common"] = { "_t1", "t1", "common", "tier1", "tier 1" },
						["uncommon"] = { "_t2", "t2", "uncommon", "tier2", "tier 2" },
						["rare"] = { "_t3", "t3", "rare", "tier3", "tier 3" },
						["epic"] = { "_t4", "t4", "epic", "tier4", "tier 4" },
						["legendary"] = { "_t5", "t5", "legendary", "tier5", "tier 5" },
						["mythical"] = { "_t6", "t6", "mythical", "mythic", "tier6", "tier 6" },
						["mythic"] = { "_t6", "t6", "mythical", "mythic", "tier6", "tier 6" },
					}

					for selRarity, isSel in pairs(autoFavRarityFilters) do
						if isSel == true then
							local rLower = string.lower(tostring(selRarity))
							local kws = filterMap[rLower]
							if kws then
								for _, kw in ipairs(kws) do
									if string.find(text, kw, 1, true) then matchesR = true break end
								end
							end
							if not matchesR and string.find(text, rLower, 1, true) then matchesR = true end
							if matchesR then break end
						end
					end
				end

				-- Check Size
				local matchesS = false
				if autoFavSizeFilters["All"] or next(autoFavSizeFilters) == nil then
					matchesS = true
				else
					local wKg = tool:GetAttribute("WeightKg") or tool:GetAttribute("Weight")
					local tName = string.lower(tool.Name)
					local attrStr = ""
					pcall(function()
						for aName, aVal in pairs(tool:GetAttributes()) do
							attrStr = attrStr .. " " .. string.lower(tostring(aName)) .. " " .. string.lower(tostring(aVal))
						end
					end)
					local text = tName .. " " .. attrStr

					for selSize, isSel in pairs(autoFavSizeFilters) do
						if isSel == true then
							local sLower = string.lower(tostring(selSize))
							local matched = false

							if string.find(text, sLower, 1, true) then
								matched = true
							elseif sLower == "behemoth" and (wKg and wKg >= 25000) then matched = true
							elseif sLower == "leviathan" and (wKg and wKg >= 8000 and wKg < 25000) then matched = true
							elseif sLower == "titan" and (wKg and wKg >= 3000 and wKg < 8000) then matched = true
							elseif sLower == "colossal" and (wKg and wKg >= 1000 and wKg < 3000) then matched = true
							elseif sLower == "giant" and (wKg and wKg >= 200 and wKg < 1000) then matched = true
							elseif (sLower == "extra large" or sLower == "xl") and (wKg and wKg >= 90 and wKg < 200) then matched = true
							elseif (sLower == "large" or sLower == "l") and (wKg and wKg >= 30 and wKg < 90) then matched = true
							elseif (sLower == "medium" or sLower == "m") and (wKg and wKg >= 8 and wKg < 30) then matched = true
							elseif (sLower == "small" or sLower == "s") and (wKg and wKg < 8) then matched = true
							end

							if matched then matchesS = true break end
						end
					end
				end

				return matchesR and matchesS
			end

			local function scanAndToggle(container)
				if not container then return end
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") then
						local hasTier = child:GetAttribute("Tier") ~= nil
						local wKg = child:GetAttribute("WeightKg")
						local isCrystal = hasTier or wKg ~= nil or string.find(string.lower(child.Name), "crystal", 1, true) or string.find(string.lower(child.Name), "kg", 1, true) or string.find(string.lower(child.Name), "[m]", 1, true)
						if isCrystal and matchesFavFilters(child) then
							pcall(function()
								favRem:FireServer(child, isFavState)
							end)
							task.wait(0.05)
						end
					end
				end
			end

			scanAndToggle(p:FindFirstChildOfClass("Backpack") or p:FindFirstChild("Backpack"))
			if p.Character then scanAndToggle(p.Character) end
		end

		favActionBtn.MouseButton1Click:Connect(function()
			pcall(executeFavoriteCrystals, true)
		end)

		unfavActionBtn.MouseButton1Click:Connect(function()
			pcall(executeFavoriteCrystals, false)
		end)

		-- Auto Favorite Loop
		task.spawn(function()
			while true do
				task.wait(3.0)
				if autoFavoriteEnabled then
					pcall(executeFavoriteCrystals, true)
				end
			end
		end)

			_G.HipHubAutomationFavorite = {
				getState = function()
					return {
						autoFavoriteEnabled = autoFavoriteEnabled,
						autoFavRarityFilters = autoFavRarityFilters,
						autoFavSizeFilters = autoFavSizeFilters,
					}
				end,
				setState = function(s)
					if not s then return end
					if s.autoFavoriteEnabled ~= nil then
						autoFavoriteEnabled = (s.autoFavoriteEnabled == true)
						updateAutoFavVisuals()
					end
					if s.autoFavRarityFilters ~= nil then
						if type(s.autoFavRarityFilters) == "table" then
							autoFavRarityFilters = s.autoFavRarityFilters
						elseif type(s.autoFavRarityFilters) == "string" then
							autoFavRarityFilters = { [s.autoFavRarityFilters] = true }
						end
						updateFavRarityVisuals()
					end
					if s.autoFavSizeFilters ~= nil then
						if type(s.autoFavSizeFilters) == "table" then
							autoFavSizeFilters = s.autoFavSizeFilters
						elseif type(s.autoFavSizeFilters) == "string" then
							autoFavSizeFilters = { [s.autoFavSizeFilters] = true }
						end
						updateFavSizeVisuals()
					end
				end
			}
		end

		------------------------------------------------
		-- ⛏️ AUTOMATION MINING CATEGORY SECTION (MAIN TAB)
		------------------------------------------------
		do
			local isAutoMineCategoryExpanded = false
		local autoFarmCrystalsEnabled = false
		local autoFarmNoclipEnabled = false
		local autoFarmRarityFilter = "All"
		local autoFarmSizeFilter = "All"

		local autoMineCategoryCard = Instance.new("Frame")
		autoMineCategoryCard.Size = UDim2.new(1, 0, 0, 36)
		autoMineCategoryCard.BackgroundColor3 = COLORS.glassCard
		autoMineCategoryCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		autoMineCategoryCard.BorderSizePixel = 0
		autoMineCategoryCard.ClipsDescendants = true
		autoMineCategoryCard.LayoutOrder = 3
		autoMineCategoryCard.Parent = mainFrameContent

		refs.applyGlass(autoMineCategoryCard, {
			corner = refs.CORNER.medium,
			stroke = true,
			strokeColor = COLORS.borderGlass,
			strokeThickness = 1,
			strokeTransparency = 0.7
		})

		-- Expandable Header Click Button
		local amHeaderBtn = Instance.new("TextButton")
		amHeaderBtn.Size = UDim2.new(1, 0, 0, 36)
		amHeaderBtn.BackgroundTransparency = 0.999
		amHeaderBtn.Text = ""
		amHeaderBtn.ZIndex = 10
		amHeaderBtn.Active = true
		amHeaderBtn.Parent = autoMineCategoryCard

		local amAccentBar = Instance.new("Frame")
		amAccentBar.Size = UDim2.new(0, 3, 0, 18)
		amAccentBar.Position = UDim2.new(0, 12, 0, 9)
		amAccentBar.BackgroundColor3 = COLORS.accentCyan
		amAccentBar.BorderSizePixel = 0
		amAccentBar.Parent = amHeaderBtn

		local amAccentCorner = Instance.new("UICorner")
		amAccentCorner.CornerRadius = UDim.new(0, 2)
		amAccentCorner.Parent = amAccentBar

		local amTitle = Instance.new("TextLabel")
		amTitle.Size = UDim2.new(1, -60, 1, 0)
		amTitle.Position = UDim2.new(0, 24, 0, 0)
		amTitle.BackgroundTransparency = 1
		amTitle.Text = "Automation Mining"
		amTitle.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
		amTitle.Font = Enum.Font.GothamBold
		amTitle.TextSize = 13
		amTitle.TextXAlignment = Enum.TextXAlignment.Left
		amTitle.Parent = amHeaderBtn

		local amChevronLabel = Instance.new("TextLabel")
		amChevronLabel.Size = UDim2.new(0, 24, 1, 0)
		amChevronLabel.Position = UDim2.new(1, -30, 0, 0)
		amChevronLabel.BackgroundTransparency = 1
		amChevronLabel.Text = ">"
		amChevronLabel.TextColor3 = COLORS.accentCyan
		amChevronLabel.Font = Enum.Font.GothamBold
		amChevronLabel.TextSize = 13
		amChevronLabel.Parent = amHeaderBtn

		-- Content Container inside Automation Mining Card
		local amContentContainer = Instance.new("Frame")
		amContentContainer.Size = UDim2.new(1, -24, 0, 230)
		amContentContainer.Position = UDim2.new(0, 12, 0, 42)
		amContentContainer.BackgroundTransparency = 1
		amContentContainer.Parent = autoMineCategoryCard

		refs.applyListLayout(amContentContainer, 6)

		local lastAmClick = 0
		local function toggleAmSection()
			if os.clock() - lastAmClick < 0.2 then return end
			lastAmClick = os.clock()
			isAutoMineCategoryExpanded = not isAutoMineCategoryExpanded
			amChevronLabel.Text = isAutoMineCategoryExpanded and "v" or ">"
			local targetHeight = isAutoMineCategoryExpanded and 270 or 36
			local tween = TweenService:Create(autoMineCategoryCard,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			})
			tween:Play()
			tween.Completed:Connect(updateMainTabCanvas)
			updateMainTabCanvas()
		end

		amHeaderBtn.MouseButton1Click:Connect(toggleAmSection)
		amHeaderBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				toggleAmSection()
			end
		end)

		-- 1. Auto Farm Crystals Toggle
		local afcRow, afcTrack, afcThumb = refs.createGlassToggle(amContentContainer, "Auto Farm Crystals", 1)
		local updateAutoFarmVisuals = function()
			if autoFarmCrystalsEnabled then
				TweenService:Create(afcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(afcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoFarmVisuals()

		-- 2. Auto Mine Runes Toggle
		local autoFarmRunesEnabled = false
		local afrRow, afrTrack, afrThumb = refs.createGlassToggle(amContentContainer, "Auto Mine Runes", 2)
		local updateAutoMineRunesVisuals = function()
			if autoFarmRunesEnabled then
				TweenService:Create(afrTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(afrThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afrTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afrThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoMineRunesVisuals()

		afrTrack.MouseButton1Click:Connect(function()
			autoFarmRunesEnabled = not autoFarmRunesEnabled
			updateAutoMineRunesVisuals()
			if updateAutomationNoclipEngine then updateAutomationNoclipEngine() end
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		-- 3. Auto Farm Noclip Toggle
		local afnRow, afnTrack, afnThumb = refs.createGlassToggle(amContentContainer, "Auto Farm Noclip", 3)
		local updateAutoFarmNoclipVisuals = function()
			if autoFarmNoclipEnabled then
				TweenService:Create(afnTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(afnThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afnTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afnThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoFarmNoclipVisuals()

		-- 4. Auto Sell When Full Toggle
		local autoSellOnFullEnabled = false
		local asfRow, asfTrack, asfThumb = refs.createGlassToggle(amContentContainer, "Auto Sell When Full", 4)
		local updateAutoSellFullVisuals = function()
			if autoSellOnFullEnabled then
				TweenService:Create(asfTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(asfThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(asfTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(asfThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
					{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoSellFullVisuals()

		asfTrack.MouseButton1Click:Connect(function()
			autoSellOnFullEnabled = not autoSellOnFullEnabled
			updateAutoSellFullVisuals()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		-- 5. Target Rarity Filter Card inside Automation Mining
		local amRarCard, amRarDropBtn, amRarDropLabel, amRarMenuFrame, amRarSearch, amRarScroll = refs
		.createGlassDropdown(
			amContentContainer, "Target Rarity", "All", 5
		)
		amRarCard.Size = UDim2.new(1, 0, 0, 32)

		local autoFarmRarityFilters = { ["All"] = true }
		local autoFarmSizeFilters = { ["All"] = true }
		local autoFarmMinValueMillions = 0

		local function getSelectedRarityLabelText()
			if autoFarmRarityFilters["All"] or next(autoFarmRarityFilters) == nil then
				return "All"
			end
			local list = {}
			for _, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }) do
				if autoFarmRarityFilters[r] then table.insert(list, r) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local function getSelectedSizeLabelText()
			if autoFarmSizeFilters["All"] or next(autoFarmSizeFilters) == nil then
				return "All"
			end
			local list = {}
			for _, s in ipairs({ "Small", "Medium", "Large", "Extra Large", "Giant", "Colossal", "Titan", "Leviathan", "Behemoth" }) do
				if autoFarmSizeFilters[s] then table.insert(list, s) end
			end
			if #list == 0 then return "All" end
			if #list == 1 then return list[1] end
			if #list == 2 then return list[1] .. ", " .. list[2] end
			return tostring(#list) .. " Selected"
		end

		local amRarities = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

		refs.registerDropdownMenu(amRarDropBtn, amRarMenuFrame)
		local amRarityBinder = refs.bindDropdown(
			amRarDropBtn, amRarMenuFrame, amRarSearch, amRarScroll, amRarities,
			function(opt)
				return autoFarmRarityFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					autoFarmRarityFilters = { ["All"] = true }
				else
					autoFarmRarityFilters["All"] = nil
					autoFarmRarityFilters[opt] = not autoFarmRarityFilters[opt]
					local hasAny = false
					for _, v in pairs(autoFarmRarityFilters) do
						if v then
							hasAny = true
							break
						end
					end
					if not hasAny then
						autoFarmRarityFilters["All"] = true
					end
				end
			end,
			function()
				amRarDropLabel.Text = getSelectedRarityLabelText()
			end
		)

		local function updateAmRarityVisuals()
			amRarDropLabel.Text = getSelectedRarityLabelText()
			amRarityBinder.updateOptionVisuals()
		end

		-- 6. Target Size Filter Card inside Automation Mining
		local amSzCard, amSzDropBtn, amSzDropLabel, amSzMenuFrame, amSzSearch, amSzScroll = refs.createGlassDropdown(
			amContentContainer, "Target Size", "All", 6
		)
		amSzCard.Size = UDim2.new(1, 0, 0, 32)

		local amSizes = { "All", "Small", "Medium", "Large", "Extra Large", "Giant", "Colossal", "Titan", "Leviathan", "Behemoth" }

		refs.registerDropdownMenu(amSzDropBtn, amSzMenuFrame)
		local amSizeBinder = refs.bindDropdown(
			amSzDropBtn, amSzMenuFrame, amSzSearch, amSzScroll, amSizes,
			function(opt)
				return autoFarmSizeFilters[opt] == true
			end,
			function(opt)
				if opt == "All" then
					autoFarmSizeFilters = { ["All"] = true }
				else
					autoFarmSizeFilters["All"] = nil
					autoFarmSizeFilters[opt] = not autoFarmSizeFilters[opt]
					local hasAny = false
					for _, v in pairs(autoFarmSizeFilters) do
						if v then
							hasAny = true
							break
						end
					end
					if not hasAny then
						autoFarmSizeFilters["All"] = true
					end
				end
			end,
			function()
				amSzDropLabel.Text = getSelectedSizeLabelText()
			end
		)

		local function updateAmSizeVisuals()
			amSzDropLabel.Text = getSelectedSizeLabelText()
			amSizeBinder.updateOptionVisuals()
		end

		-- Dedicated Noclip Engine for Automation Mining
		local amNoclipConnection = nil
		local function updateAutomationNoclipEngine()
			if autoFarmNoclipEnabled then
				if not amNoclipConnection then
					amNoclipConnection = RunService.Stepped:Connect(function()
						local char = player and player.Character
						if char then
							for _, part in ipairs(char:GetDescendants()) do
								if part:IsA("BasePart") then
									part.CanCollide = false
								end
							end
						end
					end)
				end
			else
				if amNoclipConnection then
					amNoclipConnection:Disconnect()
					amNoclipConnection = nil
				end
			end
		end

		afcTrack.MouseButton1Click:Connect(function()
			autoFarmCrystalsEnabled = not autoFarmCrystalsEnabled
			updateAutoFarmVisuals()
			updateAutomationNoclipEngine()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		afnTrack.MouseButton1Click:Connect(function()
			autoFarmNoclipEnabled = not autoFarmNoclipEnabled
			updateAutoFarmNoclipVisuals()
			updateAutomationNoclipEngine()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		------------------------------------------------
		-- 🪨 AUTOMATION BOULDER CATEGORY SECTION
		------------------------------------------------
		local autoFarmBouldersEnabled = false
		local boulderRarityFilters = { ["All"] = true }
		local selectedBoulderBomb = "ClassicBomb"

		local function getTargetPart(obj)
			if not obj then return nil end
			if obj:IsA("BasePart") then return obj end
			if obj:IsA("Model") then
				return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
			end
			return nil
		end

		local function getClosestFilteredBoulder()
			local char = player and player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return nil end

			local myPos = hrp.Position
			local bestObj = nil
			local shortestDist = math.huge

			local BOULDER_MAP = {
				mossite = "Common",
				voltite = "Uncommon",
				gildrite = "Rare",
				rimeveil = "Epic",
				nocturnite = "Legendary"
			}

			local scanned = {}
			local function checkBoulderCandidate(child)
				if not child or not child.Parent or scanned[child] then return end
				scanned[child] = true

				if not (child:IsA("Model") or child:IsA("BasePart")) or child:IsA("Accessory") then return end

				local nameLower = string.lower(child.Name)
				local pNameLower = child.Parent and string.lower(child.Parent.Name) or ""
				local combinedName = nameLower .. " " .. pNameLower

				local rarityStr = child:GetAttribute("Rarity") or child:GetAttribute("rarity")
					or (child.Parent and (child.Parent:GetAttribute("Rarity") or child.Parent:GetAttribute("rarity")))

				if not rarityStr then
					for key, rName in pairs(BOULDER_MAP) do
						if string.find(combinedName, key, 1, true) then
							rarityStr = rName
							break
						end
					end
				end

				if rarityStr then
					local matchesRarity = false
					if boulderRarityFilters["All"] or next(boulderRarityFilters) == nil then
						matchesRarity = true
					else
						for rFilter, isSel in pairs(boulderRarityFilters) do
							if isSel == true and string.lower(tostring(rFilter)) == string.lower(tostring(rarityStr)) then
								matchesRarity = true
								break
							end
						end
					end

					if matchesRarity then
						local part = getTargetPart(child)
						if part then
							local dist = (part.Position - myPos).Magnitude
							if dist < shortestDist then
								shortestDist = dist
								bestObj = child
							end
						end
					end
				end
			end

			-- Scan primary Boulder folders
			local mDeco = workspace:FindFirstChild("MountainDecorations")
			local things = workspace:FindFirstChild("Things")
			local targetFolders = {
				mDeco and mDeco:FindFirstChild("Boulders"),
				workspace:FindFirstChild("Boulders"),
				workspace:FindFirstChild("RenderedBoulders"),
				workspace:FindFirstChild("ActiveBoulders"),
				things and things:FindFirstChild("Boulders"),
			}

			for _, folder in ipairs(targetFolders) do
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						checkBoulderCandidate(child)
					end
				end
			end

			-- Fallback: Scan MountainDecorations descendants and direct Workspace children
			if not bestObj then
				if mDeco then
					for _, desc in ipairs(mDeco:GetDescendants()) do
						checkBoulderCandidate(desc)
					end
				end
				for _, child in ipairs(workspace:GetChildren()) do
					checkBoulderCandidate(child)
				end
			end

			return bestObj
		end

		do
			local isAutoBoulderCategoryExpanded = false
			local autoBoulderCategoryCard = Instance.new("Frame")
			autoBoulderCategoryCard.Size = UDim2.new(1, 0, 0, 36)
			autoBoulderCategoryCard.BackgroundColor3 = COLORS.glassCard
			autoBoulderCategoryCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
			autoBoulderCategoryCard.BorderSizePixel = 0
			autoBoulderCategoryCard.ClipsDescendants = true
			autoBoulderCategoryCard.LayoutOrder = 3.5
			autoBoulderCategoryCard.Parent = mainFrameContent

			refs.applyGlass(autoBoulderCategoryCard, {
				corner = refs.CORNER.medium,
				stroke = true,
				strokeColor = COLORS.borderGlass,
				strokeThickness = 1,
				strokeTransparency = 0.7
			})

			local abHeaderBtn = Instance.new("TextButton")
			abHeaderBtn.Size = UDim2.new(1, 0, 0, 36)
			abHeaderBtn.BackgroundTransparency = 1
			abHeaderBtn.Text = ""
			abHeaderBtn.Parent = autoBoulderCategoryCard

			local abAccentBar = Instance.new("Frame")
			abAccentBar.Size = UDim2.new(0, 3, 0, 18)
			abAccentBar.Position = UDim2.new(0, 12, 0, 9)
			abAccentBar.BackgroundColor3 = COLORS.accentCyan
			abAccentBar.BorderSizePixel = 0
			abAccentBar.Parent = abHeaderBtn

			local abAccentCorner = Instance.new("UICorner")
			abAccentCorner.CornerRadius = UDim.new(0, 2)
			abAccentCorner.Parent = abAccentBar

			local abTitle = Instance.new("TextLabel")
			abTitle.Size = UDim2.new(1, -60, 1, 0)
			abTitle.Position = UDim2.new(0, 24, 0, 0)
			abTitle.BackgroundTransparency = 1
			abTitle.Text = "Automation Boulder"
			abTitle.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
			abTitle.Font = Enum.Font.GothamBold
			abTitle.TextSize = 13
			abTitle.TextXAlignment = Enum.TextXAlignment.Left
			abTitle.Parent = abHeaderBtn

			local abChevronLabel = Instance.new("TextLabel")
			abChevronLabel.Size = UDim2.new(0, 24, 1, 0)
			abChevronLabel.Position = UDim2.new(1, -30, 0, 0)
			abChevronLabel.BackgroundTransparency = 1
			abChevronLabel.Text = ">"
			abChevronLabel.TextColor3 = COLORS.accentCyan
			abChevronLabel.Font = Enum.Font.GothamBold
			abChevronLabel.TextSize = 13
			abChevronLabel.Parent = abHeaderBtn

			local abContentContainer = Instance.new("Frame")
			abContentContainer.Size = UDim2.new(1, -24, 0, 120)
			abContentContainer.Position = UDim2.new(0, 12, 0, 42)
			abContentContainer.BackgroundTransparency = 1
			abContentContainer.Parent = autoBoulderCategoryCard

			refs.applyListLayout(abContentContainer, 6)

			abHeaderBtn.MouseButton1Click:Connect(function()
				isAutoBoulderCategoryExpanded = not isAutoBoulderCategoryExpanded
				abChevronLabel.Text = isAutoBoulderCategoryExpanded and "v" or ">"
				local targetHeight = isAutoBoulderCategoryExpanded and 165 or 36
				local tween = TweenService:Create(autoBoulderCategoryCard,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, targetHeight)
				})
				tween:Play()
			end)

			-- 1. Auto Farm Boulder Toggle
			local afbRow, afbTrack, afbThumb = refs.createGlassToggle(abContentContainer, "Auto Farm Boulder", 1)
			local updateAutoFarmBoulderVisuals = function()
				if autoFarmBouldersEnabled then
					TweenService:Create(afbTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
					TweenService:Create(afbThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
				else
					TweenService:Create(afbTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
					TweenService:Create(afbThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
				end
			end
			updateAutoFarmBoulderVisuals()

			afbTrack.MouseButton1Click:Connect(function()
				autoFarmBouldersEnabled = not autoFarmBouldersEnabled
				updateAutoFarmBoulderVisuals()
				if autoFarmBouldersEnabled then
					pcall(function()
						if _G.HipHubMisc and _G.HipHubMisc.setState then
							_G.HipHubMisc.setState({ flyEnabled = true })
						end
						if _G.HipHubSettings and _G.HipHubSettings.setState then
							_G.HipHubSettings.setState({ noclip = true })
						end
					end)
				end
				if refs.saveConfig then pcall(refs.saveConfig) end
			end)

			-- 2. Dropdown: Boulder Rarity Filter
			local bRarities = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			local bRarityCard, bRarityBtn, bRarityLabel, bRarityMenuFrame, bRaritySearch, bRarityScroll = refs.createGlassDropdown(
				abContentContainer, "Boulder Rarity Filter", "All", 2
			)

			local function getSelectedBoulderRarityLabelText()
				if not boulderRarityFilters or boulderRarityFilters["All"] or next(boulderRarityFilters) == nil then
					return "All"
				end
				local list = {}
				for _, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary" }) do
					if boulderRarityFilters[r] then table.insert(list, r) end
				end
				if #list == 0 then return "All" end
				if #list == 1 then return list[1] end
				if #list == 2 then return list[1] .. ", " .. list[2] end
				return tostring(#list) .. " Selected"
			end

			refs.registerDropdownMenu(bRarityBtn, bRarityMenuFrame)
			local bRarityBinder = refs.bindDropdown(
				bRarityBtn, bRarityMenuFrame, bRaritySearch, bRarityScroll, bRarities,
				function(opt) return boulderRarityFilters[opt] == true end,
				function(opt)
					if opt == "All" then
						boulderRarityFilters = { ["All"] = true }
					else
						boulderRarityFilters["All"] = nil
						boulderRarityFilters[opt] = not boulderRarityFilters[opt]
						local hasAny = false
						for _, v in pairs(boulderRarityFilters) do
							if v then hasAny = true break end
						end
						if not hasAny then boulderRarityFilters["All"] = true end
					end
					if refs.saveConfig then pcall(refs.saveConfig) end
				end,
				function()
					bRarityLabel.Text = getSelectedBoulderRarityLabelText()
				end
			)

			-- 3. Dropdown: Select Bomb for Mining Boulder
			local bombOptions = {
				"ClassicBomb",
				"WindBomb",
				"IceBomb",
				"FireBomb",
				"ThunderBomb",
				"PoisonBomb",
				"TimeBomb",
				"AgonyBomb"
			}
			local bombCard, bombBtn, bombLabel, bombMenuFrame, bombSearch, bombScroll = refs.createGlassDropdown(
				abContentContainer, "Select Bomb for Mining Boulder", selectedBoulderBomb, 3
			)

			refs.registerDropdownMenu(bombBtn, bombMenuFrame)
			local bombBinder = refs.bindDropdown(
				bombBtn, bombMenuFrame, bombSearch, bombScroll, bombOptions,
				function(opt) return selectedBoulderBomb == opt end,
				function(val)
					selectedBoulderBomb = val
					bombLabel.Text = val
					if refs.saveConfig then pcall(refs.saveConfig) end
				end,
				function()
					bombLabel.Text = selectedBoulderBomb
				end
			)
		end

		-- Auto Farm Boulder Loop Engine
		task.spawn(function()
			while true do
				task.wait(0.15)
				if autoFarmBouldersEnabled then
					-- Sync Fly & Noclip toggles automatically
					pcall(function()
						if _G.HipHubMisc and _G.HipHubMisc.setState then
							_G.HipHubMisc.setState({ flyEnabled = true })
						end
						if _G.HipHubSettings and _G.HipHubSettings.setState then
							_G.HipHubSettings.setState({ noclip = true })
						end
					end)

					local targetBoulderModel = getClosestFilteredBoulder()
					if targetBoulderModel and targetBoulderModel.Parent then
						local boulderPart = getTargetPart(targetBoulderModel)
						local myChar = player and player.Character
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

						if myHrp and boulderPart and boulderPart.Parent then
							-- 1. Fly / Tween to Boulder position with anti-gravity levitation
							if myHum then myHum.PlatformStand = true end

							local holdBv = myHrp:FindFirstChild("BoulderHoldBV")
							if not holdBv then
								holdBv = Instance.new("BodyVelocity")
								holdBv.Name = "BoulderHoldBV"
								holdBv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
								holdBv.Velocity = Vector3.zero
								holdBv.Parent = myHrp
							end

							local targetPos = boulderPart.Position + Vector3.new(0, 3, 0)
							local targetCFrame = CFrame.new(targetPos, boulderPart.Position)
							local distToBoulder = (myHrp.Position - targetPos).Magnitude

							if distToBoulder > 4 then
								local duration = math.clamp(distToBoulder / 350, 0.15, 4.0)
								local tweenMove = TweenService:Create(myHrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
								tweenMove:Play()
								tweenMove.Completed:Wait()
							end
							myHrp.CFrame = targetCFrame
							pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)
							task.wait(0.1)

							-- 2. Equip Pickaxe & Mine Boulder continuously until destroyed, collecting Runes instantly in mid-air
							local function getPickaxeTool()
								local p = player or game:GetService("Players").LocalPlayer
								local char = p and p.Character
								local bp = p and (p:FindFirstChildOfClass("Backpack") or p:FindFirstChild("Backpack"))

								local knownPickaxeKeywords = {
									"pick", "axe", "spike", "apex", "fang", "reign", "terminus",
									"titanium", "celestial", "eclipse", "void", "starter", "mining"
								}

								local function scan(cont)
									if not cont then return nil end
									for _, child in ipairs(cont:GetChildren()) do
										if child:IsA("Tool") then
											local nLower = string.lower(child.Name)
											for _, kw in ipairs(knownPickaxeKeywords) do
												if string.find(nLower, kw, 1, true) then
													return child
												end
											end
											if child:GetAttribute("Pickaxe") or child:GetAttribute("IsPickaxe") then
												return child
											end
										end
									end
									-- Fallback: Any tool that is NOT a bomb, crystal, or rune
									for _, child in ipairs(cont:GetChildren()) do
										if child:IsA("Tool") then
											local nLower = string.lower(child.Name)
											if not string.find(nLower, "bomb", 1, true)
												and not string.find(nLower, "crystal", 1, true)
												and not string.find(nLower, "rune", 1, true)
												and not string.find(nLower, "kg", 1, true) then
												return child
											end
										end
									end
									return nil
								end

								return scan(char) or scan(bp)
							end

							local pickTool = getPickaxeTool()
							if pickTool and myChar then
								pcall(function()
									pickTool.Parent = myChar
									if myHum then myHum:EquipTool(pickTool) end
								end)
								task.wait(0.15)
							end

							-- Helper to collect all spawned Runes near position by TWEENING to each Rune (Matches Auto Mining Rune engine!)
							local function collectRunesNearPos(centerPos)
								if not centerPos or not myHrp then return end

								local runeKeywords = {
									"rune", "luck", "haste", "storm", "weight", "fortune",
									"detonation", "preservation", "warmth", "excavator", "colossus"
								}

								local function triggerRunePrompt(p)
									if not p or not p:IsA("ProximityPrompt") then return end
									pcall(function()
										p.RequiresLineOfSight = false
										p.MaxActivationDistance = 99999
										p.HoldDuration = 0
										if fireproximityprompt then
											fireproximityprompt(p)
										end
									end)
								end

								local targetRunes = {}
								local scanList = {}
								local things = workspace:FindFirstChild("Things")
								local runeFolders = {
									workspace:FindFirstChild("DroppedRunes"),
									workspace:FindFirstChild("Runes"),
									things and things:FindFirstChild("Runes"),
									things and things:FindFirstChild("DroppedRunes"),
									workspace:FindFirstChild("MountainDecorations")
								}

								for _, folder in ipairs(runeFolders) do
									if folder then
										for _, c in ipairs(folder:GetChildren()) do table.insert(scanList, c) end
									end
								end
								for _, c in ipairs(workspace:GetChildren()) do table.insert(scanList, c) end

								local addedMap = {}
								for _, child in ipairs(scanList) do
									if child and child.Parent and not addedMap[child] and (child:IsA("MeshPart") or child:IsA("BasePart") or child:IsA("Model")) and not child:IsA("Accessory") then
										addedMap[child] = true
										local cName = string.lower(child.Name)
										local pName = child.Parent and string.lower(child.Parent.Name) or ""
										local isR = string.find(pName, "rune", 1, true) ~= nil or string.find(cName, "rune", 1, true) ~= nil

										if not isR then
											for _, kw in ipairs(runeKeywords) do
												if string.find(cName, kw, 1, true) then isR = true break end
											end
										end

										if isR then
											local rPart = child:IsA("BasePart") and child or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
											if rPart and rPart.Position.Y >= 10 and (rPart.Position - centerPos).Magnitude <= 120 then
												table.insert(targetRunes, { item = child, part = rPart })
											end
										end
									end
								end

								-- Collect ALL target Runes sequentially by TWEENING to each Rune (like Auto Mining!)
								for _, rData in ipairs(targetRunes) do
									local item = rData.item
									local part = rData.part
									if item and item.Parent and part and part.Parent then
										local rTargetPos = part.Position
										if rTargetPos.Y >= 10 then
											local rCFrame = CFrame.new(rTargetPos)
											if tweenToTargetCFrame then
												pcall(function() tweenToTargetCFrame(myHrp, rCFrame, 500) end)
											else
												local dist = (myHrp.Position - rTargetPos).Magnitude
												local dur = math.clamp(dist / 450, 0.05, 0.3)
												local tw = TweenService:Create(myHrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = rCFrame })
												tw:Play()
												tw.Completed:Wait()
											end
											myHrp.CFrame = rCFrame
											pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)

											-- Trigger ProximityPrompts repeatedly in a short loop until collected (exact Auto Mining logic!)
											local startTime = os.clock()
											while item and item.Parent and (os.clock() - startTime < 0.4) do
												local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true) or part:FindFirstChildWhichIsA("ProximityPrompt", true)
												if prompt then
													triggerRunePrompt(prompt)
												end

												pcall(function()
													for _, desc in ipairs(item:GetDescendants()) do
														if desc:IsA("ProximityPrompt") then
															triggerRunePrompt(desc)
														end
													end
												end)

												if firetouchinterest then
													pcall(function()
														firetouchinterest(myHrp, part, 0)
														firetouchinterest(myHrp, part, 1)
													end)
												end

												task.wait(0.05)
											end
										end
									end
								end
							end

							-- Fast Mining Loop: Mine boulder continuously until model or part is destroyed
							local mineStart = os.clock()
							local lastRuneScan = 0
							while autoFarmBouldersEnabled and boulderPart and boulderPart.Parent and targetBoulderModel and targetBoulderModel.Parent and (os.clock() - mineStart < 20) do
								pcall(function()
									if pickTool and pickTool.Parent == myChar then
										pickTool:Activate()
									end

									local rems = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
										or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
										or game:GetService("ReplicatedStorage")
									if rems then
										local mineRem = rems:FindFirstChild("MineRequest") or rems:FindFirstChild("Mine") or rems:FindFirstChild("Damage")
										if mineRem then
											mineRem:FireServer(boulderPart)
										end
									end
								end)

								-- Periodic Rune scan while mining (every 0.3s)
								if os.clock() - lastRuneScan > 0.3 then
									lastRuneScan = os.clock()
									pcall(function() collectRunesNearPos(bInitialPos) end)
								end

								task.wait(0.1)
							end

							-- Post-destruction Guaranteed Rune Collection (Active 2.0s window for server spawned Runes)
							if autoFarmBouldersEnabled then
								local sweepStart = os.clock()
								while autoFarmBouldersEnabled and (os.clock() - sweepStart < 2.0) do
									pcall(function() collectRunesNearPos(bInitialPos) end)
									task.wait(0.2)
								end
							end
						end
					end
				else
					local myChar = player and player.Character
					local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
					local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
					if myHrp then
						local holdBv = myHrp:FindFirstChild("BoulderHoldBV")
						if holdBv then pcall(function() holdBv:Destroy() end) end
					end
					if myHum and not flyEnabled then
						myHum.PlatformStand = false
					end
				end
			end
		end)

		-- Helper to get closest filtered crystal using Automation Mining's multi-select filters
		local function getClosestFilteredCrystal()
			local char = player and player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return nil end

			local myPos = hrp.Position
			local evaluatedObjects = {}

			-- =========================================================
			-- PRIORITY 1: AUTO MINE RUNES (If enabled, search & target Runes FIRST!)
			-- =========================================================
			if autoFarmRunesEnabled then
				local bestRuneObj = nil
				local bestRunePart = nil
				local shortestRuneDist = math.huge

				local function checkRuneCandidate(child)
					if not child or not child.Parent or evaluatedObjects[child] then return end
					evaluatedObjects[child] = true

					if not (child:IsA("BasePart") or child:IsA("Model")) or child:IsA("Accessory") then return end

					local pName = child.Parent and child.Parent.Name or ""
					local fullName = string.lower(child.Name .. " " .. pName)
					local attrStr = ""
					pcall(function()
						for aName, aVal in pairs(child:GetAttributes()) do
							attrStr = attrStr .. " " .. string.lower(tostring(aName)) .. " " .. string.lower(tostring(aVal))
						end
					end)
					local combinedSearchText = fullName .. " " .. attrStr

					local isRune = string.find(combinedSearchText, "rune", 1, true) ~= nil
						or (child.Parent and string.find(string.lower(child.Parent.Name), "rune", 1, true) ~= nil)
						or string.find(combinedSearchText, "luck", 1, true) ~= nil
						or string.find(combinedSearchText, "haste", 1, true) ~= nil
						or string.find(combinedSearchText, "storm", 1, true) ~= nil
						or string.find(combinedSearchText, "weight", 1, true) ~= nil
						or string.find(combinedSearchText, "fortune", 1, true) ~= nil
						or string.find(combinedSearchText, "detonation", 1, true) ~= nil
						or string.find(combinedSearchText, "preservation", 1, true) ~= nil
						or string.find(combinedSearchText, "warmth", 1, true) ~= nil
						or string.find(combinedSearchText, "excavator", 1, true) ~= nil
						or string.find(combinedSearchText, "colossus", 1, true) ~= nil

					if isRune then
						local targetPart = child:IsA("BasePart") and child or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
						if targetPart and targetPart.Position.Y >= 10 then
							local dist = (myPos - targetPart.Position).Magnitude
							if dist < shortestRuneDist then
								shortestRuneDist = dist
								bestRuneObj = child
								bestRunePart = targetPart
							end
						end
					end
				end

				-- 1. Scan direct Workspace children for Runes (Haste Rune, Luck Rune, etc.)
				for _, child in ipairs(workspace:GetChildren()) do
					checkRuneCandidate(child)
				end

				-- 2. Scan known Rune Folders
				local things = workspace:FindFirstChild("Things")
				local runeFolders = {
					workspace:FindFirstChild("Runes"),
					things and things:FindFirstChild("Runes"),
					workspace:FindFirstChild("DroppedRunes"),
					things and things:FindFirstChild("DroppedRunes"),
				}
				for _, folder in ipairs(runeFolders) do
					if folder then
						for _, child in ipairs(folder:GetChildren()) do
							checkRuneCandidate(child)
						end
					end
				end

				-- If ANY Rune is found, RETURN IT IMMEDIATELY! (Priority 1)
				if bestRuneObj and bestRunePart then
					return { obj = bestRuneObj, part = bestRunePart }
				end
			end

			-- =========================================================
			-- PRIORITY 2: AUTO FARM CRYSTALS (Only if Crystals is enabled & no Rune targeted)
			-- =========================================================
			if not autoFarmCrystalsEnabled then
				return nil
			end

			local bestObj = nil
			local bestPart = nil
			local shortestDist = math.huge

			local filterMap = {
				["common"] = { "_t1", "t1", "common", "tier1", "tier 1" },
				["uncommon"] = { "_t2", "t2", "uncommon", "tier2", "tier 2" },
				["rare"] = { "_t3", "t3", "rare", "tier3", "tier 3" },
				["epic"] = { "_t4", "t4", "epic", "tier4", "tier 4" },
				["legendary"] = { "_t5", "t5", "legendary", "tier5", "tier 5" },
				["mythical"] = { "_t6", "t6", "mythical", "mythic", "tier6", "tier 6" },
				["mythic"] = { "_t6", "t6", "mythical", "mythic", "tier6", "tier 6" },
			}

			-- Check if any rarity is explicitly enabled
			local hasAnyEnabledRarity = false
			if type(autoFarmRarityFilters) == "table" then
				for r, isSel in pairs(autoFarmRarityFilters) do
					if isSel == true then
						hasAnyEnabledRarity = true
						break
					end
				end
			end

			-- Check if any size is explicitly enabled
			local hasAnyEnabledSize = false
			if type(autoFarmSizeFilters) == "table" then
				for s, isSel in pairs(autoFarmSizeFilters) do
					if isSel == true then
						hasAnyEnabledSize = true
						break
					end
				end
			end

			local function evaluateCandidate(child)
				if not child or not child.Parent or evaluatedObjects[child] then return end
				evaluatedObjects[child] = true

				if not (child:IsA("BasePart") or child:IsA("Model")) or child:IsA("Accessory") then return end

				local pName = child.Parent and child.Parent.Name or ""
				local gpName = (child.Parent and child.Parent.Parent) and child.Parent.Parent.Name or ""
				local fullName = string.lower(child.Name .. " " .. pName .. " " .. gpName)

				local attrStr = ""
				pcall(function()
					for aName, aVal in pairs(child:GetAttributes()) do
						attrStr = attrStr .. " " .. string.lower(tostring(aName)) .. " " .. string.lower(tostring(aVal))
					end
					if child.Parent then
						for aName, aVal in pairs(child.Parent:GetAttributes()) do
							attrStr = attrStr .. " " .. string.lower(tostring(aName)) .. " " .. string.lower(tostring(aVal))
						end
					end
				end)

				local combinedSearchText = fullName .. " " .. attrStr

				local isRune = string.find(combinedSearchText, "rune", 1, true) ~= nil
				if isRune then return end -- Runes were already processed in Priority 1

				local isCrystal = string.find(combinedSearchText, "crystal", 1, true) ~= nil or child:GetAttribute("Tier") ~= nil or child:GetAttribute("WeightKg") ~= nil or string.find(combinedSearchText, "kg", 1, true)

				-- Min Value Filter Check ($M)
				local matchesValue = true
				if autoFarmMinValueMillions > 0 then
					local rawVal = 0
					pcall(function()
						local vAttr = child:GetAttribute("Value") or child:GetAttribute("Worth") or child:GetAttribute("Price") or child:GetAttribute("SellValue") or child:GetAttribute("EstimatedValue")
						if typeof(vAttr) == "number" then
							rawVal = vAttr
						elseif typeof(vAttr) == "string" then
							local n = tonumber(string.match(vAttr, "%d+%.?%d*")) or 0
							if string.find(string.lower(vAttr), "b", 1, true) then n = n * 1000000000
							elseif string.find(string.lower(vAttr), "m", 1, true) then n = n * 1000000
							elseif string.find(string.lower(vAttr), "k", 1, true) then n = n * 1000 end
							rawVal = n
						end
					end)

					if rawVal <= 0 then
						pcall(function()
							for _, desc in ipairs(child:GetDescendants()) do
								if desc:IsA("TextLabel") then
									local txt = string.lower(desc.Text)
									if string.find(txt, "val", 1, true) or string.find(txt, "$", 1, true) or string.find(txt, "m", 1, true) or string.find(txt, "b", 1, true) then
										local n = tonumber(string.match(txt, "%d+%.?%d*")) or 0
										if string.find(txt, "b", 1, true) then n = n * 1000000000
										elseif string.find(txt, "m", 1, true) then n = n * 1000000
										elseif string.find(txt, "k", 1, true) then n = n * 1000 end
										if n > rawVal then rawVal = n end
									end
								end
							end
						end)
					end

					local valInMillions = rawVal / 1000000
					if valInMillions < autoFarmMinValueMillions then
						matchesValue = false
					end
				end

				-- Multi-Select Rarity Check
				local matchesRarity = false
				if not hasAnyEnabledRarity or autoFarmRarityFilters["All"] == true then
					matchesRarity = true
				else
					for selRarity, isSel in pairs(autoFarmRarityFilters) do
						if isSel == true then
							local rarityLower = string.lower(tostring(selRarity))
							local kws = filterMap[rarityLower]
							if kws then
								for _, kw in ipairs(kws) do
									if string.find(combinedSearchText, kw, 1, true) then
										matchesRarity = true
										break
									end
								end
							end
							if not matchesRarity and string.find(combinedSearchText, rarityLower, 1, true) then
								matchesRarity = true
							end
							if matchesRarity then break end
						end
					end
				end

				-- Multi-Select Size Check
				local matchesSize = false
				if not hasAnyEnabledSize or autoFarmSizeFilters["All"] == true then
					matchesSize = true
				else
					local wKg = child:GetAttribute("WeightKg") or child:GetAttribute("Weight") or (child.Parent and child.Parent:GetAttribute("WeightKg")) or (child.Parent and child.Parent:GetAttribute("Weight"))

					if not wKg then
						local kgMatch = string.match(combinedSearchText, "(%d+%.?%d*)%s*kg")
						if kgMatch then
							wKg = tonumber(kgMatch)
						end
					end

					local sizeVec = nil
					if child:IsA("BasePart") then
						sizeVec = child.Size
					elseif child:IsA("Model") then
						pcall(function()
							local _, sz = child:GetBoundingBox()
							sizeVec = sz
						end)
						if not sizeVec then
							local primary = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
							if primary then sizeVec = primary.Size end
						end
					end
					local maxDim = sizeVec and math.max(sizeVec.X, sizeVec.Y, sizeVec.Z) or 0

					local detectedSize = nil
					if string.find(combinedSearchText, "%[behemoth%]", 1, true) or string.find(combinedSearchText, "behemoth", 1, true) then
						detectedSize = "behemoth"
					elseif string.find(combinedSearchText, "%[leviathan%]", 1, true) or string.find(combinedSearchText, "leviathan", 1, true) then
						detectedSize = "leviathan"
					elseif string.find(combinedSearchText, "%[titan%]", 1, true) or string.find(combinedSearchText, "titan", 1, true) then
						detectedSize = "titan"
					elseif string.find(combinedSearchText, "%[colossal%]", 1, true) or string.find(combinedSearchText, "colossal", 1, true) then
						detectedSize = "colossal"
					elseif string.find(combinedSearchText, "%[giant%]", 1, true) or string.find(combinedSearchText, "giant", 1, true) then
						detectedSize = "giant"
					elseif string.find(combinedSearchText, "%[xl%]", 1, true) or string.find(combinedSearchText, "%[extra large%]", 1, true) or string.find(combinedSearchText, "extra large", 1, true) then
						detectedSize = "extra large"
					elseif string.find(combinedSearchText, "%[l%]", 1, true) or string.find(combinedSearchText, "%[large%]", 1, true) or string.find(combinedSearchText, "large", 1, true) then
						detectedSize = "large"
					elseif string.find(combinedSearchText, "%[m%]", 1, true) or string.find(combinedSearchText, "%[medium%]", 1, true) or string.find(combinedSearchText, "medium", 1, true) then
						detectedSize = "medium"
					elseif string.find(combinedSearchText, "%[s%]", 1, true) or string.find(combinedSearchText, "%[small%]", 1, true) or string.find(combinedSearchText, "small", 1, true) then
						detectedSize = "small"
					elseif wKg then
						if wKg >= 25000 then detectedSize = "behemoth"
						elseif wKg >= 8000 then detectedSize = "leviathan"
						elseif wKg >= 3000 then detectedSize = "titan"
						elseif wKg >= 1000 then detectedSize = "colossal"
						elseif wKg >= 200 then detectedSize = "giant"
						elseif wKg >= 90 then detectedSize = "extra large"
						elseif wKg >= 30 then detectedSize = "large"
						elseif wKg >= 8 then detectedSize = "medium"
						else detectedSize = "small"
						end
					elseif maxDim > 0 then
						if maxDim >= 50 then detectedSize = "behemoth"
						elseif maxDim >= 35 then detectedSize = "leviathan"
						elseif maxDim >= 22 then detectedSize = "titan"
						elseif maxDim >= 15 then detectedSize = "colossal"
						elseif maxDim >= 10 then detectedSize = "giant"
						elseif maxDim >= 7 then detectedSize = "extra large"
						elseif maxDim >= 4.5 then detectedSize = "large"
						elseif maxDim >= 1.8 then detectedSize = "medium"
						else detectedSize = "small"
						end
					end

					for selSize, isSel in pairs(autoFarmSizeFilters) do
						if isSel == true then
							local sLower = string.lower(tostring(selSize))
							if detectedSize and (sLower == detectedSize or (sLower == "xl" and detectedSize == "extra large") or (sLower == "l" and detectedSize == "large") or (sLower == "m" and detectedSize == "medium") or (sLower == "s" and detectedSize == "small")) then
								matchesSize = true
								break
							end
						end
					end
				end

				if matchesRarity and matchesSize and matchesValue then
					local targetPart = child:IsA("BasePart") and child or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
					if targetPart then
						if targetPart.Position.Y >= 10 then
							local dist = (myPos - targetPart.Position).Magnitude
							if dist < shortestDist then
								shortestDist = dist
								bestObj = child
								bestPart = targetPart
							end
						end
					end
				end
			end

			local function evaluateFolder(folder)
				if not folder then return end
				for _, child in ipairs(folder:GetChildren()) do
					evaluateCandidate(child)
					if child:IsA("Model") or child:IsA("Folder") then
						for _, sub in ipairs(child:GetChildren()) do
							evaluateCandidate(sub)
						end
					end
				end
			end

			-- Search known workspace crystal folders
			local things = workspace:FindFirstChild("Things")
			evaluateFolder(workspace:FindFirstChild("Crystals"))
			evaluateFolder(things and things:FindFirstChild("Crystals"))
			evaluateFolder(workspace:FindFirstChild("DroppedCrystals"))
			evaluateFolder(workspace:FindFirstChild("FrozenCaves"))
			evaluateFolder(workspace:FindFirstChild("CaveZones"))
			evaluateFolder(workspace:FindFirstChild("Rocks"))
			evaluateFolder(things and things:FindFirstChild("MountainZones"))
			evaluateFolder(workspace:FindFirstChild("Ores"))
			evaluateFolder(things and things:FindFirstChild("Ores"))
			evaluateFolder(workspace:FindFirstChild("Mines"))
			evaluateFolder(workspace:FindFirstChild("Nodes"))

			if bestObj and bestPart then
				return { obj = bestObj, part = bestPart }
			end
			return nil
		end

		-- Helper to check if player backpack/inventory is full based on PlayerGui, CarryWeight, or slot limits
		isBackpackFull = function()
			local p = player or game:GetService("Players").LocalPlayer
			if not p then return false end

			-- 1. Check PlayerGui for visible "BACKPACK FULL!" popups or notifications (as shown in game UI)
			local guiFull = false
			pcall(function()
				local pGui = p:FindFirstChildOfClass("PlayerGui") or p:FindFirstChild("PlayerGui")
				if pGui then
					for _, desc in ipairs(pGui:GetDescendants()) do
						if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Visible then
							local txt = string.lower(desc.Text or "")
							if string.find(txt, "backpack full", 1, true)
								or string.find(txt, "backpack is full", 1, true)
								or string.find(txt, "go sell", 1, true)
								or string.find(txt, "bag full", 1, true)
								or string.find(txt, "inventory full", 1, true) then
								guiFull = true
								break
							end
						end
					end
				end
			end)
			if guiFull then return true end

			-- 2. Check game's capacity logic (PlayerData.RealStats.CarryWeight)
			local carryCap = 10
			pcall(function()
				local pd = p:FindFirstChild("PlayerData")
				local rs = pd and (pd:FindFirstChild("RealStats") or pd:FindFirstChild("Stats") or pd)
				local cw = rs and (rs:FindFirstChild("CarryWeight") or rs:FindFirstChild("MaxCarryWeight") or rs:FindFirstChild("MaxWeight"))
				if cw and typeof(cw.Value) == "number" and cw.Value > 0 then
					carryCap = cw.Value
				end
			end)

			-- Sum weight of all crystal tools in Backpack + Character
			local totalWeight = 0
			local crystalCount = 0
			local totalTools = 0

			local function scanContainer(container)
				if not container then return end
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") then
						totalTools = totalTools + 1
						local hasTier = child:GetAttribute("Tier") ~= nil
						local wKg = child:GetAttribute("WeightKg") or child:GetAttribute("Weight")
						local tNameLower = string.lower(child.Name)
						local isCrystalTool = hasTier or wKg ~= nil
							or string.find(tNameLower, "crystal", 1, true)
							or string.find(tNameLower, "kg", 1, true)
							or string.find(tNameLower, "%[s%]")
							or string.find(tNameLower, "%[m%]")
							or string.find(tNameLower, "%[l%]")
							or string.find(tNameLower, "%[xl%]")

						if isCrystalTool then
							crystalCount = crystalCount + 1
							local toolWeight = wKg
							if not toolWeight then
								local matchKg = string.match(child.Name, "(%d+%.?%d*)%s*kg")
								if matchKg then
									toolWeight = tonumber(matchKg)
								end
							end
							totalWeight = totalWeight + (toolWeight or 1)
						end
					end
				end
			end

			scanContainer(p:FindFirstChildOfClass("Backpack") or p:FindFirstChild("Backpack"))
			if p.Character then
				scanContainer(p.Character)
			end

			-- 3. Check tool/slot capacity limit (Roblox hotbar holds max 10 tools)
			if totalTools >= 10 or crystalCount >= 8 then
				return true
			end

			-- 4. If total weight exceeds or equals CarryWeight capacity, or within 0.2 kg of capacity
			if carryCap > 0 and (totalWeight >= carryCap or (carryCap - totalWeight) <= 0.2) then
				return true
			end

			-- Fallback: Check Player attributes
			local maxCap = p:GetAttribute("MaxCapacity") or p:GetAttribute("MaxBackpack") or p:GetAttribute("MaxStorage") or p:GetAttribute("MaxCrystals") or p:GetAttribute("MaxBag") or p:GetAttribute("CarryWeight")
			local currCap = p:GetAttribute("Capacity") or p:GetAttribute("BackpackCount") or p:GetAttribute("StorageCount") or p:GetAttribute("CrystalsCount") or p:GetAttribute("BagCount")
			if typeof(maxCap) == "number" and typeof(currCap) == "number" and maxCap > 0 then
				if currCap >= maxCap then return true end
			end

			-- Fallback: Check leaderstats
			local leaderstats = p:FindFirstChild("leaderstats")
			if leaderstats then
				local capVal = leaderstats:FindFirstChild("Capacity") or leaderstats:FindFirstChild("Storage") or leaderstats:FindFirstChild("Backpack") or leaderstats:FindFirstChild("Bag") or leaderstats:FindFirstChild("Crystals")
				local maxVal = leaderstats:FindFirstChild("MaxCapacity") or leaderstats:FindFirstChild("MaxStorage") or leaderstats:FindFirstChild("MaxBackpack") or leaderstats:FindFirstChild("MaxBag") or leaderstats:FindFirstChild("MaxCrystals")
				if capVal and maxVal and tonumber(capVal.Value) and tonumber(maxVal.Value) then
					local cVal = tonumber(capVal.Value)
					local mVal = tonumber(maxVal.Value)
					if mVal > 0 and cVal >= mVal then return true end
				end
			end

			return false
		end

		-- Smooth Fast Tween Helper for Automation Mining (Glide with fast speed)
		local activeFarmTween = nil
		tweenToTargetCFrame = function(myHrp, targetCFrame, speed)
			if not myHrp or not targetCFrame then return end

			-- Don't tween if target Y position < 10
			if targetCFrame.Position.Y < 10 then
				return
			end
			local spd = speed or 350
			local dist = (myHrp.Position - targetCFrame.Position).Magnitude
			if dist <= 3 then
				myHrp.CFrame = targetCFrame
				pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)
				return
			end

			local duration = math.clamp(dist / spd, 0.08, 4.0)
			if activeFarmTween then
				pcall(function() activeFarmTween:Cancel() end)
				activeFarmTween = nil
			end

			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			activeFarmTween = TweenService:Create(myHrp, tweenInfo, { CFrame = targetCFrame })
			activeFarmTween:Play()

			local startT = os.clock()
			while activeFarmTween and (os.clock() - startT < duration + 0.05) and (autoFarmCrystalsEnabled or autoFarmRunesEnabled) do
				task.wait(0.02)
				pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)
			end

			if activeFarmTween then
				pcall(function() activeFarmTween:Cancel() end)
				activeFarmTween = nil
			end
			pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)
		end

		-- Auto Farm Loop with Levitating / Flying Stay Engine & Fast Speed Movement (Continuous Mining & Selling Loop)
		local consecutiveFullCount = 0
		task.spawn(function()
			while true do
				task.wait(0.1)
				if autoFarmCrystalsEnabled or autoFarmRunesEnabled then
					-- Check if backpack is full and trigger Auto Sell (Teleport to shop, sell, return, and resume mining)
					if isBackpackFull and isBackpackFull() and consecutiveFullCount < 3 then
						consecutiveFullCount = consecutiveFullCount + 1
						local myChar = player and player.Character
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if myHrp then
							local flyHold = myHrp:FindFirstChild("HipHubFarmFly")
							if flyHold then pcall(function() flyHold:Destroy() end) end
						end

						pcall(executeSellAllTeleport)
						task.wait(0.3)

						if not (isBackpackFull and isBackpackFull()) then
							consecutiveFullCount = 0
						end
					else
						if consecutiveFullCount >= 3 then
							consecutiveFullCount = 0
							task.wait(0.5)
						end

						local target = getClosestFilteredCrystal()
					if target and target.obj and target.obj.Parent and target.part and target.part.Parent then
						local obj = target.obj
						local part = target.part
						local myChar = player and player.Character
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

						if myHrp then
							-- Create / Attach Hover Flight BodyVelocity to freeze character position in air like flying
							local flyHold = myHrp:FindFirstChild("HipHubFarmFly")
							if not flyHold then
								flyHold = Instance.new("BodyVelocity")
								flyHold.Name = "HipHubFarmFly"
								flyHold.MaxForce = Vector3.new(9e9, 9e9, 9e9)
								flyHold.Velocity = Vector3.zero
								flyHold.Parent = myHrp
							end

							-- Fly & levitate 6.5 studs above the target crystal while picking it up
							local farmTargetPos = part.Position + Vector3.new(0, 6.5, 0)
							local farmTargetCFrame = CFrame.new(farmTargetPos)

							-- Only tween if target Y position >= 10
							if part.Position.Y >= 10 and farmTargetPos.Y >= 10 then
								local currentDist = (myHrp.Position - farmTargetCFrame.Position).Magnitude
								if currentDist > 75 then
									local targetY = part.Position.Y
									local highY = math.max(targetY + 80, 225)
									local mountainMiddleUp = CFrame.new(35, highY, 715)

									tweenToTargetCFrame(myHrp, mountainMiddleUp, 380)
									task.wait(0.1)
								end

								tweenToTargetCFrame(myHrp, farmTargetCFrame, 350)
							end

							-- Check if target is a Rune or Has "COLLECT" / "RUNE" prompt
							local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or (part and part:FindFirstChildWhichIsA("ProximityPrompt", true))
							local isRuneTarget = string.find(string.lower(obj.Name), "rune", 1, true) ~= nil
								or (prompt and (string.find(string.lower(prompt.ActionText or ""), "collect", 1, true) or string.find(string.lower(prompt.ObjectText or ""), "rune", 1, true)))

							if isRuneTarget and myHrp and part then
								-- Position character directly on the Rune's CFrame to guarantee range
								myHrp.CFrame = part.CFrame
								pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)
							end

							-- Helper to bypass line-of-sight & distance limits when crystals are stacked on top
							local function triggerRunePrompt(p)
								if not p or not p:IsA("ProximityPrompt") then return end
								pcall(function()
									p.RequiresLineOfSight = false
									p.MaxActivationDistance = 99999
									p.HoldDuration = 0
									if fireproximityprompt then
										fireproximityprompt(p)
									end
								end)
							end

							if prompt then
								triggerRunePrompt(prompt)
							end

							pcall(function()
								for _, desc in ipairs(obj:GetDescendants()) do
									if desc:IsA("ProximityPrompt") then
										triggerRunePrompt(desc)
									end
								end
							end)

							-- Stay levitated / attached while picking up crystal / collecting rune until collected or timeout
							local startTime = os.clock()
							while (autoFarmCrystalsEnabled or autoFarmRunesEnabled) and obj and obj.Parent and (os.clock() - startTime < 2.5) do
								task.wait(0.08)

								-- Ensure flying BodyVelocity stays attached while picking up
								if myHrp and not myHrp:FindFirstChild("HipHubFarmFly") then
									local fh = Instance.new("BodyVelocity")
									fh.Name = "HipHubFarmFly"
									fh.MaxForce = Vector3.new(9e9, 9e9, 9e9)
									fh.Velocity = Vector3.zero
									fh.Parent = myHrp
								end

								-- Check if backpack becomes full mid-mining to auto-sell immediately
								if isBackpackFull and isBackpackFull() then
									break
								end

								if prompt and prompt.Parent then
									triggerRunePrompt(prompt)
								else
									-- Finish loop immediately if Rune / Crystal was collected and removed
									break
								end
							end
						end
					else
						-- Remove flying hover when no target found
						local myChar = player and player.Character
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if myHrp then
							local flyHold = myHrp:FindFirstChild("HipHubFarmFly")
							if flyHold then flyHold:Destroy() end
						end
						task.wait(0.4)
					end
					end
				else
					-- Clean up flying hover when auto farm is turned OFF
					local myChar = player and player.Character
					local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
					if myHrp then
						local flyHold = myHrp:FindFirstChild("HipHubFarmFly")
						if flyHold then flyHold:Destroy() end
					end
				end
			end
		end)
		end

		------------------------------------------------
		-- ⛏️ AUTOMATION DIGGING CARD & ENGINE
		------------------------------------------------
		do
			local autoDigEnabled = false
			local selectedDigPickaxe = "VolcanoBasalt"
			local selectedDigMaterial = "All"
			local selectedDigRange = 50
			local selectedDigRangeText = "50 Studs"
			local selectedDigTweenSpeed = 350
			local selectedDigTweenSpeedText = "350 (Fast)"

			-- Preference UI Collapsible Section
			local isAutoDigCategoryExpanded = false
			local autoDigCategoryCard = Instance.new("Frame")
			autoDigCategoryCard.Size = UDim2.new(1, 0, 0, 36)
			autoDigCategoryCard.BackgroundColor3 = COLORS.glassCard
			autoDigCategoryCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
			autoDigCategoryCard.BorderSizePixel = 0
			autoDigCategoryCard.ClipsDescendants = true
			autoDigCategoryCard.LayoutOrder = 4
			autoDigCategoryCard.Parent = mainFrameContent

			refs.applyGlass(autoDigCategoryCard, {
				corner = refs.CORNER.medium,
				stroke = true,
				strokeColor = COLORS.borderGlass,
				strokeThickness = 1,
				strokeTransparency = 0.7
			})

			-- Expandable Header Click Button
			local adHeaderBtn = Instance.new("TextButton")
			adHeaderBtn.Size = UDim2.new(1, 0, 0, 36)
			adHeaderBtn.BackgroundTransparency = 1
			adHeaderBtn.Text = ""
			adHeaderBtn.Parent = autoDigCategoryCard

			local adAccentBar = Instance.new("Frame")
			adAccentBar.Size = UDim2.new(0, 3, 0, 18)
			adAccentBar.Position = UDim2.new(0, 12, 0, 9)
			adAccentBar.BackgroundColor3 = COLORS.accentCyan
			adAccentBar.BorderSizePixel = 0
			adAccentBar.Parent = adHeaderBtn

			local adAccentCorner = Instance.new("UICorner")
			adAccentCorner.CornerRadius = UDim.new(0, 2)
			adAccentCorner.Parent = adAccentBar

			local adTitle = Instance.new("TextLabel")
			adTitle.Size = UDim2.new(1, -60, 1, 0)
			adTitle.Position = UDim2.new(0, 24, 0, 0)
			adTitle.BackgroundTransparency = 1
			adTitle.Text = "Automation Digging"
			adTitle.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
			adTitle.Font = Enum.Font.GothamBold
			adTitle.TextSize = 13
			adTitle.TextXAlignment = Enum.TextXAlignment.Left
			adTitle.Parent = adHeaderBtn

			local adChevronLabel = Instance.new("TextLabel")
			adChevronLabel.Size = UDim2.new(0, 24, 1, 0)
			adChevronLabel.Position = UDim2.new(1, -30, 0, 0)
			adChevronLabel.BackgroundTransparency = 1
			adChevronLabel.Text = ">"
			adChevronLabel.TextColor3 = COLORS.accentCyan
			adChevronLabel.Font = Enum.Font.GothamBold
			adChevronLabel.TextSize = 13
			adChevronLabel.Parent = adHeaderBtn

			-- Content Container inside Automation Digging Card
			local autoDigContainer = Instance.new("Frame")
			autoDigContainer.Size = UDim2.new(1, -24, 0, 165)
			autoDigContainer.Position = UDim2.new(0, 12, 0, 42)
			autoDigContainer.BackgroundTransparency = 1
			autoDigContainer.Parent = autoDigCategoryCard

			refs.applyListLayout(autoDigContainer, 6)

			adHeaderBtn.MouseButton1Click:Connect(function()
				isAutoDigCategoryExpanded = not isAutoDigCategoryExpanded
				adChevronLabel.Text = isAutoDigCategoryExpanded and "v" or ">"
				local targetHeight = isAutoDigCategoryExpanded and 215 or 36
				local tween = TweenService:Create(autoDigCategoryCard,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, targetHeight)
				})
				tween:Play()
			end)

			-- Toggle Row 1: Enable Auto Digging
			local adToggleRow, adToggleTrack, adToggleThumb = refs.createGlassToggle(autoDigContainer, "Auto Digging", 1)

			local updateAutoDigVisuals = function()
				if autoDigEnabled then
					TweenService:Create(adToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
					TweenService:Create(adToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
				else
					TweenService:Create(adToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
					TweenService:Create(adToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
				end
			end
			updateAutoDigVisuals()

			adToggleTrack.MouseButton1Click:Connect(function()
				autoDigEnabled = not autoDigEnabled
				updateAutoDigVisuals()
				if saveConfig then pcall(saveConfig) end
			end)

			-- Dropdown Row 2: Select Pickaxe
			local pickaxeOptions = {
				"RustyScrapper",
				"WeatheredWood",
				"ChippedStone",
				"HardenedIron",
				"CopperPick",
				"ReinforcedSteel",
				"TitaniumSpike",
				"FrostbitePick",
				"EmeraldCarver",
				"VolcanoBasalt",
				"ObsidianEdge",
				"TempestPick",
				"CelestialApex",
				"AstralRend",
				"EclipseFang",
				"NebularThrone",
				"Voidreign",
				"Singularity",
				"TheTerminus",
				"SharkPickaxe",
				"DiamondPickaxe"
			}

			local pickDropCard, pickDropBtn, pickDropLabel, pickMenuFrame, pickSearch, pickScroll = refs.createGlassDropdown(
				autoDigContainer, "Select Pickaxe for Digging", selectedDigPickaxe, 2
			)

			refs.registerDropdownMenu(pickDropBtn, pickMenuFrame)
			local pickBinder = refs.bindDropdown(
				pickDropBtn, pickMenuFrame, pickSearch, pickScroll, pickaxeOptions,
				function(opt) return selectedDigPickaxe == opt end,
				function(val)
					selectedDigPickaxe = val
					pickDropLabel.Text = val
					if saveConfig then pcall(saveConfig) end
				end,
				function()
					pickDropLabel.Text = selectedDigPickaxe
				end
			)

			local updatePickDropdownVisuals = function()
				pickDropLabel.Text = selectedDigPickaxe
				pickBinder.updateOptionVisuals()
			end

			-- Dropdown Row 3: Select Material for Digging
			local materialOptions = {
				"All",
				"Slate",
				"Ground",
				"Rock",
				"Sand",
				"Grass",
				"Mud",
				"Dirt",
				"Asphalt",
				"Brick",
				"Cobblestone",
				"Concrete",
				"Ice",
				"LeafyGrass",
				"Pavement",
				"Salt"
			}

			local matDropCard, matDropBtn, matDropLabel, matMenuFrame, matSearch, matScroll = refs.createGlassDropdown(
				autoDigContainer, "Select Material for Digging", selectedDigMaterial, 3
			)

			refs.registerDropdownMenu(matDropBtn, matMenuFrame)
			local matBinder = refs.bindDropdown(
				matDropBtn, matMenuFrame, matSearch, matScroll, materialOptions,
				function(opt) return selectedDigMaterial == opt end,
				function(val)
					selectedDigMaterial = val
					matDropLabel.Text = val
					if saveConfig then pcall(saveConfig) end
				end,
				function()
					matDropLabel.Text = selectedDigMaterial
				end
			)

			local updateMatDropdownVisuals = function()
				matDropLabel.Text = selectedDigMaterial
				matBinder.updateOptionVisuals()
			end

			-- Button Row 4: Set Current Center Position
			local customDigCenterPos = Vector3.new(31.1644400100708008, 92.10850524902344, 867.5848388671875)

			local setPosCard, setPosBtn = refs.createGlassButton(autoDigContainer, "Set Current Center Pos (50 Studs Box)", 4)
			setPosBtn.MouseButton1Click:Connect(function()
				local char = player and player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					customDigCenterPos = hrp.Position
					setPosBtn.Text = string.format("Center Set: (%.1f, %.1f, %.1f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
					updateDigBoxVisuals()
					if saveConfig then pcall(saveConfig) end
				end
			end)

			-- 3D Visual Box Helper (Cleaned - No visual adornment on screen)
			local function updateDigBoxVisuals()
				pcall(function()
					local boxPart = workspace:FindFirstChild("HipHubDigBoxPart")
					if boxPart then boxPart:Destroy() end
				end)
			end

			-- Auto Fly Mode Toggle Sync
			local function syncAutoDigFlyMode()
				local char = player and player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local flyHold = hrp:FindFirstChild("HipHubFarmFly")
					if autoDigEnabled then
						if not flyHold then
							flyHold = Instance.new("BodyVelocity")
							flyHold.Name = "HipHubFarmFly"
							flyHold.MaxForce = Vector3.new(9e9, 9e9, 9e9)
							flyHold.Velocity = Vector3.zero
							flyHold.Parent = hrp
						end
					else
						if flyHold then flyHold:Destroy() end
					end
				end
			end

			adToggleTrack.MouseButton1Click:Connect(function()
				updateDigBoxVisuals()
				syncAutoDigFlyMode()
			end)

			-- Auto-Digging Loop Engine inside Equal Cube (150x150x150 Studs) with Speed = 30
			local DIGGABLE_MATERIAL_KEYWORDS = {
				"asphalt", "brick", "cobblestone", "concrete", "ice", "leafygrass", "pavement", "salt",
				"mud", "dirt", "dig", "ground", "rock", "basalt", "stone", "sand", "gravel", "soil", "slate"
			}

			local function performOutermostAutoDig(getIsActiveFunc, pickaxeName)
				local char = player and player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not hrp or not hum then return end

				local moveSpeed = 30 -- Custom move speed = 30 studs/sec
				local centerPos = customDigCenterPos or Vector3.new(31.16444001, 92.108505, 867.584838)
				local rangeStuds = 75 -- Equal Cube Side Radius (150 x 150 x 150 Studs)

				updateDigBoxVisuals()
				syncAutoDigFlyMode()

				-- Helper to find diggable Terrain surface or material block strictly INSIDE 150x150x150 cube
				local function findOutermostDigTarget(pos, targetMatFilter)
					local candidates = {}
					local filterLower = (targetMatFilter and targetMatFilter ~= "All") and string.lower(targetMatFilter) or nil

					-- 1. Scan Workspace.Terrain using Raycasts inside equal cube
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					local filterList = {}
					if char then table.insert(filterList, char) end
					rayParams.FilterDescendantsInstances = filterList
					rayParams.IgnoreWater = true

					local step = 6

					for offsetZ = -rangeStuds, rangeStuds, step do
						for offsetX = -rangeStuds, rangeStuds, step do
							local rayOrigin = Vector3.new(centerPos.X + offsetX, centerPos.Y + rangeStuds, centerPos.Z + offsetZ)
							local rayDirection = Vector3.new(0, -(rangeStuds * 2), 0)
							local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

							if rayResult and (rayResult.Instance == workspace.Terrain or rayResult.Instance:IsA("Terrain")) then
								local hitPos = rayResult.Position
								local hitMatName = string.lower(tostring(rayResult.Material.Name))

								if math.abs(hitPos.Y - centerPos.Y) <= rangeStuds and hitPos.Y >= 5 then
									local isMatch = false
									if not filterLower then
										isMatch = true
									else
										if string.find(hitMatName, filterLower, 1, true) then
											isMatch = true
										end
									end

									if isMatch then
										table.insert(candidates, { Position = hitPos, Instance = rayResult.Instance })
									end
								end
							end
						end
					end

					-- 2. Scan folders for any dig BaseParts inside 150x150x150 cube
					local folders = {
						workspace:FindFirstChild("RealisticMaterials"),
						workspace:FindFirstChild("Materials"),
						workspace:FindFirstChild("Mud"),
						workspace:FindFirstChild("Dirt"),
						workspace:FindFirstChild("CaveZones"),
						workspace:FindFirstChild("Things"),
						workspace:FindFirstChild("Map"),
						workspace:FindFirstChild("Nodes"),
						workspace:FindFirstChild("Rocks"),
					}

					for _, folder in ipairs(folders) do
						if folder then
							for _, obj in ipairs(folder:GetDescendants()) do
								if obj:IsA("BasePart") and not obj:IsA("Terrain") then
									local dx = math.abs(obj.Position.X - centerPos.X)
									local dy = math.abs(obj.Position.Y - centerPos.Y)
									local dz = math.abs(obj.Position.Z - centerPos.Z)

									if dx <= rangeStuds and dy <= rangeStuds and dz <= rangeStuds and obj.Position.Y >= 5 then
										local nameLower = string.lower(obj.Name)
										local matName = string.lower(tostring(obj.Material))
										local inRealisticFolder = false
										local p = obj.Parent
										while p and p ~= workspace do
											local pName = string.lower(p.Name)
											if string.find(pName, "realisticmaterials", 1, true) or string.find(pName, "materials", 1, true) then
												inRealisticFolder = true
												break
											end
											p = p.Parent
										end

										local isMatch = false
										if filterLower then
											if string.find(nameLower, filterLower, 1, true) or string.find(matName, filterLower, 1, true) then
												isMatch = true
											end
										else
											if inRealisticFolder then
												isMatch = true
											else
												for _, kw in ipairs(DIGGABLE_MATERIAL_KEYWORDS) do
													if string.find(nameLower, kw, 1, true) or string.find(matName, kw, 1, true) then
														isMatch = true
														break
													end
												end
											end
										end

										if isMatch then
											table.insert(candidates, { Position = obj.Position, Instance = obj })
										end
									end
								end
							end
						end
					end

					-- 3. Strict Layer-by-Layer Top-Down Selection:
					-- Find maximum Y position among candidates (top Y level layer)
					if #candidates > 0 then
						local maxY = -99999
						for _, item in ipairs(candidates) do
							if item.Position.Y > maxY then
								maxY = item.Position.Y
							end
						end

						-- Keep ONLY candidates on the current top Y layer (within 2.5 studs of maxY)
						local topLayerCandidates = {}
						local layerThreshold = 2.5
						for _, item in ipairs(candidates) do
							if (maxY - item.Position.Y) <= layerThreshold then
								table.insert(topLayerCandidates, item)
							end
						end

						-- Sort current top Y layer:
						-- 1. Outermost perimeter shell band from center
						-- 2. Nearest neighbor distance to player (Smooth sequential digging on current Y layer!)
						table.sort(topLayerCandidates, function(a, b)
							local posA, posB = a.Position, b.Position
							local shellA = math.max(math.abs(posA.X - centerPos.X), math.abs(posA.Z - centerPos.Z))
							local shellB = math.max(math.abs(posB.X - centerPos.X), math.abs(posB.Z - centerPos.Z))
							local shellTierA = math.floor(shellA / 4)
							local shellTierB = math.floor(shellB / 4)
							if shellTierA ~= shellTierB then
								return shellTierA > shellTierB
							end

							return (posA - pos).Magnitude < (posB - pos).Magnitude
						end)

						return topLayerCandidates[1].Position
					end

					return nil
				end

				-- Ensure pickaxe tool is equipped
				local heldTool = char:FindFirstChildWhichIsA("Tool")
				if not heldTool then
					local backpack = player and player:FindFirstChild("Backpack")
					if backpack then
						for _, tool in ipairs(backpack:GetChildren()) do
							if tool:IsA("Tool") then
								hum:EquipTool(tool)
								task.wait(0.05)
								break
							end
						end
					end
				end

				-- Search for highest & outermost Terrain / Material target inside 150x150x150 cube
				local targetDigPos = findOutermostDigTarget(hrp.Position, selectedDigMaterial)

				if not targetDigPos then
					local fallbackRay = workspace:Raycast(Vector3.new(centerPos.X, centerPos.Y + rangeStuds, centerPos.Z), Vector3.new(0, -(rangeStuds * 2), 0), rayParams)
					if fallbackRay then
						targetDigPos = fallbackRay.Position
					else
						targetDigPos = Vector3.new(centerPos.X, 30, centerPos.Z)
					end
				end

				if targetDigPos.Y < 5 then
					targetDigPos = Vector3.new(targetDigPos.X, 5, targetDigPos.Z)
				end

				-- Position character 1.2 studs DIRECTLY ABOVE target mountain block
				local targetHover = Vector3.new(targetDigPos.X, targetDigPos.Y + 1.2, targetDigPos.Z)

				local dist = (hrp.Position - targetHover).Magnitude
				if dist > 1.0 then
					local timeToMove = math.clamp(dist / moveSpeed, 0.05, 3.0)
					local tw = TweenService:Create(hrp, TweenInfo.new(timeToMove, Enum.EasingStyle.Linear), {
						CFrame = CFrame.new(targetHover)
					})
					tw:Play()
					tw.Completed:Wait()
				else
					hrp.CFrame = CFrame.new(targetHover)
				end

				-- Brief wait to ensure player position replicates to server
				task.wait(0.05)

				-- Calculate target position directly under character's current position
				local posUnderFeet = Vector3.new(hrp.Position.X, math.max(hrp.Position.Y - 1.5, 5), hrp.Position.Z)

				local downRayParams = RaycastParams.new()
				downRayParams.FilterType = Enum.RaycastFilterType.Exclude
				local excList = {}
				if char then table.insert(excList, char) end
				local boxPart = workspace:FindFirstChild("HipHubDigBoxPart")
				if boxPart then table.insert(excList, boxPart) end
				downRayParams.FilterDescendantsInstances = excList
				downRayParams.IgnoreWater = true

				local downRayHit = workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), downRayParams)
				if downRayHit then
					posUnderFeet = downRayHit.Position
				end

			local PICKAXE_REMOTE_NAME_MAP = {
				["RustyScrapper"] = "Rusty Scrapper",
				["WeatheredWood"] = "Weathered Wood",
				["ChippedStone"] = "Chipped Stone",
				["HardenedIron"] = "Hardened Iron",
				["CopperPick"] = "Copper Pick",
				["ReinforcedSteel"] = "Reinforced Steel",
				["TitaniumSpike"] = "Titanium Spike",
				["FrostbitePick"] = "Frostbite Pick",
				["EmeraldCarver"] = "Emerald Carver",
				["VolcanoBasalt"] = "Volcano Basalt",
				["ObsidianEdge"] = "Obsidian Edge",
				["TempestPick"] = "Tempest Pick",
				["CelestialApex"] = "Celestial Apex",
				["AstralRend"] = "Astral Rend",
				["EclipseFang"] = "Eclipse Fang",
				["NebularThrone"] = "Nebular Throne",
				["Voidreign"] = "Voidreign",
				["Singularity"] = "Singularity",
				["TheTerminus"] = "The Terminus",
				["SharkPickaxe"] = "Shark Pickaxe",
				["DiamondPickaxe"] = "Diamond Pickaxe",
			}

			local function getFormattedPickaxeName(name)
				if not name or name == "" then return "Volcano Basalt" end
				if PICKAXE_REMOTE_NAME_MAP[name] then
					return PICKAXE_REMOTE_NAME_MAP[name]
				end
				return name
			end

			-- Fire Remote DigRequest (exact game contract with spaced pickaxe name)
			pcall(function()
				local digEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("DigRequest")
				if digEvent then
					local formattedPickaxe = getFormattedPickaxeName(selectedDigPickaxe)
					digEvent:FireServer(formattedPickaxe, posUnderFeet)
				end
			end)
		end

		-- Pure Remote Paced Digging loop (0.15s interval)
		task.spawn(function()
			while true do
				task.wait(0.15)
				if autoDigEnabled then
					pcall(function()
						local char = player and player.Character
						local hrp = char and char:FindFirstChild("HumanoidRootPart")
						if hrp then
							local posUnderFeet = Vector3.new(hrp.Position.X, math.max(hrp.Position.Y - 1.5, 5), hrp.Position.Z)

							local downRayParams = RaycastParams.new()
							downRayParams.FilterType = Enum.RaycastFilterType.Exclude
							local excList = {}
							if char then table.insert(excList, char) end
							local boxPart = workspace:FindFirstChild("HipHubDigBoxPart")
							if boxPart then table.insert(excList, boxPart) end
							downRayParams.FilterDescendantsInstances = excList
							downRayParams.IgnoreWater = true

							local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), downRayParams)
							if hit then
								posUnderFeet = hit.Position
							end

							local digEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("DigRequest")
							if digEvent then
								local formattedPickaxe = getFormattedPickaxeName(selectedDigPickaxe)
								digEvent:FireServer(formattedPickaxe, posUnderFeet)
							end
						end
					end)
				end
			end
		end)

			task.spawn(function()
				while true do
					task.wait(0.25)
					if autoDigEnabled then
						local char = player and player.Character
						local hrp = char and char:FindFirstChild("HumanoidRootPart")
						if hrp then
							local ok, err = pcall(function()
								performOutermostAutoDig(function() return autoDigEnabled end, selectedDigPickaxe)
							end)
							if not ok and err then
								warn("[HipHub AutoDig Error]:", err)
							end
						end
					else
						-- Clean up flying hover & box when disabled
						updateDigBoxVisuals()
						syncAutoDigFlyMode()
					end
				end
			end)

			-- State Interface
			_G.HipHubAutomationDigging = {
				getState = function()
					return {
						autoDigEnabled = autoDigEnabled,
						selectedDigPickaxe = selectedDigPickaxe,
						selectedDigMaterial = selectedDigMaterial,
						customDigCenterX = customDigCenterPos and customDigCenterPos.X,
						customDigCenterY = customDigCenterPos and customDigCenterPos.Y,
						customDigCenterZ = customDigCenterPos and customDigCenterPos.Z,
					}
				end,
				setState = function(s)
					if not s then return end
					if s.autoDigEnabled ~= nil then
						autoDigEnabled = (s.autoDigEnabled == true)
						updateAutoDigVisuals()
						updateDigBoxVisuals()
						syncAutoDigFlyMode()
					end
					if s.selectedDigPickaxe ~= nil and tostring(s.selectedDigPickaxe) ~= "" then
						selectedDigPickaxe = tostring(s.selectedDigPickaxe)
						updatePickDropdownVisuals()
					end
					if s.selectedDigMaterial ~= nil and tostring(s.selectedDigMaterial) ~= "" then
						selectedDigMaterial = tostring(s.selectedDigMaterial)
						updateMatDropdownVisuals()
					end
					if s.customDigCenterX and s.customDigCenterY and s.customDigCenterZ then
						customDigCenterPos = Vector3.new(s.customDigCenterX, s.customDigCenterY, s.customDigCenterZ)
						setPosBtn.Text = string.format("Center Set: (%.1f, %.1f, %.1f)", s.customDigCenterX, s.customDigCenterY, s.customDigCenterZ)
						updateDigBoxVisuals()
					end
				end
			}
		end

		------------------------------------------------
		-- 💎 AUTO PLACE CRYSTAL CARD & ENGINE
		------------------------------------------------
		do
			local isAutoPlaceCategoryExpanded = false
			local autoPlaceCategoryCard = Instance.new("Frame")
			autoPlaceCategoryCard.Size = UDim2.new(1, 0, 0, 36)
			autoPlaceCategoryCard.BackgroundColor3 = COLORS.glassCard
			autoPlaceCategoryCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
			autoPlaceCategoryCard.BorderSizePixel = 0
			autoPlaceCategoryCard.ClipsDescendants = true
			autoPlaceCategoryCard.LayoutOrder = 5
			autoPlaceCategoryCard.Parent = mainFrameContent

			refs.applyGlass(autoPlaceCategoryCard, {
				corner = refs.CORNER.medium,
				stroke = true,
				strokeColor = COLORS.borderGlass,
				strokeThickness = 1,
				strokeTransparency = 0.7
			})

			-- Expandable Header Click Button
			local apHeaderBtn = Instance.new("TextButton")
			apHeaderBtn.Size = UDim2.new(1, 0, 0, 36)
			apHeaderBtn.BackgroundTransparency = 1
			apHeaderBtn.Text = ""
			apHeaderBtn.Parent = autoPlaceCategoryCard

			local apAccentBar = Instance.new("Frame")
			apAccentBar.Size = UDim2.new(0, 3, 0, 18)
			apAccentBar.Position = UDim2.new(0, 12, 0, 9)
			apAccentBar.BackgroundColor3 = COLORS.accentCyan
			apAccentBar.BorderSizePixel = 0
			apAccentBar.Parent = apHeaderBtn

			local apAccentCorner = Instance.new("UICorner")
			apAccentCorner.CornerRadius = UDim.new(0, 2)
			apAccentCorner.Parent = apAccentBar

			local apTitle = Instance.new("TextLabel")
			apTitle.Size = UDim2.new(1, -60, 1, 0)
			apTitle.Position = UDim2.new(0, 24, 0, 0)
			apTitle.BackgroundTransparency = 1
			apTitle.Text = "Auto Place Crystal"
			apTitle.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
			apTitle.Font = Enum.Font.GothamBold
			apTitle.TextSize = 13
			apTitle.TextXAlignment = Enum.TextXAlignment.Left
			apTitle.Parent = apHeaderBtn

			local apChevronLabel = Instance.new("TextLabel")
			apChevronLabel.Size = UDim2.new(0, 24, 1, 0)
			apChevronLabel.Position = UDim2.new(1, -30, 0, 0)
			apChevronLabel.BackgroundTransparency = 1
			apChevronLabel.Text = ">"
			apChevronLabel.TextColor3 = COLORS.accentCyan
			apChevronLabel.Font = Enum.Font.GothamBold
			apChevronLabel.TextSize = 13
			apChevronLabel.Parent = apHeaderBtn

			-- Content Container inside Auto Place Crystal Card
			local apContentContainer = Instance.new("Frame")
			apContentContainer.Size = UDim2.new(1, -24, 0, 200)
			apContentContainer.Position = UDim2.new(0, 12, 0, 42)
			apContentContainer.BackgroundTransparency = 1
			apContentContainer.Parent = autoPlaceCategoryCard

			refs.applyListLayout(apContentContainer, 6)

			apHeaderBtn.MouseButton1Click:Connect(function()
				isAutoPlaceCategoryExpanded = not isAutoPlaceCategoryExpanded
				apChevronLabel.Text = isAutoPlaceCategoryExpanded and "v" or ">"
				local targetHeight = isAutoPlaceCategoryExpanded and 215 or 36
				local tween = TweenService:Create(autoPlaceCategoryCard,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, targetHeight)
				})
				tween:Play()
				tween.Completed:Connect(updateMainTabCanvas)
				updateMainTabCanvas()
			end)

			-- 1. Auto Place Crystals Toggle
			local autoPlaceCrystalsEnabled = false
			local apcRow, apcTrack, apcThumb = refs.createGlassToggle(apContentContainer, "Auto Place Crystals", 1)
			local updateAutoPlaceVisuals = function()
				if autoPlaceCrystalsEnabled then
					TweenService:Create(apcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
					TweenService:Create(apcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
						{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
				else
					TweenService:Create(apcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
					TweenService:Create(apcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
						{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
				end
			end
			updateAutoPlaceVisuals()

			apcTrack.MouseButton1Click:Connect(function()
				autoPlaceCrystalsEnabled = not autoPlaceCrystalsEnabled
				updateAutoPlaceVisuals()
				if refs.saveConfig then pcall(refs.saveConfig) end
			end)

			-- 2. Place by Highest Luck Toggle
			local placeByHighestLuckEnabled = false
			local hlRow, hlTrack, hlThumb = refs.createGlassToggle(apContentContainer, "Place by Highest Luck", 2)
			local updatePlaceHighestLuckVisuals = function()
				if placeByHighestLuckEnabled then
					TweenService:Create(hlTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
					TweenService:Create(hlThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
						{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
				else
					TweenService:Create(hlTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
					TweenService:Create(hlThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
						{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
				end
			end
			updatePlaceHighestLuckVisuals()

			hlTrack.MouseButton1Click:Connect(function()
				placeByHighestLuckEnabled = not placeByHighestLuckEnabled
				updatePlaceHighestLuckVisuals()
				if refs.saveConfig then pcall(refs.saveConfig) end
			end)

			-- 3. Place Rarity Filter Dropdown
			local autoPlaceRarityFilters = { ["All"] = true }
			local apRarCard, apRarDropBtn, apRarDropLabel, apRarMenuFrame, apRarSearch, apRarScroll = refs.createGlassDropdown(
				apContentContainer, "Place Rarity Filter", "All", 3
			)
			apRarCard.Size = UDim2.new(1, 0, 0, 32)

			local function getSelectedPlaceRarityLabelText()
				if autoPlaceRarityFilters["All"] or next(autoPlaceRarityFilters) == nil then
					return "All"
				end
				local list = {}
				for _, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }) do
					if autoPlaceRarityFilters[r] then table.insert(list, r) end
				end
				if #list == 0 then return "All" end
				if #list == 1 then return list[1] end
				if #list == 2 then return list[1] .. ", " .. list[2] end
				return tostring(#list) .. " Selected"
			end

			local apRarities = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }
			refs.registerDropdownMenu(apRarDropBtn, apRarMenuFrame)
			local apRarityBinder = refs.bindDropdown(
				apRarDropBtn, apRarMenuFrame, apRarSearch, apRarScroll, apRarities,
				function(opt)
					return autoPlaceRarityFilters[opt] == true
				end,
				function(opt)
					if opt == "All" then
						autoPlaceRarityFilters = { ["All"] = true }
					else
						autoPlaceRarityFilters["All"] = nil
						autoPlaceRarityFilters[opt] = not autoPlaceRarityFilters[opt]
						local hasAny = false
						for _, v in pairs(autoPlaceRarityFilters) do
							if v then hasAny = true break end
						end
						if not hasAny then autoPlaceRarityFilters["All"] = true end
					end
				end,
				function()
					apRarDropLabel.Text = getSelectedPlaceRarityLabelText()
				end
			)

			local function updateApRarityVisuals()
				apRarDropLabel.Text = getSelectedPlaceRarityLabelText()
				apRarityBinder.updateOptionVisuals()
			end

			-- 4. Action Button: Place Crystals Now
			local apActionBtn = Instance.new("TextButton")
			apActionBtn.Size = UDim2.new(1, 0, 0, 32)
			apActionBtn.BackgroundColor3 = COLORS.accentCyan
			apActionBtn.BackgroundTransparency = 0.15
			apActionBtn.Text = "Place Selected Crystals Now"
			apActionBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			apActionBtn.Font = Enum.Font.GothamBold
			apActionBtn.TextSize = 12
			apActionBtn.LayoutOrder = 4
			apActionBtn.Parent = apContentContainer

			local apActionCorner = Instance.new("UICorner")
			apActionCorner.CornerRadius = refs.CORNER.small
			apActionCorner.Parent = apActionBtn

			-- Core Placement Helpers & Logic (Targets Dead Center Ground Floor of Workspace.Things.Plots.Slots[Player].Region)
			local function getPlayerPlotCenter()
				local p = player or game:GetService("Players").LocalPlayer
				if not p then return nil end

				local things = workspace:FindFirstChild("Things")
				local plotsFolder = things and things:FindFirstChild("Plots") or workspace:FindFirstChild("Plots")
				if plotsFolder then
					local slots = plotsFolder:FindFirstChild("Slots") or plotsFolder
					local myPlot = slots:FindFirstChild(p.Name)
					if not myPlot then
						for _, slot in ipairs(slots:GetChildren()) do
							if string.lower(slot.Name) == string.lower(p.Name) or slot:GetAttribute("Owner") == p.Name or slot:GetAttribute("UserId") == p.UserId then
								myPlot = slot
								break
							end
						end
					end

					if myPlot then
						local regionPart = myPlot:FindFirstChild("Region")
						if regionPart and regionPart:IsA("BasePart") then
							-- Raycast down to find exact dirt floor height
							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							local filterList = { regionPart }
							if p.Character then table.insert(filterList, p.Character) end
							rayParams.FilterDescendantsInstances = filterList

							local rayStart = Vector3.new(regionPart.Position.X, regionPart.Position.Y + 50, regionPart.Position.Z)
							local rayHit = workspace:Raycast(rayStart, Vector3.new(0, -300, 0), rayParams)
							local groundY = rayHit and rayHit.Position.Y or (regionPart.Position.Y - (regionPart.Size.Y * 0.5))

							return Vector3.new(regionPart.Position.X, groundY, regionPart.Position.Z)
						end

						local spawnPart = myPlot:FindFirstChild("Spawn")
						if spawnPart and spawnPart:IsA("BasePart") then
							return spawnPart.Position
						end

						local centerPos = nil
						pcall(function()
							centerPos = myPlot:GetPivot().Position
						end)
						if centerPos then return centerPos end
					end
				end

				local char = p.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				return hrp and hrp.Position or nil
			end

			local function matchesPlaceRarity(tool)
				if not tool or not tool:IsA("Tool") then return false end

				local hasAnyEnabled = false
				if type(autoPlaceRarityFilters) == "table" then
					for r, isSel in pairs(autoPlaceRarityFilters) do
						if isSel == true then
							hasAnyEnabled = true
							break
						end
					end
				end

				if not hasAnyEnabled or autoPlaceRarityFilters["All"] == true then
					return true
				end

				local tName = string.lower(tool.Name)
				local attrStr = ""
				pcall(function()
					for aName, aVal in pairs(tool:GetAttributes()) do
						attrStr = attrStr .. " " .. string.lower(tostring(aName)) .. " " .. string.lower(tostring(aVal))
					end
				end)
				local combinedText = tName .. " " .. attrStr

				local filterMap = {
					["common"] = { "_t1", "t1", "common", "tier1", "tier 1" },
					["uncommon"] = { "_t2", "t2", "uncommon", "tier2", "tier 2" },
					["rare"] = { "_t3", "t3", "rare", "tier3", "tier 3" },
					["epic"] = { "_t4", "t4", "epic", "tier4", "tier 4" },
					["legendary"] = { "_t5", "t5", "legendary", "tier5", "tier 5" },
					["mythical"] = { "_t6", "t6", "mythical", "mythic", "tier6", "tier 6" },
					["mythic"] = { "_t6", "t6", "mythical", "mythic", "tier6", "tier 6" },
				}

				for selRarity, isSel in pairs(autoPlaceRarityFilters) do
					if isSel == true then
						local rarityLower = string.lower(tostring(selRarity))
						local kws = filterMap[rarityLower]
						if kws then
							for _, kw in ipairs(kws) do
								if string.find(combinedText, kw, 1, true) then return true end
							end
						end
						if string.find(combinedText, rarityLower, 1, true) then return true end
					end
				end

				return false
			end

			local function executeAutoPlaceCrystals()
				local p = player or game:GetService("Players").LocalPlayer
				if not p then return end

				local char = p.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not hrp or not hum then return end

				local rems = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
				local placeRem = rems and rems:FindFirstChild("PlotPlaceRequest")
				if not placeRem then return end

				local plotCenter = getPlayerPlotCenter()
				if not plotCenter then return end

				local targetTools = {}
				local function scanTools(container)
					if not container then return end
					for _, child in ipairs(container:GetChildren()) do
						if child:IsA("Tool") then
							local hasTier = child:GetAttribute("Tier") ~= nil
							local wKg = child:GetAttribute("WeightKg")
							local nameLower = string.lower(child.Name)
							local isCrystal = hasTier or wKg ~= nil or string.find(nameLower, "crystal", 1, true) or string.find(nameLower, "kg", 1, true) or string.find(nameLower, "[m]", 1, true) or string.find(nameLower, "[s]", 1, true) or string.find(nameLower, "[l]", 1, true)
							if isCrystal and matchesPlaceRarity(child) then
								table.insert(targetTools, child)
							end
						end
					end
				end

				scanTools(p:FindFirstChildOfClass("Backpack") or p:FindFirstChild("Backpack"))
				scanTools(char)

				if #targetTools == 0 then return end

				-- Helper to calculate crystal luck value for sorting
				local function getCrystalLuckValue(tool)
					if not tool then return 0 end
					local luck = 0
					pcall(function()
						local lAttr = tool:GetAttribute("Luck") or tool:GetAttribute("LuckMultiplier") or tool:GetAttribute("LuckMult") or tool:GetAttribute("LuckBoost") or tool:GetAttribute("Multiplier") or tool:GetAttribute("Boost")
						if typeof(lAttr) == "number" then
							luck = lAttr
						elseif typeof(lAttr) == "string" then
							luck = tonumber(string.match(lAttr, "%d+%.?%d*")) or 0
						end
					end)

					local tier = tool:GetAttribute("Tier") or 0
					if typeof(tier) ~= "number" then tier = 0 end
					if tier == 0 then
						local tName = string.lower(tool.Name)
						if string.find(tName, "mythic", 1, true) or string.find(tName, "_t6", 1, true) or string.find(tName, "tier 6", 1, true) then tier = 6
						elseif string.find(tName, "legendary", 1, true) or string.find(tName, "_t5", 1, true) or string.find(tName, "tier 5", 1, true) then tier = 5
						elseif string.find(tName, "epic", 1, true) or string.find(tName, "_t4", 1, true) or string.find(tName, "tier 4", 1, true) then tier = 4
						elseif string.find(tName, "rare", 1, true) or string.find(tName, "_t3", 1, true) or string.find(tName, "tier 3", 1, true) then tier = 3
						elseif string.find(tName, "uncommon", 1, true) or string.find(tName, "_t2", 1, true) or string.find(tName, "tier 2", 1, true) then tier = 2
						elseif string.find(tName, "common", 1, true) or string.find(tName, "_t1", 1, true) or string.find(tName, "tier 1", 1, true) then tier = 1
						end
					end

					local wKg = tool:GetAttribute("WeightKg") or tool:GetAttribute("Weight") or 0
					if typeof(wKg) ~= "number" or wKg <= 0 then
						local matchKg = string.match(tool.Name, "(%d+%.?%d*)%s*kg")
						wKg = matchKg and tonumber(matchKg) or 0
					end

					return (luck * 1000000) + (tier * 100000) + wKg
				end

				-- Sort crystals by highest luck / tier / weight first if Place by Highest Luck is enabled
				if placeByHighestLuckEnabled then
					table.sort(targetTools, function(a, b)
						return getCrystalLuckValue(a) > getCrystalLuckValue(b)
					end)
				end

				-- Stand directly in the middle of your plot floor
				local targetStandCF = CFrame.new(plotCenter.X, plotCenter.Y + 3.0, plotCenter.Z)
				if (hrp.Position - plotCenter).Magnitude > 12 then
					hrp.CFrame = targetStandCF
					task.wait(0.2)
				end

				-- Generate placement sequence: Phase 1 Center H-Shape -> Phase 2 Outer Perimeter Fence Lines (picture style)
				local function generatePlotPlacementOffsets(totalCount)
					local offsets = {}
					local hSpacing = 3.5
					local barX = 7.0 -- Center H-Shape

					-- 1. Phase 1: Center H-Shape (17 points)
					-- Left vertical leg
					for dz = -10.5, 10.5, hSpacing do
						table.insert(offsets, Vector3.new(-barX, 0, dz))
					end
					-- Right vertical leg
					for dz = -10.5, 10.5, hSpacing do
						table.insert(offsets, Vector3.new(barX, 0, dz))
					end
					-- Center crossbar
					for dx = -barX + hSpacing, barX - hSpacing, hSpacing do
						table.insert(offsets, Vector3.new(dx, 0, 0))
					end

					-- 2. Phase 2: Outer Perimeter Border (Far Outer Fence Lines - near wooden fence boundary)
					local borderDist = 35.0
					pcall(function()
						local p = player or game:GetService("Players").LocalPlayer
						local things = workspace:FindFirstChild("Things")
						local plots = things and things:FindFirstChild("Plots") or workspace:FindFirstChild("Plots")
						local slots = plots and (plots:FindFirstChild("Slots") or plots)
						local myPlot = slots and slots:FindFirstChild(p.Name)
						local regionPart = myPlot and myPlot:FindFirstChild("Region")
						if regionPart and regionPart:IsA("BasePart") then
							local halfW = (regionPart.Size.X * 0.5) - 3.5
							if halfW > 20 then borderDist = halfW end
						end
					end)

					local bSpacing = 3.5

					-- Bottom fence line
					for dx = -borderDist, borderDist, bSpacing do
						table.insert(offsets, Vector3.new(dx, 0, borderDist))
					end
					-- Top fence line
					for dx = -borderDist, borderDist, bSpacing do
						table.insert(offsets, Vector3.new(dx, 0, -borderDist))
					end
					-- Left fence line
					for dz = -borderDist + bSpacing, borderDist - bSpacing, bSpacing do
						table.insert(offsets, Vector3.new(-borderDist, 0, dz))
					end
					-- Right fence line
					for dz = -borderDist + bSpacing, borderDist - bSpacing, bSpacing do
						table.insert(offsets, Vector3.new(borderDist, 0, dz))
					end

					-- 3. Phase 3: Secondary Inner Perimeter Ring Rows (stepping inward towards center)
					local ringDist = borderDist - 5.0
					while #offsets < totalCount and ringDist > 11.0 do
						for dx = -ringDist, ringDist, bSpacing do
							table.insert(offsets, Vector3.new(dx, 0, ringDist))
						end
						for dx = -ringDist, ringDist, bSpacing do
							table.insert(offsets, Vector3.new(dx, 0, -ringDist))
						end
						for dz = -ringDist + bSpacing, ringDist - bSpacing, bSpacing do
							table.insert(offsets, Vector3.new(-ringDist, 0, dz))
						end
						for dz = -ringDist + bSpacing, ringDist - bSpacing, bSpacing do
							table.insert(offsets, Vector3.new(ringDist, 0, dz))
						end
						ringDist = ringDist - 4.5
					end

					return offsets
				end

				local placeOffsets = generatePlotPlacementOffsets(#targetTools)

				for idx, tool in ipairs(targetTools) do
					if not tool or not tool.Parent then continue end

					-- Equip tool to Character
					if tool.Parent ~= char then
						pcall(function()
							hum:EquipTool(tool)
						end)
						task.wait(0.12)
					end

					local offset = placeOffsets[idx] or Vector3.new(0, 0, 0)
					local placePos = Vector3.new(plotCenter.X + offset.X, plotCenter.Y + 0.1, plotCenter.Z + offset.Z)

					pcall(function()
						placeRem:FireServer(
							tool.Name,
							placePos,
							0,
							tool
						)
					end)
					task.wait(0.2)
				end
			end

			apActionBtn.MouseButton1Click:Connect(function()
				pcall(executeAutoPlaceCrystals)
			end)

			-- Loop for Auto Place Crystal
			task.spawn(function()
				while true do
					task.wait(2.5)
					if autoPlaceCrystalsEnabled then
						pcall(executeAutoPlaceCrystals)
					end
				end
			end)

			_G.HipHubAutomationMining = {
				getState = function()
					return {
						autoFarmCrystalsEnabled = autoFarmCrystalsEnabled,
						autoFarmRunesEnabled = autoFarmRunesEnabled,
						autoFarmNoclipEnabled = autoFarmNoclipEnabled,
						autoSellOnFullEnabled = autoSellOnFullEnabled,
						autoFarmRarityFilters = autoFarmRarityFilters,
						autoFarmSizeFilters = autoFarmSizeFilters,
					}
				end,
				setState = function(s)
					if not s then return end
					if s.autoFarmCrystalsEnabled ~= nil then
						autoFarmCrystalsEnabled = (s.autoFarmCrystalsEnabled == true)
						updateAutoFarmVisuals()
						updateAutomationNoclipEngine()
					end
					if s.autoFarmRunesEnabled ~= nil then
						autoFarmRunesEnabled = (s.autoFarmRunesEnabled == true)
						updateAutoMineRunesVisuals()
					end
					if s.autoFarmNoclipEnabled ~= nil then
						autoFarmNoclipEnabled = (s.autoFarmNoclipEnabled == true)
						updateAutoFarmNoclipVisuals()
						updateAutomationNoclipEngine()
					end
					if s.autoSellOnFullEnabled ~= nil then
						autoSellOnFullEnabled = (s.autoSellOnFullEnabled == true)
						updateAutoSellFullVisuals()
					end
					if s.autoFarmRarityFilters ~= nil then
						if type(s.autoFarmRarityFilters) == "table" then
							autoFarmRarityFilters = s.autoFarmRarityFilters
						elseif type(s.autoFarmRarityFilters) == "string" then
							autoFarmRarityFilters = { [s.autoFarmRarityFilters] = true }
						end
						updateAmRarityVisuals()
					elseif s.autoFarmRarityFilter ~= nil then
						autoFarmRarityFilters = { [tostring(s.autoFarmRarityFilter)] = true }
						updateAmRarityVisuals()
					end
					if s.autoFarmSizeFilters ~= nil then
						if type(s.autoFarmSizeFilters) == "table" then
							autoFarmSizeFilters = s.autoFarmSizeFilters
						elseif type(s.autoFarmSizeFilters) == "string" then
							autoFarmSizeFilters = { [s.autoFarmSizeFilters] = true }
						end
						updateAmSizeVisuals()
					elseif s.autoFarmSizeFilter ~= nil then
						autoFarmSizeFilters = { [tostring(s.autoFarmSizeFilter)] = true }
						updateAmSizeVisuals()
					end
				end
			}

			_G.HipHubAutomationBoulder = {
				getState = function()
					return {
						autoFarmBouldersEnabled = autoFarmBouldersEnabled,
						boulderRarityFilters = boulderRarityFilters,
						selectedBoulderBomb = selectedBoulderBomb,
					}
				end,
				setState = function(s)
					if not s then return end
					if s.autoFarmBouldersEnabled ~= nil then
						autoFarmBouldersEnabled = (s.autoFarmBouldersEnabled == true)
						if updateAutoFarmBoulderVisuals then updateAutoFarmBoulderVisuals() end
						if autoFarmBouldersEnabled then
							pcall(function()
								if _G.HipHubMisc and _G.HipHubMisc.setState then
									_G.HipHubMisc.setState({ flyEnabled = true })
								end
								if _G.HipHubSettings and _G.HipHubSettings.setState then
									_G.HipHubSettings.setState({ noclip = true })
								end
							end)
						end
					end
					if s.boulderRarityFilters ~= nil then
						if type(s.boulderRarityFilters) == "table" then
							boulderRarityFilters = s.boulderRarityFilters
						elseif type(s.boulderRarityFilters) == "string" then
							boulderRarityFilters = { [s.boulderRarityFilters] = true }
						end
					end
					if s.selectedBoulderBomb ~= nil then
						selectedBoulderBomb = tostring(s.selectedBoulderBomb)
					end
				end
			}

			_G.HipHubAutoPlaceCrystal = {
				getState = function()
					return {
						autoPlaceCrystalsEnabled = autoPlaceCrystalsEnabled,
						placeByHighestLuckEnabled = placeByHighestLuckEnabled,
						autoPlaceRarityFilters = autoPlaceRarityFilters,
					}
				end,
				setState = function(s)
					if not s then return end
					if s.autoPlaceCrystalsEnabled ~= nil then
						autoPlaceCrystalsEnabled = (s.autoPlaceCrystalsEnabled == true)
						updateAutoPlaceVisuals()
					end
					if s.placeByHighestLuckEnabled ~= nil then
						placeByHighestLuckEnabled = (s.placeByHighestLuckEnabled == true)
						updatePlaceHighestLuckVisuals()
					end
					if s.autoPlaceRarityFilters ~= nil then
						if type(s.autoPlaceRarityFilters) == "table" then
							autoPlaceRarityFilters = s.autoPlaceRarityFilters
						elseif type(s.autoPlaceRarityFilters) == "string" then
							autoPlaceRarityFilters = { [s.autoPlaceRarityFilters] = true }
						end
						updateApRarityVisuals()
					end
				end
			}
		end
	end

	------------------------------------------------
	-- 🧠 BRAINROT AUTO-CATCHER INTEGRATION
	------------------------------------------------
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BrainrotDir = ReplicatedStorage:WaitForChild("Brainrot", 5)

	if BrainrotDir then
		task.spawn(function()
			local RotChillerDir = BrainrotDir:WaitForChild("RotChiller", 5)
			local ServerDir = RotChillerDir and RotChillerDir:WaitForChild("Server", 5)
			if not ServerDir then return end

			local CatchRequest = ServerDir:WaitForChild("CatchRequest", 5)
			local GetInitialContainerStates = ServerDir:WaitForChild("GetInitialContainerStates", 5)
			local UpdateEvent = ServerDir:WaitForChild("Update", 5)
			if not (CatchRequest and GetInitialContainerStates and UpdateEvent) then return end

			local Core = nil
			pcall(function()
				Core = require(ReplicatedStorage.Brainrot.Core)
			end)

			-- State Variables
			local containers = {}
			local activeRots = {}
			local caughtCount = 0
			local battlesStarted = 0
			local autoCatchEnabled = false
			local currentlyCatching = nil
			local uiNeedsUpdate = false

			-- Filters State
			local rarityNames = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

			-- Helper functions
			local function countTable(t)
				local c = 0
				for _ in pairs(t) do c = c + 1 end
				return c
			end

			local function getRotRarity(name)
				if Core and Core.Species and Core.Species[name] then
					local species = Core.Species[name]
					if species.Rarity then
						if typeof(species.Rarity) == "table" and species.Rarity.Name then
							return species.Rarity.Name
						elseif typeof(species.Rarity) == "string" then
							return species.Rarity
						elseif typeof(species.Rarity) == "table" and species.Rarity.Value then
							local valueMap = { [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] =
							"Legendary", [6] = "Mythical" }
							return valueMap[species.Rarity.Value] or tostring(species.Rarity.Value)
						end
					end
					if species.RarityValue then
						local valueMap = { [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] =
						"Legendary", [6] = "Mythical" }
						return valueMap[species.RarityValue] or tostring(species.RarityValue)
					end
				end
				return "Common"
			end

			local function matchesRarityFilter(rotName)
				local filter = rarityNames[selectedRarityIndex]
				if filter == "All" then return true end

				local rotRarity = getRotRarity(rotName)
				local rLower = string.lower(tostring(rotRarity))
				local fLower = string.lower(filter)

				if rLower == fLower then return true end

				local rarityValueMap = {
					common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5, mythical = 6
				}
				local mappedValue = rarityValueMap[fLower]
				if mappedValue and Core and Core.Species and Core.Species[rotName] then
					local species = Core.Species[rotName]
					if species.Rarity and species.Rarity.Value == mappedValue then
						return true
					end
				end

				return false
			end

			-- Async Staff / Admin Caching
			local staffCache = {}
			local function cachePlayerStaff(p)
				if p == player then return end

				local isStaff = false
				if p.UserId == game.CreatorId then
					isStaff = true
				else
					task.spawn(function()
						local success, inGroup = pcall(function()
							return p:IsInGroup(1200769)
						end)
						if success and inGroup then
							staffCache[p] = true
						end
					end)
				end
				staffCache[p] = isStaff
			end

			for _, p in ipairs(Players:GetPlayers()) do
				cachePlayerStaff(p)
			end
			Players.PlayerAdded:Connect(cachePlayerStaff)
			Players.PlayerRemoving:Connect(function(p)
				staffCache[p] = nil
			end)

			-- Find sidebar & tabContainer dynamically
			local tabContainer = nil
			local sidebar = refs.profileCard and refs.profileCard.Parent
			if sidebar then
				for _, child in ipairs(sidebar:GetChildren()) do
					if child:IsA("Frame") and child ~= refs.profileCard and child.Name == "" then
						if child.Size.Y.Offset == -60 then
							tabContainer = child
							break
						end
					end
				end
			end

			if not tabContainer then return end

			-- Create custom tab
			local tabName = "Auto Catch"
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, 0, 0, 30)
			button.BackgroundColor3 = COLORS.glassSurface
			button.BackgroundTransparency = 1
			button.BorderSizePixel = 0
			button.ZIndex = 3
			button.Text = "   🧠  " .. tabName
			button.TextColor3 = COLORS.textSecondary
			button.Font = Enum.Font.GothamMedium
			button.TextSize = 12
			button.TextXAlignment = Enum.TextXAlignment.Left
			button.LayoutOrder = 3
			button.Parent = tabContainer

			refs.applyGlass(button, { corner = refs.CORNER.small })

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

			refs.tabButtons[tabName] = button

			local contentArea = refs.mainFrameContent.Parent
			local tabFrame = Instance.new("ScrollingFrame")
			tabFrame.Size = UDim2.new(1, 0, 1, 0)
			tabFrame.BackgroundTransparency = 1
			tabFrame.BorderSizePixel = 0
			tabFrame.ScrollBarThickness = 3
			tabFrame.ScrollBarImageColor3 = COLORS.accentCyan
			tabFrame.ScrollBarImageTransparency = 0.4
			tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
			tabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			tabFrame.ClipsDescendants = true
			tabFrame.Visible = false
			tabFrame.ZIndex = 2
			tabFrame.Parent = contentArea

			refs.applyPadding(tabFrame, 16, 16, 16, 16)
			refs.applyListLayout(tabFrame, 10)

			refs.tabs[tabName] = {
				Frame = tabFrame,
				Button = button,
				Indicator = indicator,
			}

			button.MouseButton1Click:Connect(function()
				refs.selectTab(tabName)
			end)

			button.MouseEnter:Connect(function()
				if refs.tabs[tabName].Indicator.Visible == false or button.BackgroundTransparency == 1 then
					TweenService:Create(button, TweenInfo.new(0.15), {
						BackgroundColor3 = COLORS.glassHover,
						BackgroundTransparency = 0.5,
					}):Play()
				end
			end)
			button.MouseLeave:Connect(function()
				if refs.tabs[tabName].Indicator.Visible == false or button.BackgroundTransparency == 1 then
					TweenService:Create(button, TweenInfo.new(0.15), {
						BackgroundColor3 = COLORS.glassSurface,
						BackgroundTransparency = 1,
					}):Play()
				end
			end)

			-- Control Card (Start/Stop, Stats)
			local controlCard = Instance.new("Frame")
			controlCard.Size = UDim2.new(1, 0, 0, 80)
			controlCard.BackgroundColor3 = COLORS.glassCard
			controlCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
			controlCard.BorderSizePixel = 0
			controlCard.Parent = tabFrame

			refs.applyGlass(controlCard, {
				corner = refs.CORNER.medium,
				stroke = true,
				strokeColor = COLORS.borderGlass,
				strokeThickness = 1,
				strokeTransparency = 0.7,
				gradient = true,
				gradientRotation = 120
			})

			local statsLabel = Instance.new("TextLabel")
			statsLabel.Size = UDim2.new(0.6, 0, 1, 0)
			statsLabel.Position = UDim2.new(0, 12, 0, 0)
			statsLabel.BackgroundTransparency = 1
			statsLabel.Text = "Status: <font color='#ff4d4d'>Inactive</font>\nCaught: 0 | Battles: 0"
			statsLabel.TextColor3 = COLORS.textSecondary
			statsLabel.TextSize = 12
			statsLabel.RichText = true
			statsLabel.Font = Enum.Font.GothamMedium
			statsLabel.TextXAlignment = Enum.TextXAlignment.Left
			statsLabel.LineHeight = 1.3
			statsLabel.Parent = controlCard

			local toggleBtn = Instance.new("TextButton")
			toggleBtn.Size = UDim2.new(0, 120, 0, 35)
			toggleBtn.Position = UDim2.new(1, -132, 0.5, -17.5)
			toggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
			toggleBtn.Text = "START"
			toggleBtn.TextColor3 = COLORS.textWhite
			toggleBtn.TextSize = 13
			toggleBtn.Font = Enum.Font.GothamBold
			toggleBtn.Parent = controlCard

			local toggleCorner = Instance.new("UICorner")
			toggleCorner.CornerRadius = refs.CORNER.small
			toggleCorner.Parent = toggleBtn

			-- Settings Card
			local settingsCard = Instance.new("Frame")
			settingsCard.Size = UDim2.new(1, 0, 0, 172)
			settingsCard.BackgroundColor3 = COLORS.glassCard
			settingsCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
			settingsCard.BorderSizePixel = 0
			settingsCard.Parent = tabFrame

			refs.applyGlass(settingsCard, {
				corner = refs.CORNER.medium,
				stroke = true,
				strokeColor = COLORS.borderGlass,
				strokeThickness = 1,
				strokeTransparency = 0.7
			})

			refs.applyListLayout(settingsCard, 8)
			refs.applyPadding(settingsCard, 10, 10, 10, 10)

			-- UI builders
			local function createTextBoxRow(labelText, defaultValue)
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 32)
				row.BackgroundColor3 = COLORS.glassSurface
				row.BackgroundTransparency = 0.25
				row.BorderSizePixel = 0

				refs.applyGlass(row, {
					corner = refs.CORNER.small,
					stroke = true,
					strokeColor = COLORS.borderGlass,
					strokeThickness = 1,
					strokeTransparency = 0.85
				})

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(0.6, 0, 1, 0)
				label.Position = UDim2.new(0, 12, 0, 0)
				label.BackgroundTransparency = 1
				label.Text = labelText
				label.TextColor3 = COLORS.textPrimary
				label.Font = Enum.Font.GothamMedium
				label.TextSize = 12
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local input = Instance.new("TextBox")
				input.Size = UDim2.new(0, 60, 0, 22)
				input.Position = UDim2.new(1, -72, 0.5, -11)
				input.BackgroundColor3 = Color3.fromRGB(30, 34, 54)
				input.Text = defaultValue
				input.TextColor3 = COLORS.textWhite
				input.TextSize = 11
				input.Font = Enum.Font.GothamBold
				input.Parent = row

				local inputCorner = Instance.new("UICorner")
				inputCorner.CornerRadius = refs.CORNER.small
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

				refs.applyGlass(row, {
					corner = refs.CORNER.small,
					stroke = true,
					strokeColor = COLORS.borderGlass,
					strokeThickness = 1,
					strokeTransparency = 0.85
				})

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(0.5, 0, 1, 0)
				label.Position = UDim2.new(0, 12, 0, 0)
				label.BackgroundTransparency = 1
				label.Text = labelText
				label.TextColor3 = COLORS.textPrimary
				label.Font = Enum.Font.GothamMedium
				label.TextSize = 12
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Parent = row

				local button = Instance.new("TextButton")
				button.Size = UDim2.new(0, 100, 0, 22)
				button.Position = UDim2.new(1, -112, 0.5, -11)
				button.BackgroundColor3 = Color3.fromRGB(30, 34, 54)
				button.Text = defaultButtonText
				button.TextColor3 = COLORS.textWhite
				button.TextSize = 11
				button.Font = Enum.Font.GothamBold
				button.Parent = row

				local buttonCorner = Instance.new("UICorner")
				buttonCorner.CornerRadius = refs.CORNER.small
				buttonCorner.Parent = button

				local buttonStroke = Instance.new("UIStroke")
				buttonStroke.Color = COLORS.borderGlass
				buttonStroke.Thickness = 1
				buttonStroke.Parent = button

				return row, button
			end

			local delayRow, delayInput = createTextBoxRow("Catch Delay (seconds)", tostring(catchDelay))
			delayRow.Parent = settingsCard

			local levelRow, levelInput = createTextBoxRow("Min Level Filter", tostring(minLevelFilter))
			levelRow.Parent = settingsCard

			local rarityRow, rarityBtn = createButtonRow("Rarity Filter", rarityNames[selectedRarityIndex])
			rarityRow.Parent = settingsCard

			local safeRow, safeTrack, safeThumb = refs.createGlassToggle(settingsCard, "Anti-Staff Safety", 0)
			safeRow.Size = UDim2.new(1, 0, 0, 32)

			local function updateSafeModeVisuals()
				if safeModeEnabled then
					TweenService:Create(safeTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
					TweenService:Create(safeThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
						{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
				else
					TweenService:Create(safeTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
					TweenService:Create(safeThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
						{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
				end
			end
			updateSafeModeVisuals()

			safeTrack.MouseButton1Click:Connect(function()
				safeModeEnabled = not safeModeEnabled
				updateSafeModeVisuals()
				pcall(saveConfig)
			end)

			-- Detected Brainrots Card
			local rotsCard = Instance.new("Frame")
			rotsCard.Size = UDim2.new(1, 0, 0, 200)
			rotsCard.BackgroundColor3 = COLORS.glassCard
			rotsCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
			rotsCard.BorderSizePixel = 0
			rotsCard.Parent = tabFrame

			refs.applyGlass(rotsCard, {
				corner = refs.CORNER.medium,
				stroke = true,
				strokeColor = COLORS.borderGlass,
				strokeThickness = 1,
				strokeTransparency = 0.7
			})

			local rotsTitle = Instance.new("TextLabel")
			rotsTitle.Size = UDim2.new(1, -24, 0, 26)
			rotsTitle.Position = UDim2.new(0, 12, 0, 8)
			rotsTitle.BackgroundTransparency = 1
			rotsTitle.Text = "DETECTED BRAINROTS"
			rotsTitle.TextColor3 = COLORS.accentCyan
			rotsTitle.Font = Enum.Font.GothamBold
			rotsTitle.TextSize = 10
			rotsTitle.TextXAlignment = Enum.TextXAlignment.Left
			rotsTitle.Parent = rotsCard

			local scrollList = Instance.new("ScrollingFrame")
			scrollList.Size = UDim2.new(1, -24, 1, -40)
			scrollList.Position = UDim2.new(0, 12, 0, 32)
			scrollList.BackgroundTransparency = 1
			scrollList.BorderSizePixel = 0
			scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
			scrollList.ScrollBarThickness = 3
			scrollList.ScrollBarImageColor3 = COLORS.accentCyan
			scrollList.ScrollBarImageTransparency = 0.4
			scrollList.Parent = rotsCard

			refs.applyListLayout(scrollList, 6)

			-- Battle Detection
			local battleGuiRef = nil
			local function getBattleGui()
				if battleGuiRef and battleGuiRef.Parent then return battleGuiRef end
				local playerGui = player:WaitForChild("PlayerGui", 2)
				if not playerGui then return nil end
				for _, g in ipairs(playerGui:GetChildren()) do
					if g:IsA("ScreenGui") then
						local nameLower = string.lower(g.Name)
						if string.find(nameLower, "battle") or string.find(nameLower, "combat") or string.find(nameLower, "fight") then
							battleGuiRef = g
							return g
						end
					end
				end
				return nil
			end

			local function isPlayerInBattle()
				local g = getBattleGui()
				if g and g.Enabled then return true end

				local character = player.Character
				if character then
					if character:GetAttribute("InBattle") == true or character:GetAttribute("Battling") == true then
						return true
					end
					if character:FindFirstChild("BattleTag") or character:FindFirstChild("InBattle") then
						return true
					end
				end
				return false
			end

			local function updateStats()
				local statusText
				if not autoCatchEnabled then
					statusText = "<font color='#ff4d4d'>Inactive</font>"
				elseif isPlayerInBattle() then
					statusText = "<font color='#ffb84d'>In Battle</font>"
				else
					statusText = "<font color='#4dff4d'>Scanning...</font>"
				end
				statsLabel.Text = "Status: " ..
				statusText .. "\nCaught: " .. tostring(caughtCount) .. " | Battles: " .. tostring(battlesStarted)
			end

			-- Spawn/Despawn Logic
			local function findRotModelInWorkspace(rot)
				local success, found = pcall(function()
					return workspace:FindFirstChild(rot.ID, true)
				end)
				if success and found then return found end

				success, found = pcall(function()
					return workspace:FindFirstChild(rot.ContainerID, true)
				end)
				if success and found then return found end

				local container = containers[rot.ContainerID]
				local containerPos = container and container.CFrame and container.CFrame.Position
				if containerPos and rot.Name then
					local closestModel = nil
					local closestDist = 50

					local searchSuccess, children = pcall(function() return workspace:GetChildren() end)
					if searchSuccess and children then
						for _, child in ipairs(children) do
							if child:IsA("Model") and string.lower(child.Name) == string.lower(rot.Name) then
								local primary = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
								if primary then
									local dist = (primary.Position - containerPos).Magnitude
									if dist < closestDist then
										closestDist = dist
										closestModel = child
									end
								end
							end
						end
					end
					if closestModel then return closestModel end
				end
				return nil
			end

			local function getRotCFrame(rot)
				local model = findRotModelInWorkspace(rot)
				if model then
					local success, pivot = pcall(function()
						if model:IsA("Model") then
							return model:GetPivot()
						elseif model:IsA("BasePart") then
							return model.CFrame
						end
					end)
					if success and pivot then return pivot end
				end

				local container = containers[rot.ContainerID]
				if container then
					if container.CFrame then return container.CFrame end
					local success, foundInstance = pcall(function()
						return workspace:FindFirstChild(rot.ContainerID, true)
					end)
					if success and foundInstance then
						if foundInstance:IsA("BasePart") then
							container.CFrame = foundInstance.CFrame
							return foundInstance.CFrame
						elseif foundInstance:IsA("Model") then
							local pivot = foundInstance:GetPivot()
							container.CFrame = pivot
							return pivot
						end
					end
				end
				return nil
			end

			local function teleportToRot(rot)
				local cframe = getRotCFrame(rot)
				if cframe then
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.CFrame = cframe + Vector3.new(0, 2.5, 0)
						task.wait(0.25)
					end
				end
			end

			local catchRot -- Forward decl
			local function addRot(containerId, rotData, fallbackId)
				local rotId = rotData and (rotData.ID or fallbackId)
				if not rotId then return end

				if not containers[containerId] then
					containers[containerId] = {
						ID = containerId,
						Rots = {}
					}
				end

				local name = "Unknown"
				local level = 1
				if rotData.RotInstance then
					if typeof(rotData.RotInstance) == "table" then
						name = rotData.RotInstance.Name or "Unknown"
						level = tonumber(rotData.RotInstance.Level) or 1
					elseif typeof(rotData.RotInstance) == "Instance" then
						name = rotData.RotInstance.Name or "Unknown"
						local success, lv = pcall(function()
							return rotData.RotInstance:GetAttribute("Level") or rotData.RotInstance.Level
						end)
						if success and lv then
							if typeof(lv) == "Instance" and lv:IsA("ValueObject") then
								level = lv.Value
							else
								level = tonumber(lv) or 1
							end
						end
					end
				end

				local rarity = getRotRarity(name)
				local rot = {
					ID = rotId,
					Seed = rotData.Seed,
					RotInstance = rotData.RotInstance,
					DespawnTime = rotData.DespawnTime,
					ContainerID = containerId,
					Name = name,
					Level = level,
					Rarity = rarity
				}

				containers[containerId].Rots[rotId] = rot
				activeRots[rotId] = rot
			end

			local function removeRot(containerId, rotDataOrId)
				local rotId = typeof(rotDataOrId) == "table" and rotDataOrId.ID or rotDataOrId
				if not rotId then return end

				if containers[containerId] and containers[containerId].Rots[rotId] then
					containers[containerId].Rots[rotId] = nil
				end
				activeRots[rotId] = nil
			end

			-- Dynamic rows recycling
			local uiRowsCache = {}
			local function updateUIList()
				if not tabFrame.Visible then return end

				local character = player.Character
				local playerPos = character and character.PrimaryPart and character.PrimaryPart.Position or Vector3.zero

				local sortedList = {}
				for rotId, rot in pairs(activeRots) do
					local rotLevel = rot.Level or 1
					local rotName = rot.Name or ""

					if rotLevel >= minLevelFilter and matchesRarityFilter(rotName) then
						local container = containers[rot.ContainerID]
						local dist = 999999
						if container and container.CFrame then
							dist = (playerPos - container.CFrame.Position).Magnitude
						end
						table.insert(sortedList, {
							rot = rot,
							distance = dist
						})
					end
				end

				table.sort(sortedList, function(a, b)
					return a.distance < b.distance
				end)

				local contentHeight = 0
				for i, itemData in ipairs(sortedList) do
					local rot = itemData.rot
					local distance = itemData.distance

					local cache = uiRowsCache[i]
					if not cache then
						local row = Instance.new("Frame")
						row.Size = UDim2.new(1, -6, 0, 36)
						row.BackgroundColor3 = COLORS.glassSurface
						row.BackgroundTransparency = 0.3
						row.BorderSizePixel = 0

						refs.applyGlass(row, {
							corner = refs.CORNER.small,
							stroke = true,
							strokeColor = COLORS.borderGlass,
							strokeThickness = 1,
							strokeTransparency = 0.8
						})

						local infoLabel = Instance.new("TextLabel")
						infoLabel.Size = UDim2.new(0.7, 0, 1, 0)
						infoLabel.Position = UDim2.new(0, 8, 0, 0)
						infoLabel.BackgroundTransparency = 1
						infoLabel.TextColor3 = COLORS.textPrimary
						infoLabel.TextSize = 10
						infoLabel.Font = Enum.Font.GothamMedium
						infoLabel.TextXAlignment = Enum.TextXAlignment.Left
						infoLabel.Parent = row

						local catchBtn = Instance.new("TextButton")
						catchBtn.Size = UDim2.new(0.24, 0, 0.75, 0)
						catchBtn.Position = UDim2.new(0.74, 0, 0.125, 0)
						catchBtn.BackgroundColor3 = COLORS.accentViolet
						catchBtn.Text = "CATCH"
						catchBtn.TextColor3 = COLORS.textWhite
						catchBtn.TextSize = 8
						catchBtn.Font = Enum.Font.GothamBold
						catchBtn.Parent = row

						local btnCorner = Instance.new("UICorner")
						btnCorner.CornerRadius = refs.CORNER.small
						btnCorner.Parent = catchBtn

						row.Parent = scrollList

						cache = {
							row = row,
							infoLabel = infoLabel,
							catchBtn = catchBtn,
							associatedRot = nil
						}

						catchBtn.MouseButton1Click:Connect(function()
							local currentRot = cache.associatedRot
							if not currentRot or currentlyCatching then return end

							catchBtn.Text = "..."
							catchBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

							local success = catchRot(currentRot)

							if success then
								catchBtn.Text = "OK"
								catchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
							else
								catchBtn.Text = "FAIL"
								catchBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
								task.delay(1.5, function()
									if cache.associatedRot == currentRot then
										catchBtn.Text = "CATCH"
										catchBtn.BackgroundColor3 = COLORS.accentViolet
									end
								end)
							end
						end)

						uiRowsCache[i] = cache
					end

					cache.associatedRot = rot
					cache.row.Visible = true

					local nameStr = rot.Name or "Unknown"
					local lvStr = rot.Level and tostring(rot.Level) or "?"
					local distStr = distance < 999999 and (string.format("%.0f", distance) .. "m") or "N/A"
					local rarityStr = rot.Rarity or "Common"

					cache.infoLabel.Text = string.format("%s (Lv. %s) [%s]\nDist: %s", nameStr, lvStr, rarityStr, distStr)

					if cache.catchBtn.Text ~= "..." and cache.catchBtn.Text ~= "FAIL" and cache.catchBtn.Text ~= "OK" then
						cache.catchBtn.Text = "CATCH"
						cache.catchBtn.BackgroundColor3 = COLORS.accentViolet
					end

					contentHeight = contentHeight + 42
				end

				for i = #sortedList + 1, #uiRowsCache do
					uiRowsCache[i].associatedRot = nil
					uiRowsCache[i].row.Visible = false
				end

				scrollList.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
			end

			catchRot = function(rot)
				if not rot or currentlyCatching then return false end
				currentlyCatching = rot

				teleportToRot(rot)

				local startTime = os.clock()
				local joined = false
				while os.clock() - startTime < 3 do
					if isPlayerInBattle() then
						joined = true
						break
					end
					task.wait(0.1)
				end

				if joined then
					battlesStarted = battlesStarted + 1
					caughtCount = caughtCount + 1
					updateStats()
					currentlyCatching = nil
					return true
				end

				local success, result = pcall(function()
					return CatchRequest:InvokeServer(rot.ContainerID, rot.ID)
				end)

				task.wait(0.5)

				if isPlayerInBattle() or (success and result ~= nil) then
					battlesStarted = battlesStarted + 1
					caughtCount = caughtCount + 1
					updateStats()
					currentlyCatching = nil
					return true
				end

				currentlyCatching = nil
				return false
			end

			-- Load Initial Map State
			local function loadInitialState()
				local success, result = pcall(function()
					return GetInitialContainerStates:InvokeServer()
				end)

				if success and result and result.Containers then
					for containerId, containerData in pairs(result.Containers) do
						containers[containerId] = {
							ID = containerId,
							CFrame = containerData.CFrame,
							Size = containerData.Size,
							World = containerData.World,
							Tags = containerData.Tags,
							Rots = {}
						}
						if containerData.Rots then
							for rotId, rotData in pairs(containerData.Rots) do
								addRot(containerId, rotData, rotId)
							end
						end
					end
					updateUIList()
				else
					task.delay(3, loadInitialState)
				end
			end
			loadInitialState()

			UpdateEvent.OnClientEvent:Connect(function(updates)
				for _, update in ipairs(updates) do
					if update.Type == "Spawn" then
						addRot(update.Container, update.Rot, update.Rot and update.Rot.ID)
					elseif update.Type == "Despawn" or update.Type == "Encounter" then
						removeRot(update.Container, update.Rot)
					end
				end
				uiNeedsUpdate = true
			end)

			-- Auto-Cleanup despawn local timer
			task.spawn(function()
				while true do
					task.wait(1)
					local now = os.clock()
					local changed = false
					for rotId, rot in pairs(activeRots) do
						if rot.DespawnTime and now > rot.DespawnTime then
							removeRot(rot.ContainerID, rotId)
							changed = true
						end
					end
					if changed then uiNeedsUpdate = true end
				end
			end)

			-- Inputs Event Binding
			delayInput.FocusLost:Connect(function()
				local val = tonumber(delayInput.Text)
				if val and val >= 0.1 then
					catchDelay = val
					pcall(saveConfig)
				else
					delayInput.Text = tostring(catchDelay)
				end
			end)

			levelInput.FocusLost:Connect(function()
				local val = tonumber(levelInput.Text)
				if val and val >= 1 then
					minLevelFilter = math.floor(val)
					pcall(saveConfig)
				else
					levelInput.Text = tostring(minLevelFilter)
				end
				uiNeedsUpdate = true
			end)

			rarityBtn.MouseButton1Click:Connect(function()
				selectedRarityIndex = selectedRarityIndex + 1
				if selectedRarityIndex > #rarityNames then
					selectedRarityIndex = 1
				end
				rarityBtn.Text = rarityNames[selectedRarityIndex]
				pcall(saveConfig)
				uiNeedsUpdate = true
			end)

			local function toggleAutoCatch()
				autoCatchEnabled = not autoCatchEnabled
				if autoCatchEnabled then
					toggleBtn.Text = "STOP"
					TweenService:Create(toggleBtn, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(46, 204, 113) })
						:Play()
				else
					toggleBtn.Text = "START"
					TweenService:Create(toggleBtn, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(231, 76, 60) })
						:Play()
				end
				updateStats()
			end
			toggleBtn.MouseButton1Click:Connect(toggleAutoCatch)

			-- Throttled UI & distance update loop
			local lastPlayerPos = Vector3.zero
			task.spawn(function()
				while true do
					task.wait(0.5)
					local character = player.Character
					local playerPos = character and character.PrimaryPart and character.PrimaryPart.Position or
					Vector3.zero
					local moved = (playerPos - lastPlayerPos).Magnitude > 1.5

					if autoCatchEnabled or uiNeedsUpdate or moved then
						updateUIList()
						updateStats()
						uiNeedsUpdate = false
						lastPlayerPos = playerPos
					end
				end
			end)

			-- Auto-Catching Execution Loop
			task.spawn(function()
				while true do
					task.wait(0.2)

					if not autoCatchEnabled then continue end

					if isPlayerInBattle() or currentlyCatching then
						task.wait(0.5)
						continue
					end

					-- Anti-Staff safety check
					if safeModeEnabled then
						local adminFound = false
						for _, p in ipairs(Players:GetPlayers()) do
							if staffCache[p] then
								adminFound = true
								break
							end
						end
						if adminFound then
							task.wait(5)
							continue
						end
					end

					local character = player.Character
					local playerPos = character and character.PrimaryPart and character.PrimaryPart.Position
					if not playerPos then continue end

					local closestRot = nil
					local minDistance = 999999

					for rotId, rot in pairs(activeRots) do
						local rotLevel = rot.Level or 1
						local rotName = rot.Name or ""

						if rotLevel >= minLevelFilter and matchesRarityFilter(rotName) then
							local container = containers[rot.ContainerID]
							if container and container.CFrame then
								local dist = (playerPos - container.CFrame.Position).Magnitude
								if dist < minDistance then
									minDistance = dist
									closestRot = rot
								end
							end
						end
					end

					if closestRot then
						local success = catchRot(closestRot)
						if success then
							task.wait(catchDelay)
						end
					end
				end
			end)
		end)
	end

	------------------------------------------------
	-- ⚙️ CONFIGURATION SAVING & LOADING
	------------------------------------------------
	local placeId = tostring(game.PlaceId)
	local configPath = "HipHub/" .. placeId .. "/config.json"

	saveConfig = function()
		if not writefile then return end
		pcall(function()
			if makefolder then
				pcall(makefolder, "HipHub")
				pcall(makefolder, "HipHub/" .. placeId)
			end
			local data = {}
			if _G.HipHubSettings and _G.HipHubSettings.getState then
				local settingsState = _G.HipHubSettings.getState()
				data.antiAfk = settingsState.antiAfk
				data.touchFling = settingsState.touchFling
				data.antiFling = settingsState.antiFling
				data.noclip = settingsState.noclip
				data.startMinimized = settingsState.startMinimized
				data.keybind = settingsState.keybind
			else
				data.keybind = kbValue.Text
			end
			data.catchDelay = catchDelay
			data.safeModeEnabled = safeModeEnabled
			data.minLevelFilter = minLevelFilter
			data.selectedRarityIndex = selectedRarityIndex

			-- ESP config state
			if _G.HipHubESP and _G.HipHubESP.getState then
				local espState = _G.HipHubESP.getState()
				data.crystalEspEnabled = espState.crystalEspEnabled
				data.boulderEspEnabled = espState.boulderEspEnabled
				data.droppedCrystalEspEnabled = espState.droppedCrystalEspEnabled
				data.droppedRuneEspEnabled = espState.droppedRuneEspEnabled
				data.playerEspEnabled = espState.playerEspEnabled
				data.selectedCrystalRarity = espState.selectedCrystalRarity
				data.selectedCrystalSize = espState.selectedCrystalSize
				data.selectedBoulderRarity = espState.selectedBoulderRarity
			end

			-- Mining config state
			if _G.HipHubMining and _G.HipHubMining.getState then
				local mState = _G.HipHubMining.getState()
				data.antiFallEnabled = mState.antiFallEnabled
				data.instantMineEnabled = mState.instantMineEnabled
				data.instantPickupEnabled = mState.instantPickupEnabled
			end

			-- Automation Sell config state
			if _G.HipHubAutomationSell and _G.HipHubAutomationSell.getState then
				local sellState = _G.HipHubAutomationSell.getState()
				data.autoSellEnabled = sellState.autoSellEnabled
				data.autoSellRarityFilters = sellState.autoSellRarityFilters
				data.autoSellSizeFilters = sellState.autoSellSizeFilters
			end

			-- Automation Favorite config state
			if _G.HipHubAutomationFavorite and _G.HipHubAutomationFavorite.getState then
				local favState = _G.HipHubAutomationFavorite.getState()
				data.autoFavoriteEnabled = favState.autoFavoriteEnabled
				data.autoFavRarityFilters = favState.autoFavRarityFilters
				data.autoFavSizeFilters = favState.autoFavSizeFilters
			end

			-- Automation Mining config state
			if _G.HipHubAutomationMining and _G.HipHubAutomationMining.getState then
				local amState = _G.HipHubAutomationMining.getState()
				data.autoFarmCrystalsEnabled = amState.autoFarmCrystalsEnabled
				data.autoFarmNoclipEnabled = amState.autoFarmNoclipEnabled
				data.autoSellOnFullEnabled = amState.autoSellOnFullEnabled
				data.autoFarmRarityFilters = amState.autoFarmRarityFilters
				data.autoFarmSizeFilters = amState.autoFarmSizeFilters
			end

			-- Automation Digging config state
			if _G.HipHubAutomationDigging and _G.HipHubAutomationDigging.getState then
				local adState = _G.HipHubAutomationDigging.getState()
				data.autoDigEnabled = adState.autoDigEnabled
				data.selectedDigPickaxe = adState.selectedDigPickaxe
				data.selectedDigMaterial = adState.selectedDigMaterial
				data.customDigCenterX = adState.customDigCenterX
				data.customDigCenterY = adState.customDigCenterY
				data.customDigCenterZ = adState.customDigCenterZ
			end

			-- Automation Boulder config state
			if _G.HipHubAutomationBoulder and _G.HipHubAutomationBoulder.getState then
				local abState = _G.HipHubAutomationBoulder.getState()
				data.autoFarmBouldersEnabled = abState.autoFarmBouldersEnabled
				data.boulderRarityFilters = abState.boulderRarityFilters
				data.selectedBoulderBomb = abState.selectedBoulderBomb
			end

			-- Auto Place Crystal config state
			if _G.HipHubAutoPlaceCrystal and _G.HipHubAutoPlaceCrystal.getState then
				local apState = _G.HipHubAutoPlaceCrystal.getState()
				data.autoPlaceCrystalsEnabled = apState.autoPlaceCrystalsEnabled
				data.placeByHighestLuckEnabled = apState.placeByHighestLuckEnabled
				data.autoPlaceRarityFilters = apState.autoPlaceRarityFilters
			end

			-- Shop config state
			if _G.HipHubShop and _G.HipHubShop.getState then
				local shopState = _G.HipHubShop.getState()
				data.autoBuyBombEnabled = shopState.autoBuyBombEnabled
				data.autoBuyBombSelection = shopState.autoBuyBombSelection
			end

			-- Misc config state
			if _G.HipHubMisc and _G.HipHubMisc.getState then
				local miscState = _G.HipHubMisc.getState()
				data.fpsBoostEnabled = miscState.fpsBoostEnabled
				data.blackScreenEnabled = miscState.blackScreenEnabled
				data.capFpsEnabled = miscState.capFpsEnabled
				data.walkSpeedValue = miscState.walkSpeedValue
				data.flyEnabled = miscState.flyEnabled
			end

			writefile(configPath, game:GetService("HttpService"):JSONEncode(data))
		end)
	end

	-- Expose saveConfig callback
	refs.saveConfig = function() pcall(saveConfig) end

	-- Load saved configuration on startup
	pcall(function()
		local content = nil
		if isfile and readfile then
			if isfile(configPath) then
				content = readfile(configPath)
			elseif isfile("HipHub/config.json") then
				content = readfile("HipHub/config.json")
			elseif isfile("hiphub_config.json") then
				content = readfile("hiphub_config.json")
			end
		end

		if content then
			local data = game:GetService("HttpService"):JSONDecode(content)
			if data and type(data) == "table" then
				if data.keybind and tostring(data.keybind) ~= "" then kbValue.Text = tostring(data.keybind) end

				if data.catchDelay ~= nil then catchDelay = tonumber(data.catchDelay) or 1.0 end
				if data.safeModeEnabled ~= nil then safeModeEnabled = (data.safeModeEnabled == true) end
				if data.minLevelFilter ~= nil then minLevelFilter = tonumber(data.minLevelFilter) or 1 end
				if data.selectedRarityIndex ~= nil then selectedRarityIndex = tonumber(data.selectedRarityIndex) or 1 end

				if _G.HipHubESP and _G.HipHubESP.setState then
					_G.HipHubESP.setState({
						crystalEspEnabled = data.crystalEspEnabled,
						boulderEspEnabled = data.boulderEspEnabled,
						droppedCrystalEspEnabled = data.droppedCrystalEspEnabled,
						droppedRuneEspEnabled = data.droppedRuneEspEnabled,
						playerEspEnabled = data.playerEspEnabled,
						selectedCrystalRarity = data.selectedCrystalRarity,
						selectedCrystalSize = data.selectedCrystalSize,
						selectedBoulderRarity = data.selectedBoulderRarity,
					})
				end

				if _G.HipHubMining and _G.HipHubMining.setState then
					_G.HipHubMining.setState({
						antiFallEnabled = data.antiFallEnabled,
						instantMineEnabled = data.instantMineEnabled,
						instantPickupEnabled = data.instantPickupEnabled,
					})
				end

				if _G.HipHubAutomationSell and _G.HipHubAutomationSell.setState then
					_G.HipHubAutomationSell.setState({
						autoSellEnabled = data.autoSellEnabled,
						autoSellRarityFilters = data.autoSellRarityFilters,
						autoSellSizeFilters = data.autoSellSizeFilters,
					})
				end

				if _G.HipHubAutomationFavorite and _G.HipHubAutomationFavorite.setState then
					_G.HipHubAutomationFavorite.setState({
						autoFavoriteEnabled = data.autoFavoriteEnabled,
						autoFavRarityFilters = data.autoFavRarityFilters,
						autoFavSizeFilters = data.autoFavSizeFilters,
					})
				end

				if _G.HipHubAutomationMining and _G.HipHubAutomationMining.setState then
					_G.HipHubAutomationMining.setState({
						autoFarmCrystalsEnabled = data.autoFarmCrystalsEnabled,
						autoFarmRunesEnabled = data.autoFarmRunesEnabled,
						autoFarmNoclipEnabled = data.autoFarmNoclipEnabled,
						autoSellOnFullEnabled = data.autoSellOnFullEnabled,
						autoFarmRarityFilters = data.autoFarmRarityFilters or data.autoFarmRarityFilter,
						autoFarmSizeFilters = data.autoFarmSizeFilters or data.autoFarmSizeFilter,
					})
				end

				if _G.HipHubAutomationBoulder and _G.HipHubAutomationBoulder.setState then
					_G.HipHubAutomationBoulder.setState({
						autoFarmBouldersEnabled = data.autoFarmBouldersEnabled,
						boulderRarityFilters = data.boulderRarityFilters,
						selectedBoulderBomb = data.selectedBoulderBomb,
					})
				end

				if _G.HipHubAutomationDigging and _G.HipHubAutomationDigging.setState then
					_G.HipHubAutomationDigging.setState({
						autoDigEnabled = data.autoDigEnabled,
						selectedDigPickaxe = data.selectedDigPickaxe,
						selectedDigMaterial = data.selectedDigMaterial,
						customDigCenterX = data.customDigCenterX,
						customDigCenterY = data.customDigCenterY,
						customDigCenterZ = data.customDigCenterZ,
					})
				end

				if _G.HipHubAutoPlaceCrystal and _G.HipHubAutoPlaceCrystal.setState then
					_G.HipHubAutoPlaceCrystal.setState({
						autoPlaceCrystalsEnabled = data.autoPlaceCrystalsEnabled,
						placeByHighestLuckEnabled = data.placeByHighestLuckEnabled,
						autoPlaceRarityFilters = data.autoPlaceRarityFilters,
					})
				end

				if _G.HipHubShop and _G.HipHubShop.setState then
					_G.HipHubShop.setState({
						autoBuyBombEnabled = data.autoBuyBombEnabled,
						autoBuyBombSelection = data.autoBuyBombSelection,
					})
				end

				if _G.HipHubMisc and _G.HipHubMisc.setState then
					_G.HipHubMisc.setState({
						fpsBoostEnabled = data.fpsBoostEnabled,
						blackScreenEnabled = data.blackScreenEnabled,
						capFpsEnabled = data.capFpsEnabled,
						walkSpeedValue = data.walkSpeedValue,
						flyEnabled = data.flyEnabled,
					})
				end

				-- Load settings config variables for settings.lua
				if data.antiAfk ~= nil or data.touchFling ~= nil or data.antiFling ~= nil or data.noclip ~= nil or data.startMinimized ~= nil or data.keybind ~= nil then
					_G.HipHubSettingsConfig = {
						antiAfk = data.antiAfk,
						touchFling = data.touchFling,
						antiFling = data.antiFling,
						noclip = data.noclip,
						startMinimized = data.startMinimized,
						keybind = data.keybind or "RightShift"
					}
				end
			end
		end
	end)

	-- Minimize UI on startup if Start Minimized config is set
	task.spawn(function()
		task.wait(0.6)
		local settingsState = _G.HipHubSettings and _G.HipHubSettings.getState and _G.HipHubSettings.getState()
		if settingsState and settingsState.startMinimized then
			pcall(minimizeUI, true)
		end
	end)

	-- Write current execution key to disk
	local currentKey = _G.hiphub_key or hiphub_key
	if currentKey and writefile then
		pcall(function()
			if makefolder then pcall(makefolder, "HipHub") end
			writefile("HipHub/key.txt", tostring(currentKey):gsub("%s+", ""))
		end)
	end
end)
