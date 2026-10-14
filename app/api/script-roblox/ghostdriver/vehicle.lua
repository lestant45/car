-- HipHub Ghost Driver — Vehicle Modifications & Controls (Safe)
-- Handles Car Spawning, Smooth Speed Booster, Auto-Flip, and Seat Helpers

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local player = Players.LocalPlayer

	local Config = _G.HipHubConfig or { vehicle = {} }
	local UI = _G.HipHubUI

	local SpawnCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("SpawnCarEvent", 15)

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

	------------------------------------------------
	-- SPAWN CAR
	------------------------------------------------
	local function spawnCar(carName)
		if not SpawnCarRemote then return end
		SpawnCarRemote:FireServer(carName)
		if UI and UI.Notify then
			UI.Notify("Vehicle Spawner", "Requested spawn for " .. tostring(carName), 3, "info")
		end

		task.delay(1.5, function()
			local car, seat = getMyCar()
			if car and seat and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					seat:Sit(hum)
				end
			end
		end)
	end

	------------------------------------------------
	-- AUTO FLIP / UNFLIP
	------------------------------------------------
	local function unflipCar()
		local car, seat = getMyCar()
		if car and seat then
			local currentPivot = car:GetPivot()
			local upVector = currentPivot.UpVector
			local pos = currentPivot.Position
			if upVector.Y < 0.3 then
				car:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(currentPivot.Rotation.Y), 0))
				if seat:IsA("BasePart") then
					seat.AssemblyAngularVelocity = Vector3.zero
					seat.AssemblyLinearVelocity = Vector3.zero
				end
				if UI and UI.Notify then
					UI.Notify("Vehicle", "Car successfully unflipped!", 2, "success")
				end
			end
		end
	end

	task.spawn(function()
		while true do
			task.wait(1.5)
			if Config.vehicle.autoFlip then
				pcall(unflipCar)
			end
		end
	end)

	------------------------------------------------
	-- SAFE SPEED BOOSTER LOOP
	------------------------------------------------
	RunService.Heartbeat:Connect(function()
		if Config.vehicle.speedBoost then
			local car, seat = getMyCar()
			if seat and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Sit then
				local mult = math.clamp(Config.vehicle.speedMultiplier or 1.5, 1.0, 3.5)
				local currentVel = seat.AssemblyLinearVelocity
				local currentSpeedMPH = currentVel.Magnitude * 0.56818
				if currentSpeedMPH < 380 and seat.Throttle and seat.Throttle > 0 then
					seat.AssemblyLinearVelocity = currentVel + (seat.CFrame.LookVector * (mult * 6.0))
				end
			end
		end
	end)

	_G.HipHub_GhostDriver_Vehicle = {
		SpawnCar = spawnCar,
		Unflip = unflipCar,
		GetMyCar = getMyCar
	}
end)

if not success then
	warn("[HipHub Ghost Driver Vehicle Error]:", err)
end
