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
	-- Real workflow (from decompiled remotes):
	--   1. GoOnline
	--   2. SpawnCar:FireServer("Yamahax-MioSporty")      ← spawnmotor.lua exact call
	--   3. Server fires NewOrder with orderId (number), PickupPos, DropPos
	--   4. AcceptOrder:FireServer("AcceptOrder", orderId) ← takeorder.lua exact call
	--   5. Seat player on spawned motorcycle
	--   6. safeTween to PickupPos → wait for boarding → safeTween to DropPos
	--   7. AckTripComplete
	------------------------------------------------
	local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 10)
	local TaxiEvent = TaxiAssets and TaxiAssets:WaitForChild("Events", 10) and TaxiAssets.Events:WaitForChild("TaxiEvent", 10)
	local SpawnCarEvt = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
	local SpawnCarRemote = SpawnCarEvt and SpawnCarEvt:FindFirstChild("SpawnCar")

	-- Configurable bike model name (from spawnmotor.lua decompile)
	local TAXI_BIKE_NAME = "Yamahax-MioSporty"

	local taxiActive = false
	local taxiBusy = false
	local taxiCurrentOrderId = nil
	local taxiSpawnedVehicle = nil  -- reference to the bike model after spawning

	-- Spawn the RideGO motorbike using exact remote from spawnmotor.lua:
	-- SpawnCarEvents.SpawnCar:FireServer("Yamahax-MioSporty")
	local function spawnTaxiBike()
		if not SpawnCarRemote then return end
		pcall(function()
			SpawnCarRemote:FireServer(TAXI_BIKE_NAME)
		end)
		-- Wait for the vehicle to spawn in workspace
		task.wait(2)
		-- Try to find the newly spawned vehicle model in workspace
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj.Name:find("Mio") or (obj:IsA("Model") and obj.Name:find("Yamahax")) then
				local tag = obj:FindFirstChild("Owner") or obj:FindFirstChild("OwnerName")
				if (tag and tostring(tag.Value) == player.Name) or obj.Name:find(player.Name) then
					taxiSpawnedVehicle = obj
					break
				end
			end
		end
	end

	-- Seat the player in the spawned motorcycle
	local function sitOnBike()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end

		-- Already seated in a vehicle?
		if hum.SeatPart then return true end

		-- Find VehicleSeat in the spawned bike model
		local vehicleModel = taxiSpawnedVehicle
		if not vehicleModel or not vehicleModel.Parent then
			-- Fallback: search workspace for closest vehicle model with a VehicleSeat
			local root = char:FindFirstChild("HumanoidRootPart")
			local bestDist = 80
			for _, obj in ipairs(workspace:GetChildren()) do
				if obj:IsA("Model") then
					local seat = obj:FindFirstChildOfClass("VehicleSeat", true)
					if seat and root then
						local d = (seat.Position - root.Position).Magnitude
						if d < bestDist then
							bestDist = d
							vehicleModel = obj
						end
					end
				end
			end
		end

		if not vehicleModel then return false end

		local seat = vehicleModel:FindFirstChildOfClass("VehicleSeat", true)
		if seat then
			-- Teleport character near seat first, then sit
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.3)
			end
			seat:Sit(hum)
			task.wait(0.5)
			return hum.SeatPart ~= nil
		end
		return false
	end

	if TaxiEvent then
		TaxiEvent.OnClientEvent:Connect(function(eventType, payload)
			if not taxiActive then return end

			-- ─────────────────────────────────────────────
			-- Duty confirmation
			-- ─────────────────────────────────────────────
			if eventType == "DutyStarted" or eventType == "OnlineConfirmed" then
				UI.Notify("RideGO Online ✅", "Waiting for incoming orders...", 3, "success")

			-- ─────────────────────────────────────────────
			-- Duty dropped (server forced us offline)
			-- ─────────────────────────────────────────────
			elseif eventType == "DutyEnded" or eventType == "OfflineConfirmed" then
				if taxiActive and not taxiBusy then
					task.wait(1.5)
					TaxiEvent:FireServer("GoOnline")
				end

			-- ─────────────────────────────────────────────
			-- NEW ORDER INCOMING — accept immediately
			-- payload contains: OrderId (number), PickupPos, DropPos, IsAnomaly, TierName...
			-- ─────────────────────────────────────────────
			elseif (eventType == "OrderIncoming" or eventType == "NewOrder" or eventType == "Order") and not taxiBusy then
				local orderId = nil
				local pickupPos = nil
				local dropPos = nil
				local isAnom = false

				if type(payload) == "table" then
					-- Try common field names from server
					orderId = payload.OrderId or payload.Id or payload.orderId or payload.id
					pickupPos = payload.PickupPos or payload.PickUp or payload.pickup
					dropPos = payload.DropPos or payload.DropOff or payload.dropoff or payload.Drop
					isAnom = payload.IsAnomaly or payload.Anomaly or false
				elseif type(payload) == "number" then
					-- Sometimes payload IS the orderId directly
					orderId = payload
				end

				if not orderId then return end

				taxiCurrentOrderId = orderId
				taxiBusy = true

				if isAnom then
					UI.Notify("👻 Anomaly Passenger!", "Rare tier order incoming!", 4, "warning")
				end

				task.spawn(function()
					-- Step 1: Accept the order
					-- From takeorder.lua: TaxiEvent:FireServer("AcceptOrder", 597259)
					TaxiEvent:FireServer("AcceptOrder", orderId)
					task.wait(0.5)
					UI.Notify("Order Accepted #" .. tostring(orderId), isAnom and "👻 ANOMALY PASSENGER" or "Slide accepted!", 2, "success")

					-- Step 2: Sit on the motorcycle (bike was pre-spawned at GoOnline)
					UI.Notify("Mounting Bike", "Getting on Yamahax-MioSporty...", 2, "warning")
					local seated = sitOnBike()
					if not seated then
						-- Bike may not be spawned yet; spawn and retry
						spawnTaxiBike()
						task.wait(1)
						sitonBike = sitOnBike()
					end

					-- Step 3: Ride to passenger pickup
					if pickupPos then
						UI.Notify("Riding to Pickup 🏍️", "Heading to passenger...", 2, "warning")
						safeTweenTo(CFrame.new(pickupPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
					end

					-- Step 4: Passenger boards (wait)
					task.wait(2.5)

					-- Step 5: Ride to drop-off
					if dropPos and taxiActive then
						UI.Notify("Riding to Drop-off 📍", "Delivering passenger...", 2, "warning")
						safeTweenTo(CFrame.new(dropPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
					end

					-- Step 6: Trip complete
					task.wait(0.5)
					if taxiActive then
						TaxiEvent:FireServer("AckTripComplete")
						UI.Notify("Trip Complete! 🏆", "Fare earned. Waiting for next order...", 3, "success")
					end

					taxiBusy = false
					taxiCurrentOrderId = nil

					-- Re-enter duty automatically
					if taxiActive then
						task.wait(1)
						TaxiEvent:FireServer("GoOnline")
					end
				end)

			-- ─────────────────────────────────────────────
			-- Server confirms our AcceptOrder (some games fire this)
			-- ─────────────────────────────────────────────
			elseif eventType == "OrderAccepted" then
				-- Trip data may include positions we didn't have before
				if payload and type(payload) == "table" then
					local pickupPos = payload.PickupPos or payload.PickUp
					local dropPos = payload.DropPos or payload.DropOff
					-- Update live tween target if we have a running task
					if pickupPos and not taxiBusy then
						task.spawn(function()
							taxiBusy = true
							safeTweenTo(CFrame.new(pickupPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
							task.wait(2)
							if dropPos and taxiActive then
								safeTweenTo(CFrame.new(dropPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
							end
							task.wait(0.5)
							TaxiEvent:FireServer("AckTripComplete")
							taxiBusy = false
						end)
					end
				end

			-- ─────────────────────────────────────────────
			-- Server independently confirms trip start with positions
			-- ─────────────────────────────────────────────
			elseif eventType == "TripStarted" then
				if payload and payload.DropPos and taxiActive and not taxiBusy then
					task.spawn(function()
						safeTweenTo(CFrame.new(payload.DropPos) + Vector3.new(0, 2, 0), Config.taxiSpeed)
						task.wait(0.5)
						TaxiEvent:FireServer("AckTripComplete")
						taxiBusy = false
					end)
				end

			elseif eventType == "OrderCompleted" or eventType == "TripCompleted" then
				TaxiEvent:FireServer("AckTripComplete")
				taxiBusy = false

			elseif eventType == "OrderCancelled" or eventType == "OrderExpired" or eventType == "OrderDeclined" then
				taxiBusy = false
				taxiCurrentOrderId = nil
				UI.Notify("Order Cancelled", "Re-entering duty...", 2, "warning")
				if taxiActive then
					task.wait(1)
					TaxiEvent:FireServer("GoOnline")
				end
			end
		end)
	end

	local function toggleAutoRideGO(state)
		taxiActive = state
		taxiBusy = false
		taxiSpawnedVehicle = nil
		Config.autoRideGO = state

		if state then
			changeTeam("RideGO Driver")
			task.wait(1)

			-- Step A: Dismiss intro tutorial if showing
			if TaxiEvent then
				TaxiEvent:FireServer("DismissIntro")
				task.wait(0.3)
			end

			-- Step B: Spawn motorcycle FIRST before going online
			-- From spawnmotor.lua: SpawnCarEvents.SpawnCar:FireServer("Yamahax-MioSporty")
			UI.Notify("Spawning Bike 🏍️", "Spawning Yamahax-MioSporty...", 2, "warning")
			spawnTaxiBike()

			-- Step C: Go online to receive orders
			if TaxiEvent then
				TaxiEvent:FireServer("GoOnline")
			end

			UI.Notify("Auto RideGO Active ✅", "Bike spawned. Waiting for orders.", 3, "success")
		else
			taxiBusy = false
			taxiSpawnedVehicle = nil
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
