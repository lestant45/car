-- 📍 HipHub CDID — World & Player Teleportation System
-- Handles Dealerships, Job HQs, City Landmarks, Gas Stations, Custom Waypoints, and Player Teleportation

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local player = Players.LocalPlayer

	-- Get player car
	local function getPlayerCar()
		local vehicles = workspace:FindFirstChild("Vehicles")
		if not vehicles then return nil end
		return vehicles:FindFirstChild(player.Name .. "sCar") or vehicles:FindFirstChild(player.Name .. "'s Car")
	end

	local tpWithCar = true
	local tpSpeed = 150
	local useSmoothTween = false

	-- Universal Safe Teleport Function
	local function teleportTo(cframe)
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local car = tpWithCar and getPlayerCar() or nil
		local targetPart = (car and (car.PrimaryPart or car:FindFirstChild("DriveSeat"))) or root

		if useSmoothTween then
			local dist = (targetPart.Position - cframe.Position).Magnitude
			local time = math.clamp(dist / tpSpeed, 0.2, 8)
			local tw = TweenService:Create(targetPart, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = cframe })
			tw:Play()
			tw.Completed:Wait()
		else
			if car and car.PrimaryPart then
				car:SetPrimaryPartCFrame(cframe)
			elseif car and car:FindFirstChild("DriveSeat") then
				car.DriveSeat.CFrame = cframe
			else
				root.CFrame = cframe
			end
		end
	end

	------------------------------------------------
	-- 📍 LOCATION DATA
	------------------------------------------------
	local JobLocations = {
		["BCA Bank Courier (Koper Spawn)"] = Vector3.new(1250, 35, 1450),
		["BCA Reward Exchange Booth"] = Vector3.new(1260, 35, 1460),
		["SiLambat HQ"] = Vector3.new(-4023.717, 23.472, 4620.15),
		["Hospital / EMS"] = Vector3.new(-24225.34, 30.682, 13797.631),
		["Janji Jawa (Coffee)"] = Vector3.new(-22778.883, 26.077, 15431.812),
		["Burung Biru (Taxi HQ)"] = Vector3.new(2276.413, 28.783, -4590.166),
		["Office Building"] = Vector3.new(-1036.024, 263.99, 2252.971),
		["Truck Logistics HQ"] = Vector3.new(1955.909, 21.8, -3455.494),
		["Travel Shuttle"] = Vector3.new(6497.432, 22.93, -7647.746),
		["Gowes Bike Rental"] = Vector3.new(3026.47, 22.716, -6676.164)
	}

	local CityLandmarks = {
		["Menara BCA / BCA Tower Thamrin"] = Vector3.new(1250, 35, 1450),
		["MRT Blok M BCA Station"] = Vector3.new(-1500, 25, 2100),
		["Monas (Monumen Nasional)"] = Vector3.new(4848.864, 20.502, -7769.96),
		["GBK Stadium Senayan"] = Vector3.new(-2196.127, 23.245, 1482.061),
		["Plaza Senayan Mall"] = Vector3.new(-4141.175, 25.965, 3392.429),
		["Stasiun Gambir"] = Vector3.new(6502.558, 19.901, -7691.016),
		["Spark Senayan Mall"] = Vector3.new(-4016.842, 20.996, -486.268),
		["Mitra Terrace"] = Vector3.new(1348.83, 44.066, 1377.256),
		["CDID Mart Supermarket"] = Vector3.new(2047.507, 20.418, -3696.606),
		["Pensha Bakso Malang"] = Vector3.new(582.702, 20.416, -3764.472),
		["Main Highway Toll Gate"] = Vector3.new(1250, 25, -2400),
		["Sentul Circuit"] = Vector3.new(15000, 30, -12000)
	}

	local DealershipLocations = {
		["Toyota Showroom"] = Vector3.new(2500, 25, -4500),
		["Honda Dealership"] = Vector3.new(1800, 25, -4200),
		["Hyundai Motorstudio"] = Vector3.new(2200, 25, -4800),
		["Lexus Experience Center"] = Vector3.new(3100, 25, -4600),
		["DIR (Supercars & Exotics)"] = Vector3.new(1500, 25, -3900),
		["Mercedes-Benz Dealership"] = Vector3.new(2800, 25, -5100),
		["BMW Eurokars"] = Vector3.new(2700, 25, -4900),
		["Porsche Center"] = Vector3.new(3400, 25, -5200),
		["Retro & Classic Cars"] = Vector3.new(900, 25, -3200)
	}

	-- Auto detect any dynamic Dealership parts from workspace
	pcall(function()
		local dealerFolder = workspace:FindFirstChild("Etc") and workspace.Etc:FindFirstChild("Dealership")
		if dealerFolder then
			for _, d in pairs(dealerFolder:GetChildren()) do
				local part = d:FindFirstChild("Part") or d:FindFirstChildOfClass("BasePart")
				if part then
					DealershipLocations[d.Name .. " Dealership"] = part.Position
				end
			end
		end
	end)

	------------------------------------------------
	-- 🎨 BUILD TELEPORT TAB UI
	------------------------------------------------
	local tpFrame = UI.tabs["Teleport"].Frame

	-- Teleport Settings
	local optSec = UI.AddSection(tpFrame, "Teleport Options", 1)
	UI.AddToggle(optSec, "Teleport Vehicle with Character (if inside car)", tpWithCar, function(v)
		tpWithCar = v
	end, 1)

	UI.AddToggle(optSec, "Use Smooth Tween (Anti-Flykick)", useSmoothTween, function(v)
		useSmoothTween = v
	end, 2)

	UI.AddSlider(optSec, "Tween Flight Speed", 50, 300, tpSpeed, function(v)
		tpSpeed = v
	end, 3, " studs/s")

	-- Dealerships
	local dealerSec = UI.AddSection(tpFrame, "Dealerships & Showrooms", 2)
	local dealerNames = {}
	for name, _ in pairs(DealershipLocations) do table.insert(dealerNames, name) end
	table.sort(dealerNames)

	local selectedDealer = dealerNames[1]
	UI.AddDropdown(dealerSec, "Select Dealership", dealerNames, selectedDealer, function(v)
		selectedDealer = v
	end, 1)

	UI.AddButton(dealerSec, "Teleport to Dealership", function()
		local pos = DealershipLocations[selectedDealer]
		if pos then
			teleportTo(CFrame.new(pos + Vector3.new(0, 4, 0)))
			UI.Notify("Teleport", "Tiba di " .. selectedDealer, 2, "success")
		end
	end, 2)

	-- Job Starters & HQs
	local jobSec = UI.AddSection(tpFrame, "Job HQs & Workplace Starters", 3)
	local jobNames = {}
	for name, _ in pairs(JobLocations) do table.insert(jobNames, name) end
	table.sort(jobNames)

	local selectedJob = jobNames[1]
	UI.AddDropdown(jobSec, "Select Job HQ", jobNames, selectedJob, function(v)
		selectedJob = v
	end, 1)

	UI.AddButton(jobSec, "Teleport to Job HQ", function()
		local pos = JobLocations[selectedJob]
		if pos then
			teleportTo(CFrame.new(pos + Vector3.new(0, 4, 0)))
			UI.Notify("Teleport", "Tiba di " .. selectedJob, 2, "success")
		end
	end, 2)

	-- Landmarks & Cities
	local citySec = UI.AddSection(tpFrame, "Cities & Landmarks (Jakarta Map)", 4)
	local cityNames = {}
	for name, _ in pairs(CityLandmarks) do table.insert(cityNames, name) end
	table.sort(cityNames)

	local selectedCity = cityNames[1]
	UI.AddDropdown(citySec, "Select Landmark", cityNames, selectedCity, function(v)
		selectedCity = v
	end, 1)

	UI.AddButton(citySec, "Teleport to Landmark", function()
		local pos = CityLandmarks[selectedCity]
		if pos then
			teleportTo(CFrame.new(pos + Vector3.new(0, 4, 0)))
			UI.Notify("Teleport", "Tiba di " .. selectedCity, 2, "success")
		end
	end, 2)

	-- Player Teleports
	local plySec = UI.AddSection(tpFrame, "Player Teleportation", 5)
	local playerList = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then table.insert(playerList, p.Name) end
	end
	if #playerList == 0 then table.insert(playerList, "No other players") end

	local selectedPlayer = playerList[1]
	local playerDrop = UI.AddDropdown(plySec, "Select Target Player", playerList, selectedPlayer, function(v)
		selectedPlayer = v
	end, 1)

	UI.AddButton(plySec, "Refresh Player List", function()
		local updated = {}
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player then table.insert(updated, p.Name) end
		end
		if #updated == 0 then table.insert(updated, "No other players") end
		playerDrop.Refresh(updated)
		UI.Notify("Player List", "Daftar player diperbarui.", 1, "success")
	end, 2)

	UI.AddButton(plySec, "Teleport to Selected Player", function()
		local target = Players:FindFirstChild(selectedPlayer)
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			teleportTo(CFrame.new(target.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 3)))
			UI.Notify("Teleport", "Teleport ke " .. selectedPlayer, 2, "success")
		else
			UI.Notify("Teleport", "Karakter player tidak ditemukan.", 2, "warning")
		end
	end, 3)

	-- Export global teleport API
	_G.HipHubTeleport = {
		TeleportTo = teleportTo,
		JobLocations = JobLocations,
		CityLandmarks = CityLandmarks,
		DealershipLocations = DealershipLocations
	}
end)

if not success then
	warn("[HipHub CDID Teleport Error]:", err)
end
