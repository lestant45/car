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
					elseif root.Position.Y < 5 then
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
			or car:FindFirstChildWhichIsA("VehicleSeat", true)
			or car:FindFirstChildWhichIsA("Seat", true)
	end

	local isSettling = false
	local function safelySettleAndUnanchor(car)
		if not car or isSettling then return end
		isSettling = true
		pcall(function()
			local root = car.PrimaryPart or getDriveSeat(car)
			if root then
				local currentPos = root.Position
				local currentRot = car:GetPivot().Rotation
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

				-- Smooth gentle descent to ground level (over ~0.25s)
				local startY = currentPos.Y
				local tDown = os.clock()
				while os.clock() - tDown < 0.25 do
					local a = math.clamp((os.clock() - tDown) / 0.25, 0, 1)
					local easedA = -(math.cos(math.pi * a) - 1) / 2
					local curY = startY + (groundY - startY) * easedA
					car:PivotTo(CFrame.new(currentPos.X, curY, currentPos.Z) * currentRot)
					RunService.Heartbeat:Wait()
				end
				car:PivotTo(CFrame.new(currentPos.X, groundY, currentPos.Z) * currentRot)
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
		local prompt = seat:FindFirstChild("PromptDriveSeat") or seat:FindFirstChildWhichIsA("ProximityPrompt", true)
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

	-- 🚗 Reusable Vehicle Movement Engine (Extracted directly from autodrive.lua)
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

		local seat = getDriveSeat(car)
		if not seat then
			warn("[BCA] driveTo failed: Driver seat not found in vehicle")
			return false
		end

		-- 1. Ensure player is seated in driver seat
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if not hum or not hum.Sit or hum.SeatPart ~= seat then
			enterDriveSeat(car)
			task.wait(0.3)
		end

		local startCF = car:GetPivot()
		local startP = startCF.Position
		local destP = targetPos
		local dist = (startP - destP).Magnitude

		print(string.format("[BCA] Starting drive to target: %s", tostring(targetPos)))
		print(string.format("[BCA] Distance: %.1f studs", dist))

		if dist < 15 then
			print(string.format("[BCA] Already at target destination (Distance: %.1f studs)", dist))
			safelySettleAndUnanchor(car)
			return true
		end

		-- Stream region & prepare landing plate
		ensureSafetyPlate(destP, 55)
		requestStreamAsync(destP)

		local speed = 160
		local duration = math.clamp(dist / speed, 1.0, 50.0)
		local cruiseAlt = math.max(startP.Y, destP.Y) + 12.0

		print(string.format("[BCA] Drive started -> Speed: %d studs/s | Duration: %.2fs", speed, duration))

		-- Engage A-Chassis engine & release handbrake (from autodrive.lua)
		local pgui = player:FindFirstChild("PlayerGui")
		local aChassisGui = pgui and pgui:FindFirstChild("A-Chassis Interface")
		local aValues = aChassisGui and aChassisGui:FindFirstChild("Values")
		if aChassisGui and aChassisGui:FindFirstChild("IsOn") then aChassisGui.IsOn.Value = true end
		if aValues then
			if aValues:FindFirstChild("PBrake") then aValues.PBrake.Value = false end
			if aValues:FindFirstChild("Brake") then aValues.Brake.Value = 0 end
			if aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 1 end
		end
		if seat:IsA("VehicleSeat") then
			seat.Throttle = 1
			seat.ThrottleFloat = 1
		end

		-- Ghost mode: Disable collision on body/wheels and anchor during travel (from autodrive.lua)
		local anchoredParts = {}
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				if not part.Anchored then
					table.insert(anchoredParts, part)
					part.Anchored = true
				end
			end
		end

		local t0 = os.clock()
		local conn
		local finished = false
		local lastLogTime = 0

		local rawDir = (destP - startP)
		local moveDir = rawDir.Magnitude > 0.1 and rawDir.Unit or Vector3.new(0, 0, -1)
		local flatLook = Vector3.new(moveDir.X, 0, moveDir.Z).Magnitude > 0.05 and Vector3.new(moveDir.X, 0, moveDir.Z).Unit or moveDir

		conn = RunService.Heartbeat:Connect(function()
			local elapsed = os.clock() - t0
			local alpha = math.clamp(elapsed / duration, 0, 1)

			-- 3-Phase Altitude Cruise: Rise up (+12 Y) -> Cruise -> Smooth landing descent
			local curX = startP.X + (destP.X - startP.X) * alpha
			local curZ = startP.Z + (destP.Z - startP.Z) * alpha
			local curY
			if alpha < 0.12 then
				local liftA = alpha / 0.12
				curY = startP.Y + (cruiseAlt - startP.Y) * liftA
			elseif alpha <= 0.88 then
				curY = cruiseAlt
			else
				local landA = (alpha - 0.88) / 0.12
				curY = cruiseAlt + (destP.Y - cruiseAlt) * landA
			end
			local curPos = Vector3.new(curX, curY, curZ)

			local remainingDist = (destP - curPos).Magnitude
			updateBcaActivity(string.format("🚗 Driving Bank Van to Destination (%.0f studs left | 160 km/h)", remainingDist))

			if os.clock() - lastLogTime >= 1.0 then
				lastLogTime = os.clock()
				print(string.format("[BCA] Remaining: %.1f studs (%.1f%% complete)", remainingDist, alpha * 100))
			end

			local currentCF
			if flatLook.Magnitude > 0.05 and remainingDist > 6 and alpha < 0.95 then
				currentCF = CFrame.lookAt(curPos, curPos + flatLook)
			else
				currentCF = startCF:Lerp(CFrame.new(destP), alpha)
			end

			pcall(function()
				car:PivotTo(currentCF)

				-- Keep collision off during drive
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end

				-- Keep player seated in driver seat
				local c = player.Character
				local h = c and c:FindFirstChild("Humanoid")
				local r = c and c:FindFirstChild("HumanoidRootPart")
				if r and seat and (not h or not h.Sit or not h.SeatPart) then
					r.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
					if h then h.Sit = true; seat:Sit(h) end
				end
			end)

			if alpha >= 1 then
				finished = true
				if conn then conn:Disconnect() end
			end
		end)

		while not finished do
			task.wait(0.02)
		end
		if conn then pcall(function() conn:Disconnect() end) end

		-- Arrival Condition Verification
		local arrivalRemaining = (car:GetPivot().Position - destP).Magnitude
		print(string.format("[BCA] Drive completed. Arrival distance: %.1f studs", arrivalRemaining))

		-- Smoothly settle and unanchor on the road with collision restoration (from autodrive.lua)
		safelySettleAndUnanchor(car)

		local isSuccess = arrivalRemaining <= 25
		return isSuccess
	end

	------------------------------------------------
	-- 🚚 SILAMBAT COURIER AUTO FARM
	------------------------------------------------
	local siLambatActive = false
	local siLambatDelay = Config.farm.siLambatDelay or 1.2
	local siLambatHQ = Vector3.new(-4023.717, 23.472, 4620.15)

	local function runSiLambatFarm()
		task.spawn(function()
			while siLambatActive do
				pcall(function()
					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					-- Step 1: Teleport to SiLambat HQ to start / pickup package
					safeTeleport(CFrame.new(siLambatHQ + Vector3.new(0, 3, 0)))
					task.wait(siLambatDelay)

					-- Trigger Package Collection / Interaction
					fireRemote("Job", "SiLambat")
					task.wait(0.5)

					-- Step 2: Check for destination waypoint or NPC
					local waypoints = workspace:FindFirstChild("Etc") and workspace.Etc:FindFirstChild("Waypoint")
					local targetPos = nil

					if waypoints and #waypoints:GetChildren() > 0 then
						for _, wp in pairs(waypoints:GetChildren()) do
							if wp:IsA("BasePart") then
								targetPos = wp.Position
								break
							end
						end
					end

					-- If no specific waypoint found, check NPC or default delivery locations
					if not targetPos then
						local npcs = workspace:FindFirstChild("NPC")
						if npcs and #npcs:GetChildren() > 0 then
							local npc = npcs:GetChildren()[1]
							if npc:FindFirstChild("HumanoidRootPart") then
								targetPos = npc.HumanoidRootPart.Position
							end
						end
					end

					if not targetPos then
						-- Sample fallback SiLambat destinations (Gambir, Office, CDID Mart, Spark)
						local defaults = {
							Vector3.new(6502.558, 19.901, -7691.016),
							Vector3.new(-1107.12, 22.5, 2228.214),
							Vector3.new(2047.507, 20.418, -3696.606),
							Vector3.new(-4248.968, 18.562, -381.809)
						}
						targetPos = defaults[math.random(1, #defaults)]
					end

					-- Step 3: Teleport to delivery spot
					safeTeleport(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
					task.wait(siLambatDelay)

					-- Step 4: Fire Delivery Remote & Trigger Proximity Prompts
					fireRemote("SiLambat", "Delivery")

					pcall(function()
						local nearbyParts = workspace:GetPartBoundsInRadius(targetPos, 25)
						for _, p in ipairs(nearbyParts) do
							for _, prompt in ipairs(p:GetChildren()) do
								if prompt:IsA("ProximityPrompt") and prompt.Enabled then
									if prompt.ActionText:lower():find("deliver") or prompt.ObjectText:lower():find("package") or prompt.ActionText:lower():find("ambil") then
										if fireproximityprompt then fireproximityprompt(prompt, 0) end
									end
								end
							end
						end
					end)

					task.wait(siLambatDelay)
				end)
				task.wait(0.5)
			end
		end)
	end

	------------------------------------------------
	-- ☕ JANJI JIWA (COFFEE DELIVERY) AUTO FARM
	------------------------------------------------
	local janjiJiwaActive = false
	local janjiJiwaDelay = Config.farm.janjiJiwaDelay or 1.2
	local janjiJiwaStart = Vector3.new(-22778.883, 26.077, 15431.812)

	local function runJanjiJiwaFarm()
		task.spawn(function()
			while janjiJiwaActive do
				pcall(function()
					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					-- Step 1: Teleport to Coffee Shop
					safeTeleport(CFrame.new(janjiJiwaStart + Vector3.new(0, 3, 0)))
					task.wait(janjiJiwaDelay)

					-- Trigger start / grab coffee
					fireRemote("Job", "JanjiJiwa")
					task.wait(0.5)

					-- Step 2: Teleport to Customer NPC
					local npcs = workspace:FindFirstChild("NPC")
					if npcs and #npcs:GetChildren() > 0 then
						for _, npc in pairs(npcs:GetChildren()) do
							if npc:FindFirstChild("HumanoidRootPart") then
								safeTeleport(CFrame.new(npc.HumanoidRootPart.Position + Vector3.new(0, 2, 2)))
								task.wait(0.5)
								break
							end
						end
					end

					-- Step 3: Complete Coffee Delivery
					fireRemote("JanjiJiwa", "Delivery")
					task.wait(janjiJiwaDelay)
				end)
				task.wait(0.5)
			end
		end)
	end

	------------------------------------------------
	-- 🚑 EMS / HOSPITAL HEAL AUTO FARM
	------------------------------------------------
	local emsActive = false
	local emsDelay = Config.farm.emsDelay or 1.5
	local emsHQ = Vector3.new(-24225.34, 30.682, 13797.631)

	local function runEmsFarm()
		task.spawn(function()
			while emsActive do
				pcall(function()
					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					-- Step 1: Ensure at Hospital / Spawn
					safeTeleport(CFrame.new(emsHQ + Vector3.new(0, 3, 0)))
					task.wait(0.5)
					fireRemote("Job", "Emergency")
					task.wait(emsDelay)

					-- Step 2: Teleport near injured patient NPC
					local npcs = workspace:FindFirstChild("NPC")
					if npcs and #npcs:GetChildren() > 0 then
						for _, npc in pairs(npcs:GetChildren()) do
							if npc:FindFirstChild("HumanoidRootPart") then
								safeTeleport(CFrame.new(npc.HumanoidRootPart.Position + Vector3.new(0, 2, 2)))
								task.wait(0.5)

								-- Step 3: Trigger Heal Remote
								fireRemote("EMS", "Heal")
								task.wait(0.5)
								break
							end
						end
					end

					task.wait(emsDelay)
				end)
				task.wait(0.5)
			end
		end)
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

	local function updateBcaActivity(activity)
		currentBcaActivity = activity
		if bcaActivityLabel then
			bcaActivityLabel.Text = "📍 Action: " .. activity
		end
	end

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
			local stepText = jobGui.Status.Step.Text or ""
			local curKoper, totKoper = parseProgress(koperText)

			-- If already full or in step 2 (delivering), stop loading
			if (totKoper > 0 and curKoper >= totKoper) or stepText:find("2)") or stepText:find("Antar") then
				print(string.format("[BCA-TRACE][LOADING] Suitcases full (%d/%d) or step 2 detected (%s). Exiting loading loop.", curKoper, totKoper, stepText))
				break
			end

			-- 1. Walk/Tween to Koper Stack & Pickup
			print(string.format("[BCA-TRACE][LOADING] Picking up suitcase %d/%d from stack...", curKoper + 1, totKoper))
			updateBcaActivity(string.format("🧳 Grabbing Suitcase from Stack (%d/%d)", curKoper, totKoper))
			if koperPart then
				safeTeleport(koperPart.CFrame + Vector3.new(0, 1.2, 0), true, 40)
				task.wait(0.3)
				local prompt = koperPart:FindFirstChild("Prompt", true) or koperPart:FindFirstChildWhichIsA("ProximityPrompt", true)
				triggerPrompt(prompt)
			else
				safeTeleport(CFrame.new(bcaKoperPos), true, 40)
			end

			task.wait(0.5)

			-- 2. Walk/Tween to Car Bagasi & Trigger Muat
			print(string.format("[BCA-TRACE][LOADING] Loading suitcase %d/%d into vehicle trunk...", curKoper + 1, totKoper))
			updateBcaActivity("📦 Loading Suitcase into Trunk (Timing Minigame)")
			car = getPlayerCar() or car
			local bagasi = car and car:FindFirstChild("BagasiPoint")
			if bagasi then
				safeTeleport(bagasi.CFrame + Vector3.new(0, 1, 0), true, 40)
				task.wait(0.3)
				local muatPrompt = bagasi:FindFirstChild("MuatPrompt") or bagasi:FindFirstChildWhichIsA("ProximityPrompt", true)
				triggerPrompt(muatPrompt)
			end

			-- 3. Precise Timing Drop into Slot (matching Picture 2)
			timing = jobGui and jobGui:FindFirstChild("Timing")
			local tStart = os.clock()
			while timing and not timing.Visible and os.clock() - tStart < 2.5 do
				task.wait(0.02)
			end

			if timing and timing.Visible then
				local koperImg = timing:FindFirstChild("Track") and timing.Track:FindFirstChild("Koper")
				local slot = timing:FindFirstChild("Trunk") and timing.Trunk:FindFirstChild("Slot")
				local goBtn = timing:FindFirstChild("Go")
				local t0 = os.clock()

				while timing.Visible and os.clock() - t0 < 4.0 do
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

				-- Wait until the minigame UI completes and closes before moving to next suitcase
				local tClose = os.clock()
				while timing.Visible and os.clock() - tClose < 2.0 do
					task.wait(0.05)
				end
			end

			task.wait(0.8)
		end

		-- Confirm all 4 suitcases loaded and seat player in driver seat
		car = getPlayerCar() or car
		if car then
			print(string.format("[BCA-TRACE][LOADING] ✅ All 4 suitcases confirmed loaded in trunk. Car is at %s. Seating in DriverSeat...", tostring(car:GetPivot().Position)))
			updateBcaActivity("✅ 4/4 Suitcases Loaded -> Entering Driver Seat to Cruise")
			enterDriveSeat(car)
			task.wait(0.4)
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

	local function getBankCourierTargetPos()
		-- 1. Check BankCourierRoute Beam in workspace
		local route = workspace:FindFirstChild("BankCourierRoute")
		if route and route:FindFirstChild("To") then
			local pos = route.To.WorldPosition
			if pos and (pos - bcaDepotPos).Magnitude > 30 then
				return pos
			end
		end

		-- 2. Check __BankCourierTarget
		local targetPart = workspace:FindFirstChild("__BankCourierTarget")
		if targetPart and (targetPart.Position - bcaDepotPos).Magnitude > 30 then
			return targetPart.Position
		end

		-- 3. Check Waypoints
		local waypoints = workspace:FindFirstChild("Etc") and workspace.Etc:FindFirstChild("Waypoint")
		if waypoints and #waypoints:GetChildren() > 0 then
			for _, wp in ipairs(waypoints:GetChildren()) do
				if wp:IsA("BasePart") and (wp.Position - bcaDepotPos).Magnitude > 30 then
					return wp.Position
				end
			end
		end

		return nil
	end

	local function deliverToAtms(car)
		local jobGui = getBankCourierGui()
		local bagasi = car:FindFirstChild("BagasiPoint")

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
					local p = atm and atm:FindFirstChildWhichIsA("BasePart", true)
					if (p and (p.Position - targetPos).Magnitude < 50) or (spotPos - targetPos).Magnitude < 80 then
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
			print(string.format("[BCA] Starting drive to ATM target (%s)", tostring(targetDrivePos)))
			updateBcaActivity("🚗 Driving Bank Van to Destination ATM (160 studs/s)")
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
				if c:FindFirstChild("KoperUang") or c:FindFirstChildWhichIsA("Tool") then return true end
				if c:FindFirstChild("Koper", true) then return true end
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
				local ambilPrompt = bagasi:FindFirstChild("AmbilPrompt") or bagasi:FindFirstChildWhichIsA("ProximityPrompt", true)
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

					ambilPrompt = bagasi and (bagasi:FindFirstChild("AmbilPrompt") or bagasi:FindFirstChildWhichIsA("ProximityPrompt", true))
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
								firesignal(ambilPrompt.PromptButtonHoldBegan, player)
								firesignal(ambilPrompt.PromptButtonHoldEnded, player)
								firesignal(ambilPrompt.Triggered, player)
							end
							if getconnections then
								for _, c in ipairs(getconnections(ambilPrompt.Triggered)) do c:Fire(player) end
								for _, c in ipairs(getconnections(ambilPrompt.PromptButtonHoldEnded)) do c:Fire(player) end
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
					local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
					local screen = atm:FindFirstChild("Screen_ATM_01", true) or (prompt and prompt.Parent) or atm:FindFirstChildWhichIsA("BasePart", true)
					if screen and (screen.Position - targetPos).Magnitude < 100 then
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
						local andhiniPrompt = andhiniNpc and andhiniNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
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
						updateBcaActivity("🏁 Driving Bank Van Back to BCA Depot (160 studs/s)")
						local arrivedDepot = driveTo(Vector3.new(1781.04, 22.22, -4615.77))
						if arrivedDepot then
							exitDriveSeat()
							task.wait(0.5)
						end

						-- Walk/Tween inside lobby to approach Andhini (Koordinator Kurir BCA) at 200 studs/s
						updateBcaActivity("🚶 Tweening to Andhini NPC (200 studs/s)")
						local andhiniPos = Vector3.new(1807.269, 23.362, -4635.745)
						safeTeleport(CFrame.new(andhiniPos + Vector3.new(0, 0, 3)), true, 200)
						task.wait(0.5)

						-- Trigger Andhini's DialogPrompt
						updateBcaActivity("💰 Speaking to Andhini & Claiming Salary")
						local andhiniNpc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("NPC_START_JOB")
						local andhiniPrompt = andhiniNpc and andhiniNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
						if andhiniPrompt then
							triggerPrompt(andhiniPrompt)
						end

						-- Tap screen to skip dialog text and confirm salary payout
						skipAndConfirmNpcDialog(4.0)

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

					-- STEP 3: Load Kopers into Car Trunk (ONLY when in Step 1: Angkut koper uang)
					local isKoperFull = (totKoper > 0 and curKoper >= totKoper) or stepText:find("2)") or stepText:find("Antar")
					if not isKoperFull and (stepText:find("1)") or stepText:find("Angkut") or hintText:find("tumpukan")) then
						loadKopersIntoCar(car)
						task.wait(0.5)
						return
					end

					-- STEP 4: Deliver to marked ATMs (When in Step 2: Antar uang ke ATM)
					if (stepText:find("2)") or stepText:find("Antar") or isKoperFull) and not isAtmDone then
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
	-- 🛣️ ODOMETER / HIGHWAY SPEED MILEAGE FARM
	------------------------------------------------
	local odometerActive = false
	local odoSpeed = Config.farm.odometerSpeed or 140

	local function runOdometerFarm()
		task.spawn(function()
			-- Highway points across CDID Jakarta map
			local ptA = CFrame.new(1200, 25, -2500)
			local ptB = CFrame.new(6500, 25, -7500)
			local target = ptA

			while odometerActive do
				pcall(function()
					local car = getPlayerCar()
					if car and car:FindFirstChild("DriveSeat") then
						-- Teleport vehicle across highway stretch
						target = (target == ptA) and ptB or ptA
						car:SetPrimaryPartCFrame(target)

						-- Fire odometer telemetry packet
						fireRemote("Odometer", 4500)
						fireRemote("DataReceiver", { RPM = 4500, Speed = odoSpeed })
					else
						-- Fire simulated RPM update
						fireRemote("Odometer", 3800)
					end
				end)
				task.wait(1.5)
			end
		end)
	end

	------------------------------------------------
	-- 🎁 AUTO CLAIM HOURLY BOX & DAILY REWARDS
	------------------------------------------------
	local autoClaimActive = true
	task.spawn(function()
		while true do
			if autoClaimActive then
				pcall(function()
					fireRemote("Box", "Claim")
					fireRemote("PhoneJobSalary")
				end)
			end
			task.wait(30)
		end
	end)

	------------------------------------------------
	-- 🎨 BUILD FARM TAB UI
	------------------------------------------------
	local farmFrame = UI.tabs["Farm"].Frame

	-- Quick Status Card
	local statusSec = UI.AddSection(farmFrame, "Automated Money Farm (CDID Jobs)", 1)
	UI.AddLabel(statusSec, "Select a job below. Script will automate pickups, deliveries, and rewards.")

	-- 🏦 BCA Collaboration Event & Bank Courier
	local bcaSec = UI.AddSection(farmFrame, "🏦 BCA Collaboration Event & Bank Courier", 2)

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
									if (spotPos - targetPos).Magnitude < 80 then
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
	end, 6, "s")

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
				local root = exchangeNpc:FindFirstChild("HumanoidRootPart") or exchangeNpc:FindFirstChildWhichIsA("BasePart")
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

	-- SiLambat Courier
	local siLambatSec = UI.AddSection(farmFrame, "📦 SiLambat Express Delivery", 3)
	UI.AddToggle(siLambatSec, "Auto Farm SiLambat", Config.farm.siLambat, function(v)
		siLambatActive = v
		Config.farm.siLambat = v
		if v then
			UI.Notify("SiLambat Farm Active", "Starting automated parcel deliveries.", 3, "success")
			runSiLambatFarm()
		else
			UI.Notify("SiLambat Farm Stopped", "Farming paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	UI.AddSlider(siLambatSec, "Delivery Delay (Seconds)", 0.5, 5.0, siLambatDelay, function(v)
		siLambatDelay = v
		Config.farm.siLambatDelay = v
	end, 2, "s")

	-- Janji Jiwa Coffee Delivery
	local jjSec = UI.AddSection(farmFrame, "☕ Janji Jiwa Coffee Delivery", 3)
	UI.AddToggle(jjSec, "Auto Farm Janji Jiwa", Config.farm.janjiJiwa, function(v)
		janjiJiwaActive = v
		Config.farm.janjiJiwa = v
		if v then
			UI.Notify("Janji Jiwa Farm Active", "Starting coffee deliveries.", 3, "success")
			runJanjiJiwaFarm()
		else
			UI.Notify("Janji Jiwa Farm Stopped", "Farming paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	UI.AddSlider(jjSec, "Coffee Delay (Seconds)", 0.5, 5.0, janjiJiwaDelay, function(v)
		janjiJiwaDelay = v
		Config.farm.janjiJiwaDelay = v
	end, 2, "s")

	-- EMS / Hospital Medic
	local emsSec = UI.AddSection(farmFrame, "🚑 EMS Doctor / Ambulance", 4)
	UI.AddToggle(emsSec, "Auto Farm EMS Ambulance", Config.farm.ems, function(v)
		emsActive = v
		Config.farm.ems = v
		if v then
			UI.Notify("EMS Farm Active", "Starting paramedic auto heal.", 3, "success")
			runEmsFarm()
		else
			UI.Notify("EMS Farm Stopped", "Farming paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	-- Odometer Mileage Farm
	local odoSec = UI.AddSection(farmFrame, "🛣️ Odometer & Highway Mileage Farm", 5)
	UI.AddToggle(odoSec, "Auto Farm Mileage / Odometer", Config.farm.odometer, function(v)
		odometerActive = v
		Config.farm.odometer = v
		if v then
			UI.Notify("Mileage Farm Active", "Earning passive cash from driving simulation.", 3, "success")
			runOdometerFarm()
		else
			UI.Notify("Mileage Farm Stopped", "Mileage farm paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	UI.AddSlider(odoSec, "Simulated Speed", 60, 250, odoSpeed, function(v)
		odoSpeed = v
		Config.farm.odometerSpeed = v
	end, 2, " km/h")

	-- Rewards & Claim Tools
	local claimSec = UI.AddSection(farmFrame, "🎁 Auto Claim Rewards", 6)
	UI.AddToggle(claimSec, "Auto Claim Hourly Box & Salary", true, function(v)
		autoClaimActive = v
	end, 1)

	UI.AddButton(claimSec, "Claim Hourly Reward Box Now", function()
		fireRemote("Box", "Claim")
		fireRemote("PhoneJobSalary")
		UI.Notify("Reward Claimed", "Attempted to claim free reward box & salary!", 2, "success")
	end, 2)

	-- Export global farm API
	_G.HipHubFarm = {
		SetSiLambat = function(v) siLambatActive = v end,
		SetJanjiJiwa = function(v) janjiJiwaActive = v end,
		SetEMS = function(v) emsActive = v end,
		SetOdometer = function(v) odometerActive = v end,
		ClaimRewards = function()
			fireRemote("Box", "Claim")
			fireRemote("PhoneJobSalary")
		end
	}
end)

if not success then
	warn("[HipHub CDID Farm Error]:", err)
end
