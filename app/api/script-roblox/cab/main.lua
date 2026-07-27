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
						Size = UDim2.new(windowedSize.X.Scale, windowedSize.X.Offset + 12, windowedSize.Y.Scale, windowedSize.Y.Offset + 12),
						Position = UDim2.new(windowedPos.X.Scale, windowedPos.X.Offset - 6, windowedPos.Y.Scale, windowedPos.Y.Offset - 6),
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
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
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
		miningTitle.Text = "Mining"
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

			local tween = TweenService:Create(miningCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
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
				TweenService:Create(afThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

		-- 2. Instant Mine Toggle
		local imRow, imTrack, imThumb = refs.createGlassToggle(toggleContainer, "Instant Mine", 2)
		local updateInstantMineVisuals = function()
			if instantMineEnabled then
				TweenService:Create(imTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(imThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(imTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(imThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

		-- 3. Instant Pickup Toggle
		local ipRow, ipTrack, ipThumb = refs.createGlassToggle(toggleContainer, "Instant Pickup", 3)
		local updateInstantPickupVisuals = function()
			if instantPickupEnabled then
				TweenService:Create(ipTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(ipThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(ipTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(ipThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

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
			{ parent = nil, child = "DroppedCrystals" },
			{ parent = nil, child = "Crystals" }
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
		sellHeaderBtn.BackgroundTransparency = 1
		sellHeaderBtn.Text = ""
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
		sellContentContainer.Size = UDim2.new(1, -24, 0, 80)
		sellContentContainer.Position = UDim2.new(0, 12, 0, 42)
		sellContentContainer.BackgroundTransparency = 1
		sellContentContainer.Parent = sellCard

		refs.applyListLayout(sellContentContainer, 6)

		sellHeaderBtn.MouseButton1Click:Connect(function()
			isSellExpanded = not isSellExpanded
			sellChevronLabel.Text = isSellExpanded and "v" or ">"
			local targetHeight = isSellExpanded and 130 or 36

			local tween = TweenService:Create(sellCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			})
			tween:Play()
			tween.Completed:Connect(updateMainTabCanvas)
			updateMainTabCanvas()
		end)

		-- Sell All Execution Logic (Teleport to Shop, Fire Remote, Return to Original Position)
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
				myHrp.CFrame = shopCFrame
				task.wait(0.4)
			end

			pcall(function()
				local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("SellRequest")
				if rem then
					rem:FireServer("all")
				end
			end)

			if shopCFrame then
				task.wait(0.3)
				if myHrp and myHrp.Parent then
					myHrp.CFrame = lastCFrame
				end
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
		local asRow, asTrack, asThumb = refs.createGlassToggle(sellContentContainer, "Auto Sell All", 2)
		local updateAutoSellVisuals = function()
			if autoSellEnabled then
				TweenService:Create(asTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(asThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(asTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(asThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

		asTrack.MouseButton1Click:Connect(function()
			autoSellEnabled = not autoSellEnabled
			updateAutoSellVisuals()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

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
				return { autoSellEnabled = autoSellEnabled }
			end,
			setState = function(s)
				if s and s.autoSellEnabled ~= nil then
					autoSellEnabled = (s.autoSellEnabled == true)
					updateAutoSellVisuals()
				end
			end
		}

		------------------------------------------------
		-- ⛏️ AUTOMATION MINING CATEGORY SECTION (MAIN TAB)
		------------------------------------------------
		local isAutoMineCategoryExpanded = false
		local autoFarmCrystalsEnabled = false
		local autoFarmNoclipEnabled = true
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
		amHeaderBtn.BackgroundTransparency = 1
		amHeaderBtn.Text = ""
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
		amContentContainer.Size = UDim2.new(1, -24, 0, 360)
		amContentContainer.Position = UDim2.new(0, 12, 0, 42)
		amContentContainer.BackgroundTransparency = 1
		amContentContainer.Parent = autoMineCategoryCard

		refs.applyListLayout(amContentContainer, 6)

		local isRarOpen = false
		local isSzOpen = false

		amHeaderBtn.MouseButton1Click:Connect(function()
			isAutoMineCategoryExpanded = not isAutoMineCategoryExpanded
			amChevronLabel.Text = isAutoMineCategoryExpanded and "v" or ">"
			if not isAutoMineCategoryExpanded then
				isRarOpen = false
				isSzOpen = false
			end

			local targetHeight = isAutoMineCategoryExpanded and (isRarOpen and 430 or (isSzOpen and 410 or 265)) or 36
			local tween = TweenService:Create(autoMineCategoryCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			})
			tween:Play()
			tween.Completed:Connect(updateMainTabCanvas)
			updateMainTabCanvas()
		end)

		-- 1. Auto Farm Crystals Toggle
		local afcRow, afcTrack, afcThumb = refs.createGlassToggle(amContentContainer, "Auto Farm Crystals", 1)
		local updateAutoFarmVisuals = function()
			if autoFarmCrystalsEnabled then
				TweenService:Create(afcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(afcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afcTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afcThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end

		-- 2. Auto Farm Noclip Toggle
		local afnRow, afnTrack, afnThumb = refs.createGlassToggle(amContentContainer, "Auto Farm Noclip", 2)
		local updateAutoFarmNoclipVisuals = function()
			if autoFarmNoclipEnabled then
				TweenService:Create(afnTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(afnThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(afnTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(afnThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoFarmNoclipVisuals()

		-- 3. Auto Sell When Full Toggle
		local autoSellOnFullEnabled = true
		local asfRow, asfTrack, asfThumb = refs.createGlassToggle(amContentContainer, "Auto Sell When Full", 3)
		local updateAutoSellFullVisuals = function()
			if autoSellOnFullEnabled then
				TweenService:Create(asfTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
				TweenService:Create(asfThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			else
				TweenService:Create(asfTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
				TweenService:Create(asfThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			end
		end
		updateAutoSellFullVisuals()

		asfTrack.MouseButton1Click:Connect(function()
			autoSellOnFullEnabled = not autoSellOnFullEnabled
			updateAutoSellFullVisuals()
			if refs.saveConfig then pcall(refs.saveConfig) end
		end)

		-- 4. Target Rarity Filter Card inside Automation Mining
		local amRarCard = Instance.new("Frame")
		amRarCard.Size = UDim2.new(1, 0, 0, 36)
		amRarCard.BackgroundColor3 = COLORS.glassCard
		amRarCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		amRarCard.BorderSizePixel = 0
		amRarCard.ClipsDescendants = true
		amRarCard.LayoutOrder = 4
		amRarCard.Parent = amContentContainer

		refs.applyGlass(amRarCard, { corner = refs.CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.75 })

		local amRarTitle = Instance.new("TextLabel")
		amRarTitle.Size = UDim2.new(0.5, 0, 0, 36)
		amRarTitle.Position = UDim2.new(0, 12, 0, 0)
		amRarTitle.BackgroundTransparency = 1
		amRarTitle.Text = "Target Rarity"
		amRarTitle.TextColor3 = COLORS.textPrimary
		amRarTitle.Font = Enum.Font.GothamMedium
		amRarTitle.TextSize = 11
		amRarTitle.TextXAlignment = Enum.TextXAlignment.Left
		amRarTitle.Parent = amRarCard

		local amRarDropBtn = Instance.new("TextButton")
		amRarDropBtn.Size = UDim2.new(0, 128, 0, 22)
		amRarDropBtn.Position = UDim2.new(1, -140, 0, 7)
		amRarDropBtn.BackgroundColor3 = Color3.fromRGB(24, 30, 50)
		amRarDropBtn.Text = (autoFarmRarityFilter or "All") .. "  ▼"
		amRarDropBtn.TextColor3 = COLORS.accentCyan
		amRarDropBtn.Font = Enum.Font.GothamBold
		amRarDropBtn.TextSize = 10
		amRarDropBtn.Parent = amRarCard

		local amRarCorner = Instance.new("UICorner")
		amRarCorner.CornerRadius = refs.CORNER.small
		amRarCorner.Parent = amRarDropBtn

		local amRarMenuFrame = Instance.new("Frame")
		amRarMenuFrame.Size = UDim2.new(0, 128, 0, 160)
		amRarMenuFrame.Position = UDim2.new(1, -140, 0, 36)
		amRarMenuFrame.BackgroundTransparency = 1
		amRarMenuFrame.Visible = false
		amRarMenuFrame.ClipsDescendants = true
		amRarMenuFrame.Parent = amRarCard

		refs.applyListLayout(amRarMenuFrame, 3)

		local amRarities = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

		local function updateAmRarityVisuals()
			amRarDropBtn.Text = (autoFarmRarityFilter or "All") .. (isRarOpen and "  ▲" or "  ▼")
			for _, child in ipairs(amRarMenuFrame:GetChildren()) do
				if child:IsA("TextButton") then
					local isSel = (child.Text == autoFarmRarityFilter)
					child.BackgroundColor3 = isSel and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
					child.TextColor3 = isSel and COLORS.accentCyan or COLORS.textSecondary
				end
			end
		end

		for _, rName in ipairs(amRarities) do
			local itemBtn = Instance.new("TextButton")
			itemBtn.Size = UDim2.new(1, 0, 0, 20)
			itemBtn.BackgroundColor3 = (autoFarmRarityFilter == rName) and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
			itemBtn.BackgroundTransparency = 0.15
			itemBtn.Text = rName
			itemBtn.TextColor3 = (autoFarmRarityFilter == rName) and COLORS.accentCyan or COLORS.textSecondary
			itemBtn.Font = Enum.Font.GothamMedium
			itemBtn.TextSize = 10
			itemBtn.Parent = amRarMenuFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 4)
			itemCorner.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				autoFarmRarityFilter = rName
				isRarOpen = false
				updateAmRarityVisuals()
				TweenService:Create(amRarCard, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 36) }):Play()
				TweenService:Create(autoMineCategoryCard, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 220) }):Play()
				updateMainTabCanvas()
				if refs.saveConfig then pcall(refs.saveConfig) end
			end)
		end

		amRarDropBtn.MouseButton1Click:Connect(function()
			isRarOpen = not isRarOpen
			if isRarOpen then isSzOpen = false end
			amRarMenuFrame.Visible = isRarOpen
			updateAmRarityVisuals()

			local rarTargetHeight = isRarOpen and (36 + 165) or 36
			local cardTargetHeight = isRarOpen and 385 or 220
			TweenService:Create(amRarCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, rarTargetHeight) }):Play()
			TweenService:Create(autoMineCategoryCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, cardTargetHeight) }):Play()
			updateMainTabCanvas()
		end)

		-- 4. Target Size Filter Card inside Automation Mining
		local amSzCard = Instance.new("Frame")
		amSzCard.Size = UDim2.new(1, 0, 0, 36)
		amSzCard.BackgroundColor3 = COLORS.glassCard
		amSzCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
		amSzCard.BorderSizePixel = 0
		amSzCard.ClipsDescendants = true
		amSzCard.LayoutOrder = 4
		amSzCard.Parent = amContentContainer

		refs.applyGlass(amSzCard, { corner = refs.CORNER.small, stroke = true, strokeColor = COLORS.borderGlass, strokeThickness = 1, strokeTransparency = 0.75 })

		local amSzTitle = Instance.new("TextLabel")
		amSzTitle.Size = UDim2.new(0.5, 0, 0, 36)
		amSzTitle.Position = UDim2.new(0, 12, 0, 0)
		amSzTitle.BackgroundTransparency = 1
		amSzTitle.Text = "Target Size"
		amSzTitle.TextColor3 = COLORS.textPrimary
		amSzTitle.Font = Enum.Font.GothamMedium
		amSzTitle.TextSize = 11
		amSzTitle.TextXAlignment = Enum.TextXAlignment.Left
		amSzTitle.Parent = amSzCard

		local amSzDropBtn = Instance.new("TextButton")
		amSzDropBtn.Size = UDim2.new(0, 128, 0, 22)
		amSzDropBtn.Position = UDim2.new(1, -140, 0, 7)
		amSzDropBtn.BackgroundColor3 = Color3.fromRGB(24, 30, 50)
		amSzDropBtn.Text = (autoFarmSizeFilter or "All") .. "  ▼"
		amSzDropBtn.TextColor3 = COLORS.accentCyan
		amSzDropBtn.Font = Enum.Font.GothamBold
		amSzDropBtn.TextSize = 10
		amSzDropBtn.Parent = amSzCard

		local amSzCorner = Instance.new("UICorner")
		amSzCorner.CornerRadius = refs.CORNER.small
		amSzCorner.Parent = amSzDropBtn

		local amSzMenuFrame = Instance.new("Frame")
		amSzMenuFrame.Size = UDim2.new(0, 128, 0, 140)
		amSzMenuFrame.Position = UDim2.new(1, -140, 0, 36)
		amSzMenuFrame.BackgroundTransparency = 1
		amSzMenuFrame.Visible = false
		amSzMenuFrame.ClipsDescendants = true
		amSzMenuFrame.Parent = amSzCard

		refs.applyListLayout(amSzMenuFrame, 3)

		local amSizes = { "All", "Small", "Medium", "Large", "Titan", "Colossal" }

		local function updateAmSizeVisuals()
			amSzDropBtn.Text = (autoFarmSizeFilter or "All") .. (isSzOpen and "  ▲" or "  ▼")
			for _, child in ipairs(amSzMenuFrame:GetChildren()) do
				if child:IsA("TextButton") then
					local isSel = (child.Text == autoFarmSizeFilter)
					child.BackgroundColor3 = isSel and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
					child.TextColor3 = isSel and COLORS.accentCyan or COLORS.textSecondary
				end
			end
		end

		for _, sName in ipairs(amSizes) do
			local itemBtn = Instance.new("TextButton")
			itemBtn.Size = UDim2.new(1, 0, 0, 20)
			itemBtn.BackgroundColor3 = (autoFarmSizeFilter == sName) and Color3.fromRGB(36, 44, 72) or Color3.fromRGB(18, 22, 38)
			itemBtn.BackgroundTransparency = 0.15
			itemBtn.Text = sName
			itemBtn.TextColor3 = (autoFarmSizeFilter == sName) and COLORS.accentCyan or COLORS.textSecondary
			itemBtn.Font = Enum.Font.GothamMedium
			itemBtn.TextSize = 10
			itemBtn.Parent = amSzMenuFrame

			local itemCorner = Instance.new("UICorner")
			itemCorner.CornerRadius = UDim.new(0, 4)
			itemCorner.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				autoFarmSizeFilter = sName
				isSzOpen = false
				updateAmSizeVisuals()
				TweenService:Create(amSzCard, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 36) }):Play()
				TweenService:Create(autoMineCategoryCard, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 220) }):Play()
				updateMainTabCanvas()
				if refs.saveConfig then pcall(refs.saveConfig) end
			end)
		end

		amSzDropBtn.MouseButton1Click:Connect(function()
			isSzOpen = not isSzOpen
			if isSzOpen then isRarOpen = false end
			amSzMenuFrame.Visible = isSzOpen
			updateAmSizeVisuals()

			local szTargetHeight = isSzOpen and (36 + 145) or 36
			local cardTargetHeight = isSzOpen and 365 or 220
			TweenService:Create(amSzCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, szTargetHeight) }):Play()
			TweenService:Create(autoMineCategoryCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, cardTargetHeight) }):Play()
			updateMainTabCanvas()
		end)

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

		-- Helper to get closest filtered crystal using Automation Mining's independent filters
		local function getClosestFilteredCrystal()
			local char = player and player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then return nil end

			local myPos = hrp.Position
			local selRarity = autoFarmRarityFilter or "All"
			local selSize = autoFarmSizeFilter or "All"

			local things = workspace:FindFirstChild("Things")
			local crystalsFolder = workspace:FindFirstChild("Crystals") or (things and things:FindFirstChild("Crystals"))
			local dcFolder = workspace:FindFirstChild("DroppedCrystals")

			local bestObj = nil
			local bestPart = nil
			local shortestDist = math.huge

			local function evaluateFolder(folder)
				if not folder then return end
				for _, child in ipairs(folder:GetChildren()) do
					if child and child.Parent then
						local nameLower = string.lower(child.Name)
						local rarityLower = string.lower(selRarity)
						local sizeLower = string.lower(selSize)

						-- Independent Rarity Check
						local matchesRarity = (rarityLower == "all" or rarityLower == "")
						if not matchesRarity then
							local filterMap = {
								["common"] = {"_t1", "t1", "common"},
								["uncommon"] = {"_t2", "t2", "uncommon"},
								["rare"] = {"_t3", "t3", "rare"},
								["epic"] = {"_t4", "t4", "epic"},
								["legendary"] = {"_t5", "t5", "legendary"},
								["mythical"] = {"_t6", "t6", "mythical", "mythic"},
								["mythic"] = {"_t6", "t6", "mythical", "mythic"},
							}
							local kws = filterMap[rarityLower]
							if kws then
								for _, kw in ipairs(kws) do
									if string.find(nameLower, kw, 1, true) then
										matchesRarity = true
										break
									end
								end
							end
							if not matchesRarity and string.find(nameLower, rarityLower, 1, true) then
								matchesRarity = true
							end
							if not matchesRarity then
								local attr = child:GetAttribute("Rarity") or child:GetAttribute("Tier") or child:GetAttribute("rarity") or child:GetAttribute("tier")
								if attr and string.find(string.lower(tostring(attr)), rarityLower, 1, true) then
									matchesRarity = true
								end
							end
						end

						-- Independent Size Check
						local matchesSize = (sizeLower == "all" or sizeLower == "")
						if not matchesSize then
							if string.find(nameLower, sizeLower, 1, true) then
								matchesSize = true
							else
								local attr = child:GetAttribute("Size") or child:GetAttribute("Category") or child:GetAttribute("size") or child:GetAttribute("category")
								if attr and string.find(string.lower(tostring(attr)), sizeLower, 1, true) then
									matchesSize = true
								else
									local sizeVec = nil
									if child:IsA("BasePart") then
										sizeVec = child.Size
									elseif child:IsA("Model") then
										local primary = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
										if primary then sizeVec = primary.Size end
									end
									if sizeVec then
										local maxDim = math.max(sizeVec.X, sizeVec.Y, sizeVec.Z)
										if sizeLower == "colossal" and maxDim >= 12 then
											matchesSize = true
										elseif sizeLower == "titan" and (maxDim >= 7 and maxDim < 12) then
											matchesSize = true
										elseif sizeLower == "large" and (maxDim >= 4.5 and maxDim < 7) then
											matchesSize = true
										elseif sizeLower == "medium" and (maxDim >= 1.8 and maxDim < 4.5) then
											matchesSize = true
										elseif sizeLower == "small" and maxDim < 1.8 then
											matchesSize = true
										end
									end
								end
							end
						end

						if matchesRarity and matchesSize then
							local targetPart = child:IsA("BasePart") and child or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
							if targetPart then
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
			end

			evaluateFolder(crystalsFolder)
			evaluateFolder(dcFolder)

			if bestObj and bestPart then
				return { obj = bestObj, part = bestPart }
			end
			return nil
		end

		-- Helper to check if player backpack/inventory is full
		local function isBackpackFull()
			local p = player or game:GetService("Players").LocalPlayer
			if not p then return false end

			-- 1. Check Player attributes
			local maxCap = p:GetAttribute("MaxCapacity") or p:GetAttribute("MaxBackpack") or p:GetAttribute("MaxStorage") or p:GetAttribute("Capacity") or p:GetAttribute("MaxCrystals") or p:GetAttribute("MaxBag")
			local currCap = p:GetAttribute("Capacity") or p:GetAttribute("BackpackCount") or p:GetAttribute("StorageCount") or p:GetAttribute("CrystalsCount") or p:GetAttribute("BagCount")

			if typeof(maxCap) == "number" and typeof(currCap) == "number" and maxCap > 0 then
				if currCap >= maxCap then return true end
			end

			-- 2. Check leaderstats
			local leaderstats = p:FindFirstChild("leaderstats")
			if leaderstats then
				local capVal = leaderstats:FindFirstChild("Capacity") or leaderstats:FindFirstChild("Storage") or leaderstats:FindFirstChild("Backpack") or leaderstats:FindFirstChild("Bag")
				local maxVal = leaderstats:FindFirstChild("MaxCapacity") or leaderstats:FindFirstChild("MaxStorage") or leaderstats:FindFirstChild("MaxBackpack") or leaderstats:FindFirstChild("MaxBag")
				if capVal and maxVal and tonumber(capVal.Value) and tonumber(maxVal.Value) then
					if tonumber(capVal.Value) >= tonumber(maxVal.Value) then return true end
				end
			end

			-- 3. Check items in Backpack + Character tools
			local bFolder = p:FindFirstChild("Backpack")
			local bItems = bFolder and #bFolder:GetChildren() or 0
			local charTools = 0
			if p.Character then
				for _, child in ipairs(p.Character:GetChildren()) do
					if child:IsA("Tool") then charTools = charTools + 1 end
				end
			end
			local totalItems = bItems + charTools

			if typeof(maxCap) == "number" and maxCap > 0 and totalItems >= maxCap then
				return true
			end

			-- 4. Check PlayerGui for Inventory Full popups / text
			local pGui = p:FindFirstChild("PlayerGui")
			if pGui then
				for _, gui in ipairs(pGui:GetChildren()) do
					if gui:IsA("ScreenGui") and gui.Enabled then
						for _, label in ipairs(gui:GetDescendants()) do
							if label:IsA("TextLabel") and label.Visible then
								local txt = string.lower(label.Text or "")
								if string.find(txt, "inventory full", 1, true) or string.find(txt, "backpack full", 1, true) or string.find(txt, "bag full", 1, true) or string.find(txt, "storage full", 1, true) or string.find(txt, "max capacity", 1, true) then
									return true
								end
							end
						end
					end
				end
			end

			return false
		end

		-- Auto Farm Loop with Levitating / Flying Stay Engine & Auto Sell When Full
		task.spawn(function()
			while true do
				task.wait(0.1)
				if autoFarmCrystalsEnabled then
					-- Check if backpack is full and trigger Auto Sell (Teleport to shop, sell, return)
					if autoSellOnFullEnabled and isBackpackFull() then
						local myChar = player and player.Character
						local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
						if myHrp then
							local flyHold = myHrp:FindFirstChild("HipHubFarmFly")
							if flyHold then pcall(function() flyHold:Destroy() end) end
						end

						pcall(executeSellAllTeleport)
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

							-- Teleport EXACTLY ONCE to the target crystal
							myHrp.CFrame = part.CFrame + Vector3.new(0, 2.5, 0)
							pcall(function() myHrp.AssemblyLinearVelocity = Vector3.zero end)

							local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
							if prompt then
								prompt.HoldDuration = 0
								pcall(function()
									if fireproximityprompt then
										fireproximityprompt(prompt)
									end
								end)
							end

							-- Stay flying in place while mining until crystal breaks (no repeated CFrame teleporting)
							local startTime = os.clock()
							while autoFarmCrystalsEnabled and obj and obj.Parent and (os.clock() - startTime < 2.5) do
								task.wait(0.15)
								if prompt and prompt.Parent then
									pcall(function()
										if fireproximityprompt then
											fireproximityprompt(prompt)
										end
									end)
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

		_G.HipHubAutomationMining = {
			getState = function()
				return {
					autoFarmCrystalsEnabled = autoFarmCrystalsEnabled,
					autoFarmNoclipEnabled = autoFarmNoclipEnabled,
					autoSellOnFullEnabled = autoSellOnFullEnabled,
					autoFarmRarityFilter = autoFarmRarityFilter,
					autoFarmSizeFilter = autoFarmSizeFilter,
				}
			end,
			setState = function(s)
				if not s then return end
				if s.autoFarmCrystalsEnabled ~= nil then
					autoFarmCrystalsEnabled = (s.autoFarmCrystalsEnabled == true)
					updateAutoFarmVisuals()
					updateAutomationNoclipEngine()
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
				if s.autoFarmRarityFilter ~= nil then
					autoFarmRarityFilter = tostring(s.autoFarmRarityFilter)
					updateAmRarityVisuals()
				end
				if s.autoFarmSizeFilter ~= nil then
					autoFarmSizeFilter = tostring(s.autoFarmSizeFilter)
					updateAmSizeVisuals()
				end
			end
		}
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
			local rarityNames = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"}

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
							local valueMap = {[1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythical"}
							return valueMap[species.Rarity.Value] or tostring(species.Rarity.Value)
						end
					end
					if species.RarityValue then
						local valueMap = {[1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythical"}
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
				statsLabel.Text = "Status: " .. statusText .. "\nCaught: " .. tostring(caughtCount) .. " | Battles: " .. tostring(battlesStarted)
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
					TweenService:Create(toggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(46, 204, 113)}):Play()
				else
					toggleBtn.Text = "START"
					TweenService:Create(toggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(231, 76, 60)}):Play()
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
					local playerPos = character and character.PrimaryPart and character.PrimaryPart.Position or Vector3.zero
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
	saveConfig = function()
		if not writefile then return end
		pcall(function()
			if makefolder then pcall(makefolder, "HipHub") end
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
				data.droppedCrystalEspEnabled = espState.droppedCrystalEspEnabled
				data.droppedRuneEspEnabled = espState.droppedRuneEspEnabled
				data.playerEspEnabled = espState.playerEspEnabled
				data.selectedCrystalRarity = espState.selectedCrystalRarity
				data.selectedCrystalSize = espState.selectedCrystalSize
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
			end

			-- Automation Mining config state
			if _G.HipHubAutomationMining and _G.HipHubAutomationMining.getState then
				local amState = _G.HipHubAutomationMining.getState()
				data.autoFarmCrystalsEnabled = amState.autoFarmCrystalsEnabled
				data.autoFarmNoclipEnabled = amState.autoFarmNoclipEnabled
				data.autoSellOnFullEnabled = amState.autoSellOnFullEnabled
				data.autoFarmRarityFilter = amState.autoFarmRarityFilter
				data.autoFarmSizeFilter = amState.autoFarmSizeFilter
			end

			writefile("HipHub/config.json", game:GetService("HttpService"):JSONEncode(data))
		end)
	end

	-- Expose saveConfig callback
	refs.saveConfig = function() pcall(saveConfig) end

	-- Load saved configuration on startup
	pcall(function()
		local content = nil
		if isfile and readfile then
			if isfile("HipHub/config.json") then
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
						droppedCrystalEspEnabled = data.droppedCrystalEspEnabled,
						droppedRuneEspEnabled = data.droppedRuneEspEnabled,
						playerEspEnabled = data.playerEspEnabled,
						selectedCrystalRarity = data.selectedCrystalRarity,
						selectedCrystalSize = data.selectedCrystalSize,
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
					})
				end

				if _G.HipHubAutomationMining and _G.HipHubAutomationMining.setState then
					_G.HipHubAutomationMining.setState({
						autoFarmCrystalsEnabled = data.autoFarmCrystalsEnabled,
						autoFarmNoclipEnabled = data.autoFarmNoclipEnabled,
						autoSellOnFullEnabled = data.autoSellOnFullEnabled,
						autoFarmRarityFilter = data.autoFarmRarityFilter,
						autoFarmSizeFilter = data.autoFarmSizeFilter,
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

if not success then
	warn("CAB UI Main Wire Init Error: " .. tostring(err))
end
