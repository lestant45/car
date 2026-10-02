-- HipHub DE -- Driving Empire UI Layer
-- Repurposes baseui.lua tabs into DE-specific interface.
-- Depends on: _G.HipHubUI (from baseui.lua), _G.HipHubConfig (from settings.lua)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then warn("[HipHub DE UI] _G.HipHubUI not found"); return end

	local TweenService = UI.TweenService
	local COLORS       = UI.COLORS
	local CORNER       = UI.CORNER
	local TRANSPARENCY = UI.TRANSPARENCY
	local applyGlass   = UI.applyGlass
	local applyPadding = UI.applyPadding
	local applyListLayout = UI.applyListLayout
	local createGlassToggle = UI.createGlassToggle

	-- Initialize DE global state container
	_G.HipHubDE = _G.HipHubDE or {}
	_G.HipHubDE.UI = {}
	local deUI = _G.HipHubDE.UI

	------------------------------------------------
	-- UPDATE TOP BAR BADGE
	------------------------------------------------
	if UI.badge then
		UI.badge.Text = "Driving Empire"
		UI.badge.Size = UDim2.new(0, 130, 0, 22)
	end

	------------------------------------------------
	-- LOCAL UI HELPER FUNCTIONS
	------------------------------------------------

	-- Clear all children from a frame
	local function clearFrame(frame)
		for _, child in ipairs(frame:GetChildren()) do
			child:Destroy()
		end
	end

	-- Re-setup a cleared ScrollingFrame with layout + padding
	local function setupScrollFrame(frame)
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 8)
		layout.Parent = frame

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft   = UDim.new(0, 14)
		pad.PaddingRight  = UDim.new(0, 14)
		pad.PaddingTop    = UDim.new(0, 14)
		pad.PaddingBottom = UDim.new(0, 14)
		pad.Parent = frame

		return layout
	end

	-- Status card at top of each tab
	local function createStatusCard(parent, initialText, layoutOrder)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.medium,
			stroke = true, strokeColor = COLORS.borderGlass,
			strokeThickness = 1, strokeTransparency = 0.7,
			gradient = true, gradientRotation = 120,
		})
		applyPadding(card, 14, 14, 12, 12)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.BackgroundTransparency = 1
		label.Text = initialText
		label.TextColor3 = COLORS.textSecondary
		label.TextSize = 12
		label.RichText = true
		label.TextWrapped = true
		label.Font = Enum.Font.GothamMedium
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LineHeight = 1.35
		label.Parent = card

		return card, label
	end

	-- Cyan accent section header
	local function createSectionHeader(parent, titleText, layoutOrder)
		local header = Instance.new("Frame")
		header.Size = UDim2.new(1, 0, 0, 26)
		header.BackgroundTransparency = 1
		header.BorderSizePixel = 0
		header.LayoutOrder = layoutOrder or 0
		header.Parent = parent

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 3, 0, 14)
		bar.Position = UDim2.new(0, 0, 0.5, -7)
		bar.BackgroundColor3 = COLORS.accentCyan
		bar.BorderSizePixel = 0
		bar.Parent = header

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(0, 2)
		barCorner.Parent = bar

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -12, 1, 0)
		lbl.Position = UDim2.new(0, 10, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = titleText:upper()
		lbl.TextColor3 = COLORS.accentCyan
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = header

		return header
	end

	-- Glass button
	local function createGlassButton(parent, labelText, onClick, layoutOrder, variant)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 34)
		local bgColor, strokeColor
		if variant == "danger" then
			bgColor    = Color3.fromRGB(160, 30, 30)
			strokeColor = Color3.fromRGB(255, 80, 80)
		elseif variant == "success" then
			bgColor    = Color3.fromRGB(0, 120, 80)
			strokeColor = Color3.fromRGB(0, 200, 140)
		else
			bgColor    = COLORS.glassCard
			strokeColor = COLORS.accentCyan
		end
		btn.BackgroundColor3 = bgColor
		btn.BackgroundTransparency = (variant == "danger" or variant == "success") and 0.15 or TRANSPARENCY.glassCard
		btn.BorderSizePixel = 0
		btn.Text = labelText
		btn.TextColor3 = COLORS.textWhite
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.LayoutOrder = layoutOrder or 0
		btn.ZIndex = 2
		btn.Parent = parent

		applyGlass(btn, {
			corner = CORNER.small,
			stroke = true, strokeColor = strokeColor,
			strokeThickness = 1, strokeTransparency = 0.45,
		})

		if onClick then btn.MouseButton1Click:Connect(onClick) end

		pcall(function()
			local baseTrans = btn.BackgroundTransparency
			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = math.max(0, baseTrans - 0.15)}):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = baseTrans}):Play()
			end)
		end)

		return btn
	end

	-- Input row (label left, textbox right)
	local function createInputRow(parent, labelText, placeholder, defaultVal, layoutOrder, onChange)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 34)
		row.BackgroundColor3 = COLORS.glassCard
		row.BackgroundTransparency = TRANSPARENCY.glassCard
		row.BorderSizePixel = 0
		row.LayoutOrder = layoutOrder or 0
		row.ZIndex = 2
		row.Parent = parent

		applyGlass(row, {
			corner = CORNER.small,
			stroke = true, strokeColor = COLORS.borderGlass,
			strokeThickness = 1, strokeTransparency = 0.75,
		})

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.62, 0, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.TextColor3 = COLORS.textPrimary
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 3
		label.Parent = row

		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(0, 72, 0, 24)
		inputBox.Position = UDim2.new(1, -82, 0.5, -12)
		inputBox.BackgroundColor3 = COLORS.glassSurface
		inputBox.BackgroundTransparency = 0.25
		inputBox.BorderSizePixel = 0
		inputBox.Text = tostring(defaultVal or "")
		inputBox.PlaceholderText = placeholder or ""
		inputBox.PlaceholderColor3 = COLORS.textMuted
		inputBox.TextColor3 = COLORS.accentCyan
		inputBox.Font = Enum.Font.GothamBold
		inputBox.TextSize = 12
		inputBox.TextXAlignment = Enum.TextXAlignment.Center
		inputBox.ZIndex = 4
		inputBox.ClearTextOnFocus = false
		inputBox.Parent = row

		applyGlass(inputBox, {
			corner = CORNER.small,
			stroke = true, strokeColor = COLORS.borderGlass,
			strokeThickness = 1, strokeTransparency = 0.85,
		})

		if onChange then
			inputBox.FocusLost:Connect(function()
				onChange(inputBox.Text)
			end)
		end

		return row, inputBox
	end

	-- Toggle wrapper (uses baseui.lua's exported createGlassToggle)
	local function createToggle(parent, labelText, initialState, layoutOrder, onChange)
		local card, track, thumb = createGlassToggle(parent, labelText, layoutOrder)
		card.Size = UDim2.new(1, 0, 0, 34)

		local state = initialState == true

		local function updateVisual()
			TweenService:Create(track, TweenInfo.new(0.18), {
				BackgroundColor3 = state and COLORS.toggleOn or COLORS.toggleOff,
				BackgroundTransparency = 0.15,
			}):Play()
			TweenService:Create(thumb, TweenInfo.new(0.18), {
				Position = state
					and UDim2.new(1, -16, 0.5, -7)
					or  UDim2.new(0,   2, 0.5, -7),
			}):Play()
		end

		updateVisual()

		track.MouseButton1Click:Connect(function()
			state = not state
			updateVisual()
			if onChange then pcall(onChange, state) end
		end)

		return {
			setState = function(newState)
				state = newState
				updateVisual()
			end,
			getState = function() return state end,
			card = card, track = track, thumb = thumb,
		}
	end

	-- Inner card (grouped controls)
	local function createInnerCard(parent, layoutOrder)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = COLORS.glassCard
		card.BackgroundTransparency = TRANSPARENCY.glassCard
		card.BorderSizePixel = 0
		card.LayoutOrder = layoutOrder or 0
		card.Parent = parent

		applyGlass(card, {
			corner = CORNER.medium,
			stroke = true, strokeColor = COLORS.borderGlass,
			strokeThickness = 1, strokeTransparency = 0.7,
		})

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 6)
		layout.Parent = card
		applyPadding(card, 10, 10, 10, 10)

		return card
	end

	------------------------------------------------
	-- RENAME SIDEBAR TABS (NO EMOJIS)
	------------------------------------------------
	local tabButtons = UI.tabButtons
	if tabButtons then
		if tabButtons["Info"]     then tabButtons["Info"].Text     = "   Info" end
		if tabButtons["Steal"]    then tabButtons["Steal"].Text    = "   Farm" end
		if tabButtons["Place"]    then tabButtons["Place"].Text    = "   Teleport" end
		if tabButtons["ESP"]      then tabButtons["ESP"].Text      = "   ESP" end
		if tabButtons["Misc"]     then tabButtons["Misc"].Text     = "   Vehicle" end
		if tabButtons["Webhook"]  then tabButtons["Webhook"].Text  = "   Webhook" end
		if tabButtons["Settings"] then tabButtons["Settings"].Text = "   Settings" end
	end

	-- Update Info tab welcome/desc text
	pcall(function()
		local infoFrame = UI.mainFrameContent
		if infoFrame then
			for _, child in ipairs(infoFrame:GetChildren()) do
				if child:IsA("Frame") then
					for _, lbl in ipairs(child:GetChildren()) do
						if lbl:IsA("TextLabel") then
							if lbl.Text:find("Clean UI Base") then
								lbl.Text = "Driving Empire script loaded and ready to use."
							end
							if lbl.Text:find("Welcome to HipHub") then
								lbl.Text = "Welcome to HipHub DE, " ..
									(game:GetService("Players").LocalPlayer.DisplayName) .. "!"
							end
						end
					end
				end
			end
		end
	end)

	------------------------------------------------
	-- FARM TAB
	------------------------------------------------
	local farmFrame = UI.tabs["Steal"].Frame
	clearFrame(farmFrame)
	setupScrollFrame(farmFrame)

	local _, farmStatusLabel = createStatusCard(farmFrame,
		"Status: <font color='#ff4d4d'>Inactive</font>\nTotal Collected: 0", 1)

	createSectionHeader(farmFrame, "Target Earn Goal", 2)
	local targetCard = createInnerCard(farmFrame, 3)

	local _, targetEarnBox = createInputRow(targetCard, "Target Earn (M / Million)", "e.g. 5",
		tostring(_G.HipHubConfig.farm.targetEarnM or 0), 1, function(val)
			local num = math.max(0, tonumber(val) or 0)
			_G.HipHubConfig.farm.targetEarnM = num
			if _G.HipHubFarm then _G.HipHubFarm.setState({targetEarnM = num}) end
			if UI.saveConfig then pcall(UI.saveConfig) end
		end)

	local targetEarnToggle = createToggle(targetCard, "Enable Target Earn Auto-Kick", false, 2, function(state)
		_G.HipHubConfig.farm.targetEarnEnabled = state
		if _G.HipHubFarm then _G.HipHubFarm.setState({targetEarnEnabled = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	createSectionHeader(farmFrame, "Auto Farm Controls", 4)
	local farmCard = createInnerCard(farmFrame, 5)

	local cashToggle = createToggle(farmCard, "Auto Collect Cash Bags", false, 1, function(state)
		_G.HipHubConfig.farm.autoCollectCash = state
		if _G.HipHubFarm then _G.HipHubFarm.setState({autoCollectCash = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	local bankRobToggle = createToggle(farmCard, "Auto Bank Rob", false, 2, function(state)
		_G.HipHubConfig.farm.autoBankRob = state
		if _G.HipHubFarm then _G.HipHubFarm.setState({autoBankRob = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	local deliveryToggle = createToggle(farmCard, "Auto Delivery Job", false, 3, function(state)
		_G.HipHubConfig.farm.autoDelivery = state
		if _G.HipHubFarm then _G.HipHubFarm.setState({autoDelivery = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	local _, collectDelayBox = createInputRow(farmCard, "Collect Delay (s)", "0.3",
		tostring(_G.HipHubConfig.farm.collectDelay or 0.3), 4, function(val)
			local num = tonumber(val) or 0.3
			_G.HipHubConfig.farm.collectDelay = num
			if _G.HipHubFarm then _G.HipHubFarm.setState({collectDelay = num}) end
			if UI.saveConfig then pcall(UI.saveConfig) end
		end)

	createSectionHeader(farmFrame, "Quick Actions", 6)

	createGlassButton(farmFrame, "Collect All Cash Now", function()
		if _G.HipHubFarm and _G.HipHubFarm.collectAllCash then
			task.spawn(_G.HipHubFarm.collectAllCash)
		end
	end, 7)

	createGlassButton(farmFrame, "Teleport To Bank", function()
		if _G.HipHubFarm and _G.HipHubFarm.goToBank then
			_G.HipHubFarm.goToBank()
		end
	end, 8)

	createGlassButton(farmFrame, "Stop All Farming", function()
		cashToggle.setState(false)
		bankRobToggle.setState(false)
		deliveryToggle.setState(false)
		targetEarnToggle.setState(false)
		_G.HipHubConfig.farm.autoCollectCash = false
		_G.HipHubConfig.farm.autoBankRob = false
		_G.HipHubConfig.farm.autoDelivery = false
		_G.HipHubConfig.farm.targetEarnEnabled = false
		if _G.HipHubFarm then
			_G.HipHubFarm.setState({
				autoCollectCash   = false,
				autoBankRob       = false,
				autoDelivery      = false,
				targetEarnEnabled = false,
			})
		end
	end, 9, "danger")

	deUI.farm = {
		statusLabel      = farmStatusLabel,
		targetEarnBox    = targetEarnBox,
		targetEarnToggle = targetEarnToggle,
		cashToggle       = cashToggle,
		bankRobToggle    = bankRobToggle,
		deliveryToggle   = deliveryToggle,
		collectDelayBox  = collectDelayBox,
	}

	------------------------------------------------
	-- TELEPORT TAB
	------------------------------------------------
	local teleFrame = UI.tabs["Place"].Frame
	clearFrame(teleFrame)
	setupScrollFrame(teleFrame)

	createSectionHeader(teleFrame, "City Locations", 1)
	local teleLocCard = createInnerCard(teleFrame, 2)

	local TELE_LOCS = {
		{"Bank",           "Bank"},
		{"Police Station", "PoliceStation"},
		{"Race Track",     "RaceTrack"},
		{"Car Dealership", "CarDealership"},
		{"Garage / Tuner", "Garage"},
		{"Gas Station",    "GasStation"},
		{"Restaurant",     "Restaurant"},
		{"Delivery Hub",   "DeliveryHub"},
	}

	for i, loc in ipairs(TELE_LOCS) do
		createGlassButton(teleLocCard, loc[1], function()
			if _G.HipHubTeleport and _G.HipHubTeleport.teleportTo then
				_G.HipHubTeleport.teleportTo(loc[2])
			end
		end, i)
	end

	createSectionHeader(teleFrame, "Custom Coordinates", 3)
	local coordCard = createInnerCard(teleFrame, 4)

	local _, xInput = createInputRow(coordCard, "X Coordinate", "0", "0", 1)
	local _, yInput = createInputRow(coordCard, "Y Coordinate", "5", "5", 2)
	local _, zInput = createInputRow(coordCard, "Z Coordinate", "0", "0", 3)

	createGlassButton(coordCard, "Teleport To Coords", function()
		local x = tonumber(xInput.Text) or 0
		local y = tonumber(yInput.Text) or 5
		local z = tonumber(zInput.Text) or 0
		if _G.HipHubTeleport and _G.HipHubTeleport.teleportToCoords then
			_G.HipHubTeleport.teleportToCoords(x, y, z)
		end
	end, 4)

	deUI.teleport = { xInput = xInput, yInput = yInput, zInput = zInput }

	------------------------------------------------
	-- ESP TAB
	------------------------------------------------
	local espFrame = UI.tabs["ESP"].Frame
	clearFrame(espFrame)
	setupScrollFrame(espFrame)

	local _, espStatusLabel = createStatusCard(espFrame,
		"Status: <font color='#ff4d4d'>Disabled</font>\nActive highlights: 0", 1)

	createSectionHeader(espFrame, "ESP Targets", 2)
	local espCard = createInnerCard(espFrame, 3)

	local playerEspToggle = createToggle(espCard, "Player ESP", false, 1, function(state)
		_G.HipHubConfig.esp.playerEsp = state
		if _G.HipHubESP then _G.HipHubESP.setState({playerEsp = state}) end
	end)

	local carEspToggle = createToggle(espCard, "Car / Vehicle ESP", false, 2, function(state)
		_G.HipHubConfig.esp.carEsp = state
		if _G.HipHubESP then _G.HipHubESP.setState({carEsp = state}) end
	end)

	local cashEspToggle = createToggle(espCard, "Cash Bag ESP", false, 3, function(state)
		_G.HipHubConfig.esp.cashEsp = state
		if _G.HipHubESP then _G.HipHubESP.setState({cashEsp = state}) end
	end)

	local distanceToggle = createToggle(espCard, "Show Distance Label", true, 4, function(state)
		_G.HipHubConfig.esp.showDistance = state
		if _G.HipHubESP then _G.HipHubESP.setState({showDistance = state}) end
	end)

	local nameToggle = createToggle(espCard, "Show Name Label", true, 5, function(state)
		_G.HipHubConfig.esp.showName = state
		if _G.HipHubESP then _G.HipHubESP.setState({showName = state}) end
	end)

	createGlassButton(espFrame, "Refresh ESP", function()
		if _G.HipHubESP and _G.HipHubESP.refresh then _G.HipHubESP.refresh() end
	end, 4)

	createGlassButton(espFrame, "Disable All ESP", function()
		playerEspToggle.setState(false)
		carEspToggle.setState(false)
		cashEspToggle.setState(false)
		if _G.HipHubESP then _G.HipHubESP.clearAll() end
	end, 5, "danger")

	deUI.esp = {
		statusLabel    = espStatusLabel,
		playerEspToggle = playerEspToggle,
		carEspToggle   = carEspToggle,
		cashEspToggle  = cashEspToggle,
		distanceToggle = distanceToggle,
		nameToggle     = nameToggle,
	}

	------------------------------------------------
	-- VEHICLE TAB
	------------------------------------------------
	local vehicleFrame = UI.tabs["Misc"].Frame
	clearFrame(vehicleFrame)
	setupScrollFrame(vehicleFrame)

	local _, vehStatusLabel = createStatusCard(vehicleFrame,
		"Status: <font color='#00e6ff'>Ready</font>\nNo vehicle detected", 1)

	createSectionHeader(vehicleFrame, "Vehicle Modifiers", 2)
	local vehCard = createInnerCard(vehicleFrame, 3)

	local _, speedBox = createInputRow(vehCard, "Speed Multiplier (x)", "1.0",
		tostring(_G.HipHubConfig.vehicle.speedMultiplier or 1.0), 1, function(val)
			local num = math.clamp(tonumber(val) or 1.0, 0.1, 50)
			_G.HipHubConfig.vehicle.speedMultiplier = num
			if _G.HipHubVehicle then _G.HipHubVehicle.setState({speedMultiplier = num}) end
			if UI.saveConfig then pcall(UI.saveConfig) end
		end)

	local godModeToggle = createToggle(vehCard, "God Mode (Invincible Car)", false, 2, function(state)
		_G.HipHubConfig.vehicle.godMode = state
		if _G.HipHubVehicle then _G.HipHubVehicle.setState({godMode = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	local nitroToggle = createToggle(vehCard, "Infinite Nitro / Boost", false, 3, function(state)
		_G.HipHubConfig.vehicle.infiniteNitro = state
		if _G.HipHubVehicle then _G.HipHubVehicle.setState({infiniteNitro = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	local noDamageToggle = createToggle(vehCard, "No Car Damage", false, 4, function(state)
		_G.HipHubConfig.vehicle.noDamage = state
		if _G.HipHubVehicle then _G.HipHubVehicle.setState({noDamage = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	local noclipToggle = createToggle(vehCard, "Noclip (Walk Through Walls)", false, 5, function(state)
		_G.HipHubConfig.vehicle.noclip = state
		if _G.HipHubVehicle then _G.HipHubVehicle.setState({noclip = state}) end
		if UI.saveConfig then pcall(UI.saveConfig) end
	end)

	createSectionHeader(vehicleFrame, "Quick Actions", 4)

	createGlassButton(vehicleFrame, "Apply Speed To Current Car", function()
		if _G.HipHubVehicle and _G.HipHubVehicle.applySpeed then
			_G.HipHubVehicle.applySpeed()
		end
	end, 5)

	createGlassButton(vehicleFrame, "Exit Vehicle", function()
		if _G.HipHubVehicle and _G.HipHubVehicle.exitVehicle then
			_G.HipHubVehicle.exitVehicle()
		end
	end, 6)

	createGlassButton(vehicleFrame, "Reset Car Position", function()
		if _G.HipHubVehicle and _G.HipHubVehicle.resetCar then
			_G.HipHubVehicle.resetCar()
		end
	end, 7)

	deUI.vehicle = {
		statusLabel    = vehStatusLabel,
		speedBox       = speedBox,
		godModeToggle  = godModeToggle,
		nitroToggle    = nitroToggle,
		noDamageToggle = noDamageToggle,
		noclipToggle   = noclipToggle,
	}

	------------------------------------------------
	-- Restore saved toggle states from config
	------------------------------------------------
	task.defer(function()
		local cfg = _G.HipHubConfig
		-- Farm
		if cfg.farm and cfg.farm.targetEarnEnabled then targetEarnToggle.setState(true) end
		-- ESP
		if cfg.esp.playerEsp then playerEspToggle.setState(true) end
		if cfg.esp.carEsp    then carEspToggle.setState(true) end
		if cfg.esp.cashEsp   then cashEspToggle.setState(true) end
		if not cfg.esp.showDistance then distanceToggle.setState(false) end
		if not cfg.esp.showName    then nameToggle.setState(false) end
		-- Vehicle
		if cfg.vehicle.godMode      then godModeToggle.setState(true) end
		if cfg.vehicle.infiniteNitro then nitroToggle.setState(true) end
		if cfg.vehicle.noDamage     then noDamageToggle.setState(true) end
		if cfg.vehicle.noclip       then noclipToggle.setState(true) end
	end)

	_G.HipHubDE.UI = deUI
	print("[HipHub DE UI] Interface initialized successfully!")
end)

if not success then
	warn("[HipHub DE UI Error]:", err)
end
