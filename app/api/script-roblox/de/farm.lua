-- 💰 HipHub DE -- Auto Farm System
-- Driving Empire (Place ID: 9694510481)
-- Features: Auto Collect Cash Bags, Auto Bank Rob, Auto Delivery (Offroad Job + Full Cargo Pickup + Auto Easy Mode)
-- Exports: _G.HipHubFarm

local success, err = pcall(function()
	local Players         = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService      = game:GetService("RunService")
	local player          = Players.LocalPlayer

	------------------------------------------------
	-- 📦 STATE
	------------------------------------------------
	local State = {
		autoCollectCash = false,
		autoBankRob     = false,
		autoDelivery    = false,
		collectDelay    = 0.3,
		totalCollected  = 0,
		totalDeliveries = 0,
		deliveryStatus  = "Idle",
	}

	-- Primary Offroad Delivery job pad CFrame
	local OFFROAD_JOB_PAD = CFrame.new(4304.24, 117.0, -1094.74)

	-- Cash detection keywords across DE
	local CASH_KEYWORDS = {
		"cashbag", "moneybag", "cash", "money", "dollar",
		"bill", "coin", "reward", "loot", "prize", "bonus",
		"pickup", "collectible", "earn", "income",
	}

	-- Bank robbery keywords
	local BANK_KEYWORDS = {
		"bank", "vault", "safe", "treasury", "deposit", "rob",
	}

	local ROB_PROMPT_KEYWORDS = {
		"rob", "vault", "steal", "break", "crack", "loot", "hack",
	}

	------------------------------------------------
	-- 🔌 GAME MODULES & REMOTES RESOLUTION
	------------------------------------------------
	local RemotesModule = nil
	pcall(function() RemotesModule = require(ReplicatedStorage.Modules.Shared.Remotes) end)

	local JobsConstants = nil
	pcall(function() JobsConstants = require(ReplicatedStorage.Modules.Shared.Jobs.JobsConstants) end)

	local DeliveryConstants = nil
	pcall(function() DeliveryConstants = require(ReplicatedStorage.Modules.Shared.Jobs.Delivery.DeliveryConstants) end)

	local DeliveryJobTask = nil
	pcall(function() DeliveryJobTask = require(ReplicatedStorage.Modules.Client.Jobs.Tasks.DeliveryJobTask) end)

	local DeliveryModeController = nil
	pcall(function() DeliveryModeController = require(ReplicatedStorage.Modules.Client.Jobs.Delivery.DeliveryModeController) end)

	local JobsUtil = nil
	pcall(function() JobsUtil = require(ReplicatedStorage.Modules.Shared.Jobs.JobsUtil) end)

	local PromptControllerV2 = nil
	pcall(function() PromptControllerV2 = require(ReplicatedStorage.Modules.Client.UI.PromptControllerV2) end)

	------------------------------------------------
	-- 🔍 HELPERS
	------------------------------------------------
	local function getCharRoot()
		local char = player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function matchesKeywords(name, keywords)
		local n = name:lower()
		for _, kw in ipairs(keywords) do
			if n:find(kw, 1, true) then return true end
		end
		return false
	end

	local function getCFrame(obj)
		if obj:IsA("BasePart") then
			return obj.CFrame
		elseif obj:IsA("Model") then
			if obj.PrimaryPart then
				return obj.PrimaryPart.CFrame
			end
			for _, v in ipairs(obj:GetChildren()) do
				if v:IsA("BasePart") then return v.CFrame end
			end
		end
		return nil
	end

	local function teleportTo(cf)
		local root = getCharRoot()
		if root then
			if typeof(cf) == "Vector3" then
				root.CFrame = CFrame.new(cf + Vector3.new(0, 3, 0))
			elseif typeof(cf) == "CFrame" then
				root.CFrame = cf + Vector3.new(0, 3, 0)
			end
			return true
		end
		return false
	end

	-- Check if player is currently in a delivery job
	local function isPlayerOnDeliveryJob()
		if JobsUtil and JobsUtil.GetPlayerJobId then
			local ok, id = pcall(JobsUtil.GetPlayerJobId, player)
			if ok and id == "Delivery" then return true end
		end
		if DeliveryJobTask and DeliveryJobTask.HasActiveDelivery then
			local ok, active = pcall(DeliveryJobTask.HasActiveDelivery)
			if ok and active then return true end
		end
		if DeliveryJobTask and DeliveryJobTask.GetCurrentDeliveryState then
			local ok, st = pcall(DeliveryJobTask.GetCurrentDeliveryState)
			if ok and st ~= nil then return true end
		end
		return false
	end

	------------------------------------------------
	-- 🔎 SCAN WORKSPACE FOR CASH OBJECTS
	------------------------------------------------
	local function findCashObjects()
		local list = {}
		local root = getCharRoot()

		for _, obj in ipairs(workspace:GetDescendants()) do
			if matchesKeywords(obj.Name, CASH_KEYWORDS) then
				if obj:IsA("BasePart") or obj:IsA("Model") then
					local cf = getCFrame(obj)
					if cf then
						local dist = root and (cf.Position - root.Position).Magnitude or math.huge
						table.insert(list, {obj = obj, cf = cf, dist = dist})
					end
				end
			end
		end

		table.sort(list, function(a, b) return a.dist < b.dist end)
		return list
	end

	------------------------------------------------
	-- 🏦 FIND BANK LOCATION
	------------------------------------------------
	local function findBankCFrame()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if matchesKeywords(obj.Name, BANK_KEYWORDS) then
				local cf = getCFrame(obj)
				if cf then return cf end
			end
		end
		return nil
	end

	local function goToBank()
		local cf = findBankCFrame()
		if cf then
			return teleportTo(cf)
		end
		warn("[HipHub DE Farm] Bank not found in workspace")
		return false
	end

	------------------------------------------------
	-- ⚡ COLLECT ALL CASH (one-shot)
	------------------------------------------------
	local function collectAllCash(fromLoop)
		local list = findCashObjects()
		local collected = 0

		for _, item in ipairs(list) do
			if fromLoop and not State.autoCollectCash then break end

			if item.obj and item.obj.Parent then
				teleportTo(item.cf)
				collected = collected + 1
				State.totalCollected = State.totalCollected + 1

				pcall(function()
					for _, pp in ipairs(item.obj:GetDescendants()) do
						if pp:IsA("ProximityPrompt") and pp.Enabled then
							if fireproximityprompt then
								fireproximityprompt(pp)
							end
						end
					end
				end)

				task.wait(math.max(State.collectDelay, 0.05))
			end
		end

		return collected
	end

	------------------------------------------------
	-- 🔁 AUTO COLLECT CASH LOOP
	------------------------------------------------
	local collectThread = nil

	local function startCollectLoop()
		if collectThread then task.cancel(collectThread) end
		collectThread = task.spawn(function()
			while State.autoCollectCash do
				pcall(collectAllCash, true)
				task.wait(math.max(State.collectDelay, 0.1))
			end
		end)
	end

	local function stopCollectLoop()
		if collectThread then
			task.cancel(collectThread)
			collectThread = nil
		end
	end

	------------------------------------------------
	-- 🏦 AUTO BANK ROB LOOP
	------------------------------------------------
	local bankThread = nil

	local function startBankRobLoop()
		if bankThread then task.cancel(bankThread) end
		bankThread = task.spawn(function()
			while State.autoBankRob do
				pcall(function()
					goToBank()
					task.wait(1.5)

					local root = getCharRoot()
					if not root then return end

					for _, obj in ipairs(workspace:GetDescendants()) do
						if obj:IsA("ProximityPrompt") and obj.Enabled then
							local actionText = (obj.ActionText or ""):lower()
							local objText    = (obj.Parent and obj.Parent.Name or ""):lower()

							local isRob = false
							for _, kw in ipairs(ROB_PROMPT_KEYWORDS) do
								if actionText:find(kw, 1, true) or objText:find(kw, 1, true) then
									isRob = true
									break
								end
							end

							if isRob then
								local promptPart = obj.Parent
								if promptPart and promptPart:IsA("BasePart") then
									local dist = (promptPart.Position - root.Position).Magnitude
									if dist < 50 then
										pcall(function()
											if fireproximityprompt then
												fireproximityprompt(obj)
											end
										end)
										task.wait(0.5)
									end
								end
							end
						end
					end
				end)
				task.wait(6)
			end
		end)
	end

	local function stopBankRobLoop()
		if bankThread then
			task.cancel(bankThread)
			bankThread = nil
		end
	end

	------------------------------------------------
	-- 📦 AUTO DELIVERY JOB (OFFROAD & AUTO EASY MODE)
	------------------------------------------------

	-- 1. Handle & auto-click "Easy" delivery mode popup ONLY when popup is actually visible
	local function handleDeliveryModePopup()
		pcall(function()
			local pgui = player:FindFirstChild("PlayerGui")
			if not pgui then return end
			local promptUI = pgui:FindFirstChild("PromptUI")
			if not promptUI then return end
			local promptV2 = promptUI:FindFirstChild("PromptV2")
			if not promptV2 or not promptV2.Visible then return end

			local title = promptV2:FindFirstChild("Title")
			local titleText = title and title.Text:lower() or ""

			if titleText:find("delivery") or titleText:find("choose") or titleText:find("mode") then
				local buttonsFrame = promptV2:FindFirstChild("ButtonsFrame")
				if buttonsFrame then
					for _, btn in ipairs(buttonsFrame:GetChildren()) do
						if btn:IsA("GuiButton") and btn.Visible then
							local btnTitle = btn:FindFirstChild("Title")
							local txt = btnTitle and btnTitle.Text:lower() or ""
							if btn.Name == "SafeDelivery" or txt:find("easy") or txt:find("safe") then
								pcall(function()
									if getconnections and btn.MouseButton1Down then
										for _, conn in ipairs(getconnections(btn.MouseButton1Down)) do
											conn:Fire()
										end
									end
								end)
								pcall(function()
									if getconnections and btn.MouseButton1Click then
										for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
											conn:Fire()
										end
									end
								end)
								pcall(function()
									if getconnections and btn.Activated then
										for _, conn in ipairs(getconnections(btn.Activated)) do
											conn:Fire()
										end
									end
								end)
							end
						end
					end
				end

				-- Hide prompt to unblock screen
				pcall(function()
					if PromptControllerV2 and PromptControllerV2.Hide then
						PromptControllerV2.Hide()
					end
				end)
			end
		end)
	end

	-- 2. Ensure Easy / Safe Delivery mode is set (ONLY when not already in active delivery)
	local function ensureEasyDeliveryMode()
		handleDeliveryModePopup()

		-- Do NOT fire SetDeliveryMode if player already has an active delivery (prevents notification warning)
		if isPlayerOnDeliveryJob() then return end

		pcall(function()
			if DeliveryModeController and DeliveryModeController.RequestSetMode then
				DeliveryModeController.RequestSetMode("Safe")
			end
		end)
		pcall(function()
			if RemotesModule and DeliveryConstants then
				RemotesModule.fireServer(DeliveryConstants.RemoteEvents.SetDeliveryMode, "Safe")
			end
		end)
	end

	-- 3. Start Delivery shift at Offroad location ONLY if player is truly not in the job
	local function startOffroadDeliveryShift()
		-- NEVER step on the start pad if already on Delivery job (stepping on pad while on job ends the shift!)
		if isPlayerOnDeliveryJob() then return end

		State.deliveryStatus = "Starting Offroad Job (Easy)..."
		teleportTo(OFFROAD_JOB_PAD)
		task.wait(0.4)
		ensureEasyDeliveryMode()

		-- Request delivery job session with "Safe" (Easy) mode
		pcall(function()
			if RemotesModule and JobsConstants then
				RemotesModule.fireServer(JobsConstants.Remotes.RequestStartJobSession, "Delivery", "jobPad", "Safe")
			end
		end)

		task.wait(0.6)
		handleDeliveryModePopup()
	end

	-- 4. Interact with DeliveryLocation Part and ProximityPrompts in range
	local function interactAtLocation(targetPos)
		local root = getCharRoot()
		if not root or not targetPos then return end

		-- Fire DeliveryLocationInteracted remote for matching DeliveryLocation part
		pcall(function()
			for _, loc in ipairs(workspace:GetDescendants()) do
				if loc.Name == "DeliveryLocation" and loc:IsA("BasePart") then
					if (loc.Position - targetPos).Magnitude < 25 then
						if RemotesModule and DeliveryConstants then
							RemotesModule.fireServer(DeliveryConstants.RemoteEvents.DeliveryLocationInteracted, loc)
						end
					end
				end
			end
		end)

		-- Also fire any nearby ProximityPrompt
		pcall(function()
			for _, pp in ipairs(workspace:GetDescendants()) do
				if pp:IsA("ProximityPrompt") and pp.Enabled then
					local p = pp.Parent and pp.Parent:IsA("BasePart") and pp.Parent.Position
					if p and (p - root.Position).Magnitude < 30 then
						if fireproximityprompt then
							fireproximityprompt(pp)
						end
					end
				end
			end
		end)
	end

	-- 5. Main execution step for Auto Delivery
	local function executeDeliveryStep()
		handleDeliveryModePopup()

		local state = nil
		if DeliveryJobTask then
			pcall(function()
				state = DeliveryJobTask.GetCurrentDeliveryState()
			end)
		end

		local root = getCharRoot()
		if not root then return end

		-- If player does NOT have delivery job, start shift at offroad pad
		if not isPlayerOnDeliveryJob() then
			startOffroadDeliveryShift()
			task.wait(1)
			return
		end

		-- If player IS on delivery job but state is momentarily nil (transition between tasks)
		if not state then
			State.deliveryStatus = "Waiting for next task..."
			task.wait(0.5)
			return
		end

		local itemsCarried = state.ItemsCarried or 0
		local maxCapacity  = state.MaxCapacity or 4
		local remaining    = state.PackagesRemainingAtPickup

		local isPickupFull = (itemsCarried >= maxCapacity) or (remaining ~= nil and remaining == 0 and itemsCarried > 0)

		-- =============================================
		-- PHASE 1: DROPOFF CARGO AT DESTINATION
		-- Only deliver once ALL available packages at this spot are picked up!
		-- =============================================
		if isPickupFull and state.DestinationPosition then
			State.deliveryStatus = "Delivering " .. itemsCarried .. "/" .. maxCapacity .. " Cargo -> Dropoff"
			teleportTo(state.DestinationPosition)
			task.wait(0.3)
			interactAtLocation(state.DestinationPosition)
			task.wait(0.8)
			return
		end

		-- =============================================
		-- PHASE 2: PICKUP ALL CARGO AT PICKUP POINT
		-- Stay at pickup location until all packages (up to maxCapacity) are loaded
		-- =============================================
		if state.PickupPosition then
			State.deliveryStatus = "Picking up Cargo (" .. itemsCarried .. "/" .. maxCapacity .. ")..."
			teleportTo(state.PickupPosition)
			task.wait(0.3)
			interactAtLocation(state.PickupPosition)
			task.wait(0.8)
			return
		end

		task.wait(0.5)
	end

	------------------------------------------------
	-- 🔁 AUTO DELIVERY LOOP THREAD
	------------------------------------------------
	local deliveryThread = nil

	local function startDeliveryLoop()
		if deliveryThread then task.cancel(deliveryThread) end
		deliveryThread = task.spawn(function()
			State.deliveryStatus = "Initializing Offroad Delivery..."
			while State.autoDelivery do
				pcall(executeDeliveryStep)
				task.wait(0.1)
			end
			State.deliveryStatus = "Idle"
		end)
	end

	local function stopDeliveryLoop()
		if deliveryThread then
			task.cancel(deliveryThread)
			deliveryThread = nil
		end
		State.deliveryStatus = "Idle"
	end

	-- Listen for delivery completion to track count and update stats
	if RemotesModule and DeliveryConstants then
		pcall(function()
			RemotesModule.connect(DeliveryConstants.RemoteEvents.DeliveryCompleted, function(p)
				if p and not p.FailureReason then
					State.totalDeliveries = State.totalDeliveries + 1
				end
			end)
		end)
	end

	------------------------------------------------
	-- 📊 STATUS UI UPDATER
	------------------------------------------------
	local function updateStatusUI()
		if not (_G.HipHubDE and _G.HipHubDE.UI and _G.HipHubDE.UI.farm) then return end
		local label = _G.HipHubDE.UI.farm.statusLabel
		if not label then return end

		local anyActive = State.autoCollectCash or State.autoBankRob or State.autoDelivery
		local color = anyActive and "#00e6ff" or "#ff4d4d"
		local statusText = anyActive and "Active" or "Inactive"

		local deliveryInfo = State.autoDelivery
			and ("\nDelivery: <font color='#00e6ff'>" .. State.deliveryStatus .. "</font>" ..
			     " (Done: " .. State.totalDeliveries .. ")")
			or ""

		label.Text =
			"Status: <font color='" .. color .. "'>" .. statusText .. "</font>" ..
			"\nTotal Collected: " .. State.totalCollected ..
			deliveryInfo
	end

	-- Status update loop
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(updateStatusUI)
		end
	end)

	------------------------------------------------
	-- 🔧 STATE SETTER
	------------------------------------------------
	local function setState(newState)
		for k, v in pairs(newState) do
			State[k] = v

			if k == "autoCollectCash" then
				if v then startCollectLoop() else stopCollectLoop() end
			elseif k == "autoBankRob" then
				if v then startBankRobLoop() else stopBankRobLoop() end
			elseif k == "autoDelivery" then
				if v then startDeliveryLoop() else stopDeliveryLoop() end
			end
		end
		pcall(updateStatusUI)
	end

	------------------------------------------------
	-- 📤 EXPORT
	------------------------------------------------
	_G.HipHubFarm = {
		setState               = setState,
		getState               = function() return State end,
		collectAllCash         = collectAllCash,
		goToBank               = goToBank,
		findCashObjects        = findCashObjects,
		handleDeliveryModePopup = handleDeliveryModePopup,
		ensureEasyDeliveryMode = ensureEasyDeliveryMode,
		isPlayerOnDeliveryJob  = isPlayerOnDeliveryJob,
	}

	-- Apply persisted config
	if _G.HipHubConfig and _G.HipHubConfig.farm then
		local cfg = _G.HipHubConfig.farm
		State.collectDelay = cfg.collectDelay or 0.3
	end

	print("[HipHub DE Farm] Auto farm system initialized (Full Cargo Offroad Delivery ready)!")
end)

if not success then
	warn("[HipHub DE Farm Error]:", err)
end
