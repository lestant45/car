-- 💰 HipHub CDID — Auto Farm & Money Generation System
-- Modular Auto Farm logic for Car Driving Indonesia (CDID)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Config = _G.HipHubConfig or { farm = {} }
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	-- Network helper
	local Network
	pcall(function()
		Network = require(ReplicatedStorage.Modules.Network)
	end)

	local function fireRemote(eventName, ...)
		if Network and Network.FireServer then
			pcall(function(...) Network:FireServer(eventName, ...) end, ...)
		else
			pcall(function(...)
				local remotes = ReplicatedStorage:FindFirstChild("NetworkContainer")
				if remotes and remotes:FindFirstChild("RemoteEvents") then
					local rem = remotes.RemoteEvents:FindFirstChild(eventName)
					if rem then rem:FireServer(...) end
				end
			end, ...)
		end
	end

	local lastSafeGroundCFrame = CFrame.new(1866.5, 24, -4874.45)

	------------------------------------------------
	-- 🏦 BCA EVENT STATE & CONFIGURATION (TOP-LEVEL)
	------------------------------------------------
	local BCA_STATE = {
		IDLE = "Idle",
		STARTING_JOB = "StartingJob",
		SPAWNING_VEHICLE = "SpawningVehicle",
		LOADING_SUITCASES = "LoadingSuitcases",
		DELIVERING_TO_ATM = "DeliveringToATM",
		RETURNING_TO_DEPOT = "ReturningToDepot",
		CLAIMING_PAYOUT = "ClaimingPayout",
		COMPLETED = "Completed",
	}
	local bcaEventState = BCA_STATE.IDLE
	local bcaCourierActive = Config.farm.bcaCourier or false
	local bcaCourierDelay = Config.farm.bcaCourierDelay or 1.0
	local targetCruiseSpeed = 163
	local bcaAppSyncActive = false
	local bcaDepotPos = Vector3.new(1866.502, 24, -4874.451)
	local bcaKoperPos = Vector3.new(1779.29, 21.5, -4643.79)
	local bcaCurKoper, bcaTotKoper = 0, 0
	local bcaCurAtm, bcaTotAtm = 0, 0
	local bcaIsCarrying = false
	local bcaJobPhase = ""
	local bcaJobComplete = false
	local bcaTargetEarning = tonumber(Config.farm.bcaTargetEarning) or 0
	local bcaTargetEarningLabel = nil
	local bcaActivityLabel = nil
	local bcaProgressLabel = nil
	local bcaTargetLabel = nil
	local bcaSalaryLabel = nil
	local currentBcaActivity = "Idle"

	local function setBcaState(newState, reason)
		if bcaEventState ~= newState then
			print(string.format("[BCA-STATE] %s -> %s%s", tostring(bcaEventState), tostring(newState), reason and (" | Reason: " .. tostring(reason)) or ""))
			bcaEventState = newState
		end
	end

	local function updateBcaActivity(activity)
		currentBcaActivity = activity or "Idle"
		if bcaActivityLabel then
			pcall(function()
				bcaActivityLabel.Text = "📍 Action: " .. currentBcaActivity
			end)
		end
	end

	local function triggerPrompt(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then return end
		pcall(function()
			prompt.Enabled = true
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 10, 40)
			if fireproximityprompt then
				if prompt.HoldDuration and prompt.HoldDuration > 0 then
					fireproximityprompt(prompt, prompt.HoldDuration)
				else
					fireproximityprompt(prompt)
				end
			elseif prompt.InputHoldBegin then
				prompt:InputHoldBegin()
				task.wait(prompt.HoldDuration or 0.05)
				prompt:InputHoldEnd()
			end
		end)
	end

	-- Spawns an invisible, anchored collision safety plate underneath destination so character & car never fall through unrendered chunks
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
		plate.CFrame = CFrame.new(pos.X, pos.Y - 1.2, pos.Z)
		return plate
	end

	-- Tells Roblox server in the background to prioritize streaming destination chunks without yielding
	local function requestStreamAsync(pos)
		pcall(function()
			if player and player.RequestStreamAroundAsync then
				task.spawn(function()
					pcall(function() player:RequestStreamAroundAsync(pos, 2) end)
				end)
			end
		end)
	end

	-- Safe Character Teleport Function with StreamingEnabled & Anti-Void Protection
	local function safeTeleport(cframe, useTween, speed)
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		print(string.format("[BCA-TRACE][MOVEMENT] safeTeleport called -> Dest: %s | useTween: %s | speed: %s | Caller: %s", 
			tostring(cframe.Position), tostring(useTween), tostring(speed), debug.traceback(nil, 2):match(":(%d+):") or "unknown"))

		-- 1. Ensure invisible safety plate exists at destination before teleporting
		ensureSafetyPlate(cframe.Position, 40)
		requestStreamAsync(cframe.Position)

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		local elevatedCF = cframe + Vector3.new(0, 1.0, 0)

		if useTween then
			speed = speed or 120
			local dist = (root.Position - elevatedCF.Position).Magnitude
			local time = math.clamp(dist / speed, 0.1, 8.0)
			local tw = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = elevatedCF })
			tw:Play()
			tw.Completed:Wait()
		else
			root.CFrame = elevatedCF
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		if elevatedCF.Position.Y > 15 then
			lastSafeGroundCFrame = elevatedCF
		end
	end

	-- Find player's vehicle
	local function getPlayerCar()
		local vehicles = workspace:FindFirstChild("Vehicles")
		if not vehicles then return nil end
		return vehicles:FindFirstChild(player.Name .. "sCar") or vehicles:FindFirstChild(player.Name .. "'s Car")
	end

	-- Universal Safe Ground CFrame Calculator with Streaming Protection
	local function getSafeGroundCFrame(targetPos, desiredAngle)
		requestStreamAsync(targetPos)
		ensureSafetyPlate(targetPos, 50)

		local rayParams = RaycastParams.new()
		local car = getPlayerCar()
		local char = player.Character
		rayParams.FilterDescendantsInstances = { car, char, workspace:FindFirstChild("__SafetyPlate") }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		-- Raycast downward from +14 studs above target
		local hit = workspace:Raycast(targetPos + Vector3.new(0, 14, 0), Vector3.new(0, -45, 0), rayParams)
		local groundY = hit and hit.Position.Y or targetPos.Y
		local safeY = groundY + 2.0 -- exact suspension clearance so tires touch road perfectly

		local rot = desiredAngle and CFrame.Angles(0, math.rad(desiredAngle), 0) or CFrame.new()
		return CFrame.new(targetPos.X, safeY, targetPos.Z) * rot
	end

	local function getGroundPosition(targetPos)
		local cf = getSafeGroundCFrame(targetPos)
		return cf.Position
	end

	-- Background Anti-Void Guardian: Rescues character immediately if falling through unrendered chunks
	task.spawn(function()
		while true do
			pcall(function()
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local humanoid = char and char:FindFirstChild("Humanoid")
				if root and humanoid and humanoid.Health > 0 then
					if root.Position.Y > 15 then
						lastSafeGroundCFrame = root.CFrame
					elseif root.Position.Y < -15 then
						-- Falling into the void! Instantly rescue to safe road!
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						local rescueCF = lastSafeGroundCFrame or CFrame.new(1866.5, 24, -4874.45)
						warn("[BCA-TRACE][ANTI-VOID] Player falling into void! Rescuing to:", tostring(rescueCF.Position))
						ensureSafetyPlate(rescueCF.Position, 60)
						root.CFrame = rescueCF + Vector3.new(0, 3, 0)
						local car = getPlayerCar()
						if car then
							car:PivotTo(rescueCF)
							for _, p in ipairs(car:GetDescendants()) do
								if p:IsA("BasePart") then
									p.AssemblyLinearVelocity = Vector3.zero
								end
							end
						end
					end
				end
			end)
			task.wait(0.1)
		end
	end)

	-- Teleport Player & Vehicle together safely directly on the ground
	local function safeTeleportCar(cframe)
		local safeCF = getSafeGroundCFrame(cframe.Position) * (cframe - cframe.Position)
		local car = getPlayerCar()

		print(string.format("[BCA-TRACE][MOVEMENT] safeTeleportCar called -> Dest: %s", tostring(cframe.Position)))
		if car then
			pcall(function()
				car:PivotTo(safeCF)
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
		end
		safeTeleport(safeCF + Vector3.new(0, 1.0, 3), false)
	end

	local function isInBankMinigame()
		local pgui = player:FindFirstChild("PlayerGui")
		local jobGui = pgui and pgui:FindFirstChild("Job") and pgui.Job:FindFirstChild("BankCourier")
		if not jobGui then return false end
		local timing = jobGui:FindFirstChild("Timing")
		local skill = jobGui:FindFirstChild("Skill")
		if (timing and timing.Visible) or (skill and skill.Visible) then
			return true
		end
		return false
	end

	local function getDriveSeat(car)
		if not car then return nil end
		return car:FindFirstChild("DriveSeat")
			or car:FindFirstChildOfClass("VehicleSeat")
			or car:FindFirstChildOfClass("Seat")
	end

	local isSettling = false
	local function safelySettleAndUnanchor(car)
		if not car or isSettling then return end
		isSettling = true
		pcall(function()
			local root = car.PrimaryPart or getDriveSeat(car)
			if root then
				local currentPos = root.Position
				local _, currentYaw, _ = car:GetPivot():ToOrientation()
				local flatRot = CFrame.Angles(0, currentYaw, 0)
				local rayParams = RaycastParams.new()
				local mapBase = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Base")
				local safetyPlate = workspace:FindFirstChild("__SafetyPlate")
				rayParams.FilterDescendantsInstances = { car, player.Character, mapBase, safetyPlate }
				rayParams.FilterType = Enum.RaycastFilterType.Exclude

				local hit = workspace:Raycast(currentPos + Vector3.new(0, 15, 0), Vector3.new(0, -80, 0), rayParams)
				local surfaceY = hit and hit.Position.Y or (currentPos.Y > 21.0 and currentPos.Y or 22.2)
				local groundY = math.max(surfaceY + 2.2, 22.2)

				-- Create solid parking plate under the vehicle so it never sinks into Map.Base.BAse
				ensureSafetyPlate(Vector3.new(currentPos.X, groundY - 2.2, currentPos.Z), 50)

				-- Smooth gentle descent to ground level (over ~0.25s) with strictly flat rotation
				local startY = currentPos.Y
				local tDown = os.clock()
				while os.clock() - tDown < 0.25 do
					local a = math.clamp((os.clock() - tDown) / 0.25, 0, 1)
					local easedA = -(math.cos(math.pi * a) - 1) / 2
					local curY = startY + (groundY - startY) * easedA
					car:PivotTo(CFrame.new(currentPos.X, curY, currentPos.Z) * flatRot)
					RunService.Heartbeat:Wait()
				end
				car:PivotTo(CFrame.new(currentPos.X, groundY, currentPos.Z) * flatRot)
			end

			-- Zero out velocities and keep unanchored
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					part.Anchored = false
				end
			end

			-- Restore wheel collision ONLY on outer wheels, NEVER on internal suspension parts (base, arm, weight)
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					local name = part.Name:lower()
					if name:find("wheel") or name == "fl" or name == "fr" or name == "rl" or name == "rr" then
						part.CanCollide = true
					elseif name == "base" or name:find("arm") or name:find("weight") or name:find("spindle") or name:find("hub") or name:find("steer") then
						part.CanCollide = false
					end
				end
			end

			-- Apply brakes on A-Chassis
			local pgui = player:FindFirstChild("PlayerGui")
			local aValues = pgui and pgui:FindFirstChild("A-Chassis Interface") and pgui["A-Chassis Interface"]:FindFirstChild("Values")
			if aValues then
				if aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 0 end
				if aValues:FindFirstChild("Brake") then aValues.Brake.Value = 1 end
				if aValues:FindFirstChild("PBrake") then aValues.PBrake.Value = true end
			end
			local seat = getDriveSeat(car)
			if seat and seat:IsA("VehicleSeat") then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
			end
		end)
		isSettling = false
	end

	-- Function to safely seat player in DriveSeat so client gets full Network Ownership for server replication
	local function enterDriveSeat(car)
		if not car or isInBankMinigame() then return false end

		-- Ensure vehicle is firmly placed on upper road surface before sitting
		local currentP = car:GetPivot().Position
		if currentP.Y < 21.0 then
			local safeCF = getSafeGroundCFrame(currentP)
			ensureSafetyPlate(safeCF.Position, 45)
			car:PivotTo(safeCF)
		else
			ensureSafetyPlate(currentP, 45)
		end

		-- Restore wheel collision so car doesn't fall through ground while getting in
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				local name = part.Name:lower()
				if name:find("wheel") or name == "fl" or name == "fr" or name == "rl" or name == "rr" then
					part.CanCollide = true
				end
			end
		end

		local seat = getDriveSeat(car)
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not seat or not hum or not root then 
			warn("[BCA-TRACE][SEAT] enterDriveSeat failed: missing seat, hum, or root")
			return false 
		end

		if hum.Sit and hum.SeatPart == seat then
			print("[BCA-TRACE][SEAT] Player already properly seated in DriveSeat")
			return true
		end

		print("[BCA-TRACE][SEAT] Attempting to seat player in DriveSeat...")
		-- 1. Trigger Official CDID PromptDriveSeat ProximityPrompt
		local prompt = seat:FindFirstChild("PromptDriveSeat") or seat:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			pcall(function()
				prompt.Enabled = true
				prompt.RequiresLineOfSight = false
				prompt.MaxActivationDistance = 40
				if fireproximityprompt then
					fireproximityprompt(prompt)
				elseif prompt.InputHoldBegin then
					prompt:InputHoldBegin()
					task.wait(0.05)
					prompt:InputHoldEnd()
				end
			end)
		end

		-- 2. Direct Engine Sit fallback
		if not hum.Sit or hum.SeatPart ~= seat then
			pcall(function()
				root.CFrame = seat.CFrame + Vector3.new(0, 1.0, 0)
				seat:Sit(hum)
			end)
		end

		local t0 = os.clock()
		while (not hum.Sit or hum.SeatPart ~= seat) and os.clock() - t0 < 1.0 do
			task.wait(0.1)
		end

		local successSeat = hum.Sit and hum.SeatPart == seat
		print(string.format("[BCA-TRACE][SEAT] enterDriveSeat result: %s (Sit=%s, SeatPart=%s)", 
			tostring(successSeat), tostring(hum.Sit), tostring(hum.SeatPart and hum.SeatPart.Name)))
		return successSeat
	end

	-- Function to safely exit DriveSeat
	local function exitDriveSeat()
		local car = getPlayerCar()
		if car then
			safelySettleAndUnanchor(car)
		end
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Sit then
			print("[BCA-TRACE][SEAT] exitDriveSeat: Unseating character from vehicle seat")
			char.Humanoid.Sit = false
			pcall(function()
				char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
			task.wait(0.2)
		end
		if car then
			safelySettleAndUnanchor(car)
		end
	end

	-- 🚗 Server-Validated Vehicle Movement Engine (Paced Direct Movement + Velocity Sync + Road Altitude)
	local function driveTo(targetPos)
		if typeof(targetPos) ~= "Vector3" then
			if typeof(targetPos) == "CFrame" then
				targetPos = targetPos.Position
			else
				warn("[BCA] driveTo failed: targetPos must be a Vector3")
				return false
			end
		end

		local car = getPlayerCar()
		if not car then
			for _ = 1, 10 do
				task.wait(0.2)
				car = getPlayerCar()
				if car then break end
			end
		end

		if not car then
			warn("[BCA] driveTo failed: No vehicle found for player")
			return false
		end

		-- Enter Driver Seat to gain Network Ownership for replication
		enterDriveSeat(car)
		task.wait(0.3)

		local seat = getDriveSeat(car)
		if not seat then
			warn("[BCA] driveTo failed: Driver seat not found in vehicle")
			return false
		end

		local startCF = car:GetPivot()
		local startP = startCF.Position
		local destP = targetPos
		local totalDirectDist = (startP - destP).Magnitude

		-- Configured vehicle driving speed (Internal fixed cruise speed: 163 studs/s)
		local speed = targetCruiseSpeed
		local arriveDist = tonumber(Config.farm.bcaArriveDist) or 35

		if totalDirectDist < arriveDist then
			print(string.format("[BCA] Already at target destination (Distance: %.1f studs)", totalDirectDist))
			safelySettleAndUnanchor(car)
			return true
		end

		print(string.format("[BCA] Starting direct drive to target ATM | Distance: %.1f studs | Speed: %d studs/s", 
			totalDirectDist, speed))

		-- Press gas pedal (W key & Up arrow) via VirtualInputManager & engage A-Chassis throttle
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
			vim:SendKeyEvent(true, Enum.KeyCode.Up, false, game)
		end)

		local pgui = player:FindFirstChild("PlayerGui")
		local aChassisGui = pgui and pgui:FindFirstChild("A-Chassis Interface")
		local aValues = aChassisGui and aChassisGui:FindFirstChild("Values")
		if aChassisGui and aChassisGui:FindFirstChild("IsOn") then aChassisGui.IsOn.Value = true end
		if aValues then
			if aValues:FindFirstChild("PBrake") then aValues.PBrake.Value = false end
			if aValues:FindFirstChild("Brake") then aValues.Brake.Value = 0 end
			if aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 1 end
			if aValues:FindFirstChild("Gear") then aValues.Gear.Value = "D" end
			if aValues:FindFirstChild("RPM") then aValues.RPM.Value = 5200 end
		end
		if seat:IsA("VehicleSeat") then
			seat.Throttle = 1
			seat.ThrottleFloat = 1
		end

		-- Selective Noclip: Disable collision on body/bumpers so obstacles are phased, but preserve unanchored physics
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = false
			end
		end

		-- Direct horizontal direction calculation: continuously point towards destination ATM
		local rawDir = (destP - startP)
		local flatDir = Vector3.new(rawDir.X, 0, rawDir.Z)
		local moveDir = flatDir.Magnitude > 0.1 and flatDir.Unit or Vector3.new(0, 0, -1)

		local duration = math.clamp(totalDirectDist / speed, 0.2, 300.0)
		local t0 = os.clock()
		local driveFinished = false
		local lastGroundY = startP.Y
		local lastOdoTime = 0
		local conn

		conn = RunService.Heartbeat:Connect(function()
			if not bcaCourierActive then
				if conn then conn:Disconnect() end
				driveFinished = true
				return
			end

			local elapsed = os.clock() - t0
			local alpha = math.clamp(elapsed / duration, 0, 1)

			-- Direct line X and Z trajectory straight to ATM
			local curX = startP.X + (destP.X - startP.X) * alpha
			local curZ = startP.Z + (destP.Z - startP.Z) * alpha

			-- Follow road ground elevation via downward raycasts (preserving altitude system)
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { car, player.Character }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local hit = workspace:Raycast(Vector3.new(curX, lastGroundY + 15, curZ), Vector3.new(0, -50, 0), rayParams)
			local roadY = hit and (hit.Position.Y + 2.2) or (startP.Y + (destP.Y - startP.Y) * alpha)
			lastGroundY = roadY
			local curY = math.max(roadY, 22.2)

			local curPos = Vector3.new(curX, curY, curZ)
			local remainingTotal = (destP - curPos).Magnitude
			updateBcaActivity(string.format("🚗 Driving Bank Van Direct (%.0f studs left | %d km/h)", 
				remainingTotal, math.floor(speed * 1.2)))

			-- Continuously compute horizontal heading directly toward the ATM
			local currentDelta = destP - curPos
			local currentFlat = Vector3.new(currentDelta.X, 0, currentDelta.Z)
			local currentMoveDir = currentFlat.Magnitude > 0.1 and currentFlat.Unit or moveDir
			local currentYaw = math.atan2(-currentMoveDir.X, -currentMoveDir.Z)
			local currentRot = CFrame.Angles(0, currentYaw, 0)

			-- Pure horizontal CFrame directly aimed at destination
			local currentCF = CFrame.new(curPos) * currentRot

			pcall(function()
				car:PivotTo(currentCF)

				-- Keep selective noclip active
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.Anchored = false
					end
				end

				-- CRITICAL: Continuous Velocity Synchronization for Server Odometer / Distance Tracking
				if aValues then
					if aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 1 end
					if aValues:FindFirstChild("Brake") then aValues.Brake.Value = 0 end
					if aValues:FindFirstChild("PBrake") then aValues.PBrake.Value = false end
					if aValues:FindFirstChild("Gear") then aValues.Gear.Value = "D" end
					if aValues:FindFirstChild("RPM") then aValues.RPM.Value = 5200 + math.random(-60, 60) end
					if aValues:FindFirstChild("Velocity") then aValues.Velocity.Value = currentMoveDir * speed end
				end
				if seat:IsA("VehicleSeat") then
					seat.Throttle = 1
					seat.ThrottleFloat = 1
					seat.AssemblyLinearVelocity = currentMoveDir * speed
				end

				-- Keep character securely seated in DriveSeat
				local char = player.Character
				local hum = char and char:FindFirstChild("Humanoid")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and seat and (not hum or not hum.Sit or hum.SeatPart ~= seat) then
					root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
					if hum then hum.Sit = true; seat:Sit(hum) end
				end
			end)

			-- Odometer telemetry packet sync (every 0.35s)
			if os.clock() - lastOdoTime >= 0.35 then
				lastOdoTime = os.clock()
				pcall(function()
					if Network and Network.FireServer then
						Network:FireServer("Odometer", 4800)
					end
					fireRemote("Odometer", 4800)
					fireRemote("DataReceiver", { RPM = 5200, Speed = speed, Throttle = 1 })
					if car then
						local curOdo = car:GetAttribute("Odometer") or 0
						car:SetAttribute("Odometer", curOdo + 1)
					end
				end)
			end

			if alpha >= 1 or remainingTotal <= 10 then
				driveFinished = true
				if conn then conn:Disconnect() end
			end
		end)

		while not driveFinished and bcaCourierActive do
			task.wait(0.02)
		end
		if conn then pcall(function() conn:Disconnect() end) end

		-- Release gas pedal (W & Up key)
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
			vim:SendKeyEvent(false, Enum.KeyCode.Up, false, game)
		end)

		-- Settle & Unanchor smoothly on the road with clear collision restoration
		safelySettleAndUnanchor(car)

		local arrivalRemaining = (car:GetPivot().Position - destP).Magnitude
		print(string.format("[BCA] Drive completed. Arrival distance: %.1f studs", arrivalRemaining))
		return arrivalRemaining <= 45
	end

	-- Reusable Vehicle Tween Alias
	local function safeTweenCar(target, speed)
		if typeof(target) == "CFrame" then
			return driveTo(target.Position)
		else
			return driveTo(target)
		end
	end

	------------------------------------------------
	-- 🗺️ JAKARTA MAP BOUNDARIES & SAFE ROUTING SYSTEM
	------------------------------------------------
	local JAKARTA_TRANSITION_REGIONS = {
		{ name = "Jawa Barat Map Portal (Etc.JawaBarat)", center = Vector3.new(2776.6, 80.9, 2390.5), radius = 350 },
		{ name = "Tol Semanggi Gate", center = Vector3.new(760.5, 45.0, 1130.0), radius = 450 },
		{ name = "Tol Semanggi Invispart", center = Vector3.new(752.7, 53.0, 1173.7), radius = 300 },
		{ name = "Simpang Semanggi Interchange", center = Vector3.new(-731.3, 45.0, 1106.4), radius = 380 },
		{ name = "Tol Batas Timur", center = Vector3.new(5100.0, 40.0, 3800.0), radius = 800 },
		{ name = "Tangerang Border Toll", center = Vector3.new(4125.0, 20.0, 5245.0), radius = 500 },
	}

	local function distSegmentToPoint2D(p1, p2, center)
		local dx = p2.X - p1.X
		local dz = p2.Z - p1.Z
		local segLenSq = dx * dx + dz * dz
		if segLenSq < 0.0001 then
			local cx = center.X - p1.X
			local cz = center.Z - p1.Z
			return math.sqrt(cx * cx + cz * cz)
		end
		local t = math.clamp(((center.X - p1.X) * dx + (center.Z - p1.Z) * dz) / segLenSq, 0, 1)
		local projX = p1.X + t * dx
		local projZ = p1.Z + t * dz
		local distX = center.X - projX
		local distZ = center.Z - projZ
		return math.sqrt(distX * distX + distZ * distZ)
	end

	local function isRouteSafe(startPos, targetPos, safetyMargin)
		safetyMargin = safetyMargin or 80

		-- 1. Dynamic Check: Live Workspace.Etc.JawaBarat Trigger Cube (Highest Ground Truth)
		pcall(function()
			local jbPart = workspace:FindFirstChild("Etc") and workspace.Etc:FindFirstChild("JawaBarat")
			if jbPart and jbPart:IsA("BasePart") then
				local jbPos = jbPart.Position
				local jbRadius = (math.max(jbPart.Size.X, jbPart.Size.Z) / 2) + safetyMargin
				local d = distSegmentToPoint2D(startPos, targetPos, jbPos)
				if d < jbRadius then
					return false, "Jawa Barat Map Portal (Etc.JawaBarat)"
				end
			end
		end)

		-- 2. Static Region Table Check
		for _, region in ipairs(JAKARTA_TRANSITION_REGIONS) do
			local dist = distSegmentToPoint2D(startPos, targetPos, region.center)
			if dist < (region.radius + safetyMargin) then
				return false, region.name
			end
		end
		return true, nil
	end

	local function getSafeRoute(startPos, targetPos)
		print(string.format("[BCA ROUTE] Start: (%.1f, %.1f, %.1f)", startPos.X, startPos.Y, startPos.Z))
		print(string.format("[BCA ROUTE] Target ATM: (%.1f, %.1f, %.1f)", targetPos.X, targetPos.Y, targetPos.Z))
		print("[BCA ROUTE] Checking Jakarta transition regions...")

		local isSafe, unsafeRegion = isRouteSafe(startPos, targetPos)
		if isSafe then
			print("[BCA ROUTE] Direct route SAFE")
			print("[BCA ROUTE] Driving directly to ATM")
			return { targetPos }
		end

		print("[BCA ROUTE] Direct route UNSAFE")
		print(string.format("[BCA ROUTE] Transition region detected: %s", tostring(unsafeRegion)))
		print("[BCA ROUTE] Generating safe Jakarta detour avoiding transition cube...")

		local detour = {}

		-- Safe inner-city avenues clear of both Tol Semanggi and Etc.JawaBarat:
		-- Inner Rasuna Said corridor (East-Central): X: 1250, Z: -1500 -> 0 -> 1500 (safely west of Etc.JawaBarat at X: 2776)
		-- Senayan / Palmerah corridor (West): X: -1800, Z: -1000 -> 1000 -> 2500 -> 4500 (safely west of Semanggi)
		-- Puri / Kebon Jeruk corridor (Far West): X: -3500, Z: -1000 -> 2000 -> 5000
		local eastInnerMid1 = Vector3.new(1250.0, 25.0, -1500.0)
		local eastInnerMid2 = Vector3.new(1250.0, 25.0, 0.0)
		local eastInnerMid3 = Vector3.new(1250.0, 28.0, 1500.0)

		local westMid1 = Vector3.new(-1800.0, 25.0, -1000.0)
		local westMid2 = Vector3.new(-1800.0, 25.0, 1500.0)
		local westMid3 = Vector3.new(-1800.0, 25.0, 3500.0)

		local farWestMid1 = Vector3.new(-3800.0, 25.0, 0.0)
		local farWestMid2 = Vector3.new(-3800.0, 25.0, 3500.0)

		-- Validate candidate detour routes
		local isEastSafe = isRouteSafe(startPos, eastInnerMid2) and isRouteSafe(eastInnerMid2, targetPos)
		local isWestSafe = isRouteSafe(startPos, westMid2) and isRouteSafe(westMid2, targetPos)
		local isFarWestSafe = isRouteSafe(startPos, farWestMid2) and isRouteSafe(farWestMid2, targetPos)

		if targetPos.X < -2500 and isFarWestSafe then
			-- Route to Far-West ATMs (e.g. ATM 5, ATM 6) via Puri corridor
			if startPos.Z < -1500 then
				table.insert(detour, farWestMid1)
			end
			table.insert(detour, farWestMid2)
		elseif (targetPos.X < -500 or not isEastSafe) and isWestSafe then
			-- Route via West Senayan corridor
			if startPos.Z < -2000 and targetPos.Z > 1000 then
				table.insert(detour, westMid1)
			end
			table.insert(detour, westMid2)
			if targetPos.Z > 3000 then
				table.insert(detour, westMid3)
			end
		elseif isEastSafe then
			-- Route via East-Central Rasuna Said corridor (safe from Etc.JawaBarat)
			if startPos.Z < -2000 and targetPos.Z > 0 then
				table.insert(detour, eastInnerMid1)
			end
			table.insert(detour, eastInnerMid2)
			if targetPos.Z > 1200 then
				table.insert(detour, eastInnerMid3)
			end
		else
			-- Fallback: Multi-leg West bypass
			table.insert(detour, westMid1)
			table.insert(detour, westMid2)
		end

		table.insert(detour, targetPos)

		for i, wp in ipairs(detour) do
			print(string.format("[BCA ROUTE] Safe Waypoint %d: (%.1f, %.1f, %.1f)", i, wp.X, wp.Y, wp.Z))
		end
		print("[BCA ROUTE] Driving through safe route")
		return detour
	end



	------------------------------------------------
	-- 🏦 BCA EVENT & BANK COURIER AUTO FARM (FULL QUEST AUTOMATION)
	------------------------------------------------
	local function getBankCourierGui()
		local pgui = player:FindFirstChild("PlayerGui")
		return pgui and pgui:FindFirstChild("Job") and pgui.Job:FindFirstChild("BankCourier")
	end

	local function parseRupiahNumber(str)
		if not str then return 0 end
		local cleaned = string.gsub(str, "[^%d]", "")
		return tonumber(cleaned) or 0
	end

	local function formatRupiah(num)
		local str = tostring(math.floor(num or 0))
		local formatted = str:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
		return "Rp. " .. formatted
	end

	local function getPocketRupiahCash()
		local pgui = player:FindFirstChild("PlayerGui")
		if not pgui then return 0 end
		local phone = pgui:FindFirstChild("ACTUAL NEW PHONE") or pgui:FindFirstChild("Phone")
		if not phone then return 0 end

		-- 1. Check PoketRupiah Accumulated & CashAmount
		local poketRupiah = phone:FindFirstChild("PoketRupiah", true)
		if poketRupiah then
			local acc = poketRupiah:FindFirstChild("Accumulated", true)
			if acc and acc:IsA("TextLabel") and acc.Text ~= "" then
				local val = parseRupiahNumber(acc.Text)
				if val > 0 then return val end
			end
			local cash = poketRupiah:FindFirstChild("CashAmount", true)
			if cash and cash:IsA("TextLabel") and cash.Text ~= "" then
				local val = parseRupiahNumber(cash.Text)
				if val > 0 then return val end
			end
		end

		-- 2. Check 3b_POCKETRUPIAH EventPocket Saldo
		local eventPocket = phone:FindFirstChild("EventPocket", true)
		if eventPocket then
			local saldo = eventPocket:FindFirstChild("Saldo", true)
			if saldo and saldo:IsA("TextLabel") and saldo.Text ~= "" then
				local val = parseRupiahNumber(saldo.Text)
				if val > 0 then return val end
			end
		end

		-- 3. Check any Accumulated label under Phone
		local accGlobal = phone:FindFirstChild("Accumulated", true)
		if accGlobal and accGlobal:IsA("TextLabel") and accGlobal.Text ~= "" then
			local val = parseRupiahNumber(accGlobal.Text)
			if val > 0 then return val end
		end

		return 0
	end

	-- 🛡️ Anti Staff / Server Join Auto-Disconnect Guardian
	local antiStaffActive = Config.farm.antiStaff or false
	local function checkAntiStaff(otherPlayer)
		if antiStaffActive and otherPlayer and otherPlayer ~= player then
			pcall(function()
				game:GetService("Players").LocalPlayer:Kick("Anti Staff Detected.")
			end)
		end
	end

	pcall(function()
		game:GetService("Players").PlayerAdded:Connect(function(newPlayer)
			checkAntiStaff(newPlayer)
		end)
	end)

	task.spawn(function()
		while true do
			if antiStaffActive then
				for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
					if otherPlayer ~= player then
						pcall(function()
							game:GetService("Players").LocalPlayer:Kick("Anti Staff Detected.")
						end)
						break
					end
				end
			end
			task.wait(1)
		end
	end)

	local function checkTargetEarningAndDisconnect()
		if bcaTargetEarning and bcaTargetEarning > 0 then
			local targetCash = bcaTargetEarning * 1000000
			local currentCash = getPocketRupiahCash()
			if currentCash > 0 and currentCash >= targetCash then
				bcaCourierActive = false
				Config.farm.bcaCourier = false
				if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end

				local formattedTarget = formatRupiah(targetCash)
				local formattedCurrent = formatRupiah(currentCash)

				local accName = player.Name
				local accDisplay = player.DisplayName
				local accInfo = (accDisplay and accDisplay ~= "" and accDisplay ~= accName) and (accName .. " (" .. accDisplay .. ")") or accName

				local kickMsg = string.format("Auto Farm Selesai di akun %s.\nTarget: %s | Saldo: %s.", accInfo, formattedTarget, formattedCurrent)
				updateBcaActivity("Auto Farm Selesai. Disconnecting...")
				UI.Notify("Target Tercapai", "Target saldo tercapai. Mengakhiri sesi.", 3, "success")
				task.wait(0.5)
				pcall(function()
					game:GetService("Players").LocalPlayer:Kick(kickMsg)
				end)
				return true
			end
		end
		return false
	end

	local function parseProgress(text)
		local cur, total = string.match(text or "", "(%d+)/(%d+)")
		return tonumber(cur) or 0, tonumber(total) or 0
	end

	local function resetBcaState()
		bcaCurKoper = 0
		bcaTotKoper = 0
		bcaCurAtm = 0
		bcaTotAtm = 0
		bcaIsCarrying = false
		bcaJobPhase = ""
		bcaJobComplete = false
		setBcaState(BCA_STATE.IDLE, "resetBcaState called")
	end

	pcall(function()
		player.CharacterAdded:Connect(function()
			-- Resilient Redfinger recovery: verify if active delivery is ongoing before resetting state
			task.spawn(function()
				task.wait(1.0)
				local jobGui = getBankCourierGui()
				local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
				if hasActiveJobGui then
					local kText = jobGui.Status:FindFirstChild("Koper") and jobGui.Status.Koper.Text or ""
					local aText = jobGui.Status:FindFirstChild("Atm") and jobGui.Status.Atm.Text or ""
					local curK, totK = parseProgress(kText)
					local curA, totA = parseProgress(aText)
					if (curK > 0 or bcaCurKoper > 0) and (totA > 0 and curA < totA) then
						print(string.format("[BCA-STATE] Character respawned during active delivery (%d/%d kopers, %d/%d ATMs). Preserving DeliveringToATM state.", curK, totK, curA, totA))
						setBcaState(BCA_STATE.DELIVERING_TO_ATM, "CharacterAdded active delivery recovery")
						return
					end
				end
				if not hasActiveJobGui and not bcaCourierActive then
					resetBcaState()
				end
			end)
		end)
	end)


	local function clickGuiButton(btn)
		if not btn then return end
		pcall(function()
			if firesignal then
				if btn:IsA("GuiButton") then
					firesignal(btn.Activated)
					firesignal(btn.MouseButton1Click)
					pcall(function() firesignal(btn.TouchTap) end)
				end
			end
		end)
		pcall(function()
			if getconnections then
				for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
				for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
				pcall(function()
					for _, c in ipairs(getconnections(btn.TouchTap)) do c:Fire() end
				end)
			end
		end)
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
			vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
			task.wait(0.02)
			vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
		end)
	end

	-- Hook BankCourier Remote to auto-solve ATM Skill Checks and track Koper state with 100% precision
	pcall(function()
		if Network and Network.OnClientEvent then
			Network.OnClientEvent("BankCourier", function(action, data, arg2, arg3, arg4)
				if not bcaCourierActive then return end

				if action == "Koper" then
					bcaCurKoper = tonumber(data) or 0
					bcaCurAtm = tonumber(arg2) or 0
					bcaTotAtm = tonumber(arg3) or 0
					bcaTotKoper = bcaTotAtm
					bcaIsCarrying = (arg4 == true)
					if bcaTotAtm > 0 and bcaCurAtm >= bcaTotAtm then
						bcaJobComplete = true
					end
				elseif action == "Phase" then
					bcaJobPhase = tostring(data)
					if bcaJobPhase == "Returning" then
						bcaJobComplete = true
					end
				elseif action == "Complete" then
					bcaJobComplete = true
				elseif action == "Start" then
					bcaJobComplete = false
					if typeof(data) == "table" then
						bcaTotKoper = data.totalKoper or 0
						bcaTotAtm = bcaTotKoper
					end
				elseif action == "SkillCheck" and typeof(data) == "table" then
					task.spawn(function()
						local warnLead = data.warnLead or 0.04
						local speed = data.speed or 360
						local zoneStart = data.zoneStart or 0
						local zoneSize = data.zoneSize or 40
						local greatSize = data.greatSize or (zoneSize / 2)
						local sweetAngle = (zoneStart + (greatSize / 2)) % 360

						-- Wait until the needle reaches the exact center of the Great zone
						local timeToSweet = (sweetAngle / speed)
						task.wait(math.clamp(warnLead + timeToSweet, 0.05, 4.0))

						-- 1. Direct Server Remote (Always sent!)
						fireRemote("BankCourier", "SkillPress", sweetAngle)

						-- 2. Click Key button in UI
						local jobGui = getBankCourierGui()
						local keyBtn = jobGui and jobGui:FindFirstChild("Skill") and jobGui.Skill:FindFirstChild("Key")
						clickGuiButton(keyBtn)
					end)
				end
			end)
		end
	end)

	local function triggerPrompt(prompt)
		if not prompt or not prompt.Parent then return end

		local holdTime = 0
		pcall(function()
			prompt.Enabled = true
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 10, 35)
			holdTime = tonumber(prompt.HoldDuration) or 0
		end)

		-- 1. Standard Executor Native Hook
		pcall(function()
			if fireproximityprompt then
				if holdTime > 0 then
					fireproximityprompt(prompt, holdTime)
				else
					fireproximityprompt(prompt)
				end
			end
		end)

		-- 2. Direct Roblox Engine InputHold API Simulation (Universal PC + Mobile)
		pcall(function()
			if prompt.InputHoldBegin and prompt.InputHoldEnd then
				prompt:InputHoldBegin()
				task.wait(holdTime > 0 and (holdTime + 0.35) or 0.08)
				prompt:InputHoldEnd()
			end
		end)

		-- 3. Trigger Custom GUI Pill Tap if generated on Mobile/PC
		pcall(function()
			local pgui = player:FindFirstChild("PlayerGui")
			if pgui then
				for _, gui in ipairs(pgui:GetChildren()) do
					if gui.Name == "BankCourierPrompt" or gui:FindFirstChild("Pill") then
						local tap = gui:FindFirstChild("Tap", true)
						if tap then
							if firesignal then
								firesignal(tap.Activated)
								firesignal(tap.MouseButton1Click)
							end
							if getconnections then
								for _, c in ipairs(getconnections(tap.Activated)) do c:Fire() end
								for _, c in ipairs(getconnections(tap.MouseButton1Click)) do c:Fire() end
							end
						end
					end
				end
			end
		end)

		-- 4. Firesignal & Connection Direct Hooks
		pcall(function()
			if firesignal then
				firesignal(prompt.PromptButtonHoldBegan, player)
				firesignal(prompt.PromptButtonHoldEnded, player)
				firesignal(prompt.Triggered, player)
			end
			if getconnections then
				for _, c in ipairs(getconnections(prompt.Triggered)) do c:Fire(player) end
				for _, c in ipairs(getconnections(prompt.PromptButtonHoldEnded)) do c:Fire(player) end
			end
		end)
	end

	-- Function to simulate screen clicks to skip dialogue typewriter text and auto-select choices (Yes / Claim / Finish)
	local function skipAndConfirmNpcDialog(timeout)
		timeout = timeout or 4.0
		local vim = game:GetService("VirtualInputManager")
		local cam = workspace.CurrentCamera
		local t0 = os.clock()

		while os.clock() - t0 < timeout do
			local pgui = player:FindFirstChild("PlayerGui")
			local dialog = pgui and pgui:FindFirstChild("NpcDialog")
			if dialog then
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				local clickX = math.floor(vp.X / 2)
				local clickY = math.floor(vp.Y * 0.78)

				-- 1. Tap screen to skip dialogue typewriter animation
				pcall(function()
					vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
					task.wait(0.02)
					vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
				end)

				-- 2. Check for choices buttons (Yes / Claim / Finish / Spawn / Options)
				local choices = dialog:FindFirstChild("Choices")
				if choices then
					for _, btn in ipairs(choices:GetChildren()) do
						if btn:IsA("GuiButton") and btn.Visible then
							clickGuiButton(btn)
						end
					end
				end
				local yesBtn = (choices and choices:FindFirstChild("Yes")) or dialog:FindFirstChild("Yes", true)
				if yesBtn and yesBtn.Visible then
					clickGuiButton(yesBtn)
				end

				-- Check if dialog closed
				local textLabel = dialog:FindFirstChild("Text")
				if textLabel and not textLabel.Visible and not (choices and choices.Visible) then
					break
				end
			end
			task.wait(0.1)
		end
	end

	-- Background NPC Dialog Auto-Skipper: Taps screen whenever dialog is active
	task.spawn(function()
		local vim = game:GetService("VirtualInputManager")
		local cam = workspace.CurrentCamera
		while true do
			pcall(function()
				local pgui = player:FindFirstChild("PlayerGui")
				local dialog = pgui and pgui:FindFirstChild("NpcDialog")
				local textLabel = dialog and dialog:FindFirstChild("Text")
				local hintLabel = dialog and dialog:FindFirstChild("Hint")
				local choices = dialog and dialog:FindFirstChild("Choices")

				if dialog and ((textLabel and textLabel.Visible) or (hintLabel and hintLabel.Visible) or (choices and choices.Visible)) then
					local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
					local clickX = math.floor(vp.X / 2)
					local clickY = math.floor(vp.Y * 0.78)

					vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
					task.wait(0.02)
					vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)

					if choices then
						for _, btn in ipairs(choices:GetChildren()) do
							if btn:IsA("GuiButton") and btn.Visible then
								clickGuiButton(btn)
							end
						end
					end

					local yesBtn = (choices and choices:FindFirstChild("Yes")) or dialog:FindFirstChild("Yes", true)
					if yesBtn and yesBtn.Visible then
						clickGuiButton(yesBtn)
					end
				end
			end)
			task.wait(0.15)
		end
	end)

	local function getAndhiniNpc()
		local bca = workspace:FindFirstChild("MY_BCA_COLLAB")
		if bca then
			local npc = bca:FindFirstChild("NPC_START_JOB")
				or bca:FindFirstChild("Andhini", true)
				or bca:FindFirstChild("NPC_START_JOB", true)
			if npc then return npc end
		end
		return workspace:FindFirstChild("NPC_START_JOB") or workspace:FindFirstChild("Andhini", true)
	end

	local function getAndhiniPrompt()
		local npc = getAndhiniNpc()
		if npc then
			local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
				or npc:FindFirstChild("DialogPrompt", true)
				or npc:FindFirstChild("Prompt", true)
			if prompt then return prompt, npc end
		end

		local andhiniPos = Vector3.new(1807.269, 23.362, -4635.745)
		local nearby = workspace:GetPartBoundsInRadius(andhiniPos, 15)
		for _, p in ipairs(nearby) do
			local prompt = p:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				return prompt, p:FindFirstAncestorWhichIsA("Model") or p
			end
		end

		return nil, npc
	end

	local function spawnBankCar()
		updateBcaActivity("🚶 Tweening to Putra NPC (200 studs/s)")
		local npc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("CAR_SPAWNER_NPC")
		local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")

		-- 1. Smooth tween right in front of Putra NPC at 200 studs/s
		if npcRoot then
			safeTeleport(npcRoot.CFrame + npcRoot.CFrame.LookVector * 3 + Vector3.new(0, 0.5, 0), true, 200)
		else
			safeTeleport(CFrame.new(bcaDepotPos), true, 200)
		end
		task.wait(0.4)

		-- 2. Trigger Putra Dialog Prompt
		if npc then
			local prompt = npc:FindFirstChild("DialogPrompt", true)
			triggerPrompt(prompt)
		end

		-- 3. Click screen to skip dialog text and confirm vehicle spawn
		updateBcaActivity("🚐 Spawning Armored Bank Van (Skipping Dialog)...")
		skipAndConfirmNpcDialog(3.5)

		fireRemote("NpcDialog", "Finish", 1)
		fireRemote("NpcDialog", "Finish", "SpawnBankCar")
		fireRemote("BankCourier", "RespawnCar")

		-- 4. Wait until vehicle actually exists in workspace
		local t1 = os.clock()
		local car = nil
		while os.clock() - t1 < 6 do
			car = getPlayerCar()
			if car then break end
			task.wait(0.2)
		end

		-- 5. Car spawned successfully in parking lot
		updateBcaActivity("✅ Bank Van Ready -> Loading Suitcases")
		task.wait(0.5)

		return getPlayerCar()
	end

	local function loadKopersIntoCar(car)
		-- DELIVERY STATE GUARD: Block suitcase pickup if currently delivering to ATMs
		if bcaEventState == BCA_STATE.DELIVERING_TO_ATM then
			warn("[BCA-GUARD] Blocked loadKopersIntoCar: Automation is currently in DeliveringToATM state!")
			return
		end

		local jobGui = getBankCourierGui()
		local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
		if not hasActiveJobGui then return end

		local koperText = jobGui.Status:FindFirstChild("Koper") and jobGui.Status.Koper.Text or ""
		local atmText = jobGui.Status:FindFirstChild("Atm") and jobGui.Status.Atm.Text or ""
		local curKoper, totKoper = parseProgress(koperText)
		local curAtm, totAtm = parseProgress(atmText)
		if bcaTotAtm and bcaTotAtm > 0 then
			totAtm = math.max(totAtm, bcaTotAtm)
			curAtm = math.max(curAtm, bcaCurAtm)
		end

		-- MULTIPLE STATE SIGNALS: Validate that we are not in an active partial delivery cycle
		if (curKoper > 0 and curAtm < totAtm) or (bcaCurKoper > 0 and bcaCurAtm < bcaTotAtm) then
			warn(string.format("[BCA-GUARD] Blocked loadKopersIntoCar: Van already carrying %d/%d suitcases with ATM progress %d/%d!", curKoper, totKoper, curAtm, totAtm))
			setBcaState(BCA_STATE.DELIVERING_TO_ATM, "Active delivery in progress")
			return
		end

		setBcaState(BCA_STATE.LOADING_SUITCASES, "Starting suitcase loading sequence")
		local timing = jobGui and jobGui:FindFirstChild("Timing")
		local koperPart = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("KoperSpawn") and workspace.MY_BCA_COLLAB.Job.BankCourier.KoperSpawn:FindFirstChild("Part")

		car = car or getPlayerCar()

		while bcaCourierActive do
			if checkTargetEarningAndDisconnect() then return end

			jobGui = getBankCourierGui()
			local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
			if not hasActiveJobGui then break end

			local koperText = jobGui.Status.Koper.Text or ""
			local curKoper, totKoper = parseProgress(koperText)
			if bcaTotKoper and bcaTotKoper > 0 then
				totKoper = math.max(totKoper, bcaTotKoper)
				curKoper = math.max(curKoper, bcaCurKoper)
			end

			-- If all kopers are loaded (e.g. 2/2, 3/3, 4/4), stop loading
			if totKoper > 0 and curKoper >= totKoper then
				print(string.format("[BCA-TRACE][LOADING] Suitcases full (%d/%d). Exiting loading loop.", curKoper, totKoper))
				break
			end

			-- 1. INSTANT TELEPORT to Koper Stack & Pickup
			print(string.format("[BCA-TRACE][LOADING] Instant teleport to pickup suitcase %d/%d...", curKoper + 1, totKoper))
			updateBcaActivity(string.format("🧳 Teleporting to Suitcase Stack (%d/%d)", curKoper, totKoper))
			if koperPart then
				safeTeleport(koperPart.CFrame + Vector3.new(0, 1.2, 0), false)
				task.wait(0.15)
				local prompt = koperPart:FindFirstChild("Prompt", true) or koperPart:FindFirstChildOfClass("ProximityPrompt")
				triggerPrompt(prompt)
			else
				safeTeleport(CFrame.new(bcaKoperPos), false)
			end

			task.wait(0.2)

			-- 2. INSTANT TELEPORT to Car Bagasi & Trigger Muat
			print(string.format("[BCA-TRACE][LOADING] Instant teleport to trunk with suitcase %d/%d...", curKoper + 1, totKoper))
			updateBcaActivity(string.format("📦 Teleporting to Trunk (%d/%d)", curKoper, totKoper))
			car = getPlayerCar() or car
			local bagasi = car and car:FindFirstChild("BagasiPoint")
			if bagasi then
				local trunkLook = bagasi.CFrame.LookVector
				local trunkStandCF = CFrame.new(bagasi.Position - (trunkLook * 2.2) + Vector3.new(0, 0.5, 0), bagasi.Position)
				safeTeleport(trunkStandCF, false)
				task.wait(0.15)
				local muatPrompt = bagasi:FindFirstChild("MuatPrompt") or bagasi:FindFirstChildOfClass("ProximityPrompt")
				triggerPrompt(muatPrompt)
			else
				local carPivot = car and car:GetPivot() or CFrame.new(bcaDepotPos)
				local trunkStandCF = CFrame.new(carPivot.Position - (carPivot.LookVector * 4.5) + Vector3.new(0, 0.5, 0), carPivot.Position)
				safeTeleport(trunkStandCF, false)
			end

			-- 3. Solve Timing Minigame (drop into green slot)
			timing = jobGui and jobGui:FindFirstChild("Timing")
			local tStart = os.clock()
			while timing and not timing.Visible and os.clock() - tStart < 2.0 do
				task.wait(0.02)
			end

			if timing and timing.Visible then
				local koperImg = timing:FindFirstChild("Track") and timing.Track:FindFirstChild("Koper")
				local slot = timing:FindFirstChild("Trunk") and timing.Trunk:FindFirstChild("Slot")
				local goBtn = timing:FindFirstChild("Go")
				local t0 = os.clock()

				while timing.Visible and os.clock() - t0 < 3.5 do
					if koperImg and slot then
						local kX = koperImg.Position.X.Scale
						local sX = slot.Position.X.Scale
						local sW = slot.Size.X.Scale

						-- Drop precisely when suitcase is inside the green slot
						if kX >= (sX + sW * 0.15) and kX <= (sX + sW * 0.85) then
							-- 1. Direct Server Remote (Always sent!)
							fireRemote("BankCourier", "LoadPress")

							-- 2. Click Go button in UI
							clickGuiButton(goBtn)
							break
						end
					end
					task.wait(0.01)
				end

				-- Wait until minigame closes before next loop iteration
				local tClose = os.clock()
				while timing.Visible and os.clock() - tClose < 1.5 do
					task.wait(0.03)
				end
			end

			task.wait(0.25)
		end

		-- Confirm all suitcases loaded and seat player in driver seat
		car = getPlayerCar() or car
		if car then
			print(string.format("[BCA-TRACE][LOADING] ✅ Suitcases loaded in trunk. Seating in DriverSeat..."))
			updateBcaActivity("✅ Suitcases Loaded -> Entering Driver Seat to Cruise")
			enterDriveSeat(car)
			task.wait(0.3)
		end
	end

	-- Safe Open Parking Spots for Vehicle (Clear sky, open asphalt, no pillars or ceilings)
	local ATM_PARKING_SPOTS = {
		["ATM1"] = Vector3.new(1860.0, 24.5, -4850.0),
		["ATM2"] = Vector3.new(2212.55, 27.5, -4594.36),
		["ATM3"] = Vector3.new(825.0, 24.2, -3810.0),
		["ATM4"] = Vector3.new(2291.25, 27.96, -4882.77),
		["ATM7"] = Vector3.new(-475.64, 26.27, 8732.79),
		["ATM8"] = Vector3.new(-223.75, 21.93, 10705.88),
		["ATM9"] = Vector3.new(1550.03, 50.14, 875.15),
		["ATM10"] = Vector3.new(2023.20, 21.44, -3538.69),
	}

	-- Exact Stand Positions for Character Directly in Front of ATM Screen (< 3 studs)
	local ATM_STAND_SPOTS = {
		["ATM1"] = Vector3.new(1860.0, 24.5, -4850.0),
		["ATM2"] = Vector3.new(2224.71, 29.29, -4596.95),
		["ATM3"] = Vector3.new(833.32, 24.23, -3825.72),
		["ATM4"] = Vector3.new(2291.25, 27.96, -4882.77),
		["ATM7"] = Vector3.new(-475.64, 26.27, 8732.79),
		["ATM8"] = Vector3.new(-223.75, 21.93, 10705.88),
		["ATM9"] = Vector3.new(1585.46, 51.14, 870.47),
		["ATM10"] = Vector3.new(1988.32, 24.44, -3531.15),
	}

	local ATM_OPTION_MAP = {
		["Auto (Active ATM)"] = "Auto",
		["ATM 9 (BSD City - 5700 studs)"] = "ATM9",
		["ATM 7 (Tol Selatan - 13800 studs)"] = "ATM7",
		["ATM 8 (Ring Road - 15700 studs)"] = "ATM8",
		["ATM 3 (Plaza Barat - 1470 studs)"] = "ATM3",
		["ATM 10 (City South - 1400 studs)"] = "ATM10",
		["ATM 2 (BCA Office - 440 studs)"] = "ATM2",
		["ATM 4 (City Center - 420 studs)"] = "ATM4",
		["ATM 1 (Depot - 25 studs)"] = "ATM1",
	}

	local function getBankCourierTargetPos()
		local customAtm = Config.farm.bcaTargetAtm
		if customAtm and customAtm ~= "Auto" and ATM_PARKING_SPOTS[customAtm] then
			return ATM_PARKING_SPOTS[customAtm], customAtm
		end

		-- 1. Check Active Target ATM in MY_BCA_COLLAB (Highest Priority - Ground Truth)
		local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
		if atms then
			-- Check for active ATM with Enabled prompt
			for _, atm in ipairs(atms:GetChildren()) do
				local prompt = atm:FindFirstChildOfClass("ProximityPrompt") or atm:FindFirstChild("Prompt", true)
				local p = atm:FindFirstChildOfClass("BasePart") or (prompt and prompt.Parent)
				if prompt and prompt.Enabled and p and (p.Position - bcaDepotPos).Magnitude > 30 then
					return p.Position, atm.Name
				end
			end

			-- Check for active Highlight or BillboardGui on ATM
			for _, atm in ipairs(atms:GetChildren()) do
				local highlight = atm:FindFirstChildOfClass("Highlight") or atm:FindFirstChild("Highlight", true)
				local bbg = atm:FindFirstChildOfClass("BillboardGui") or atm:FindFirstChild("BillboardGui", true)
				local p = atm:FindFirstChildOfClass("BasePart")
				if ((highlight and highlight.Enabled) or (bbg and bbg.Enabled)) and p and (p.Position - bcaDepotPos).Magnitude > 30 then
					return p.Position, atm.Name
				end
			end
		end

		-- 2. Check Waypoints (Pick the FURTHEST destination waypoint to get the true ATM destination, not intermediate turns!)
		local waypoints = workspace:FindFirstChild("Etc") and workspace.Etc:FindFirstChild("Waypoint")
		if waypoints and #waypoints:GetChildren() > 0 then
			local furthestPos = nil
			local maxDist = 0
			for _, wp in ipairs(waypoints:GetChildren()) do
				if wp:IsA("BasePart") then
					local d = (wp.Position - bcaDepotPos).Magnitude
					if d > 30 and d > maxDist then
						maxDist = d
						furthestPos = wp.Position
					end
				end
			end
			if furthestPos then
				for atmName, spotPos in pairs(ATM_PARKING_SPOTS) do
					if (spotPos - furthestPos).Magnitude < 400 then
						return spotPos, atmName
					end
				end
				return furthestPos
			end
		end

		-- 3. Check BankCourierRoute Beam in workspace
		local route = workspace:FindFirstChild("BankCourierRoute")
		if route and route:FindFirstChild("To") then
			local pos = route.To.WorldPosition
			if pos and (pos - bcaDepotPos).Magnitude > 30 then
				return pos
			end
		end

		-- 4. Check __BankCourierTarget
		local targetPart = workspace:FindFirstChild("__BankCourierTarget")
		if targetPart and (targetPart.Position - bcaDepotPos).Magnitude > 30 then
			return targetPart.Position
		end

		return nil
	end

	local function deliverToAtms(car)
		setBcaState(BCA_STATE.DELIVERING_TO_ATM, "Entering deliverToAtms")
		local jobGui = getBankCourierGui()
		local bagasi = car and car:FindFirstChild("BagasiPoint")

		-- Pre-check: If car has 0 kopers and no ATM progress, abort delivery and let main loop load them first
		local koperText = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("Koper") and jobGui.Status.Koper.Text or ""
		local atmText = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("Atm") and jobGui.Status.Atm.Text or ""
		local curKoper, totKoper = parseProgress(koperText)
		local curAtm, totAtm = parseProgress(atmText)
		if curAtm == 0 and totKoper > 0 and curKoper == 0 then
			print(string.format("[BCA] deliverToAtms: Car has %d/%d kopers at start. Aborting delivery, needs loading first.", curKoper, totKoper))
			return
		end

		while bcaCourierActive do
			if checkTargetEarningAndDisconnect() then return end

			atmText = jobGui and jobGui.Status:FindFirstChild("Atm") and jobGui.Status.Atm.Text or ""
			local stepText = jobGui and jobGui.Status:FindFirstChild("Step") and jobGui.Status.Step.Text or ""
			curAtm, totAtm = parseProgress(atmText)

			-- If all ATMs filled, stop delivering
			if (totAtm > 0 and curAtm >= totAtm) or stepText:find("3)") or stepText:find("Selesai") then
				break
			end

			local targetPos = getBankCourierTargetPos()
			if not targetPos then
				print("[BCA-TRACE][DELIVERY] Waiting for Bank Courier route / target waypoint...")
				local tWait = os.clock()
				while not targetPos and os.clock() - tWait < 6 and bcaCourierActive do
					task.wait(0.5)
					targetPos = getBankCourierTargetPos()
					local curA, totA = parseProgress(jobGui and jobGui.Status.Atm.Text or "")
					if bcaJobComplete or (totA > 0 and curA >= totA) then break end
				end
				if not targetPos then 
					warn("[BCA-TRACE][DELIVERY] Aborting delivery loop: No target ATM found in workspace")
					break 
				end
			end

			-- 1. Match destination to designated safe open parking spot
			local safeAtmCF = nil
			local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
			if atms then
				for atmName, spotPos in pairs(ATM_PARKING_SPOTS) do
					local atm = atms:FindFirstChild(atmName)
					local p = atm and (atm:FindFirstChildOfClass("BasePart") or atm:FindFirstChild("Part", true))
					if (p and (p.Position - targetPos).Magnitude < 100) or (spotPos - targetPos).Magnitude < 250 then
						safeAtmCF = CFrame.new(spotPos)
						print(string.format("[BCA-TRACE][DELIVERY] Matched targetPos %s to designated spot %s (%s)", 
							tostring(targetPos), atmName, tostring(spotPos)))
						break
					end
				end
			end

			if not safeAtmCF then
				safeAtmCF = getSafeGroundCFrame(targetPos + Vector3.new(-12, 0, 10))
				print(string.format("[BCA-TRACE][DELIVERY] Using raycasted fallback ground spot: %s", tostring(safeAtmCF.Position)))
			end

			local targetDrivePos = safeAtmCF and safeAtmCF.Position or targetPos
			local currentCarPos = car and car:GetPivot().Position or (player.Character and player.Character:GetPivot().Position) or bcaDepotPos
			local route = getSafeRoute(currentCarPos, targetDrivePos)

			local driveSuccess = true
			for segIdx, waypoint in ipairs(route) do
				if not bcaCourierActive then break end
				if #route > 1 then
					updateBcaActivity(string.format("🚗 Driving Safe Detour (%d/%d) to ATM (163 studs/s)", segIdx, #route))
				else
					updateBcaActivity("🚗 Driving Bank Van Direct to ATM (163 studs/s)")
				end
				local success = driveTo(waypoint)
				if not success then
					driveSuccess = false
					warn(string.format("[BCA] driveTo failed at waypoint %d/%d. Aborting delivery step.", segIdx, #route))
					break
				end
			end

			if not driveSuccess then
				break
			end

			print(string.format("[BCA] Arrived at destination ATM. Car is now at %s", tostring(car and car:GetPivot().Position)))
			exitDriveSeat()
			task.wait(1.0) -- Wait 1.0s after parking car near ATM before grabbing koper

			-- Check if game enforces an arrival cooldown (e.g. "TUNGGU 32s")
			local respawnBtn = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("RespawnCar")
			if respawnBtn and respawnBtn.Visible and respawnBtn.Text:find("TUNGGU") then
				local waitSeconds = tonumber(respawnBtn.Text:match("(%d+)"))
				if waitSeconds and waitSeconds > 0 then
					updateBcaActivity("⏳ Waiting Arrival Cooldown (" .. waitSeconds .. "s)")
					local t0 = os.clock()
					while os.clock() - t0 < (waitSeconds + 1) and bcaCourierActive do
						task.wait(1)
					end
				end
			end

			-- 2. Take Koper from Bagasi on the ground (Verify suitcase is in hand before proceeding)
			local function isCarryingKoper()
				local c = player.Character
				if not c then return false end
				if bcaIsCarrying == true then return true end
				if c:FindFirstChild("KoperUang") or c:FindFirstChildOfClass("Tool") then return true end
				if c:GetAttribute("BankCourierCarryAnim") ~= nil then return true end
				if player:GetAttribute("HidePrompt") == true then return true end
				local jobGui = getBankCourierGui()
				local hintText = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("Hint") and jobGui.Status.Hint.Text or ""
				if hintText:find("ATM") and (hintText:find("Isi") or hintText:find("bawa") or hintText:find("Bawa")) then
					return true
				end
				return false
			end

			if bagasi then
				updateBcaActivity("✋ Taking Suitcase from Trunk (Holding for 2.7s)")
				local ambilPrompt = bagasi:FindFirstChild("AmbilPrompt") or bagasi:FindFirstChildOfClass("ProximityPrompt")
				local vim = game:GetService("VirtualInputManager")
				local tStart = os.clock()
				local failedGrabAttempts = 0

				while not isCarryingKoper() and os.clock() - tStart < 40 and bcaCourierActive do
					-- Check if failed 3 times: Auto re-park closer to ATM
					if failedGrabAttempts >= 3 then
						local carPivot = car and car:GetPivot()
						local carPos = carPivot and carPivot.Position or Vector3.zero
						local distToAtm = (carPos - targetPos).Magnitude
						updateBcaActivity(string.format("⚠️ Grab failed 3x (Dist: %.1f) -> Auto Re-parking 12 studs next to ATM...", distToAtm))

						-- Re-enter driver seat to claim network ownership
						enterDriveSeat(car)
						task.wait(0.2)

						-- Calculate close CFrame oriented with trunk facing ATM
						local closePos = getSafeGroundCFrame(targetPos + Vector3.new(-8, 0, 8), 15).Position
						local closeCF = CFrame.new(closePos, closePos + (closePos - targetPos))
						safeTweenCar(closeCF, 120)
						task.wait(1.0)

						-- Settle physics & Unsit
						for _, part in ipairs(car:GetDescendants()) do
							if part:IsA("BasePart") then
								part.AssemblyLinearVelocity = Vector3.zero
								part.AssemblyAngularVelocity = Vector3.zero
							end
						end

						local char = player.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hum and hum.Sit then
							for _ = 1, 5 do
								if not hum.Sit then break end
								hum.Sit = false
								pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
								task.wait(0.15)
							end
							task.wait(0.4)
						end

						bagasi = car:FindFirstChild("BagasiPoint")
						failedGrabAttempts = 0
						task.wait(0.5)
					end

					-- If failed 6+ times (e.g. car stuck under geometry), trigger Emergency Car Recall
					if failedGrabAttempts >= 5 then
						local respawnBtn = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("RespawnCar")
						if respawnBtn and respawnBtn.Visible and not respawnBtn.Text:find("TUNGGU") then
							updateBcaActivity("🆘 Car Stalled -> Triggering Panggil Mobil...")
							fireRemote("BankCourier", "RespawnCar")
							clickGuiButton(respawnBtn)
							task.wait(2.0)
							car = getPlayerCar() or car
							bagasi = car and car:FindFirstChild("BagasiPoint")
							failedGrabAttempts = 0
						end
					end

					-- 1. Position character right behind the trunk on the ground facing the trunk
					local trunkPos = bagasi and bagasi.Position or (car:GetPivot().Position - car:GetPivot().LookVector * 5)
					local trunkLook = bagasi and bagasi.CFrame.LookVector or car:GetPivot().LookVector
					local standCF = CFrame.new(trunkPos + (trunkLook * -2.5) + Vector3.new(0, 0.5, 0), trunkPos)
					safeTeleport(standCF)
					task.wait(0.2)

					ambilPrompt = bagasi and (bagasi:FindFirstChild("AmbilPrompt") or bagasi:FindFirstChildOfClass("ProximityPrompt"))
					if not ambilPrompt then
						for _, p in ipairs(car:GetDescendants()) do
							if p:IsA("ProximityPrompt") and (p.Name:find("Ambil") or p.ActionText:lower():find("ambil")) then
								ambilPrompt = p
								break
							end
						end
					end

					if ambilPrompt then
						local holdSec = tonumber(ambilPrompt.HoldDuration) or 2.0
						pcall(function()
							ambilPrompt.Enabled = true
							ambilPrompt.RequiresLineOfSight = false
							ambilPrompt.MaxActivationDistance = math.max(ambilPrompt.MaxActivationDistance or 9, 35)
						end)

						-- A. Standard Executor Native Hook
						pcall(function()
							if fireproximityprompt then
								if holdSec > 0 then
									fireproximityprompt(ambilPrompt, holdSec)
								else
									fireproximityprompt(ambilPrompt)
								end
							end
						end)

						-- B. Press and hold down 'F' key & InputHoldBegin for full duration
						pcall(function()
							if ambilPrompt.InputHoldBegin then
								ambilPrompt:InputHoldBegin()
							end
							local uis = game:GetService("UserInputService")
							if uis.KeyboardEnabled then
								vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
							end
						end)

						-- C. Trigger Mobile / Custom UI Pill Tap
						pcall(function()
							local pgui = player:FindFirstChild("PlayerGui")
							if pgui then
								for _, gui in ipairs(pgui:GetChildren()) do
									if gui.Name == "BankCourierPrompt" or gui:FindFirstChild("Pill") then
										local tap = gui:FindFirstChild("Tap", true)
										if tap then
											if firesignal then
												firesignal(tap.Activated)
												firesignal(tap.MouseButton1Click)
											end
											if getconnections then
												for _, c in ipairs(getconnections(tap.Activated)) do c:Fire() end
												for _, c in ipairs(getconnections(tap.MouseButton1Click)) do c:Fire() end
											end
										end
									end
								end
							end
						end)

						-- Hold continuously for required hold duration (2.7s for cloud jitter safety) or until suitcase is in hand
						local tHold = os.clock()
						while not isCarryingKoper() and os.clock() - tHold < (holdSec + 0.7) do
							task.wait(0.05)
						end

						-- Release 'F' key & InputHoldEnd
						pcall(function()
							local uis = game:GetService("UserInputService")
							if uis.KeyboardEnabled then
								vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
							end
							if ambilPrompt.InputHoldEnd then
								ambilPrompt:InputHoldEnd()
							end
						end)

						-- D. Firesignal & Connection Direct Hooks
						pcall(function()
							if firesignal then
								pcall(function() firesignal(ambilPrompt.PromptButtonHoldBegan, player) end)
								pcall(function() firesignal(ambilPrompt.PromptButtonHoldEnded, player) end)
								pcall(function() firesignal(ambilPrompt.Triggered, player) end)
							end
							if getconnections then
								pcall(function()
									for _, c in ipairs(getconnections(ambilPrompt.Triggered)) do
										pcall(function() if c.Fire then c:Fire(player) elseif c.Function then c.Function(player) end end)
									end
									for _, c in ipairs(getconnections(ambilPrompt.PromptButtonHoldEnded)) do
										pcall(function() if c.Fire then c:Fire(player) elseif c.Function then c.Function(player) end end)
									end
								end)
							end
						end)
					end

					-- Grace period for server to replicate suitcase to character before retrying
					task.wait(0.6)

					if not isCarryingKoper() then
						failedGrabAttempts = failedGrabAttempts + 1
					end
				end
			end

			task.wait(0.6)

			-- 3. Teleport character directly in front of ATM Screen (< 3 studs away)
			local atmFrontPos = nil
			local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
			if atms then
				for _, atm in ipairs(atms:GetChildren()) do
					local prompt = atm:FindFirstChildOfClass("ProximityPrompt") or atm:FindFirstChild("Prompt", true)
					local screen = atm:FindFirstChild("Screen_ATM_01", true) or (prompt and prompt.Parent) or atm:FindFirstChildOfClass("BasePart")
					if screen and screen:IsA("BasePart") and (screen.Position - targetPos).Magnitude < 100 then
						atmFrontPos = screen.Position + screen.CFrame.LookVector * 2.5
						break
					end
				end
			end

			if not atmFrontPos then
				for atmName, standPos in pairs(ATM_STAND_SPOTS) do
					if (standPos - targetPos).Magnitude < 90 then
						atmFrontPos = standPos
						break
					end
				end
			end

			if not atmFrontPos then
				atmFrontPos = getGroundPosition(targetPos)
			end

			updateBcaActivity("🏧 Stepping in Front of ATM Machine")
			safeTeleport(CFrame.new(atmFrontPos), true, 30)
			task.wait(0.5)

			local nearbyParts = workspace:GetPartBoundsInRadius(atmFrontPos, 25)
			for _, p in ipairs(nearbyParts) do
				for _, prompt in ipairs(p:GetChildren()) do
					if prompt:IsA("ProximityPrompt") and prompt.Enabled and (prompt.ActionText:lower():find("isi") or prompt.ObjectText:lower():find("atm") or prompt.Name:find("Isi")) then
						triggerPrompt(prompt)
					end
				end
			end
			updateBcaActivity("⚡ Filling ATM Machine (Skill Check Rounds)")
			fireRemote("BankCourier", "FillStart")

			-- 4. Wait for all 3 Skill Check rounds to complete (Strictly do not interrupt while minigame is open!)
			local skill = jobGui and jobGui:FindFirstChild("Skill")
			local tOpen = os.clock()
			while (not skill or not skill.Visible) and os.clock() - tOpen < 2.5 and bcaCourierActive do
				skill = jobGui and jobGui:FindFirstChild("Skill")
				task.wait(0.1)
			end

			local tSolve = os.clock()
			while (skill and skill.Visible) and os.clock() - tSolve < 20 and bcaCourierActive do
				task.wait(0.2)
			end

			task.wait(1.5)

			-- Check if all assigned ATMs are filled (e.g. 2/2, 3/3, 4/4) or Step 3 reached
			jobGui = getBankCourierGui()
			local curA, totA = parseProgress(jobGui and jobGui.Status.Atm.Text or "")
			local stepT = jobGui and jobGui.Status.Step.Text or ""
			if (totA > 0 and curA >= totA) or bcaJobComplete or stepT:find("3)") or stepT:find("Kembali") or stepT:find("Selesai") then
				bcaJobComplete = true
				break
			end
		end
	end

	local function claimAndhiniPayout()
		local maxAttempts = 3
		local andhiniDefaultPos = Vector3.new(1807.269, 23.362, -4635.745)
		local safeAwayPos = Vector3.new(1795.0, 22.22, -4625.0)

		for attempt = 1, maxAttempts do
			print(string.format("[BCA] Andhini payout attempt %d/%d", attempt, maxAttempts))
			updateBcaActivity(string.format("💰 Claiming Salary (Attempt %d/%d)...", attempt, maxAttempts))

			-- Anti-stuck recovery on attempt 3: Move slightly away to safe position before repositioning
			if attempt == 3 then
				print("[BCA] Attempt 3: Performing anti-stuck position reset...")
				safeTeleport(CFrame.new(safeAwayPos), false)
				task.wait(0.6)
			end

			-- STEP 1: POSITIONING & VERIFICATION
			print("[BCA] Moving to Andhini")
			local prompt, npc = getAndhiniPrompt()
			local root = npc and (npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("UpperTorso") or npc:FindFirstChildOfClass("BasePart"))
			local targetCF = root and (root.CFrame + root.CFrame.LookVector * 2.8 + Vector3.new(0, 0.2, 0)) or CFrame.new(andhiniDefaultPos + Vector3.new(0, 0, 3))

			safeTeleport(targetCF, false)
			task.wait(0.35)

			-- Verify character distance to Andhini
			local char = player.Character
			local charRoot = char and char:FindFirstChild("HumanoidRootPart")
			local targetPos = root and root.Position or andhiniDefaultPos
			local dist = charRoot and (charRoot.Position - targetPos).Magnitude or 999
			print(string.format("[BCA] Andhini distance: %.1f studs", dist))

			if dist > 8 then
				print("[BCA] Character outside interaction range, repositioning...")
				safeTeleport(targetCF, false)
				task.wait(0.4)
				char = player.Character
				charRoot = char and char:FindFirstChild("HumanoidRootPart")
				dist = charRoot and (charRoot.Position - targetPos).Magnitude or 999
				print(string.format("[BCA] Andhini distance after reposition: %.1f studs", dist))
			end

			-- STEP 2: INTERACTION VALIDATION
			prompt, npc = getAndhiniPrompt()
			if prompt then
				print("[BCA] Prompt detected")
				pcall(function()
					prompt.Enabled = true
					prompt.RequiresLineOfSight = false
					prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 10, 40)
				end)
			end

			print("[BCA] Triggering Andhini")
			if prompt then
				triggerPrompt(prompt)
			end

			-- STEP 3: DIALOG VALIDATION
			print("[BCA] Waiting for dialog")
			local dialogDetected = false
			local tDialogStart = os.clock()

			while os.clock() - tDialogStart < 3.0 do
				local pgui = player:FindFirstChild("PlayerGui")
				local dialog = pgui and pgui:FindFirstChild("NpcDialog")
				local textLabel = dialog and dialog:FindFirstChild("Text")
				local hintLabel = dialog and dialog:FindFirstChild("Hint")
				local choices = dialog and dialog:FindFirstChild("Choices")

				if dialog and ((textLabel and textLabel.Visible) or (hintLabel and hintLabel.Visible) or (choices and choices.Visible)) then
					dialogDetected = true
					break
				end
				task.wait(0.1)
			end

			if dialogDetected then
				print("[BCA] Dialog detected")
			else
				print(string.format("[BCA] Attempt %d failed: dialog did not appear", attempt))
			end

			-- STEP 4: PAYOUT EXECUTION
			print("[BCA] Completing payout")
			skipAndConfirmNpcDialog(3.5)

			fireRemote("NpcDialog", "Finish", 1)
			fireRemote("NpcDialog", "Finish", "BankCourier")
			fireRemote("BankCourier", "Complete")
			fireRemote("PhoneJobSalary")
			fireRemote("MyBcaAppOpened")

			-- STEP 5: PAYOUT VALIDATION (Polling state)
			print("[BCA] Verifying payout...")
			local payoutConfirmed = false
			local tVerify = os.clock()

			while os.clock() - tVerify < 4.0 do
				local jobGui = getBankCourierGui()
				local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)

				if not hasActiveJobGui then
					payoutConfirmed = true
					break
				end

				local stepText = jobGui.Status:FindFirstChild("Step") and jobGui.Status.Step.Text or ""
				local hintText = jobGui.Status:FindFirstChild("Hint") and jobGui.Status.Hint.Text or ""
				if not (stepText:find("3)") or stepText:find("Kembali") or stepText:find("GAJIAN") or stepText:find("gaji") or hintText:find("terima gaji") or hintText:find("Andhini")) then
					payoutConfirmed = true
					break
				end

				task.wait(0.2)
			end

			if payoutConfirmed then
				print("[BCA] Payout SUCCESS")
				return true
			else
				print(string.format("[BCA] Attempt %d failed: payout not confirmed", attempt))
				if attempt < maxAttempts then
					print("[BCA] Recovering position...")
					print("[BCA] Retrying Andhini interaction")
					task.wait(0.8)
				end
			end
		end

		warn(string.format("[BCA] ERROR: Andhini payout failed after %d attempts", maxAttempts))
		print("[BCA] Stopping cycle to prevent false completion")
		return false
	end

	local function runBcaCourierFarm()
		task.spawn(function()
			while bcaCourierActive do
				pcall(function()
					-- If in minigame, DO ABSOLUTELY NOTHING and wait for minigame to finish
					while isInBankMinigame() and bcaCourierActive do
						task.wait(0.2)
					end

					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					if checkTargetEarningAndDisconnect() then return end

					local jobGui = getBankCourierGui()
					local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)

					local hintText = hasActiveJobGui and jobGui.Status:FindFirstChild("Hint") and jobGui.Status.Hint.Text or ""
					local koperText = hasActiveJobGui and jobGui.Status:FindFirstChild("Koper") and jobGui.Status.Koper.Text or ""
					local atmText = hasActiveJobGui and jobGui.Status:FindFirstChild("Atm") and jobGui.Status.Atm.Text or ""
					local stepText = hasActiveJobGui and jobGui.Status:FindFirstChild("Step") and jobGui.Status.Step.Text or ""

					local curKoper, totKoper = parseProgress(koperText)
					local curAtm, totAtm = parseProgress(atmText)
					if bcaTotAtm and bcaTotAtm > 0 then
						totAtm = math.max(totAtm, bcaTotAtm)
						curAtm = math.max(curAtm, bcaCurAtm)
					end

					local isAtmDone = bcaJobComplete
						or (totAtm > 0 and curAtm >= totAtm)
						or stepText:find("3)")
						or stepText:find("Kembali")
						or stepText:find("GAJIAN")
						or stepText:find("gaji")
						or hintText:find("terima gaji")
						or hintText:find("Andhini")

					if not hasActiveJobGui and not isAtmDone and bcaEventState ~= BCA_STATE.STARTING_JOB then
						resetBcaState()
					end

					-- STEP 5: Return to Depot & Approach Andhini NPC to Claim Salary (PRIORITY #1 when all ATMs are filled / GAJIAN!)
					if isAtmDone then
						setBcaState(BCA_STATE.RETURNING_TO_DEPOT, "All ATMs delivered, returning to depot")
						updateBcaActivity("⚡ Instant Teleporting Van Back to BCA Depot...")
						local depotCF = CFrame.new(1781.04, 22.22, -4615.77)
						safeTeleportCar(depotCF)
						exitDriveSeat()

						-- Settle physics & guarantee character is unseated
						local char = player.Character
						local hum = char and char:FindFirstChild("Humanoid")
						if hum and hum.Sit then
							for _ = 1, 6 do
								hum.Sit = false
								pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
								pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
								task.wait(0.1)
								if not hum.Sit then break end
							end
						end
						task.wait(0.3)

						setBcaState(BCA_STATE.CLAIMING_PAYOUT, "Interacting with Andhini for contract salary")
						local success = claimAndhiniPayout()

						if success then
							resetBcaState()
							setBcaState(BCA_STATE.COMPLETED, "Contract completed and payout claimed successfully")
							updateBcaActivity("🎉 Contract Completed! Salary Claimed")
							task.wait(1.5)
							if checkTargetEarningAndDisconnect() then return end
							task.wait(1.0)
							return
						else
							warn("[BCA] ERROR: Andhini payout failed after all attempts. Stopping cycle safely.")
							updateBcaActivity("⚠️ Payout Failed! Pausing cycle...")
							task.wait(3.0)
							return
						end
					end

					-- STEP 1: Ensure Bank Courier Job is active (ONLY when starting completely fresh)
					if not hasActiveJobGui then
						setBcaState(BCA_STATE.STARTING_JOB, "No active job GUI, talking to Andhini")
						updateBcaActivity("🚶 Approaching Andhini NPC to Start Job...")
						local andhiniPos = Vector3.new(1807.269, 23.362, -4635.745)
						local prompt, npc = getAndhiniPrompt()
						local root = npc and npc:FindFirstChild("HumanoidRootPart")
						if root then
							safeTeleport(root.CFrame + root.CFrame.LookVector * 2.8 + Vector3.new(0, 0.2, 0), false)
						else
							safeTeleport(CFrame.new(andhiniPos + Vector3.new(0, 0, 3)), false)
						end
						task.wait(0.35)

						prompt, npc = getAndhiniPrompt()
						if prompt then
							triggerPrompt(prompt)
						end

						skipAndConfirmNpcDialog(4.0)

						fireRemote("Job", "BankCourier")
						fireRemote("NpcDialog", "Finish", 1)
						fireRemote("NpcDialog", "Finish", "BankCourier")
						task.wait(1.5)
						jobGui = getBankCourierGui()
						hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
						if not hasActiveJobGui then return end
					end

					-- STEP 2: Ensure Bank Car is spawned via Putra NPC
					local car = getPlayerCar()
					if not car or hintText:find("Keluarkan mobil") or hintText:find("petugas kendaraan") then
						setBcaState(BCA_STATE.SPAWNING_VEHICLE, "Car missing or despawned")
						car = spawnBankCar()
						task.wait(0.5)
						return
					end

					if not car then
						task.wait(1)
						return
					end

					-- RECOVERY & STATE VALIDATION: Partial Delivery Active Check
					-- If the van is already carrying suitcases OR some ATMs are already filled,
					-- the automation MUST remain in DeliveringToATM state and NEVER restart suitcase pickup!
					local isPartialDeliveryActive = (curAtm > 0 or bcaCurAtm > 0 or bcaEventState == BCA_STATE.DELIVERING_TO_ATM) and (totAtm > 0 and curAtm < totAtm)
					if isPartialDeliveryActive then
						setBcaState(BCA_STATE.DELIVERING_TO_ATM, string.format("Partial delivery active: %d/%d kopers, %d/%d ATMs", curKoper, totKoper, curAtm, totAtm))
						deliverToAtms(car)
						task.wait(0.5)
						return
					end

					-- STEP 3: Initial Suitcase Loading (ONLY when starting fresh: curAtm == 0, curKoper == 0, and not currently delivering)
					local needsInitialLoading = (curAtm == 0) and (totKoper > 0 and curKoper < totKoper) and (bcaEventState ~= BCA_STATE.DELIVERING_TO_ATM)
					if needsInitialLoading then
						print(string.format("[BCA] Starting initial suitcase loading (%d/%d kopers).", curKoper, totKoper))
						setBcaState(BCA_STATE.LOADING_SUITCASES, "Initial suitcase load")
						loadKopersIntoCar(car)
						task.wait(0.5)
						return
					end

					-- STEP 4: Deliver to marked ATMs (suitcases loaded, step text says deliver, or in delivery state)
					local isKoperFull = (totKoper > 0 and curKoper >= totKoper)
					if (isKoperFull or curKoper > 0 or stepText:find("2)") or stepText:find("Antar")) and not isAtmDone then
						setBcaState(BCA_STATE.DELIVERING_TO_ATM, "Suitcases loaded, starting ATM delivery")
						deliverToAtms(car)
						task.wait(0.5)
						return
					end
				end)
				task.wait(bcaCourierDelay)
			end
		end)
	end

	-- Background myBCA App auto-sync
	task.spawn(function()
		while true do
			if bcaAppSyncActive or bcaCourierActive then
				pcall(function()
					fireRemote("MyBcaAppOpened")
				end)
			end
			task.wait(25)
		end
	end)

	------------------------------------------------
	-- 🎨 BUILD FARM TAB UI
	------------------------------------------------
	local farmFrame = UI.tabs["Farm"].Frame

	-- BCA Collaboration Event & Bank Courier
	local bcaSec = UI.AddSection(farmFrame, "BCA Collaboration Event & Bank Courier", 1)

	-- Real-Time Status & Live Stats Display
	bcaActivityLabel = UI.AddLabel(bcaSec, "Action: Idle (Toggle Auto Farm to start)", 1, UI.COLORS.accentCyan)
	bcaProgressLabel = UI.AddLabel(bcaSec, "Van Kopers: 0/0  |  ATMs Filled: 0/0", 2, UI.COLORS.textSecondary)
	bcaTargetLabel = UI.AddLabel(bcaSec, "Target: Standby / None", 3, UI.COLORS.textMuted)
	bcaSalaryLabel = UI.AddLabel(bcaSec, "Est. Salary: Rp 0  |  Pocket: Rp 0", 4, UI.COLORS.successGreen)
	bcaTargetEarningLabel = UI.AddLabel(bcaSec, "Target Earning: Disabled  |  Live Pocket: Rp 0", 5, UI.COLORS.accentViolet)

	-- Live Stats Auto-Updater Task
	task.spawn(function()
		while true do
			pcall(function()
				local jobGui = getBankCourierGui()
				local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
				local kText = hasActiveJobGui and jobGui.Status.Koper.Text or ""
				local aText = hasActiveJobGui and jobGui.Status.Atm.Text or ""
				local sText = hasActiveJobGui and jobGui.Status.Salary.Text or ""
				local pText = hasActiveJobGui and jobGui.Status:FindFirstChild("Pocket") and jobGui.Status.Pocket.Text or ""
				local curK, totK = parseProgress(kText)
				local curA, totA = parseProgress(aText)

				local livePocket = getPocketRupiahCash()
				if bcaTargetEarningLabel then
					if bcaTargetEarning > 0 then
						local targetCash = bcaTargetEarning * 1000000
						local pct = math.clamp(math.floor((livePocket / targetCash) * 100), 0, 100)
						bcaTargetEarningLabel.Text = string.format("Target: %s  |  Live Pocket: %s (%d%%)", formatRupiah(targetCash), formatRupiah(livePocket), pct)
					else
						bcaTargetEarningLabel.Text = string.format("Target: Disabled  |  Live Pocket: %s", formatRupiah(livePocket))
					end
				end

				-- Real-time auto-disconnect when target earning is reached (checked continuously!)
				if checkTargetEarningAndDisconnect() then
					return
				end

				if bcaCourierActive then
					if bcaActivityLabel then
						bcaActivityLabel.Text = "Action: " .. currentBcaActivity
					end

					if bcaProgressLabel then
						bcaProgressLabel.Text = string.format("Van Kopers: %d/%d  |  ATMs Filled: %d/%d", curK, totK, curA, totA)
					end

					if bcaTargetLabel then
						local targetPos = getBankCourierTargetPos()
						if targetPos and hasActiveJobGui then
							local char = player.Character
							local root = char and char:FindFirstChild("HumanoidRootPart")
							local dist = root and math.floor((root.Position - targetPos).Magnitude) or 0
							local matchedAtm = "Destination ATM"
							local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
							if atms then
								for atmName, spotPos in pairs(ATM_PARKING_SPOTS) do
									if (spotPos - targetPos).Magnitude < 250 then
										matchedAtm = atmName
										break
									end
								end
							end
							bcaTargetLabel.Text = string.format("Target: %s (%dm away)", matchedAtm, dist)
						else
							bcaTargetLabel.Text = hasActiveJobGui and "Target: Standby / Generating Route" or "Target: None (Starting Job...)"
						end
					end

					if bcaSalaryLabel and sText ~= "" then
						bcaSalaryLabel.Text = string.format("%s %s", sText, (pText ~= "" and (" | " .. pText) or ""))
					end
				else
					if bcaActivityLabel then
						bcaActivityLabel.Text = "Action: Idle (Toggle Auto Farm to start)"
					end
				end
			end)
			task.wait(0.5)
		end
	end)

	UI.AddToggle(bcaSec, "Auto Farm Bank Courier (ATMs & Briefcases)", Config.farm.bcaCourier, function(v)
		bcaCourierActive = v
		Config.farm.bcaCourier = v
		if v then
			UI.Notify("Auto-Farm ON", "BCA Courier Farm aktif.", 2.5, "success")
			runBcaCourierFarm()
		else
			updateBcaActivity("Paused (Toggle off)")
			UI.Notify("Auto-Farm OFF", "BCA Courier Farm dinonaktifkan.", 2, "info")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 6)

	UI.AddSlider(bcaSec, "Delivery Delay (Seconds)", 0.5, 5.0, bcaCourierDelay, function(v)
		bcaCourierDelay = v
		Config.farm.bcaCourierDelay = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 7, "s")

	UI.AddSlider(bcaSec, "Car Tween Height (studs)", 10, 80, Config.farm.bcaTweenHeight or 38, function(v)
		Config.farm.bcaTweenHeight = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 8, " studs")

	UI.AddSlider(bcaSec, "Arrive Distance (studs)", 15, 60, Config.farm.bcaArriveDist or 35, function(v)
		Config.farm.bcaArriveDist = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 9, " studs")

	local atmDropdownOptions = {
		"Auto (Active ATM)",
		"ATM 9 (BSD City - 5700 studs)",
		"ATM 7 (Tol Selatan - 13800 studs)",
		"ATM 8 (Ring Road - 15700 studs)",
		"ATM 3 (Plaza Barat - 1470 studs)",
		"ATM 10 (City South - 1400 studs)",
		"ATM 2 (BCA Office - 440 studs)",
		"ATM 4 (City Center - 420 studs)",
		"ATM 1 (Depot - 25 studs)"
	}

	local currentAtmLabel = "Auto (Active ATM)"
	for optName, optKey in pairs(ATM_OPTION_MAP) do
		if optKey == Config.farm.bcaTargetAtm then
			currentAtmLabel = optName
			break
		end
	end

	UI.AddDropdown(bcaSec, "Destination ATM (Far = 6M+)", atmDropdownOptions, currentAtmLabel, function(selectedOpt)
		local key = ATM_OPTION_MAP[selectedOpt] or "Auto"
		Config.farm.bcaTargetAtm = key
		UI.Notify("Destination ATM", selectedOpt, 2, "info")
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 10)

	UI.AddTextbox(bcaSec, "Target Earning (Million IDR)", tostring(bcaTargetEarning or 0), function(val)
		local num = tonumber(val) or 0
		bcaTargetEarning = num
		Config.farm.bcaTargetEarning = num
		if num > 0 then
			local fullIdr = num * 1000000
			UI.Notify("Target Earning", string.format("Target: %s", formatRupiah(fullIdr)), 2.5, "success")
			checkTargetEarningAndDisconnect()
		else
			UI.Notify("Target Earning", "Target dinonaktifkan.", 2, "info")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 11)

	UI.AddLabel(bcaSec, "Type in millions: 1 = Rp 1.000.000, 10 = Rp 10.000.000, 68 = Rp 68.000.000 (0 = No limit)", 12, UI.COLORS.textMuted)

	UI.AddToggle(bcaSec, "Anti Staff / Auto Disconnect on Player Join", Config.farm.antiStaff or false, function(v)
		antiStaffActive = v
		Config.farm.antiStaff = v
		if v then
			UI.Notify("Proteksi Server", "Proteksi server aktif.", 2.5, "info")
			for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
				if otherPlayer ~= player then
					pcall(function()
						game:GetService("Players").LocalPlayer:Kick("Anti Staff Detected.")
					end)
					break
				end
			end
		else
			UI.Notify("Proteksi Server", "Proteksi server dinonaktifkan.", 2, "info")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 13)

	UI.AddToggle(bcaSec, "Auto Sync myBCA App (Pocket Rupiah)", Config.farm.bcaAppSync or true, function(v)
		bcaAppSyncActive = v
		Config.farm.bcaAppSync = v
		if v then
			fireRemote("MyBcaAppOpened")
			UI.Notify("myBCA", "Sinkronisasi saldo berhasil.", 2, "success")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 14)

	UI.AddButton(bcaSec, "Spawn BCA Bank Armored Van", function()
		pcall(function()
			local remotes = ReplicatedStorage:FindFirstChild("NetworkContainer")
			if remotes and remotes:FindFirstChild("RemoteFunctions") and remotes.RemoteFunctions:FindFirstChild("Spawner") then
				remotes.RemoteFunctions.Spawner:InvokeServer("Spawn", "2025SemeruLarasBankCar")
				UI.Notify("Kendaraan", "Mobil operasional berhasil dipanggil.", 2.5, "success")
			else
				UI.Notify("Kendaraan", "Gagal memanggil kendaraan.", 2, "warning")
			end
		end)
	end, 15)

	UI.AddButton(bcaSec, "Claim / Exchange BCA Event Rewards", function()
		pcall(function()
			local collab = workspace:FindFirstChild("MY_BCA_COLLAB")
			local exchangeNpc = collab and collab:FindFirstChild("NPC_EXCHANGE_REWARD")
			if exchangeNpc then
				local root = exchangeNpc:FindFirstChild("HumanoidRootPart") or exchangeNpc:FindFirstChildOfClass("BasePart")
				if root then
					safeTeleport(root.CFrame + Vector3.new(0, 3, 3))
				end
				for _, prompt in ipairs(exchangeNpc:GetDescendants()) do
					if prompt:IsA("ProximityPrompt") then
						prompt.HoldDuration = 0
						if fireproximityprompt then fireproximityprompt(prompt) end
					end
				end
				UI.Notify("Teleport", "Tiba di Exchange Booth.", 2, "success")
			else
				safeTeleport(CFrame.new(bcaDepotPos))
				UI.Notify("Teleport", "Tiba di BCA Depot.", 2, "success")
			end
		end)
	end, 16)

	------------------------------------------------
	-- ☕ BARISTA (KANJI JAWA) AUTO FARM CONTROLLER
	------------------------------------------------
	local BARISTA_STATE = {
		IDLE = "Idle",
		STARTING_JOB = "StartingJob",
		TAKING_ORDER = "TakingOrder",
		BREWING = "Brewing",
		SERVING = "Serving",
		COMPLETED = "Completed"
	}

	local baristaState = BARISTA_STATE.IDLE
	local baristaActive = Config.farm.janjiJiwa or false
	local baristaDelay = Config.farm.janjiJiwaDelay or 0.8
	local baristaNoMinigame = Config.farm.baristaNoMinigame ~= false
	local baristaInstantServe = Config.farm.baristaInstantServe ~= false
	local baristaNoclip = Config.farm.baristaNoclip ~= false
	local baristaOrdersCompleted = 0
	local baristaActivity = "Idle"
	local baristaTutorialAnswered = false

	local baristaActivityLabel = nil
	local baristaStatsLabel = nil

	-- Cafe Kanji Jawa Coordinates (Safe Ground Altitude Y = 25.0)
	local KANJI_JAWA_COUNTER        = Vector3.new(-35.98, 25.0, 8419.95)
	local KANJI_JAWA_COUNTER_INSIDE = Vector3.new(-34.68, 25.0, 8422.75)
	local KANJI_JAWA_COUNTER_FRONT  = Vector3.new(-36.20, 25.0, 8419.50)
	local KANJI_JAWA_MANAGER        = Vector3.new(-13.5, 25.0, 8450.0)
	local KANJI_JAWA_PHONE          = Vector3.new(-7.87, 25.0, 8425.5)

	local BARISTA_STATIONS = {
		CupRack         = Vector3.new(-11.64, 25.0, 8409.11),
		IceMaker        = Vector3.new(-5.73, 25.0, 8415.39),
		BeanHopper      = Vector3.new(-27.46, 25.0, 8416.72),
		Brewer          = Vector3.new(-25.40, 25.0, 8415.33),
		Steamer         = Vector3.new(-23.85, 25.0, 8413.78),
		Milk            = Vector3.new(-13.96, 25.0, 8427.20),
		FlavourBottle   = Vector3.new(-25.90, 25.0, 8441.20),
		LemonBoard      = Vector3.new(-28.25, 25.0, 8443.58),
		Carbonator      = Vector3.new(-36.30, 25.0, 8441.02),
		WaterTap        = Vector3.new(-41.09, 25.0, 8436.42),
		CreamDispenser  = Vector3.new(-34.14, 25.0, 8443.18),
		ChocolateJar    = Vector3.new(-20.89, 25.0, 8436.18),
		MatchaJar       = Vector3.new(-18.60, 25.0, 8433.67),
		BobaPot         = Vector3.new(-23.34, 25.0, 8438.54),
		TeaBox          = Vector3.new(-16.11, 25.0, 8431.05),
		Trash           = Vector3.new(-9.76, 25.0, 8426.67),
		Counter         = Vector3.new(-35.98, 25.0, 8419.95)
	}

	-- Precise player standing positions and look-at targets for counter & machines (Safe Ground Altitude Y = 25.0)
	local BARISTA_STATION_POSITIONS = {
		CupRack         = { stand = Vector3.new(-11.65, 25.0, 8411.0), look = Vector3.new(-11.65, 25.0, 8409.11) },
		IceMaker        = { stand = Vector3.new(-7.30, 25.0, 8415.39),  look = Vector3.new(-5.73, 25.0, 8415.39) },
		BeanHopper      = { stand = Vector3.new(-27.47, 25.0, 8418.3), look = Vector3.new(-27.47, 25.0, 8416.71) },
		Brewer          = { stand = Vector3.new(-25.41, 25.0, 8416.9), look = Vector3.new(-25.41, 25.0, 8415.32) },
		Steamer         = { stand = Vector3.new(-23.86, 25.0, 8415.3), look = Vector3.new(-23.86, 25.0, 8413.77) },
		Milk            = { stand = Vector3.new(-15.40, 25.0, 8427.19), look = Vector3.new(-13.96, 25.0, 8427.19) },
		FlavourBottle   = { stand = Vector3.new(-25.91, 25.0, 8439.6), look = Vector3.new(-25.91, 25.0, 8441.20) },
		LemonBoard      = { stand = Vector3.new(-28.25, 25.0, 8442.0), look = Vector3.new(-28.25, 25.0, 8443.57) },
		Carbonator      = { stand = Vector3.new(-36.30, 25.0, 8439.5), look = Vector3.new(-36.30, 25.0, 8441.02) },
		WaterTap        = { stand = Vector3.new(-39.50, 25.0, 8436.41), look = Vector3.new(-41.09, 25.0, 8436.41) },
		CreamDispenser  = { stand = Vector3.new(-34.14, 25.0, 8441.6), look = Vector3.new(-34.14, 25.0, 8443.18) },
		ChocolateJar    = { stand = Vector3.new(-20.89, 25.0, 8434.6), look = Vector3.new(-20.89, 25.0, 8436.17) },
		MatchaJar       = { stand = Vector3.new(-18.61, 25.0, 8432.1), look = Vector3.new(-18.61, 25.0, 8433.67) },
		BobaPot         = { stand = Vector3.new(-23.35, 25.0, 8437.0), look = Vector3.new(-23.35, 25.0, 8438.54) },
		TeaBox          = { stand = Vector3.new(-16.11, 25.0, 8429.5), look = Vector3.new(-16.11, 25.0, 8431.04) },
		Trash           = { stand = Vector3.new(-11.30, 25.0, 8426.67), look = Vector3.new(-9.76, 25.0, 8426.67) },
		CounterInside   = { stand = Vector3.new(-34.68, 25.0, 8422.75), look = Vector3.new(-36.20, 25.0, 8419.50) },
		Manager         = { stand = Vector3.new(-13.50, 25.0, 8450.0), look = Vector3.new(-13.50, 25.0, 8451.7) },
		Phone           = { stand = Vector3.new(-7.87, 25.0, 8425.5),  look = Vector3.new(-7.87, 25.0, 8427.23) }
	}

	-- Map Step Name to Station Name
	local STEP_TO_STATION = {
		Cup             = "CupRack",
		Beans           = "BeanHopper",
		LoadBeans       = "Brewer",
		Brew            = "Brewer",
		Pour            = "Brewer",
		Milk            = "Milk",
		Foam            = "Steamer",
		Flavour         = "FlavourBottle",
		Ice             = "IceMaker",
		Water           = "WaterTap",
		TeaBag          = "TeaBox",
		Boba            = "BobaPot",
		MatchaPowder    = "MatchaJar",
		ChocolatePowder = "ChocolateJar",
		Carbonate       = "Carbonator",
		LemonSlice      = "LemonBoard",
		Cream           = "CreamDispenser"
	}

	-- Full Official CDID Barista Recipes
	local BARISTA_RECIPES = {
		Latte = {
			pay = 5600000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour", "Milk" }
		},
		BubbleTea = {
			pay = 12000000,
			steps = { "Cup", "Water", "TeaBag", "Milk", "Boba", "Ice" }
		},
		Matcha = {
			pay = 9600000,
			steps = { "Cup", "Water", "MatchaPowder", "Milk" }
		},
		Lemonade = {
			pay = 11200000,
			steps = { "Cup", "Water", "Carbonate", "LemonSlice", "Ice" }
		},
		Soda = {
			pay = 7200000,
			steps = { "Cup", "Water", "Carbonate", "Ice" }
		},
		ThaiTea = {
			pay = 8000000,
			steps = { "Cup", "Water", "TeaBag", "Milk", "Ice" }
		},
		Frappuccino = {
			pay = 10400000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour", "Milk", "Cream", "Ice" }
		},
		Tea = {
			pay = 3600000,
			steps = { "Cup", "Water", "TeaBag" }
		},
		Macchiato = {
			pay = 6000000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour", "Foam" }
		},
		EsKopiSusu = {
			pay = 8000000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour", "Milk", "Flavour", "Ice" }
		},
		HotChocolate = {
			pay = 4000000,
			steps = { "Cup", "Milk", "ChocolatePowder" }
		},
		KopiHitam = {
			pay = 4800000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour" }
		},
		Americano = {
			pay = 5200000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour", "Water" }
		},
		Cappuccino = {
			pay = 7200000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour", "Milk", "Flavour", "Foam" }
		},
		Mocha = {
			pay = 8800000,
			steps = { "Cup", "Beans", "LoadBeans", "Brew", "Pour", "Milk", "ChocolatePowder" }
		}
	}

	-- Indonesian display name aliases to Internal recipe IDs
	local RECIPE_NAME_ALIASES = {
		["kopi hitam"]      = "KopiHitam",
		["black coffee"]    = "KopiHitam",
		["es kopi susu"]    = "EsKopiSusu",
		["iced milk coffee"]= "EsKopiSusu",
		["cappuccino"]      = "Cappuccino",
		["latte"]           = "Latte",
		["americano"]       = "Americano",
		["mocha"]           = "Mocha",
		["macchiato"]       = "Macchiato",
		["frappuccino"]     = "Frappuccino",
		["bubble tea"]      = "BubbleTea",
		["boba"]            = "BubbleTea",
		["matcha"]          = "Matcha",
		["lemonade"]        = "Lemonade",
		["soda"]            = "Soda",
		["thai tea"]        = "ThaiTea",
		["teh"]             = "Tea",
		["tea"]             = "Tea",
		["cokelat panas"]   = "HotChocolate",
		["hot chocolate"]   = "HotChocolate"
	}

	local function getLiveHubCash()
		local pGui = player:FindFirstChild("PlayerGui")
		local cashLabel = pGui and pGui:FindFirstChild("Main") and pGui.Main:FindFirstChild("Container") and pGui.Main.Container:FindFirstChild("Hub") and pGui.Main.Container.Hub:FindFirstChild("CashFrame") and pGui.Main.Container.Hub.CashFrame:FindFirstChild("Frame") and pGui.Main.Container.Hub.CashFrame.Frame:FindFirstChild("TextLabel")
		if cashLabel and cashLabel.Text ~= "" then
			return cashLabel.Text
		end
		return formatRupiah(getPocketRupiahCash())
	end

	local function updateBaristaActivity(act)
		baristaActivity = act or "Idle"
		if baristaActivityLabel then
			pcall(function()
				baristaActivityLabel.Text = "☕ Action: " .. baristaActivity
			end)
		end
	end

	local function updateBaristaStats()
		if baristaStatsLabel then
			pcall(function()
				local liveCash = getLiveHubCash()
				baristaStatsLabel.Text = string.format("Orders Served: %d  |  Cash: %s", baristaOrdersCompleted, liveCash)
			end)
		end
	end

	-- Super Instant & Reliable Proximity Prompt Trigger (Handles Engine Hold Timing)
	local function triggerInstantPrompt(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then return end
		pcall(function()
			prompt.Enabled = true
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance or 10, 45)
			local holdTime = tonumber(prompt.HoldDuration) or 0.35
			if fireproximityprompt then
				fireproximityprompt(prompt, holdTime)
			end
			if prompt.InputHoldBegin then
				prompt:InputHoldBegin()
				task.wait(math.max(holdTime + 0.05, 0.08))
				prompt:InputHoldEnd()
			end
		end)
	end

	-- Spawns a permanent collision safety floor underneath Cafe Kanji Jawa so player never falls through map
	local function ensureCafeSafetyFloor()
		local plate = workspace:FindFirstChild("__CafeFloorSafetyPlate")
		if not plate then
			plate = Instance.new("Part")
			plate.Name = "__CafeFloorSafetyPlate"
			plate.Anchored = true
			plate.CanCollide = true
			plate.Transparency = 1
			plate.CastShadow = false
			plate.Material = Enum.Material.SmoothPlastic
			plate.Size = Vector3.new(250, 2, 250)
			plate.Position = Vector3.new(-25, 18.5, 8430)
			pcall(function() plate.Parent = workspace end)
		else
			plate.Position = Vector3.new(-25, 18.5, 8430)
			plate.Size = Vector3.new(250, 2, 250)
			plate.CanCollide = true
		end
		return plate
	end

	-- Move Character with Exact Orientation & Solid Anti-Fall Floor
	local function baristaMoveTo(targetPos, facePos)
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root or not targetPos then return end

		ensureCafeSafetyFloor()

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		-- Elevate slightly (+1.2 studs) so physics engine drops character onto ground cleanly without clipping into mesh
		local safeTargetPos = Vector3.new(targetPos.X, math.max(targetPos.Y, 25.5) + 1.2, targetPos.Z)

		if facePos then
			local safeFacePos = Vector3.new(facePos.X, math.max(facePos.Y, 25.5), facePos.Z)
			root.CFrame = CFrame.lookAt(safeTargetPos, safeFacePos)
			pcall(function()
				workspace.CurrentCamera.CFrame = CFrame.lookAt(safeTargetPos + Vector3.new(0, 2, 0), safeFacePos + Vector3.new(0, 1.5, 0))
			end)
		else
			root.CFrame = CFrame.new(safeTargetPos)
		end
		root.AssemblyLinearVelocity = Vector3.zero
	end

	-- Check if Barista Job is Active
	local function isBaristaJobGuiOpen()
		local pGui = player:FindFirstChild("PlayerGui")
		local pJob = pGui and pGui:FindFirstChild("Job")
		local bGui = pJob and pJob:FindFirstChild("Barista")
		return bGui and bGui.Visible == true
	end

	-- Hook BrewMinigame module for 100% instant extraction without manual minigame
	local function hookBaristaBrewMinigame()
		pcall(function()
			local pGui = player:FindFirstChild("PlayerGui")
			local bModule = pGui and pGui:FindFirstChild("Job") and pGui.Job:FindFirstChild("Barista") and pGui.Job.Barista:FindFirstChild("BrewMinigame")
			if bModule and not _G.HipHubBaristaBrewHooked then
				local BrewMinigame = require(bModule)
				local oldStart = BrewMinigame.start
				BrewMinigame.start = function(self, duration, onFinished)
					if Config.farm.baristaNoMinigame ~= false then
						self.inZoneSeconds = duration or 5
						self.fillSeconds = duration or 5
						self.isRunning = true
						task.defer(function()
							if onFinished then
								onFinished(1.0)
							end
							pcall(function() self:stop() end)
							pcall(function()
								local PlayerScripts = player:WaitForChild("PlayerScripts")
								local controls = require(PlayerScripts:WaitForChild("PlayerModule")):GetControls()
								controls:Enable()
							end)
						end)
						return
					end
					return oldStart(self, duration, onFinished)
				end
				_G.HipHubBaristaBrewHooked = true
			end
		end)
	end

	-- Hook ChoicePicker module for instant auto-selection matching customer's exact order
	local function hookBaristaChoicePicker()
		pcall(function()
			local pGui = player:FindFirstChild("PlayerGui")
			local cpModule = pGui and pGui:FindFirstChild("Job") and pGui.Job:FindFirstChild("Barista") and pGui.Job.Barista:FindFirstChild("ChoicePicker")
			if cpModule and not _G.HipHubChoicePickerHooked then
				local ChoicePicker = require(cpModule)
				local oldOpen = ChoicePicker.open
				ChoicePicker.open = function(self, title, items, onPick)
					if Config.farm.janjiJiwa or _G.HipHubAutoPickChoice then
						local targetValue = _G.HipHubTargetMenu or _G.HipHubTargetFlavour
						local selected = nil
						if targetValue and items then
							for _, itm in ipairs(items) do
								local cleanVal = tostring(itm.value):gsub("%s+", ""):lower()
								local cleanTarget = tostring(targetValue):gsub("%s+", ""):lower()
								local cleanText = itm.text and tostring(itm.text):gsub("%s+", ""):lower() or ""
								if cleanVal == cleanTarget or cleanText == cleanTarget or cleanText:find(cleanTarget, 1, true) then
									selected = itm.value
									break
								end
							end
						end
						if not selected and items and #items > 0 then
							selected = items[1].value
						end
						task.defer(function()
							if onPick then
								onPick(selected)
							end
							pcall(function() self:close() end)
						end)
						return
					end
					return oldOpen(self, title, items, onPick)
				end
				_G.HipHubChoicePickerHooked = true
			end
		end)
	end

	-- Single Station Interaction Helper (Clean Single Remote Trigger, Prevents Duplicate Action)
	local function triggerStationInteraction(stationName)
		local info = BARISTA_STATION_POSITIONS[stationName]
		if info then
			baristaMoveTo(info.stand, info.look)
		else
			local pos = BARISTA_STATIONS[stationName] or KANJI_JAWA_COUNTER_INSIDE
			baristaMoveTo(pos)
		end
		task.wait(0.12)

		-- Auto-dismiss ChoicePicker if open
		pcall(function()
			local pGui = player:FindFirstChild("PlayerGui")
			local choicePicker = pGui and pGui:FindFirstChild("Job") and pGui.Job:FindFirstChild("ChoicePicker")
			if choicePicker and choicePicker.Visible then
				choicePicker.Visible = false
			end
		end)

		fireRemote("Barista", "Station", stationName)
	end

	-- Find the front customer standing directly at counter
	local function findFrontCustomerAtCounter()
		local custFolder = workspace:FindFirstChild("BaristaCustomers")
		if not custFolder then return nil end

		local frontCust = nil
		local closestDist = 999

		for _, cust in ipairs(custFolder:GetChildren()) do
			local hrp = cust:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - KANJI_JAWA_COUNTER_FRONT).Magnitude
				if dist < closestDist then
					closestDist = dist
					frontCust = cust
				end
			end
		end

		if frontCust and closestDist < 7.0 then
			return frontCust
		end
		return nil
	end

	-- Main Barista Autofarm Execution Loop
	local function runBaristaFarm()
		task.spawn(function()
			local currentCupState = nil
			local activeOrder = nil
			local targetFlavour = nil
			local isBrewing = false

			-- Ensure permanent cafe safety floor is active
			ensureCafeSafetyFloor()

			-- Apply Brew Minigame and ChoicePicker hooks immediately
			hookBaristaBrewMinigame()
			hookBaristaChoicePicker()

			-- Hook RemoteEvents.Barista for Real-Time Event Sync
			local baristaRemote = nil
			pcall(function()
				baristaRemote = game:GetService("ReplicatedStorage"):WaitForChild("NetworkContainer", 5):WaitForChild("RemoteEvents", 5):WaitForChild("Barista", 5)
			end)

			local eventConn = nil
			if baristaRemote then
				eventConn = baristaRemote.OnClientEvent:Connect(function(action, p1, p2, p3)
					if action == "OrderTaken" then
						activeOrder = { slot = p1, menuId = p2, flavour = p3 }
						targetFlavour = p3
						_G.HipHubTargetMenu = p2
						_G.HipHubTargetFlavour = p3
					elseif action == "CupState" then
						currentCupState = p1
					elseif action == "BrewStart" then
						isBrewing = true
						task.spawn(function()
							if baristaNoMinigame then
								task.wait(0.15)
								fireRemote("Barista", "BrewResult", 1.0)
								task.wait(0.15)
								isBrewing = false
							end
						end)
					elseif action == "PickPrompt" then
						task.wait(0.06)
						if p1 == "Menu" then
							local chosenMenu = (activeOrder and activeOrder.menuId) or _G.HipHubTargetMenu or (p2 and p2[1]) or "EsKopiSusu"
							fireRemote("Barista", "Pick", "Menu", chosenMenu)
						elseif p1 == "Flavour" then
							local chosenFlavour = targetFlavour or _G.HipHubTargetFlavour or (p2 and p2[1]) or "Vanilla"
							fireRemote("Barista", "Pick", "Flavour", chosenFlavour)
						else
							local val = (p2 and p2[1]) or "Vanilla"
							fireRemote("Barista", "Pick", p1, val)
						end
					elseif action == "OrderDone" then
						activeOrder = nil
						currentCupState = nil
					end
				end)
			end

			while baristaActive do
				pcall(function()
					local char = player.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if not root then
						task.wait(1)
						return
					end

					if checkTargetEarningAndDisconnect() then return end

					ensureCafeSafetyFloor()

					-- Ensure BrewMinigame and ChoicePicker are hooked
					hookBaristaBrewMinigame()
					hookBaristaChoicePicker()

					-- STEP 1: Verify player is near Cafe Kanji Jawa
					local distToCafe = (root.Position - KANJI_JAWA_COUNTER).Magnitude
					if distToCafe > 300 then
						updateBaristaActivity("🚀 Teleporting to Kanji Jawa Cafe...")
						safeTeleport(CFrame.new(KANJI_JAWA_COUNTER_INSIDE), false)
						task.wait(0.8)
						return
					end

					-- Ensure Barista Job is Active
					if not isBaristaJobGuiOpen() then
						baristaState = BARISTA_STATE.STARTING_JOB
						updateBaristaActivity("👔 Talking to Mbak Surti to Start Job...")
						local mgrInfo = BARISTA_STATION_POSITIONS.Manager
						baristaMoveTo(mgrInfo.stand, mgrInfo.look)
						task.wait(0.2)

						local mgrPrompt = workspace:FindFirstChild("Barista") and workspace.Barista:FindFirstChild("NPC_BARISTA_MANAGER") and workspace.Barista.NPC_BARISTA_MANAGER:FindFirstChild("Head") and workspace.Barista.NPC_BARISTA_MANAGER.Head:FindFirstChild("DialogPrompt")
						if mgrPrompt then
							triggerInstantPrompt(mgrPrompt)
						end

						fireRemote("Job", "Barista")
						task.wait(0.8)
					end

					-- Answer Phone ONCE if tutorial ringing
					if not baristaTutorialAnswered then
						local phoneObj = workspace:FindFirstChild("NEW_JOB") and workspace.NEW_JOB:FindFirstChild("Cafe") and workspace.NEW_JOB.Cafe:FindFirstChild("Cafe_Kanji_Jawa") and workspace.NEW_JOB.Cafe.Cafe_Kanji_Jawa:FindFirstChild("Telphone") and workspace.NEW_JOB.Cafe.Cafe_Kanji_Jawa.Telphone:FindFirstChild("Telephone")
						local phonePrompt = phoneObj and phoneObj:FindFirstChild("BaristaPhonePrompt")
						if phonePrompt and phonePrompt.Enabled then
							local phoneInfo = BARISTA_STATION_POSITIONS.Phone
							baristaMoveTo(phoneInfo.stand, phoneInfo.look)
							task.wait(0.15)
							triggerInstantPrompt(phonePrompt)
							fireRemote("Barista", "TutorialDone")
							baristaTutorialAnswered = true
							task.wait(0.3)
						else
							baristaTutorialAnswered = true
						end
					end

					-- ============================================================
					-- 1. STAND BEHIND CASHIER & WAIT FOR CUSTOMER
					-- ============================================================
					baristaState = BARISTA_STATE.TAKING_ORDER
					baristaMoveTo(KANJI_JAWA_COUNTER_INSIDE, KANJI_JAWA_COUNTER_FRONT)

					local frontCustomer = findFrontCustomerAtCounter()
					local waitCustomerCounter = 0

					while not frontCustomer and baristaActive do
						waitCustomerCounter = waitCustomerCounter + 1
						updateBaristaActivity(string.format("⏳ Menunggu pelanggan tiba di kasir (%ds)...", waitCustomerCounter))
						task.wait(0.5)
						frontCustomer = findFrontCustomerAtCounter()
					end

					if not baristaActive then return end

					-- Tanya Pesanan ke Pelanggan Terdepan
					updateBaristaActivity("📋 Tanya Pesanan Pelanggan di Kasir...")
					baristaMoveTo(KANJI_JAWA_COUNTER_INSIDE, KANJI_JAWA_COUNTER_FRONT)
					task.wait(0.15)

					local customerSlot = 1
					if frontCustomer then
						local p = frontCustomer:FindFirstChildWhichIsA("ProximityPrompt", true)
						if p then
							local num = tonumber(p.ObjectText:match("%d+"))
							if num then customerSlot = num end
							if p.Enabled and (p.ActionText:lower():find("tanya") or p.ActionText:lower():find("ambil")) then
								triggerInstantPrompt(p)
							end
						end
					end

					-- Clear previous order cache before taking new order
					activeOrder = nil
					_G.HipHubTargetMenu = nil
					_G.HipHubTargetFlavour = nil

					-- Fire TakeOrder for that slot
					fireRemote("Barista", "TakeOrder", customerSlot)

					-- Wait for server OrderTaken event to populate target menu
					local tOrderWait = os.clock()
					while not activeOrder and (os.clock() - tOrderWait < 2.0) and baristaActive do
						task.wait(0.08)
					end

					if not activeOrder then
						activeOrder = { slot = customerSlot, menuId = _G.HipHubTargetMenu or "EsKopiSusu", flavour = _G.HipHubTargetFlavour }
						_G.HipHubTargetMenu = activeOrder.menuId
					end

					updateBaristaActivity(string.format("📋 Pesanan: %s (Pelanggan #%s)", tostring(activeOrder.menuId), tostring(activeOrder.slot)))
					task.wait(0.2)

					-- ============================================================
					-- 2. AMBIL GELAS DI CUP RACK SESUAI ORDERAN PELANGGAN
					-- ============================================================
					updateBaristaActivity(string.format("🥤 Mengambil Gelas [%s] di Rak Gelas...", tostring(activeOrder.menuId)))
					local cupInfo = BARISTA_STATION_POSITIONS.CupRack
					baristaMoveTo(cupInfo.stand, cupInfo.look)
					task.wait(0.12)
					fireRemote("Barista", "Station", "CupRack")
					if _G.HipHubTargetMenu then
						fireRemote("Barista", "Pick", "Menu", _G.HipHubTargetMenu)
					end

					local tCupWait = os.clock()
					while (not currentCupState or currentCupState.ruined) and (os.clock() - tCupWait < 1.8) and baristaActive do
						task.wait(0.1)
					end

					-- ============================================================
					-- 3. KERJAIN PESANAN SESUAI RESEP (DYNAMIC STEP EXECUTION)
					-- ============================================================
					baristaState = BARISTA_STATE.BREWING
					local loopSafety = 30

					while loopSafety > 0 and baristaActive do
						loopSafety = loopSafety - 1

						if isBrewing then
							updateBaristaActivity("☕ Brewing Espresso Extraction (100% Instant)...")
							task.wait(0.2)
						elseif not currentCupState then
							-- Ambil gelas jika belum ada gelas
							updateBaristaActivity(string.format("🥤 Ambil Gelas [%s] di CupRack...", tostring(activeOrder and activeOrder.menuId or "Drink")))
							local cInfo = BARISTA_STATION_POSITIONS.CupRack
							baristaMoveTo(cInfo.stand, cInfo.look)
							task.wait(0.12)
							fireRemote("Barista", "Station", "CupRack")
							if _G.HipHubTargetMenu then
								fireRemote("Barista", "Pick", "Menu", _G.HipHubTargetMenu)
							end
							task.wait(0.35)
						elseif currentCupState.ruined then
							-- Buang gelas rusak ke tempat sampah & ambil baru
							updateBaristaActivity("🗑️ Gelas Rusak -> Buang ke Tong Sampah...")
							local trInfo = BARISTA_STATION_POSITIONS.Trash
							baristaMoveTo(trInfo.stand, trInfo.look)
							task.wait(0.15)
							fireRemote("Barista", "Station", "Trash")
							task.wait(0.3)
							currentCupState = nil
						elseif currentCupState.nextStep == nil then
							-- Minuman selesai diracik!
							updateBaristaActivity("✨ Minuman Siap Diantar!")
							break
						else
							-- Kerjakan stasiun berikutnya sesuai petunjuk server
							local nextStation = currentCupState.nextStation or "CupRack"
							local nextStep = currentCupState.nextStep or "Cup"
							local menuName = currentCupState.menuId or (activeOrder and activeOrder.menuId) or "Drink"
							updateBaristaActivity(string.format("☕ [%s] %s di %s...", menuName, nextStep, nextStation))

							if nextStep == "Brew" then
								local brewInfo = BARISTA_STATION_POSITIONS.Brewer
								baristaMoveTo(brewInfo.stand, brewInfo.look)
								task.wait(0.12)
								fireRemote("Barista", "Station", "Brewer")
								task.wait(0.1)
								if baristaNoMinigame then
									fireRemote("Barista", "BrewResult", 1.0)
								end
								local brewWait = 10
								while brewWait > 0 and baristaActive and (isBrewing or (currentCupState and currentCupState.nextStep == "Brew")) do
									brewWait = brewWait - 1
									if baristaNoMinigame then
										fireRemote("Barista", "BrewResult", 1.0)
									end
									task.wait(0.2)
								end
							elseif nextStep == "Flavour" then
								local flvInfo = BARISTA_STATION_POSITIONS.FlavourBottle
								baristaMoveTo(flvInfo.stand, flvInfo.look)
								task.wait(0.12)
								fireRemote("Barista", "Station", "FlavourBottle")
								task.wait(0.1)
								local flv = targetFlavour or _G.HipHubTargetFlavour or "Vanilla"
								fireRemote("Barista", "Pick", "Flavour", flv)
								task.wait(0.3)
							else
								local info = BARISTA_STATION_POSITIONS[nextStation]
								if info then
									baristaMoveTo(info.stand, info.look)
								else
									local pos = BARISTA_STATIONS[nextStation] or KANJI_JAWA_COUNTER_INSIDE
									baristaMoveTo(pos)
								end
								task.wait(0.12)
								fireRemote("Barista", "Station", nextStation)
								task.wait(0.35)
							end
						end
					end

					-- ============================================================
					-- 4. ANTAR KE PELANGGAN DEPAN (BEHIND COUNTER ONLY)
					-- ============================================================
					baristaState = BARISTA_STATE.SERVING
					updateBaristaActivity("🍽️ Antar Pesanan ke Pelanggan di Kasir...")
					baristaMoveTo(KANJI_JAWA_COUNTER_INSIDE, KANJI_JAWA_COUNTER_FRONT)
					task.wait(0.25)

					local targetServeCust = findFrontCustomerAtCounter() or frontCustomer
					if targetServeCust then
						local p = targetServeCust:FindFirstChildWhichIsA("ProximityPrompt", true)
						if p and p.Enabled then
							triggerInstantPrompt(p)
						end
					end

					if activeOrder and activeOrder.slot then
						fireRemote("Barista", "Serve", activeOrder.slot)
					else
						for slot = 1, 4 do
							fireRemote("Barista", "Serve", slot)
						end
					end

					task.wait(0.5)

					-- Selesai 1 siklus & update live stats
					baristaOrdersCompleted = baristaOrdersCompleted + 1
					baristaState = BARISTA_STATE.COMPLETED
					updateBaristaActivity("✅ Pesanan Terkirim! +Gajian Berhasil")
					updateBaristaStats()

					task.wait(baristaDelay)
				end)
				task.wait(0.2)
			end

			if eventConn then
				eventConn:Disconnect()
			end
		end)
	end

	------------------------------------------------
	-- 🎨 BUILD BARISTA FARM TAB UI
	------------------------------------------------
	local baristaSec = UI.AddSection(farmFrame, "Janji Jawa Cafe & Barista Autofarm", 2)

	baristaActivityLabel = UI.AddLabel(baristaSec, "Action: Idle (Toggle Barista to start)", 1, UI.COLORS.accentCyan)
	baristaStatsLabel = UI.AddLabel(baristaSec, "Orders Served: 0  |  Cash: Rp 0", 2, UI.COLORS.successGreen)

	-- Barista Auto-Stats Background Updater
	task.spawn(function()
		while true do
			pcall(function()
				if baristaActive then
					updateBaristaStats()
				end
			end)
			task.wait(1.0)
		end
	end)

	UI.AddToggle(baristaSec, "Auto Farm Barista (Take Menu, Brew, Serve)", Config.farm.janjiJiwa or false, function(v)
		baristaActive = v
		Config.farm.janjiJiwa = v
		if v then
			UI.Notify("Barista Farm ON", "Janji Jawa Barista Farm aktif.", 2.5, "success")
			runBaristaFarm()
		else
			updateBaristaActivity("Paused (Toggle off)")
			UI.Notify("Barista Farm OFF", "Janji Jawa Barista Farm dinonaktifkan.", 2, "info")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 3)

	UI.AddSlider(baristaSec, "Barista Cycle Delay", 0.2, 3.0, baristaDelay, function(v)
		baristaDelay = v
		Config.farm.janjiJiwaDelay = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 4, "s")

	UI.AddToggle(baristaSec, "No Minigame on Brew (Instant Complete)", baristaNoMinigame, function(v)
		baristaNoMinigame = v
		Config.farm.baristaNoMinigame = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 5)

	UI.AddToggle(baristaSec, "Instant Serve Order (Auto Deliver to Table)", baristaInstantServe, function(v)
		baristaInstantServe = v
		Config.farm.baristaInstantServe = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 6)

	UI.AddToggle(baristaSec, "Character Noclip (Phase through Cafe Counters)", baristaNoclip, function(v)
		baristaNoclip = v
		Config.farm.baristaNoclip = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 7)

	UI.AddButton(baristaSec, "Teleport to Janji Jawa Cafe", function()
		pcall(function()
			safeTeleport(CFrame.new(KANJI_JAWA_COUNTER + Vector3.new(0, 1.5, 0)), false)
			UI.Notify("Teleport", "Tiba di Janji Jawa Cafe.", 2, "success")
		end)
	end, 8)

	-- Launch Barista thread immediately if saved in config
	if baristaActive then
		runBaristaFarm()
	end

	-- Launch BCA Courier thread immediately if enabled in saved config
	if bcaCourierActive then
		runBcaCourierFarm()
	end

	-- Export Farm API
	_G.HipHubFarm = {
		SetBcaCourier = function(v) bcaCourierActive = v end,
		SetBarista = function(v) 
			baristaActive = v 
			if v then runBaristaFarm() end
		end,
	}
end)

if not success then
	warn("[HipHub CDID Farm Error]:", err)
end



