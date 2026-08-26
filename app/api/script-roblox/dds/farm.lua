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
	-- Confirmed via MCP remote inspection:
	--   EVENT:  "OrderOffer"  (NOT "NewOrder"/"OrderIncoming")
	--   ACCEPT: TaxiEvent:FireServer("AcceptOrder", Token)  ← Token is a NUMBER in payload
	--   RIDE:   ProximityPrompt ActionText="Ride", ObjectText="Motorcycle" on DriveSeat
	--           → safeTween to DriveSeat.Position → fireproximityprompt(prompt)
	--   SPAWN:  SpawnCarEvents.SpawnCar:FireServer("Yamahax-MioSporty")
	--   NOTE:   OrderOffer has NO PickupPos/DropPos — only PickupAddr/DropAddr text
	--           Position data arrives in a follow-up event after AcceptOrder
	------------------------------------------------
	local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 10)
	local TaxiEvent = TaxiAssets and TaxiAssets:WaitForChild("Events", 10) and TaxiAssets.Events:WaitForChild("TaxiEvent", 10)
	local SpawnCarEvt = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
	local SpawnCarRemote = SpawnCarEvt and SpawnCarEvt:FindFirstChild("SpawnCar")

	local TAXI_BIKE_NAME  = "Yamahax-MioSporty"
	local taxiActive      = false
	local taxiBusy        = false
	local taxiToken       = nil   -- current Token from OrderOffer
	local taxiPickupPos   = nil   -- set by TripData/TripStarted after AcceptOrder
	local taxiDropPos     = nil

	-- ── Spawn motorcycle via exact remote from spawnmotor.lua ──────────────
	local function spawnTaxiBike()
		if not SpawnCarRemote then return end
		pcall(function() SpawnCarRemote:FireServer(TAXI_BIKE_NAME) end)
		task.wait(2.5)
	end

	-- ── Find the Ride ProximityPrompt on the spawned motorcycle ──────────
	-- Confirmed: ActionText="Ride", ObjectText="Motorcycle" on DriveSeat part
	local function findRidePrompt()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt")
				and obj.ActionText == "Ride"
				and obj.ObjectText == "Motorcycle"
				and obj.Enabled then
				-- Check it belongs to our player's bike (model name contains playerName)
				local model = obj.Parent and obj.Parent.Parent
				if model and model.Name:find(player.Name) then
					return obj, obj.Parent  -- prompt, DriveSeat part
				end
			end
		end
		-- Fallback: return ANY enabled Ride/Motorcycle prompt
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt")
				and obj.ActionText == "Ride"
				and obj.Enabled then
				return obj, obj.Parent
			end
		end
		return nil, nil
	end

	-- ── Tween to bike then fireproximityprompt to mount ──────────────────
	local function mountBike()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if hum.SeatPart then return true end  -- already seated

		local prompt, seatPart = findRidePrompt()
		if not prompt or not seatPart then
			UI.Notify("⚠️ Bike Not Found", "Could not locate motorcycle Ride prompt", 2, "warning")
			return false
		end

		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			-- Step 1: safeTween to the DriveSeat position
			local targetCF = seatPart.CFrame + Vector3.new(0, 3, 0)
			safeTweenTo(targetCF, 30)
			task.wait(0.3)

			-- Step 2: fire the ProximityPrompt to mount
			if fireproximityprompt then
				pcall(fireproximityprompt, prompt)
			else
				-- Fallback: teleport directly onto seat and sit
				root.CFrame = seatPart.CFrame + Vector3.new(0, 1, 0)
				task.wait(0.2)
				local seat = seatPart:IsA("VehicleSeat") and seatPart
					or seatPart.Parent:FindFirstChildOfClass("VehicleSeat", true)
				if seat then seat:Sit(hum) end
			end
			task.wait(1)
		end

		return hum.SeatPart ~= nil
	end

	-- ── Execute a trip: mount → ride to pickup → ride to dropoff → complete
	local function executeTripAsync(token, pickupPos, dropPos, passengerName)
		taxiToken   = token
		taxiBusy    = true
		taxiPickupPos = pickupPos
		taxiDropPos   = dropPos

		-- 1. Accept order (Token from OrderOffer payload)
		TaxiEvent:FireServer("AcceptOrder", token)
		task.wait(0.5)
		UI.Notify("✅ Accepted Order", (passengerName or "Passenger") .. " — mounting bike...", 2, "success")

		-- 2. Mount the motorcycle (tween + ProximityPrompt Ride)
		local seated = mountBike()
		if not seated then
			-- Spawn a fresh bike and retry
			spawnTaxiBike()
			task.wait(1)
			seated = mountBike()
		end

		-- 3. Ride to pickup (if we have position from post-accept event)
		if taxiPickupPos and taxiActive then
			UI.Notify("🏍️ Riding to Pickup", "Heading to " .. tostring(taxiPickupPos), 2, "warning")
			safeTweenTo(CFrame.new(taxiPickupPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
		else
			-- No position yet — wait for TripData event to populate taxiPickupPos
			UI.Notify("📍 Waiting for trip data...", "Server sending positions...", 2, "warning")
			local waited = 0
			while not taxiPickupPos and taxiActive and waited < 8 do
				task.wait(0.5)
				waited = waited + 0.5
			end
			if taxiPickupPos and taxiActive then
				safeTweenTo(CFrame.new(taxiPickupPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
			end
		end

		-- 4. Wait for passenger to board
		task.wait(2.5)

		-- 5. Ride to drop-off
		if taxiDropPos and taxiActive then
			UI.Notify("📍 Riding to Drop-off", "Delivering passenger...", 2, "warning")
			safeTweenTo(CFrame.new(taxiDropPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
		end

		-- 6. Complete trip
		task.wait(0.5)
		if taxiActive then
			TaxiEvent:FireServer("AckTripComplete")
			UI.Notify("🏆 Trip Complete!", "Fare earned. Re-entering duty...", 3, "success")
		end

		taxiBusy    = false
		taxiToken   = nil
		taxiPickupPos = nil
		taxiDropPos   = nil

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
				UI.Notify("RideGO Online ✅", "Waiting for orders...", 3, "success")

			-- ── ORDER OFFER (confirmed event name from MCP) ───────────────
			-- Payload: { Token=720208, PassengerName="Dewi", PickupAddr="...", DropAddr="...",
			--            Fare=379032, DistKm=2.59, ExpiresIn=20, IsAnomaly=false, TierName="Common" }
			elseif eventType == "OrderOffer" and not taxiBusy then
				local token     = payload and (payload.Token or payload.token)
				local name      = payload and payload.PassengerName or "Passenger"
				local isAnom    = payload and payload.IsAnomaly or false
				local fare      = payload and payload.Fare or 0

				if not token then return end

				if isAnom then
					UI.Notify("👻 ANOMALY ORDER!", "Rare passenger: " .. name, 4, "warning")
				else
					UI.Notify("🛵 New Order!", name .. " — Rp " .. tostring(fare), 3, "success")
				end

				task.spawn(executeTripAsync, token, nil, nil, name)

			-- ── POST-ACCEPT: Trip data with positions (fires after AcceptOrder) ──
			elseif eventType == "TripData" or eventType == "TripStarted" or eventType == "OrderAccepted" then
				if payload then
					local pickup = payload.PickupPos or payload.PickUp or payload.pickup
					local drop   = payload.DropPos   or payload.DropOff or payload.Drop

					if pickup then taxiPickupPos = pickup end
					if drop   then taxiDropPos   = drop   end

					-- If we're busy with a trip that has no position yet, positions just arrived
					if taxiBusy and taxiPickupPos and not taxiDropPos then
						-- Only pickup arrived; drop will come in next event or when passenger boards
					end
				end

			-- ── DUTY DROPPED (server forced offline) ─────────────────────
			elseif eventType == "DutyEnded" then
				if taxiActive and not taxiBusy then
					task.wait(1.5)
					TaxiEvent:FireServer("GoOnline")
				end

			-- ── TRIP / ORDER COMPLETE ─────────────────────────────────────
			elseif eventType == "TripComplete" or eventType == "OrderComplete" then
				task.wait(0.3)
				TaxiEvent:FireServer("AckTripComplete")
				taxiBusy = false
				taxiToken = nil
				if taxiActive then
					task.wait(1.5)
					TaxiEvent:FireServer("GoOnline")
				end

			-- ── CANCEL / EXPIRE / DECLINE ─────────────────────────────────
			elseif eventType == "OrderExpired" or eventType == "OrderCancelled"
				or eventType == "OrderDeclined" or eventType == "TripCancelled" then
				taxiBusy  = false
				taxiToken = nil
				taxiPickupPos = nil
				taxiDropPos   = nil
				UI.Notify("❌ Order " .. eventType, "Re-entering duty...", 2, "warning")
				if taxiActive then
					local delay = (payload and type(payload.Delay) == "number" and payload.Delay) or 2
					task.wait(math.min(delay, 5))
					TaxiEvent:FireServer("GoOnline")
				end
			end
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

			-- Spawn motorcycle FIRST
			UI.Notify("🏍️ Spawning Bike", "Spawning " .. TAXI_BIKE_NAME .. "...", 2, "warning")
			spawnTaxiBike()

			-- Go online to receive OrderOffer events
			if TaxiEvent then
				TaxiEvent:FireServer("GoOnline")
			end

			UI.Notify("Auto RideGO Active ✅", "Bike ready. Waiting for OrderOffer.", 3, "success")
		else
			cancelActiveTween()
			if TaxiEvent then
				TaxiEvent:FireServer("GoOffline")
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
