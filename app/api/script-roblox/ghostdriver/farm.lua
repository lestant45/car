-- HipHub Ghost Driver — Automation & Farm Engine (BAC-5513 Bypass Safe)
-- Implements Auto Race, Quest Automation, Speed Cruise, and Auto Buy Car

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer

	local UI = _G.HipHubUI
	local Config = _G.HipHubConfig or { farm = {} }
	local Settings = _G.HipHub_GhostDriver_Settings

	local Remotes = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Remotes"))
	local CarCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Menu"):WaitForChild("CarCatalog"))
	local HudTeleport = ReplicatedStorage:WaitForChild("HudTeleport", 15)
	local GetQuestsByScope = ReplicatedStorage:WaitForChild("GetQuestsByScope", 15)
	local ClaimQuestByScope = ReplicatedStorage:WaitForChild("ClaimQuestByScope", 15)

	local PurchaseCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("PurchaseCar", 15)
	local SpawnCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("SpawnCarEvent", 15)

	------------------------------------------------
	-- VEHICLE DETECTION HELPER
	------------------------------------------------
	local function getMyCar()
		if not player.Character then return nil end
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart and hum.SeatPart.Parent then
			return hum.SeatPart.Parent, hum.SeatPart
		end

		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and (child:GetAttribute("OwnerUserId") == player.UserId or child.Name:find(player.Name)) then
				local seat = child:FindFirstChild("DriveSeat")
				if seat then
					return child, seat
				end
			end
		end
		return nil, nil
	end

	local function ensureInCar()
		local car, seat = getMyCar()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end

		if car and seat then
			if not hum.Sit or hum.SeatPart ~= seat then
				seat:Sit(hum)
				task.wait(0.4)
			end
			return car, seat
		end

		local targetSpawn = Config.vehicle.selectedCar or "Wulfbrecht RZ7"
		if SpawnCarRemote then
			SpawnCarRemote:FireServer(targetSpawn)
			task.wait(1.5)
			car, seat = getMyCar()
			if car and seat and hum then
				seat:Sit(hum)
				task.wait(0.4)
				return car, seat
			end
		end

		return nil, nil
	end

	------------------------------------------------
	-- 🛡️ ANTI-CRASH & COLLISION CONTROLLER NEUTRALIZER
	------------------------------------------------
	-- The game simulates traffic crashes via custom client-side controllers:
	-- 1. TrafficImpactController: calculates SAT bounding-box intersections with TrafficFolder and violently pushes your car!
	-- 2. PoliceContactController: calculates contact against police cars and triggers PIT maneuver / bust!
	-- 3. CollisionController: triggers crash sound and sparks!
	local function neutralizeGameCollisions()
		pcall(function()
			local c = ReplicatedStorage:FindFirstChild("Controllers")
			if c then
				local TrafficImpact = c:FindFirstChild("TrafficImpactController")
				if TrafficImpact then
					local mod = require(TrafficImpact)
					if mod then
						-- Neutralize violent push impulse only (allows Near Miss & Close Call proximity sensors to still trigger!)
						mod.Push = function(self, ...) end
						-- Keep mod.Update, mod.sensors, mod.lastSeen intact so the game awards Near Miss streak!
					end
				end

				local PoliceContact = c:FindFirstChild("PoliceContactController")
				if PoliceContact then
					local mod = require(PoliceContact)
					if mod then
						mod.Update = function(self, ...) end
					end
				end

				local CollisionController = c:FindFirstChild("CollisionController")
				if CollisionController then
					local mod = require(CollisionController)
					if mod then
						mod.TriggerImpact = function(self, ...) end
					end
				end

				local uiFolder = c:FindFirstChild("UI")
				local ComboUI = uiFolder and uiFolder:FindFirstChild("ComboUIController")
				if ComboUI then
					local mod = require(ComboUI)
					if mod then
						if mod.TriggerCrashCheck then
							mod.TriggerCrashCheck = function(self, ...) return false end
						end
						if mod.ResetCombo then
							local origReset = mod.ResetCombo
							mod.ResetCombo = function(self, ...)
								if Config.farm.autoSpeedFarm or Config.farm.autoRace then return end
								return origReset(self, ...)
							end
						end
						local origLose = mod.LoseCombo
						mod.LoseCombo = function(self, reason, ...)
							-- Keep streak alive 100% while auto farm is running
							if Config.farm.autoSpeedFarm or Config.farm.autoRace then
								return
							end
							if origLose then return origLose(self, reason, ...) end
						end
						if mod.ResetComboState then
							local origResetState = mod.ResetComboState
							mod.ResetComboState = function(self, ...)
								if Config.farm.autoSpeedFarm or Config.farm.autoRace then
									return -- Block combo reset completely! Streak stays preserved!
								end
								return origResetState(self, ...)
							end
						end
						if mod.DrainAdrenaline then
							local origDrain = mod.DrainAdrenaline
							mod.DrainAdrenaline = function(self, dt, ...)
								if Config.farm.autoSpeedFarm or Config.farm.autoRace then
									self.adrenaline = 15.0 -- Lock adrenaline 100% full, combo streak NEVER expires!
								end
								return origDrain(self, dt, ...)
							end
						end
					end
				end
			end
		end)
	end

	-- Immediately neutralize on script execution
	neutralizeGameCollisions()

	------------------------------------------------
	-- 🏁 AUTO RACE & HIGHWAY ENGINE (ANTI-FLYOVER & NOCLIP)
	------------------------------------------------
	local isRacingNow = false

	-- Universal Ghost Noclip & Traffic Neutralizer: runs on Stepped (before physics solver)
	-- Disables solid collisions while preserving CanTouch & CanQuery for Near-Miss detection.
	local lastNeutralizeCheck = 0
	RunService.Stepped:Connect(function()
		local now = os.clock()
		if now - lastNeutralizeCheck > 2.0 then
			lastNeutralizeCheck = now
			neutralizeGameCollisions()
		end

		if player.Character then
			for _, cp in ipairs(player.Character:GetDescendants()) do
				if cp:IsA("BasePart") and cp.CanCollide and (cp.Name == "CollisionPart" or cp.Name:find("Hitbox") or cp.Name:find("Collision")) then
					cp.CanCollide = false
				end
			end
		end

		local myCar = getMyCar()

		-- 1. Disable collision on car body parts, preserving CanTouch and CanQuery for near-miss registration
		if myCar then
			for _, p in ipairs(myCar:GetDescendants()) do
				if p:IsA("BasePart") then
					if p.Name:find("TrafficCollision") or p.Name:find("Impact") or p.Name:find("Hitbox") then
						p.CanCollide = false
					elseif p.Name ~= "FL" and p.Name ~= "FR" and p.Name ~= "RL" and p.Name ~= "RR" and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end

		-- 2. Disable solid collisions on NPC Traffic vehicles in workspace.TrafficFolder
		-- CanTouch = true and CanQuery = true are preserved for Near Miss / Streak detection!
		local tf = workspace:FindFirstChild("TrafficFolder")
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				for _, p in ipairs(tCar:GetDescendants()) do
					if p:IsA("BasePart") and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end

		-- 3. Disable collision on all other player characters in game
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				for _, part in ipairs(p.Character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end

		-- 4. Disable collision on all other vehicles, AI racers, police, and models in workspace
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar then
				if obj:FindFirstChild("DriveSeat") or obj:FindFirstChild("A-Chassis Tune") or obj:FindFirstChild("Body") or obj:FindFirstChild("Wheels") or obj.Name:find("AI") or obj.Name:find("Police") or obj.Name:find("Traffic") or obj.Name:find("_") then
					for _, part in ipairs(obj:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end
		end
	end)

	------------------------------------------------
	-- 🛣️ 3-LANE HIGHWAY ROAD MARGIN SENSOR (MOBILE & REDFINGER OPTIMIZED)
	------------------------------------------------
	local function isRoadAt(testPos, rayParams)
		local hit = workspace:Raycast(testPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
		if hit then
			local instName = hit.Instance.Name:lower()
			if not (instName:find("wall") or instName:find("guard") or instName:find("rail") or instName:find("fence")) then
				return true, hit.Position.Y
			end
		end
		return false, nil
	end

	local function getRoadMargins(carPos, rightVec, rayParams)
		local leftClearance = 0
		for _, dist in ipairs({ 7, 13, 20, 28 }) do
			if isRoadAt(carPos - rightVec * dist, rayParams) then
				leftClearance = dist
			else
				break
			end
		end

		local rightClearance = 0
		for _, dist in ipairs({ 7, 13, 20, 28 }) do
			if isRoadAt(carPos + rightVec * dist, rayParams) then
				rightClearance = dist
			else
				break
			end
		end

		return leftClearance, rightClearance
	end

	------------------------------------------------
	-- 🛡️ SENSOR PEMBATAS JALAN REAL-TIME MULTI-LEVEL (BARRIER SENSOR)
	------------------------------------------------
	local function isBarrierPart(instance)
		if not instance or not instance:IsA("BasePart") then return false end
		local n = instance.Name:lower()
		local p = instance.Parent and instance.Parent.Name:lower() or ""
		local g = instance.Parent and instance.Parent.Parent and instance.Parent.Parent.Name:lower() or ""

		-- Abaikan jalanan / aspal / garis / checkpoint
		if n:find("road") or n:find("asphalt") or n:find("street") or n:find("ground") or n:find("lane") or n:find("start") or n:find("finish") or n:find("checkpoint") then
			return false
		end

		-- Deteksi pagar besi, guardrail, collision shield, tembok beton, tiang
		if n:find("wall") or n:find("fence") or n:find("shield") or n:find("guard") or n:find("rail")
			or n:find("holder") or n:find("barrier") or n:find("post") or n:find("pole") or n:find("curb")
			or p:find("fence") or p:find("wall") or p:find("guard") or p:find("barrier")
			or g:find("fence") or g:find("wall") then
			return true
		end

		if (instance.Material == Enum.Material.Concrete or instance.Material == Enum.Material.Plastic or instance.Material == Enum.Material.Rubber or instance.Material == Enum.Material.Metal) and instance.CanCollide then
			return true
		end

		return false
	end

	local function detectBarriers(carPos, rightVec, forwardDir, rayParams)
		local rayHeights = {-0.7, 0.2, 1.2}
		local maxRayDist = 32

		local fDir = forwardDir or Vector3.zero
		local diagR = (rightVec * 0.707 + fDir * 0.707).Unit
		local diagL = (-rightVec * 0.707 + fDir * 0.707).Unit

		-- 1. Deteksi pembatas kanan (Tembok Beton) - Samping 90° & Serong Depan 45°
		local hasRightBarrier = false
		local distR = 99
		for _, h in ipairs(rayHeights) do
			local origin = carPos + Vector3.new(0, h, 0)
			local hitR = workspace:Raycast(origin, rightVec * maxRayDist, rayParams)
			if hitR and isBarrierPart(hitR.Instance) then
				hasRightBarrier = true
				if hitR.Distance < distR then
					distR = hitR.Distance
				end
			end

			if forwardDir then
				local hitDiagR = workspace:Raycast(origin, diagR * maxRayDist, rayParams)
				if hitDiagR and isBarrierPart(hitDiagR.Instance) then
					hasRightBarrier = true
					local effDist = hitDiagR.Distance * 0.707
					if effDist < distR then
						distR = effDist
					end
				end
			end
		end

		-- 2. Deteksi pembatas kiri (Pagar Besi Biru / CollisionShield / Tiang) - Samping 90° & Serong Depan 45°
		local hasLeftBarrier = false
		local distL = 99
		for _, h in ipairs(rayHeights) do
			local origin = carPos + Vector3.new(0, h, 0)
			local hitL = workspace:Raycast(origin, -rightVec * maxRayDist, rayParams)
			if hitL and isBarrierPart(hitL.Instance) then
				hasLeftBarrier = true
				if hitL.Distance < distL then
					distL = hitL.Distance
				end
			end

			if forwardDir then
				local hitDiagL = workspace:Raycast(origin, diagL * maxRayDist, rayParams)
				if hitDiagL and isBarrierPart(hitDiagL.Instance) then
					hasLeftBarrier = true
					local effDist = hitDiagL.Distance * 0.707
					if effDist < distL then
						distL = effDist
					end
				end
			end
		end

		-- 3. 🛣️ ROAD-EDGE DOWNCAST SENSOR (Sensor Ujung Aspal Kiri & Kanan)
		-- Memeriksa apakah aspal masih ada di kiri/kanan pada jarak 6, 10, 14, 18 studs.
		-- Jika raycast menyentuh rumput (Grass), tebing, void, atau bukan jalan:
		-- Berarti posisi tersebut sudah berada di luar batas jalan!
		local checkOffsets = {6, 10, 14, 18}
		for _, off in ipairs(checkOffsets) do
			-- Cek tepi aspal kiri
			local probeL = carPos - rightVec * off + Vector3.new(0, 5, 0)
			local downL = workspace:Raycast(probeL, Vector3.new(0, -20, 0), rayParams)
			if not downL or downL.Position.Y < (carPos.Y - 4.5) or isBarrierPart(downL.Instance) or downL.Instance.Material == Enum.Material.Grass then
				hasLeftBarrier = true
				if off < distL then
					distL = off
				end
			end

			-- Cek tepi aspal kanan
			local probeR = carPos + rightVec * off + Vector3.new(0, 5, 0)
			local downR = workspace:Raycast(probeR, Vector3.new(0, -20, 0), rayParams)
			if not downR or downR.Position.Y < (carPos.Y - 4.5) or isBarrierPart(downR.Instance) or downR.Instance.Material == Enum.Material.Grass then
				hasRightBarrier = true
				if off < distR then
					distR = off
				end
			end
		end

		return hasLeftBarrier, hasRightBarrier, distL, distR
	end

	------------------------------------------------
	-- 🛣️ WAYPOINTS RESMI HIGHWAY & ROAD DIRECTION TRACKER
	------------------------------------------------
	------------------------------------------------
	-- 🛣️ FULL HIGHWAY CORRIDOR DUAL-LANE TRACK ENGINE (ANTI-OUT-OF-BOUNDS)
	------------------------------------------------
	-- Powered by 3,462 synchronized left & right lane boundaries
	-- Covers the complete 95,000-stud closed-loop highway circuit
	local Corridor = _G.HipHub_GhostDriver_Corridor or {}
	local cachedCorridorIdx = nil

	local function getCorridorRoadInfo(pos)
		local n = #Corridor
		if n == 0 then
			return pos, Vector3.new(0, 0, -1), 34.0, 1
		end

		-- 1. Initial 3D Search or Recovery
		if not cachedCorridorIdx then
			local bestDistSq = math.huge
			local bestIdx = 1
			for idx = 1, n, 4 do
				local pt = Corridor[idx]
				local dx = pos.X - pt[1]
				local dy = (pos.Y - pt[2]) * 1.5
				local dz = pos.Z - pt[3]
				local dSq = dx * dx + dy * dy + dz * dz
				if dSq < bestDistSq then
					bestDistSq = dSq
					bestIdx = idx
				end
			end
			local fineStart = math.max(1, bestIdx - 8)
			local fineEnd = math.min(n, bestIdx + 8)
			for idx = fineStart, fineEnd do
				local pt = Corridor[idx]
				local dx = pos.X - pt[1]
				local dy = (pos.Y - pt[2]) * 1.5
				local dz = pos.Z - pt[3]
				local dSq = dx * dx + dy * dy + dz * dz
				if dSq < bestDistSq then
					bestDistSq = dSq
					bestIdx = idx
				end
			end
			cachedCorridorIdx = bestIdx
		end

		-- 2. Monotonic Forward Search (Prevents Backward Flipping & Flyover Crosstalk)
		local bestIdx = cachedCorridorIdx
		local bestDistSq = math.huge

		for offset = -1, 10 do
			local idx = ((cachedCorridorIdx - 1 + offset) % n) + 1
			local pt = Corridor[idx]
			local dx = pos.X - pt[1]
			local dy = (pos.Y - pt[2]) * 1.5
			local dz = pos.Z - pt[3]
			local dSq = dx * dx + dy * dy + dz * dz
			if dSq < bestDistSq then
				bestDistSq = dSq
				bestIdx = idx
			end
		end

		-- Fallback global search if teleported or drifted > 250 studs away
		if bestDistSq > 62500 then
			cachedCorridorIdx = nil
			return getCorridorRoadInfo(pos)
		end

		cachedCorridorIdx = bestIdx

		local pA = Corridor[bestIdx]
		local nextIdx = (bestIdx % n) + 1
		local pB = Corridor[nextIdx]

		local segX = pB[1] - pA[1]
		local segY = pB[2] - pA[2]
		local segZ = pB[3] - pA[3]
		local segLenHoriz = math.sqrt(segX * segX + segZ * segZ)
		local dirX = segLenHoriz > 0.001 and (segX / segLenHoriz) or 0
		local dirZ = segLenHoriz > 0.001 and (segZ / segLenHoriz) or -1
		local roadForward = Vector3.new(dirX, 0, dirZ)

		-- Segment projection
		local vx = pos.X - pA[1]
		local vz = pos.Z - pA[3]
		local proj = vx * dirX + vz * dirZ

		-- Advance to next waypoint as soon as segment is traversed
		if proj >= (segLenHoriz - 2.0) and segLenHoriz > 0.001 then
			cachedCorridorIdx = nextIdx
		end

		local t = math.clamp(proj, 0, segLenHoriz)
		local frac = segLenHoriz > 0.001 and (t / segLenHoriz) or 0

		local roadCenterX = pA[1] + dirX * t
		local roadCenterY = pA[2] + segY * frac
		local roadCenterZ = pA[3] + dirZ * t
		local roadWidth = pA[4] or 34.0

		return Vector3.new(roadCenterX, roadCenterY, roadCenterZ), roadForward, roadWidth, bestIdx
	end

	------------------------------------------------
	-- 🎯 SMART 3-LANE TRAFFIC OVERTAKE & NEAR-MISS STREAK ENGINE
	------------------------------------------------
	-- Dynamically evaluates Left Lane (-8.5 studs), Center Lane (0.0 studs), and Right Lane (+8.5 studs).
	-- Eliminates the center-car collision bug completely!
	-- Maintains a clean 2.0 - 2.5 stud open-air gap between vehicles, triggering Near Miss and
	-- Close Call proximity sensors 100% reliably with ZERO bounding box overlap or crash impact!
	local currentSlideOffset = 0.0
	local targetSlideOffset = 0.0

	local function calculateSmartTrafficDodge(carPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
		local tf = workspace:FindFirstChild("TrafficFolder")
		local obstacles = {}

		local halfWidth = (roadWidth or 34.0) * 0.5
		local minLateral = -halfWidth + 3.8
		local maxLateral = halfWidth - 3.8

		-- Standard highway lane offset: 8.5 studs
		-- Clamped dynamically on narrower roads/bridges so car never gets closer than 4.2 studs to barriers
		local laneOffset = math.clamp(8.5, 5.0, halfWidth - 4.2)

		-- 1. Kumpulkan semua mobil NPC dari TrafficFolder
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				if tCar:IsA("Model") then
					local pivot = tCar:GetPivot()
					table.insert(obstacles, pivot.Position)
				end
			end
		end

		-- 2. Kumpulkan kendaraan lain (Police, AI racers, player lain)
		local myCar = getMyCar()
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar and obj ~= player.Character then
				if obj:FindFirstChild("DriveSeat") or obj.Name:find("Police") or obj.Name:find("AI") then
					local pivot = obj:GetPivot()
					table.insert(obstacles, pivot.Position)
				end
			end
		end

		-- 3. Evaluasi skor bahaya untuk 3 lajur jalan:
		-- -1: Lajur Kiri  (-laneOffset, sekitar -8.5 studs)
		--  0: Lajur Tengah (0.0 studs)
		--  1: Lajur Kanan (+laneOffset, sekitar +8.5 studs)
		local laneDanger = {
			[-1] = 0,
			[0]  = 0,
			[1]  = 0
		}

		local minAheadDist = 999.0
		local totalThreatsCount = 0

		for _, obsPos in ipairs(obstacles) do
			local delta = obsPos - roadCenter
			local fDist = delta:Dot(forwardDir)
			local obsLateral = delta:Dot(rightVec)

			-- Periksa semua kendaraan di zona aktif: dari -16.0 studs (samping/belakang bumper)
			-- sampai 140.0 studs (jauh di depan)
			if fDist >= -16.0 and fDist <= 140.0 and math.abs(obsLateral) <= (halfWidth + 3.0) then
				totalThreatsCount = totalThreatsCount + 1

				if fDist > 0 and fDist < minAheadDist then
					minAheadDist = fDist
				end

				-- Bobot urgensi: mobil yang berdampingan atau dekat di depan punya urgensi tertinggi
				local urgency
				if fDist <= 16.0 then
					urgency = 10000.0 -- Mobil sedang sejajar / nempel di samping! DILARANG KERAS MASUK LAJUR INI!
				else
					urgency = (140.0 - fDist) * 15.0 -- Semakin dekat jaraknya, semakin tinggi bahaya lajurnya
				end

				-- Periksa konflik terhadap masing-masing lajur
				for _, laneCode in ipairs({-1, 0, 1}) do
					local laneLat = laneCode * laneOffset
					local latDiff = math.abs(laneLat - obsLateral)

					-- Mobil NPC menutup lajur ini jika jarak lateral < 5.8 studs
					if latDiff < 5.8 then
						laneDanger[laneCode] = laneDanger[laneCode] + urgency
					elseif latDiff < 7.2 then
						-- Agak mepet, beri penalti moderat
						laneDanger[laneCode] = laneDanger[laneCode] + urgency * 0.35
					end
				end
			end
		end

		-- 4. Hysteresis / Stabilitas Lajur: Prioritaskan lajur yang sedang dilalui agar tidak goyang bolak-balik
		local currentLane = 0
		if currentSlideOffset < -laneOffset * 0.35 then
			currentLane = -1
		elseif currentSlideOffset > laneOffset * 0.35 then
			currentLane = 1
		end
		laneDanger[currentLane] = laneDanger[currentLane] - 25.0

		-- Jika jalanan sepi tanpa mobil sama sekali, arahkan santai ke tengah jalan
		if totalThreatsCount == 0 then
			laneDanger[0] = laneDanger[0] - 35.0
		end

		-- 5. Pilih lajur dengan tingkat bahaya paling rendah (Paling Aman, Bersih & Memicu Near Miss)
		local bestLane = 0
		local lowestDanger = math.huge
		for _, laneCode in ipairs({-1, 0, 1}) do
			if laneDanger[laneCode] < lowestDanger then
				lowestDanger = laneDanger[laneCode]
				bestLane = laneCode
			end
		end

		targetSlideOffset = bestLane * laneOffset
		targetSlideOffset = math.clamp(targetSlideOffset, minLateral, maxLateral)

		-- 6. Dynamic Steering Speed: Responsif saat mendeteksi mobil di depan
		local steerSpeed = 26.0
		if minAheadDist < 50.0 then
			steerSpeed = 40.0
		elseif minAheadDist < 80.0 then
			steerSpeed = 32.0
		end

		local diff = targetSlideOffset - currentSlideOffset
		local maxStep = steerSpeed * dt
		currentSlideOffset = currentSlideOffset + math.clamp(diff, -maxStep, maxStep)
		currentSlideOffset = math.clamp(currentSlideOffset, minLateral, maxLateral)

		return currentSlideOffset
	end

	task.spawn(function()
		while true do
			task.wait(1.5)
			if Config.farm.autoRace and not isRacingNow then
				-- 1. Spawn mobil yang dipilih di tab vehicle
				local targetCar = (Config.vehicle and Config.vehicle.selectedCar) or "Wulfbrecht RZ7"
				local car, seat = getMyCar()
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

				if not car or not car.Name:find(targetCar) then
					if SpawnCarRemote then
						SpawnCarRemote:FireServer(targetCar)
						local spawnT0 = os.clock()
						while (os.clock() - spawnT0) < 4 do
							task.wait(0.3)
							car, seat = getMyCar()
							if car and seat then break end
						end
					end
				end

				car, seat = getMyCar()
				hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

				if car and seat and hum then
					isRacingNow = true
					pcall(function()
						-- 2. Naiki mobil lalu teleport ke buletan buat join race
						if not hum.Sit or hum.SeatPart ~= seat then
							seat:Sit(hum)
							task.wait(0.4)
						end

						local pad = workspace:FindFirstChild("RaceSystem") and workspace.RaceSystem:FindFirstChild("RacePad")
						if not pad and HudTeleport then
							HudTeleport:FireServer("HighwayRace")
							task.wait(2.0)
							pad = workspace:FindFirstChild("RaceSystem") and workspace.RaceSystem:FindFirstChild("RacePad")
						end

						if pad and car then
							car:PivotTo(pad.CFrame + Vector3.new(0, 3, 0))
							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
								seat.AssemblyAngularVelocity = Vector3.zero
							end
							task.wait(1.0)
						end

						-- 3. Race with AI
						local diff = Config.farm.raceDifficulty or "Hard"
						Remotes.RaceSoloPick:FireServer(diff)
						if UI and UI.Notify then
							UI.Notify("Auto Race", "Joining " .. diff .. " race! Highway Corridor Active...", 2, "info")
						end

						local started = false
						local finished = false
						local finishResult = nil

						local conn
						conn = Remotes.RaceEvent.OnClientEvent:Connect(function(action, data)
							if action == "StartRaceTimer" then
								started = true
							elseif action == "Finish" then
								finished = true
								finishResult = data
							elseif action == "Abort" then
								finished = true
							end
						end)

						local waitStart = os.clock()
						while not started and not finished and (os.clock() - waitStart) < 25 do
							local curP = car:GetPivot().Position
							if curP.Z < -1000 and curP.Y < 80 then
								car:PivotTo(CFrame.new(-3499.8, 63.4, curP.Z) * CFrame.Angles(0, math.rad(180), 0))
								if seat and seat:IsA("BasePart") then
									seat.AssemblyLinearVelocity = Vector3.zero
									seat.AssemblyAngularVelocity = Vector3.zero
								end
							end
							task.wait(0.2)
						end

						if started and not finished then
							-- 🏁 COUNTDOWN SELESAI: GAS MAJU MENGIKUTI CORRIDOR
							local curP = car:GetPivot().Position
							car:PivotTo(CFrame.new(-3499.8, 63.4, curP.Z) * CFrame.Angles(0, math.rad(180), 0))
							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
								seat.AssemblyAngularVelocity = Vector3.zero
							end
							currentSlideOffset = 0
							targetSlideOffset = 0
							task.wait(0.15)

							local cruiseMPH = Config.farm.raceSpeed or 70
							local targetStudsSec = cruiseMPH * 1.760

							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {player.Character, car}

							local heartbeatConn
							local lastTick = os.clock()

							heartbeatConn = RunService.Heartbeat:Connect(function()
								if not isRacingNow or finished or not seat or not car or not seat.Parent then return end

								local now = os.clock()
								local dt = math.clamp(now - lastTick, 0.005, 0.07)
								lastTick = now

								local currentPos = car:GetPivot().Position
								local roadCenter, forwardDir, roadWidth = getCorridorRoadInfo(currentPos)
								local rightVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X).Unit

								-- 1. Deteksi permukaan jalan tepat di bawah mobil (mengikuti elevasi 3D flyover/bridge)
								local probeOrigin = Vector3.new(currentPos.X, roadCenter.Y + 6, currentPos.Z)
								local downHit = workspace:Raycast(probeOrigin, Vector3.new(0, -18, 0), rayParams)
								local roadY = (downHit and math.abs(downHit.Position.Y - roadCenter.Y) < 6) and downHit.Position.Y or roadCenter.Y

								-- 2. Dapatkan offset lateral dari Near-Miss Overtake Engine
								local lateralOffset = 0
								if Config.farm.autoDodgeTraffic ~= false then
									lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
								end

								-- 3. Kunci posisi: roadCenter + forwardDir * stepDist + rightVec * lateralOffset
								local stepDist = targetStudsSec * dt
								local nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset

								-- 4. Kunci orientasi mobil 100% tegak lurus sejajar jalan
								local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, roadY + 2.0, nextPos.Z), Vector3.new(nextPos.X + forwardDir.X * 10, roadY + 2.0, nextPos.Z + forwardDir.Z * 10))
								car:PivotTo(targetCF)

								-- 5. Dorong dengan kecepatan penuh stabil
								seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, (roadY + 2.0 - currentPos.Y) * 6, 0)
								seat.AssemblyAngularVelocity = Vector3.zero
								if seat:IsA("VehicleSeat") then
									seat.ThrottleFloat = 1.0
									seat.Throttle = 1
								end
							end)

							-- Tunggu sampai server konfirmasi event Finish (timeout 80 detik)
							local waitFinish = os.clock()
							while not finished and (os.clock() - waitFinish) < 80 do
								task.wait(0.1)
							end

							if heartbeatConn then
								heartbeatConn:Disconnect()
							end

							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
							end

							if finishResult and UI and UI.Notify then
								local earned = finishResult.reward or 0
								local place = finishResult.placement or "FINISHED"
								UI.Notify("Race Finished", place .. " | Cash: +$" .. tostring(earned), 4, "success")
							end
						end

						if conn then conn:Disconnect() end
					end)

					isRacingNow = false
					task.wait(Config.farm.raceDelay or 2.0)
				end
			end
		end
	end)

	------------------------------------------------
	-- 📋 AUTO QUEST CLAIMER
	------------------------------------------------
	task.spawn(function()
		while true do
			task.wait(Config.farm.claimInterval or 4)
			if Config.farm.autoClaimQuests and GetQuestsByScope and ClaimQuestByScope then
				pcall(function()
					for _, scope in ipairs({ "Daily", "Weekly" }) do
						local data = GetQuestsByScope:InvokeServer(scope)
						if data and data.Quests then
							for i, q in ipairs(data.Quests) do
								if not q.Claimed and q.Progress >= q.Max then
									local res = ClaimQuestByScope:InvokeServer(scope, i)
									if res and UI and UI.Notify then
										UI.Notify("Quest Claimed", "Claimed " .. scope .. " Quest " .. tostring(i) .. " (+$" .. tostring(q.Reward) .. ")", 3, "success")
									end
									task.wait(0.4)
								end
							end
						end
					end
				end)
			end
		end
	end)

	------------------------------------------------
	-- ⚡ AUTO SPEED & 24/7 ENDLESS HIGHWAY CRUISE (NEAR-MISS STREAK FARM)
	------------------------------------------------
	task.spawn(function()
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local lastTick = os.clock()

		while true do
			task.wait(0.015)
			if Config.farm.autoSpeedFarm and not isRacingNow then
				local car, seat = getMyCar()
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if car and seat and hum and hum.Sit then
					local now = os.clock()
					local dt = math.clamp(now - lastTick, 0.005, 0.05)
					lastTick = now

					rayParams.FilterDescendantsInstances = {player.Character, car}

					local currentPos = car:GetPivot().Position

					-- 1. Ambil info koridor lintasan (centerline, arah forward, lebar jalan)
					local roadCenter, forwardDir, roadWidth = getCorridorRoadInfo(currentPos)
					local rightVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X).Unit

					-- 2. Deteksi permukaan jalan tepat di bawah mobil (mengikuti elevasi 3D flyover/bridge)
					local probeOrigin = Vector3.new(currentPos.X, roadCenter.Y + 6, currentPos.Z)
					local downHit = workspace:Raycast(probeOrigin, Vector3.new(0, -18, 0), rayParams)
					local roadY = (downHit and math.abs(downHit.Position.Y - roadCenter.Y) < 6) and downHit.Position.Y or roadCenter.Y

					-- 3. Hitung manuver nyalip mobil NPC untuk memicu Near Miss streak
					local lateralOffset = 0
					if Config.farm.autoDodgeTraffic ~= false then
						lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
					end

					-- 4. Kunci posisi: roadCenter + stepDist + lateralOffset (100% di dalam aspal)
					local targetMPH = Config.farm.targetSpeed or 70
					local targetStudsSec = targetMPH * 1.760
					local stepDist = targetStudsSec * dt
					local nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset

					-- 5. Kunci orientasi mobil 100% tegak lurus sejajar jalan
					local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, roadY + 2.0, nextPos.Z), Vector3.new(nextPos.X + forwardDir.X * 10, roadY + 2.0, nextPos.Z + forwardDir.Z * 10))
					car:PivotTo(targetCF)

					-- 6. Dorong dengan kecepatan target konstan + Gas Pedal On
					seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, (roadY + 2.0 - currentPos.Y) * 6, 0)
					seat.AssemblyAngularVelocity = Vector3.zero
					if seat:IsA("VehicleSeat") then
						seat.ThrottleFloat = 1.0
						seat.Throttle = 1
					end
				else
					lastTick = os.clock()
				end
			else
				lastTick = os.clock()
			end
		end
	end)

	------------------------------------------------
	-- 🚗 AUTO BUY CAR
	------------------------------------------------
	task.spawn(function()
		while true do
			task.wait(3)
			if Config.farm.autoBuyCar and PurchaseCarRemote then
				pcall(function()
					local targetName = Config.farm.targetCarToBuy
					if targetName and targetName ~= "" then
						local price = nil
						for _, c in ipairs(CarCatalog.Cars) do
							if c.Name == targetName then
								price = c.Price
								break
							end
						end

						if price and price > 0 then
							local currentCash = player.leaderstats and player.leaderstats:FindFirstChild("Cash") and player.leaderstats.Cash.Value or 0
							if currentCash >= price then
								local success, errCode = PurchaseCarRemote:InvokeServer(targetName)
								if success then
									Config.farm.autoBuyCar = false
									if Settings then Settings.Save() end
									if UI and UI.Notify then
										UI.Notify("Dealership", "Congratulations! Purchased " .. targetName .. " for $" .. tostring(price) .. "!", 6, "success")
									end
								end
							end
						end
					end
				end)
			end
		end
	end)

	_G.HipHub_GhostDriver_Farm = {
		GetMyCar = getMyCar,
		EnsureInCar = ensureInCar,
		IsRacing = function() return isRacingNow end
	}
end)

if not success then
	warn("[HipHub Ghost Driver Farm Error]:", err)
end
