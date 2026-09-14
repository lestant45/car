-- 🏍️ HipHub TR Legacy — Vehicle Controller & Kasaki z800 2015 Integration
-- Handles Motorcycle Spawning, Driver Seating, Torque/Speed Boosting, Anti-Fall Guardian & Mobility

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Vehicle"] and UI.tabs["Vehicle"].Frame
	if not tab then return end

	local Config = _G.HipHubConfig and _G.HipHubConfig.vehicle or {
		speedMultiplier = 1.0,
		antiFall = true,
		autoMount = true,
		instantBrake = true,
		vehicleFly = false,
		flySpeed = 120,
		vehicleNoclip = false
	}

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	-- Find player's active motorbike in workspace
	local function getPlayerBike()
		local vFolder = workspace:FindFirstChild("Vehicles")
		if not vFolder then return nil end
		local playerVehicles = vFolder:FindFirstChild(player.Name)
		if not playerVehicles then return nil end

		-- Check for Kasaki z800 2015 first, ensuring it has DriveSeat
		local bike = playerVehicles:FindFirstChild("Kasaki z800 2015")
		if not bike or not bike:FindFirstChild("DriveSeat", true) then
			bike = nil
			for _, child in ipairs(playerVehicles:GetChildren()) do
				if child:IsA("Model") and child:FindFirstChild("DriveSeat", true) then
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
				-- Player is at central spawn, but bike was left in a distant race zone
				return nil
			end
		end

		return bike, seat, primary
	end

	_G.HipHub_GetPlayerBike = getPlayerBike

	-- Spawn Kasaki z800 2015
	local function spawnKasakiZ800()
		local success = false
		pcall(function()
			local old = (getthreadidentity and getthreadidentity()) or 8
			if setthreadidentity then setthreadidentity(2) end
			local Warp = require(ReplicatedStorage.Modules.Warp)
			local dClient = Warp.Client("Dealership")
			dClient:Fire(true, "Kasaki z800 2015", "Spawn")
			if setthreadidentity then setthreadidentity(old) end
			success = true
		end)
		if success then
			UI.Notify("Vehicle", "Spawning Kasaki z800 2015...", 2, "info")
			return true
		else
			UI.Notify("Vehicle", "Failed to access Dealership network.", 3, "error")
			return false
		end
	end

	_G.HipHub_SpawnKasaki = spawnKasakiZ800

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
			spawnKasakiZ800()
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

		-- Step 3: CRITICAL USER REQUIREMENT: Wait until bike is fully spawned AND menapak dengan tanah (grounded & settled)
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
					-- Bike has touched ground and vertical falling velocity is settled
					if groundDist <= 3.8 and math.abs(velY) < 1.5 then
						break
					end
				end
				task.wait(0.1)
			end
			-- Stabilization buffer: let suspension and game vehicle controller attach
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
				-- Position character standing beside the seat, not clipping inside it
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
	-- 🎛️ UI SECTIONS: VEHICLE TAB
	------------------------------------------------
	local bikeSection = UI.AddSection(tab, "Kasaki z800 2015 Management", 1)

	local bikeStatusCard = UI.AddStatsCard(bikeSection, "Active Motorcycle", "Searching...", 2)

	UI.AddButton(bikeSection, "Spawn Kasaki z800 2015", function()
		spawnKasakiZ800()
	end, 3)

	UI.AddButton(bikeSection, "Mount / Sit Driver Seat", function()
		if ensureDriverSeated(true) then
			UI.Notify("Vehicle", "Successfully seated on motorcycle.", 2, "success")
		else
			UI.Notify("Vehicle", "Could not sit on motorcycle.", 2, "warning")
		end
	end, 4, "secondary")

	local autoMountToggle = UI.AddToggle(bikeSection, "Auto Re-Spawn & Mount", Config.autoMount, function(enabled)
		Config.autoMount = enabled
	end, 5)

	-- Physics Section
	local tuningSection = UI.AddSection(tab, "Tuning & Handling", 6)

	local speedBoostToggle = UI.AddToggle(tuningSection, "Speed & Torque Multiplier", Config.speedMultiplier > 1.0, function(enabled)
		if not enabled then
			Config.speedMultiplier = 1.0
		end
	end, 7)

	local speedBoostSlider = UI.AddSlider(tuningSection, "Speed Multiplier Boost", 1.0, 5.0, Config.speedMultiplier or 1.0, function(val)
		Config.speedMultiplier = val
	end, 0.1, "x", 8)

	local antiFallToggle = UI.AddToggle(tuningSection, "Anti-Fall / Auto-Upright Guardian", Config.antiFall, function(enabled)
		Config.antiFall = enabled
	end, 9)

	local instantBrakeToggle = UI.AddToggle(tuningSection, "Instant Brake (Space / S)", Config.instantBrake, function(enabled)
		Config.instantBrake = enabled
	end, 10)

	-- Mobility Section
	local mobilitySection = UI.AddSection(tab, "Mobility & Flight", 11)

	local flyToggle = UI.AddToggle(mobilitySection, "Motorcycle Flight", Config.vehicleFly, function(enabled)
		Config.vehicleFly = enabled
	end, 12)

	local flySpeedSlider = UI.AddSlider(mobilitySection, "Flight Speed", 50, 400, Config.flySpeed or 120, function(val)
		Config.flySpeed = val
	end, 5, " studs/s", 13)

	local noclipToggle = UI.AddToggle(mobilitySection, "Vehicle Noclip", Config.vehicleNoclip, function(enabled)
		Config.vehicleNoclip = enabled
	end, 14)

	------------------------------------------------
	-- ⚙️ RUNTIME PHYSICS & CONTROLLERS
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
		if Config.antiFall and not Config.vehicleFly then
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
		SpawnBike = spawnKasakiZ800,
		MountBike = function() ensureDriverSeated(true) end,
		EnsureDriverSeated = ensureDriverSeated
	}
end)

if not success then
	warn("[HipHub TR Legacy Vehicle Error]:", err)
end
