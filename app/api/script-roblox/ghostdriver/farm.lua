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
						mod.Push = function(self, ...) end
						mod.Update = function(self, ...) end
						mod.BindVehicle = function(self, ...) end
						mod.footprint = nil
						if mod.roots then table.clear(mod.roots) end
						if mod.sensors then table.clear(mod.sensors) end
						if mod.touching then table.clear(mod.touching) end
						if mod.lastSeen then table.clear(mod.lastSeen) end
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
						mod.Update = function(self, ...) end
						mod.BindVehicle = function(self, ...) end
						if mod.activeBoxes then table.clear(mod.activeBoxes) end
					end
				end

				local uiFolder = c:FindFirstChild("UI")
				local ComboUI = uiFolder and uiFolder:FindFirstChild("ComboUIController")
				if ComboUI then
					local mod = require(ComboUI)
					if mod then
						mod.TriggerCrashCheck = function(self, ...) end
						local origLose = mod.LoseCombo
						mod.LoseCombo = function(self, reason, ...)
							if type(reason) == "string" and (reason:find("CRASH") or reason:find("0X")) then
								return
							end
							if origLose then return origLose(self, reason, ...) end
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
	-- Completely eliminates collisions with NPC traffic cars, AI racers, police, and players
	local lastNeutralizeCheck = 0
	RunService.Stepped:Connect(function()
		local now = os.clock()
		if now - lastNeutralizeCheck > 2.0 then
			lastNeutralizeCheck = now
			neutralizeGameCollisions()
		end

		local myCar = getMyCar()

		-- 1. Disable collision, touch, and query on all non-wheel parts & sensors of our own car
		-- (Never rename parts to preserve server replication integrity)
		if myCar then
			for _, p in ipairs(myCar:GetDescendants()) do
				if p:IsA("BasePart") then
					if p.Name:find("TrafficCollision") or p.Name:find("Impact") or p.Name:find("Hitbox") then
						p.CanCollide = false
						p.CanTouch = false
						p.CanQuery = false
					elseif p.Name ~= "FL" and p.Name ~= "FR" and p.Name ~= "RL" and p.Name ~= "RR" and p.CanCollide then
						p.CanCollide = false
					end
				end
			end
		end

		-- 2. Disable collision, touch & queries on all NPC Traffic vehicles in workspace.TrafficFolder
		local tf = workspace:FindFirstChild("TrafficFolder")
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				for _, p in ipairs(tCar:GetDescendants()) do
					if p:IsA("BasePart") then
						if p.CanCollide then p.CanCollide = false end
						if p.CanTouch then p.CanTouch = false end
						if p.CanQuery then p.CanQuery = false end
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
		if hit and hit.Position.Y <= 95 then
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
	local highwayWaypoints = {
		Vector3.new(-3499.8, 63.4, -1882.2), -- Posisi awal tengah jalur
		Vector3.new(-3499.8, 62.2, -2300.0), -- Jalan tol tengah
		Vector3.new(-3499.8, 62.2, -2900.0), -- Jalan tol tengah
		Vector3.new(-3499.8, 62.2, -3500.0), -- Menuju Checkpoint 6
		Vector3.new(-3505.0, 79.4, -3922.6), -- Checkpoint 6 tengah
		Vector3.new(-3516.0, 62.2, -4128.2), -- Checkpoint 7 tengah
		Vector3.new(-3530.0, 61.3, -4459.7), -- Checkpoint 8 tengah
		Vector3.new(-3555.0, 61.3, -4829.8), -- Checkpoint 9 tengah
		Vector3.new(-3595.0, 61.3, -5242.1), -- Checkpoint 10 tengah
		Vector3.new(-3660.0, 61.3, -5714.0), -- Checkpoint 11 tengah
		Vector3.new(-3760.0, 61.5, -6322.1), -- Checkpoint 12 tengah
		Vector3.new(-3820.0, 61.5, -6600.0), -- Tikungan highway 1
		Vector3.new(-4070.0, 61.5, -7606.0), -- Tikungan highway 2
		Vector3.new(-4389.0, 62.2, -8593.0), -- Tikungan highway 3
		Vector3.new(-4580.0, 62.2, -9070.0), -- Tikungan highway 3.5
		Vector3.new(-4776.0, 62.2, -9555.0), -- Tikungan highway 4 (Awal 56% Progress)
		Vector3.new(-4980.0, 62.2, -9950.0), -- Tikungan highway 4.3 (Halus Kurva 56%)
		Vector3.new(-5210.0, 62.2, -10350.0),-- Tikungan highway 4.6 (Halus Kurva 56%)
		Vector3.new(-5451.0, 62.2, -10750.0),-- Highway strip 5
		Vector3.new(-5850.0, 62.2, -11350.0),-- Highway strip 5.5
		Vector3.new(-6301.0, 62.2, -12000.0),-- Highway strip 6
		Vector3.new(-6780.0, 72.0, -12650.0),-- Highway strip 6.5
		Vector3.new(-7300.0, 81.6, -13300.0),-- Highway strip 7
		Vector3.new(-7820.0, 72.0, -13900.0),-- Highway strip 7.5
		Vector3.new(-8382.0, 62.2, -14500.0),-- Menuju garis finish
		Vector3.new(-9742.0, 62.2, -15626.9),-- RaceFinishLine
		Vector3.new(-10200.0, 62.2, -16000.0),-- Tembus garis finish +450 studs
		Vector3.new(-10800.0, 62.2, -16500.0) -- Tembus garis finish +1000 studs
	}

	local function getClosestRoadInfo(pos)
		local bestDist = math.huge
		local bestCenter = nil
		local bestDir = nil

		for i = 1, #highwayWaypoints - 1 do
			local p0 = highwayWaypoints[i]
			local p1 = highwayWaypoints[i + 1]
			local segVec = p1 - p0
			local segDir = Vector3.new(segVec.X, 0, segVec.Z).Unit
			local segLen = (Vector2.new(p1.X, p1.Z) - Vector2.new(p0.X, p0.Z)).Magnitude

			local v = pos - p0
			local proj = v:Dot(segDir)
			local clampedProj = math.clamp(proj, 0, segLen)
			local closestPoint = p0 + segDir * clampedProj
			local dist = (Vector2.new(pos.X, pos.Z) - Vector2.new(closestPoint.X, closestPoint.Z)).Magnitude

			if dist < bestDist then
				bestDist = dist
				bestDir = segDir
				bestCenter = closestPoint
			end
		end

		if bestDist < 120 and bestCenter and bestDir then
			return bestCenter, bestDir
		end
		return nil, nil
	end

	------------------------------------------------
	-- 🎯 3-LANE SMART TRAFFIC DODGE & OVERTAKE ENGINE
	------------------------------------------------
	-- Highway 3-Jalur (Left: -7.5 studs, Center: 0.0 studs, Right: +7.5 studs)
	-- Menganalisis seluruh kendaraan di depan dalam jarak 220 studs.
	-- Memilih jalur teraman dan paling lapang, serta menghindari kendaraan NPC secara otomatis.
	-- Memberikan bonus Near-Miss & Close-Shave secara konsisten tanpa risiko tabrakan!
	local currentSlideOffset = 0.0    -- Offset lateral saat ini (-7.8 s/d +7.8 studs)
	local targetSlideOffset = 0.0     -- Offset target (-7.5, 0.0, atau +7.5)
	local currentLaneChoice = 0       -- -1 = Kiri, 0 = Tengah, 1 = Kanan

	local LANE_OFFSETS = {
		[-1] = -7.5, -- Jalur Kiri
		[0]  =  0.0, -- Jalur Tengah (Default)
		[1]  =  7.5  -- Jalur Kanan
	}
	local MAX_ROAD_OFFSET = 7.8

	local function calculateSmartTrafficDodge(carPos, forwardDir, rightVec, roadCenter, dt)
		local tf = workspace:FindFirstChild("TrafficFolder")
		local obstacles = {}

		-- 1. Kumpulkan semua mobil NPC dari TrafficFolder
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				if tCar:IsA("Model") then
					local pivot = tCar:GetPivot()
					table.insert(obstacles, {
						model = tCar,
						pos = pivot.Position
					})
				end
			end
		end

		-- 2. Kumpulkan kendaraan lain (Police, AI racers, player lain)
		local myCar = getMyCar()
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar and obj ~= player.Character then
				if obj:FindFirstChild("DriveSeat") or obj.Name:find("Police") or obj.Name:find("AI") then
					local pivot = obj:GetPivot()
					table.insert(obstacles, {
						model = obj,
						pos = pivot.Position
					})
				end
			end
		end

		-- 3. Analisis okupansi rintangan per lajur
		-- Lane -1 (Left), Lane 0 (Center), Lane 1 (Right)
		local laneMinDist = {
			[-1] = 999.0,
			[0]  = 999.0,
			[1]  = 999.0
		}
		local laneSideBlocked = {
			[-1] = false,
			[0]  = false,
			[1]  = false
		}

		local centerRef = roadCenter or carPos
		local nearestThreatDist = 999.0

		for _, obs in ipairs(obstacles) do
			local delta = obs.pos - carPos
			local fDist = delta:Dot(forwardDir)

			-- Hanya periksa objek di koridor highway depan & samping (-8 s/d 220 studs)
			if fDist >= -8.0 and fDist <= 220.0 then
				local deltaCenter = obs.pos - centerRef
				local obsLateral = deltaCenter:Dot(rightVec)

				-- Pastikan berada dalam rentang badan jalan (-16 s/d +16 studs)
				if math.abs(obsLateral) <= 16.0 then
					-- Tentukan lajur yang terhalang oleh rintangan
					-- Karena mobil NPC memiliki lebar ~6.5 studs, periksa overlap
					local blocksLeft   = (obsLateral < -3.2)
					local blocksCenter = (obsLateral >= -5.5 and obsLateral <= 5.5)
					local blocksRight  = (obsLateral > 3.2)

					if blocksLeft then
						if fDist >= 0 and fDist < laneMinDist[-1] then
							laneMinDist[-1] = fDist
						end
						if fDist >= -8.0 and fDist <= 15.0 then
							laneSideBlocked[-1] = true
						end
					end

					if blocksCenter then
						if fDist >= 0 and fDist < laneMinDist[0] then
							laneMinDist[0] = fDist
						end
						if fDist >= -8.0 and fDist <= 15.0 then
							laneSideBlocked[0] = true
						end
					end

					if blocksRight then
						if fDist >= 0 and fDist < laneMinDist[1] then
							laneMinDist[1] = fDist
						end
						if fDist >= -8.0 and fDist <= 15.0 then
							laneSideBlocked[1] = true
						end
					end

					-- Catat ancaman langsung di jalur kita saat ini
					local myLateralDiff = math.abs(obsLateral - currentSlideOffset)
					if myLateralDiff < 4.5 and fDist >= 0 and fDist < nearestThreatDist then
						nearestThreatDist = fDist
					end
				end
			end
		end

		-- 4. Logika Pemilihan Jalur (Hierarchical Lane Decision)
		-- Cek apakah jalur yang kita pilih saat ini aman
		local SAFE_CLEARANCE = 140.0   -- Jarak minimal untuk merasa aman di lajur saat ini
		local currentIsSafe = (laneMinDist[currentLaneChoice] > SAFE_CLEARANCE) and not laneSideBlocked[currentLaneChoice]

		if not currentIsSafe then
			-- Jalur saat ini terhalang! Evaluasi semua opsi jalur:
			local bestLane = currentLaneChoice
			local bestScore = -999999

			for _, laneIdx in ipairs({ 0, -1, 1 }) do
				if not laneSideBlocked[laneIdx] then
					local dist = laneMinDist[laneIdx]
					local score = dist

					-- Jalur tengah sedikit lebih disukai jika benar-benar kosong
					if laneIdx == 0 and dist > 160.0 then
						score = score + 20.0
					end

					-- Preferensi tidak berpindah 2 lajur sekaligus jika lajur tengah bisa dipakai
					if math.abs(laneIdx - currentLaneChoice) == 1 then
						score = score + 10.0
					end

					if score > bestScore then
						bestScore = score
						bestLane = laneIdx
					end
				end
			end

			currentLaneChoice = bestLane
		else
			-- Jalur saat ini aman:
			-- Jika kita berada di pinggir (Kiri / Kanan), kembali ke Tengah HANYA JIKA Tengah benar-benar lowong
			if currentLaneChoice ~= 0 then
				if laneMinDist[0] > 180.0 and not laneSideBlocked[0] then
					currentLaneChoice = 0
				end
			end
		end

		targetSlideOffset = LANE_OFFSETS[currentLaneChoice] or 0.0
		targetSlideOffset = math.clamp(targetSlideOffset, -MAX_ROAD_OFFSET, MAX_ROAD_OFFSET)

		-- 5. Dynamic Steering / Strafe Speed:
		-- Jika ada rintangan mendadak di depan (< 50 studs), percepat manuver dodge!
		local dynamicSpeed = 26.0
		if nearestThreatDist < 50.0 then
			dynamicSpeed = 40.0
		elseif nearestThreatDist < 80.0 then
			dynamicSpeed = 32.0
		end

		local diff = targetSlideOffset - currentSlideOffset
		local maxStep = dynamicSpeed * dt
		local slideStep = math.clamp(diff, -maxStep, maxStep)
		currentSlideOffset = currentSlideOffset + slideStep
		currentSlideOffset = math.clamp(currentSlideOffset, -MAX_ROAD_OFFSET, MAX_ROAD_OFFSET)

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
							UI.Notify("Auto Race", "Joining " .. diff .. " race! Staying strictly on lower highway...", 2, "info")
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
							-- Selama countdown 3 detik, posisikan mobil stabil di tengah jalur (X = -3499.8, Y = 63.4)
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
							-- 🏁 COUNTDOWN 3 DETIK SELESAI!
							-- Posisikan mobil tepat di posisi awal tengah jalur (X = -3499.8, Y = 63.4) sebelum gas ke depan!
							local curP = car:GetPivot().Position
							car:PivotTo(CFrame.new(-3499.8, 63.4, curP.Z) * CFrame.Angles(0, math.rad(180), 0))
							if seat and seat:IsA("BasePart") then
								seat.AssemblyLinearVelocity = Vector3.zero
								seat.AssemblyAngularVelocity = Vector3.zero
							end
							currentLaneChoice = 0
							currentSlideOffset = 0
							targetSlideOffset = 0
							task.wait(0.15)

							local currentWpIndex = 1
							local cruiseMPH = 100
							local targetStudsSec = cruiseMPH * 1.760

							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {player.Character, car}

							-- Real-time road corridor tracking & 100% straight driving loop with lateral dodge
							local heartbeatConn
							local lastTick = os.clock()

							heartbeatConn = RunService.Heartbeat:Connect(function()
								if not isRacingNow or finished or not seat or not car or not seat.Parent then return end

								local now = os.clock()
								local dt = math.clamp(now - lastTick, 0.005, 0.07)
								lastTick = now

								local currentPos = car:GetPivot().Position
								local pA = highwayWaypoints[currentWpIndex]
								local pB = highwayWaypoints[math.min(currentWpIndex + 1, #highwayWaypoints)]
								local segVec = pB - pA
								local roadForward = Vector3.new(segVec.X, 0, segVec.Z).Unit
								if currentWpIndex >= #highwayWaypoints then
									roadForward = Vector3.new(-0.768, 0, -0.640).Unit
								end

								-- Maju ke waypoint berikutnya jika sudah melewati pB
								local toB = pB - currentPos
								local distAlong = toB:Dot(roadForward)
								if distAlong <= 20 and currentWpIndex < #highwayWaypoints then
									currentWpIndex = currentWpIndex + 1
									pA = highwayWaypoints[currentWpIndex]
									pB = highwayWaypoints[math.min(currentWpIndex + 1, #highwayWaypoints)]
									segVec = pB - pA
									roadForward = Vector3.new(segVec.X, 0, segVec.Z).Unit
								end

								-- Titik tengah jalan (centerline) segmen saat ini
								local t = (currentPos - pA):Dot(roadForward)
								local segLen = (pB - pA):Dot(roadForward)
								t = math.clamp(t, 0, math.max(segLen, 1))
								local roadCenter = pA + roadForward * t

								-- 1. Deteksi permukaan jalan tepat di bawah mobil
								local downHit = workspace:Raycast(currentPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
								local roadY = (downHit and downHit.Position.Y <= 95) and downHit.Position.Y or 62.5

								-- Arah maju highway (100% sejajar koridor jalan)
								local forwardDir = roadForward
								local rightVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X).Unit

								-- 2. Dapatkan offset lateral dari Traffic Dodge Engine (otomatis hindari rintangan & NPC)
								local lateralOffset = 0
								if Config.farm.autoDodgeTraffic ~= false then
									lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, dt)
								end

								-- 3. Posisi baru: Dikunci pada roadCenter + forwardDir * stepDist + rightVec * lateralOffset (-8.0 s/d +8.0)
								local stepDist = targetStudsSec * dt
								local nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset

								-- 4. Kunci orientasi mobil 100% TEGAK LURUS SEJAJAR JALAN
								local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, roadY + 2.0, nextPos.Z), Vector3.new(nextPos.X + forwardDir.X * 10, roadY + 2.0, nextPos.Z + forwardDir.Z * 10))
								car:PivotTo(targetCF)

								-- 5. Dorong dengan kecepatan penuh stabil mengikuti arah maju highway
								seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, (roadY + 2.0 - currentPos.Y) * 6, 0)
								seat.AssemblyAngularVelocity = Vector3.zero
								if seat:IsA("VehicleSeat") then
									seat.ThrottleFloat = 1.0
									seat.Throttle = 1
								end
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
	-- ⚡ AUTO SPEED & COMBO HIGHWAY CRUISE (SMART TRAFFIC DODGE)
	------------------------------------------------
	task.spawn(function()
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local smoothDodge = 0
		local smoothLateral = 0
		local lastTick = os.clock()

		while true do
			task.wait(0.02)
			if Config.farm.autoSpeedFarm and not isRacingNow then
				local car, seat = getMyCar()
				local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if car and seat and hum and hum.Sit then
					local now = os.clock()
					local dt = math.clamp(now - lastTick, 0.005, 0.05)
					lastTick = now

					rayParams.FilterDescendantsInstances = {player.Character, car}

					local currentPos = car:GetPivot().Position

					-- Cari titik tengah & arah jalan raya terdekat dari daftar waypoints highway
					local roadCenter, roadForward = getClosestRoadInfo(currentPos)
					local currentLook = seat.CFrame.LookVector
					local forwardDir = roadForward or Vector3.new(currentLook.X, 0, currentLook.Z).Unit
					local rightVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X).Unit

					-- 1. Deteksi permukaan jalan tepat di bawah mobil
					local downHit = workspace:Raycast(currentPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
					local roadY = (downHit and downHit.Position.Y <= 95) and downHit.Position.Y or 62.5

					-- 2. Dapatkan offset lateral dari Traffic Dodge Engine (otomatis hindari rintangan & NPC)
					local lateralOffset = 0
					if Config.farm.autoDodgeTraffic ~= false then
						lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, dt)
					end

					-- 3. Posisi baru: Jika berada di dekat waypoint highway, kunci pada roadCenter + lateralOffset!
					local targetMPH = Config.farm.targetSpeed or 100
					local targetStudsSec = targetMPH * 1.760
					local stepDist = targetStudsSec * dt
					local nextPos
					if roadCenter then
						nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset
					else
						nextPos = currentPos + forwardDir * stepDist + rightVec * (lateralOffset - currentSlideOffset)
					end

					-- 4. Kunci orientasi mobil 100% TEGAK LURUS SEJAJAR JALAN
					local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, roadY + 2.0, nextPos.Z), Vector3.new(nextPos.X + forwardDir.X * 10, roadY + 2.0, nextPos.Z + forwardDir.Z * 10))
					car:PivotTo(targetCF)

					-- 5. Dorong dengan kecepatan target konstan + Gas Pedal On
					seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, (roadY + 2.0 - currentPos.Y) * 6, 0)
					seat.AssemblyAngularVelocity = Vector3.zero
					if seat:IsA("VehicleSeat") then
						seat.ThrottleFloat = 1.0
						seat.Throttle = 1
					end
				else
					lastTick = os.clock()
					smoothDodge = 0
					smoothLateral = 0
				end
			else
				lastTick = os.clock()
				smoothDodge = 0
				smoothLateral = 0
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
