-- HipHub Ghost Driver — Fast Teleport System
-- Handles Map Teleports, Car Teleports, and Destination Shortcuts

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	local UI = _G.HipHubUI
	local HudTeleport = ReplicatedStorage:WaitForChild("HudTeleport", 15)

	local function teleportTo(destName)
		if not HudTeleport then return end
		HudTeleport:FireServer(destName)
		if UI and UI.Notify then
			UI.Notify("Teleport", "Teleporting to " .. destName .. "...", 2, "info")
		end
	end

	local function teleportToCar()
		local car = nil
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and (child:GetAttribute("OwnerUserId") == player.UserId or child.Name:find(player.Name)) then
				local seat = child:FindFirstChild("DriveSeat")
				if seat then
					car = child
					break
				end
			end
		end

		if car and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local seat = car:FindFirstChild("DriveSeat")
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if seat and hum then
				seat:Sit(hum)
			else
				player.Character.HumanoidRootPart.CFrame = car:GetPivot() + Vector3.new(0, 4, 0)
			end
			if UI and UI.Notify then
				UI.Notify("Teleport", "Teleported to your vehicle!", 2, "success")
			end
		else
			if UI and UI.Notify then
				UI.Notify("Teleport", "Vehicle not found in workspace. Spawn one first!", 3, "warn")
			end
		end
	end

	_G.HipHub_GhostDriver_Teleport = {
		TeleportTo = teleportTo,
		TeleportToCar = teleportToCar
	}
end)

if not success then
	warn("[HipHub Ghost Driver Teleport Error]:", err)
end
