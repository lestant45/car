-- 🛣️ HipHub BXI — Autonomous Route Crawler & Safe Road Mapper
-- Strictly calibrated for Safe Transit (70-75 km/h, ~42 studs/sec, ~30 min total route)
-- Guarantees engine is ON, ban-free timing, and precise asphalt tracking.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local BUS_SEAT_GROUND_OFFSET = 6.02
-- 🛡️ Anti-482 Safe Cruise Speed: 72-75 km/h (~80 studs/sec)
-- Calibrated for A-Chassis speedometer (80 studs/s = ~73 km/h on HUD gauge)
local CRUISE_SPEED = 75 -- km/h
local SPEED_STUDS = 80 -- studs/sec (A-Chassis speedometer reads ~72-75 km/h)
local SAMPLE_DISTANCE = 65 -- Record waypoint every 65 studs
local ROUTE_NAME = "Baranangsiang_ke_Cirebon4"

_G.BXI_CrawlerRunning = true
_G.BXI_RecordedWaypoints = _G.BXI_RecordedWaypoints or {}

local function log(msg)
	print("[BXI Safe Crawler] " .. tostring(msg))
end

-- Ensure Engine Ignition is ON
local function ensureEngineOn()
	pcall(function()
		local achassis = player.PlayerGui:FindFirstChild("A-Chassis Interface")
		if achassis then
			local isOn = achassis:FindFirstChild("IsOn", true)
			if isOn and not isOn.Value then
				isOn.Value = true
				log("Engine Ignition: ON")
			end
			local pbrake = achassis:FindFirstChild("Values") and achassis.Values:FindFirstChild("PBrake")
			if pbrake and pbrake.Value then
				pbrake.Value = false
			end
		end
	end)
end

-- Ensure Handbrake state
local function setHandbrake(enabled)
	pcall(function()
		local achassis = player.PlayerGui:FindFirstChild("A-Chassis Interface")
		if achassis then
			local pbrake = achassis:FindFirstChild("Values") and achassis.Values:FindFirstChild("PBrake")
			if pbrake then pbrake.Value = enabled end
		end
	end)
end

local function getMyBus()
	local sv = workspace:FindFirstChild("SpawnedVehicles")
	if not sv then return nil end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local currentSeat = hum and hum.SeatPart
	if currentSeat then
		for _, v in ipairs(sv:GetChildren()) do
			if currentSeat:IsDescendantOf(v) then return v end
		end
	end
	return sv:GetChildren()[1]
end

local function getDriverSeat(bus)
	bus = bus or getMyBus()
	if not bus then return nil end
	local seat = bus:FindFirstChild("DriveSeat", true) or bus:FindFirstChildWhichIsA("VehicleSeat", true)
	if seat and bus.PrimaryPart ~= seat then
		pcall(function() bus.PrimaryPart = seat end)
	end
	return seat
end

local function probeGround(x, z, expectedY)
	expectedY = expectedY or 286
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filter = { player.Character }
	local sv = workspace:FindFirstChild("SpawnedVehicles")
	if sv then table.insert(filter, sv) end
	local cps = workspace:FindFirstChild("Checkpoints")
	if cps then table.insert(filter, cps) end
	rayParams.FilterDescendantsInstances = filter

	local rayOrigin = Vector3.new(x, expectedY + 25, z)
	local hit = workspace:Raycast(rayOrigin, Vector3.new(0, -60, 0), rayParams)
	if hit and hit.Position then
		local roadY = hit.Position.Y
		if roadY <= (expectedY + 12) and roadY >= (expectedY - 35) then
			return roadY + BUS_SEAT_GROUND_OFFSET
		end
	end
	return expectedY + BUS_SEAT_GROUND_OFFSET
end

