-- 🚗 HipHub CDID — Vehicle Controller & Customization Suite
-- Handles vehicle spawning, speed hacks, torque tuning, fly, noclip, drift, infinite fuel, and auto-flip

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Config = _G.HipHubConfig or { vehicle = {} }
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Lighting = game:GetService("Lighting")
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

	local function invokeRemote(funcName, ...)
		if Network and Network.InvokeServer then
			local s, r = pcall(function(...) return Network:InvokeServer(funcName, ...) end, ...)
			if s then return r end
		else
			local remotes = ReplicatedStorage:FindFirstChild("NetworkContainer")
			if remotes and remotes:FindFirstChild("RemoteFunctions") then
				local rem = remotes.RemoteFunctions:FindFirstChild(funcName)
				if rem then
					local s, r = pcall(function(...) return rem:InvokeServer(...) end, ...)
					if s then return r end
				end
			end
		end
		return nil
	end

	-- Get player's active car
	local function getPlayerCar()
		local vehicles = workspace:FindFirstChild("Vehicles")
		if not vehicles then return nil end
		return vehicles:FindFirstChild(player.Name .. "sCar") or vehicles:FindFirstChild(player.Name .. "'s Car")
	end

	------------------------------------------------
	-- 🚀 SPEED & ACCELERATION MULTIPLIER
	------------------------------------------------
	local speedMultiplier = Config.vehicle.speedMultiplier or 1.0
	local torqueBoost = Config.vehicle.torqueMultiplier or 1.0
	local topSpeedOverride = Config.vehicle.topSpeedOverride or 0
	local instantBrakeEnabled = Config.vehicle.instantBrake or false

	RunService.Heartbeat:Connect(function()
		local car = getPlayerCar()
		if not car then return end

		local seat = car:FindFirstChild("DriveSeat")
		if not seat or not seat:IsA("VehicleSeat") or seat.Occupant ~= (player.Character and player.Character:FindFirstChild("Humanoid")) then
			return
		end

		-- Speed / Velocity Multiplier
		if speedMultiplier > 1.0 and seat.Throttle ~= 0 then
			local primary = car.PrimaryPart or seat
			if primary and primary:IsA("BasePart") then
				local forward = seat.CFrame.LookVector * (seat.Throttle * (speedMultiplier - 1.0) * 20)
				primary.AssemblyLinearVelocity = primary.AssemblyLinearVelocity + Vector3.new(forward.X, 0, forward.Z)
			end
		end

		-- Instant Brake
		if instantBrakeEnabled and (UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.S)) then
			local primary = car.PrimaryPart or seat
			if primary and primary:IsA("BasePart") then
				primary.AssemblyLinearVelocity = Vector3.new(0, primary.AssemblyLinearVelocity.Y, 0)
				primary.AssemblyAngularVelocity = Vector3.zero
			end
		end

		-- TopSpeed value overrides
		if topSpeedOverride > 0 then
			pcall(function()
				Lighting.TopSpeed.Value = topSpeedOverride
			end)
		end
	end)

	------------------------------------------------
	-- 🛸 VEHICLE FLY
	------------------------------------------------
	local flyVehicleActive = false
	local flyVehicleSpeed = Config.vehicle.flyVehicleSpeed or 60
	local bv, bg

	local function toggleVehicleFly(enable)
		flyVehicleActive = enable
		local car = getPlayerCar()

		if not enable then
			if bv then bv:Destroy(); bv = nil end
			if bg then bg:Destroy(); bg = nil end
			return
		end

		if not car then return end
		local root = car.PrimaryPart or car:FindFirstChild("DriveSeat")
		if not root then return end

		bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.zero
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bv.Parent = root

		bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		bg.P = 9000
		bg.CFrame = root.CFrame
		bg.Parent = root

		task.spawn(function()
			local cam = workspace.CurrentCamera
			while flyVehicleActive and car and car.Parent and root and root.Parent do
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
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					moveDir = moveDir - Vector3.new(0, 1, 0)
				end

				if bv and bg then
					bv.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * flyVehicleSpeed) or Vector3.zero
					bg.CFrame = cam.CFrame
				end

				RunService.RenderStepped:Wait()
			end

			if bv then bv:Destroy(); bv = nil end
			if bg then bg:Destroy(); bg = nil end
		end)
	end

	------------------------------------------------
	-- 👻 VEHICLE NOCLIP
	------------------------------------------------
	local noclipVehicleActive = false
	RunService.Stepped:Connect(function()
		if noclipVehicleActive then
			local car = getPlayerCar()
			if car then
				for _, part in pairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
	end)

	------------------------------------------------
	-- 🔄 AUTO FLIP VEHICLE
	------------------------------------------------
	local autoFlipActive = true
	task.spawn(function()
		while true do
			if autoFlipActive then
				pcall(function()
					local car = getPlayerCar()
					if car and car.PrimaryPart then
						local up = car.PrimaryPart.CFrame.UpVector
						-- If car is upside down or severely tilted
						if up.Y < 0.2 then
							local curPos = car.PrimaryPart.Position
							local curLook = car.PrimaryPart.CFrame.LookVector
							car:SetPrimaryPartCFrame(CFrame.new(curPos + Vector3.new(0, 3, 0), curPos + Vector3.new(curLook.X, 0, curLook.Z)))
							car.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
						end
					end
				end)
			end
			task.wait(1)
		end
	end)

	------------------------------------------------
	-- ⛽ INFINITE FUEL & AUTO REFUEL
	------------------------------------------------
	local infiniteFuelActive = false
	task.spawn(function()
		while true do
			if infiniteFuelActive then
				pcall(function()
					local car = getPlayerCar()
					if car then
						local fuelVal = car:FindFirstChild("Fuel") or (car:FindFirstChild("DriveSeat") and car.DriveSeat:FindFirstChild("Fuel"))
						if fuelVal and fuelVal:IsA("NumberValue") then
							fuelVal.Value = 100
						end
						fireRemote("Fuel", 100, car.CarData.CarName.Value, 100)
					end
				end)
			end
			task.wait(5)
		end
	end)

	------------------------------------------------
	-- 🎨 BUILD VEHICLE TAB UI
	------------------------------------------------
	local vFrame = UI.tabs["Vehicle"].Frame

	-- Car Spawner Section
	local spawnSec = UI.AddSection(vFrame, "🚘 Vehicle Spawner & Manager", 1)

	local sampleCars = {
		"2023ToyotaInnovaZenixV",
		"2022HondaCivicTypeR",
		"2023HyundaiIoniq5",
		"2021ToyotaFortunerGR",
		"2022MitsubishiPajeroSport",
		"2021BMW_M4_Competition",
		"2020MercedesAMG_G63",
		"2023Porsche911GT3RS",
		"2020LamborghiniHuracanSTO",
		"2022ToyotaAlphardExecutive"
	}
	local selectedCarToSpawn = sampleCars[1]

	local carDrop = UI.AddDropdown(spawnSec, "Select Vehicle Preset", sampleCars, selectedCarToSpawn, function(v)
		selectedCarToSpawn = v
	end, 1)

	local customCarInput = UI.AddTextbox(spawnSec, "Or Enter Car Model Name", "", function(v)
		if v and v ~= "" then selectedCarToSpawn = v end
	end, 2)

	UI.AddButton(spawnSec, "🚀 Spawn Selected Vehicle", function()
		local target = customCarInput.Get() ~= "" and customCarInput.Get() or selectedCarToSpawn
		invokeRemote("Spawner", "Spawn", target)
		UI.Notify("Car Spawned", "Attempted to spawn: " .. tostring(target), 3, "success")
	end, 3)

	UI.AddButton(spawnSec, "🗑️ Despawn / Delete Current Car", function()
		invokeRemote("Spawner", "Delete")
		fireRemote("ForceRemoveVehicle")
		UI.Notify("Car Removed", "Despawned current vehicle.", 2, "warning")
	end, 4, Color3.fromRGB(180, 50, 50))

	-- Performance & Tuning
	local tuneSec = UI.AddSection(vFrame, "⚡ Engine Tuning & Speed Boosters", 2)

	UI.AddSlider(tuneSec, "Acceleration / Speed Multiplier", 1.0, 5.0, speedMultiplier, function(v)
		speedMultiplier = v
		Config.vehicle.speedMultiplier = v
	end, 1, "x")

	UI.AddSlider(tuneSec, "Top Speed Override (0 = Stock)", 0, 500, topSpeedOverride, function(v)
		topSpeedOverride = v
		Config.vehicle.topSpeedOverride = v
		pcall(function() Lighting.TopSpeed.Value = v end)
	end, 2, " km/h")

	UI.AddToggle(tuneSec, "Instant Handbrake (Stop on S/Space)", instantBrakeEnabled, function(v)
		instantBrakeEnabled = v
		Config.vehicle.instantBrake = v
	end, 3)

	UI.AddToggle(tuneSec, "Drift & Grip Mod", Config.vehicle.driftMode, function(v)
		Config.vehicle.driftMode = v
		pcall(function()
			local car = getPlayerCar()
			if car and car:FindFirstChild("DriveSeat") and car.DriveSeat:FindFirstChild("TireStats") then
				local stats = car.DriveSeat.TireStats
				if v then
					if stats:FindFirstChild("Rminfriction") then stats.Rminfriction.Value = 0.5 end
					if stats:FindFirstChild("Fminfriction") then stats.Fminfriction.Value = 1.8 end
				else
					if stats:FindFirstChild("Rminfriction") then stats.Rminfriction.Value = 1.0 end
					if stats:FindFirstChild("Fminfriction") then stats.Fminfriction.Value = 1.0 end
				end
			end
		end)
		if v then UI.Notify("Drift Mode ON", "Rear friction reduced for smooth drifting.", 2, "success") end
	end, 4)

	-- Flight & Noclip
	local flySec = UI.AddSection(vFrame, "🛸 Vehicle Flight & Noclip", 3)

	UI.AddToggle(flySec, "Enable Vehicle Fly", flyVehicleActive, function(v)
		toggleVehicleFly(v)
		Config.vehicle.flyVehicle = v
	end, 1)

	UI.AddSlider(flySec, "Flight Speed", 20, 200, flyVehicleSpeed, function(v)
		flyVehicleSpeed = v
		Config.vehicle.flyVehicleSpeed = v
	end, 2, " studs/s")

	UI.AddToggle(flySec, "Vehicle Noclip (Pass through walls)", noclipVehicleActive, function(v)
		noclipVehicleActive = v
		Config.vehicle.noclipVehicle = v
	end, 3)

	-- Maintenance & Utilities
	local utilSec = UI.AddSection(vFrame, "🔧 Vehicle Utilities & Toll Automation", 4)

	UI.AddToggle(utilSec, "Auto Right / Flip Upside-Down Car", autoFlipActive, function(v)
		autoFlipActive = v
		Config.vehicle.autoFlipCar = v
	end, 1)

	UI.AddToggle(utilSec, "Infinite Fuel (Auto Refuel)", infiniteFuelActive, function(v)
		infiniteFuelActive = v
		Config.vehicle.infiniteFuel = v
		if v then UI.Notify("Infinite Fuel Active", "Fuel automatically replenished.", 2, "success") end
	end, 2)

	UI.AddButton(utilSec, "⛽ Auto Refuel Tank to 100%", function()
		local car = getPlayerCar()
		if car then
			fireRemote("Fuel", 100, car.CarData.CarName.Value, 100)
			UI.Notify("Refueled", "Fuel tank filled to 100%!", 2, "success")
		else
			UI.Notify("No Car Found", "Spawn a car first to refuel.", 2, "warning")
		end
	end, 3)

	UI.AddButton(utilSec, "🚿 Auto Wash Car", function()
		fireRemote("Wash")
		UI.Notify("Car Wash", "Sent car wash request!", 2, "success")
	end, 4)

	UI.AddButton(utilSec, "🛢️ Auto Change Engine Oil", function()
		fireRemote("ChangeOil")
		UI.Notify("Oil Changed", "Engine oil serviced!", 2, "success")
	end, 5)

	UI.AddButton(utilSec, "💳 Auto Pay Toll / Gate", function()
		fireRemote("Toll")
		UI.Notify("Toll Paid", "Paid toll barrier fee!", 2, "success")
	end, 6)

	-- Export global vehicle API
	_G.HipHubVehicle = {
		GetCar = getPlayerCar,
		SpawnCar = function(name) invokeRemote("Spawner", "Spawn", name) end,
		DeleteCar = function() invokeRemote("Spawner", "Delete"); fireRemote("ForceRemoveVehicle") end,
		SetSpeed = function(v) speedMultiplier = v end,
		ToggleFly = toggleVehicleFly,
		FlipCar = function()
			local car = getPlayerCar()
			if car and car.PrimaryPart then
				local curPos = car.PrimaryPart.Position
				local curLook = car.PrimaryPart.CFrame.LookVector
				car:SetPrimaryPartCFrame(CFrame.new(curPos + Vector3.new(0, 4, 0), curPos + Vector3.new(curLook.X, 0, curLook.Z)))
			end
		end
	}
end)

if not success then
	warn("[HipHub CDID Vehicle Error]:", err)
end
