-- 📍 HipHub DDS — Teleport Locations, Waypoints & Safe Travel
-- Drag Drive Simulator (Place ID: 131378148336503)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Teleport"].content
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local player = Players.LocalPlayer

	------------------------------------------------
	-- 🗺️ DDS PRESET LOCATIONS
	------------------------------------------------
	local LOCATIONS = {
		Dealerships = {
			["Yahamax Dealer"] = Vector3.new(-835, 4, -420),
			["Hando Dealer"] = Vector3.new(245, 4, 380),
			["Kawzaki Dealer"] = Vector3.new(-410, 4, 820),
			["Luxury Motorbike Dealer"] = Vector3.new(620, 4, -120),
			["Sizuki Dealer"] = Vector3.new(-120, 4, -650),
			["Vespero Dealer"] = Vector3.new(450, 4, 910),
			["Car Dealer"] = Vector3.new(-680, 4, 150),
			["Truck Dealer"] = Vector3.new(890, 4, 520),
			["DragSpec Dealer"] = Vector3.new(-1420, 4, 310),
			["Police Vehicle Dealer"] = Vector3.new(-1150, 4, -890)
		},
		Jobs = {
			["Starbooks Coffee (Barista)"] = Vector3.new(315, 4, -220),
			["Courier Office Jajar"] = Vector3.new(-540, 4, 460),
			["Rajawali Office (Worker)"] = Vector3.new(120, 4, 680),
			["Surakarta Police HQ"] = Vector3.new(-1100, 4, -850)
		},
		Landmarks = {
			["Drag Race Strip (Start)"] = Vector3.new(-9043, 4, 854),
			["Drag Race Strip (Finish)"] = Vector3.new(-8200, 4, 854),
			["Manahan Town Square"] = Vector3.new(0, 4, 0),
			["Colomadu Residence"] = Vector3.new(780, 4, -750),
			["Modification Garage"] = Vector3.new(-320, 4, 180),
			["Purwosari Flyover"] = Vector3.new(420, 18, 50),
			["Ngemplak Toll Gate"] = Vector3.new(1250, 6, 1100),
			["Football Pitch / Stadium"] = Vector3.new(-750, 4, -480)
		}
	}

	local teleportMode = "Instant" -- "Instant" or "Safe Tween"
	local tweenSpeed = 120

	local function getTargetPart()
		local char = player.Character
		if not char then return nil end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart then
			local seat = humanoid.SeatPart
			local model = seat:FindFirstAncestorOfClass("Model")
			if model and model.PrimaryPart then
				return model.PrimaryPart
			end
			return seat
		end

		return char:FindFirstChild("HumanoidRootPart")
	end

	local function teleportTo(targetPos)
		local part = getTargetPart()
		if not part then return end

		local goalCFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))

		if teleportMode == "Instant" then
			part.CFrame = goalCFrame
			UI.Notify("Teleported", "Arrived at destination.", 2, "success")
		else
			local dist = (part.Position - targetPos).Magnitude
			local duration = math.max(0.5, dist / tweenSpeed)
			local tw = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = goalCFrame })
			tw:Play()
			UI.Notify("Travelling...", "Safe gliding at " .. tweenSpeed .. " studs/s", 2, "warning")
		end
	end

	------------------------------------------------
	-- 💾 CUSTOM SAVED WAYPOINTS
	------------------------------------------------
	local savedWaypoints = {}

	local function saveCurrentLocation(name)
		if not name or name == "" then
			UI.Notify("Error", "Please enter a valid waypoint name.", 2, "danger")
			return
		end

		local part = getTargetPart()
		if part then
			savedWaypoints[name] = part.Position
			UI.Notify("Waypoint Saved", "Saved '" .. name .. "' successfully.", 2, "success")
		end
	end

	------------------------------------------------
	-- 🖼️ UI COMPONENTS IN TELEPORT TAB
	------------------------------------------------
	UI.AddSection(tab, "Teleport Mode & Speed")
	UI.AddDropdown(tab, "Travel Mode", { "Instant", "Safe Tween" }, 1, function(selected)
		teleportMode = selected
	end)

	UI.AddSlider(tab, "Tween Speed (Studs/s)", 40, 300, 120, function(val)
		tweenSpeed = val
	end)

	UI.AddSection(tab, "Dealerships")
	local dealerNames = {}
	for name, _ in pairs(LOCATIONS.Dealerships) do
		table.insert(dealerNames, name)
	end
	table.sort(dealerNames)

	local selectedDealer = dealerNames[1]
	UI.AddDropdown(tab, "Select Dealer", dealerNames, 1, function(name)
		selectedDealer = name
	end)
	UI.AddButton(tab, "Teleport to Dealership", "Go", function()
		if selectedDealer and LOCATIONS.Dealerships[selectedDealer] then
			teleportTo(LOCATIONS.Dealerships[selectedDealer])
		end
	end)

	UI.AddSection(tab, "Job Locations")
	local jobNames = {}
	for name, _ in pairs(LOCATIONS.Jobs) do
		table.insert(jobNames, name)
	end
	table.sort(jobNames)

	local selectedJob = jobNames[1]
	UI.AddDropdown(tab, "Select Job", jobNames, 1, function(name)
		selectedJob = name
	end)
	UI.AddButton(tab, "Teleport to Job", "Go", function()
		if selectedJob and LOCATIONS.Jobs[selectedJob] then
			teleportTo(LOCATIONS.Jobs[selectedJob])
		end
	end)

	UI.AddSection(tab, "Landmarks & Drag Circuits")
	local landmarkNames = {}
	for name, _ in pairs(LOCATIONS.Landmarks) do
		table.insert(landmarkNames, name)
	end
	table.sort(landmarkNames)

	local selectedLandmark = landmarkNames[1]
	UI.AddDropdown(tab, "Select Landmark", landmarkNames, 1, function(name)
		selectedLandmark = name
	end)
	UI.AddButton(tab, "Teleport to Landmark", "Go", function()
		if selectedLandmark and LOCATIONS.Landmarks[selectedLandmark] then
			teleportTo(LOCATIONS.Landmarks[selectedLandmark])
		end
	end)

	UI.AddSection(tab, "Custom Waypoint Saver")
	local customWaypointName = "My Spot"
	UI.AddTextbox(tab, "Waypoint Name", "Enter name...", function(text)
		customWaypointName = text
	end)
	UI.AddButton(tab, "Save Current Location", "Save", function()
		saveCurrentLocation(customWaypointName)
	end)
end)

if not success then
	warn("[HipHub DDS Teleport Error]:", err)
end
