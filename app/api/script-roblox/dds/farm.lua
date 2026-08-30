-- 💰 HipHub DDS — RideGO Taxi Auto-Farm Engine
-- Drag Drive Simulator (Place ID: 131378148336503)
-- Features: Fully Autonomous RideGO Taxi Farming, Void Bridging & Anti-Accident Stabilization

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
		autoRideGO = false,
		taxiSpeed = 90,
		passengerBoardDelay = 3
	}

	------------------------------------------------
	-- 🚕 SHARED RIDEGO TAXI STATE & REMOTE CONTROLLER
	------------------------------------------------
	local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 10)
	local TaxiEvent = TaxiAssets and TaxiAssets:WaitForChild("Events", 10) and TaxiAssets.Events:WaitForChild("TaxiEvent", 10)

	local function getTaxiEvent()
		if TaxiEvent then return TaxiEvent end
		local assets = ReplicatedStorage:FindFirstChild("TaxiAssets")
		local ev = assets and assets:FindFirstChild("Events") and assets.Events:FindFirstChild("TaxiEvent")
		TaxiEvent = ev
		return ev
	end

	local taxiActive          = false
	local taxiBusy            = false
	local taxiState           = "IDLE"
	local taxiToken           = nil
	local lastCompletedToken  = nil
	local taxiPickupPos       = nil
	local taxiDropPos         = nil
	local passengerSeated     = false
	local taxiOverlayPoller   = nil

	local function setTaxiState(newState)
		taxiState = newState
	end

	local function resetTaxiDutyCycle(specificToken)
		local tok = specificToken or taxiToken
		pcall(function()
			local ev = getTaxiEvent()
			if ev then
				if tok then ev:FireServer("CancelOrder", tok) end
				ev:FireServer("CancelOrder")
				ev:FireServer("CancelTrip")
				ev:FireServer("GoOffline")
			end
		end)

		lastCompletedToken = tok
		taxiBusy = false
		taxiToken = nil
		taxiPickupPos = nil
		taxiDropPos = nil
		passengerSeated = false
		setTaxiState("WAITING_FOR_NEXT_ORDER")

		task.wait(1.5)

		pcall(function()
			local ev = getTaxiEvent()
			if ev then
				ev:FireServer("GoOnline")
			end
		end)
	end

	------------------------------------------------
	-- 🛠️ 1. VEHICLE & MOVEMENT CORE ENGINE
	------------------------------------------------
	local currentDriveConn = nil
	local isDrivingActive  = false

	-- 🛡️ Adonis-Safe Universal Anti-AFK Engine (Zero Disallowed Services, 100% Undetectable)
	task.spawn(function()
		local vim = nil
		pcall(function() vim = game:GetService("VirtualInputManager") end)
		while true do
			task.wait(45)
			pcall(function()
				if vim then
					vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
					task.wait(0.03)
					vim:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
				elseif mousemoverel then
					mousemoverel(0, 1)
					task.wait(0.03)
					mousemoverel(0, -1)
				else
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum and hum.SeatPart then
						local seat = hum.SeatPart
						if seat:IsA("VehicleSeat") then
							seat.SteerFloat = 0.001
							task.wait(0.03)
							seat.SteerFloat = 0
						end
					end
				end
			end)
		end
	end)

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

		-- Search workspace direct children for player's motorcycle
		for _, c in ipairs(workspace:GetChildren()) do
			if c:IsA("Model") and c ~= char and (c.Name:find(player.Name) or c.Name:find("Montor") or c.Name:find("Yamaha") or c.Name:find("Mio") or c:FindFirstChild("DriveSeat", true) or c:FindFirstChildWhichIsA("VehicleSeat", true)) then
				local seat = c:FindFirstChild("DriveSeat", true) or c:FindFirstChildWhichIsA("VehicleSeat", true) or c:FindFirstChildWhichIsA("Seat", true)
				if seat then return c, seat end
			end
		end

		return nil, nil
	end

	-- Spawns an invisible collision safety plate underneath destination/vehicle
	local function ensureSafetyPlate(pos, width)
		width = width or 80
		local plate = workspace:FindFirstChild("__DdsSafetyPlate")
		if not plate then
			plate = Instance.new("Part")
			plate.Name = "__DdsSafetyPlate"
			plate.Anchored = true
			plate.CanCollide = true
			plate.Transparency = 1
			plate.CastShadow = false
			plate.Material = Enum.Material.Concrete
			pcall(function() plate.Parent = workspace end)
		end
		plate.Size = Vector3.new(width, 4, width)
		plate.CFrame = CFrame.new(pos.X, pos.Y - 2.0, pos.Z)
		return plate
	end

	local function destroySafetyPlate()
		pcall(function()
			local plate = workspace:FindFirstChild("__DdsSafetyPlate")
			if plate then
				plate:Destroy()
			end
		end)
	end

	local TAXI_BIKE_NAME = "Yamahax-MioSporty"

	local function spawnTaxiBike()
		local SpawnCarEvt = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
		local remote = SpawnCarEvt and SpawnCarEvt:FindFirstChild("SpawnCar")
		if not remote then return end
		pcall(function() remote:FireServer(TAXI_BIKE_NAME) end)
		task.wait(2)
	end

	local function findRidePrompt()
		local car, seat = getPlayerVehicle()
		if not car and not seat then
			for _, c in ipairs(workspace:GetChildren()) do
				if c:IsA("Model") and c ~= player.Character and (c.Name:find(player.Name) or c.Name:find("Montor") or c.Name:find("Yamaha") or c.Name:find("Mio") or c:FindFirstChild("DriveSeat", true) or c:FindFirstChildWhichIsA("VehicleSeat", true)) then
					car = c
					seat = c:FindFirstChild("DriveSeat", true) or c:FindFirstChildWhichIsA("VehicleSeat", true) or c:FindFirstChildWhichIsA("Seat", true)
					break
				end
			end
		end

		local seatPart = seat or (car and (car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)))
		if not seatPart then return nil, nil end

		-- 1. Search prompt inside DriveSeat directly
		local prompt = seatPart:FindFirstChildWhichIsA("ProximityPrompt", true)

		-- 2. Search prompt in entire car excluding Lock, Tuner, Kickstand, Trunk
		if not prompt and car then
			for _, p in ipairs(car:GetDescendants()) do
				if p:IsA("ProximityPrompt") then
					local pn = p.Name:lower()
					local an = (p.ActionText or ""):lower()
					local on = (p.ObjectText or ""):lower()
					if not (pn:find("lock") or pn:find("tuner") or pn:find("trunk") or pn:find("bagasi") or pn:find("kickstand") or an:find("lock") or on:find("lock")) then
						prompt = p
						break
					end
				end
			end
		end

		return prompt, seatPart
	end

	local function neutralizeBikeHazards(car)
		pcall(function()
			if car then
				for _, s in ipairs(car:GetDescendants()) do
					if s:IsA("LocalScript") and (s.Name:find("Fall") or s.Name:find("Crash") or s.Name:find("Accident") or s.Name:find("Ragdoll")) then
						s.Disabled = true
					end
				end
			end
			local char = player.Character
			if char then
				for _, s in ipairs(char:GetDescendants()) do
					if s:IsA("Script") or s:IsA("LocalScript") then
						if s.Name == "RagdollHandler" or s.Name:find("Fall") or s.Name:find("Crash") or s.Name:find("Accident") or s.Name:find("Ragdoll") then
							s.Disabled = true
						end
					end
					if s:IsA("BasePart") then
						s.CanCollide = false
					end
				end
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				end
			end
		end)
	end

	local function mountBike()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return false end
		if hum.SeatPart then return true end

		-- Reset sitting state palsu di udara
		hum.Sit = false

		local prompt, seatPart = findRidePrompt()
		if not seatPart then
			UI.Notify("🏍️ Spawning Motor", "Memanggil motor baru...", 2.5, "warning")
			spawnTaxiBike()
			local spawnWait = os.clock()
			while not seatPart and (os.clock() - spawnWait < 4.0) do
				task.wait(0.25)
				prompt, seatPart = findRidePrompt()
			end
			if not seatPart then
				warn("[HipHub DDS] mountBike: seatPart tetap tidak ditemukan setelah spawnTaxiBike")
				return false
			end
		end

		local car = seatPart:FindFirstAncestorOfClass("Model") or seatPart.Parent
		if car then
			neutralizeBikeHazards(car)
		end

		pcall(function() seatPart.Disabled = false end)

		-- Pindahkan posisi player tepat menempel di atas kursi motor
		root.CFrame = seatPart.CFrame + Vector3.new(0, 0.3, 0)
		task.wait(0.1)

		-- Loop agresif verifikasi duduk (maksimal 3.0 detik)
		local sitStart = os.clock()
		while not hum.SeatPart and (os.clock() - sitStart < 3.0) do
			-- 1. Trigger ProximityPrompt pengemudi jika ada
			if prompt then
				pcall(function()
					if fireproximityprompt then
						fireproximityprompt(prompt)
					elseif prompt.InputHoldBegin then
						prompt:InputHoldBegin()
						task.wait(0.05)
						prompt:InputHoldEnd()
					end
				end)
			end

			-- 2. Trigger native touch event via firetouchinterest
			pcall(function()
				if firetouchinterest then
					firetouchinterest(root, seatPart, 0)
					task.wait(0.02)
					firetouchinterest(root, seatPart, 1)
				end
			end)

			-- 3. Native seat sit call (tanpa hum.Sit = true agar tidak duduk di udara)
			pcall(function()
				seatPart:Sit(hum)
			end)

			root.CFrame = seatPart.CFrame + Vector3.new(0, 0.3, 0)
			task.wait(0.25)
		end

		local isSeated = (hum.SeatPart ~= nil)
		if isSeated then
			UI.Notify("✅ Driver Seated", "Motor berhasil dikendarai.", 1.5, "success")
		else
			UI.Notify("⚠️ Belum Duduk", "Gagal menaiki motor, mencoba kembali...", 2, "warning")
		end

		return isSeated
	end

	-- 🪑 Safety check: pastikan player duduk di kursi pengemudi.
	local function ensureDriverSeated()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart then return true end

		for attempt = 1, 3 do
			UI.Notify("⚠️ Driver Not Seated", string.format("Menaiki motor (Percobaan %d/3)...", attempt), 2, "warning")
			local ok = mountBike()
			if ok then
				task.wait(0.3)
				local h2 = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if h2 and h2.SeatPart then
					return true
				end
			end
			task.wait(0.5)
		end

		warn("[HipHub DDS] ensureDriverSeated: gagal duduk setelah 3 percobaan")
		return false
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

	-- 🧹 UNIVERSAL DESTROY ALL BUILDINGS & OBSTACLES (Ground & Roads Only Mode)
	local function isRoadOrGround(obj)
		if not obj then return false end
		if obj:IsA("Terrain") then return true end
		local name = obj.Name:upper()
		if name:find("BUILDING") or name:find("BANGUNAN") or name:find("RUMAH") or name:find("GEDUNG")
			or name:find("HOUSE") or name:find("LANTAI") or name:find("SHOP") or name:find("DEALER")
			or name:find("GARAGE") or name:find("PAGAR") or name:find("RAIL") or name:find("LAMPU")
			or name:find("POHON") or name:find("PROPS") or name:find("SETTING") or name:find("STOPPER")
			or name:find("MACHINE") or name:find("MONTOR") or name:find("CAR")
			or name:find("VEHICLE") or name:find("MISSION") or name:find("QUEST") or name:find("MANCING")
			or name:find("JOB") or name:find("FLAG") or name:find("SIGN") or name:find("CONE")
			or name:find("BARRIER") or name:find("PITCH") or name:find("STAGE") or name:find("PANGGUNG")
			or name:find("TIMER") or name:find("DISPLAY") or name:find("HELMET") or name:find("KFC")
			or name:find("RESTAURANT") or name:find("GATE") or name:find("MOLDING") or name:find("MEJA")
		then
			return false
		end
		if name == "BASEPLATE" or name == "OTHER_GRASS" or name == "ROADSNEW" or name == "TROTOARNEW"
			or name == "ZEBRA_CROSS" or name == "OTHER_FLYOVER_PURWOSARI" or name:find("AIR_SUNGAI")
			or name:find("SUNGAI") or name:find("HILL") or name:find("GROUND") or name:find("TERRAIN")
			or name:find("GRASS") or name:find("MESH") or name:find("UNION") or name:find("WEIGHT")
			or name:find("FLYOVER") or name:find("JEMBATAN") or name:find("BRIDGE") or name:find("OVERPASS")
			or name:find("RAMP") or name:find("HIGHWAY") or name:find("TOLL") or name:find("TROTO")
			or name:find("ROAD") or name:find("JALAN") or name:find("ASPHALT") or name:find("ASPAL")
		then
			return true
		end
		return false
	end

	local function isVehicleOrSeatOrPlayer(obj)
		if not obj then return false end
		local char = player.Character
		if char and (obj == char or obj:IsDescendantOf(char)) then return true end
		if obj:IsA("VehicleSeat") or obj:IsA("Seat") or obj:IsA("ProximityPrompt") then return true end

		-- Check if obj is or is inside any Vehicle/Motor model in workspace
		local cur = obj
		while cur and cur ~= workspace and cur ~= game do
			if cur:IsA("Model") then
				if cur:FindFirstChildWhichIsA("VehicleSeat", true) or cur:FindFirstChild("DriveSeat", true) then
					return true
				end
				local n = cur.Name:upper()
				if n:find("MONTOR") or n:find("YAMAHA") or n:find("MIO") or n:find("HONDA") or n:find("BEAT")
					or n:find("VARIO") or n:find("NMAX") or n:find("PCX") or n:find("MOTOR") or n:find("BIKE")
					or n:find("CAR") or n:find("MOBIL") or n:find("VEHICLE") or n:find(player.Name:upper())
				then
					return true
				end
			end
			cur = cur.Parent
		end

		return false
	end
	local function isInManahanArea(obj)
		local cur = obj
		while cur and cur ~= workspace and cur ~= game do
			local n = cur.Name:upper()
			if n:find("MANAHAN") then return true end
			cur = cur.Parent
		end
		return false
	end

	local function shouldDestroyBuilding(obj)
		if not obj or not obj.Parent then return false end
		if obj:IsA("Terrain") or obj:IsA("Camera") then return false end
		if isVehicleOrSeatOrPlayer(obj) then return false end

		-- 🏙️ JANGAN HAPUS APAPUN DI AREA MANAHAN atau Folder JL_ dan Jalanan
		local cur = obj
		while cur and cur ~= workspace and cur ~= game do
			local n = cur.Name:upper()
			if n:find("MANAHAN") or n:sub(1, 3) == "JL_" or n:find("JALAN") or n:find("ROADSNEW") or n:find("TROTOARNEW") then
				return false
			end
			cur = cur.Parent
		end

		if isRoadOrGround(obj) then return false end

		local name = obj.Name:upper()
		if name:find("BUILDING") or name:find("BANGUNAN") or name:find("PROPS") or name:find("SETTING")
			or name:find("HOUSE") or name:find("LANTAI") or name:find("PAGAR") or name:find("RAIL")
			or name:find("POHON") or name:find("LAMPU") or name:find("BARRIER") or name:find("GEDUNG")
			or name:find("RUMAH") or name:find("PITCH") or name:find("SHIRT") or name:find("MEDKIT")
			or name:find("BILLBOARD") or name:find("CONE") or name:find("PANGGUNG") or name:find("HELMET")
			or name:find("SHOWCASE") or name:find("TITIK_KUMPUL") or name:find("FLAG") or name:find("SIGN")
			or name:find("DEALER") or name:find("GARAGE") or name:find("SATLANTAS") or name == "RS"
			or name:find("INDOMART") or name:find("PLATINUM") or name:find("GATAU") or name:find("PJL")
			or name:find("CAFE") or name:find("RUKO") or name:find("STOPPER") or name:find("MACHINE")
			or name:find("PROPBANGUNAN") or name:find("GATE") or name:find("KFC") or name:find("RESTAURANT")
			or name:find("WARUNG") or name:find("TOKO") or name:find("JOGLO") or name:find("STADION")
			or name:find("MOLDING") or name:find("MEJA") or name:find("KURSI")
		then
			return true
		end
		return false
	end

	local function destroyAllBuildings()
		pcall(function()
			for _, c in ipairs(workspace:GetChildren()) do
				if shouldDestroyBuilding(c) then
					pcall(function() c:Destroy() end)
				elseif c:IsA("Folder") or c:IsA("Model") then
					for _, ch in ipairs(c:GetChildren()) do
						if shouldDestroyBuilding(ch) then
							pcall(function() ch:Destroy() end)
						elseif ch:IsA("Folder") or ch:IsA("Model") then
							for _, sub in ipairs(ch:GetChildren()) do
								if shouldDestroyBuilding(sub) then
									pcall(function() sub:Destroy() end)
								end
							end
						end
					end
				end
			end
		end)
	end

	-- Auto-destroy newly streamed buildings KECUALI di area Manahan
	workspace.DescendantAdded:Connect(function(descendant)
		if shouldDestroyBuilding(descendant) then
			task.wait(0.05)
			if descendant and descendant.Parent and shouldDestroyBuilding(descendant) then
				pcall(function() descendant:Destroy() end)
			end
		end
	end)

	task.spawn(destroyAllBuildings)


	local function getGroundExcludeFilter(car)
		local filter = { car, player.Character }
		local existingPlate = workspace:FindFirstChild("__DdsSafetyPlate")
		if existingPlate then
			table.insert(filter, existingPlate)
		end
		for _, c in ipairs(workspace:GetChildren()) do
			if not isRoadOrGround(c) then
				table.insert(filter, c)
			end
		end
		return filter
	end

	local function safelySettleAndUnanchor(car, safePos)
		if not car then return end
		neutralizeBikeHazards(car)
		pcall(function()
			if safePos then
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = getGroundExcludeFilter(car)
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				local hit = workspace:Raycast(Vector3.new(safePos.X, safePos.Y + 30, safePos.Z), Vector3.new(0, -60, 0), rayParams)
				local groundY = hit and (hit.Position.Y + 0.3) or safePos.Y
				local groundPos = Vector3.new(safePos.X, groundY, safePos.Z)

				-- Spawn safety plate under parked bike only
				ensureSafetyPlate(groundPos, 35)
				local curPiv = car:GetPivot()
				car:PivotTo(CFrame.new(groundPos) * (curPiv - curPiv.Position))
			end
			-- Restore collision parts on the DDS motorcycle so tires firmly touch the road trigger
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					local name = part.Name:lower()
					if name == "dds_collision" or name == "primarypart" or name:find("tire") or name:find("wheel") or name == "paint" or name == "foot" or name == "p" then
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

	-- 🛡️ Synchronized Atomic Pivot & Physics Stabilization Leap
	local function teleportVehicleAcrossVoid(car, landPos, baseDir)
		-- 1. Pre-stream daratan seberang & bentangkan Safety Plate kokoh (60x60)
		requestStreamAsync(landPos)
		ensureSafetyPlate(landPos, 60)

		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChild("DriveSeat", true)
		local prim = car.PrimaryPart or seat or car:FindFirstChildWhichIsA("BasePart")

		local activeMissions = workspace:FindFirstChild("ActiveMissions")
		local passengerNpc = (activeMissions and activeMissions:FindFirstChild("RideGO_Passenger")) or workspace:FindFirstChild("RideGO_Passenger")
		local passRoot = passengerNpc and passengerNpc:FindFirstChild("HumanoidRootPart")

		local targetYaw = math.atan2(baseDir.X, baseDir.Z)
		local targetRot = CFrame.Angles(0, targetYaw, 0)
		local targetCF  = CFrame.new(landPos) * targetRot

		-- 2. Freeze physics (Anchored = true) to prevent weld snap / separation forces
		pcall(function()
			if prim then prim.Anchored = true end
			if seat then seat.Anchored = true end
			if root then root.Anchored = true end
			if passRoot then passRoot.Anchored = true end
		end)

		-- 3. Zero all velocities on car, driver, and passenger
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity  = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		if passRoot then
			passRoot.AssemblyLinearVelocity = Vector3.zero
			passRoot.AssemblyAngularVelocity = Vector3.zero
		end

		-- 4. Synchronized Atomic Leap (Teleport motorcycle, driver, and passenger together)
		car:PivotTo(targetCF)
		if root and seat then
			root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
		end
		if passRoot and seat then
			passRoot.CFrame = seat.CFrame + Vector3.new(0, 0.5, -1.2)
		end

		task.wait(0.1)

		-- 5. Re-establish driver seat connection firmly & disable ragdoll/falling damage
		if root and seat and hum then
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			hum.Sit = true
			pcall(function() seat:Sit(hum) end)
		end

		-- 6. Unanchor cleanly on top of safety plate
		pcall(function()
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.AssemblyLinearVelocity  = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
			if root then
				root.Anchored = false
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
			if passRoot then
				passRoot.Anchored = false
				passRoot.AssemblyLinearVelocity = Vector3.zero
				passRoot.AssemblyAngularVelocity = Vector3.zero
			end
		end)

		-- Double-check driver seat connection
		ensureDriverSeated()

		-- Nol-kan kembali seluruh kecepatan agar mulai melaju dari 0 km/h secara mulus
		pcall(function()
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity  = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
			if seat then
				seat.AssemblyLinearVelocity = Vector3.zero
				seat.AssemblyAngularVelocity = Vector3.zero
			end
		end)

		return landPos
	end

	-- 🌉 Void Bridge Engine: scan daratan seberang jurang (hanya sudut maju ke arah tujuan),
	-- lalu teleport vehicle ke ground seberang dengan safety plate.
	local function attemptVoidBridge(car, fromPos, toPos)
		local flatDiff = Vector3.new(toPos.X - fromPos.X, 0, toPos.Z - fromPos.Z)
		local totalDistToDest = flatDiff.Magnitude
		if totalDistToDest < 25 then return nil end
		local baseDir = flatDiff.Unit

		-- Pre-stream daratan tujuan di seberang
		requestStreamAsync(toPos)

		local brp = RaycastParams.new()
		local safetyPlate = workspace:FindFirstChild("__DdsSafetyPlate")
		local filter = { car, player.Character }
		if safetyPlate then table.insert(filter, safetyPlate) end
		brp.FilterDescendantsInstances = filter
		brp.FilterType = Enum.RaycastFilterType.Exclude

		-- Scan sampai jarak penuh ke destination (maksimal 3000 stud)
		local maxScan = math.min(totalDistToDest * 1.05, 3000)
		local stepSize = 35

		-- Scan HANYA sudut maju ke arah tujuan (0, ±10, ±20, ±30 deg).
		-- JANGAN PERNAH SCAN KE SAMPING / BELAKANG (±45, ±60, ±75, ±90) agar tidak melompat liar ke pulau lain!
		local scanAngles = { 0, 10, -10, 20, -20, 30, -30 }

		for _, ang in ipairs(scanAngles) do
			local scanRot = CFrame.Angles(0, math.rad(ang), 0)
			local flatDir = (scanRot * Vector3.new(baseDir.X, 0, baseDir.Z)).Unit

			local refY = fromPos.Y
			local inVoid = false
			local voidEnteredAt = nil

			for i = 1, math.ceil(maxScan / stepSize) do
				local curDist = i * stepSize
				local px = fromPos.X + flatDir.X * curDist
				local pz = fromPos.Z + flatDir.Z * curDist
				local testPos = Vector3.new(px, 0, pz)

				-- Request stream chunk setiap 100 stud pemindaian jurang
				if inVoid and curDist % 100 == 0 then
					requestStreamAsync(testPos)
				end

				local origin = Vector3.new(px, math.max(refY + 60, 80), pz)
				local hit = workspace:Raycast(origin, Vector3.new(0, -220, 0), brp)

				local solidY = hit and hit.Position.Y
				local isGround = solidY
					and solidY >= -30 and solidY <= 350
					and (not hit.Normal or hit.Normal.Y >= 0.12)

				if isGround then
					refY = solidY
					local isVoidGap = (inVoid and voidEnteredAt and (curDist - voidEnteredAt >= 35))
					local isElevatedLedge = (solidY >= fromPos.Y + 6 and curDist >= 15 and curDist <= 120)

					if isVoidGap or isElevatedLedge then
						local landDistToDest = (Vector3.new(toPos.X, 0, toPos.Z) - Vector3.new(px, 0, pz)).Magnitude
						-- 🛡️ Forward Progress Gate: Adaptif berdasarkan jarak total
						-- Jarak jauh (>200): butuh maju 40 stud. Jarak dekat (<200): cukup maju 5 stud saja
						local minProgress = totalDistToDest > 200 and 40 or 5
						if landDistToDest < totalDistToDest - minProgress then
							local landPos = Vector3.new(px, solidY + 0.5, pz)
							return teleportVehicleAcrossVoid(car, landPos, baseDir)
						end
					end
				else
					if not inVoid then
						inVoid = true
						voidEnteredAt = curDist
					end
				end
			end
		end

		return nil
	end

	-- 🛣️ Pure Road Navigation Engine
	local function driveVehicleTo(targetPos, speed, destroyPlateAfterStuds)
		if typeof(targetPos) == "CFrame" then
			targetPos = targetPos.Position
		end
		if typeof(targetPos) ~= "Vector3" then return false end

		local car, seat = getPlayerVehicle()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")

		if not car or not seat or not (hum and hum.SeatPart) then
			local ok = ensureDriverSeated()
			if not ok then
				warn("[HipHub DDS] driveVehicleTo: Pengemudi belum duduk, membatalkan jalan untuk keselamatan player")
				UI.Notify("⚠️ Belum Duduk", "Gagal menaiki motor, berkendara ditunda...", 2.5, "error")
				return false
			end
			car, seat = getPlayerVehicle()
			if not car or not seat then
				return false
			end
		end

		cancelActiveDrive()
		isDrivingActive = true
		neutralizeBikeHazards(car)

		local plateDestroyedDeferred = false
		if not destroyPlateAfterStuds or destroyPlateAfterStuds <= 0 then
			destroySafetyPlate()
		end

		requestStreamAsync(targetPos)

		speed = tonumber(speed) or tonumber(Config.taxiSpeed) or 60
		local startCF = car:GetPivot()
		local startP  = startCF.Position
		local destP   = targetPos

		if (startP - destP).Magnitude <= 6 then
			safelySettleAndUnanchor(car, destP)
			isDrivingActive = false
			return true
		end

		local rayFilter = { car, player.Character }
		local existingPlate = workspace:FindFirstChild("__DdsSafetyPlate")
		if existingPlate then table.insert(rayFilter, existingPlate) end

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = rayFilter
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local function probeGround(probePos, refY)
			local offsets = {
				Vector3.zero,
				Vector3.new(2, 0, 0),
				Vector3.new(-2, 0, 0),
				Vector3.new(0, 0, 2),
				Vector3.new(0, 0, -2)
			}

			-- 1. Lapis Utama: Menembak dari refY + 25 ke bawah sejauh 35 stud
			-- Mendukung tanjakan, tanggul jalan tinggi (+20 stud), flyover, dan turunan
			-- Menolak dasar jurang/lautan (Y < -10 atau drop drastis > 11 stud ke bawah)
			for _, off in ipairs(offsets) do
				local pos = probePos + off
				local rayOrigin = Vector3.new(pos.X, refY + 25, pos.Z)
				local hit = workspace:Raycast(rayOrigin, Vector3.new(0, -38, 0), rayParams)
				if hit and hit.Position.Y >= (refY - 11) and hit.Position.Y >= -10 and hit.Position.Y <= 350 and (not hit.Normal or hit.Normal.Y >= 0.12) then
					return hit.Position.Y + 0.3
				end
			end

			-- 2. Lapis Cadangan: HANYA jika refY belum ada (awal eksekusi script / baru spawn)
			if not refY or refY < -10 then
				for _, off in ipairs(offsets) do
					local pos = probePos + off
					local rayOrigin = Vector3.new(pos.X, 60, pos.Z)
					local hit = workspace:Raycast(rayOrigin, Vector3.new(0, -100, 0), rayParams)
					if hit and hit.Position.Y >= -5 and hit.Position.Y <= 350 and (not hit.Normal or hit.Normal.Y >= 0.12) then
						return hit.Position.Y + 0.3
					end
				end
			end

			return nil
		end

		-- Selective Noclip on vehicle parts
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = false
			end
		end

		local totalDist = (startP - destP).Magnitude
		local driveFinished = false
		local lastTick = os.clock()
		local lastGroundY = startP.Y

		local stuckLastDist   = totalDist
		local stuckLastTime   = os.clock()
		local stuckNudgeCount = 0

		local navHeading = nil
		local edgeFollowSign = 1
		local curHeadingAngle = math.atan2(((destP - startP).Unit).X, ((destP - startP).Unit).Z)
		local lastBridgeScanTime = 0
		local bridgeHoldUntil = 0
		local bridgeLandCF = nil
		local driveStartTime = os.clock()
		local currentSmoothSpeed = 0
		local cliffWaitStartTime = nil

		currentDriveConn = RunService.Heartbeat:Connect(function()
			if not isDrivingActive then
				if currentDriveConn then currentDriveConn:Disconnect() end
				driveFinished = true
				return
			end

			local now = os.clock()

			-- 🛑 Void Bridge Landing Hold: Tahan posisi kokoh di atas aspal seberang selama 2.0 detik
			if now < bridgeHoldUntil then
				lastTick = now
				ensureDriverSeated()
				pcall(function()
					if bridgeLandCF then
						car:PivotTo(bridgeLandCF)
					end
					for _, part in ipairs(car:GetDescendants()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = Vector3.zero
							part.AssemblyAngularVelocity = Vector3.zero
						end
					end
					if seat then
						seat.Throttle = 0
						seat.ThrottleFloat = 0
						seat.AssemblyLinearVelocity = Vector3.zero
						seat.AssemblyAngularVelocity = Vector3.zero
					end
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if root and seat then
						root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
					end
				end)
				return
			end

			local dt = math.clamp(now - lastTick, 0.001, 0.1)
			lastTick = now

			local carCF = car:GetPivot()
			local carPos = carCF.Position

			-- 🔒 Enforced Frame-Level Seat Lock: pastikan pengemudi tidak pernah terlempar dari motor saat melaju
			if hum and seat and (not hum.SeatPart or hum.SeatPart ~= seat) then
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0) end
				hum.Sit = true
				pcall(function() seat:Sit(hum) end)
			end

			-- 🦺 Emergency Void Fall Recovery: Jaring pengaman jika jatuh di bawah Y < -20
			if carPos.Y < -20 then
				local rescuePos = Vector3.new(carPos.X, math.max(lastGroundY, 5), carPos.Z)
				ensureSafetyPlate(rescuePos, 80)
				car:PivotTo(CFrame.new(rescuePos))
				lastGroundY = rescuePos.Y
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and seat then root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0) end
			end

			local delta = destP - carPos
			local flatDelta = Vector3.new(delta.X, 0, delta.Z)
			local dist = flatDelta.Magnitude

			-- Deferred safetyPlate removal
			if not plateDestroyedDeferred and destroyPlateAfterStuds and destroyPlateAfterStuds > 0 then
				local flatTravelled = Vector3.new(carPos.X - startP.X, 0, carPos.Z - startP.Z).Magnitude
				if flatTravelled >= destroyPlateAfterStuds then
					plateDestroyedDeferred = true
					destroySafetyPlate()
				end
			end

			if dist <= 3.5 then
				driveFinished = true
				if currentDriveConn then currentDriveConn:Disconnect() end
				return
			end

			-- Stuck Recovery
			local nowClock = os.clock()
			if dist < stuckLastDist - 2.5 then
				stuckLastDist = dist
				stuckLastTime = nowClock
			elseif (nowClock - stuckLastTime) >= 2.5 and stuckNudgeCount < 10 then
				stuckNudgeCount = stuckNudgeCount + 1
				stuckLastTime   = nowClock
				stuckLastDist   = dist

				local nudgeDir = flatDelta.Magnitude > 0.1 and flatDelta.Unit or Vector3.new(0, 0, -1)
				local nudgeDist = math.min(30, dist - 4)
				if nudgeDist > 0 then
					local nudgePos2D = Vector3.new(
						carPos.X + nudgeDir.X * nudgeDist,
						0,
						carPos.Z + nudgeDir.Z * nudgeDist
					)
					local nudgeRp = RaycastParams.new()
					nudgeRp.FilterDescendantsInstances = buildingFilter
					nudgeRp.FilterType = Enum.RaycastFilterType.Exclude
					local nudgeHit = workspace:Raycast(
						Vector3.new(nudgePos2D.X, math.max(lastGroundY + 50, 70), nudgePos2D.Z),
						Vector3.new(0, -150, 0),
						nudgeRp
					)
					if nudgeHit and nudgeHit.Position.Y >= -30 and nudgeHit.Position.Y <= 300 then
						local nudgeY = nudgeHit.Position.Y + 0.3
						local nudgeLand = Vector3.new(nudgePos2D.X, nudgeY, nudgePos2D.Z)

						pcall(function()
							ensureSafetyPlate(nudgeLand, 40)
							local yaw = math.atan2(nudgeDir.X, nudgeDir.Z)
							car:PivotTo(CFrame.new(nudgeLand) * CFrame.Angles(0, yaw, 0))
							for _, part in ipairs(car:GetDescendants()) do
								if part:IsA("BasePart") then
									part.AssemblyLinearVelocity  = Vector3.zero
									part.AssemblyAngularVelocity = Vector3.zero
								end
							end
							lastGroundY = nudgeY
						end)

						UI.Notify("🚨 Stuck Bypass", "Menembus rintangan, melanjutkan...", 1.5, "warning")
						return -- Selesaikan frame ini agar posisi bypass tidak ter-override
					else
						edgeFollowSign = -edgeFollowSign
						stuckLastTime = nowClock
					end
				end
			end

			-- 🏎️ 2-Stage Smooth Deceleration:
			-- Stage 1 (300 -> 50 stud): Kecepatan turun mulus dari slider speed ke 15 km/h
			-- Stage 2 (50 -> 0 stud): Kecepatan merayap presisi dari 15 km/h ke 0 km/h tepat di tujuan
			local targetSpeed = speed
			if dist < 50 then
				targetSpeed = math.max(0, 15 * (dist / 50))
			elseif dist < 300 then
				local factor = (dist - 50) / 250
				targetSpeed = 15 + math.max(0, speed - 15) * factor
			end

			local directGoalDir = flatDelta.Magnitude > 0.1 and flatDelta.Unit or Vector3.new(0, 0, -1)

			-- 🛑 2-Stage Cliff Lookahead: Pengereman menuju tepi jurang
			-- Stage 1 (300 -> 50 stud sebelum jurang): Kecepatan turun mulus dari slider speed ke 15 km/h
			-- Stage 2 (50 -> 0 stud sebelum tepi jurang): Kecepatan merayap dari 15 km/h ke 0 km/h tepat di tepi jurang
			local solidAheadDist = 300
			for lookDist = 15, 300, 15 do
				if lookDist >= dist then
					break
				end
				local testPos = carPos + directGoalDir * lookDist
				if not probeGround(testPos, lastGroundY) then
					solidAheadDist = lookDist
					break
				end
			end

			if solidAheadDist < 300 and solidAheadDist < dist then
				local cliffTargetSpeed = speed
				if solidAheadDist < 50 then
					cliffTargetSpeed = math.max(0, 15 * (solidAheadDist / 50))
				else
					local factor = (solidAheadDist - 50) / 250
					cliffTargetSpeed = 15 + math.max(0, speed - 15) * factor
				end
				targetSpeed = math.min(targetSpeed, cliffTargetSpeed)
			end

			-- 🛡️ Slew-Rate Limiter (Akselerasi & Deselerasi Halus Adaptif):
			-- Mencegah sentakan inersia tajam yang dapat memutus weld pengemudi!
			local maxAccelRate = 50 * dt
			local maxDecelRate = 65 * dt
			if currentSmoothSpeed < targetSpeed then
				currentSmoothSpeed = math.min(targetSpeed, currentSmoothSpeed + maxAccelRate)
			elseif currentSmoothSpeed > targetSpeed then
				currentSmoothSpeed = math.max(targetSpeed, currentSmoothSpeed - maxDecelRate)
			end

			local curSpeed = currentSmoothSpeed

			local stepDist = curSpeed * dt
			local probeDist = math.max(stepDist * 1.6, 4)

			local directProbePos = carPos + directGoalDir * probeDist
			local directHitY = probeGround(directProbePos, lastGroundY)

			local actualMoveDir = directGoalDir
			local targetElevY = lastGroundY

			if directHitY then
				cliffWaitStartTime = nil
				actualMoveDir = directGoalDir
				navHeading = directGoalDir
				targetElevY = directHitY
			else
				-- 🛑 TEPI JURANG: DILARANG KERAS BERJALAN MAJU KE ATAS RUANG HAMPA UDARA!
				-- Motor WAJIB diam total di atas aspal daratan asal sambil memindai daratan seberang.
				actualMoveDir = Vector3.zero
				stepDist = 0
				currentSmoothSpeed = 0
				targetElevY = lastGroundY

				local nowClock = os.clock()
				cliffWaitStartTime = cliffWaitStartTime or nowClock

				-- ⏱️ Timeout 5 Detik di Tepi Jurang: Jika tidak bisa melompat dalam 5s, batalkan orderan & reset RideGO
				if (nowClock - cliffWaitStartTime) >= 5.0 then
					cliffWaitStartTime = nil
					UI.Notify("⚠️ Jurang Terlalu Luas", "Membatalkan order & mereset status RideGO...", 3, "warning")
					cancelActiveDrive()
					task.spawn(function()
						resetTaxiDutyCycle(taxiToken)
					end)
					return
				end

				if (nowClock - lastBridgeScanTime) >= 0.25 then
					lastBridgeScanTime = nowClock
					local bridgeLanding = attemptVoidBridge(car, carPos, destP)
					if bridgeLanding then
						cliffWaitStartTime = nil
						lastGroundY = bridgeLanding.Y
						targetElevY = bridgeLanding.Y
						stuckLastTime = nowClock
						stuckLastDist = (destP - bridgeLanding).Magnitude
						local newDir = (destP - bridgeLanding).Unit
						curHeadingAngle = math.atan2(newDir.X, newDir.Z)
						bridgeLandCF = CFrame.new(bridgeLanding) * CFrame.Angles(0, curHeadingAngle, 0)
						bridgeHoldUntil = os.clock() + 2.0
						driveStartTime = os.clock() + 2.0
						UI.Notify("🌉 Melompati Jurang", "Mendarat di daratan seberang, menstabilkan posisi (2.0s)...", 2.0, "success")
						return -- 🛑 KRUSIAL: Selesaikan frame ini seketika agar posisi mendarat di seberang tidak ter-override kembali ke tepi tebing!
					end
				end
			end

			-- Smooth vertical descent/ascent rate
			local maxVertStep = math.max(50 * dt, 2.5)
			local chosenY = lastGroundY
			if chosenY > targetElevY then
				chosenY = math.max(targetElevY, chosenY - maxVertStep)
			elseif chosenY < targetElevY then
				chosenY = math.min(targetElevY, chosenY + maxVertStep)
			end
			lastGroundY = chosenY

			local newX = carPos.X + actualMoveDir.X * stepDist
			local newZ = carPos.Z + actualMoveDir.Z * stepDist
			local newPos = Vector3.new(newX, chosenY, newZ)

			-- Smooth Angular Steering
			if actualMoveDir.Magnitude > 0.05 then
				local targetAngle = math.atan2(actualMoveDir.X, actualMoveDir.Z)
				local angleDiff = (targetAngle - curHeadingAngle + math.pi) % (2 * math.pi) - math.pi
				curHeadingAngle = curHeadingAngle + math.clamp(angleDiff, -12 * dt, 12 * dt)
			end

			local currentRot = CFrame.Angles(0, curHeadingAngle, 0)
			local currentCF  = CFrame.new(newPos) * currentRot

			pcall(function()
				car:PivotTo(currentCF)

				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.Anchored = false
					end
				end

				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end

				local activeMissions = workspace:FindFirstChild("ActiveMissions")
				local passengerNpc = (activeMissions and activeMissions:FindFirstChild("RideGO_Passenger")) or workspace:FindFirstChild("RideGO_Passenger")
				if passengerNpc then
					for _, part in ipairs(passengerNpc:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end

				local velocityVec = actualMoveDir * curSpeed
				if seat:IsA("VehicleSeat") then
					seat.Throttle = actualMoveDir.Magnitude > 0 and 1 or 0
					seat.ThrottleFloat = actualMoveDir.Magnitude > 0 and 1 or 0
					seat.AssemblyLinearVelocity = velocityVec
				end
				local prim = car.PrimaryPart or seat
				if prim then
					prim.AssemblyLinearVelocity = velocityVec
				end

				-- 🔒 Sinkronisasi Momentum Tubuh Pengemudi & Penumpang
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and seat and hum then
					if not hum.Sit or hum.SeatPart ~= seat then
						root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
						hum.Sit = true
						seat:Sit(hum)
					end
					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
					root.AssemblyLinearVelocity = velocityVec
					root.AssemblyAngularVelocity = Vector3.zero
				end

				if passengerNpc then
					local passHrp = passengerNpc:FindFirstChild("HumanoidRootPart")
					if passHrp then
						passHrp.AssemblyLinearVelocity = velocityVec
						passHrp.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
		end)

		while not driveFinished and isDrivingActive do
			task.wait(0.03)
		end

		if currentDriveConn then
			pcall(function() currentDriveConn:Disconnect() end)
			currentDriveConn = nil
		end

		-- Natural smooth stop on road: spawn safety plate and restore tire collision
		pcall(function()
			local curPos = car:GetPivot().Position
			ensureSafetyPlate(curPos, 45)

			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					local name = part.Name:lower()
					if name == "dds_collision" or name == "primarypart" or name:find("tire") or name:find("wheel") or name == "paint" or name == "foot" or name == "p" then
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
				seat.AssemblyAngularVelocity = Vector3.zero
			end
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and seat then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end)

		isDrivingActive = false
		return (car:GetPivot().Position - destP).Magnitude <= 15
	end

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

	------------------------------------------------
	-- 🚕 2. AUTO RIDEGO TAXI CONTROLLER
	------------------------------------------------

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

	local function isPassengerOnboard()
		if passengerSeated then return true end
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

	local function executeTripAsync(token, name, initialPickup, initialDrop)
		if taxiBusy then return end
		if not token or token == lastCompletedToken then return end

		taxiBusy = true
		taxiToken = token
		passengerSeated = false
		taxiPickupPos = parsePosition(initialPickup)
		taxiDropPos   = parsePosition(initialDrop)

		setTaxiState("NEW_ORDER_DETECTED")
		setTaxiState("PICKING_UP")

		-- 1. Accept Order
		TaxiEvent:FireServer("AcceptOrder", token)
		task.wait(0.3)
		UI.Notify("✅ Order Accepted", "Passenger: " .. tostring(name or "Passenger"), 2, "success")

		-- 2. Mount bike
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.SeatPart) then
			UI.Notify("🏍️ Mounting Bike", "Menaiki motor...", 2, "warning")
			local seated = ensureDriverSeated()
			if not seated then
				taxiBusy = false
				taxiToken = nil
				setTaxiState("WAITING_FOR_NEXT_ORDER")
				return
			end
		end

		-- 3. Wait for pickup coordinates
		local waitStart = tick()
		while not taxiPickupPos and taxiActive and (tick() - waitStart < 5) do
			task.wait(0.2)
		end

		-- 4. Drive to Pickup
		if taxiPickupPos and taxiActive then
			UI.Notify("🏍️ Heading to Pickup", "Driving to passenger...", 2, "warning")
			driveVehicleTo(taxiPickupPos, Config.taxiSpeed)
		end

		-- 5. Wait for passenger boarding
		if taxiPickupPos and taxiActive then
			UI.Notify("Arrived at Pickup 📍", "Waiting for passenger to board...", 3, "warning")

			local car, seat = getPlayerVehicle()
			if car then
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
			if seat then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
			end
			ensureDriverSeated()

			local waitStartBoard = tick()
			while not isPassengerOnboard() and taxiActive and (tick() - waitStartBoard < 25) do
				local checkHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if not (checkHum and checkHum.SeatPart) then
					mountBike()
				end
				task.wait(0.4)
			end

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
				if taxiActive then
					task.wait(2)
					TaxiEvent:FireServer("GoOnline")
				end
				return
			end
		end

		task.wait(0.3)

		-- 6. Drive to Drop-off
		if not taxiDropPos and taxiActive then
			local dropWait = tick()
			while not taxiDropPos and taxiActive and (tick() - dropWait < 5) do
				task.wait(0.2)
			end
		end

		local tripStartTime = tick()
		local tripDistance = (taxiPickupPos and taxiDropPos) and (Vector3.new(taxiDropPos.X, 0, taxiDropPos.Z) - Vector3.new(taxiPickupPos.X, 0, taxiPickupPos.Z)).Magnitude or 1000

		if taxiDropPos and taxiActive then
			setTaxiState("DRIVING_TO_DESTINATION")
			UI.Notify("📍 Heading to Drop-off", "Delivering passenger to destination...", 2, "warning")
			driveVehicleTo(taxiDropPos, Config.taxiSpeed, 50)

			setTaxiState("DROPPING_OFF")
			local car, seat = getPlayerVehicle()
			if car then
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
			if seat then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
			end
			ensureDriverSeated()

			UI.Notify("Arrived at Destination 🏁", "Waiting for passenger disembark...", 2, "success")
			local disembarkWait = tick()
			local verifyCount = 0
			local lastVerifyCheck = 0

			while isPassengerOnboard() and taxiActive do
				local nowT = tick()

				-- Deteksi notifikasi "Memverifikasi rute perjalananmu" (Bahasa Indonesia & English)
				local isVerifying = false
				pcall(function()
					local pGui = player:FindFirstChild("PlayerGui")
					if pGui then
						for _, g in ipairs(pGui:GetDescendants()) do
							if (g:IsA("TextLabel") or g:IsA("TextButton")) and g.Visible then
								local txt = (g.Text or ""):lower()
								if txt:find("memverifikasi rute") or txt:find("verifying your trip route")
									or txt:find("tunggu sebentar") or txt:find("hold on a moment")
									or txt:find("verifikasi rute") or txt:find("verifying trip")
								then
									isVerifying = true
									break
								end
							end
						end
					end
				end)

				if isVerifying and (nowT - lastVerifyCheck >= 1.2) then
					lastVerifyCheck = nowT
					verifyCount = verifyCount + 1
					UI.Notify("⚠️ Verifikasi Rute (" .. verifyCount .. "/5)", "Menunggu konfirmasi server DDS...", 1.5, "warning")
					if verifyCount >= 5 then
						UI.Notify("❌ Batas Verifikasi Tercapai", "Mereset status RideGO untuk orderan baru...", 3, "error")
						break
					end
				end

				-- Batas waktu maksimal disembark 10 detik
				if (nowT - disembarkWait > 10) then
					UI.Notify("⚠️ Disembark Timeout", "Penumpang tidak turun. Mereset RideGO...", 3, "warning")
					break
				end

				task.wait(0.35)
			end

			-- Jika penumpang belum turun (gagal verifikasi rute > 5x atau timeout):
			-- Lakukan siklus Reset RideGO (GESER UNTUK OFFLINE -> ON KEMBALI)
			if isPassengerOnboard() and taxiActive then
				UI.Notify("🔄 Resetting Duty", "Mematikan & menyalakan kembali RideGO...", 3, "warning")
				resetTaxiDutyCycle(token)
				return
			end

			task.wait(0.5)
		end

		-- 7. Complete Trip & Acknowledge
		if taxiActive then
			TaxiEvent:FireServer("AckTripComplete")
			UI.Notify("🏆 Trip Complete!", "Fare earned. Ready for next order!", 2, "success")
		end

		lastCompletedToken = token
		taxiBusy = false
		taxiToken = nil
		taxiPickupPos = nil
		taxiDropPos = nil
		passengerSeated = false

		setTaxiState("WAITING_FOR_NEXT_ORDER")
	end

	-- Taxi Remote Events Listener
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

				if not token or token == lastCompletedToken then return end

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
				UI.Notify("🏆 Order Selesai!", "Pembayaran diterima & penumpang turun.", 3, "success")
				task.wait(0.5)
				TaxiEvent:FireServer("AckTripComplete")
				if not taxiBusy then
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
				UI.Notify("Order Reset", "Waiting for next offer...", 2, "warning")
				if taxiActive then
					task.wait(2)
					TaxiEvent:FireServer("GoOnline")
				end
			end
		end)
	end

	-- Phone Screen Overlay Poller & Auto-Dismiss Complete Screen
	local function startPhoneOverlayPoller()
		if taxiOverlayPoller then return end
		taxiOverlayPoller = task.spawn(function()
			local lastKeepAliveTime = tick()
			while taxiActive do
				task.wait(0.2)
				if taxiActive then
					pcall(function()
						local pg = player:FindFirstChild("PlayerGui")
						local phone = pg and pg:FindFirstChild("Phone")
						local rideGO = phone and phone:FindFirstChild("RideGO", true)
						local appFrame = rideGO and rideGO:FindFirstChild("AppFrame")
						local complete = appFrame and appFrame:FindFirstChild("CompleteOverlay")
						local overlay = appFrame and appFrame:FindFirstChild("OrderOverlay")

						-- 1. Auto-Dismiss Complete Screen agar UI tidak pernah nyangkut di ringkasan trip
						if complete and complete.Visible then
							complete.Visible = false
							if TaxiEvent then
								TaxiEvent:FireServer("AckTripComplete")
							end
						end

						-- 2. Auto-Accept orderan baru yang masuk
						if overlay and overlay.Visible and not taxiBusy then
							if #_G.HipHubTaxiLog > 0 then
								local last = _G.HipHubTaxiLog[#_G.HipHubTaxiLog]
								local args = last.args or {}
								if args[1] == "OrderOffer" and type(args[2]) == "table" and args[2].Token then
									if args[2].Token ~= lastCompletedToken then
										overlay.Visible = false
										task.spawn(executeTripAsync, args[2].Token, args[2].PassengerName, args[2].PickupPos, args[2].DropPos)
									end
								end
							end
						end

						-- 3. Matchmaking Keep-Alive Heartbeat (setiap 35s saat menganggur)
						if not taxiBusy and (tick() - lastKeepAliveTime >= 35) then
							lastKeepAliveTime = tick()
							ensureDriverSeated()
							if TaxiEvent then
								TaxiEvent:FireServer("GoOnline")
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
	-- 🖼️ 3. UI COMPONENTS IN FARM TAB
	------------------------------------------------
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
end)

if not success then
	warn("[HipHub DDS Farm Error]:", err)
end
