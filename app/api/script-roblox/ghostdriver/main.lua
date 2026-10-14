-- HipHub Ghost Driver — Main Controller & UI Binding
-- Populates all Dashboard, Auto Farm, Vehicle, Dealership, and Teleport tabs with live controls

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer

	local UI = _G.HipHubUI
	if not UI then return end

	local Settings = _G.HipHub_GhostDriver_Settings
	local Config = _G.HipHubConfig or { farm = {}, vehicle = {}, settings = {} }
	local Farm = _G.HipHub_GhostDriver_Farm
	local Vehicle = _G.HipHub_GhostDriver_Vehicle
	local Teleport = _G.HipHub_GhostDriver_Teleport

	local CarCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Menu"):WaitForChild("CarCatalog"))
	local PurchaseCarRemote = ReplicatedStorage:WaitForChild("Remotes", 15):WaitForChild("PurchaseCar", 15)

	------------------------------------------------
	-- WINDOW DRAGGING & CONTROLS
	------------------------------------------------
	local mainFrame = UI.mainFrame
	local topBar = UI.topBar
	local dragging, dragStart, startPos
	local isMinimized = false
	local origSize = mainFrame.Size

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
			UI.SyncShadow()
		end
	end)

	UI.closeButton.MouseButton1Click:Connect(function()
		UI.gui.Enabled = false
		if UI.shadowFrame then UI.shadowFrame.Visible = false end
	end)

	UI.minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			mainFrame.Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 42)
			UI.contentArea.Visible = false
			UI.sidebar.Visible = false
		else
			mainFrame.Size = origSize
			UI.contentArea.Visible = true
			UI.sidebar.Visible = true
		end
		UI.SyncShadow()
	end)

	-- Keybind toggle (RightControl or Insert)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
			UI.gui.Enabled = not UI.gui.Enabled
			if UI.shadowFrame then UI.shadowFrame.Visible = UI.gui.Enabled end
		end
	end)

	------------------------------------------------
	-- ANTI-AFK & ACTIVITY HEARTBEAT (BAC-SAFE)
	------------------------------------------------
	-- Safely neutralise Roblox 20-minute client idle kick without VirtualUser
	pcall(function()
		local getconns = getconnections or get_signal_cons
		if getconns then
			for _, conn in ipairs(getconns(player.Idled)) do
				if conn.Disable then
					conn:Disable()
				elseif conn.Disconnect then
					conn:Disconnect()
				end
			end
		end
	end)

	-- Keep-Alive Loop: Satisfies Ghost Driver's AC6 and Activity Bot Check remotes
	-- Completely undetectable because it mimics legit client InputHeartbeat
	task.spawn(function()
		while true do
			task.wait(4)
			if Config.settings.antiAfk ~= false then
				pcall(function()
					local ac6 = ReplicatedStorage:FindFirstChild("AC6Shared")
					if ac6 and ac6:FindFirstChild("Remotes") and ac6.Remotes:FindFirstChild("InputHeartbeat") then
						ac6.Remotes.InputHeartbeat:FireServer()
					end
				end)
				pcall(function()
					local remotes = require(ReplicatedStorage.Packages.Remotes)
					if remotes and remotes.InputHeartbeat then
						remotes.InputHeartbeat:FireServer()
					end
				end)
			end
		end
	end)

	------------------------------------------------
	-- 📊 TAB 1: DASHBOARD
	------------------------------------------------
	local secStats = UI.AddSection("Dashboard", "Player & Vehicle Status")
	local statCash = UI.AddStatsCard(secStats, "Cash Balance", "$ " .. tostring(player.leaderstats and player.leaderstats.Cash.Value or 0))
	local statLevel = UI.AddStatsCard(secStats, "Level & Rank", "Level " .. tostring(player.leaderstats and player.leaderstats.Level.Value or 1))
	local statSpeed = UI.AddStatsCard(secStats, "Speed", "0 MPH")
	local statCar = UI.AddStatsCard(secStats, "Current Car", "None")

	-- Real-time stats updater
	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(function()
				if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash") then
					statCash.Update("$ " .. tostring(player.leaderstats.Cash.Value))
				end
				if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
					local rank = player.leaderstats:FindFirstChild("Rank") and player.leaderstats.Rank.Value or "ROOKIE"
					statLevel.Update("Lvl " .. tostring(player.leaderstats.Level.Value) .. " (" .. rank .. ")")
				end

				local car, seat = Farm and Farm.GetMyCar()
				if car and seat then
					statCar.Update(car.Name:gsub(player.Name .. "_", ""))
					local mph = math.floor(seat.AssemblyLinearVelocity.Magnitude * 0.56818)
					statSpeed.Update(tostring(mph) .. " MPH")
				else
					statCar.Update("No Vehicle Active")
					statSpeed.Update("0 MPH")
				end
			end)
		end
	end)

	local secQuick = UI.AddSection("Dashboard", "Quick Actions")
	UI.AddButton(secQuick, "Teleport to Highway Race", "Instant shortcut to race pad", "Teleport", function()
		if Teleport then Teleport.TeleportTo("HighwayRace") end
	end)
	UI.AddButton(secQuick, "Sit In Car", "Immediately board your active vehicle", "Enter Seat", function()
		if Farm then Farm.EnsureInCar() end
	end)

	------------------------------------------------
	-- 🏁 TAB 2: AUTO FARM
	------------------------------------------------
	local secRace = UI.AddSection("Auto Farm", "Auto Race Automation")
	UI.AddToggle(secRace, "Auto Race", "Automatically joins & wins Highway Races 1st place", Config.farm.autoRace, function(v)
		Config.farm.autoRace = v
		if Settings then Settings.Save() end
	end)

	UI.AddToggle(secRace, "Auto Dodge NPC Traffic", "Actively swerves & changes lanes around traffic cars", Config.farm.autoDodgeTraffic ~= false, function(v)
		Config.farm.autoDodgeTraffic = v
		if Settings then Settings.Save() end
	end)

	UI.AddDropdown(secRace, "Race Difficulty", "Select race level (Hard = highest cash payout)", { "Hard", "Normal", "Easy" }, Config.farm.raceDifficulty or "Hard", function(v)
		Config.farm.raceDifficulty = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secRace, "Race Top Speed", "Maximum cruise speed during auto race (MPH)", 200, 420, Config.farm.raceSpeed or 340, " MPH", function(v)
		Config.farm.raceSpeed = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secRace, "Race Cooldown Delay", "Interval between race iterations", 1, 10, Config.farm.raceDelay or 2, "s", function(v)
		Config.farm.raceDelay = v
		if Settings then Settings.Save() end
	end)

	local secQuest = UI.AddSection("Auto Farm", "Daily & Weekly Quests")
	UI.AddToggle(secQuest, "Auto Claim Quests", "Auto claims Daily & Weekly quests as they complete", Config.farm.autoClaimQuests, function(v)
		Config.farm.autoClaimQuests = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secQuest, "Claim All Finished Quests", "Force instant claim of all eligible rewards", "Claim Now", function()
		pcall(function()
			local getQuests = ReplicatedStorage:FindFirstChild("GetQuestsByScope")
			local claim = ReplicatedStorage:FindFirstChild("ClaimQuestByScope")
			if getQuests and claim then
				local totalClaimed = 0
				for _, scope in ipairs({ "Daily", "Weekly" }) do
					local data = getQuests:InvokeServer(scope)
					if data and data.Quests then
						for i, q in ipairs(data.Quests) do
							if not q.Claimed and q.Progress >= q.Max then
								local res = claim:InvokeServer(scope, i)
								if res then
									totalClaimed = totalClaimed + (q.Reward or 0)
								end
							end
						end
					end
				end
				UI.Notify("Quests", "Claimed all rewards! Total Cash: +$" .. tostring(totalClaimed), 3, "success")
			end
		end)
	end)

	local secSpeedFarm = UI.AddSection("Auto Farm", "Highway Speed & Distance Farm")
	UI.AddToggle(secSpeedFarm, "Auto Speed Farm", "Maintains high velocity to grind near-misses and mileage", Config.farm.autoSpeedFarm, function(v)
		Config.farm.autoSpeedFarm = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secSpeedFarm, "Target Speed", "Set cruise control speed for highway driving", 100, 260, Config.farm.targetSpeed or 180, " MPH", function(v)
		Config.farm.targetSpeed = v
		if Settings then Settings.Save() end
	end)

	------------------------------------------------
	-- 🏎️ TAB 3: VEHICLE MODS
	------------------------------------------------
	local secSpawn = UI.AddSection("Vehicle", "Vehicle Spawner")
	local ownedCars = { "Wulfbrecht RZ7", "Kitsuni LX", "StarterCar" }
	pcall(function()
		local req = ReplicatedStorage.Remotes:FindFirstChild("RequestGarageData")
		if req then
			local data = req:InvokeServer()
			if data then
				local list = {}
				for name, _ in pairs(data) do
					table.insert(list, name)
				end
				if #list > 0 then ownedCars = list end
			end
		end
	end)

	local selectedCarToSpawn = Config.vehicle.selectedCar or ownedCars[1]
	UI.AddDropdown(secSpawn, "Select Vehicle", "Choose vehicle from your garage", ownedCars, selectedCarToSpawn, function(v)
		selectedCarToSpawn = v
		Config.vehicle.selectedCar = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secSpawn, "Spawn Vehicle", "Spawns selected car and puts you in driver seat", "Spawn Car", function()
		if Vehicle then Vehicle.SpawnCar(selectedCarToSpawn) end
	end)

	local secMods = UI.AddSection("Vehicle", "Performance & Safety")
	UI.AddToggle(secMods, "Speed Booster", "Increases forward acceleration while driving", Config.vehicle.speedBoost, function(v)
		Config.vehicle.speedBoost = v
		if Settings then Settings.Save() end
	end)

	UI.AddSlider(secMods, "Speed Multiplier", "Boost intensity multiplier", 1, 3, Config.vehicle.speedMultiplier or 1.3, "x", function(v)
		Config.vehicle.speedMultiplier = v
		if Settings then Settings.Save() end
	end)

	UI.AddToggle(secMods, "Auto Unflip", "Automatically re-orient car if flipped upside down", Config.vehicle.autoFlip, function(v)
		Config.vehicle.autoFlip = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secMods, "Unflip Car Now", "Instantly resets vehicle upright angle", "Unflip", function()
		if Vehicle then Vehicle.Unflip() end
	end)

	------------------------------------------------
	-- 🏪 TAB 4: DEALERSHIP & AUTO BUY
	------------------------------------------------
	local secCatalog = UI.AddSection("Dealership", "Auto Car Buyer")
	local catalogNames = {}
	local catalogMap = {}
	for _, c in ipairs(CarCatalog.Cars) do
		if not c.Hidden and c.Price > 0 then
			table.insert(catalogNames, c.Name)
			catalogMap[c.Name] = c
		end
	end

	local targetBuyCar = Config.farm.targetCarToBuy or catalogNames[1] or "Novis N55"
	local cardPrice = UI.AddStatsCard(secCatalog, "Target Car Price", "$ " .. tostring(catalogMap[targetBuyCar] and catalogMap[targetBuyCar].Price or 0))
	local cardTopSpeed = UI.AddStatsCard(secCatalog, "Top Speed", tostring(catalogMap[targetBuyCar] and catalogMap[targetBuyCar].TopSpeed or 0) .. " MPH")

	UI.AddDropdown(secCatalog, "Target Car to Buy", "Select car you want to purchase", catalogNames, targetBuyCar, function(v)
		targetBuyCar = v
		Config.farm.targetCarToBuy = v
		if Settings then Settings.Save() end
		if catalogMap[v] then
			cardPrice.Update("$ " .. tostring(catalogMap[v].Price))
			cardTopSpeed.Update(tostring(catalogMap[v].TopSpeed) .. " MPH")
		end
	end)

	UI.AddToggle(secCatalog, "Auto Buy When Affordable", "Buys vehicle instantly once your Cash is enough", Config.farm.autoBuyCar, function(v)
		Config.farm.autoBuyCar = v
		if Settings then Settings.Save() end
	end)

	UI.AddButton(secCatalog, "Buy Selected Car Now", "Immediate manual purchase request", "Buy Now", function()
		pcall(function()
			if PurchaseCarRemote and targetBuyCar then
				local res, errCode = PurchaseCarRemote:InvokeServer(targetBuyCar)
				if res then
					UI.Notify("Dealership", "Successfully purchased " .. targetBuyCar .. "!", 4, "success")
				else
					UI.Notify("Dealership", "Purchase failed: " .. tostring(errCode or "Not enough cash"), 3, "warn")
				end
			end
		end)
	end)

	------------------------------------------------
	-- 📍 TAB 5: TELEPORTS
	------------------------------------------------
	local secTele = UI.AddSection("Teleports", "Fast Map Travel")
	UI.AddButton(secTele, "Highway Race", "Teleports to Highway Race Starting Area", "Teleport", function()
		if Teleport then Teleport.TeleportTo("HighwayRace") end
	end)

	UI.AddButton(secTele, "Dealership Showroom", "Teleports to Main Dealership", "Teleport", function()
		if Teleport then Teleport.TeleportTo("Dealership") end
	end)

	UI.AddButton(secTele, "Gas Station / AFK Area", "Teleports to Gas Station AFK hub", "Teleport", function()
		if Teleport then Teleport.TeleportTo("GasStation") end
	end)

	local secCarTele = UI.AddSection("Teleports", "Vehicle Teleport")
	UI.AddButton(secCarTele, "Teleport To My Car", "Teleports character directly into car seat", "Go to Car", function()
		if Teleport then Teleport.TeleportToCar() end
	end)

	------------------------------------------------
	-- ⚙️ TAB 6: SETTINGS
	------------------------------------------------
	local secSet = UI.AddSection("Settings", "General Configuration")
	UI.AddToggle(secSet, "Anti-AFK Protection", "Prevents Roblox 20-minute idle disconnection", Config.settings.antiAfk, function(v)
		Config.settings.antiAfk = v
		if Settings then Settings.Save() end
	end)

	UI.AddLabel(secSet, "Toggle Menu Key: RightControl or Insert")

	UI.AddButton(secSet, "Rejoin Server", "Quickly reconnects to the current place", "Rejoin", function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, player)
	end)

	UI.AddButton(secSet, "Unload Script", "Closes and completely destroys script UI", "Unload", function()
		if UI.gui then UI.gui:Destroy() end
		if UI.shadowFrame then UI.shadowFrame:Destroy() end
	end)
end)

if not success then
	warn("[HipHub Ghost Driver Main Error]:", err)
end