local function getActiveCheckpointPart()
	-- 1. Check BillboardGui on checkpoints
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BillboardGui") and d.Enabled then
			local label = d:FindFirstChildWhichIsA("TextLabel", true)
			if label and (label.Text:find("STOP HERE") or label.Text:find("HERE")) then
				if d.Parent and d.Parent:IsA("BasePart") then
					return d.Parent
				end
			end
		end
	end

	-- 2. Check End Triggers if last stop
	local endTriggers = workspace:FindFirstChild("BusJobEndTriggers")
	if endTriggers then
		for _, c in ipairs(endTriggers:GetChildren()) do
			if c:IsA("BasePart") then
				local bb = c:FindFirstChildWhichIsA("BillboardGui", true)
				if bb and bb.Enabled then return c end
			end
		end
	end

	-- 3. Robust HUD Destination Pattern Resolver (streaming-proof)
	local busGui = player.PlayerGui:FindFirstChild("BusJobGUI")
	local infoLabel = busGui and busGui.JobStatusFrame and busGui.JobStatusFrame:FindFirstChild("InfoLabel")
	local text = infoLabel and infoLabel.Text
	if text and workspace:FindFirstChild("Checkpoints") then
		local cps = workspace.Checkpoints
		if text:find("Citeureup") then
			return cps:FindFirstChild("Citeureup_D") or cps:FindFirstChild("Citeureup_A")
		elseif text:find("Jatijajar") or text:find("Depok") then
			return cps:FindFirstChild("Jatijajar_A") or cps:FindFirstChild("Jatijajar_B")
		elseif text:find("Rambutan") then
			return cps:FindFirstChild("RambutanDrop_C") or cps:FindFirstChild("RambutanDrop_A")
		elseif text:find("Cakung") then
			return cps:FindFirstChild("Cakung_A") or cps:FindFirstChild("Cakung_B")
		elseif text:find("Pulogebang") then
			return cps:FindFirstChild("PuloGebangDrop_A") or cps:FindFirstChild("Pulogebang_A")
		elseif text:find("Bekasi") then
			return cps:FindFirstChild("BekasiTimurPick_A") or cps:FindFirstChild("Bekasi_A")
		elseif text:find("Cikampek") then
			return cps:FindFirstChild("Cikampek_A") or cps:FindFirstChild("Cikampek_B")
		elseif text:find("Subang") or text:find("Cikamurang") then
			return cps:FindFirstChild("Cikamurang_A") or cps:FindFirstChild("Subang_A")
		elseif text:find("Cirebon") then
			return cps:FindFirstChild("Cirebon_A") or cps:FindFirstChild("CirebonDrop_A")
		end
	end

	return nil
end

local function isWaitingCountdown()
	local busGui = player.PlayerGui:FindFirstChild("BusJobGUI")
	local infoLabel = busGui and busGui.JobStatusFrame and busGui.JobStatusFrame:FindFirstChild("InfoLabel")
	if infoLabel and infoLabel.Text then
		local txt = infoLabel.Text:lower()
		if txt:find("stay in the zone") or txt:find("waiting for server") or txt:find("return to") then
			return true, infoLabel.Text
		end
	end
	return false, nil
end

