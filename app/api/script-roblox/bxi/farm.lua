-- 💰 HipHub BXI — Auto Farm, Hybrid AssemblyLinearVelocity Engine & Money Generation System
-- Bus X Indonesia (Place ID: 137806249434874)
-- Hybrid 3D Trajectory + AssemblyLinearVelocity Momentum Engine (Zero Snag & Zero Stall)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"].content
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local CollectionService = game:GetService("CollectionService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local VirtualUser = game:GetService("VirtualUser")
	local player = Players.LocalPlayer

	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoBusJob = false,
		selectedRoute = "Auto (Highest Payout)",
		targetSpeed = 160,
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
	local isWaitingInZone = false
	local currentRouteId = "Auto"
	local currentTerminalId = nil

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
	local selectedBusModel = "Jetbus_3_RM _SHD"

	local function getMyBus()
		local spawnedFolder = workspace:FindFirstChild("SpawnedVehicles")
		if not spawnedFolder then return nil end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local currentSeat = hum and hum.SeatPart
		if currentSeat then
			for _, veh in ipairs(spawnedFolder:GetChildren()) do
				if currentSeat:IsDescendantOf(veh) then
					return veh
				end
			end
		end

		for _, veh in ipairs(spawnedFolder:GetChildren()) do
			local ownerAttr = veh:GetAttribute("Owner") or veh:GetAttribute("OwnerName")
			local ownerVal = veh:FindFirstChild("Owner")
			if (ownerAttr and tostring(ownerAttr) == player.Name) or (ownerVal and tostring(ownerVal.Value) == player.Name) or veh.Name:find(player.Name) then
				return veh
			end
		end

		local vehicles = spawnedFolder:GetChildren()
		return vehicles[#vehicles]
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
				Remotes.SpawnCar:FireServer(selectedBusModel)
				task.wait(2.0)
			end
			bus = getMyBus()
		end

		if not bus then return nil, nil end

		local seat = getDriverSeat(bus)
		local char = player.Character or player.CharacterAdded:Wait()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")

		if seat and hum and root then
			if bus.PrimaryPart ~= seat then
				pcall(function() bus.PrimaryPart = seat end)
			end
			if hum.SeatPart ~= seat then
				root.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.2)
				local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt", true) or bus:FindFirstChildWhichIsA("ProximityPrompt", true)
				if prompt and fireproximityprompt then
					fireproximityprompt(prompt)
				else
					pcall(function() seat:Sit(hum) end)
				end
				task.wait(0.3)
			end
		end

		return bus, seat
	end

	local function getTargetPart(name, folderName)
		local folder = workspace:WaitForChild(folderName, 5)
		if not folder then return nil end
		local part = folder:FindFirstChild(name, true)
		if not part then
			task.wait(0.3)
			part = folder:FindFirstChild(name, true)
		end
		return part
	end

	------------------------------------------------
	-- 🚀 HYBRID 3D TRAJECTORY + VELOCITY ENGINE
	------------------------------------------------
	local isDrivingActive = false

	local function moveToTarget(targetPart, customSpeed)
		if not targetPart then return false end
		local bus, seat = ensureBusAndSeat()
		if not (bus and seat) then return false end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		local speed = customSpeed or (Config.targetSpeed or 160)
		-- Convert km/h to studs/second (1 km/h ≈ 0.99 studs/s in Roblox physics scale)
		local speedStudsPerSec = math.max(speed * 0.95, 80)

		local targetModel = bus
		local rootPart = bus.PrimaryPart or seat
		if not rootPart then return false end

		local startCFrame = targetModel:GetPivot()
		local targetCFrame = targetPart.CFrame + Vector3.new(0, 3.2, 0)
		local distance = (targetCFrame.Position - startCFrame.Position).Magnitude
		local duration = math.max(distance / speedStudsPerSec, 0.1)

		ensureSafetyPlate(targetPart.Position, 50)
		requestStreamAsync(targetPart.Position)

		local originalCollisions = {}
		for _, part in ipairs(targetModel:GetDescendants()) do
			if part:IsA("BasePart") then
				originalCollisions[part] = part.CanCollide
			end
		end

		local wasAnchored = rootPart.Anchored
		rootPart.Anchored = false
		isDrivingActive = true

		local noclipConnection = RunService.Stepped:Connect(function()
			for part in pairs(originalCollisions) do
				if part and part.Parent then
					part.CanCollide = false
				end
			end
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			end
		end)

		local elapsed = 0
		while elapsed < duration and isFarmRunning do
			local dt = RunService.Heartbeat:Wait()
			elapsed = elapsed + dt
			local alpha = math.min(elapsed / duration, 1)

			-- Smooth Interpolation along direct 3D trajectory
			local curPos = startCFrame.Position:Lerp(targetCFrame.Position, alpha)
			local moveVector = (targetCFrame.Position - startCFrame.Position)
			local flatMove = Vector3.new(moveVector.X, 0, moveVector.Z)
			local rotAngle = flatMove.Magnitude > 0.05 and math.atan2(flatMove.X, flatMove.Z) or 0
			local currentRot = CFrame.Angles(0, rotAngle, 0)

			local currentCF = CFrame.new(curPos) * currentRot
			pcall(function()
				targetModel:PivotTo(currentCF)

				-- Real-time AssemblyLinearVelocity Momentum Sync
				local velocityVec = flatMove.Magnitude > 0.05 and (flatMove.Unit * speedStudsPerSec) or Vector3.zero
				seat.Throttle = 1
				seat.AssemblyLinearVelocity = velocityVec
				seat.AssemblyAngularVelocity = Vector3.zero

				if hrp then
					hrp.AssemblyLinearVelocity = velocityVec
					hrp.AssemblyAngularVelocity = Vector3.zero
				end
			end)
		end

		pcall(function() targetModel:PivotTo(targetCFrame) end)
		noclipConnection:Disconnect()

		-- Restore Collisions & Stabilize Physics
		for part, canCollide in pairs(originalCollisions) do
			if part and part.Parent then
				local name = part.Name:lower()
				if name:find("wheel") or name:find("tire") or name == "fl" or name == "fr" or name == "rl" or name == "rr" or name == "driveseat" then
					part.CanCollide = true
				else
					part.CanCollide = canCollide
				end
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end

		if seat then
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
			seat.Throttle = 0
		end

		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end

		task.wait(0.5)

		-- Re-verify final positioning inside trigger zone
		if not isWaitingInZone and isFarmRunning then
			pcall(function() targetModel:PivotTo(targetPart.CFrame + Vector3.new(0, 3.2, 0)) end)
			task.wait(0.2)
		end

		rootPart.Anchored = wasAnchored
		isDrivingActive = false
		return true
	end

	------------------------------------------------
	-- 🏁 AUTOMATIC BUS JOB RUNNER
	------------------------------------------------
	local function startBusJob()
		setFarmState(FARM_STATE.STARTING_JOB, "Detecting Terminal")

		-- 1. Detect Terminal Tag or Fallback
		local triggers = CollectionService:GetTagged("BusJobTrigger")
		local terminalId = nil

		for _, trigger in ipairs(triggers) do
			local id = trigger:GetAttribute("TerminalId")
			if id then
				terminalId = id
				break
			end
		end

		if not terminalId then
			terminalId = "Baranangsiang"
		end
		currentTerminalId = terminalId

		-- 2. Fetch Available Routes & Pick Highest Payout
		setFarmState(FARM_STATE.STARTING_JOB, "Querying Routes for " .. terminalId)
		local routes = Remotes.GetAvailableBusRoutes:InvokeServer(terminalId)
		if type(routes) ~= "table" then
			task.wait(2)
			return false
		end

		local bestRouteId = nil
		local maxReward = -1

		for id, info in pairs(routes) do
			if type(info) == "table" and info.Reward and info.Reward > maxReward then
				maxReward = info.Reward
				bestRouteId = id
			end
		end

		if not bestRouteId then
			bestRouteId = "Baranangsiang_ke_Rambutan"
		end
		currentRouteId = bestRouteId

		-- 3. Ensure Vehicle & Start Job
		ensureBusAndSeat()
		setFarmState(FARM_STATE.STARTING_JOB, "Starting " .. tostring(bestRouteId))

		local res = Remotes.StartBusJob:InvokeServer(bestRouteId, terminalId)
		if type(res) == "table" and res.success and res.nextCheckpointPartName then
			local cpIndex = res.checkpointIndex or 1
			local cpTotal = res.totalCheckpoints or 4
			currentCheckpointText = string.format("%d / %d", cpIndex, cpTotal)
			if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
			setFarmState(FARM_STATE.DRIVING_CHECKPOINT, res.nextDestinationName or "Checkpoint 1")

			local part = getTargetPart(res.nextCheckpointPartName, "Checkpoints")
			if part then
				moveToTarget(part, Config.targetSpeed or 160)
			end
			return true
		end

		return false
	end

	-- Listen for Server Job Updates
	Remotes:WaitForChild("BusJobUpdate").OnClientEvent:Connect(function(action, data)
		if not isFarmRunning then return end

		if action == "StartCheckpointWait" then
			isWaitingInZone = true
			if type(data) == "table" then
				local cpIdx = data.checkpointIndex or 1
				local cpTot = data.totalCheckpoints or 4
				currentCheckpointText = string.format("%d / %d", cpIdx, cpTot)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.WAITING_PASSENGERS, string.format("Loading (%ds)", data.waitTime or 15))
			end
			return
		end

		if action == "WaitCompleted" then
			isWaitingInZone = false
			setFarmState(FARM_STATE.DRIVING_CHECKPOINT, "Passenger Loading Complete")
			return
		end

		if action == "JobSuccess" then
			isWaitingInZone = false
			totalRoutesDone = totalRoutesDone + 1
			if statRouteCard then statRouteCard.Set(tostring(totalRoutesDone)) end
			setFarmState(FARM_STATE.JOB_COMPLETED, "Route Completed!")
			UI.Notify("Route Completed", "Received bus route payout!", 3, "success")

			if _G.HipHubSendWebhook then
				_G.HipHubSendWebhook("🚌 Bus Route Completed!", string.format("Completed **%s** successfully.", tostring(currentRouteId)), {
					{ name = "Route", value = tostring(currentRouteId), inline = true },
					{ name = "Total Routes Completed", value = tostring(totalRoutesDone), inline = true },
					{ name = "Status", value = "✅ Success", inline = true }
				}, 0x00E68C)
			end

			task.wait(1.5)
			if isFarmRunning and Config.autoNextJob then
				startBusJob()
			end
			return
		end

		if action == "JobCancelled" then
			isWaitingInZone = false
			setFarmState(FARM_STATE.IDLE, "Job Cancelled")
			task.wait(2)
			if isFarmRunning and Config.autoNextJob then
				startBusJob()
			end
			return
		end

		if type(data) ~= "table" then return end

		local isFinal = (action == "FinalDestination" or data.isFinalDestination)
		local targetName = isFinal and data.endTriggerPartName or (data.nextCheckpointPartName or data.checkpointPartName)
		local folder = isFinal and "BusJobEndTriggers" or "Checkpoints"

		if data.checkpointIndex and data.totalCheckpoints then
			currentCheckpointText = string.format("%d / %d", data.checkpointIndex, data.totalCheckpoints)
			if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
		end

		if targetName then
			task.spawn(function()
				isWaitingInZone = false
				setFarmState(isFinal and FARM_STATE.DRIVING_FINAL or FARM_STATE.DRIVING_CHECKPOINT, data.nextDestinationName or targetName)

				if isFinal then
					-- Grace period to let server sync finish stop
					task.wait(1.0)
				end

				if not isFarmRunning then return end
				local part = getTargetPart(targetName, folder)
				if part then
					moveToTarget(part, Config.targetSpeed or 160)
				end
			end)
		end
	end)

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

	-- Master Auto-Farm Routine
	local function toggleAutoFarm(state)
		isFarmRunning = state
		Config.autoBusJob = state

		if state then
			farmStartTime = os.clock()
			setFarmState(FARM_STATE.PREPARING_BUS, "Starting Farm Engine")
			UI.Notify("Auto Farm Started", "Hybrid AssemblyLinearVelocity driving activated!", 3, "success")
			task.spawn(function()
				pcall(checkAndClaimQuests)
				pcall(checkAndSpinBox)
				startBusJob()
			end)
		else
			isDrivingActive = false
			isWaitingInZone = false
			setFarmState(FARM_STATE.IDLE, "Stopped")
			UI.Notify("Auto Farm Stopped", "Farm paused.", 2, "warning")
		end
	end

	-- Money Tracking Listener
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

	-- Uptime Counter
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

	-- 2. Master Toggle & Route Controls
	UI.AddSection(tab, "Auto Farm Controller")

	local farmToggle = UI.AddToggle(tab, "Start Auto Bus Farm (Hybrid Velocity Engine)", isFarmRunning, function(state)
		toggleAutoFarm(state)
	end)

	local ownedBusesList = { "Jetbus_3_RM _SHD" }
	pcall(function()
		local pData = player:FindFirstChild("PlayerData")
		if pData and pData:FindFirstChild("OwnedCars") then
			local cars = pData.OwnedCars:GetChildren()
			if #cars > 0 then
				ownedBusesList = {}
				for _, c in ipairs(cars) do table.insert(ownedBusesList, c.Name) end
			end
		end
	end)

	UI.AddDropdown(tab, "Select Bus Model", ownedBusesList, selectedBusModel, function(chosen)
		selectedBusModel = chosen
	end)

	UI.AddSlider(tab, "Driving Cruise Speed", 80, 260, Config.targetSpeed or 160, function(val)
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
