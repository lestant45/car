-- 📍 HipHub BXI — Teleport & Safe Waypoint Navigation System
-- Bus X Indonesia (Place ID: 137806249434874)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Teleport"].content
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	------------------------------------------------
	-- 🛡️ ANTI-VOID & STREAMING SAFETY PLATFORM
	------------------------------------------------
	local function ensureSafetyPlate(pos, width)
		width = width or 40
		local plate = workspace:FindFirstChild("__SafetyPlate")
		if not plate then
			plate = Instance.new("Part")
			plate.Name = "__SafetyPlate"
			plate.Anchored = true
			plate.CanCollide = true
			plate.Transparency = 1
			plate.CastShadow = false
			plate.Material = Enum.Material.SmoothPlastic
			pcall(function() plate.Parent = workspace end)
		end
		plate.Size = Vector3.new(width, 2, width)
		plate.CFrame = CFrame.new(pos.X, pos.Y - 1.5, pos.Z)
		return plate
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

	-- Safe Character Teleport
	local function safeTeleport(targetCF, useTween, speed)
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local targetPos = typeof(targetCF) == "CFrame" and targetCF.Position or targetCF
		local targetCFrame = typeof(targetCF) == "CFrame" and targetCF or CFrame.new(targetPos)

		ensureSafetyPlate(targetPos, 45)
		requestStreamAsync(targetPos)

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		if useTween then
			local dist = (root.Position - targetPos).Magnitude
			local duration = math.clamp(dist / (speed or 120), 0.2, 8)
			local tw = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
				CFrame = targetCFrame + Vector3.new(0, 3, 0)
			})
			tw:Play()
			tw.Completed:Wait()
		else
			root.CFrame = targetCFrame + Vector3.new(0, 3.5, 0)
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	_G.HipHubSafeTeleport = safeTeleport

	------------------------------------------------
	-- 🗺️ WAYPOINTS & DESTINATIONS
	------------------------------------------------
	local TERMINALS = {
		{ name = "Terminal Baranangsiang (Bogor)", pos = Vector3.new(22771.8, 294.8, -39584.0), spawn = "SpawnPoint_Bogor" },
		{ name = "Terminal Kp. Rambutan (Jakarta)", pos = Vector3.new(27536.3, 130.2, -3746.7), spawn = "SpawnPoint_Rambutan" },
		{ name = "Terminal Harjamukti (Cirebon)", pos = Vector3.new(-24211.4, -205.2, 34271.9), spawn = "SpawnPoint_Cirebon" },
		{ name = "Terminal Bekasi Timur", pos = Vector3.new(21819.8, 288.6, -40078.6), spawn = "SpawnPoint_Bekasi" },
		{ name = "Terminal Depok (Jatijajar)", pos = Vector3.new(22022.4, 291.1, -39931.0), spawn = "SpawnPoint_Depok" },
		{ name = "Terminal Cikampek", pos = Vector3.new(-2888.9, -135.3, 28219.4), spawn = "SpawnPoint_Cikampek" }
	}

	local POINTS_OF_INTEREST = {
		{ name = "Bengkel Modifikasi (Modif Shop)", pos = Vector3.new(12035.5, -21.3, 12740.0) },
		{ name = "Spin Box Location", pos = Vector3.new(21960.1, 291.9, -39987.4) },
		{ name = "Quest Master Location", pos = Vector3.new(25988.7, 220.9, -18498.3) },
		{ name = "Arena Lomba 17 Agustus", pos = Vector3.new(-10778.9, -147.1, 36313.3) },
		{ name = "Sawah & Pedesaan", pos = Vector3.new(5000, 50, 5000) }
	}

	------------------------------------------------
	-- 📍 TELEPORT UI BUILDER
	------------------------------------------------

	-- 1. Vehicle & Personal Teleports
	UI.AddSection(tab, "Vehicle Teleports")

	UI.AddButton(tab, "🚗 Teleport to My Bus", function()
		local myBus = nil
		if workspace:FindFirstChild("SpawnedVehicles") then
			for _, v in ipairs(workspace.SpawnedVehicles:GetChildren()) do
				local seat = v:FindFirstChildWhichIsA("VehicleSeat", true)
				if seat then
					myBus = v
					break
				end
			end
		end

		if myBus then
			local prim = myBus.PrimaryPart or myBus:FindFirstChildWhichIsA("BasePart")
			if prim then
				safeTeleport(prim.CFrame + Vector3.new(0, 5, 0))
				UI.Notify("Teleported", "Teleported to your bus!", 2, "success")
				return
			end
		end
		UI.Notify("No Bus Found", "Spawn your bus first from the Vehicle tab.", 2, "warning")
	end, "cyan")

	UI.AddButton(tab, "💺 Teleport Inside Driver Seat", function()
		local myBus = nil
		if workspace:FindFirstChild("SpawnedVehicles") then
			for _, v in ipairs(workspace.SpawnedVehicles:GetChildren()) do
				local seat = v:FindFirstChildWhichIsA("VehicleSeat", true)
				if seat then
					myBus = v
					break
				end
			end
		end

		if myBus then
			local seat = myBus:FindFirstChild("DriveSeat", true) or myBus:FindFirstChildWhichIsA("VehicleSeat", true)
			if seat then
				safeTeleport(seat.CFrame + Vector3.new(0, 2, 0))
				task.wait(0.2)
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and not hum.SeatPart then
					seat:Sit(hum)
				end
				UI.Notify("Seated", "Mounted driver seat!", 2, "success")
				return
			end
		end
		UI.Notify("No Driver Seat", "Could not locate driver seat.", 2, "warning")
	end, "success")

	-- 2. Bus Terminals
	UI.AddSection(tab, "Bus Terminals & Spawns")

	for _, term in ipairs(TERMINALS) do
		UI.AddButton(tab, "🚌 " .. term.name, function()
			-- Check if game has official spawn destination part
			local destPart = nil
			if workspace:FindFirstChild("TeleportDestinations") and term.spawn then
				destPart = workspace.TeleportDestinations:FindFirstChild(term.spawn)
			end

			local targetPos = destPart and destPart.Position or term.pos
			safeTeleport(CFrame.new(targetPos) * CFrame.Angles(0, 0, 0))
			UI.Notify("Teleported", "Arrived at " .. term.name, 2, "success")
		end, "cyan")
	end

	-- 3. Points of Interest
	UI.AddSection(tab, "Key Locations & Shops")

	for _, poi in ipairs(POINTS_OF_INTEREST) do
		UI.AddButton(tab, "📍 " .. poi.name, function()
			safeTeleport(CFrame.new(poi.pos))
			UI.Notify("Teleported", "Arrived at " .. poi.name, 2, "success")
		end, "gold")
	end

	-- 4. Checkpoints Browser & Teleport
	UI.AddSection(tab, "Checkpoints Waypoints")

	local checkpointList = {}
	pcall(function()
		if workspace:FindFirstChild("Checkpoints") then
			for _, cp in ipairs(workspace.Checkpoints:GetDescendants()) do
				if cp:IsA("BasePart") then
					table.insert(checkpointList, cp.Name)
				end
			end
		end
	end)

	if #checkpointList == 0 then
		checkpointList = { "Patrol_D", "Cikampek_B", "Cikampek_D", "RambutanDrop_D", "RosinPick_C" }
	end

	local selectedCheckpoint = checkpointList[1]
	UI.AddDropdown(tab, "Select Checkpoint", checkpointList, selectedCheckpoint, function(chosen)
		selectedCheckpoint = chosen
	end)

	UI.AddButton(tab, "🚩 Teleport to Selected Checkpoint", function()
		if not selectedCheckpoint then return end
		local cpPart = workspace.Checkpoints:FindFirstChild(selectedCheckpoint, true)
		if cpPart and cpPart:IsA("BasePart") then
			safeTeleport(cpPart.CFrame + Vector3.new(0, 4, 0))
			UI.Notify("Checkpoint", "Teleported to " .. selectedCheckpoint, 2, "success")
		else
			UI.Notify("Not Found", "Could not find checkpoint part in workspace.", 2, "danger")
		end
	end, "warning")
end)

if not success then
	warn("[HipHub BXI Teleport Error]:", err)
end
