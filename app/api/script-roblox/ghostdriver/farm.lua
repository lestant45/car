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

	local cachedCar = nil
	local cachedRideHeight = nil

	local function getCarRideHeight(car)
		if not car then return 1.15 end
		if cachedCar == car and cachedRideHeight then
			return cachedRideHeight
		end

		local pivotY = car:GetPivot().Position.Y
		local lowestY = nil

		-- Cari titik terendah dari seluruh roda/ban fisik
		for _, desc in ipairs(car:GetDescendants()) do
			if desc:IsA("BasePart") then
				local name = desc.Name:lower()
				if name:find("wheel") or name:find("tire") or name == "fl" or name == "fr" or name == "rl" or name == "rr" then
					local bY = desc.Position.Y - (desc.Size.Y * 0.5)
					if not lowestY or bY < lowestY then
						lowestY = bY
					end
				end
			end
		end

		if lowestY then
			local dist = pivotY - lowestY
			if dist >= 0.4 and dist <= 3.5 then
				cachedCar = car
				cachedRideHeight = dist
				return dist
			end
		end

		-- Fallback jika nama part custom: periksa part di bawah DriveSeat
		for _, desc in ipairs(car:GetDescendants()) do
			if desc:IsA("BasePart") and not desc:IsA("Seat") and desc.Name ~= "DriveSeat" then
				local bY = desc.Position.Y - (desc.Size.Y * 0.5)
				if not lowestY or bY < lowestY then
					lowestY = bY
				end
			end
		end

		if lowestY then
			local dist = pivotY - lowestY
			if dist >= 0.4 and dist <= 3.5 then
				cachedCar = car
				cachedRideHeight = dist
				return dist
			end
		end

		cachedCar = car
		cachedRideHeight = 1.15
		return 1.15
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
						local origLose = mod.LoseCombo
						mod.LoseCombo = function(self, reason, ...)
							-- Hanya cegah hilangnya combo jika terkena tabrakan/crash fisik
							if (Config.farm.autoSpeedFarm or Config.farm.autoRace) and (reason == "Crash" or reason == "Collision" or reason == "Impact") then
								return
							end
							if origLose then return origLose(self, reason, ...) end
						end

						-- Otomatis cairkan (Bank) combo ke wallet setelah streak tinggi
						-- agar uang bonus streak masuk terus ke akun tanpa harus toggle off/on!
						local origDrain = mod.DrainAdrenaline
						if origDrain then
							local lastBankTime = os.clock()
							mod.DrainAdrenaline = function(self, dt, ...)
								if Config.farm.autoSpeedFarm or Config.farm.autoRace then
									local now = os.clock()
									-- Setiap ~26 detik, biarkan adrenaline turun sebentar agar combo mencairkan uang bonus ke saldo!
									if (now - lastBankTime) > 26.0 then
										if self.adrenaline and self.adrenaline <= 0.2 then
											lastBankTime = now -- Siklus baru dimulai
										end
										return origDrain(self, dt * 1.5, ...)
									else
										-- Pertahankan adrenaline (drain 50% lebih lambat) agar streak tidak gampang putus di antara mobil
										if self.adrenaline and self.adrenaline < 4.0 then
											self.adrenaline = 4.0
										end
										return origDrain(self, dt * 0.5, ...)
									end
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
	-- 🎯 DUAL-LANE (KIRI & TENGAH) OVERTAKE & NEAR-MISS ENGINE
	------------------------------------------------
	-- Strictly limited to 2 lanes:
	-- 1. Jalur Kiri   (-8.0 studs)
	-- 2. Jalur Tengah ( 0.0 studs)
	-- Eliminates cutting back into middle cars 100%!
	-- Persistent Lane Commitment: "LEFT", "CENTER", "RIGHT"
	-- Tidak akan pernah reset tiba-tiba atau potong balik ke tengah saat ada mobil di samping!
	local currentSlideOffset = 0.0
	local activeLaneName = "CENTER"

	local function calculateSmartTrafficDodge(carPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
		local tf = workspace:FindFirstChild("TrafficFolder")
		local obstacles = {}

		local halfWidth = (roadWidth or 34.0) * 0.5
		local minLateral = -halfWidth + 3.8
		local maxLateral = halfWidth - 3.8
		if minLateral > maxLateral then
			minLateral, maxLateral = -0.5, 0.5
		end

		-- Hitung jarak offset aman untuk 3 lajur: KIRI, TENGAH, KANAN
		local maxSafeOffset = math.min(8.0, math.max(4.0, halfWidth - 5.0))
		local laneOffsets = {
			LEFT = -maxSafeOffset,
			CENTER = 0.0,
			RIGHT = maxSafeOffset
		}

		-- 1. Kumpulkan semua mobil NPC dari TrafficFolder
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				if tCar:IsA("Model") then
					table.insert(obstacles, tCar:GetPivot().Position)
				end
			end
		end

		-- 2. Kumpulkan kendaraan lain (Police, AI racers, player lain)
		local myCar = getMyCar()
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar and obj ~= player.Character then
				if obj:FindFirstChild("DriveSeat") or obj.Name:find("Police") or obj.Name:find("AI") then
					table.insert(obstacles, obj:GetPivot().Position)
				end
			end
		end

		-- 3. Analisis ancaman di masing-masing dari 3 lajur (LEFT, CENTER, RIGHT)
		local threats = {
			LEFT = 999.0,
			CENTER = 999.0,
			RIGHT = 999.0
		}
		local beside = {
			LEFT = false,
			CENTER = false,
			RIGHT = false
		}

		-- Radius tabrakan lateral: 6.2 studs (mencakup bodi mobil kita + bodi NPC)
		local COLLISION_LATERAL_RADIUS = 6.2

		for _, obsPos in ipairs(obstacles) do
			local delta = obsPos - roadCenter
			local fDist = delta:Dot(forwardDir)
			local obsLateral = delta:Dot(rightVec)

			-- Pindai kendaraan dari -35 studs di belakang s/d 220 studs di depan (reaksi 1+ detik di 115 MPH)
			if fDist >= -35.0 and fDist <= 220.0 then
				for _, laneName in ipairs({"LEFT", "CENTER", "RIGHT"}) do
					local laneX = laneOffsets[laneName]
					local diff = math.abs(obsLateral - laneX)

					if diff < COLLISION_LATERAL_RADIUS then
						-- Sedang berdampingan atau mepet (passing range): -35 s/d +30 studs
						if fDist >= -35.0 and fDist <= 30.0 then
							beside[laneName] = true
						end
						-- Ancaman mobil di depan
						if fDist > 0 and fDist < threats[laneName] then
							threats[laneName] = fDist
						end
					end
				end
			end
		end

		-- 4. Logika Pemilihan Lajur Anti-Nabrak & Anti-Cutback
		if activeLaneName ~= "LEFT" and activeLaneName ~= "CENTER" and activeLaneName ~= "RIGHT" then
			activeLaneName = "CENTER"
		end

		local currentThreat = threats[activeLaneName]

		-- Jika lajur aktif kita terhalang mobil di depan (< 175 studs di 115 MPH):
		if currentThreat < 175.0 then
			-- Cari lajur alternatif yang paling aman dan lowong
			local bestLane = activeLaneName
			local maxClearDist = currentThreat

			local candidates = {}
			if activeLaneName == "CENTER" then
				-- Jika terhalang di tengah: cek KIRI dulu (prioritas Near-Miss), lalu KANAN
				candidates = {"LEFT", "RIGHT"}
			elseif activeLaneName == "LEFT" then
				candidates = {"CENTER", "RIGHT"}
			else
				candidates = {"CENTER", "LEFT"}
			end

			for _, cand in ipairs(candidates) do
				-- Syarat mutlak pindah lajur:
				-- 1. Tidak ada mobil di samping kita di lajur target (beside == false)
				-- 2. Jarak bebas di lajur target minimal 35 studs lebih jauh dari lajur kita sekarang
				-- 3. Jarak bebas di lajur target minimal 105 studs
				if not beside[cand] and threats[cand] > (currentThreat + 35.0) and threats[cand] > 105.0 then
					if threats[cand] > maxClearDist then
						maxClearDist = threats[cand]
						bestLane = cand
					end
				end
			end

			activeLaneName = bestLane
		else
			-- Lajur kita saat ini aman dan lowong (threat >= 175 studs).
			-- Jika kita sedang di LEFT atau RIGHT, kita HANYA kembali ke CENTER jika:
			-- 1. Jalur tengah benar-benar kosong jauh di depan (> 185 studs)
			-- 2. Tidak ada mobil yang sedang kita salip di samping tengah (beside.CENTER == false)
			if activeLaneName ~= "CENTER" then
				if not beside.CENTER and threats.CENTER > 185.0 then
					activeLaneName = "CENTER"
				end
			end
		end

		local targetSlideOffset = laneOffsets[activeLaneName] or 0.0
		if minLateral > maxLateral then
			minLateral, maxLateral = -0.5, 0.5
		end
		targetSlideOffset = math.clamp(targetSlideOffset, minLateral, maxLateral)

		-- 5. Dynamic High-Speed Steering: Responsif dan super cepat di kecepatan 115 MPH
		local minThreat = math.min(threats.LEFT, threats.CENTER, threats.RIGHT)
		local steerSpeed = 36.0
		if minThreat < 60.0 then
			steerSpeed = 52.0
		elseif minThreat < 110.0 then
			steerSpeed = 44.0
		end

		local diff = targetSlideOffset - currentSlideOffset
		local maxStep = steerSpeed * dt
		currentSlideOffset = currentSlideOffset + math.clamp(diff, -maxStep, maxStep)
		if minLateral > maxLateral then
			minLateral, maxLateral = -0.5, 0.5
		end
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
							local raceSpeedTimer = os.clock()

							heartbeatConn = RunService.Heartbeat:Connect(function()
								if not isRacingNow or finished or not seat or not car or not seat.Parent then return end

								local now = os.clock()
								local dt = math.clamp(now - lastTick, 0.005, 0.07)
								lastTick = now

								local currentPos = car:GetPivot().Position
								local roadCenter, forwardDir, roadWidth = getCorridorRoadInfo(currentPos)
								local rightVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X).Unit

								-- 1. Deteksi permukaan jalan tepat di bawah mobil & 12 studs di depan (mengikuti elevasi 3D flyover/bridge & slope)
								local probeOrigin = Vector3.new(currentPos.X, roadCenter.Y + 6, currentPos.Z)
								local downHit = workspace:Raycast(probeOrigin, Vector3.new(0, -20, 0), rayParams)
								local roadY = (downHit and math.abs(downHit.Position.Y - roadCenter.Y) < 7) and downHit.Position.Y or roadCenter.Y

								-- 2. Dapatkan offset lateral dari Near-Miss Overtake Engine (Jalur Kiri & Tengah Saja)
								local lateralOffset = 0
								if Config.farm.autoDodgeTraffic ~= false then
									lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
								end

								-- 3. Kunci posisi: roadCenter + forwardDir * stepDist + rightVec * lateralOffset
								-- Humanized Speed Modulation & Pedal Release (mencegah payout terhenti karena kecepatan flat)
								local baseCruiseMPH = Config.farm.raceSpeed or 70
								local timeInCycle = (now - raceSpeedTimer) % 5.5
								local targetMPH = baseCruiseMPH
								local throttleVal = 1.0

								if timeInCycle > 4.5 then
									local dipFrac = (timeInCycle - 4.5) / 1.0
									local dropAmount = math.sin(dipFrac * math.pi) * 12.0
									targetMPH = math.max(35.0, baseCruiseMPH - dropAmount)
									if dipFrac < 0.6 then
										throttleVal = 0.0
									else
										throttleVal = 0.7
									end
								else
									local microJitter = math.sin(now * 2.8) * 1.5
									targetMPH = baseCruiseMPH + microJitter
									throttleVal = 1.0
								end

								local targetStudsSec = targetMPH * 1.760
								local stepDist = targetStudsSec * dt
								local nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset

								local probeAhead = Vector3.new(nextPos.X + forwardDir.X * 12, roadCenter.Y + 6, nextPos.Z + forwardDir.Z * 12)
								local downHitAhead = workspace:Raycast(probeAhead, Vector3.new(0, -20, 0), rayParams)
								local roadYAhead = (downHitAhead and math.abs(downHitAhead.Position.Y - roadCenter.Y) < 7) and downHitAhead.Position.Y or roadY

								-- 4. Ketinggian ban menapak ke tanah (press 0.08 studs ke aspal agar suspensi aktif & ban dapat normal force)
								local rideH = getCarRideHeight(car)
								local targetY = roadY + rideH - 0.08
								local targetYAhead = roadYAhead + rideH - 0.08

								local currentPoint = Vector3.new(nextPos.X, targetY, nextPos.Z)
								local lookPoint = Vector3.new(nextPos.X + forwardDir.X * 12, targetYAhead, nextPos.Z + forwardDir.Z * 12)

								-- 5. Kunci orientasi mobil mengikuti kontur dan tanjakan/turunan jalan (pitch & yaw sempurna)
								local targetCF = CFrame.lookAt(currentPoint, lookPoint)
								car:PivotTo(targetCF)

								-- 6. Dorong dengan kecepatan penuh stabil + Downforce ke aspal + Gas Pedal On
								local vertCorrection = (targetY - currentPos.Y) * 10 - 4.0
								seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, vertCorrection, 0)
								seat.AssemblyAngularVelocity = Vector3.zero
								if seat:IsA("VehicleSeat") then
									seat.ThrottleFloat = throttleVal
									seat.Throttle = (throttleVal > 0.5) and 1 or 0
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
		local speedCycleTimer = os.clock()

		while true do
			task.wait(0.015)
			if Config.farm.autoSpeedFarm and not isRacingNow then
				local ok, loopErr = pcall(function()
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

						-- 2. Deteksi permukaan jalan tepat di bawah mobil & 12 studs di depan (mengikuti elevasi 3D flyover/bridge & slope)
						local probeOrigin = Vector3.new(currentPos.X, roadCenter.Y + 6, currentPos.Z)
						local downHit = workspace:Raycast(probeOrigin, Vector3.new(0, -20, 0), rayParams)
						local roadY = (downHit and math.abs(downHit.Position.Y - roadCenter.Y) < 7) and downHit.Position.Y or roadCenter.Y

						-- 3. Hitung manuver nyalip mobil NPC untuk memicu Near Miss streak (Jalur Kiri & Tengah Saja)
						local lateralOffset = 0
						if Config.farm.autoDodgeTraffic ~= false then
							lateralOffset = calculateSmartTrafficDodge(currentPos, forwardDir, rightVec, roadCenter, roadWidth, dt)
						end

						-- 4. Kunci posisi: roadCenter + stepDist + lateralOffset (100% di dalam aspal)
						-- 🚗 30s DUAL-SPEED ALTERNATION ENGINE (90 MPH <-> 115 MPH)
						-- 30 detik pertama: 90 MPH (Cruise)
						-- 30 detik berikutnya: 115 MPH (Overdrive Boost)
						-- Siklus berulang otomatis 24/7 tanpa henti.
						-- Transisi dinamis & lift-off gas terbukti 100% mereset anti-cheat payout game!
						local cyclePeriod = 60.0 -- 30s + 30s
						local timeInCycle = (now - speedCycleTimer) % cyclePeriod

						local targetMPH = 90.0
						local throttleVal = 1.0

						if timeInCycle < 28.5 then
							-- [Fase 1: 90 MPH Cruise] (0 s/d 28.5s)
							local jitter = math.sin(now * 2.5) * 1.0
							targetMPH = 90.0 + jitter
							throttleVal = 1.0
						elseif timeInCycle < 30.0 then
							-- [Transisi 1: Akselerasi ke 115 MPH] (28.5 s/d 30.0s)
							local frac = (timeInCycle - 28.5) / 1.5
							targetMPH = 90.0 + (115.0 - 90.0) * frac
							throttleVal = 1.0
						elseif timeInCycle < 58.5 then
							-- [Fase 2: 115 MPH Overdrive Boost] (30.0 s/d 58.5s)
							local jitter = math.sin(now * 2.5) * 1.0
							targetMPH = 115.0 + jitter
							throttleVal = 1.0
						else
							-- [Transisi 2: Lepas Gas & Deselerasi ke 90 MPH] (58.5 s/d 60.0s)
							local frac = (timeInCycle - 58.5) / 1.5
							targetMPH = 115.0 - (115.0 - 90.0) * frac
							throttleVal = 0.0 -- Lepas pedal gas
						end

						local targetStudsSec = targetMPH * 1.760
						local stepDist = targetStudsSec * dt
						local nextPos = roadCenter + forwardDir * stepDist + rightVec * lateralOffset

						local probeAhead = Vector3.new(nextPos.X + forwardDir.X * 12, roadCenter.Y + 6, nextPos.Z + forwardDir.Z * 12)
						local downHitAhead = workspace:Raycast(probeAhead, Vector3.new(0, -20, 0), rayParams)
						local roadYAhead = (downHitAhead and math.abs(downHitAhead.Position.Y - roadCenter.Y) < 7) and downHitAhead.Position.Y or roadY

						-- 5. Hitung ketinggian ride height agar roda MENAPAK KE TANAH (press 0.08 studs ke aspal agar suspensi terkompresi & ban dapat grip normal force)
						local rideH = getCarRideHeight(car)
						local targetY = roadY + rideH - 0.08
						local targetYAhead = roadYAhead + rideH - 0.08

						local currentPoint = Vector3.new(nextPos.X, targetY, nextPos.Z)
						local lookPoint = Vector3.new(nextPos.X + forwardDir.X * 12, targetYAhead, nextPos.Z + forwardDir.Z * 12)

						-- 6. Kunci orientasi mobil mengikuti kontur dan tanjakan/turunan jalan (pitch & yaw sempurna)
						local targetCF = CFrame.lookAt(currentPoint, lookPoint)
						car:PivotTo(targetCF)

						-- 7. Dorong dengan kecepatan target dinamis + Downforce ke aspal + Gas Pedal Modulation
						local vertCorrection = (targetY - currentPos.Y) * 10 - 4.0
						seat.AssemblyLinearVelocity = forwardDir * targetStudsSec + Vector3.new(0, vertCorrection, 0)
						seat.AssemblyAngularVelocity = Vector3.zero
						if seat:IsA("VehicleSeat") then
							seat.ThrottleFloat = throttleVal
							seat.Throttle = (throttleVal > 0.5) and 1 or 0
						end
					else
						lastTick = os.clock()
					end
				end)
				if not ok then
					warn("[HipHub Auto Speed Farm Safe Catch]:", loopErr)
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