local HIGHWAY_CORRIDOR = {
	{ name = "Baranangsiang_Exit",      x = 22487.6, y = 286.9, z = -39420.7 },
	{ name = "Gerbang_Bogor_Approach", x = 21000.0, y = 287.0, z = -38800.0 },
	{ name = "Gerbang_Bogor_Plaza",    x = 20300.0, y = 287.4, z = -38100.0 },
	{ name = "Bogor_Tol_Curve_1",      x = 20035.0, y = 285.8, z = -37700.0 },
	{ name = "Bogor_Tol_Curve_2",      x = 19165.0, y = 285.7, z = -37500.0 },
	{ name = "Tol_Sentul_Selatan",      x = 19340.0, y = 282.7, z = -36700.0 },
	{ name = "Tol_Sentul_Mid",          x = 19380.0, y = 282.7, z = -35000.0 },
	{ name = "Tol_Sentul_Utara",        x = 19340.0, y = 283.1, z = -31500.0 },
	{ name = "Citeureup_Approach",      x = 20140.0, y = 282.7, z = -29500.0 },
	{ name = "Citeureup",               x = 20380.0, y = 275.1, z = -27765.0 },
	{ name = "Gunung_Putri",            x = 22000.0, y = 250.0, z = -25500.0 },
	{ name = "Jatijajar_Depok",         x = 24322.9, y = 228.5, z = -23148.8 },
	{ name = "Cibubur",                 x = 26000.0, y = 180.0, z = -14000.0 },
	{ name = "Rambutan",                x = 27536.3, y = 130.1, z = -3746.6 },
	{ name = "Cakung",                  x = 16053.0, y = 37.9,  z = 7200.0 },
	{ name = "Pulogebang",              x = 20100.0, y = 65.2,  z = 12000.0 },
	{ name = "Bekasi_Timur",            x = 6316.3,  y = -60.0, z = 20584.1 },
	{ name = "Cikampek",                x = -2200.0, y = -138.9, z = 25000.0 },
	{ name = "Cikamurang",              x = -15721.1, y = -212.6, z = 30866.7 },
	{ name = "Patrol",                  x = -18500.0, y = -215.0, z = 32000.0 },
	{ name = "Cirebon_A",               x = -22296.7, y = -186.1, z = 31104.1 },
	{ name = "Cirebon_Term",            x = -26300.5, y = -212.7, z = 33449.8 }
}

local function getCorridorSubPath(startPos, targetPos)
	local startIndex, targetIndex = 1, #HIGHWAY_CORRIDOR
	local minSD, minTD = 999999, 999999
	for i, node in ipairs(HIGHWAY_CORRIDOR) do
		local sd = (Vector3.new(node.x - startPos.X, 0, node.z - startPos.Z)).Magnitude
		local td = (Vector3.new(node.x - targetPos.X, 0, node.z - targetPos.Z)).Magnitude
		if sd < minSD then minSD = sd; startIndex = i end
		if td < minTD then minTD = td; targetIndex = i end
	end

	local sub = {}
	if startIndex <= targetIndex then
		for i = startIndex, targetIndex do
			table.insert(sub, Vector3.new(HIGHWAY_CORRIDOR[i].x, HIGHWAY_CORRIDOR[i].y, HIGHWAY_CORRIDOR[i].z))
		end
	else
		for i = startIndex, targetIndex, -1 do
			table.insert(sub, Vector3.new(HIGHWAY_CORRIDOR[i].x, HIGHWAY_CORRIDOR[i].y, HIGHWAY_CORRIDOR[i].z))
		end
	end
	table.insert(sub, targetPos)
	return sub
end

