-- 💰 HipHub DDS — Advanced Auto-Farm Suite
-- Drag Drive Simulator (Place ID: 131378148336503)
-- Features: Auto Barista, Auto RideGO Taxi, Auto Courier, Auto Drag Race, Auto Daily Quests, Auto Codes

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"].content
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local player = Players.LocalPlayer

	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoBarista = false,
		baristaMinigameDelay = 2.2,
		autoRideGO = false,
		taxiSpeed = 80,
		autoCourier = false,
		courierSpeed = 90,
		autoDragRace = false,
		dragTargetTime = 6.5,
		autoDailyQuests = false
	}

	------------------------------------------------
	-- 🛠️ SHARED UTILITIES & SAFE TWEEN ENGINE
	------------------------------------------------
	local currentTween = nil
	local function cancelActiveTween()
		if currentTween then
			currentTween:Cancel()
			currentTween = nil
		end
	end

	local function getRootPart()
		local char = player.Character
		if char then
			return char:FindFirstChild("HumanoidRootPart")
		end
		return nil
	end

	local function getVehicleOrRoot()
		local char = player.Character
		if not char then return nil end

		-- Check if seated in a vehicle
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart then
			local seat = humanoid.SeatPart
			local model = seat:FindFirstAncestorOfClass("Model")
			if model and model.PrimaryPart then
				return model.PrimaryPart, true
			end
			return seat, true
		end

		return char:FindFirstChild("HumanoidRootPart"), false
	end

	-- Safe anti-cheat compliant tween (Lerp/Tween without instant CFrame teleport flag)
	local function safeTweenTo(targetCFrame, speedStudsPerSec)
		local targetPart, isVehicle = getVehicleOrRoot()
		if not targetPart then return false end

		speedStudsPerSec = speedStudsPerSec or 80
		local currentPos = targetPart.Position
		local targetPos = typeof(targetCFrame) == "CFrame" and targetCFrame.Position or targetCFrame
		local dist = (currentPos - targetPos).Magnitude
		local duration = math.max(0.5, dist / speedStudsPerSec)

		local cframeGoal = typeof(targetCFrame) == "CFrame" and targetCFrame or CFrame.new(targetPos)

		cancelActiveTween()
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		currentTween = TweenService:Create(targetPart, tweenInfo, { CFrame = cframeGoal })
		currentTween:Play()

		local completed = false
		local conn = currentTween.Completed:Connect(function()
			completed = true
		end)

		local startTime = tick()
		while not completed and tick() - startTime < (duration + 2) do
			task.wait(0.1)
			-- Ensure targetPart still exists
			if not targetPart or not targetPart.Parent then break end
		end

		if conn then conn:Disconnect() end
		return completed
	end

	------------------------------------------------
	-- ☕ 1. AUTO BARISTA JOB (Starbooks Coffee)
	------------------------------------------------
	local BaristaAssets = ReplicatedStorage:WaitForChild("BaristaAssets", 10)
	local BaristaEvent = BaristaAssets and BaristaAssets:WaitForChild("Events", 10) and BaristaAssets.Events:WaitForChild("BaristaEvent", 10)
	local BaristaJob = workspace:FindFirstChild("BaristaJob")

	local baristaActive = false
	local baristaToken = nil
	local baristaCurrentOrder = nil
	local baristaThread = nil

	local function changeTeam(teamName)
		pcall(function()
			local teamChangeRequest = ReplicatedStorage:FindFirstChild("teamChangeRequest")
			if teamChangeRequest then
				teamChangeRequest:FireServer(teamName)
			end
			local jobEvents = ReplicatedStorage:FindFirstChild("JobEvents")
			if jobEvents and jobEvents:FindFirstChild("TeamChangeRequest") then
				jobEvents.TeamChangeRequest:FireServer(teamName)
			end
		end)
	end

	if BaristaEvent then
		BaristaEvent.OnClientEvent:Connect(function(action, data)
			if not baristaActive then return end

			if action == "JobStarted" then
				baristaToken = data and data.Token
				task.wait(0.5)
				BaristaEvent:FireServer("RequestCustomer")
			elseif action == "SpawnNPC" then
				baristaToken = data and data.Token
				baristaCurrentOrder = data
				if data and (data.IsAnomalyNPC or data.IsMenuAnomaly) then
					UI.Notify("👻 Anomaly Customer!", "Serving: " .. tostring(data.MenuName), 3, "warning")
				end

				task.delay(1.5, function()
					if baristaActive and BaristaEvent then
						BaristaEvent:FireServer("TryBrew")
					end
				end)
			elseif action == "StartMinigameAllowed" then
				-- Solve minigame with realistic delay to evade server speed check
				local delayTime = Config.baristaMinigameDelay or 2.2
				task.delay(delayTime, function()
					if baristaActive and BaristaEvent and baristaToken then
						BaristaEvent:FireServer("CompleteMinigame", { Token = baristaToken })
					end
				end)
			elseif action == "BrewSuccess" then
				task.delay(0.5, function()
					if baristaActive and BaristaEvent then
						BaristaEvent:FireServer("ServeOrder")
					end
				end)
			elseif action == "OrderServed" then
				task.delay(1.5, function()
					if baristaActive and BaristaEvent then
						BaristaEvent:FireServer("RequestCustomer")
					end
				end)
			elseif action == "MachineBroken" then
				task.delay(0.5, function()
					if baristaActive and BaristaEvent then
						BaristaEvent:FireServer("RestockSupplies")
					end
				end)
			elseif action == "RestockSuccess" then
				task.delay(0.5, function()
					if baristaActive and BaristaEvent then
						BaristaEvent:FireServer("TryBrew")
					end
				end)
			elseif action == "DirtyTable" then
				task.delay(0.5, function()
					if baristaActive and BaristaEvent and data then
						BaristaEvent:FireServer("CleanTable", data)
					end
				end)
			end
		end)
	end

	local function toggleAutoBarista(state)
		baristaActive = state
		Config.autoBarista = state

		if state then
			changeTeam("Barista")
			task.wait(1)

			-- Teleport to barista counter safely if too far
			local root = getRootPart()
			if root and BaristaJob and BaristaJob:FindFirstChild("Counter") then
				local counter = BaristaJob.Counter:FindFirstChild("PartModel") or BaristaJob.Counter
				local part = counter:FindFirstChildWhichIsA("BasePart", true)
				if part and (root.Position - part.Position).Magnitude > 50 then
					root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
					task.wait(1)
				end
			end

			if BaristaEvent then
				BaristaEvent:FireServer("ToggleJob")
				task.wait(0.5)
				BaristaEvent:FireServer("RequestCustomer")
			end
			UI.Notify("Auto Barista Started", "Automatically serving customers & solving minigames.", 3, "success")
		else
			if BaristaEvent then
				BaristaEvent:FireServer("ToggleJob")
			end
			UI.Notify("Auto Barista Stopped", "Shift ended.", 2, "warning")
		end
	end

	------------------------------------------------
	-- 🚕 2. AUTO RIDEGO TAXI (Motorbike Taxi Driver)
	-- Verified workflow & remotes:
	--   1. SpawnCar:FireServer("Yamahax-MioSporty")
	--   2. Mount bike via ProximityPrompt (ActionText="Ride", ObjectText="Motorcycle", parent="DriveSeat")
	--   3. GoOnline
	--   4. Server fires "OrderOffer" with { Token = <number>, ... }
	--   5. AcceptOrder:FireServer("AcceptOrder", Token)
	--   6. Server fires "OrderAccepted" with { PickupPos = Vector3, DropPos = Vector3 }
	--   7. safeTweenTo(PickupPos) → wait for boarding → safeTweenTo(DropPos)
	--   8. AckTripComplete:FireServer("AckTripComplete")
	------------------------------------------------
	local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 10)
	local TaxiEvent = TaxiAssets and TaxiAssets:WaitForChild("Events", 10) and TaxiAssets.Events:WaitForChild("TaxiEvent", 10)
	local SpawnCarEvt = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
	local SpawnCarRemote = SpawnCarEvt and SpawnCarEvt:FindFirstChild("SpawnCar")

	local TAXI_BIKE_NAME  = "Yamahax-MioSporty"
	local taxiActive      = false
	local taxiBusy        = false
	local taxiToken       = nil
	local taxiPickupPos   = nil
	local taxiDropPos     = nil
	local taxiOverlayPoller = nil

	-- ── Spawn motorcycle via exact remote from spawnmotor.lua ──────────────
	local function spawnTaxiBike()
		if not SpawnCarRemote then return end
		pcall(function() SpawnCarRemote:FireServer(TAXI_BIKE_NAME) end)
		task.wait(2)
	end

	-- ── Find the Ride ProximityPrompt on the motorcycle ───────────────────
	local function findRidePrompt()
		-- Priority 1: Check player's own bike in workspace
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt")
				and obj.ActionText == "Ride"
				and obj.ObjectText == "Motorcycle"
				and obj.Enabled then
				local model = obj.Parent and obj.Parent.Parent
				if model and model.Name:find(player.Name) then
					return obj, obj.Parent
				end
			end
		end
		-- Priority 2: Return any enabled Ride prompt
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt")
				and obj.ActionText == "Ride"
				and obj.Enabled then
				return obj, obj.Parent
			end
		end
		return nil, nil
	end

	-- ── Safe tween to motorcycle and hold Ride ProximityPrompt ───────────
	local function mountBike()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if hum.SeatPart then return true end  -- already seated

		local prompt, seatPart = findRidePrompt()
		if not prompt or not seatPart then
			UI.Notify("⚠️ Bike Not Found", "Spawning new motorcycle...", 2, "warning")
			spawnTaxiBike()
			prompt, seatPart = findRidePrompt()
			if not prompt or not seatPart then return false end
		end

		local root = char:FindFirstChild("HumanoidRootPart")
		if root and seatPart then
			-- Step 1: Smoothly tween to the motorcycle DriveSeat position
			local targetCF = seatPart.CFrame + Vector3.new(0, 1.5, 0)
			safeTweenTo(targetCF, 40)
			task.wait(0.2)
			root.CFrame = targetCF
			task.wait(0.1)

			-- Step 2: Hold Ride ProximityPrompt (simulates real key hold)
			if fireproximityprompt then
				pcall(fireproximityprompt, prompt)
			end
			pcall(function()
				prompt:InputHoldBegin()
				task.wait(prompt.HoldDuration + 0.15)
				prompt:InputHoldEnd()
			end)
			task.wait(0.8)
		end

		return hum.SeatPart ~= nil
	end

	-- ── Execute full trip workflow ────────────────────────────────────────
	local function executeTripAsync(token, name)
		if taxiBusy then return end
		taxiBusy = true
		taxiToken = token
		taxiPickupPos = nil
		taxiDropPos = nil

		-- 1. Accept the incoming order via Token
		TaxiEvent:FireServer("AcceptOrder", token)
		task.wait(0.4)
		UI.Notify("✅ Order Accepted", "Passenger: " .. tostring(name or "Passenger"), 2, "success")

		-- 2. Make sure we are mounted on the motorcycle
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.SeatPart) then
			UI.Notify("🏍️ Mounting Bike", "Getting on motorcycle...", 2, "warning")
			mountBike()
		end

		-- 3. Wait for OrderAccepted event with pickup/drop positions (or max 5s)
		local waitStart = tick()
		while not taxiPickupPos and taxiActive and (tick() - waitStart < 5) do
			task.wait(0.2)
		end

		-- 4. Ride to Passenger Pickup Position
		if taxiPickupPos and taxiActive then
			UI.Notify("🏍️ Heading to Pickup", "Riding to passenger...", 2, "warning")
			safeTweenTo(CFrame.new(taxiPickupPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
		end

		-- 5. Wait for passenger boarding
		task.wait(3)

		-- 6. Ride to Drop-off Position
		if taxiDropPos and taxiActive then
			UI.Notify("📍 Heading to Drop-off", "Delivering passenger...", 2, "warning")
			safeTweenTo(CFrame.new(taxiDropPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
		end

		-- 7. Complete Trip & Acknowledge
		task.wait(0.6)
		if taxiActive then
			TaxiEvent:FireServer("AckTripComplete")
			UI.Notify("🏆 Trip Complete!", "Fare earned. Waiting for next order...", 3, "success")
		end

		taxiBusy = false
		taxiToken = nil
		taxiPickupPos = nil
		taxiDropPos = nil

		-- 8. Automatically go online for the next trip
		if taxiActive then
			task.wait(1.5)
			TaxiEvent:FireServer("GoOnline")
		end
	end

	-- ── Main TaxiEvent listener ────────────────────────────────────────────
	if TaxiEvent then
		_G.HipHubTaxiLog = {}

		TaxiEvent.OnClientEvent:Connect(function(...)
			local raw = { ... }
			table.insert(_G.HipHubTaxiLog, { t = tick(), args = raw })

			if not taxiActive then return end

			local eventType = tostring(raw[1] or "")
			local payload   = type(raw[2]) == "table" and raw[2] or nil

			-- ── DUTY STARTED ──────────────────────────────────────────────
			if eventType == "DutyStarted" then
				UI.Notify("RideGO Online ✅", "Mounted & waiting for orders...", 3, "success")

			-- ── ORDER OFFER ───────────────────────────────────────────────
			elseif eventType == "OrderOffer" and not taxiBusy then
				local token = payload and (payload.Token or payload.token)
				local name  = payload and payload.PassengerName or "Passenger"
				local isAnom = payload and payload.IsAnomaly or false
				local fare  = payload and payload.Fare or 0

				if not token then return end

				if isAnom then
					UI.Notify("👻 ANOMALY ORDER!", "Rare passenger: " .. name, 4, "warning")
				else
					UI.Notify("🛵 New Order!", name .. " — Rp " .. tostring(fare), 3, "success")
				end

				task.spawn(executeTripAsync, token, name)

			-- ── ORDER ACCEPTED (provides actual PickupPos & DropPos) ──────
			elseif eventType == "OrderAccepted" then
				if payload then
					if payload.PickupPos then taxiPickupPos = payload.PickupPos end
					if payload.DropPos then taxiDropPos = payload.DropPos end
				end

			-- ── PASSENGER BOARDING ────────────────────────────────────────
			elseif eventType == "PassengerBoarding" then
				-- Passenger is walking to bike

			-- ── TRIP STARTED ──────────────────────────────────────────────
			elseif eventType == "TripStarted" then
				if payload and payload.DropPos then
					taxiDropPos = payload.DropPos
				end

			-- ── DUTY DROPPED ──────────────────────────────────────────────
			elseif eventType == "DutyEnded" then
				if taxiActive and not taxiBusy then
					task.wait(1.5)
					TaxiEvent:FireServer("GoOnline")
				end

			-- ── ORDER COMPLETED ───────────────────────────────────────────
			elseif eventType == "OrderCompleted" or eventType == "TripComplete" then
				task.wait(0.3)
				TaxiEvent:FireServer("AckTripComplete")
				taxiBusy = false
				taxiToken = nil
				if taxiActive then
					task.wait(1.5)
					TaxiEvent:FireServer("GoOnline")
				end

			-- ── ORDER CANCELLED / EXPIRED ─────────────────────────────────
			elseif eventType == "OrderExpired" or eventType == "OrderCancelled" or eventType == "OrderDeclined" then
				taxiBusy = false
				taxiToken = nil
				taxiPickupPos = nil
				taxiDropPos = nil
				UI.Notify("Order Reset", "Waiting for next offer...", 2, "warning")
				if taxiActive then
					task.wait(2)
					TaxiEvent:FireServer("GoOnline")
				end
			end
		end)
	end

	-- ── Phone Screen Overlay Poller (backup) ──────────────────────────────
	local function startPhoneOverlayPoller()
		if taxiOverlayPoller then return end
		taxiOverlayPoller = task.spawn(function()
			while taxiActive do
				task.wait(0.5)
				if not taxiBusy and taxiActive then
					pcall(function()
						local pg = player:FindFirstChild("PlayerGui")
						local phone = pg and pg:FindFirstChild("Phone")
						local rideGO = phone and phone:FindFirstChild("RideGO", true)
						local appFrame = rideGO and rideGO:FindFirstChild("AppFrame")
						local overlay = appFrame and appFrame:FindFirstChild("OrderOverlay")

						if overlay and overlay.Visible and not taxiBusy then
							-- Order offer is showing on screen: find token from recent logs or accept directly
							if #_G.HipHubTaxiLog > 0 then
								local last = _G.HipHubTaxiLog[#_G.HipHubTaxiLog]
								local args = last.args or {}
								if args[1] == "OrderOffer" and type(args[2]) == "table" and args[2].Token then
									task.spawn(executeTripAsync, args[2].Token, args[2].PassengerName)
								end
							end
						end
					end)
				end
			end
			taxiOverlayPoller = nil
		end)
	end

	local function toggleAutoRideGO(state)
		taxiActive    = state
		taxiBusy      = false
		taxiToken     = nil
		taxiPickupPos = nil
		taxiDropPos   = nil
		Config.autoRideGO = state

		if state then
			changeTeam("RideGO Driver")
			task.wait(1)

			if TaxiEvent then
				TaxiEvent:FireServer("DismissIntro")
				task.wait(0.3)
			end

			-- 1. Spawn motorcycle
			UI.Notify("🏍️ Spawning Bike", "Spawning " .. TAXI_BIKE_NAME .. "...", 2, "warning")
			spawnTaxiBike()

			-- 2. Mount the motorcycle immediately
			UI.Notify("🏍️ Mounting Bike", "Getting on motorcycle...", 2, "warning")
			mountBike()

			-- 3. Go online to receive OrderOffer events
			if TaxiEvent then
				TaxiEvent:FireServer("GoOnline")
			end

			-- 4. Start overlay backup poller
			startPhoneOverlayPoller()

			UI.Notify("Auto RideGO Active ✅", "Bike ready & seated. Waiting for orders.", 3, "success")
		else
			if taxiOverlayPoller then
				task.cancel(taxiOverlayPoller)
				taxiOverlayPoller = nil
			end
			cancelActiveTween()
			if TaxiEvent then
				TaxiEvent:FireServer("GoOffline")
			end
			UI.Notify("Auto RideGO Stopped", "Went offline.", 2, "warning")
		end
	end

	------------------------------------------------
	-- 📦 3. AUTO COURIER DELIVERY (Package Delivery)
	------------------------------------------------

	local courierActive = false
	local courierThread = nil

	local function toggleAutoCourier(state)
		courierActive = state
		Config.autoCourier = state

		if state then
			changeTeam("Courier")
			task.wait(1)

			if not courierThread then
				courierThread = task.spawn(function()
					while courierActive do
						local success, loopErr = pcall(function()
							local livrason = workspace:FindFirstChild("Livrason")
							local settingsMod = ReplicatedStorage:FindFirstChild("Delivery System") and ReplicatedStorage["Delivery System"]:FindFirstChild("Settings")

							-- Request job if needed
							if settingsMod and settingsMod:FindFirstChild("ServiceEvent") then
								settingsMod.ServiceEvent:FireServer("RequestJobUpdate")
							end

							-- Find active destination prompt in Livrason
							if livrason and livrason:FindFirstChild("Location") then
								local activeTarget = nil
								for _, loc in ipairs(livrason.Location:GetChildren()) do
									local block = loc:FindFirstChild("Block")
									local prompt = block and block:FindFirstChildOfClass("ProximityPrompt")
									if prompt and prompt.Enabled then
										activeTarget = block
										break
									end
								end

								if activeTarget then
									-- Smooth transit to delivery block
									safeTweenTo(activeTarget.CFrame + Vector3.new(0, 3, 0), Config.courierSpeed)
									task.wait(0.5)
									local prompt = activeTarget:FindFirstChildOfClass("ProximityPrompt")
									if prompt and prompt.Enabled and fireproximityprompt then
										fireproximityprompt(prompt)
									end
									task.wait(1)
								else
									-- Go pick up package at Courier Office
									local jobPoint = workspace:FindFirstChild("Job_Point")
									local courierPt = jobPoint and (jobPoint:FindFirstChild("Courier_Point") or jobPoint:FindFirstChild("Courier_Point1"))
									if courierPt then
										local part = courierPt:FindFirstChildWhichIsA("BasePart", true)
										if part then
											safeTweenTo(part.CFrame + Vector3.new(0, 3, 0), Config.courierSpeed)
											task.wait(1)
										end
									end
								end
							end
						end)

						task.wait(1)
					end
					courierThread = nil
				end)
			end

			UI.Notify("Auto Courier Started", "Delivering packages continuously.", 3, "success")
		else
			if courierThread then
				task.cancel(courierThread)
				courierThread = nil
			end
			cancelActiveTween()
			UI.Notify("Auto Courier Stopped", "Delivery loop halted.", 2, "warning")
		end
	end

	------------------------------------------------
	-- 🏁 4. AUTO DRAG RACE (Circuit Drag Strip)
	------------------------------------------------
	local dragActive = false
	local dragThread = nil

	local function toggleAutoDragRace(state)
		dragActive = state
		Config.autoDragRace = state

		if state then
			if not dragThread then
				dragThread = task.spawn(function()
					while dragActive do
						pcall(function()
							local sdt = workspace:FindFirstChild("SensorDragTimer")
							local startFolder = sdt and sdt:FindFirstChild("SensorStart")
							local finishFolder = sdt and sdt:FindFirstChild("SensorFinish")

							local root = getRootPart()
							if root and startFolder and finishFolder then
								local startPart = startFolder:FindFirstChildWhichIsA("BasePart", true)
								local finishPart = finishFolder:FindFirstChildWhichIsA("BasePart", true)

								if startPart and finishPart then
									-- Line up at start line
									root.CFrame = startPart.CFrame + Vector3.new(0, 3, 0)
									task.wait(2)

									-- Accelerate / glide smoothly to finish line with target time
									local targetDuration = Config.dragTargetTime or 6.5
									local speed = (startPart.Position - finishPart.Position).Magnitude / targetDuration
									safeTweenTo(finishPart.CFrame + Vector3.new(0, 3, 0), speed)
									task.wait(4)
								end
							end
						end)
						task.wait(2)
					end
					dragThread = nil
				end)
			end
			UI.Notify("Auto Drag Race Active", "Racing drag strip for maximum XP.", 3, "success")
		else
			if dragThread then
				task.cancel(dragThread)
				dragThread = nil
			end
			cancelActiveTween()
			UI.Notify("Auto Drag Race Stopped", "Drag strip loop halted.", 2, "warning")
		end
	end

	------------------------------------------------
	-- 📜 5. AUTO DAILY QUESTS CLAIMER
	------------------------------------------------
	local function claimAllQuests()
		local dq = ReplicatedStorage:FindFirstChild("DailyQuestRemotes")
		if not dq then return end

		local getQuest = dq:FindFirstChild("GetQuestData")
		local claimQuest = dq:FindFirstChild("ClaimQuest")

		if getQuest and claimQuest then
			local questData = getQuest:InvokeServer()
			local claimedCount = 0
			if questData then
				for categoryName, categoryQuests in pairs(questData) do
					for questKey, q in pairs(categoryQuests) do
						if q.Completed and not q.Claimed then
							claimQuest:FireServer(questKey)
							claimedCount = claimedCount + 1
							task.wait(0.2)
						end
					end
				end
			end

			if claimedCount > 0 then
				UI.Notify("Quests Claimed!", "Successfully claimed " .. claimedCount .. " rewards.", 3, "success")
			else
				UI.Notify("Daily Quests", "All completed quests are already claimed.", 2, "warning")
			end
		end
	end

	------------------------------------------------
	-- 🎁 6. AUTO REDEEM ACTIVE CODES
	------------------------------------------------
	local ACTIVE_CODES = {
		"LIMITED",
		"BIGUPDATE",
		"DRAGRACE",
		"ADVTEAM",
		"SURAKARTA",
		"STARBOOKS",
		"RIDEGO",
		"RELEASE"
	}

	local function redeemAllCodes()
		local rc = ReplicatedStorage:FindFirstChild("RedeemCodeEvents")
		local redeemFunc = rc and rc:FindFirstChild("Redeem")
		if not redeemFunc then return end

		task.spawn(function()
			for _, code in ipairs(ACTIVE_CODES) do
				pcall(function()
					local res = redeemFunc:InvokeServer(code)
					task.wait(0.4)
				end)
			end
			UI.Notify("Codes Redeemed", "Attempted redemption on all promotional codes.", 3, "success")
		end)
	end

	------------------------------------------------
	-- 🖼️ UI COMPONENTS IN FARM TAB
	------------------------------------------------
	UI.AddSection(tab, "Starbooks Barista Auto-Farm")
	UI.AddToggle(tab, "Auto Barista Shift", "Automates customer ordering, coffee brewing minigame & cleanup", Config.autoBarista, function(state)
		toggleAutoBarista(state)
	end)

	UI.AddSlider(tab, "Minigame Solve Delay (s)", 1, 5, math.floor(Config.baristaMinigameDelay or 2), function(val)
		Config.baristaMinigameDelay = val
	end)

	UI.AddSection(tab, "RideGO Taxi Auto-Driver")
	UI.AddToggle(tab, "Auto RideGO Taxi", "Goes online, auto-accepts orders & smoothly navigates to drops", Config.autoRideGO, function(state)
		toggleAutoRideGO(state)
	end)

	UI.AddSlider(tab, "Taxi Speed (Studs/s)", 40, 160, math.floor(Config.taxiSpeed or 80), function(val)
		Config.taxiSpeed = val
	end)

	UI.AddSection(tab, "Courier Package Delivery")
	UI.AddToggle(tab, "Auto Courier Delivery", "Picks up packages and completes deliveries continuously", Config.autoCourier, function(state)
		toggleAutoCourier(state)
	end)

	UI.AddSlider(tab, "Courier Speed (Studs/s)", 40, 180, math.floor(Config.courierSpeed or 90), function(val)
		Config.courierSpeed = val
	end)

	UI.AddSection(tab, "Drag Race Strip Automation")
	UI.AddToggle(tab, "Auto Drag Racer", "Automatically lines up, launches & finishes drag races", Config.autoDragRace, function(state)
		toggleAutoDragRace(state)
	end)

	UI.AddSlider(tab, "Target Record Time (s)", 3, 12, math.floor(Config.dragTargetTime or 6), function(val)
		Config.dragTargetTime = val
	end)

	UI.AddSection(tab, "Quests & Promo Codes")
	UI.AddButton(tab, "Claim All Finished Quests", "Claim Quests", function()
		claimAllQuests()
	end)

	UI.AddButton(tab, "Redeem All Promo Codes", "Redeem Codes", function()
		redeemAllCodes()
	end)
end)

if not success then
	warn("[HipHub DDS Farm Error]:", err)
end
