-- 🏎️ HipHub DDS — Vehicle Modifications, Bike Anti-Fall & Spawner
-- Drag Drive Simulator (Place ID: 131378148336503)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Vehicle"].content
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer

	local Config = _G.HipHubConfig and _G.HipHubConfig.vehicle or {
		antiFall = true,
		speedMultiplier = 1,
		torqueMultiplier = 1,
		infiniteFuel = true,
		vehicleFly = false
	}

	------------------------------------------------
	-- 🛡️ ANTI-FALL OFF BIKE / ANTI-EJECTION
	------------------------------------------------
	local antiFallConn = nil

	local function setupAntiFall(state)
		Config.antiFall = state
		if _G.HipHubConfig and _G.HipHubConfig.vehicle then
			_G.HipHubConfig.vehicle.antiFall = state
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
		if antiFallConn then
			antiFallConn:Disconnect()
			antiFallConn = nil
		end

		if state then
			antiFallConn = RunService.Heartbeat:Connect(function()
				local char = player.Character
				if not char then return end

				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
					humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

					-- If seated in a vehicle, ensure no unwanted unseat
					if humanoid.SeatPart and humanoid.Sit == false then
						humanoid.Sit = true
					end
				end
			end)
		end
	end

	setupAntiFall(Config.antiFall)

	------------------------------------------------
	-- ⚡ VEHICLE SPEED & ACCELERATION BOOST
	------------------------------------------------
	local boostConn = nil
	local speedBoost = 1
	local torqueBoost = 1

	local function setupVehicleBoost()
		if boostConn then boostConn:Disconnect() end

		boostConn = RunService.Heartbeat:Connect(function()
			if speedBoost <= 1 and torqueBoost <= 1 then return end

			local char = player.Character
			if not char then return end

			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if not (humanoid and humanoid.SeatPart) then return end

			local seat = humanoid.SeatPart
			local vehicleModel = seat:FindFirstAncestorOfClass("Model")
			local root = vehicleModel and vehicleModel.PrimaryPart or seat

			if not root then return end

			-- Apply forward boost if W / Accelerate is pressed
			if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
				local boostForce = (speedBoost - 1) * 25
				root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + (root.CFrame.LookVector * boostForce)
			end
		end)
	end
	setupVehicleBoost()

	------------------------------------------------
	-- 🚀 VEHICLE FLY MODE
	------------------------------------------------
	local vehicleFlyActive = false
	local vehicleFlyConn = nil
	local flySpeed = 80

	local function toggleVehicleFly(state)
		vehicleFlyActive = state
		Config.vehicleFly = state
		if _G.HipHubConfig and _G.HipHubConfig.vehicle then
			_G.HipHubConfig.vehicle.vehicleFly = state
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end

		if vehicleFlyConn then
			vehicleFlyConn:Disconnect()
			vehicleFlyConn = nil
		end

		if state then
			vehicleFlyConn = RunService.RenderStepped:Connect(function(dt)
				local char = player.Character
				if not char then return end

				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if not (humanoid and humanoid.SeatPart) then return end

				local seat = humanoid.SeatPart
				local vehicleModel = seat:FindFirstAncestorOfClass("Model")
				local root = vehicleModel and vehicleModel.PrimaryPart or seat

				if not root then return end

				local cam = workspace.CurrentCamera
				local moveDir = Vector3.zero

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end

				if moveDir.Magnitude > 0 then
					root.AssemblyLinearVelocity = moveDir.Unit * flySpeed
				else
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end)
			UI.Notify("Vehicle Fly Active", "WASD + Space/Ctrl to fly vehicle.", 3, "success")
		else
			UI.Notify("Vehicle Fly Disabled", "Normal vehicle physics restored.", 2, "warning")
		end
	end

	------------------------------------------------
	-- 🚗 QUICK SPAWNER & DESPAWNER
	------------------------------------------------
	local ownedVehicles = _G.HipHubOwnedVehicles or {}
	local selectedVehicle = (_G.HipHubConfig and _G.HipHubConfig.vehicle and _G.HipHubConfig.vehicle.selectedVehicle) or (_G.HipHubConfig and _G.HipHubConfig.farm and _G.HipHubConfig.farm.selectedVehicle) or ""
	local vehicleDropdown = nil

	local function fetchOwnedCars(silent)
		pcall(function()
			local initCar = ReplicatedStorage:FindFirstChild("DealershipEvents") and ReplicatedStorage.DealershipEvents:FindFirstChild("InitializeCarData")
			if initCar then
				local data = initCar:InvokeServer()
				if data and type(data) == "table" then
					local newList = {}
					for _, car in ipairs(data) do
						local name = nil
						if type(car) == "table" then
							name = car.Name or car.CarName or car.VehicleName or car.ModelName or car[1]
						elseif type(car) == "string" then
							name = car
						end
						if name and tostring(name) ~= "" then
							table.insert(newList, tostring(name))
						end
					end

					if #newList > 0 then
						ownedVehicles = newList
						_G.HipHubOwnedVehicles = newList

						local found = false
						for _, v in ipairs(ownedVehicles) do
							if v == selectedVehicle then
								found = true
								break
							end
						end
						if not found or selectedVehicle == "" then
							selectedVehicle = ownedVehicles[1]
							if _G.HipHubConfig and _G.HipHubConfig.vehicle then
								_G.HipHubConfig.vehicle.selectedVehicle = selectedVehicle
							end
							if _G.HipHubConfig and _G.HipHubConfig.farm then
								_G.HipHubConfig.farm.selectedVehicle = selectedVehicle
							end
							if _G.HipHubSaveConfig then
								_G.HipHubSaveConfig(true)
							end
						end

						if vehicleDropdown and vehicleDropdown.Refresh then
							vehicleDropdown.Refresh(ownedVehicles)
						end
						if not silent and UI and UI.Notify then
							UI.Notify("Vehicles Refreshed", string.format("Ditemukan %d kendaraan milik akun.", #ownedVehicles), 2.5, "success")
						end
					end
				end
			end
		end)
	end
	task.spawn(function()
		task.wait(0.5)
		fetchOwnedCars(true)
	end)

	local function spawnCurrentVehicle()
		if not selectedVehicle or selectedVehicle == "" or selectedVehicle == "Loading..." then
			UI.Notify("No Vehicle Selected", "Pilih kendaraan terlebih dahulu.", 2, "warning")
			return
		end

		pcall(function()
			local sc = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
			local spawnEvent = sc and sc:FindFirstChild("SpawnCar")
			if spawnEvent then
				spawnEvent:FireServer(selectedVehicle)
				UI.Notify("Vehicle Spawned", "Spawned: " .. tostring(selectedVehicle), 3, "success")
			end
		end)
	end

	local function despawnCurrentVehicle()
		pcall(function()
			local sc = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
			local despawnEvent = sc and sc:FindFirstChild("DespawnCar")
			if despawnEvent then
				despawnEvent:FireServer()
				UI.Notify("Vehicle Despawned", "Kendaraan dimasukkan ke garasi.", 2, "warning")
			end
		end)
	end

	------------------------------------------------
	-- 🖼️ UI COMPONENTS IN VEHICLE TAB
	------------------------------------------------
	UI.AddSection(tab, "Vehicle Enhancements")
	UI.AddToggle(tab, "Anti-Fall Off Motorbike", "Prevents ejection or ragdoll when bumping into walls/terrain", Config.antiFall, function(state)
		setupAntiFall(state)
	end)

	UI.AddSlider(tab, "Speed Multiplier", 1, 5, 1, function(val)
		speedBoost = val
	end)

	UI.AddToggle(tab, "Vehicle Flight Mode", "Fly in the air while driving using WASD + Space/Ctrl", Config.vehicleFly, function(state)
		toggleVehicleFly(state)
	end)

	UI.AddSlider(tab, "Vehicle Fly Speed", 40, 200, 80, function(val)
		flySpeed = val
	end)

	UI.AddSection(tab, "Quick Spawner & Garage")

	local initialItems = #ownedVehicles > 0 and ownedVehicles or { (selectedVehicle ~= "" and selectedVehicle) or "Loading..." }
	local initialSelected = (selectedVehicle ~= "" and selectedVehicle) or (ownedVehicles[1] or "Select Vehicle")

	vehicleDropdown = UI.AddDropdown(tab, "Select Vehicle", initialItems, initialSelected, function(chosen)
		if chosen and chosen ~= "Loading..." and chosen ~= "No Vehicles Found" and chosen ~= "Select Vehicle" then
			selectedVehicle = chosen
			if _G.HipHubConfig and _G.HipHubConfig.vehicle then
				_G.HipHubConfig.vehicle.selectedVehicle = chosen
			end
			if _G.HipHubConfig and _G.HipHubConfig.farm then
				_G.HipHubConfig.farm.selectedVehicle = chosen
			end
			if _G.HipHubSaveConfig then
				_G.HipHubSaveConfig(true)
			end
			UI.Notify("Vehicle Selected", "Kendaraan Aktif: " .. tostring(chosen), 2, "info")
		end
	end)

	UI.AddButton(tab, "Refresh Owned Vehicles", "Refresh", function()
		fetchOwnedCars(false)
	end)

	UI.AddButton(tab, "Spawn Selected Vehicle", "Spawn Car", function()
		spawnCurrentVehicle()
	end)

	UI.AddButton(tab, "Despawn Current Vehicle", "Despawn Car", function()
		despawnCurrentVehicle()
	end)

	UI.AddButton(tab, "Toggle Vehicle Door Lock", "Toggle Lock", function()
		pcall(function()
			local ve = ReplicatedStorage:FindFirstChild("VehicleEvents")
			local lockEvent = ve and ve:FindFirstChild("LockVehicleEvent")
			if lockEvent then
				lockEvent:FireServer()
				UI.Notify("Vehicle Lock", "Toggled vehicle locks.", 2, "success")
			end
		end)
	end)
end)

if not success then
	warn("[HipHub DDS Vehicle Error]:", err)
end
