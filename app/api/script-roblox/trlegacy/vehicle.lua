-- ️ HipHub TR Legacy — Universal Motorcycle Spawner & Mobility Suite
-- Handles Searchable Motorcycle Spawning (97+ Models), Dynamic Seating, Speed Boost, Guardian & Flight

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Vehicle"] and UI.tabs["Vehicle"].Frame
	if not tab then return end

	local Config = _G.HipHubConfig and _G.HipHubConfig.vehicle or {
		selectedVehicle = "Kasaki z800 2015",
		speedMultiplier = 1.0,
		antiFall = true,
		autoMount = true,
		instantBrake = true,
		vehicleFly = false,
		flySpeed = 120,
		vehicleNoclip = false
	}

	if not Config.selectedVehicle then Config.selectedVehicle = "Kasaki z800 2015" end

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	-- Complete verified catalog of 97 TR Legacy Motorcycles (Alphabetical)
	local ALL_MOTORCYCLES = {
		"April RS250 2001",
		"April RS660 2021",
		"April RSV1KR Racing Modified 2003",
		"April RSV4 APRC ABS 2014",
		"April RSV4 E5 2021",
		"April RXV RR Racing Modified 2015",
		"April Tuono V4 Factory 2015",
		"Bomoto Yb8 Furino 1992",
		"BZM HP4 RACE 2017",
		"BZM M1KRR 2020",
		"BZM M1KRR Racing Modified 2021",
		"BZM PRAEM S1KRR 2017",
		"BZM S1KR 2021",
		"BZM S1KRR 2005",
		"BZM S1KRR 2015",
		"BZM S1KRR 2019",
		"BZM S1KRR 2019 RACING MODIFIED",
		"BZM S1KRR 2023",
		"BZM S1KRR Street Edition 2015",
		"BZM S1KXR 2017",
		"Ducatti 1098r 2008",
		"Ducatti 1098R Racing Modified 2008",
		"Ducatti 1199 Moto Rapid 2017",
		"Ducatti 1299 Panigale S 2017",
		"Ducatti 916 1998",
		"Ducatti 999r Racing Modified 2006",
		"Ducatti Diavel Carbon 2014",
		"Ducatti Hypermotard 1100 EVO SP 2012",
		"Ducatti StreetFighter V4",
		"Ducatti V4 2018",
		"Ducatti V4 SP2 2022",
		"Ducatti V4r 2019",
		"Ducatti V4r Endurance Modified 2019",
		"Honde Cbr 1000rr Fireblade 2014",
		"Honde CBR1KRR ENDURANCE",
		"Honde CBR1KRR Fireblade SP 2019",
		"Honde CBR1KRR-R 2020",
		"Honde CBR1KRR-R FIREBLADE SP 2022",
		"Honde Cbr250r 2017",
		"Honde Cbr600rr 2015",
		"Honde Nr750 1992",
		"Honde Nsr 125 1992",
		"Honde Nsr 250",
		"Honde Nsr 250 1995",
		"Honde RC45",
		"Honde VTR1000 SP2 2006",
		"K1m 450 SX-F 2012",
		"K1m 600 SMC 2017",
		"K1m RC8R 1190 2014",
		"K1m Super Duke 1290r 2019",
		"K1m Super Duke Gt 2017",
		"Kasaki Ninja 300 2017",
		"Kasaki Ninja H2 2015",
		"Kasaki Z H2 2022",
		"Kasaki z1000 2014",
		"Kasaki z800 2015",
		"Kasaki Zx-10r 2015",
		"Kasaki Zx-10r DRAG EDITION 2006",
		"Kasaki Zx-10r Racing Modified 2019",
		"Kasaki Zx-10rr 2024",
		"Kasaki Zx-14r 2021",
		"Kasaki Zx-6R 636 2005",
		"Kasaki Zx-6r 2017",
		"Kasaki Zx-6r 2019",
		"Kasaki Zx-7rr 1996",
		"Kasaki ZZR1400 2015",
		"Mz Agusta Boldor 2017",
		"Mz Agusta Brutale 1000  Serie Oro 2019",
		"Mz Agusta Superveloce800 2019",
		"Mz F3 2014",
		"Mz F4 Tamborini 2006",
		"Mz F4rr 2019",
		"Mz Rvs #1 2018",
		"Noxon Dominate SS 2017",
		"Nurtun V4 1200 2017",
		"Trump 675r Racing Modified",
		"Trump Daytona 675R",
		"Trump Jaguar Sport 2016",
		"Trump Speed Triple 1200RR 2025",
		"Yamha MT-09 SP 2023",
		"Yamha R1M Racing Modified 2025",
		"Yamha R7 Racing Modified 1998",
		"Yamha Tzr 250r 1994",
		"Yamha Yz450f supermoto 2011",
		"Yamha Yzf R1 1998",
		"Yamha Yzf R1 2014",
		"Yamha Yzf R1 Drag Edition 2006",
		"Yamha Yzf R1m 2015",
		"Yamha Yzf R1m 2019",
		"Yamha Yzf R1m 2020",
		"Yamha Yzf R3 2019",
		"Yamha Yzf R3 Racing Modified 2019",
		"Yamha Yzf R6 2015",
		"Yamha Yzr 500 1992",
		"Zuzuki Gsxr 1000 K5 2005",
		"Zuzuki Gsxr 1000r 2017",
		"Zuzuki Gsxr 750 1998",
		"Zuzuki Hayabusa 2016",
		"Zuzuki Hayabusa 2022",
		"Zuzuki Hayabusa Racing Modified 2015"
	}

	-- Find player's active motorbike in workspace
	local function getPlayerBike(preferredModel)
		local vFolder = workspace:FindFirstChild("Vehicles")
		if not vFolder then return nil end
		local playerVehicles = vFolder:FindFirstChild(player.Name)
		if not playerVehicles then return nil end

		local targetName = preferredModel or Config.selectedVehicle or "Kasaki z800 2015"
		local bike = playerVehicles:FindFirstChild(targetName)
		if not bike or not bike:FindFirstChild("DriveSeat", true) then
			bike = nil
			for _, child in ipairs(playerVehicles:GetChildren()) do
				if child:IsA("Model") and (child:FindFirstChild("DriveSeat", true) or child:FindFirstChildWhichIsA("VehicleSeat", true)) then
					bike = child
					break
				end
			end
		end

		if not bike then return nil end

		local seat = bike:FindFirstChild("DriveSeat", true) or bike:FindFirstChildWhichIsA("VehicleSeat", true)
		if not seat then return nil end

		local primary = bike.PrimaryPart or seat or bike:FindFirstChildWhichIsA("BasePart")
		if not primary then return nil end

		-- CRITICAL HEALTH CHECK: If bike is falling in the void or destroyed underground, ignore it!
		if primary.Position.Y < -15 then
			return nil
		end

		-- If player is at Dealership / spawn area but bike is abandoned far away (> 500 studs), treat as abandoned
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local dist = (hrp.Position - primary.Position).Magnitude
			if dist > 500 and hrp.Position.Magnitude < 400 then
				return nil
			end
		end

		return bike, seat, primary
	end

	_G.HipHub_GetPlayerBike = getPlayerBike

	-- Safe Warp Client Resolver (Bypasses executor module context restrictions)
	local function getWarpClient(clientName)
		local client = nil
		local setIdent = setthreadidentity or setidentity or setthreadcontext
		local oldIdentity = (getthreadidentity and getthreadidentity()) or 8
		pcall(function()
			if setIdent then setIdent(2) end
			local Warp = require(ReplicatedStorage.Modules.Warp)
			client = Warp.Client(clientName)
			if setIdent then setIdent(oldIdentity) end
		end)
		if not client then
			pcall(function()
				if setIdent then setIdent(2) end
				local getClient = require(ReplicatedStorage.Modules.Warp.Index.Client.Index)
				client = getClient(clientName)
				if setIdent then setIdent(oldIdentity) end
			end)
		end
		return client
	end

	-- Universal Vehicle Spawner via Dealership Network Remote
	local function spawnVehicle(modelName)
		modelName = modelName or Config.selectedVehicle or "Kasaki z800 2015"
		local success = false
		pcall(function()
			local dClient = getWarpClient("Dealership")
			if dClient and dClient.Fire then
				dClient:Fire(true, modelName, "Spawn")
				success = true
			end
		end)
		if success then
			UI.Notify("Vehicle", "Spawning " .. tostring(modelName) .. "...", 2, "info")
			return true
		else
			UI.Notify("Vehicle", "Failed to access Dealership network.", 3, "error")
			return false
		end
	end

	_G.HipHub_SpawnVehicle = spawnVehicle
	_G.HipHub_SpawnKasaki = spawnVehicle

	-- Ensure player is seated on bike's DriveSeat with authentic riding pose & Speedometer HUD
	local function ensureDriverSeated(autoSpawn)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		
		-- RESPAWN RECOVERY: If player is currently dead or respawning, wait for character to rebuild
		if not hum or hum.Health <= 0 or not char:FindFirstChild("HumanoidRootPart") then
			local tRespawnWait = os.clock() + 5.0
			while os.clock() < tRespawnWait do
				task.wait(0.3)
				char = player.Character
				hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") then
					break
				end
			end
		end

		if not hum or hum.Health <= 0 then return false end

		local bike, seat, primary = getPlayerBike()
		local newlySpawned = false

		if not bike and autoSpawn then
			newlySpawned = true
			spawnVehicle(Config.selectedVehicle)
			-- Step 1: Wait for bike model and parts to appear in workspace
			local start = os.clock()
			while (os.clock() - start) < 6.0 do
				task.wait(0.2)
				bike, seat, primary = getPlayerBike()
				if bike and seat and primary and #bike:GetChildren() >= 10 then break end
			end
		end

		if not bike or not seat or not primary then return false end

		-- Step 2: Ensure wheels are collidable so bike won't glitch through the ground
		pcall(function()
			for _, desc in ipairs(bike:GetDescendants()) do
				if desc:IsA("BasePart") then
					local n = desc.Name:lower()
					if n:find("wheel") or n:find("tire") or n:find("tireh") or desc.CollisionGroup == "BikeWheel" then
						desc.CanCollide = true
					end
				end
			end
		end)

		-- Step 3: Wait until bike is fully spawned AND grounded & settled on terrain
		if newlySpawned or (primary.AssemblyLinearVelocity.Magnitude > 8.0) then
			local groundTimeout = os.clock() + 4.0
			while os.clock() < groundTimeout do
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = { bike, char }
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				local ray = workspace:Raycast(primary.Position, Vector3.new(0, -35, 0), rayParams)
				if ray then
					local groundDist = primary.Position.Y - ray.Position.Y
					local velY = primary.AssemblyLinearVelocity.Y
					if groundDist <= 3.8 and math.abs(velY) < 1.5 then
						break
					end
				end
				task.wait(0.1)
			end
			task.wait(0.6)
		end

		local pGui = player:FindFirstChild("PlayerGui")
		local hasGauge = pGui and pGui:FindFirstChild("Gauge_EXRGARAGE", true)

		-- If already seated and has the gauge HUD active, authentic riding pose is active!
		if hum.SeatPart == seat and hasGauge and hasGauge.Visible then
			return true
		end

		-- If seated without gauge HUD (buggy sit state), jump out first so prompt can properly re-seat with HUD
		if hum.SeatPart == seat and (not hasGauge or not hasGauge.Visible) then
			hum.Sit = false
			task.wait(0.3)
		end

		-- Priority 1: Official Game VehiclePrompt (Mounts bike with custom riding animations & Speedometer HUD)
		local prompt = seat:FindFirstChild("VehiclePrompt") or seat:FindFirstChildWhichIsA("ProximityPrompt") or bike:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt and fireproximityprompt then
			pcall(function()
				char:PivotTo(seat.CFrame + Vector3.new(0, 1.2, 0))
				task.wait(0.2)
				prompt.Enabled = true
				prompt.RequiresLineOfSight = false
				prompt.MaxActivationDistance = 50
				fireproximityprompt(prompt, 0)
			end)
			local waitStart = os.clock()
			while (os.clock() - waitStart) < 2.0 do
				task.wait(0.1)
				if hum.SeatPart == seat then break end
			end
		end

		-- Priority 2: Fallback to direct sit if prompt failed
		if hum.SeatPart ~= seat then
			pcall(function()
				seat:Sit(hum)
			end)
			task.wait(0.2)
		end

		-- Step 4: Verify Speedometer HUD (Gauge_EXRGARAGE)
		local waitHud = os.clock()
		while (os.clock() - waitHud) < 2.0 do
			hasGauge = pGui and pGui:FindFirstChild("Gauge_EXRGARAGE", true)
			if hasGauge and hasGauge.Visible then break end
			task.wait(0.1)
		end

		return hum.SeatPart == seat
	end

	_G.HipHub_EnsureSeated = ensureDriverSeated

	------------------------------------------------
	-- ️ UI SECTIONS: VEHICLE TAB
	------------------------------------------------
	local bikeSection = UI.AddSection(tab, "Motorcycle Spawner & Controls", 1)

	local bikeStatusCard = UI.AddStatsCard(bikeSection, "Active Motorcycle", "Searching...", 2)

	local bikeDropdown = UI.AddDropdown(bikeSection, "Pilih Motor (Searchable)", ALL_MOTORCYCLES, Config.selectedVehicle or "Kasaki z800 2015", function(val)
		Config.selectedVehicle = val
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 3)

	UI.AddButton(bikeSection, "Spawn Motor Terpilih", function()
		spawnVehicle(Config.selectedVehicle)
	end, 4)

	UI.AddButton(bikeSection, "Mount / Sit Driver Seat", function()
		if ensureDriverSeated(true) then
			UI.Notify("Vehicle", "Successfully seated on motorcycle.", 2, "success")
		else
			UI.Notify("Vehicle", "Could not sit on motorcycle.", 2, "warning")
		end
	end, 5, "secondary")

	local autoMountToggle = UI.AddToggle(bikeSection, "Auto Re-Spawn & Mount", Config.autoMount, function(enabled)
		Config.autoMount = enabled
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 6)

	-- Physics Section
	local tuningSection = UI.AddSection(tab, "Tuning & Handling", 7)

	local speedBoostToggle = UI.AddToggle(tuningSection, "Speed & Torque Multiplier", Config.speedMultiplier > 1.0, function(enabled)
		if not enabled then
			Config.speedMultiplier = 1.0
		end
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 8)

	local speedBoostSlider = UI.AddSlider(tuningSection, "Speed Multiplier Boost", 1.0, 5.0, Config.speedMultiplier or 1.0, function(val)
		Config.speedMultiplier = val
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 0.1, "x", 9)

	local antiFallToggle = UI.AddToggle(tuningSection, "Anti-Fall / Auto-Upright Guardian", Config.antiFall, function(enabled)
		Config.antiFall = enabled
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 10)

	local instantBrakeToggle = UI.AddToggle(tuningSection, "Instant Brake (Space / S)", Config.instantBrake, function(enabled)
		Config.instantBrake = enabled
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 11)

	-- Mobility Section
	local mobilitySection = UI.AddSection(tab, "Mobility & Flight", 12)

	local flyToggle = UI.AddToggle(mobilitySection, "Motorcycle Flight", Config.vehicleFly, function(enabled)
		Config.vehicleFly = enabled
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 13)

	local flySpeedSlider = UI.AddSlider(mobilitySection, "Flight Speed", 50, 400, Config.flySpeed or 120, function(val)
		Config.flySpeed = val
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 5, " studs/s", 14)

	local noclipToggle = UI.AddToggle(mobilitySection, "Vehicle Noclip", Config.vehicleNoclip, function(enabled)
		Config.vehicleNoclip = enabled
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 15)

	------------------------------------------------
	-- ️ RUNTIME PHYSICS & CONTROLLERS
	------------------------------------------------

	-- Status monitor
	task.spawn(function()
		while true do
			task.wait(1.0)
			pcall(function()
				local bike, seat = getPlayerBike()
				if bike and seat then
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local isSeated = hum and hum.SeatPart == seat
					local pGui = player:FindFirstChild("PlayerGui")
					local hasGauge = pGui and pGui:FindFirstChild("Gauge_EXRGARAGE", true)
					local properSit = isSeated and hasGauge and hasGauge.Visible

					bikeStatusCard.Set(bike.Name .. (properSit and " (Seated)" or (isSeated and " (Seated - No HUD)" or " (Unmounted)")))

					if not isSeated and Config.autoMount and not _G.HipHub_IsAutoRacing and not _G.HipHub_IsAutoDriving then
						ensureDriverSeated(false)
					end
				else
					bikeStatusCard.Set("None (Despawned)")
					if Config.autoMount and not _G.HipHub_IsAutoRacing and not _G.HipHub_IsAutoDriving then
						ensureDriverSeated(true)
					end
				end
			end)
		end
	end)

	-- Heartbeat physics loop
	RunService.Heartbeat:Connect(function(dt)
		local bike, seat, primary = getPlayerBike()
		if not bike or not seat or not primary then return end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local isSeated = hum and hum.SeatPart == seat
		if not isSeated then return end

		-- Anti-Fall / Auto-Upright Guardian
		if Config.antiFall and not Config.vehicleFly and not _G.HipHub_IsAutoRacing then
			local currentCF = primary.CFrame
			local _, yaw, _ = currentCF:ToEulerAnglesYXZ()
			primary.CFrame = CFrame.new(currentCF.Position) * CFrame.Angles(0, yaw, 0)
			primary.AssemblyAngularVelocity = Vector3.new(0, primary.AssemblyAngularVelocity.Y, 0)
		end

		-- Speed Multiplier
		if Config.speedMultiplier > 1.0 and seat.Throttle ~= 0 and not Config.vehicleFly then
			local forward = seat.CFrame.LookVector * (seat.Throttle * (Config.speedMultiplier - 1.0) * 45)
			primary.AssemblyLinearVelocity = primary.AssemblyLinearVelocity + Vector3.new(forward.X, 0, forward.Z)
		end

		-- Instant Brake
		if Config.instantBrake and (UserInputService:IsKeyDown(Enum.KeyCode.Space) or (seat.Throttle < 0 and primary.AssemblyLinearVelocity.Magnitude > 10)) then
			primary.AssemblyLinearVelocity = Vector3.new(0, primary.AssemblyLinearVelocity.Y, 0)
			primary.AssemblyAngularVelocity = Vector3.zero
		end

		-- Noclip
		if Config.vehicleNoclip then
			for _, part in ipairs(bike:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end

		-- Vehicle Flight
		if Config.vehicleFly then
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero

			local cam = workspace.CurrentCamera
			local moveDir = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

			if moveDir.Magnitude > 0 then
				local step = moveDir.Unit * (Config.flySpeed * dt)
				bike:PivotTo(bike:GetPivot() + step)
			end
		end
	end)

	-- Export global vehicle API
	_G.HipHubVehicle = {
		GetPlayerBike = getPlayerBike,
		GetActiveVehicle = getPlayerBike,
		SpawnBike = spawnVehicle,
		SpawnVehicle = spawnVehicle,
		MountBike = function() ensureDriverSeated(true) end,
		EnsureDriverSeated = ensureDriverSeated
	}
end)

if not success then
	warn("[HipHub TR Legacy Vehicle Error]:", err)
end
