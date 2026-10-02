-- 🚗 HipHub DE -- Vehicle Modifications & Teleport System
-- Driving Empire (Place ID: 9694510481)
-- Exports: _G.HipHubVehicle, _G.HipHubTeleport

local success, err = pcall(function()
	local Players         = game:GetService("Players")
	local RunService      = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local player          = Players.LocalPlayer

	------------------------------------------------
	-- 📦 STATE
	------------------------------------------------
	local State = {
		speedMultiplier = (_G.HipHubConfig and _G.HipHubConfig.vehicle.speedMultiplier) or 1.0,
		godMode         = false,
		infiniteNitro   = false,
		noDamage        = false,
		noclip          = false,
	}

	-- DE base vehicle max speed (approximate). Many DE cars cap at ~150-200 studs/s.
	local BASE_MAX_SPEED = 150

	------------------------------------------------
	-- 🗺️ KNOWN LOCATIONS
	-- Positions are runtime-resolved from workspace named objects.
	-- Defaults are safe fallback coords near world origin with Y offset.
	------------------------------------------------
	local LOCATIONS = {
		Bank          = CFrame.new(  0,  8,  0),
		PoliceStation = CFrame.new( 80,  8, 80),
		RaceTrack     = CFrame.new(-300, 8,-300),
		CarDealership = CFrame.new(150,  8,-120),
		Garage        = CFrame.new(-80,  8, 100),
		GasStation    = CFrame.new(200,  8, 200),
		Restaurant    = CFrame.new(-150, 8,-60),
		DeliveryHub   = CFrame.new(250,  8, 160),
	}

	-- Keyword tables used to scan workspace for real positions
	local LOC_KEYWORDS = {
		Bank          = {"Bank", "Vault", "Treasury"},
		PoliceStation = {"Police", "PoliceDept", "PD", "Station"},
		RaceTrack     = {"Race", "RaceTrack", "Finish", "StartLine"},
		CarDealership = {"Dealer", "Dealership", "Showroom", "CarShop"},
		Garage        = {"Garage", "Tuner", "Mechanic"},
		GasStation    = {"Gas", "GasStation", "Fuel", "Petrol"},
		Restaurant    = {"Restaurant", "Diner", "Food", "Burger"},
		DeliveryHub   = {"Delivery", "Package", "Cargo", "Hub"},
	}

	-- Scan workspace once to resolve real CFrame positions
	local function resolveLocations()
		for key, keywords in pairs(LOC_KEYWORDS) do
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") or obj:IsA("Model") then
					local name = obj.Name
					for _, kw in ipairs(keywords) do
						if name:lower():find(kw:lower(), 1, true) then
							local cf
							if obj:IsA("BasePart") then
								cf = obj.CFrame + Vector3.new(0, 6, 0)
							elseif obj:IsA("Model") and obj.PrimaryPart then
								cf = obj.PrimaryPart.CFrame + Vector3.new(0, 6, 0)
							end
							if cf then
								LOCATIONS[key] = cf
								break
							end
						end
					end
				end
			end
		end
	end

	task.spawn(resolveLocations)
	-- Re-resolve after 5s when more objects may be loaded
	task.delay(5, resolveLocations)

	------------------------------------------------
	-- 🔍 CHARACTER / VEHICLE HELPERS
	------------------------------------------------
	local function getCharRoot()
		local char = player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function getHumanoid()
		local char = player.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	-- Returns current VehicleSeat + parent Model (nil if not in a vehicle)
	local function getCurrentVehicle()
		local hum = getHumanoid()
		if not hum then return nil, nil end
		local seat = hum.SeatPart
		if seat and seat:IsA("VehicleSeat") then
			return seat, seat.Parent
		end
		return nil, nil
	end

	------------------------------------------------
	-- ⚡ APPLY SPEED TO CURRENT CAR
	------------------------------------------------
	local function applySpeed()
		local seat, vehicle = getCurrentVehicle()
		if seat then
			local targetSpeed = BASE_MAX_SPEED * State.speedMultiplier
			pcall(function() seat.MaxSpeed = targetSpeed end)

			-- Update vehicle tab status
			if _G.HipHubDE and _G.HipHubDE.UI and _G.HipHubDE.UI.vehicle then
				local vname = vehicle and vehicle.Name or "Unknown"
				_G.HipHubDE.UI.vehicle.statusLabel.Text =
					"Status: <font color='#00e6ff'>Active</font>" ..
					"\nVehicle: " .. vname ..
					"\nSpeed: " .. BASE_MAX_SPEED * State.speedMultiplier .. " studs/s"
			end
			return true
		else
			if _G.HipHubDE and _G.HipHubDE.UI and _G.HipHubDE.UI.vehicle then
				_G.HipHubDE.UI.vehicle.statusLabel.Text =
					"Status: <font color='#ffaa00'>Standby</font>\nNo vehicle detected"
			end
			return false
		end
	end

	------------------------------------------------
	-- 🛡️ GOD MODE (disable collision + keep health max)
	------------------------------------------------
	local godConn = nil

	local function startGodMode()
		if godConn then godConn:Disconnect() end
		godConn = RunService.Heartbeat:Connect(function()
			local seat, vehicle = getCurrentVehicle()
			-- Keep character health at max
			local hum = getHumanoid()
			if hum then
				pcall(function()
					if hum.Health < hum.MaxHealth then
						hum.Health = hum.MaxHealth
					end
				end)
			end
			-- Disable vehicle part collision
			if vehicle then
				for _, part in ipairs(vehicle:GetDescendants()) do
					if part:IsA("BasePart") then
						pcall(function() part.CanCollide = false end)
					end
				end
			end
		end)
	end

	local function stopGodMode()
		if godConn then godConn:Disconnect(); godConn = nil end
		-- Re-enable collision on current vehicle
		local _, vehicle = getCurrentVehicle()
		if vehicle then
			for _, part in ipairs(vehicle:GetDescendants()) do
				if part:IsA("BasePart") then
					pcall(function() part.CanCollide = true end)
				end
			end
		end
	end

	------------------------------------------------
	-- 🚀 INFINITE NITRO
	-- Boosts MaxSpeed while Shift/LCtrl held; also fills any Boost value
	------------------------------------------------
	local nitroConn = nil

	local function startInfiniteNitro()
		if nitroConn then nitroConn:Disconnect() end
		nitroConn = RunService.Heartbeat:Connect(function()
			local seat = getCurrentVehicle()
			if not seat then return end
			local isBoost = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or
			                UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			pcall(function()
				seat.MaxSpeed = isBoost
					and (BASE_MAX_SPEED * State.speedMultiplier * 3)
					or  (BASE_MAX_SPEED * State.speedMultiplier)
			end)
			-- Fill any Boost IntValue / NumberValue inside the vehicle model
			local _, vehicle = getCurrentVehicle()
			if vehicle then
				for _, v in ipairs(vehicle:GetDescendants()) do
					if (v:IsA("IntValue") or v:IsA("NumberValue")) and
					   v.Name:lower():find("boost", 1, true) then
						pcall(function() v.Value = math.max(v.Value, 100) end)
					end
				end
			end
		end)
	end

	local function stopInfiniteNitro()
		if nitroConn then nitroConn:Disconnect(); nitroConn = nil end
		-- Restore normal speed
		local seat = getCurrentVehicle()
		if seat then
			pcall(function() seat.MaxSpeed = BASE_MAX_SPEED * State.speedMultiplier end)
		end
	end

	------------------------------------------------
	-- 🧱 NOCLIP
	------------------------------------------------
	local noclipConn = nil

	local function startNoclip()
		if noclipConn then noclipConn:Disconnect() end
		noclipConn = RunService.Stepped:Connect(function()
			local char = player.Character
			if not char then return end
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					pcall(function() v.CanCollide = false end)
				end
			end
		end)
	end

	local function stopNoclip()
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
		local char = player.Character
		if char then
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					pcall(function() v.CanCollide = true end)
				end
			end
		end
	end

	------------------------------------------------
	-- 💥 NO DAMAGE (keep health max via heartbeat)
	------------------------------------------------
	local noDmgConn = nil

	local function startNoDamage()
		if noDmgConn then noDmgConn:Disconnect() end
		noDmgConn = RunService.Heartbeat:Connect(function()
			local hum = getHumanoid()
			if hum then
				pcall(function()
					if hum.Health < hum.MaxHealth then
						hum.Health = hum.MaxHealth
					end
				end)
			end
		end)
	end

	local function stopNoDamage()
		if noDmgConn then noDmgConn:Disconnect(); noDmgConn = nil end
	end

	------------------------------------------------
	-- 🔄 CONTINUOUS SPEED APPLICATION LOOP
	-- Applies when speedMultiplier != 1 so it persists
	-- even after entering/exiting vehicles
	------------------------------------------------
	RunService.Heartbeat:Connect(function()
		if State.speedMultiplier ~= 1.0 then
			local seat = getCurrentVehicle()
			if seat then
				pcall(function()
					seat.MaxSpeed = BASE_MAX_SPEED * State.speedMultiplier
				end)
			end
		end
	end)

	------------------------------------------------
	-- 🎯 TELEPORT FUNCTIONS
	------------------------------------------------
	local function teleportTo(key)
		local cf = LOCATIONS[key]
		if not cf then
			warn("[HipHub DE Vehicle] Unknown location: " .. tostring(key))
			return false
		end
		local root = getCharRoot()
		if root then
			root.CFrame = cf
			return true
		end
		return false
	end

	local function teleportToCoords(x, y, z)
		local root = getCharRoot()
		if root then
			root.CFrame = CFrame.new(x, y, z)
			return true
		end
		return false
	end

	------------------------------------------------
	-- 🚪 EXIT VEHICLE
	------------------------------------------------
	local function exitVehicle()
		local hum = getHumanoid()
		if hum and hum.SeatPart then
			-- Force unseat by calling VehicleSeat:Sit(nil) or setting seat
			pcall(function()
				hum.SeatPart:Sit(hum) -- toggles off in some DE builds
			end)
			pcall(function()
				hum.Jump = true
			end)
		end
	end

	------------------------------------------------
	-- 🔁 RESET CAR POSITION
	------------------------------------------------
	local function resetCar()
		local _, vehicle = getCurrentVehicle()
		if vehicle and vehicle.PrimaryPart then
			local cf = vehicle.PrimaryPart.CFrame
			vehicle:SetPrimaryPartCFrame(CFrame.new(cf.Position + Vector3.new(0, 8, 0)))
		end
	end

	------------------------------------------------
	-- 🔧 STATE SETTER
	------------------------------------------------
	local function setState(newState)
		for k, v in pairs(newState) do
			State[k] = v
			if k == "noclip"       then if v then startNoclip()       else stopNoclip()       end
			elseif k == "godMode"  then if v then startGodMode()       else stopGodMode()      end
			elseif k == "infiniteNitro" then if v then startInfiniteNitro() else stopInfiniteNitro() end
			elseif k == "noDamage" then if v then startNoDamage()     else stopNoDamage()     end
			elseif k == "speedMultiplier" then applySpeed()
			end
		end
	end

	------------------------------------------------
	-- 📤 EXPORTS
	------------------------------------------------
	_G.HipHubVehicle = {
		setState        = setState,
		getState        = function() return State end,
		applySpeed      = applySpeed,
		exitVehicle     = exitVehicle,
		resetCar        = resetCar,
		getCurrentVehicle = getCurrentVehicle,
	}

	_G.HipHubTeleport = {
		teleportTo      = teleportTo,
		teleportToCoords = teleportToCoords,
		locations       = LOCATIONS,
		refreshLocations = resolveLocations,
	}

	-- Apply persisted config on load
	if _G.HipHubConfig and _G.HipHubConfig.vehicle then
		local cfg = _G.HipHubConfig.vehicle
		State.speedMultiplier = cfg.speedMultiplier or 1.0
		if cfg.godMode      then startGodMode() end
		if cfg.infiniteNitro then startInfiniteNitro() end
		if cfg.noDamage     then startNoDamage() end
		if cfg.noclip       then startNoclip() end
	end

	print("[HipHub DE Vehicle] Vehicle mods + teleport initialized!")
end)

if not success then
	warn("[HipHub DE Vehicle Error]:", err)
end
