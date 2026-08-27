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
		taxiSpeed = 90,
		autoCourier = false,
		courierSpeed = 95,
		autoDragRace = false,
		dragTargetTime = 6.5,
		autoDailyQuests = false
	}

	------------------------------------------------
	-- 🛠️ CDID-STYLE ROBUST VEHICLE & MOVEMENT ENGINE
	------------------------------------------------
	local currentDriveConn = nil
	local isDrivingActive  = false

	local function cancelActiveDrive()
		if currentDriveConn then
			pcall(function() currentDriveConn:Disconnect() end)
			currentDriveConn = nil
		end
		isDrivingActive = false
	end

	local function getRootPart()
		local char = player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function getPlayerVehicle()
		local char = player.Character
		if not char then return nil, nil end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart then
			local seat = humanoid.SeatPart
			local model = seat:FindFirstAncestorOfClass("Model")
			return model or seat.Parent, seat
		end

		-- Search workspace direct children for player's motorcycle (avoid matching player's Character model)
		for _, c in ipairs(workspace:GetChildren()) do
			if c:IsA("Model") and c ~= char and (c.Name:find(player.Name) or c.Name:find("Montor") or c:FindFirstChild("DriveSeat")) then
				local seat = c:FindFirstChild("DriveSeat", true) or c:FindFirstChildWhichIsA("VehicleSeat", true) or c:FindFirstChildWhichIsA("Seat", true)
				if seat then return c, seat end
			end
		end

		return nil, nil
	end

	-- Spawns an invisible collision safety plate underneath destination
	local function ensureSafetyPlate(pos, width)
		width = width or 55
		local plate = workspace:FindFirstChild("__DdsSafetyPlate")
		if not plate then
			plate = Instance.new("Part")
			plate.Name = "__DdsSafetyPlate"
			plate.Anchored = true
			plate.CanCollide = true
			plate.Transparency = 1
			plate.CastShadow = false
			plate.Material = Enum.Material.SmoothPlastic
			pcall(function() plate.Parent = workspace end)
		end
		plate.Size = Vector3.new(width, 4, width)
		plate.CFrame = CFrame.new(pos.X, pos.Y - 2.0, pos.Z)
		return plate
	end

	local function requestStreamAsync(pos)
		pcall(function()
			if player and player.RequestStreamAroundAsync then
				task.spawn(function()
					pcall(function() player:RequestStreamAroundAsync(pos, 2) end)
				end)
			end
		end)
	end

	local function neutralizeBikeHazards(car)
		if not car then return end
		pcall(function()
			for _, s in ipairs(car:GetDescendants()) do
				if s:IsA("LocalScript") and (s.Name:find("Fall") or s.Name:find("Crash") or s.Name:find("Accident")) then
					s.Disabled = true
				end
			end
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			end
		end)
	end

	local function safelySettleAndUnanchor(car, safePos)
		if not car then return end
		neutralizeBikeHazards(car)
		pcall(function()
			if safePos then
				ensureSafetyPlate(safePos, 55)
				car:PivotTo(CFrame.new(safePos + Vector3.new(0, 2.0, 0)))
			end
			-- Restore ONLY official collision parts on the DDS motorcycle to prevent physics explosion/unseat
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					local name = part.Name:lower()
					if name == "dds_collision" or name == "primarypart" or name:find("tire") or name == "paint" or name == "foot" or name == "p" then
						part.CanCollide = true
					else
						part.CanCollide = false
					end
				end
			end
			local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChild("DriveSeat", true)
			if seat then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
				seat.AssemblyLinearVelocity = Vector3.zero
			end

			-- Ensure player stays firmly seated on the motorcycle
			local char = player.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and seat and hum then
				if not hum.Sit or hum.SeatPart ~= seat then
					root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
					hum.Sit = true
					seat:Sit(hum)
				end
			end
		end)
	end

	-- 🛡️ Holds vehicle stably anchored on surface so it NEVER falls into void while waiting
	local function holdVehicleStable(targetPos, maxDuration, conditionFunc)
		local car, seat = getPlayerVehicle()
		if not car then return end

		local destP = typeof(targetPos) == "CFrame" and targetPos.Position or targetPos
		-- Raycast down to find true solid surface
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { car, player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(Vector3.new(destP.X, destP.Y + 30, destP.Z), Vector3.new(0, -60, 0), rayParams)
		local groundY = hit and (hit.Position.Y + 2.2) or (destP.Y + 2.0)
		local stablePos = Vector3.new(destP.X, groundY, destP.Z)
		local stableCF = CFrame.new(stablePos)

		ensureSafetyPlate(stablePos, 55)

		local t0 = tick()
		while (not conditionFunc or conditionFunc()) and (tick() - t0 < maxDuration) and taxiActive do
			pcall(function()
				car:PivotTo(stableCF)

				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum  = char and char:FindFirstChildOfClass("Humanoid")
				if root and seat and hum then
					if not hum.Sit or hum.SeatPart ~= seat then
						root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
						hum.Sit = true
						seat:Sit(hum)
					end
				end

				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
			task.wait(0.1)
		end
	end

	-- 🚗 Safe Direct-Landing Vehicle Engine (Zero Void Fly, 100% Anti-Kick)
	local function driveVehicleTo(targetPos, speed)
		if typeof(targetPos) == "CFrame" then
			targetPos = targetPos.Position
		end
		if typeof(targetPos) ~= "Vector3" then return false end

		local car, seat = getPlayerVehicle()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum  = char and char:FindFirstChildOfClass("Humanoid")

		if not car or not seat or not (hum and hum.SeatPart) then
			-- Ensure player is mounted before landing
			if mountBike and not (hum and hum.SeatPart) then
				mountBike()
				car, seat = getPlayerVehicle()
			end
			if not car or not seat then
				warn("[HipHub DDS] driveVehicleTo: Vehicle not found, operation aborted to protect player")
				return false
			end
		end

		cancelActiveDrive()
		isDrivingActive = true
		neutralizeBikeHazards(car)

		-- 1. Ensure collision safety plate & chunk streaming around target
		ensureSafetyPlate(targetPos, 60)
		requestStreamAsync(targetPos)
		task.wait(0.15)

		-- 2. Calculate true solid ground elevation
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { car, char, workspace:FindFirstChild("__DdsSafetyPlate") }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(Vector3.new(targetPos.X, targetPos.Y + 35, targetPos.Z), Vector3.new(0, -70, 0), rayParams)
		local groundY = hit and (hit.Position.Y + 1.8) or (targetPos.Y + 1.5)
		local safePos = Vector3.new(targetPos.X, groundY, targetPos.Z)

		-- 3. Direct Landing on solid ground (Zero mid-air void transit)
		pcall(function()
			local currentPivot = car:GetPivot()
			local safeCF = CFrame.new(safePos) * (currentPivot - currentPivot.Position)
			car:PivotTo(safeCF)

			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end

			if root and seat and hum then
				root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
				hum.Sit = true
				seat:Sit(hum)
			end
		end)

		task.wait(0.2)
		safelySettleAndUnanchor(car, safePos)
		isDrivingActive = false
		return true
	end

	-- Universal Safe Navigation Function (handles vehicles or characters)
	local function safeTweenTo(targetCFrame, speedStudsPerSec)
		local targetPos = typeof(targetCFrame) == "CFrame" and targetCFrame.Position or targetCFrame
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")

		if hum and hum.SeatPart then
			return driveVehicleTo(targetPos, speedStudsPerSec or Config.taxiSpeed)
		end

		-- Character on foot: safe Heartbeat lerp
		local root = getRootPart()
		if not root then return false end

		speedStudsPerSec = speedStudsPerSec or 60
		local startPos = root.Position
		local totalDist = (startPos - targetPos).Magnitude
		local duration = math.clamp(totalDist / speedStudsPerSec, 0.2, 120.0)
		local t0 = os.clock()
		local finished = false

		local conn = RunService.Heartbeat:Connect(function()
			local elapsed = os.clock() - t0
			local alpha = math.clamp(elapsed / duration, 0, 1)
			local curPos = startPos:Lerp(targetPos, alpha)
			root.CFrame = CFrame.new(curPos)
			root.AssemblyLinearVelocity = Vector3.zero
			if alpha >= 1 then
				finished = true
			end
		end)

		while not finished do task.wait(0.03) end
		if conn then conn:Disconnect() end
		return true
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
	-- 🚕 2. AUTO RIDEGO TAXI (CDID-Style Movement Engine)
	------------------------------------------------
	local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 10)
	local TaxiEvent = TaxiAssets and TaxiAssets:WaitForChild("Events", 10) and TaxiAssets.Events:WaitForChild("TaxiEvent", 10)
	local SpawnCarEvt = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
	local SpawnCarRemote = SpawnCarEvt and SpawnCarEvt:FindFirstChild("SpawnCar")

	local TAXI_BIKE_NAME      = "Yamahax-MioSporty"
	local taxiActive          = false
	local taxiBusy            = false
	local taxiState           = "IDLE" -- IDLE, WAITING_FOR_NEXT_ORDER, NEW_ORDER_DETECTED, PICKING_UP, DRIVING_TO_DESTINATION, DROPPING_OFF
	local taxiToken           = nil
	local lastCompletedToken  = nil
	local taxiPickupPos       = nil
	local taxiDropPos         = nil
	local passengerSeated     = false
	local taxiOverlayPoller   = nil

	local function setTaxiState(newState)
		taxiState = newState
	end

	-- Helper: extract Vector3 from dynamic payload formats
	local function parsePosition(val)
		if typeof(val) == "Vector3" then return val end
		if typeof(val) == "CFrame" then return val.Position end
		if type(val) == "table" then
			if val.X and val.Y and val.Z then
				return Vector3.new(tonumber(val.X) or 0, tonumber(val.Y) or 0, tonumber(val.Z) or 0)
			end
			if val[1] and val[2] and val[3] then
				return Vector3.new(tonumber(val[1]) or 0, tonumber(val[2]) or 0, tonumber(val[3]) or 0)
			end
		end
		return nil
	end

	local function spawnTaxiBike()
		if not SpawnCarRemote then return end
		pcall(function() SpawnCarRemote:FireServer(TAXI_BIKE_NAME) end)
		task.wait(2)
	end

	local function findRidePrompt()
		local car, seat = getPlayerVehicle()
		if car then
			for _, pr in ipairs(car:GetDescendants()) do
				if pr:IsA("ProximityPrompt") and pr.ActionText == "Ride" then
					return pr, pr.Parent
				end
			end
		end
		for _, c in ipairs(workspace:GetChildren()) do
			if c:IsA("Model") and c ~= player.Character and (c.Name:find(player.Name) or c.Name:find("Montor") or c:FindFirstChild("DriveSeat")) then
				for _, pr in ipairs(c:GetDescendants()) do
					if pr:IsA("ProximityPrompt") and pr.ActionText == "Ride" then
						return pr, pr.Parent
					end
				end
			end
		end
		return nil, nil
	end

	local function mountBike()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if hum.SeatPart then return true end

		local prompt, seatPart = findRidePrompt()
		if not prompt or not seatPart then
			UI.Notify("⚠️ Bike Not Found", "Spawning new motorcycle...", 2, "warning")
			spawnTaxiBike()
			prompt, seatPart = findRidePrompt()
			if not prompt or not seatPart then return false end
		end

		local car = seatPart:FindFirstAncestorOfClass("Model") or seatPart.Parent
		if car then
			neutralizeBikeHazards(car)
			-- Upright bike so it's not tipped over
			pcall(function()
				local pivot = car:GetPivot()
				car:PivotTo(CFrame.new(pivot.Position + Vector3.new(0, 1.5, 0)))
			end)
		end

		local root = char:FindFirstChild("HumanoidRootPart")
		if root and seatPart then
			root.CFrame = seatPart.CFrame + Vector3.new(0, 1.0, 0)
			task.wait(0.15)

			pcall(function()
				if fireproximityprompt then
					fireproximityprompt(prompt)
				elseif prompt.InputHoldBegin then
					prompt:InputHoldBegin()
					task.wait(prompt.HoldDuration + 0.1)
					prompt:InputHoldEnd()
				end
			end)
			task.wait(0.5)

			-- Direct Seat Sit fallback if proximity prompt didn't seat
			if not hum.SeatPart and (seatPart:IsA("VehicleSeat") or seatPart:IsA("Seat")) then
				pcall(function() seatPart:Sit(hum) end)
				task.wait(0.2)
			end
		end

		return hum.SeatPart ~= nil
	end

	-- Exact verification that passenger is seated (based on decompiled TaxiClient RideGO_SeatWeld & TripStarted event)
	local function isPassengerOnboard()
		if passengerSeated then return true end

		-- Check exact RideGO passenger instance in ActiveMissions
		local activeMissions = workspace:FindFirstChild("ActiveMissions")
		local passenger = (activeMissions and activeMissions:FindFirstChild("RideGO_Passenger")) or workspace:FindFirstChild("RideGO_Passenger")
		if passenger then
			local hrp = passenger:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:FindFirstChild("RideGO_SeatWeld") then
				passengerSeated = true
				return true
			end
		end

		return false
	end

	-- ── Full End-to-End Trip Automation ──────────────────────────────────
	local function executeTripAsync(token, name, initialPickup, initialDrop)
		if taxiBusy then return end
		if not token or token == lastCompletedToken then
			-- Ignore stale or already completed order
			return
		end

		taxiBusy = true
		taxiToken = token
		passengerSeated = false
		taxiPickupPos = parsePosition(initialPickup)
		taxiDropPos   = parsePosition(initialDrop)

		-- STATE: NEW_ORDER_DETECTED
		setTaxiState("NEW_ORDER_DETECTED")
		print("[PASSENGER] New order detected")
		if taxiPickupPos then
			print("[PASSENGER] New pickup location acquired")
		end
		print("[PASSENGER] Resuming normal passenger workflow")

		-- STATE: PICKING_UP
		setTaxiState("PICKING_UP")

		-- 1. Accept Order
		TaxiEvent:FireServer("AcceptOrder", token)
		task.wait(0.3)
		UI.Notify("✅ Order Accepted", "Passenger: " .. tostring(name or "Passenger"), 2, "success")

		-- 2. Mount bike
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.SeatPart) then
			UI.Notify("🏍️ Mounting Bike", "Getting on motorcycle...", 2, "warning")
			mountBike()
		end

		-- 3. Wait for pickup coordinates (if not in initial payload)
		local waitStart = tick()
		while not taxiPickupPos and taxiActive and (tick() - waitStart < 5) do
			task.wait(0.2)
		end

		-- 4. Ride smoothly to Passenger Pickup Location
		if taxiPickupPos and taxiActive then
			UI.Notify("🏍️ Heading to Pickup", "Driving to passenger...", 2, "warning")
			driveVehicleTo(taxiPickupPos, Config.taxiSpeed)
		end

		-- 5. Wait for passenger to walk & sit (listen for RideGO_SeatWeld or TripStarted)
		if taxiPickupPos and taxiActive then
			UI.Notify("Arrived at Pickup 📍", "Waiting for passenger to board...", 3, "warning")

			-- Settle bike on road at pickup point
			local car, seat = getPlayerVehicle()
			safelySettleAndUnanchor(car, taxiPickupPos)

			-- Always re-affirm driver is sitting on bike so game allows passenger to walk & board
			local curHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not (curHum and curHum.SeatPart) then
				mountBike()
			end

			local waitStartBoard = tick()
			while not isPassengerOnboard() and taxiActive and (tick() - waitStartBoard < 30) do
				local checkHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if not (checkHum and checkHum.SeatPart) then
					mountBike()
				end
				task.wait(0.4)
			end

			-- ONLY proceed if passenger actually boarded the bike!
			if isPassengerOnboard() then
				local settleDelay = tonumber(Config.passengerBoardDelay) or 3
				UI.Notify("Passenger Seated 🛵", string.format("Departing in %.1fs...", settleDelay), settleDelay, "success")
				task.wait(settleDelay)
			else
				UI.Notify("⚠️ Boarding Timeout", "Passenger did not board. Resetting...", 3, "warning")
				lastCompletedToken = token
				taxiBusy = false
				taxiToken = nil
				setTaxiState("WAITING_FOR_NEXT_ORDER")
				print("[PASSENGER] Waiting at current destination for next order...")
				if taxiActive then
					task.wait(2)
					TaxiEvent:FireServer("GoOnline")
				end
				return
			end
		end

		task.wait(0.3)

		-- 6. Ride smoothly to Drop-off Location
		if not taxiDropPos and taxiActive then
			local dropWait = tick()
			while not taxiDropPos and taxiActive and (tick() - dropWait < 5) do
				task.wait(0.2)
			end
		end

		if taxiDropPos and taxiActive then
			-- Calculate trip distance & required realistic travel time so server route validation passes instantly
			local tripDist = (taxiDropPos - (taxiPickupPos or (player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position) or taxiDropPos)).Magnitude
			local speed = tonumber(Config.taxiSpeed) or 65
			local neededTripDuration = math.clamp(math.floor(tripDist / speed), 6, 28)

			-- STATE: DRIVING_TO_DESTINATION
			setTaxiState("DRIVING_TO_DESTINATION")
			UI.Notify("📍 Heading to Drop-off", "Delivering passenger to destination...", 2, "warning")
			driveVehicleTo(taxiDropPos, Config.taxiSpeed)

			-- STATE: DROPPING_OFF
			setTaxiState("DROPPING_OFF")
			print("[PASSENGER] Reached destination")

			-- Settle vehicle safely at exact destination on solid ground
			local car, seat = getPlayerVehicle()
			safelySettleAndUnanchor(car, taxiDropPos)

			-- Realistic Route Simulation Wait: safely parked at destination
			UI.Notify("At Destination 🛵", string.format("Completing trip route (%ds)...", neededTripDuration), 3, "warning")
			local startWait = tick()
			while (tick() - startWait < neededTripDuration) and taxiActive do
				task.wait(0.5)
			end

			-- Wait until passenger completes normal drop-off/exit interaction
			UI.Notify("Arrived at Destination 🏁", "Passenger disembarking (3s)...", 3, "success")
			task.wait(3.0)
			print("[PASSENGER] Passenger drop-off confirmed")
		end

		-- 7. Complete Trip & Acknowledge
		if taxiActive then
			TaxiEvent:FireServer("AckTripComplete")
			print("[PASSENGER] Order completed")
			UI.Notify("🏆 Trip Complete!", "Fare earned. Waiting for next order...", 3, "success")
		end

		-- Record completed order token to guarantee we never re-execute it
		lastCompletedToken = token

		taxiBusy = false
		taxiToken = nil
		taxiPickupPos = nil
		taxiDropPos = nil
		passengerSeated = false

		-- STATE: WAITING_FOR_NEXT_ORDER
		setTaxiState("WAITING_FOR_NEXT_ORDER")
		print("[PASSENGER] Waiting at current destination for next order...")

		-- While in WAITING_FOR_NEXT_ORDER:
		-- Remain completely stationary at the exact destination.
		-- Humanized rate-limited delay before going online
		if taxiActive then
			task.wait(2.5)
			TaxiEvent:FireServer("GoOnline")
		end
	end

	-- ── Taxi Remote Events Listener ──────────────────────────────────────
	if TaxiEvent then
		_G.HipHubTaxiLog = {}

		TaxiEvent.OnClientEvent:Connect(function(...)
			local raw = { ... }
			table.insert(_G.HipHubTaxiLog, { t = tick(), args = raw })

			if not taxiActive then return end

			local eventType = tostring(raw[1] or "")
			local payload   = type(raw[2]) == "table" and raw[2] or nil

			if eventType == "DutyStarted" then
				UI.Notify("RideGO Online ✅", "Mounted & waiting for orders...", 3, "success")
				if not taxiBusy then
					setTaxiState("WAITING_FOR_NEXT_ORDER")
				end

			elseif eventType == "OrderOffer" and not taxiBusy then
				local token = payload and (payload.Token or payload.token or payload.OrderId)
				local name  = payload and (payload.PassengerName or payload.Name) or "Passenger"
				local isAnom = payload and payload.IsAnomaly or false
				local fare  = payload and (payload.Fare or payload.Price) or 0
				local pickPos = payload and (payload.PickupPos or payload.PickupPosition or payload.Pickup or payload.StartPos)
				local dropP   = payload and (payload.DropPos or payload.DropPosition or payload.Destination or payload.Drop or payload.TargetPos)

				if not token or token == lastCompletedToken then
					-- Ignore stale/duplicate order
					return
				end

				if isAnom then
					UI.Notify("👻 ANOMALY ORDER!", "Rare passenger: " .. name, 4, "warning")
				else
					UI.Notify("🛵 New Order!", name .. " — Rp " .. tostring(fare), 3, "success")
				end

				task.spawn(executeTripAsync, token, name, pickPos, dropP)

			elseif eventType == "OrderAccepted" then
				if payload then
					local pick = payload.PickupPos or payload.PickupPosition or payload.Pickup or payload.StartPos
					local drop = payload.DropPos or payload.DropPosition or payload.Destination or payload.Drop or payload.TargetPos
					if pick then taxiPickupPos = parsePosition(pick) end
					if drop then taxiDropPos   = parsePosition(drop) end
				end

			elseif eventType == "PassengerBoarding" then
				-- Passenger started walking towards bike
				UI.Notify("Passenger Approaching 🚶", "Passenger is walking to the bike...", 3, "warning")

			elseif eventType == "TripStarted" or eventType == "PassengerSeated" then
				passengerSeated = true
				if payload then
					local drop = payload.DropPos or payload.DropPosition or payload.Destination or payload.Drop or payload.TargetPos
					if drop then taxiDropPos = parsePosition(drop) end
				end
				UI.Notify("Trip Started! 🚀", "Passenger on board.", 2, "success")

			elseif eventType == "DutyEnded" then
				if taxiActive and not taxiBusy then
					task.wait(1.5)
					TaxiEvent:FireServer("GoOnline")
				end

			elseif eventType == "OrderCompleted" or eventType == "TripComplete" then
				passengerSeated = false
				if not taxiBusy then
					task.wait(0.3)
					TaxiEvent:FireServer("AckTripComplete")
					setTaxiState("WAITING_FOR_NEXT_ORDER")
					if taxiActive then
						task.wait(1.5)
						TaxiEvent:FireServer("GoOnline")
					end
				end

			elseif eventType == "OrderExpired" or eventType == "OrderCancelled" or eventType == "OrderDeclined" then
				taxiBusy = false
				taxiToken = nil
				taxiPickupPos = nil
				taxiDropPos = nil
				passengerSeated = false
				cancelActiveDrive()
				setTaxiState("WAITING_FOR_NEXT_ORDER")
				print("[PASSENGER] Waiting at current destination for next order...")
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
							if #_G.HipHubTaxiLog > 0 then
								local last = _G.HipHubTaxiLog[#_G.HipHubTaxiLog]
								local args = last.args or {}
								if args[1] == "OrderOffer" and type(args[2]) == "table" and args[2].Token then
									if args[2].Token ~= lastCompletedToken then
										task.spawn(executeTripAsync, args[2].Token, args[2].PassengerName, args[2].PickupPos, args[2].DropPos)
									end
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
		taxiActive         = state
		taxiBusy           = false
		taxiToken          = nil
		lastCompletedToken = nil
		taxiPickupPos      = nil
		taxiDropPos        = nil
		passengerSeated    = false
		taxiState          = state and "WAITING_FOR_NEXT_ORDER" or "IDLE"
		Config.autoRideGO  = state

		if state then
			changeTeam("RideGO Driver")
			task.wait(1)

			if TaxiEvent then
				TaxiEvent:FireServer("DismissIntro")
				task.wait(0.3)
			end

			startPhoneOverlayPoller()

			-- Spawn & mount taxi bike
			task.spawn(function()
				mountBike()
				task.wait(1)
				if TaxiEvent then
					TaxiEvent:FireServer("GoOnline")
				end
			end)

			UI.Notify("RideGO Auto-Farm ON", "Waiting for orders at current location...", 3, "success")
		else
			if taxiOverlayPoller then
				task.cancel(taxiOverlayPoller)
				taxiOverlayPoller = nil
			end
			cancelActiveDrive()
			if TaxiEvent then
				TaxiEvent:FireServer("GoOffline")
			end
			UI.Notify("RideGO Auto-Farm OFF", "Driver offline.", 2, "warning")
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

							if settingsMod and settingsMod:FindFirstChild("ServiceEvent") then
								settingsMod.ServiceEvent:FireServer("RequestJobUpdate")
							end

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
									safeTweenTo(activeTarget.CFrame + Vector3.new(0, 3, 0), Config.courierSpeed)
									task.wait(0.5)
									local prompt = activeTarget:FindFirstChildOfClass("ProximityPrompt")
									if prompt and prompt.Enabled and fireproximityprompt then
										fireproximityprompt(prompt)
									end
									task.wait(1)
								else
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
			cancelActiveDrive()
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
									root.CFrame = startPart.CFrame + Vector3.new(0, 3, 0)
									task.wait(2)

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
			cancelActiveDrive()
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

	UI.AddSlider(tab, "Taxi Speed (Studs/s)", 30, 120, math.floor(Config.taxiSpeed or 60), function(val)
		Config.taxiSpeed = val
	end)

	UI.AddSlider(tab, "Boarding Pause Delay (s)", 1, 8, math.floor(Config.passengerBoardDelay or 3), function(val)
		Config.passengerBoardDelay = val
	end)

	UI.AddSection(tab, "Courier Package Delivery")
	UI.AddToggle(tab, "Auto Courier Delivery", "Picks up packages and completes deliveries continuously", Config.autoCourier, function(state)
		toggleAutoCourier(state)
	end)

	UI.AddSlider(tab, "Courier Speed (Studs/s)", 40, 180, math.floor(Config.courierSpeed or 95), function(val)
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

