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
	local bcaCourierActive = Config.farm.bcaCourier or false
	local bcaCourierDelay = Config.farm.bcaCourierDelay or 1.0
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

		if useTween then
			speed = speed or 120
			local dist = (root.Position - cframe.Position).Magnitude
			local time = math.clamp(dist / speed, 0.1, 8.0)
			local tw = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = cframe })
			tw:Play()
			tw.Completed:Wait()
		else
			root.CFrame = cframe
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		if cframe.Position.Y > 15 then
			lastSafeGroundCFrame = cframe
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

	------------------------------------------------
	-- 🛣️ ROAD NETWORK WAYPOINTS FOR MAX DISTANCE BONUS
	------------------------------------------------
	local HighwayWaypoints = {
		{ name = "BCA_Depot", pos = Vector3.new(1866.5, 24.5, -4874.5) },
		{ name = "BCA_Exit", pos = Vector3.new(1980.0, 24.5, -4720.0) },
		{ name = "Plaza_Barat_Junc", pos = Vector3.new(1100.0, 24.2, -4100.0) },
		{ name = "City_Center_Junc", pos = Vector3.new(2150.0, 26.0, -4200.0) },
		{ name = "Boulevard_Mid", pos = Vector3.new(1850.0, 24.5, -2800.0) },
		{ name = "Toll_North_Entry", pos = Vector3.new(1650.0, 27.5, -1200.0) },
		{ name = "Overpass_Mid", pos = Vector3.new(1550.0, 48.5, 875.0) },
		{ name = "Toll_Mid_Straight", pos = Vector3.new(950.0, 30.0, 3200.0) },
		{ name = "Toll_South_Gate", pos = Vector3.new(200.0, 26.5, 5800.0) },
		{ name = "Tol_Selatan_Junc", pos = Vector3.new(-350.0, 26.0, 8200.0) },
		{ name = "Ring_Road_Entry", pos = Vector3.new(-220.0, 22.0, 10200.0) },
	}

	-- Resolves direct navigation path to destination
	local function resolveRoadPath(startP, destP)
		return { destP }
	end

	-- 🚗 Server-Validated Vehicle Movement Engine (Paced Tweening + Velocity Sync + Road Tracking)
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

		-- Configured Safe Speed (80 studs/s = ~95 km/h for perfect server delta acceptance)
		local speed = tonumber(Config.farm.bcaTweenSpeed) or 80
		if speed > 100 then
			speed = 80 -- Clamp to server-safe threshold for travel distance validation
		end

		local arriveDist = tonumber(Config.farm.bcaArriveDist) or 35

		if totalDirectDist < arriveDist then
			print(string.format("[BCA] Already at target destination (Distance: %.1f studs)", totalDirectDist))
			safelySettleAndUnanchor(car)
			return true
		end

		-- Resolve full road waypoints path to maximize legitimate travel distance bonus
		local waypoints = resolveRoadPath(startP, destP)
		print(string.format("[BCA] Starting road-routed drive to target (%d legs) | Direct Dist: %.1f studs | Speed: %d studs/s (~95 km/h)", 
			#waypoints, totalDirectDist, speed))

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

		local lastOdoTime = 0
		local currentLegStart = startP

		for legIndex, legTarget in ipairs(waypoints) do
			if not bcaCourierActive then break end

			local legStartCF = car:GetPivot()
			currentLegStart = legStartCF.Position
			local legDist = (currentLegStart - legTarget).Magnitude

			if legDist >= 15 then
				local legDuration = math.clamp(legDist / speed, 0.2, 50.0)
				local rawDir = (legTarget - currentLegStart)
				local flatDir = Vector3.new(rawDir.X, 0, rawDir.Z)
				local moveDir = flatDir.Magnitude > 0.1 and flatDir.Unit or Vector3.new(0, 0, -1)
				local yawAngle = math.atan2(-moveDir.X, -moveDir.Z)
				local horizontalRot = CFrame.Angles(0, yawAngle, 0)

				local t0 = os.clock()
				local legFinished = false
				local lastGroundY = currentLegStart.Y
				local conn

				conn = RunService.Heartbeat:Connect(function()
					if not bcaCourierActive then
						if conn then conn:Disconnect() end
						legFinished = true
						return
					end

					local elapsed = os.clock() - t0
					local alpha = math.clamp(elapsed / legDuration, 0, 1)

					-- Follow road ground asphalt via downward raycasts
					local curX = currentLegStart.X + (legTarget.X - currentLegStart.X) * alpha
					local curZ = currentLegStart.Z + (legTarget.Z - currentLegStart.Z) * alpha

					local rayParams = RaycastParams.new()
					rayParams.FilterDescendantsInstances = { car, player.Character }
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					local hit = workspace:Raycast(Vector3.new(curX, lastGroundY + 15, curZ), Vector3.new(0, -50, 0), rayParams)
					local roadY = hit and (hit.Position.Y + 2.2) or (currentLegStart.Y + (legTarget.Y - currentLegStart.Y) * alpha)
					lastGroundY = roadY
					local curY = math.max(roadY, 22.2)

					local curPos = Vector3.new(curX, curY, curZ)
					local remainingTotal = (destP - curPos).Magnitude
					updateBcaActivity(string.format("🚗 Driving Bank Van (Leg %d/%d | %.0f stud left | %d km/h)", 
						legIndex, #waypoints, remainingTotal, math.floor(speed * 1.2)))

					-- Pure horizontal CFrame with road alignment
					local currentCF = CFrame.new(curPos) * horizontalRot

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
							if aValues:FindFirstChild("Velocity") then aValues.Velocity.Value = moveDir * speed end
						end
						if seat:IsA("VehicleSeat") then
							seat.Throttle = 1
							seat.ThrottleFloat = 1
							seat.AssemblyLinearVelocity = moveDir * speed
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

					if alpha >= 1 then
						legFinished = true
						if conn then conn:Disconnect() end
					end
				end)

				while not legFinished and bcaCourierActive do
					task.wait(0.02)
				end
				if conn then pcall(function() conn:Disconnect() end) end
			end
		end

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
				updateBcaActivity("🛑 Auto Farm Selesai! Disconnecting...")
				UI.Notify("Target Earning Reached!", kickMsg, 5, "success")
				task.wait(0.5)
				pcall(function()
					game:GetService("Players").LocalPlayer:Kick(kickMsg)
				end)
				return true
			end
		end
		return false
	end

	local function resetBcaState()
		bcaCurKoper = 0
		bcaTotKoper = 0
		bcaCurAtm = 0
		bcaTotAtm = 0
		bcaIsCarrying = false
		bcaJobPhase = ""
		bcaJobComplete = false
	end

	pcall(function()
		player.CharacterAdded:Connect(function()
			resetBcaState()
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
		timeout = timeout or 3.5
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

				-- 2. Check for choices buttons (Yes / Claim / Finish / Spawn)
				local choices = dialog:FindFirstChild("Choices")
				local yesBtn = (choices and choices:FindFirstChild("Yes")) or dialog:FindFirstChild("Yes", true)
				if yesBtn and yesBtn.Visible then
					pcall(function()
						if firesignal then
							firesignal(yesBtn.Activated)
							firesignal(yesBtn.MouseButton1Click)
						end
						if getconnections then
							for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
							for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
						end
					end)
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

					local yesBtn = (choices and choices:FindFirstChild("Yes")) or dialog:FindFirstChild("Yes", true)
					if yesBtn and yesBtn.Visible then
						if firesignal then
							firesignal(yesBtn.Activated)
							firesignal(yesBtn.MouseButton1Click)
						end
						if getconnections then
							for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
							for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
						end
					end
				end
			end)
			task.wait(0.15)
		end
	end)

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

	local function parseProgress(text)
		local cur, total = string.match(text or "", "(%d+)/(%d+)")
		return tonumber(cur) or 0, tonumber(total) or 0
	end

	local function loadKopersIntoCar(car)
		local jobGui = getBankCourierGui()
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

		-- 0. Check Job GUI Hint/Step Text for specific ATM name/number (Direct Server Assignment)
		local jobGui = getBankCourierGui()
		local hintText = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("Hint") and jobGui.Status.Hint.Text or ""
		local stepText = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("Step") and jobGui.Status.Step.Text or ""
		local fullText = (hintText .. " " .. stepText):lower()

		for atmKey, spotPos in pairs(ATM_PARKING_SPOTS) do
			local num = atmKey:match("%d+")
			if num and (fullText:find("atm " .. num) or fullText:find("atm" .. num)) then
				return spotPos, atmKey
			end
		end
		if fullText:find("bsd") and ATM_PARKING_SPOTS["ATM9"] then
			return ATM_PARKING_SPOTS["ATM9"], "ATM9"
		elseif (fullText:find("tol") or fullText:find("selatan")) and ATM_PARKING_SPOTS["ATM7"] then
			return ATM_PARKING_SPOTS["ATM7"], "ATM7"
		elseif (fullText:find("ring") or fullText:find("ringroad")) and ATM_PARKING_SPOTS["ATM8"] then
			return ATM_PARKING_SPOTS["ATM8"], "ATM8"
		elseif fullText:find("plaza") and ATM_PARKING_SPOTS["ATM3"] then
			return ATM_PARKING_SPOTS["ATM3"], "ATM3"
		elseif fullText:find("center") and ATM_PARKING_SPOTS["ATM4"] then
			return ATM_PARKING_SPOTS["ATM4"], "ATM4"
		elseif fullText:find("office") and ATM_PARKING_SPOTS["ATM2"] then
			return ATM_PARKING_SPOTS["ATM2"], "ATM2"
		end

		-- 1. Check BankCourierRoute Beam in workspace (Exact Active Server Route)
		local route = workspace:FindFirstChild("BankCourierRoute")
		if route and route:FindFirstChild("To") then
			local pos = route.To.WorldPosition
			if pos and (pos - bcaDepotPos).Magnitude > 30 then
				for atmName, spotPos in pairs(ATM_PARKING_SPOTS) do
					if (spotPos - pos).Magnitude < 250 then
						return spotPos, atmName
					end
				end
				return pos
			end
		end

		-- 2. Check Active Highlight or BillboardGui on ATM in MY_BCA_COLLAB
		local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
		if atms then
			for _, atm in ipairs(atms:GetChildren()) do
				local highlight = atm:FindFirstChildOfClass("Highlight") or atm:FindFirstChild("Highlight", true)
				local bbg = atm:FindFirstChildOfClass("BillboardGui") or atm:FindFirstChild("BillboardGui", true)
				local p = atm:FindFirstChildOfClass("BasePart") or atm:FindFirstChild("Part", true)
				if ((highlight and highlight.Enabled) or (bbg and bbg.Enabled)) and p and (p.Position - bcaDepotPos).Magnitude > 30 then
					local spot = ATM_PARKING_SPOTS[atm.Name] or p.Position
					return spot, atm.Name
				end
			end
		end

		-- 3. Check Waypoints in workspace.Etc.Waypoint
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

		-- 4. Check __BankCourierTarget
		local targetPart = workspace:FindFirstChild("__BankCourierTarget")
		if targetPart and (targetPart.Position - bcaDepotPos).Magnitude > 30 then
			return targetPart.Position
		end

		-- 5. Fallback: Default to ATM9 (BSD City - high distance bonus)
		if ATM_PARKING_SPOTS["ATM9"] then
			return ATM_PARKING_SPOTS["ATM9"], "ATM9"
		end

		return nil
	end

	local function deliverToAtms(car)
		local jobGui = getBankCourierGui()
		local bagasi = car and car:FindFirstChild("BagasiPoint")

		-- Pre-check: If car has 0 kopers, abort delivery and let main loop load them first
		local koperText = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("Koper") and jobGui.Status.Koper.Text or ""
		local curKoper, totKoper = parseProgress(koperText)
		if totKoper > 0 and curKoper < totKoper then
			print(string.format("[BCA] deliverToAtms: Car has %d/%d kopers. Aborting delivery, needs loading first.", curKoper, totKoper))
			return
		end

		while bcaCourierActive do
			if checkTargetEarningAndDisconnect() then return end

			local atmText = jobGui and jobGui.Status.Atm.Text or ""
			local stepText = jobGui and jobGui.Status.Step.Text or ""
			local curAtm, totAtm = parseProgress(atmText)

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
			print(string.format("[BCA] Starting vehicle tween to ATM target (%s)", tostring(targetDrivePos)))
			updateBcaActivity("🚗 Tweening Bank Van to Destination ATM (220 studs/s)")
			local driveSuccess = driveTo(targetDrivePos)
			if not driveSuccess then
				warn("[BCA] driveTo failed to reach target ATM. Aborting delivery step.")
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
					if not hasActiveJobGui then
						resetBcaState()
					end

					local hintText = hasActiveJobGui and jobGui.Status.Hint.Text or ""
					local koperText = hasActiveJobGui and jobGui.Status.Koper.Text or ""
					local atmText = hasActiveJobGui and jobGui.Status.Atm.Text or ""
					local stepText = hasActiveJobGui and jobGui.Status.Step.Text or ""

					local curKoper, totKoper = parseProgress(koperText)
					local curAtm, totAtm = parseProgress(atmText)

					-- STEP 1: Ensure Bank Courier Job is active (ONLY when starting completely fresh)
					if not hasActiveJobGui then
						updateBcaActivity("🚶 Tweening to Andhini NPC (200 studs/s)")
						local andhiniPos = Vector3.new(1807.269, 23.362, -4635.745)
						safeTeleport(CFrame.new(andhiniPos + Vector3.new(0, 0, 3)), true, 200)
						task.wait(0.5)

						local andhiniNpc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("NPC_START_JOB")
						local andhiniPrompt = andhiniNpc and andhiniNpc:FindFirstChildOfClass("ProximityPrompt")
						if andhiniPrompt then
							triggerPrompt(andhiniPrompt)
						end

						skipAndConfirmNpcDialog(3.0)

						fireRemote("Job", "BankCourier")
						fireRemote("NpcDialog", "Finish", 1)
						fireRemote("NpcDialog", "Finish", "BankCourier")
						task.wait(1.5)
						jobGui = getBankCourierGui()
						hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
						if not hasActiveJobGui then return end
					end

					-- STEP 5: Return to Depot & Approach Andhini NPC to Claim Salary (PRIORITY #1 when all ATMs are filled / GAJIAN!)
					local isAtmDone = bcaJobComplete
						or (totAtm > 0 and curAtm >= totAtm)
						or stepText:find("3)")
						or stepText:find("Kembali")
						or stepText:find("GAJIAN")
						or stepText:find("gaji")
						or hintText:find("terima gaji")
						or hintText:find("Andhini")

					if isAtmDone then
						updateBcaActivity("⚡ Instant Teleporting Van Back to BCA Depot...")
						local depotCF = CFrame.new(1781.04, 22.22, -4615.77)
						safeTeleportCar(depotCF)
						exitDriveSeat()
						task.wait(0.2)

						-- Instant Teleport directly in front of Andhini NPC
						updateBcaActivity("⚡ Teleporting to Andhini NPC")
						local andhiniPos = Vector3.new(1807.269, 23.362, -4635.745)
						safeTeleport(CFrame.new(andhiniPos + Vector3.new(0, 0, 3)), false)
						task.wait(0.3)

						-- Trigger Andhini's DialogPrompt
						updateBcaActivity("💰 Speaking to Andhini & Claiming Salary")
						local andhiniNpc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("NPC_START_JOB")
						local andhiniPrompt = andhiniNpc and andhiniNpc:FindFirstChildOfClass("ProximityPrompt")
						if andhiniPrompt then
							triggerPrompt(andhiniPrompt)
						end

						-- Tap screen to skip dialog text and confirm salary payout
						skipAndConfirmNpcDialog(3.5)

						fireRemote("NpcDialog", "Finish", 1)
						fireRemote("NpcDialog", "Finish", "BankCourier")
						fireRemote("BankCourier", "Complete")
						fireRemote("PhoneJobSalary")
						fireRemote("MyBcaAppOpened")
						resetBcaState()
						updateBcaActivity("🎉 Contract Completed! Salary Claimed")
						task.wait(1.5)
						if checkTargetEarningAndDisconnect() then return end
						task.wait(1.5)
						return
					end

					-- STEP 2: Ensure Bank Car is spawned via Putra NPC
					local car = getPlayerCar()
					if not car or hintText:find("Keluarkan mobil") or hintText:find("petugas kendaraan") then
						car = spawnBankCar()
						task.wait(0.5)
						return
					end

					if not car then
						task.wait(1)
						return
					end

					-- STEP 3: Load Kopers into Car Trunk
					-- Check actual koper count — if car has 0 kopers out of N, we MUST load regardless of step text
					local isKoperFull = (totKoper > 0 and curKoper >= totKoper)
					local needsLoading = not isKoperFull and totKoper > 0 and curKoper < totKoper
					if needsLoading then
						print(string.format("[BCA] Kopers need loading: %d/%d in car. Loading...", curKoper, totKoper))
						loadKopersIntoCar(car)
						task.wait(0.5)
						return
					end

					-- STEP 4: Deliver to marked ATMs (kopers loaded or step text says deliver)
					if (isKoperFull or stepText:find("2)") or stepText:find("Antar")) and not isAtmDone then
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

	-- 🏦 BCA Collaboration Event & Bank Courier
	local bcaSec = UI.AddSection(farmFrame, "🏦 BCA Collaboration Event & Bank Courier", 1)

	-- Real-Time Status & Live Stats Display
	bcaActivityLabel = UI.AddLabel(bcaSec, "📍 Action: Idle (Toggle Auto Farm to start)", 1, UI.COLORS.accentCyan)
	bcaProgressLabel = UI.AddLabel(bcaSec, "📦 Van Kopers: 0/0  |  🏧 ATMs Filled: 0/0", 2, UI.COLORS.textSecondary)
	bcaTargetLabel = UI.AddLabel(bcaSec, "🎯 Target: Standby / None", 3, UI.COLORS.textMuted)
	bcaSalaryLabel = UI.AddLabel(bcaSec, "💵 Est. Salary: Rp 0  |  Pocket: Rp 0", 4, UI.COLORS.successGreen)
	bcaTargetEarningLabel = UI.AddLabel(bcaSec, "🎯 Target Earning: Disabled  |  Live Poket: Rp 0", 5, UI.COLORS.accentViolet)

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
						bcaTargetEarningLabel.Text = string.format("🎯 Target: %s  |  Live Poket: %s (%d%%)", formatRupiah(targetCash), formatRupiah(livePocket), pct)
					else
						bcaTargetEarningLabel.Text = string.format("🎯 Target: Disabled  |  Live Poket: %s", formatRupiah(livePocket))
					end
				end

				-- Real-time auto-disconnect when target earning is reached (checked continuously!)
				if checkTargetEarningAndDisconnect() then
					return
				end

				if bcaCourierActive then
					if bcaActivityLabel then
						bcaActivityLabel.Text = "📍 Action: " .. currentBcaActivity
					end

					if bcaProgressLabel then
						bcaProgressLabel.Text = string.format("📦 Van Kopers: %d/%d  |  🏧 ATMs Filled: %d/%d", curK, totK, curA, totA)
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
							bcaTargetLabel.Text = string.format("🎯 Target: %s (%dm away)", matchedAtm, dist)
						else
							bcaTargetLabel.Text = hasActiveJobGui and "🎯 Target: Standby / Generating Route" or "🎯 Target: None (Starting Job...)"
						end
					end

					if bcaSalaryLabel and sText ~= "" then
						bcaSalaryLabel.Text = string.format("💵 %s %s", sText, (pText ~= "" and (" | " .. pText) or ""))
					end
				else
					if bcaActivityLabel then
						bcaActivityLabel.Text = "📍 Action: Idle (Toggle Auto Farm to start)"
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
			UI.Notify("BCA Courier Farm Active", "Automating money briefcases & 10 ATMs deliveries!", 3, "success")
			runBcaCourierFarm()
		else
			updateBcaActivity("Paused (Toggle off)")
			UI.Notify("BCA Courier Farm Stopped", "Bank courier paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 5)

	UI.AddSlider(bcaSec, "Delivery Delay (Seconds)", 0.5, 5.0, bcaCourierDelay, function(v)
		bcaCourierDelay = v
		Config.farm.bcaCourierDelay = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 6, "s")

	UI.AddSlider(bcaSec, "Car Tween Speed (studs/s)", 60, 200, Config.farm.bcaTweenSpeed or 120, function(v)
		Config.farm.bcaTweenSpeed = v
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 7, " studs/s")

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

	UI.AddDropdown(bcaSec, "🎯 Destination ATM (Far = 6M+)", atmDropdownOptions, currentAtmLabel, function(selectedOpt)
		local key = ATM_OPTION_MAP[selectedOpt] or "Auto"
		Config.farm.bcaTargetAtm = key
		UI.Notify("Destination ATM Set", selectedOpt, 2, "info")
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 10)

	UI.AddTextbox(bcaSec, "Target Earning (Million IDR)", tostring(bcaTargetEarning or 0), function(val)
		local num = tonumber(val) or 0
		bcaTargetEarning = num
		Config.farm.bcaTargetEarning = num
		if num > 0 then
			local fullIdr = num * 1000000
			UI.Notify("Target Earning Set", string.format("Target: %s (%d Juta). Will disconnect when reached!", formatRupiah(fullIdr), num), 3, "success")
			checkTargetEarningAndDisconnect()
		else
			UI.Notify("Target Earning Disabled", "No earning limit set (runs continuously).", 2, "info")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 7)

	UI.AddLabel(bcaSec, "💡 Type in millions: 1 = Rp 1.000.000, 10 = Rp 10.000.000, 68 = Rp 68.000.000 (0 = No limit)", 8, UI.COLORS.textMuted)

	UI.AddToggle(bcaSec, "Anti Staff / Auto Disconnect on Player Join", Config.farm.antiStaff or false, function(v)
		antiStaffActive = v
		Config.farm.antiStaff = v
		if v then
			UI.Notify("Anti Staff Active", "Will auto-disconnect if any player joins server.", 3, "warning")
			for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
				if otherPlayer ~= player then
					pcall(function()
						game:GetService("Players").LocalPlayer:Kick("Anti Staff Detected.")
					end)
					break
				end
			end
		else
			UI.Notify("Anti Staff Disabled", "Player join protection turned off.", 2, "info")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 9)

	UI.AddToggle(bcaSec, "Auto Sync myBCA App (Pocket Rupiah)", Config.farm.bcaAppSync or true, function(v)
		bcaAppSyncActive = v
		Config.farm.bcaAppSync = v
		if v then
			fireRemote("MyBcaAppOpened")
			UI.Notify("myBCA Synced", "Synced Pocket Rupiah & NFC status!", 2, "success")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 7)

	UI.AddButton(bcaSec, "Spawn BCA Bank Armored Van", function()
		pcall(function()
			local remotes = ReplicatedStorage:FindFirstChild("NetworkContainer")
			if remotes and remotes:FindFirstChild("RemoteFunctions") and remotes.RemoteFunctions:FindFirstChild("Spawner") then
				remotes.RemoteFunctions.Spawner:InvokeServer("Spawn", "2025SemeruLarasBankCar")
				UI.Notify("BCA Van Spawned", "Spawned 2025 Semeru Laras Bank Car!", 3, "success")
			else
				UI.Notify("Spawn Failed", "Spawner remote unavailable.", 3, "warning")
			end
		end)
	end, 8)

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
				UI.Notify("Exchange Booth", "Teleported to BCA Reward Exchange Booth!", 3, "success")
			else
				safeTeleport(CFrame.new(bcaDepotPos))
				UI.Notify("Teleported", "Teleported to BCA Depot.", 3, "success")
			end
		end)
	end, 5)

	-- Launch BCA Courier thread immediately if enabled in saved config
	if bcaCourierActive then
		runBcaCourierFarm()
	end

	-- Export BCA farm API
	_G.HipHubFarm = {
		SetBcaCourier = function(v) bcaCourierActive = v end,
	}
end)

if not success then
	warn("[HipHub CDID Farm Error]:", err)
end
