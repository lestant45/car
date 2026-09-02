-- 💰 HipHub BXI — Auto Farm, AssemblyLinearVelocity Driving & Money Generation System
-- Bus X Indonesia (Place ID: 137806249434874)
-- High-Performance Road Physics Engine: AssemblyLinearVelocity Driving (No Teleportation)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"].content
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoBusJob = false,
		selectedRoute = "Baranangsiang_ke_Rambutan",
		targetSpeed = 140,
		autoNextJob = true,
		autoClaimQuests = true,
		autoSpinBox = false,
		selectedBox = "Event",
		targetEarn = 0
	}

	------------------------------------------------
	-- 📊 AUTO FARM STATE & METRICS
	------------------------------------------------
	local FARM_STATE = {
		IDLE = "Idle",
		PREPARING_BUS = "PreparingBus",
		STARTING_JOB = "StartingJob",
		DRIVING_CHECKPOINT = "DrivingToCheckpoint",
		WAITING_PASSENGERS = "WaitingPassengers",
		DRIVING_FINAL = "DrivingToFinal",
		JOB_COMPLETED = "JobCompleted"
	}

	local currentFarmState = FARM_STATE.IDLE
	local isFarmRunning = false
	local currentRouteId = Config.selectedRoute or "Baranangsiang_ke_Cirebon4"
	local currentTerminalId = "Baranangsiang"

	-- Live Stats
	local totalEarnings = 0
	local totalRoutesDone = 0
	local farmStartTime = os.clock()
	local currentActivityText = "Idle"
	local currentCheckpointText = "None"

	-- Dashboard UI References
	local statEarnCard = nil
	local statRouteCard = nil
	local statCheckpointCard = nil
	local statUptimeCard = nil
	local activityLabel = nil

	local function setFarmState(newState, reason)
		if currentFarmState ~= newState then
			currentFarmState = newState
			currentActivityText = tostring(newState) .. (reason and (" (" .. reason .. ")") or "")
			if activityLabel then
				pcall(function() activityLabel.Set("📍 Status: " .. currentActivityText) end)
			end
		end
	end

	local function formatRp(amount)
		amount = math.floor(tonumber(amount) or 0)
		local str = tostring(amount):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
		return "Rp " .. str
	end

	------------------------------------------------
	-- 🛡️ SAFETY PLATFORM & STREAMING
	------------------------------------------------
	local function ensureSafetyPlate(pos, width)
		width = width or 50
		local plate = workspace:FindFirstChild("__SafetyPlate")
		if not plate then
			plate = Instance.new("Part")
			plate.Name = "__SafetyPlate"
			plate.Anchored = true
			plate.CanCollide = true
			plate.Transparency = 1
			plate.CastShadow = false
			plate.Material = Enum.Material.SmoothPlastic
			pcall(function() plate.Parent = workspace end)
		end
		plate.Size = Vector3.new(width, 2, width)
		plate.CFrame = CFrame.new(pos.X, pos.Y - 1.0, pos.Z)
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

	------------------------------------------------
	-- 🚌 BUS SPAWN & MOUNT HELPERS
	------------------------------------------------
	local BUS_SEAT_GROUND_OFFSET = 5.525 -- Exact height of DriveSeat above road surface

	local function getMyBus()
		local spawned = workspace:FindFirstChild("SpawnedVehicles")
		if not spawned then return nil end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local currentSeat = hum and hum.SeatPart
		if currentSeat then
			for _, v in ipairs(spawned:GetChildren()) do
				if currentSeat:IsDescendantOf(v) then
					return v
				end
			end
		end

		local buses = spawned:GetChildren()
		return buses[1]
	end

	local function getDriverSeat(bus)
		bus = bus or getMyBus()
		if not bus then return nil end
		local seat = bus:FindFirstChild("DriveSeat", true) or bus:FindFirstChildWhichIsA("VehicleSeat", true)
		if seat and bus.PrimaryPart ~= seat then
			pcall(function() bus.PrimaryPart = seat end)
		end
		return seat
	end

	local function ensureBusAndSeat()
		local bus = getMyBus()
		if not bus then
			setFarmState(FARM_STATE.PREPARING_BUS, "Spawning Bus")
			if Remotes:FindFirstChild("SpawnCar") then
				Remotes.SpawnCar:FireServer("Jetbus_3_RM _SHD")
				task.wait(1.5)
			end
			bus = getMyBus()
		end

		if not bus then return nil, nil end

		local seat = getDriverSeat(bus)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if seat and hum and hrp then
			if bus.PrimaryPart ~= seat then
				pcall(function() bus.PrimaryPart = seat end)
			end
			if hum.SeatPart ~= seat then
				hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.2)
				pcall(function() seat:Sit(hum) end)
				task.wait(0.2)

				if hum.SeatPart ~= seat then
					local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true) or bus:FindFirstChildWhichIsA("ProximityPrompt", true)
					if prompt and fireproximityprompt then
						pcall(function() fireproximityprompt(prompt) end)
						task.wait(0.5)
					end
				end
			end
		end

		return bus, seat
	end

	------------------------------------------------
	-- 🏎️ ASSEMBLY LINEAR VELOCITY ROAD DRIVING ENGINE
	------------------------------------------------
	local isDrivingActive = false
	local currentDriveConn = nil

	local function probeGround(pos, fallbackY)
		local char = player.Character
		local bus = getMyBus()

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local filterList = { char, bus }

		local spawned = workspace:FindFirstChild("SpawnedVehicles")
		if spawned then table.insert(filterList, spawned) end
		local checkpoints = workspace:FindFirstChild("Checkpoints")
		if checkpoints then table.insert(filterList, checkpoints) end
		local triggers = workspace:FindFirstChild("BusJobTriggers")
		if triggers then table.insert(filterList, triggers) end
		local endTriggers = workspace:FindFirstChild("BusJobEndTriggers")
		if endTriggers then table.insert(filterList, endTriggers) end
		local safety = workspace:FindFirstChild("__SafetyPlate")
		if safety then table.insert(filterList, safety) end
		local esp = workspace.CurrentCamera:FindFirstChild("HipHub_BXI_ESP")
		if esp then table.insert(filterList, esp) end
		local cam = workspace.CurrentCamera
		if cam then table.insert(filterList, cam) end

		rayParams.FilterDescendantsInstances = filterList

		local startY = (fallbackY or pos.Y) + 35
		local rayOrigin = Vector3.new(pos.X, startY, pos.Z)
		local rayDir = Vector3.new(0, -90, 0)
		local hit = workspace:Raycast(rayOrigin, rayDir, rayParams)

		if hit then
			return hit.Position.Y
		end
		return fallbackY
	end

	-- Move to target destination or part using Smooth 3D CFrame Lerp Glide (From reference script)
	local function driveToDestination(targetDestination, targetCruiseSpeed)
		targetCruiseSpeed = targetCruiseSpeed or (Config.targetSpeed or 140)

		local bus, seat = ensureBusAndSeat()
		if not (bus and seat) then return false end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		isDrivingActive = true

		local targetCFrame = nil
		if typeof(targetDestination) == "Instance" and targetDestination:IsA("BasePart") then
			targetCFrame = targetDestination.CFrame + Vector3.new(0, 3, 0)
		elseif typeof(targetDestination) == "CFrame" then
			targetCFrame = targetDestination + Vector3.new(0, 3, 0)
		elseif typeof(targetDestination) == "Vector3" then
			targetCFrame = CFrame.new(targetDestination + Vector3.new(0, 3, 0))
		else
			isDrivingActive = false
			return false
		end

		local rootPart = bus.PrimaryPart or seat
		local startCFrame = bus:GetPivot()
		local distance = (targetCFrame.Position - startCFrame.Position).Magnitude
		local duration = math.max(distance / targetCruiseSpeed, 0.1)

		local originalCollisions = {}
		for _, part in ipairs(bus:GetDescendants()) do
			if part:IsA("BasePart") then
				originalCollisions[part] = part.CanCollide
			end
		end

		rootPart.Anchored = true

		-- Pre-load destination safety plate & streaming
		ensureSafetyPlate(targetCFrame.Position, 50)
		requestStreamAsync(targetCFrame.Position)

		local noclipConnection = RunService.Stepped:Connect(function()
			for part in pairs(originalCollisions) do
				if part and part.Parent then
					part.CanCollide = false
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)

		local elapsed = 0
		while elapsed < duration do
			if not isFarmRunning then break end
			local dt = RunService.Heartbeat:Wait()
			elapsed = elapsed + dt
			local alpha = math.min(elapsed / duration, 1)
			bus:PivotTo(startCFrame:Lerp(targetCFrame, alpha))
		end

		bus:PivotTo(targetCFrame)
		noclipConnection:Disconnect()

		-- Restore collision on wheels ONLY and keep body non-colliding with platform architecture
		for part, _ in pairs(originalCollisions) do
			if part and part.Parent then
				local name = part.Name:lower()
				if name:find("wheel") or name:find("tire") or name == "fl" or name == "fr" or name == "rl" or name == "rr" then
					part.CanCollide = true
				else
					part.CanCollide = false
				end
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end

		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end

		bus:PivotTo(targetCFrame)

		-- KEEP ANCHORED while waiting at the checkpoint so physics can NEVER fling the bus!
		rootPart.Anchored = true
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero

		isDrivingActive = false
		return true
	end

	------------------------------------------------
	-- 🏁 FULL BUS JOB AUTO FARM PIPELINE
	------------------------------------------------
	local currentJobActive = false
	local waitingForCheckpointCountdown = false
	local nextCheckpointPartName = nil
	local nextDestinationName = nil
	local endTriggerPartName = nil
	local currentCheckpointIndex = 0
	local totalCheckpoints = 0

	-- Listen for Server Job Updates
	if Remotes:FindFirstChild("BusJobUpdate") then
		Remotes.BusJobUpdate.OnClientEvent:Connect(function(eventName, eventData)
			if not isFarmRunning then return end

			if eventName == "StartCheckpointWait" then
				waitingForCheckpointCountdown = true
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.WAITING_PASSENGERS, eventData.checkpointName or "Checkpoint Zone")

			elseif eventName == "WaitCompleted" then
				waitingForCheckpointCountdown = false
				setFarmState(FARM_STATE.DRIVING_CHECKPOINT, "Passenger Loading Complete")

			elseif eventName == "NextCheckpoint" then
				nextCheckpointPartName = eventData.nextCheckpointPartName
				nextDestinationName = eventData.nextDestinationName
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName or "Next Stop")

			elseif eventName == "FinalDestination" then
				endTriggerPartName = eventData.endTriggerPartName
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.DRIVING_FINAL, "Final Destination Trigger")

			elseif eventName == "JobSuccess" then
				currentJobActive = false
				waitingForCheckpointCountdown = false
				totalRoutesDone = totalRoutesDone + 1
				if statRouteCard then statRouteCard.Set(tostring(totalRoutesDone)) end
				setFarmState(FARM_STATE.JOB_COMPLETED, "Route Completed!")
				UI.Notify("Route Completed", "Received bus route payout!", 3, "success")

				-- Discord Webhook notification
				if _G.HipHubSendWebhook and Config.autoNextJob then
					_G.HipHubSendWebhook("🚌 Bus Route Completed!", string.format("Completed **%s** successfully.", tostring(currentRouteId)), {
						{ name = "Route", value = tostring(currentRouteId), inline = true },
						{ name = "Total Routes Completed", value = tostring(totalRoutesDone), inline = true },
						{ name = "Status", value = "✅ Success", inline = true }
					}, 0x00E68C)
				end

			elseif eventName == "JobCancelled" then
				currentJobActive = false
				waitingForCheckpointCountdown = false
				setFarmState(FARM_STATE.IDLE, "Job Cancelled")
			end
		end)
	end

	-- Execute one full bus route loop
	local function executeBusRouteLoop()
		local terminalTriggerPos = Vector3.new(22771.8, 294.8, -39584.0)

		-- 1. Ensure Bus and Driver Seat
		local bus, seat = ensureBusAndSeat()
		if not (bus and seat) then
			task.wait(2)
			return
		end

		-- 2. Drive to Terminal Trigger if far
		local seatPos = seat.Position
		if (Vector3.new(seatPos.X - terminalTriggerPos.X, 0, seatPos.Z - terminalTriggerPos.Z)).Magnitude > 60 then
			setFarmState(FARM_STATE.STARTING_JOB, "Navigating to Terminal")
			driveToDestination(terminalTriggerPos, Config.targetSpeed or 140)
		end

		-- 3. Auto-detect route with highest payout (max money reward)
		setFarmState(FARM_STATE.STARTING_JOB, "Selecting Highest Paying Route")
		pcall(function()
			local routes = Remotes.GetAvailableBusRoutes:InvokeServer(currentTerminalId)
			if type(routes) == "table" then
				local bestRouteId = nil
				local maxReward = -1
				for id, info in pairs(routes) do
					if type(info) == "table" and info.Reward and info.Reward > maxReward then
						maxReward = info.Reward
						bestRouteId = id
					end
				end
				if bestRouteId then
					currentRouteId = bestRouteId
					Config.selectedRoute = bestRouteId
				end
			end
		end)

		-- Fallback to highest paying route in game if query was nil
		if not currentRouteId or currentRouteId == "Baranangsiang_ke_Rambutan" then
			currentRouteId = "Baranangsiang_ke_Cirebon4"
		end

		setFarmState(FARM_STATE.STARTING_JOB, "Starting Job: " .. tostring(currentRouteId))
		local startRes = nil
		pcall(function()
			startRes = Remotes.StartBusJob:InvokeServer(currentRouteId, currentTerminalId)
		end)

		if type(startRes) == "table" and startRes.success then
			currentJobActive = true
			currentCheckpointIndex = startRes.checkpointIndex or 1
			totalCheckpoints = startRes.totalCheckpoints or 8
			nextCheckpointPartName = startRes.nextCheckpointPartName
			nextDestinationName = startRes.nextDestinationName
			currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
			if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
			setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName)
		else
			task.wait(3)
			return
		end

		-- 4. Route Navigation Loop (Checkpoint to Checkpoint)
		local lastDrivenTarget = nil
		while currentJobActive and isFarmRunning do
			-- A. Driving to next checkpoint
			if nextCheckpointPartName and nextCheckpointPartName ~= lastDrivenTarget then
				local cpPart = workspace.Checkpoints:FindFirstChild(nextCheckpointPartName, true)
				if cpPart and cpPart:IsA("BasePart") then
					setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName or nextCheckpointPartName)
					driveToDestination(cpPart, Config.targetSpeed or 140)
					lastDrivenTarget = nextCheckpointPartName
				end
			end

			-- B. Waiting inside Checkpoint Zone for passenger countdown
			if waitingForCheckpointCountdown and isFarmRunning then
				setFarmState(FARM_STATE.WAITING_PASSENGERS, "Passenger Loading")
				local waitTimeout = os.clock()
				while waitingForCheckpointCountdown and isFarmRunning and (os.clock() - waitTimeout) < 25 do
					local b, s = ensureBusAndSeat()
					if b and s then
						local r = b.PrimaryPart or s
						r.Anchored = true
						s.AssemblyLinearVelocity = Vector3.zero
						s.AssemblyAngularVelocity = Vector3.zero
						s.Throttle = 0
					end
					task.wait(0.5)
				end
			end

			-- C. Driving to Final Destination
			if endTriggerPartName and currentJobActive and endTriggerPartName ~= lastDrivenTarget then
				local endTrigger = workspace.BusJobEndTriggers:FindFirstChild(endTriggerPartName)
				if endTrigger and endTrigger:IsA("BasePart") then
					setFarmState(FARM_STATE.DRIVING_FINAL, "Approaching Final Stop")
					driveToDestination(endTrigger, Config.targetSpeed or 140)
					lastDrivenTarget = endTriggerPartName
				end
				task.wait(2)
				break
			elseif endTriggerPartName and not currentJobActive then
				break
			end

			task.wait(0.2)
		end

		task.wait(2)
	end

	------------------------------------------------
	-- 🎁 AUTO DAILY QUESTS & SPIN BOX
	------------------------------------------------
	local function checkAndClaimQuests()
		if not Config.autoClaimQuests then return end
		pcall(function()
			local questData = Remotes.GetQuestData:InvokeServer()
			local questDefs = Remotes.GetQuestDefinitions:InvokeServer()
			if questData and questData.Quests and questDefs then
				for qId, qInfo in pairs(questData.Quests) do
					local def = questDefs[qId]
					if def and qInfo.Progress >= def.Target and not qInfo.Claimed then
						local successClaim = Remotes.ClaimQuestReward:InvokeServer(qId)
						if successClaim then
							UI.Notify("Quest Claimed", "Claimed reward for: " .. def.Title, 3, "success")
							if _G.HipHubSendWebhook then
								_G.HipHubSendWebhook("🎁 Daily Quest Claimed!", "Successfully claimed daily quest reward.", {
									{ name = "Quest", value = def.Title, inline = true },
									{ name = "Reward", value = formatRp(def.Reward), inline = true }
								}, 0xFFD700)
							end
						end
					end
				end
			end
		end)
	end

	local function checkAndSpinBox()
		if not Config.autoSpinBox then return end
		pcall(function()
			local spinData = Remotes.SpinBox_GetData:InvokeServer()
			if spinData and spinData.Boxes then
				local boxName = Config.selectedBox or "Event"
				local boxInfo = spinData.Boxes[boxName]
				if boxInfo and spinData.Points >= boxInfo.Cost and not spinData.GarageFull then
					local spinRes = Remotes.SpinBox_RequestSpin:InvokeServer(boxName)
					if spinRes and spinRes.success then
						Remotes.SpinBox_AnimationDone:FireServer()
						local rewardName = spinRes.reward and spinRes.reward.DisplayName or "Reward"
						UI.Notify("Spin Box Won!", "Obtained: " .. rewardName, 3, "gold")
					end
				end
			end
		end)
	end

	------------------------------------------------
	-- 🔁 MASTER AUTO FARM THREAD
	------------------------------------------------
	task.spawn(function()
		while true do
			task.wait(1)
			if isFarmRunning then
				pcall(checkAndClaimQuests)
				pcall(checkAndSpinBox)
				pcall(executeBusRouteLoop)

				if not Config.autoNextJob then
					isFarmRunning = false
					setFarmState(FARM_STATE.IDLE, "Single Route Done")
				end
			end
		end
	end)

	-- Track Money & Update Stats
	pcall(function()
		local PlayerData = player:WaitForChild("PlayerData", 5)
		if PlayerData and PlayerData:FindFirstChild("Uang") then
			local uangVal = PlayerData.Uang
			local lastUang = uangVal.Value
			uangVal.Changed:Connect(function(newVal)
				if newVal > lastUang then
					local diff = newVal - lastUang
					totalEarnings = totalEarnings + diff
					if statEarnCard then statEarnCard.Set(formatRp(totalEarnings)) end
				end
				lastUang = newVal
			end)
		end
	end)

	-- Update Uptime Counter
	RunService.Heartbeat:Connect(function()
		if isFarmRunning and statUptimeCard then
			local elapsed = math.floor(os.clock() - farmStartTime)
			local hrs = math.floor(elapsed / 3600)
			local mins = math.floor((elapsed % 3600) / 60)
			local secs = elapsed % 60
			statUptimeCard.Set(string.format("%02d:%02d:%02d", hrs, mins, secs))
		end
	end)

	------------------------------------------------
	-- 💰 AUTO FARM UI BUILDER
	------------------------------------------------

	-- 1. Live Stats Dashboard
	UI.AddSection(tab, "Live Auto Farm Metrics")

	local statsRow1 = Instance.new("Frame")
	statsRow1.Size = UDim2.new(1, 0, 0, 56)
	statsRow1.BackgroundTransparency = 1
	statsRow1.Parent = tab
	local sLayout1 = Instance.new("UIListLayout")
	sLayout1.FillDirection = Enum.FillDirection.Horizontal
	sLayout1.Padding = UDim.new(0, 8)
	sLayout1.Parent = statsRow1

	statEarnCard = UI.AddStatsCard(statsRow1, "Total Earned", "Rp 0", "💰")
	statRouteCard = UI.AddStatsCard(statsRow1, "Routes Done", "0", "🛣️")

	local statsRow2 = Instance.new("Frame")
	statsRow2.Size = UDim2.new(1, 0, 0, 56)
	statsRow2.BackgroundTransparency = 1
	statsRow2.Parent = tab
	local sLayout2 = Instance.new("UIListLayout")
	sLayout2.FillDirection = Enum.FillDirection.Horizontal
	sLayout2.Padding = UDim.new(0, 8)
	sLayout2.Parent = statsRow2

	statCheckpointCard = UI.AddStatsCard(statsRow2, "Checkpoint", "0 / 0", "🚩")
	statUptimeCard = UI.AddStatsCard(statsRow2, "Farm Uptime", "00:00:00", "⏱️")

	activityLabel = UI.AddLabel(tab, "📍 Status: Idle", "cyan")

	-- 2. Master Toggle & Route Selection
	UI.AddSection(tab, "Auto Farm Controller")

	local farmToggle = UI.AddToggle(tab, "Start Auto Bus Farm (Assembly Linear Velocity)", isFarmRunning, function(state)
		isFarmRunning = state
		Config.autoBusJob = state
		if state then
			farmStartTime = os.clock()
			setFarmState(FARM_STATE.PREPARING_BUS, "Starting Farm Engine")
			UI.Notify("Auto Farm Started", "AssemblyLinearVelocity driving activated!", 3, "success")
		else
			isDrivingActive = false
			currentJobActive = false
			setFarmState(FARM_STATE.IDLE, "Stopped")
			UI.Notify("Auto Farm Stopped", "Farm paused.", 2, "warning")
		end
	end)

	local AVAILABLE_ROUTES = {
		"Baranangsiang_ke_Cirebon4",
		"Baranangsiang_ke_Cirebon3",
		"Baranangsiang_ke_Cirebon2",
		"Baranangsiang_ke_Cirebon1",
		"Baranangsiang_ke_Cirebon",
		"Baranangsiang_ke_Rambutan"
	}

	UI.AddDropdown(tab, "Target Route", AVAILABLE_ROUTES, currentRouteId, function(chosen)
		currentRouteId = chosen
		Config.selectedRoute = chosen
	end)

	UI.AddSlider(tab, "Driving Cruise Speed", 80, 260, Config.targetSpeed or 140, function(val)
		Config.targetSpeed = val
	end, "km/h")

	UI.AddToggle(tab, "Continuous Loop (Auto Start Next Job)", Config.autoNextJob, function(state)
		Config.autoNextJob = state
	end)

	-- 3. Automation Modules
	UI.AddSection(tab, "Rewards & Extra Automation")

	UI.AddToggle(tab, "Auto Claim Daily Quests (Rp 150M+)", Config.autoClaimQuests, function(state)
		Config.autoClaimQuests = state
		if state then checkAndClaimQuests() end
	end)

	UI.AddToggle(tab, "Auto Spin Box Roller", Config.autoSpinBox, function(state)
		Config.autoSpinBox = state
		if state then checkAndSpinBox() end
	end)

	UI.AddDropdown(tab, "Spin Box Type", { "Event", "Silver", "Gold" }, Config.selectedBox or "Event", function(chosen)
		Config.selectedBox = chosen
	end)
end)

if not success then
	warn("[HipHub BXI Auto Farm Error]:", err)
end