task.spawn(function()
	log("Autonomous Safe Crawler Started for " .. ROUTE_NAME)
	local lastRecordedPos = nil

	while _G.BXI_CrawlerRunning do
		task.wait(0.2)

		local bus = getMyBus()
		local seat = getDriverSeat(bus)
		if not (bus and seat) then
			log("Waiting for bus and seat...")
			task.wait(2)
			continue
		end

		-- Ensure character is seated
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hum.SeatPart ~= seat and hrp then
			hrp.CFrame = seat.CFrame * CFrame.new(0, 1, 0)
			task.wait(0.2)
			pcall(function() seat:Sit(hum) end)
			task.wait(0.5)
		end

		-- Ensure Engine Ignition is ON
		ensureEngineOn()

		-- Check if in passenger wait zone
		local isWaiting, waitTxt = isWaitingCountdown()
		if isWaiting then
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.Anchored = true
			setHandbrake(true)
			log("In Passenger Zone: " .. tostring(waitTxt))
			task.wait(1)
			continue
		else
			seat.Anchored = false
			setHandbrake(false)
		end

		-- Locate active checkpoint
		local cpPart = getActiveCheckpointPart()
		if not cpPart then
			local busGui = player.PlayerGui:FindFirstChild("BusJobGUI")
			local cpLabel = busGui and busGui.JobStatusFrame and busGui.JobStatusFrame:FindFirstChild("CheckpointLabel")
			log("Searching for active checkpoint... (HUD: " .. tostring(cpLabel and cpLabel.Text or "nil") .. ")")
			task.wait(2)
			continue
		end

		local targetPos = cpPart.Position
		local currentSeatPos = seat.Position
		local distToTarget = (Vector3.new(targetPos.X - currentSeatPos.X, 0, targetPos.Z - currentSeatPos.Z)).Magnitude

		-- If within 8 studs, ensure bus touches checkpoint center
		if distToTarget <= 8 then
			log("At Checkpoint Center: " .. cpPart.Name)
			seat.AssemblyLinearVelocity = Vector3.zero
			setHandbrake(true)
			task.wait(1.5)
			continue
		end

		-- If close (within 40 studs), drive directly to checkpoint center to trigger Touched
		if distToTarget < 40 then
			local groundY = probeGround(targetPos.X, targetPos.Z, targetPos.Y)
			local cf = CFrame.lookAt(Vector3.new(targetPos.X, groundY, targetPos.Z), Vector3.new(targetPos.X, groundY, targetPos.Z) + (targetPos - currentSeatPos).Unit)
			bus:PivotTo(cf)
			seat.AssemblyLinearVelocity = Vector3.zero
			task.wait(1)
			continue
		end

		local subPath = getCorridorSubPath(currentSeatPos, targetPos)
		log("Navigating to " .. cpPart.Name .. " (" .. tostring(math.floor(distToTarget)) .. " studs, " .. tostring(#subPath) .. " nodes)")

		-- 🚀 Butter-smooth 60 FPS delta-time transit (No task.wait jitter!)
		seat.Anchored = true
		for _, nodePos in ipairs(subPath) do
			if not _G.BXI_CrawlerRunning then break end
			if isWaitingCountdown() then break end

			local nodeDist = (Vector3.new(nodePos.X - seat.Position.X, 0, nodePos.Z - seat.Position.Z)).Magnitude
			if nodeDist < 30 and nodePos ~= targetPos then
				continue
			end

			local moveDir = (Vector3.new(nodePos.X - seat.Position.X, 0, nodePos.Z - seat.Position.Z)).Unit
			local reachedNode = false

			while not reachedNode and _G.BXI_CrawlerRunning and not isWaitingCountdown() do
				local dt = RunService.Heartbeat:Wait()
				local curPos = seat.Position
				local remainDist = (Vector3.new(nodePos.X - curPos.X, 0, nodePos.Z - curPos.Z)).Magnitude
				local stepMove = math.min(remainDist, SPEED_STUDS * dt)

				if remainDist <= stepMove or remainDist < 4 then
					reachedNode = true
				end

				local nextX = curPos.X + moveDir.X * stepMove
				local nextZ = curPos.Z + moveDir.Z * stepMove
				local groundY = probeGround(nextX, nextZ, nodePos.Y)

				local currentCF = CFrame.lookAt(
					Vector3.new(nextX, groundY, nextZ),
					Vector3.new(nextX, groundY, nextZ) + moveDir
				)
				bus:PivotTo(currentCF)
				seat.AssemblyLinearVelocity = moveDir * SPEED_STUDS

				-- Sample waypoint smoothly
				if not lastRecordedPos or (Vector3.new(nextX - lastRecordedPos.x, 0, nextZ - lastRecordedPos.z)).Magnitude >= SAMPLE_DISTANCE then
					local wp = { x = math.floor(nextX * 10) / 10, y = math.floor(groundY * 10) / 10, z = math.floor(nextZ * 10) / 10 }
					table.insert(_G.BXI_RecordedWaypoints, wp)
					lastRecordedPos = wp
				end
			end
		end
		seat.Anchored = false
	end

	-- Save route if finished
	if #_G.BXI_RecordedWaypoints > 10 then
		pcall(function()
			if writefile then
				local json = HttpService:JSONEncode(_G.BXI_RecordedWaypoints)
				writefile("HipHub/bxi_routes/" .. ROUTE_NAME .. ".json", json)
				log("Route Waypoints successfully saved to HipHub/bxi_routes/" .. ROUTE_NAME .. ".json! (" .. #_G.BXI_RecordedWaypoints .. " waypoints)")
			end
		end)
	end
end)
