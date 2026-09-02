-- 🚌 HipHub BXI — Vehicle Management, Spawner & Physics Enhancers
-- Bus X Indonesia (Place ID: 137806249434874)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Vehicle"].content
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

	local Config = _G.HipHubConfig and _G.HipHubConfig.vehicle or {
		speedMultiplier = 1.0,
		instantBrake = true,
		antiFlip = true,
		vehicleFly = false,
		flySpeed = 80
	}

	------------------------------------------------
	-- 🔍 HELPER: FIND LOCAL PLAYER BUS
	------------------------------------------------
	local function getMyBus()
		local spawned = workspace:FindFirstChild("SpawnedVehicles")
		if not spawned then return nil end

		-- Check if player is currently seated
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local currentSeat = hum and hum.SeatPart
		if currentSeat then
			for _, v in ipairs(spawned:GetChildren()) do
				if currentSeat:IsDescendantOf(v) then
					return v
				end
			end
		end

		-- Check by ownership or recent spawned
		for _, v in ipairs(spawned:GetChildren()) do
			local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName")
			if owner == player.Name or owner == player.UserId then
				return v
			end
		end

		-- Return first bus with a DriveSeat if only 1 exists
		local buses = spawned:GetChildren()
		if #buses == 1 then
			return buses[1]
		end

		return buses[1]
	end
	_G.HipHubGetMyBus = getMyBus

	local function getDriverSeat(bus)
		bus = bus or getMyBus()
		if not bus then return nil end
		return bus:FindFirstChild("DriveSeat", true) or bus:FindFirstChildWhichIsA("VehicleSeat", true)
	end
	_G.HipHubGetDriverSeat = getDriverSeat

	------------------------------------------------
	-- 🏎️ SPEED BOOST & FLIGHT PHYSICS
	------------------------------------------------
	local speedBoostActive = false
	local boostMultiplier = 1.0
	local instantBrakeActive = true
	local antiFlipActive = true
	local vehicleFlyActive = false
	local vehicleFlySpeed = 80

	local vehicleFlyConn = nil
	local antiFlipConn = nil

	-- 1. Anti-Flip Stabilizer
	local function setAntiFlip(state)
		antiFlipActive = state
		Config.antiFlip = state

		if antiFlipConn then
			antiFlipConn:Disconnect()
			antiFlipConn = nil
		end

		if state then
			antiFlipConn = RunService.Heartbeat:Connect(function()
				local bus = getMyBus()
				local seat = getDriverSeat(bus)
				if not seat then return end

				local cf = seat.CFrame
				local lookVec = cf.LookVector
				local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
				if flatLook.Magnitude > 0.01 then
					flatLook = flatLook.Unit
					-- If bus is tilted sideways too much, upright it smoothly
					local upVec = cf.UpVector
					if upVec.Y < 0.65 then
						seat.AssemblyAngularVelocity = Vector3.zero
						seat.CFrame = CFrame.lookAt(seat.Position + Vector3.new(0, 3, 0), seat.Position + flatLook + Vector3.new(0, 3, 0))
					end
				end
			end)
		end
	end

	-- 2. Vehicle Flight Mode
	local function setVehicleFly(state)
		vehicleFlyActive = state
		Config.vehicleFly = state

		if vehicleFlyConn then
			vehicleFlyConn:Disconnect()
			vehicleFlyConn = nil
		end

		if state then
			vehicleFlyConn = RunService.RenderStepped:Connect(function()
				local bus = getMyBus()
				local seat = getDriverSeat(bus)
				if not (bus and seat) then return end

				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not (hum and hum.SeatPart == seat) then return end

				local cam = workspace.CurrentCamera
				local moveDir = Vector3.zero

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + cam.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - cam.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - cam.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + cam.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDir = moveDir + Vector3.new(0, 1, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					moveDir = moveDir - Vector3.new(0, 1, 0)
				end

				for _, part in ipairs(bus:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end

				if moveDir.Magnitude > 0 then
					local targetVel = moveDir.Unit * vehicleFlySpeed
					seat.AssemblyLinearVelocity = targetVel
					local prim = bus.PrimaryPart or seat
					if prim then prim.AssemblyLinearVelocity = targetVel end
					if char and char:FindFirstChild("HumanoidRootPart") then
						char.HumanoidRootPart.AssemblyLinearVelocity = targetVel
					end
				else
					seat.AssemblyLinearVelocity = Vector3.zero
					local prim = bus.PrimaryPart or seat
					if prim then prim.AssemblyLinearVelocity = Vector3.zero end
				end
			end)
			UI.Notify("Vehicle Fly Active", "Fly your bus with WASD + Space/Ctrl.", 2, "success")
		else
			local bus = getMyBus()
			if bus then
				for _, part in ipairs(bus:GetDescendants()) do
					if part:IsA("BasePart") then
						local name = part.Name:lower()
						if name:find("wheel") or name == "fl" or name == "fr" or name == "rl" or name == "rr" then
							part.CanCollide = true
						end
					end
				end
			end
			UI.Notify("Vehicle Fly Disabled", "Standard physics restored.", 2, "warning")
		end
	end

	-- 3. Speed Booster Loop
	RunService.Heartbeat:Connect(function()
		if not speedBoostActive or vehicleFlyActive then return end
		local bus = getMyBus()
		local seat = getDriverSeat(bus)
		if not seat then return end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.SeatPart == seat) then return end

		if seat.Throttle > 0 and boostMultiplier > 1.0 then
			local forwardVec = seat.CFrame.LookVector
			local addVel = forwardVec * (boostMultiplier * 8)
			seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity + Vector3.new(addVel.X, 0, addVel.Z)
		end
	end)

	------------------------------------------------
	-- 🚌 VEHICLE UI BUILDER
	------------------------------------------------

	-- 1. Bus Spawner & Management
	UI.AddSection(tab, "Bus Spawner & Garage")

	local ownedBuses = { "Jetbus_3_RM _SHD" }
	pcall(function()
		local PlayerData = player:FindFirstChild("PlayerData")
		if PlayerData and PlayerData:FindFirstChild("OwnedCars") then
			ownedBuses = {}
			for _, carVal in ipairs(PlayerData.OwnedCars:GetChildren()) do
				table.insert(ownedBuses, carVal.Name)
			end
		end
	end)

	local selectedBusToSpawn = ownedBuses[1] or "Jetbus_3_RM _SHD"

	local busDropdown = UI.AddDropdown(tab, "Select Bus Model", ownedBuses, selectedBusToSpawn, function(chosen)
		selectedBusToSpawn = chosen
	end)

	UI.AddButton(tab, "🚀 Spawn Selected Bus", function()
		if not selectedBusToSpawn then return end
		if Remotes and Remotes:FindFirstChild("SpawnCar") then
			Remotes.SpawnCar:FireServer(selectedBusToSpawn)
			UI.Notify("Spawning Bus", "Spawned " .. selectedBusToSpawn, 3, "success")
		else
			UI.Notify("Error", "Spawn remote not found.", 2, "danger")
		end
	end, "success")

	UI.AddButton(tab, "❌ Despawn Current Bus", function()
		if Remotes and Remotes:FindFirstChild("DespawnCar") then
			Remotes.DespawnCar:FireServer()
			UI.Notify("Despawned", "Bus despawned.", 2, "warning")
		end
	end, "danger")

	UI.AddButton(tab, "💺 Instant Mount Driver Seat", function()
		local bus = getMyBus()
		local seat = getDriverSeat(bus)
		if seat then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and hum then
				hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.1)
				seat:Sit(hum)
				UI.Notify("Seated", "Driver seat mounted!", 2, "success")
				return
			end
		end
		UI.Notify("No Seat Found", "Spawn your bus first.", 2, "warning")
	end, "cyan")

	-- 2. Performance & Speed Multipliers
	UI.AddSection(tab, "Physics & Performance Enhancers")

	UI.AddToggle(tab, "Enable Forward Speed Boost", speedBoostActive, function(state)
		speedBoostActive = state
	end)

	UI.AddSlider(tab, "Speed Multiplier Boost", 1.0, 5.0, boostMultiplier, function(val)
		boostMultiplier = val
	end, "x")

	UI.AddButton(tab, "🛑 Instant Emergency Brake", function()
		local bus = getMyBus()
		local seat = getDriverSeat(bus)
		if seat then
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
			local prim = bus.PrimaryPart or seat
			if prim then
				prim.AssemblyLinearVelocity = Vector3.zero
				prim.AssemblyAngularVelocity = Vector3.zero
			end
			UI.Notify("Braked", "Bus stopped immediately!", 2, "success")
		end
	end, "danger")

	UI.AddButton(tab, "🔄 Auto Flip Bus Upright", function()
		local bus = getMyBus()
		local seat = getDriverSeat(bus)
		if seat then
			local cf = seat.CFrame
			local look = cf.LookVector
			seat.AssemblyAngularVelocity = Vector3.zero
			seat.CFrame = CFrame.lookAt(seat.Position + Vector3.new(0, 4, 0), seat.Position + Vector3.new(look.X, 0, look.Z) + Vector3.new(0, 4, 0))
			UI.Notify("Flipped", "Bus placed upright.", 2, "success")
		end
	end, "gold")

	UI.AddToggle(tab, "Anti-Roll / Gyro Stabilizer", Config.antiFlip, function(state)
		setAntiFlip(state)
	end)

	-- 3. Vehicle Flight
	UI.AddSection(tab, "Vehicle Flight Mode")

	UI.AddToggle(tab, "Enable Bus Flight Mode", Config.vehicleFly, function(state)
		setVehicleFly(state)
	end)

	UI.AddSlider(tab, "Flight Cruise Speed", 40, 250, vehicleFlySpeed, function(val)
		vehicleFlySpeed = val
	end, "km/h")
end)

if not success then
	warn("[HipHub BXI Vehicle Error]:", err)
end
