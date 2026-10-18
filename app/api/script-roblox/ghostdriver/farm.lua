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
			if not c then return end

			local TrafficImpact = c:FindFirstChild("TrafficImpactController")
			if TrafficImpact then
				local mod = require(TrafficImpact)
				if mod then
					mod.Push = function(self, ...) end
					mod.Update = function(self, ...) end
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
	RunService.Stepped:Connect(function()
		neutralizeGameCollisions()

		local myCar = getMyCar()

		-- 1. Disable collision on all non-wheel parts of our own car (body, hood, seat, bumpers)
		if myCar then
			for _, p in ipairs(myCar:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "FL" and p.Name ~= "FR" and p.Name ~= "RL" and p.Name ~= "RR" and p.CanCollide then
					p.CanCollide = false
				end
			end
		end

		-- 2. Disable collision on all NPC Traffic vehicles in workspace.TrafficFolder
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
	-- 🚗 SMART 3-LANE TRAFFIC DODGE & OVERTAKE SENSOR
	------------------------------------------------
	-- Aturan 3 Jalur Mutlak:
	-- 1. Mobil di jalur KIRI (leftClearance < 13)   -> WAJIB DODGE KE KANAN (+1)! Dilarang keras buang ke kiri!
	-- 2. Mobil di jalur KANAN (rightClearance < 13) -> WAJIB DODGE KE KIRI (-1)!  Dilarang keras buang ke kanan!
	-- 3. Mobil di jalur TENGAH                      -> Bebas pilih kiri/kanan (pilih lajur paling lapang)
	local function calculateTrafficAvoidance(carPos, forwardDir, rightVec, rayParams, myCar, currentLane, currentSmoothDodge)
		local tf = workspace:FindFirstChild("TrafficFolder")
		local obstacles = {}
		if tf then
			for _, tCar in ipairs(tf:GetChildren()) do
				if tCar:IsA("Model") then
					table.insert(obstacles, tCar)
				end
			end
		end

		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj ~= myCar and (obj:FindFirstChild("DriveSeat") or obj.Name:find("AI") or obj.Name:find("Police")) then
				table.insert(obstacles, obj)
			end
		end

		-- Cari rintangan terdekat di koridor depan kita
		local nearestObs = nil
		local nearestDist = 180
		local nearestLDist = 0

		for _, obs in ipairs(obstacles) do
			local oPivot = obs:GetPivot()
			local oPos = oPivot.Position
			local delta = oPos - carPos
			local fDist = delta:Dot(forwardDir)

			-- Danger corridor: 8 sampai 160 studs di depan mobil
			if fDist > 8 and fDist < nearestDist then
				local lDist = delta:Dot(rightVec)

				-- Koridor tabrakan: lebar ~8.5 studs (hanya bereaksi pada mobil yang sejalur dengan kita)
				if math.abs(lDist) < 8.5 then
					nearestDist = fDist
					nearestLDist = lDist
					nearestObs = obs
				end
			end
		end

		if not nearestObs then
			return 0
		end

		-- Ukur posisi jalur kita: prioritaskan currentLane matematis & smoothDodge aktif
		local leftClearance, rightClearance = getRoadMargins(carPos, rightVec, rayParams)

		local isLeftLane = (currentLane == "LEFT") or (currentSmoothDodge and currentSmoothDodge < -0.10) or (leftClearance < 11)
		local isRightLane = (currentLane == "RIGHT") or (currentSmoothDodge and currentSmoothDodge > 0.10) or (rightClearance < 11)

		local dodgeDir = 0
		if isLeftLane then
			-- 🛑 1. Mobil di Jalur Kiri -> WAJIB DODGE KE KANAN! DILARANG KERAS KE KIRI!
			dodgeDir = 1
		elseif isRightLane then
			-- 🛑 2. Mobil di Jalur Kanan -> WAJIB DODGE KE KIRI! DILARANG KERAS KE KANAN!
			dodgeDir = -1
		else
			-- 🚗 3. Mobil di Jalur Tengah -> Bebas pilih sisi yang paling lapang
			local preferredSide = (nearestLDist >= 0) and -1 or 1

			-- Cek apakah lajur pilihan ada mobil lain di depan
			local candidatePos = carPos + rightVec * (preferredSide * 13)
			local candidateClear = true
			for _, otherObs in ipairs(obstacles) do
				if otherObs ~= nearestObs then
					local oP = otherObs:GetPivot().Position
					local oDelta = oP - candidatePos
					local oF = oDelta:Dot(forwardDir)
					local oL = oDelta:Dot(rightVec)
					if oF > 8 and oF < 120 and math.abs(oL) < 7.0 then
						candidateClear = false
						break
					end
				end
			end

			if candidateClear then
				dodgeDir = preferredSide
			else
				dodgeDir = -preferredSide
			end
		end

		-- 🔒 MUTLAK: Jika mobil berada di jalur kiri, TIDAK BOLEH BELOK KIRI LAGI!
		if isLeftLane and dodgeDir < 0 then
			dodgeDir = 1
		end
		-- Jika mobil berada di jalur kanan, TIDAK BOLEH BELOK KANAN LAGI!
		if isRightLane and dodgeDir > 0 then
			dodgeDir = -1
		end

		-- 🛡️ INTEGRITY SAFEGUARD: Pastikan arah dodge memiliki permukaan jalan yang valid!
		if dodgeDir < 0 then
			if not isRoadAt(carPos - rightVec * 8, rayParams) then
				dodgeDir = 1 -- Sisi kiri jurang/tembok! Paksa ke kanan!
			end
		elseif dodgeDir > 0 then
			if not isRoadAt(carPos + rightVec * 8, rayParams) then
				dodgeDir = -1 -- Sisi kanan jurang/tembok! Paksa ke kiri!
			end
		end

		-- Double check batas aman mutlak
		if dodgeDir < 0 and not isRoadAt(carPos - rightVec * 6, rayParams) then
			dodgeDir = 0
		elseif dodgeDir > 0 and not isRoadAt(carPos + rightVec * 6, rayParams) then
			dodgeDir = 0
		end

		-- Urgency dinamis halus berdasarkan jarak rintangan
		local urgency = math.clamp((160 - nearestDist) / 100, 0.40, 1.20)
		return dodgeDir * urgency * 0.32
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
							task.wait(0.2)
						end

						if started and not finished then
							-- Tunggu sampai server selesai memindahkan mobil ke grid start di jalan raya (Y < 80)
							local waitGrid = os.clock()
							while (os.clock() - waitGrid) < 6 do
								local curP = car:GetPivot().Position
								if curP.Y < 80 and curP.Z < -1000 then
									break
								end
								task.wait(0.2)
							end

							-- Waypoints Resmi Highway: Titik tengah jalan raya (dead center) anti-keluar jalur
							local waypoints = {
								Vector3.new(-3487.0, 62.2, -1800.0), -- Start highway center
								Vector3.new(-3481.0, 62.2, -2300.0), -- Lower highway center
								Vector3.new(-3481.0, 62.2, -2900.0), -- Lower highway center
								Vector3.new(-3501.0, 62.2, -3500.0), -- Menuju Checkpoint 6
								Vector3.new(-3505.0, 79.4, -3922.6), -- Checkpoint 6 center
								Vector3.new(-3516.0, 62.2, -4128.2), -- Checkpoint 7 center
								Vector3.new(-3530.0, 61.3, -4459.7), -- Checkpoint 8 center
								Vector3.new(-3555.0, 61.3, -4829.8), -- Checkpoint 9 center
								Vector3.new(-3595.0, 61.3, -5242.1), -- Checkpoint 10 center
								Vector3.new(-3660.0, 61.3, -5714.0), -- Checkpoint 11 center
								Vector3.new(-3760.0, 61.5, -6322.1), -- Checkpoint 12 center
								Vector3.new(-3820.0, 61.5, -6600.0), -- Tikungan highway 1
								Vector3.new(-4070.0, 61.5, -7606.0), -- Tikungan highway 2
								Vector3.new(-4389.0, 62.2, -8593.0), -- Tikungan highway 3
								Vector3.new(-4776.0, 62.2, -9555.0), -- Tikungan highway 4
								Vector3.new(-5451.0, 62.2, -10750.0),-- Highway strip 5
								Vector3.new(-6301.0, 62.2, -12000.0),-- Highway strip 6
								Vector3.new(-7300.0, 81.6, -13300.0),-- Highway strip 7
								Vector3.new(-8382.0, 62.2, -14500.0),-- Menuju garis finish
								Vector3.new(-9742.0, 62.2, -15626.9),-- RaceFinishLine
								Vector3.new(-10200.0, 62.2, -16000.0),-- Tembus garis finish +450 studs
								Vector3.new(-10800.0, 62.2, -16500.0) -- Tembus garis finish +1000 studs
							}

							local currentWpIndex = 1
							local cruiseMPH = math.clamp(Config.farm.raceSpeed or 340, 150, 480)
							local targetStudsSec = cruiseMPH * 1.760

							local rayParams = RaycastParams.new()
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							rayParams.FilterDescendantsInstances = {player.Character, car}

							-- Real-time road tracking & lane keeping loop with 3-Lane Smooth Dodge
							local heartbeatConn
							local smoothDodge = 0
							local smoothLateral = 0
							local lastTick = os.clock()

							heartbeatConn = RunService.Heartbeat:Connect(function()
								if not isRacingNow or finished or not seat or not car or not seat.Parent then return end

								local now = os.clock()
								local dt = math.clamp(now - lastTick, 0.005, 0.07)
								lastTick = now

								local currentPos = car:GetPivot().Position
								local targetPos = waypoints[currentWpIndex] or waypoints[#waypoints]
								local deltaTarget = targetPos - currentPos
								local distToTarget = Vector2.new(deltaTarget.X, deltaTarget.Z).Magnitude

								-- Arah pergerakan makro
								local macroDir
								if currentWpIndex >= #waypoints and distToTarget < 100 then
									macroDir = Vector3.new(-0.768, 0, -0.640).Unit
								else
									macroDir = Vector3.new(deltaTarget.X, 0, deltaTarget.Z).Unit
								end

								-- Maju ke checkpoint berikutnya kalau sudah dekat (<150 studs) atau sudah terlewati
								local isPassed = deltaTarget:Dot(macroDir) < -15
								if (distToTarget < 150 or isPassed) and currentWpIndex < #waypoints then
									currentWpIndex = currentWpIndex + 1
									targetPos = waypoints[currentWpIndex]
									deltaTarget = targetPos - currentPos
								end

								-- 1. Deteksi permukaan jalan tepat di bawah mobil
								local downHit = workspace:Raycast(currentPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
								local roadY = (downHit and downHit.Position.Y <= 95) and downHit.Position.Y or 62.5

								-- 2. Deteksi arah jalan di depan: probe lurus dulu, hanya probe sudut jika di depan melenceng
								local bestDir = macroDir
								local probeOrigin = currentPos + macroDir * 35 + Vector3.new(0, 10, 0)
								local hitAhead = workspace:Raycast(probeOrigin, Vector3.new(0, -45, 0), rayParams)
								if not (hitAhead and hitAhead.Position.Y <= 95) then
									local probeAngles = {8, -8, 16, -16}
									for _, deg in ipairs(probeAngles) do
										local testDir = (CFrame.Angles(0, math.rad(deg), 0) * macroDir).Unit
										local pHit = workspace:Raycast(currentPos + testDir * 35 + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
										if pHit and pHit.Position.Y <= 95 and not (pHit.Instance.Name:lower():find("wall") or pHit.Instance.Name:lower():find("guard") or pHit.Instance.Name:lower():find("rail")) then
											bestDir = testDir
											break
										end
									end
								end

								-- 3. 3-Lane Road Margin & Smart Traffic Dodging
								local rightVec = Vector3.new(-bestDir.Z, 0, bestDir.X).Unit
								local leftClearance, rightClearance = getRoadMargins(currentPos, rightVec, rayParams)

								-- Hitung deviasi posisi mobil dari titik tengah track waypoints
								local prevWp = (currentWpIndex > 1) and waypoints[currentWpIndex - 1] or (targetPos - macroDir * 200)
								local trackDir = Vector3.new(targetPos.X - prevWp.X, 0, targetPos.Z - prevWp.Z).Unit
								local trackRight = Vector3.new(-trackDir.Z, 0, trackDir.X).Unit
								local lateralFromCenter = (currentPos - targetPos):Dot(trackRight)

								local currentLane = "CENTER"
								if lateralFromCenter <= -5.5 then
									currentLane = "LEFT"
								elseif lateralFromCenter >= 5.5 then
									currentLane = "RIGHT"
								end

								local lateralTarget = 0
								if leftClearance < 9 and rightClearance >= 13 then
									lateralTarget = 0.22 -- jangan terlalu mepet bibir kiri, dorong halus ke kanan
								elseif rightClearance < 9 and leftClearance >= 13 then
									lateralTarget = -0.22 -- jangan terlalu mepet bibir kanan, dorong halus ke kiri
								end

								local targetDodge = 0
								if Config.farm.autoDodgeTraffic ~= false then
									targetDodge = calculateTrafficAvoidance(currentPos, bestDir, rightVec, rayParams, car, currentLane, smoothDodge)
								end

								-- Smooth Exponential Moving Average transition (S-curve, no snapping, clamped to 1 lane max)
								smoothDodge = math.clamp(smoothDodge + (targetDodge - smoothDodge) * math.clamp(dt * 7.0, 0.05, 0.35), -0.32, 0.32)
								smoothLateral = math.clamp(smoothLateral + (lateralTarget - smoothLateral) * math.clamp(dt * 5.0, 0.05, 0.25), -0.22, 0.22)

								local finalHeading = (bestDir + rightVec * (smoothLateral + smoothDodge)).Unit

								-- 4. Kunci orientasi mobil & dorong maju framerate-independent (Anti-Lag Redfinger)
								local targetY = roadY + 2.0
								local stepDist = targetStudsSec * dt
								local nextPos = currentPos + finalHeading * stepDist
								local lookAtPos = nextPos + finalHeading * 10
								local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, targetY, nextPos.Z), Vector3.new(lookAtPos.X, targetY, lookAtPos.Z))
								local smoothCF = car:GetPivot():Lerp(targetCF, math.clamp(dt * 14.0, 0.18, 0.75))
								car:PivotTo(smoothCF)

								-- 5. Dorong dengan kecepatan penuh stabil mengikuti arah halus mobil + Gas Pedal On
								seat.AssemblyLinearVelocity = finalHeading * targetStudsSec + Vector3.new(0, (targetY - currentPos.Y) * 6, 0)
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
					local currentLook = seat.CFrame.LookVector
					local macroDir = Vector3.new(currentLook.X, 0, currentLook.Z).Unit
					local rightVec = Vector3.new(-macroDir.Z, 0, macroDir.X).Unit

					-- 1. Deteksi permukaan jalan tepat di bawah mobil
					local downHit = workspace:Raycast(currentPos + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
					local roadY = (downHit and downHit.Position.Y <= 95) and downHit.Position.Y or 62.5

					-- 2. Deteksi arah jalan ke depan (probe lurus dulu, hanya probe sudut jika di depan melenceng)
					local bestDir = macroDir
					local probeOrigin = currentPos + macroDir * 35 + Vector3.new(0, 10, 0)
					local hitAhead = workspace:Raycast(probeOrigin, Vector3.new(0, -45, 0), rayParams)
					if not (hitAhead and hitAhead.Position.Y <= 95) then
						local probeAngles = {8, -8, 16, -16}
						for _, deg in ipairs(probeAngles) do
							local testDir = (CFrame.Angles(0, math.rad(deg), 0) * macroDir).Unit
							local pHit = workspace:Raycast(currentPos + testDir * 35 + Vector3.new(0, 10, 0), Vector3.new(0, -45, 0), rayParams)
							if pHit and pHit.Position.Y <= 95 and not (pHit.Instance.Name:lower():find("wall") or pHit.Instance.Name:lower():find("guard") or pHit.Instance.Name:lower():find("rail")) then
								bestDir = testDir
								break
							end
						end
					end

					-- 3. 3-Lane Road Margin & Smart Traffic Dodging
					local leftClearance, rightClearance = getRoadMargins(currentPos, rightVec, rayParams)
					local currentLane = "CENTER"
					if smoothDodge < -0.10 or leftClearance < 11 then
						currentLane = "LEFT"
					elseif smoothDodge > 0.10 or rightClearance < 11 then
						currentLane = "RIGHT"
					end

					local lateralTarget = 0
					if leftClearance < 9 and rightClearance >= 13 then
						lateralTarget = 0.22 -- jangan mepet bibir kiri, dorong halus ke kanan
					elseif rightClearance < 9 and leftClearance >= 13 then
						lateralTarget = -0.22 -- jangan mepet bibir kanan, dorong halus ke kiri
					end

					local targetDodge = 0
					if Config.farm.autoDodgeTraffic ~= false then
						targetDodge = calculateTrafficAvoidance(currentPos, bestDir, rightVec, rayParams, car, currentLane, smoothDodge)
					end

					smoothDodge = math.clamp(smoothDodge + (targetDodge - smoothDodge) * math.clamp(dt * 7.0, 0.05, 0.35), -0.32, 0.32)
					smoothLateral = math.clamp(smoothLateral + (lateralTarget - smoothLateral) * math.clamp(dt * 5.0, 0.05, 0.25), -0.22, 0.22)

					local finalHeading = (bestDir + rightVec * (smoothLateral + smoothDodge)).Unit

					-- 4. Kunci orientasi mobil & dorong maju framerate-independent (Anti-Lag Redfinger)
					local targetY = roadY + 2.0
					local targetMPH = math.clamp(Config.farm.targetSpeed or 240, 50, 380)
					local targetStudsSec = targetMPH * 1.760
					local stepDist = targetStudsSec * dt
					local nextPos = currentPos + finalHeading * stepDist
					local lookAtPos = nextPos + finalHeading * 10
					local targetCF = CFrame.lookAt(Vector3.new(nextPos.X, targetY, nextPos.Z), Vector3.new(lookAtPos.X, targetY, lookAtPos.Z))
					local smoothCF = car:GetPivot():Lerp(targetCF, math.clamp(dt * 14.0, 0.18, 0.75))
					car:PivotTo(smoothCF)

					-- 5. Dorong dengan kecepatan target konstan + Gas Pedal On
					seat.AssemblyLinearVelocity = finalHeading * targetStudsSec + Vector3.new(0, (targetY - currentPos.Y) * 6, 0)
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
