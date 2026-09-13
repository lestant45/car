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

		-- Check for Kasaki z800 2015 first, or any active bike model
		local bike = playerVehicles:FindFirstChild("Kasaki z800 2015")
		if not bike then
			for _, child in ipairs(playerVehicles:GetChildren()) do
				if child:IsA("Model") then
					bike = child
					break
				end
			end
		end

		if not bike then return nil end

		local seat = bike:FindFirstChild("DriveSeat") or bike:FindFirstChildWhichIsA("VehicleSeat", true)
		local primary = bike.PrimaryPart or seat or bike:FindFirstChildWhichIsA("BasePart")

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

	-- Ensure player is seated on bike's DriveSeat
	local function ensureDriverSeated(autoSpawn)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false end

		local bike, seat = getPlayerBike()
		if not bike and autoSpawn then
			spawnKasakiZ800()
			local start = os.clock()
			while (os.clock() - start) < 3.5 do
				task.wait(0.2)
				bike, seat = getPlayerBike()
				if bike and seat then break end
			end
		end

		if not seat then return false end

		if hum.SeatPart == seat then
			return true
		end

		-- Direct sit attempt
		hum.Sit = false
		task.wait(0.05)
		pcall(function()
			seat:Sit(hum)
		end)

		-- Prompt fallback
		if hum.SeatPart ~= seat then
			local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt") or bike:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt and fireproximityprompt then
				pcall(function() fireproximityprompt(prompt, 0) end)
			end
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
					bikeStatusCard.Set(bike.Name .. (isSeated and " (Seated)" or " (Unmounted)"))
				else
					bikeStatusCard.Set("None (Despawned)")
					if Config.autoMount and not _G.HipHub_IsAutoRacing then
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
