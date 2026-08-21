-- 💰 HipHub CDID — Auto Farm & Money Generation System
-- Modular Auto Farm logic for Car Driving Indonesia (CDID)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Config = _G.HipHubConfig or { farm = {} }
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

	-- Safe Character Teleport Function
	local function safeTeleport(cframe, useTween, speed)
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		if useTween then
			speed = speed or 120
			local dist = (root.Position - cframe.Position).Magnitude
			local time = math.clamp(dist / speed, 0.2, 5)
			local tw = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = cframe })
			tw:Play()
			tw.Completed:Wait()
		else
			root.CFrame = cframe
		end
	end

	-- Find player's vehicle
	local function getPlayerCar()
		local vehicles = workspace:FindFirstChild("Vehicles")
		if not vehicles then return nil end
		return vehicles:FindFirstChild(player.Name .. "sCar") or vehicles:FindFirstChild(player.Name .. "'s Car")
	end

	-- Helper to find true ground asphalt level below any building roof/ceiling
	local function getGroundPosition(targetPos)
		local rayParams = RaycastParams.new()
		local car = getPlayerCar()
		local char = player.Character
		rayParams.FilterDescendantsInstances = { car, char }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		-- Raycast downward starting +2.5 studs above targetPos (below any ceiling)
		local hit = workspace:Raycast(targetPos + Vector3.new(0, 2.5, 0), Vector3.new(0, -35, 0), rayParams)
		if hit then
			return Vector3.new(targetPos.X, hit.Position.Y + 1.2, targetPos.Z)
		end
		return targetPos
	end

	-- Teleport Player & Vehicle together safely directly on the ground
	local function safeTeleportCar(cframe)
		local groundPos = getGroundPosition(cframe.Position)
		local safeCF = CFrame.new(groundPos) * (cframe - cframe.Position)
		local car = getPlayerCar()

		if car then
			pcall(function()
				car:PivotTo(safeCF)
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
		end
		safeTeleport(CFrame.new(groundPos + Vector3.new(0, 1, 0)), false)
	end

	-- Smooth Tween Car & Player to Destination (Glide smoothly and prevent wall flinging/collisions)
	local function safeTweenCar(targetCF, speed)
		local car = getPlayerCar()
		if not car then
			safeTeleport(targetCF, true, speed)
			return
		end

		local groundPos = getGroundPosition(targetCF.Position)
		local destCF = CFrame.new(groundPos) * (targetCF - targetCF.Position)
		local startCF = car:GetPivot()
		local dist = (startCF.Position - destCF.Position).Magnitude

		speed = speed or 220
		local duration = math.clamp(dist / speed, 0.4, 4.5)

		-- Zero out physics velocities before, during, and after tween
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end

		local t0 = os.clock()
		local conn
		local finished = false

		conn = RunService.Heartbeat:Connect(function()
			if not bcaCourierActive then
				if conn then conn:Disconnect() end
				finished = true
				return
			end

			local elapsed = os.clock() - t0
			local alpha = math.clamp(elapsed / duration, 0, 1)
			-- Smooth sine ease in-out
			local easedAlpha = -(math.cos(math.pi * alpha) - 1) / 2
			local currentCF = startCF:Lerp(destCF, easedAlpha)

			pcall(function()
				car:PivotTo(currentCF)
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end

				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					char.HumanoidRootPart.CFrame = currentCF + Vector3.new(0, 1.5, 3)
					char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
				end
			end)

			if alpha >= 1 then
				finished = true
				if conn then conn:Disconnect() end
			end
		end)

		while not finished and bcaCourierActive do
			task.wait(0.02)
		end
		if conn then pcall(function() conn:Disconnect() end) end

		-- Settle car firmly on ground
		pcall(function()
			car:PivotTo(destCF)
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end)
		safeTeleport(CFrame.new(groundPos + Vector3.new(0, 1.5, 3)), false)
	end

	------------------------------------------------
	-- 🚚 SILAMBAT COURIER AUTO FARM
	------------------------------------------------
	local siLambatActive = false
	local siLambatDelay = Config.farm.siLambatDelay or 1.2
	local siLambatHQ = Vector3.new(-4023.717, 23.472, 4620.15)

	local function runSiLambatFarm()
		task.spawn(function()
			while siLambatActive do
				pcall(function()
					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					-- Step 1: Teleport to SiLambat HQ to start / pickup package
					safeTeleport(CFrame.new(siLambatHQ + Vector3.new(0, 3, 0)))
					task.wait(siLambatDelay)

					-- Trigger Package Collection / Interaction
					fireRemote("Job", "SiLambat")
					task.wait(0.5)

					-- Step 2: Check for destination waypoint or NPC
					local waypoints = workspace:FindFirstChild("Etc") and workspace.Etc:FindFirstChild("Waypoint")
					local targetPos = nil

					if waypoints and #waypoints:GetChildren() > 0 then
						for _, wp in pairs(waypoints:GetChildren()) do
							if wp:IsA("BasePart") then
								targetPos = wp.Position
								break
							end
						end
					end

					-- If no specific waypoint found, check NPC or default delivery locations
					if not targetPos then
						local npcs = workspace:FindFirstChild("NPC")
						if npcs and #npcs:GetChildren() > 0 then
							local npc = npcs:GetChildren()[1]
							if npc:FindFirstChild("HumanoidRootPart") then
								targetPos = npc.HumanoidRootPart.Position
							end
						end
					end

					if not targetPos then
						-- Sample fallback SiLambat destinations (Gambir, Office, CDID Mart, Spark)
						local defaults = {
							Vector3.new(6502.558, 19.901, -7691.016),
							Vector3.new(-1107.12, 22.5, 2228.214),
							Vector3.new(2047.507, 20.418, -3696.606),
							Vector3.new(-4248.968, 18.562, -381.809)
						}
						targetPos = defaults[math.random(1, #defaults)]
					end

					-- Step 3: Teleport to delivery spot
					safeTeleport(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
					task.wait(siLambatDelay)

					-- Step 4: Fire Delivery Remote & Trigger Proximity Prompts
					fireRemote("SiLambat", "Delivery")

					pcall(function()
						for _, prompt in pairs(workspace:GetDescendants()) do
							if prompt:IsA("ProximityPrompt") and prompt.Enabled then
								if prompt.ActionText:lower():find("deliver") or prompt.ObjectText:lower():find("package") or prompt.ActionText:lower():find("ambil") then
									fireproximityprompt(prompt)
								end
							end
						end
					end)

					task.wait(siLambatDelay)
				end)
				task.wait(0.5)
			end
		end)
	end

	------------------------------------------------
	-- ☕ JANJI JIWA (COFFEE DELIVERY) AUTO FARM
	------------------------------------------------
	local janjiJiwaActive = false
	local janjiJiwaDelay = Config.farm.janjiJiwaDelay or 1.2
	local janjiJiwaStart = Vector3.new(-22778.883, 26.077, 15431.812)

	local function runJanjiJiwaFarm()
		task.spawn(function()
			while janjiJiwaActive do
				pcall(function()
					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					-- Step 1: Teleport to Coffee Shop
					safeTeleport(CFrame.new(janjiJiwaStart + Vector3.new(0, 3, 0)))
					task.wait(janjiJiwaDelay)

					-- Trigger start / grab coffee
					fireRemote("Job", "JanjiJiwa")
					task.wait(0.5)

					-- Step 2: Teleport to Customer NPC
					local npcs = workspace:FindFirstChild("NPC")
					if npcs and #npcs:GetChildren() > 0 then
						for _, npc in pairs(npcs:GetChildren()) do
							if npc:FindFirstChild("HumanoidRootPart") then
								safeTeleport(CFrame.new(npc.HumanoidRootPart.Position + Vector3.new(0, 2, 2)))
								task.wait(0.5)
								break
							end
						end
					end

					-- Step 3: Complete Coffee Delivery
					fireRemote("JanjiJiwa", "Delivery")
					task.wait(janjiJiwaDelay)
				end)
				task.wait(0.5)
			end
		end)
	end

	------------------------------------------------
	-- 🚑 EMS / HOSPITAL HEAL AUTO FARM
	------------------------------------------------
	local emsActive = false
	local emsDelay = Config.farm.emsDelay or 1.5
	local emsHQ = Vector3.new(-24225.34, 30.682, 13797.631)

	local function runEmsFarm()
		task.spawn(function()
			while emsActive do
				pcall(function()
					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					-- Step 1: Ensure at Hospital / Spawn
					safeTeleport(CFrame.new(emsHQ + Vector3.new(0, 3, 0)))
					task.wait(0.5)
					fireRemote("Job", "Emergency")
					task.wait(emsDelay)

					-- Step 2: Teleport near injured patient NPC
					local npcs = workspace:FindFirstChild("NPC")
					if npcs and #npcs:GetChildren() > 0 then
						for _, npc in pairs(npcs:GetChildren()) do
							if npc:FindFirstChild("HumanoidRootPart") then
								safeTeleport(CFrame.new(npc.HumanoidRootPart.Position + Vector3.new(0, 2, 2)))
								task.wait(0.5)

								-- Step 3: Trigger Heal Remote
								fireRemote("EMS", "Heal")
								task.wait(0.5)
								break
							end
						end
					end

					task.wait(emsDelay)
				end)
				task.wait(0.5)
			end
		end)
	end

	------------------------------------------------
	-- 🏦 BCA EVENT & BANK COURIER AUTO FARM (FULL QUEST AUTOMATION)
	------------------------------------------------
	local bcaCourierActive = false
	local bcaCourierDelay = Config.farm.bcaCourierDelay or 1.0
	local bcaAppSyncActive = false
	local bcaDepotPos = Vector3.new(1866.502, 24, -4874.451)
	local bcaKoperPos = Vector3.new(1779.29, 21.5, -4643.79)

	local function getBankCourierGui()
		local pgui = player:FindFirstChild("PlayerGui")
		return pgui and pgui:FindFirstChild("Job") and pgui.Job:FindFirstChild("BankCourier")
	end

	-- Hook BankCourier Remote to auto-solve ATM Skill Checks and Trunk Koper Drops with 100% precision
	pcall(function()
		if Network and Network.OnClientEvent then
			Network.OnClientEvent("BankCourier", function(action, data)
				if not bcaCourierActive then return end
				if action == "SkillCheck" and typeof(data) == "table" then
					task.spawn(function()
						task.wait(data.warnLead or 0.1)
						local greatSize = data.greatSize or (data.zoneSize / 2)
						local sweetAngle = (data.zoneStart or 0) + (greatSize / 2)
						Network:FireServer("BankCourier", "SkillPress", sweetAngle)
					end)
				elseif action == "LoadRound" and typeof(data) == "table" then
					task.spawn(function()
						-- Calculate exact time when koper reaches the center of the slot
						local sweetX = (data.greenStart or 0.2) + ((data.greenSize or 0.2) / 2)
						local dropDelay = math.clamp(sweetX * (data.period or 1.2), 0.05, 3)
						task.wait(dropDelay)
						local jobGui = getBankCourierGui()
						local goBtn = jobGui and jobGui:FindFirstChild("Timing") and jobGui.Timing:FindFirstChild("Go")
						if goBtn and firesignal then
							firesignal(goBtn.Activated)
							firesignal(goBtn.MouseButton1Click)
						end
						Network:FireServer("BankCourier", "LoadPress")
					end)
				end
			end)
		end
	end)

	local function triggerPrompt(prompt, holdTime)
		if not prompt then return end
		pcall(function()
			prompt.HoldDuration = 0
			if prompt.InputHoldBegin and (holdTime or 0) > 0 then
				prompt:InputHoldBegin()
				task.wait(holdTime)
				prompt:InputHoldEnd()
			elseif fireproximityprompt then
				fireproximityprompt(prompt)
			end
		end)
	end

	local function spawnBankCar()
		local npc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("CAR_SPAWNER_NPC")
		local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")

		-- 1. Teleport right in front of Putra NPC
		if npcRoot then
			safeTeleport(npcRoot.CFrame + npcRoot.CFrame.LookVector * 3 + Vector3.new(0, 0.5, 0))
		else
			safeTeleport(CFrame.new(bcaDepotPos))
		end
		task.wait(0.4)

		-- 2. Trigger Putra Dialog Prompt
		if npc then
			local prompt = npc:FindFirstChild("DialogPrompt", true)
			triggerPrompt(prompt)
		end

		-- 3. Wait for NpcDialog choices and click Yes
		local dialog = player.PlayerGui:WaitForChild("NpcDialog", 3)
		local yesBtn = dialog and dialog:FindFirstChild("Yes", true)

		local t0 = os.clock()
		while (not yesBtn or not yesBtn.Visible) and os.clock() - t0 < 3 do
			dialog = player.PlayerGui:FindFirstChild("NpcDialog")
			yesBtn = dialog and dialog:FindFirstChild("Yes", true)
			task.wait(0.1)
		end

		if yesBtn then
			if firesignal then
				firesignal(yesBtn.Activated)
				firesignal(yesBtn.MouseButton1Click)
			end
			if getconnections then
				for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
				for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
			end
		end

		fireRemote("NpcDialog", "Finish", 1)
		fireRemote("NpcDialog", "Finish", "SpawnBankCar")
		fireRemote("BankCourier", "RespawnCar")

		-- 4. Wait until vehicle actually exists in workspace
		local t1 = os.clock()
		local car = nil
		while os.clock() - t1 < 6 do
			car = getPlayerCar()
			if car then break end
			task.wait(0.2)
		end

		-- 5. Safely position the vehicle on the asphalt driveway beside the entrance
		if car then
			local koperParkCFrame = CFrame.new(1774.5, 20.2, -4629.0) * CFrame.Angles(0, math.rad(-75), 0)
			pcall(function()
				car:PivotTo(koperParkCFrame)
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
			task.wait(0.5)

			-- Teleport player beside car to register vehicle movement with game
			safeTeleport(koperParkCFrame + Vector3.new(0, 1.5, 3))
			task.wait(0.5)
		end

		return getPlayerCar()
	end

	local function parseProgress(text)
		local cur, total = string.match(text or "", "(%d+)/(%d+)")
		return tonumber(cur) or 0, tonumber(total) or 0
	end

	local function loadKopersIntoCar(car)
		local jobGui = getBankCourierGui()
		local timing = jobGui and jobGui:FindFirstChild("Timing")
		local koperPart = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("KoperSpawn") and workspace.MY_BCA_COLLAB.Job.BankCourier.KoperSpawn:FindFirstChild("Part")

		-- Ensure car is parked right on the asphalt driveway
		local koperParkCFrame = CFrame.new(1774.5, 20.2, -4629.0) * CFrame.Angles(0, math.rad(-75), 0)
		if car and (car:GetPivot().Position - Vector3.new(1774.5, 20.2, -4629.0)).Magnitude > 15 then
			pcall(function()
				car:PivotTo(koperParkCFrame)
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
			task.wait(0.3)
		end

		while bcaCourierActive do
			local koperText = jobGui and jobGui.Status.Koper.Text or ""
			local stepText = jobGui and jobGui.Status.Step.Text or ""
			local curKoper, totKoper = parseProgress(koperText)

			-- If already full or in step 2 (delivering), stop loading
			if (totKoper > 0 and curKoper >= totKoper) or stepText:find("2)") or stepText:find("Antar") then
				break
			end

			-- 1. Teleport to Koper Stack & Pickup
			if koperPart then
				safeTeleport(koperPart.CFrame + Vector3.new(0, 1.2, 0))
				task.wait(0.3)
				local prompt = koperPart:FindFirstChild("Prompt", true)
				triggerPrompt(prompt)
			else
				safeTeleport(CFrame.new(bcaKoperPos))
			end

			task.wait(0.4)

			-- 2. Teleport to Car Bagasi & Trigger Muat
			local bagasi = car:FindFirstChild("BagasiPoint")
			if bagasi then
				safeTeleport(bagasi.CFrame + Vector3.new(0, 1, 0))
				task.wait(0.3)
				local muatPrompt = bagasi:FindFirstChild("MuatPrompt")
				triggerPrompt(muatPrompt)
			end

			-- 3. Precise Timing Drop into Slot (matching Picture 2)
			local tStart = os.clock()
			while timing and not timing.Visible and os.clock() - tStart < 2.5 do
				task.wait(0.02)
			end

			if timing and timing.Visible then
				local koperImg = timing:FindFirstChild("Track") and timing.Track:FindFirstChild("Koper")
				local slot = timing:FindFirstChild("Trunk") and timing.Trunk:FindFirstChild("Slot")
				local goBtn = timing:FindFirstChild("Go")
				local t0 = os.clock()

				while timing.Visible and os.clock() - t0 < 3.5 do
					if koperImg and slot then
						local kX = koperImg.Position.X.Scale
						local sX = slot.Position.X.Scale
						local sW = slot.Size.X.Scale
						local targetX = sX + (sW / 2)

						-- Drop when koper is within the slot bounds
						if kX >= sX and kX <= (sX + sW) then
							if goBtn then
								if firesignal then
									firesignal(goBtn.Activated)
									firesignal(goBtn.MouseButton1Click)
								end
								if getconnections then
									for _, c in ipairs(getconnections(goBtn.Activated)) do c:Fire() end
								end
							end
							fireRemote("BankCourier", "LoadPress")
							break
						end
					end
					task.wait(0.005)
				end
			else
				fireRemote("BankCourier", "LoadPress")
			end

			task.wait(0.8)
		end
	end

	-- Safe Open Parking Spots for ATMs (Clear sky, open asphalt, no pillars or ceilings)
	local ATM_PARKING_SPOTS = {
		["ATM1"] = CFrame.new(1860, 24.5, -4850),
		["ATM2"] = CFrame.new(2212.55, 27.5, -4594.36) * CFrame.Angles(0, math.rad(90), 0),
		["ATM3"] = CFrame.new(825.0, 24.2, -3810.0),
		["ATM4"] = CFrame.new(2291.25, 27.96, -4882.77),
		["ATM9"] = CFrame.new(1575.0, 52.5, 885.0),
		["ATM10"] = CFrame.new(1975.0, 24.2, -3540.0),
	}

	local function deliverToAtms(car)
		local jobGui = getBankCourierGui()
		local bagasi = car:FindFirstChild("BagasiPoint")

		while bcaCourierActive do
			local atmText = jobGui and jobGui.Status.Atm.Text or ""
			local stepText = jobGui and jobGui.Status.Step.Text or ""
			local curAtm, totAtm = parseProgress(atmText)

			-- If all ATMs filled, stop delivering
			if (totAtm > 0 and curAtm >= totAtm) or stepText:find("3)") or stepText:find("Selesai") then
				break
			end

			local targetPart = workspace:FindFirstChild("__BankCourierTarget")
			if not targetPart or (targetPart.Position - bcaDepotPos).Magnitude < 40 then break end

			-- 1. Get dedicated safe open parking position (or dynamically calculate in open lot)
			local safeAtmCF = nil
			for atmName, spotCF in pairs(ATM_PARKING_SPOTS) do
				local atmObj = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs") and workspace.MY_BCA_COLLAB.Job.BankCourier.ATMs:FindFirstChild(atmName)
				local atmPart = atmObj and atmObj:FindFirstChildWhichIsA("BasePart", true)
				if atmPart and (atmPart.Position - targetPart.Position).Magnitude < 15 then
					safeAtmCF = spotCF
					break
				end
			end

			if not safeAtmCF then
				local openLotPos = targetPart.Position + Vector3.new(-14, 0, 10)
				local groundPos = getGroundPosition(openLotPos)
				safeAtmCF = CFrame.lookAt(groundPos, targetPart.Position)
			end

			safeTweenCar(safeAtmCF, 220)
			task.wait(0.5)

			-- 2. Take Koper from Bagasi on the ground
			if bagasi then
				safeTeleport(bagasi.CFrame + Vector3.new(0, 1, 0))
				task.wait(0.3)
				local ambilPrompt = bagasi:FindFirstChild("AmbilPrompt")
				triggerPrompt(ambilPrompt, 0.5)
			end

			task.wait(0.5)

			-- 3. Teleport character directly in front of ATM at ground level
			local atmFrontPos = getGroundPosition(targetPart.Position + targetPart.CFrame.LookVector * 2)
			safeTeleport(CFrame.new(atmFrontPos))
			task.wait(0.3)

			local isiPrompt = targetPart:FindFirstChild("IsiAtmPrompt") or targetPart.Parent:FindFirstChild("IsiAtmPrompt", true)
			triggerPrompt(isiPrompt)
			fireRemote("BankCourier", "FillStart")

			-- 4. Solve Skill Check
			local skill = jobGui and jobGui:FindFirstChild("Skill")
			local t0 = os.clock()
			while os.clock() - t0 < 5 do
				if skill and skill.Visible then
					fireRemote("BankCourier", "SkillPress", 180)
					if firesignal and skill:FindFirstChild("Key") then
						firesignal(skill.Key.Activated)
					end
					break
				end
				task.wait(0.05)
			end

			task.wait(1.5)
		end
	end

	local function runBcaCourierFarm()
		task.spawn(function()
			while bcaCourierActive do
				pcall(function()
					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					local jobGui = getBankCourierGui()

					-- STEP 1: Ensure Bank Courier Job is active
					if not jobGui or not jobGui.Status.Visible then
						safeTeleport(CFrame.new(bcaDepotPos))
						task.wait(0.5)
						fireRemote("Job", "BankCourier")
						task.wait(1)
						jobGui = getBankCourierGui()
					end

					local hintText = jobGui and jobGui.Status.Hint.Text or ""
					local koperText = jobGui and jobGui.Status.Koper.Text or ""
					local atmText = jobGui and jobGui.Status.Atm.Text or ""
					local stepText = jobGui and jobGui.Status.Step.Text or ""

					local curKoper, totKoper = parseProgress(koperText)
					local curAtm, totAtm = parseProgress(atmText)

					-- STEP 2: Ensure Bank Car is spawned via Putra NPC (NEVER touch suitcases before this!)
					local car = getPlayerCar()
					if not car or hintText:find("Keluarkan mobil") or hintText:find("petugas kendaraan") then
						car = spawnBankCar()
						task.wait(0.5)
						return
					end

					if not car then
						task.wait(1)
						return
					end

					-- STEP 3: Load Kopers into Car Trunk (ONLY while curKoper < totKoper)
					local isKoperFull = (totKoper > 0 and curKoper >= totKoper) or stepText:find("2)") or stepText:find("Antar")
					if not isKoperFull then
						loadKopersIntoCar(car)
						task.wait(0.5)
						return
					end

					-- STEP 4: Deliver to marked ATMs (ONLY when all kopers are loaded!)
					local isAtmDone = (totAtm > 0 and curAtm >= totAtm) or stepText:find("3)")
					if isKoperFull and not isAtmDone then
						local targetPart = workspace:FindFirstChild("__BankCourierTarget")
						if targetPart and (targetPart.Position - bcaDepotPos).Magnitude > 40 then
							deliverToAtms(car)
							task.wait(0.5)
							return
						end
					end

					-- STEP 5: Return to Depot & Claim Reward (When all ATMs are filled)
					if isAtmDone or stepText:find("3)") then
						safeTweenCar(CFrame.new(1774.5, 20.2, -4629.0) * CFrame.Angles(0, math.rad(-75), 0), 220)
						task.wait(0.5)
						fireRemote("BankCourier", "Complete")
						fireRemote("PhoneJobSalary")
						fireRemote("MyBcaAppOpened")
						task.wait(1.5)
					end
				end)
				task.wait(bcaCourierDelay)
			end
		end)
	end

	-- Background myBCA App auto-sync
	task.spawn(function()
		while true do
			if bcaAppSyncActive or bcaCourierActive then
				pcall(function()
					fireRemote("MyBcaAppOpened")
				end)
			end
			task.wait(25)
		end
	end)

	------------------------------------------------
	-- 🛣️ ODOMETER / HIGHWAY SPEED MILEAGE FARM
	------------------------------------------------
	local odometerActive = false
	local odoSpeed = Config.farm.odometerSpeed or 140

	local function runOdometerFarm()
		task.spawn(function()
			-- Highway points across CDID Jakarta map
			local ptA = CFrame.new(1200, 25, -2500)
			local ptB = CFrame.new(6500, 25, -7500)
			local target = ptA

			while odometerActive do
				pcall(function()
					local car = getPlayerCar()
					if car and car:FindFirstChild("DriveSeat") then
						-- Teleport vehicle across highway stretch
						target = (target == ptA) and ptB or ptA
						car:SetPrimaryPartCFrame(target)

						-- Fire odometer telemetry packet
						fireRemote("Odometer", 4500)
						fireRemote("DataReceiver", { RPM = 4500, Speed = odoSpeed })
					else
						-- Fire simulated RPM update
						fireRemote("Odometer", 3800)
					end
				end)
				task.wait(1.5)
			end
		end)
	end

	------------------------------------------------
	-- 🎁 AUTO CLAIM HOURLY BOX & DAILY REWARDS
	------------------------------------------------
	local autoClaimActive = true
	task.spawn(function()
		while true do
			if autoClaimActive then
				pcall(function()
					fireRemote("Box", "Claim")
					fireRemote("PhoneJobSalary")
				end)
			end
			task.wait(30)
		end
	end)

	------------------------------------------------
	-- 🎨 BUILD FARM TAB UI
	------------------------------------------------
	local farmFrame = UI.tabs["Farm"].Frame

	-- Quick Status Card
	local statusSec = UI.AddSection(farmFrame, "Automated Money Farm (CDID Jobs)", 1)
	UI.AddLabel(statusSec, "Select a job below. Script will automate pickups, deliveries, and rewards.")

	-- 🏦 BCA Collaboration Event & Bank Courier
	local bcaSec = UI.AddSection(farmFrame, "🏦 BCA Collaboration Event & Bank Courier", 2)
	UI.AddToggle(bcaSec, "Auto Farm Bank Courier (ATMs & Briefcases)", Config.farm.bcaCourier, function(v)
		bcaCourierActive = v
		Config.farm.bcaCourier = v
		if v then
			UI.Notify("BCA Courier Farm Active", "Automating money briefcases & 10 ATMs deliveries!", 3, "success")
			runBcaCourierFarm()
		else
			UI.Notify("BCA Courier Farm Stopped", "Bank courier paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	UI.AddSlider(bcaSec, "Delivery Delay (Seconds)", 0.5, 5.0, bcaCourierDelay, function(v)
		bcaCourierDelay = v
		Config.farm.bcaCourierDelay = v
	end, 2, "s")

	UI.AddToggle(bcaSec, "Auto Sync myBCA App (Pocket Rupiah)", Config.farm.bcaAppSync or true, function(v)
		bcaAppSyncActive = v
		Config.farm.bcaAppSync = v
		if v then
			fireRemote("MyBcaAppOpened")
			UI.Notify("myBCA Synced", "Synced Pocket Rupiah & NFC status!", 2, "success")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 3)

	UI.AddButton(bcaSec, "Spawn BCA Bank Armored Van", function()
		pcall(function()
			local remotes = ReplicatedStorage:FindFirstChild("NetworkContainer")
			if remotes and remotes:FindFirstChild("RemoteFunctions") and remotes.RemoteFunctions:FindFirstChild("Spawner") then
				remotes.RemoteFunctions.Spawner:InvokeServer("Spawn", "2025SemeruLarasBankCar")
				UI.Notify("BCA Van Spawned", "Spawned 2025 Semeru Laras Bank Car!", 3, "success")
			else
				UI.Notify("Spawn Failed", "Spawner remote unavailable.", 3, "warning")
			end
		end)
	end, 4)

	UI.AddButton(bcaSec, "Claim / Exchange BCA Event Rewards", function()
		pcall(function()
			local collab = workspace:FindFirstChild("MY_BCA_COLLAB")
			local exchangeNpc = collab and collab:FindFirstChild("NPC_EXCHANGE_REWARD")
			if exchangeNpc then
				local root = exchangeNpc:FindFirstChild("HumanoidRootPart") or exchangeNpc:FindFirstChildWhichIsA("BasePart")
				if root then
					safeTeleport(root.CFrame + Vector3.new(0, 3, 3))
				end
				for _, prompt in ipairs(exchangeNpc:GetDescendants()) do
					if prompt:IsA("ProximityPrompt") then
						prompt.HoldDuration = 0
						if fireproximityprompt then fireproximityprompt(prompt) end
					end
				end
				UI.Notify("Exchange Booth", "Teleported to BCA Reward Exchange Booth!", 3, "success")
			else
				safeTeleport(CFrame.new(bcaDepotPos))
				UI.Notify("Teleported", "Teleported to BCA Depot.", 3, "success")
			end
		end)
	end, 5)

	-- SiLambat Courier
	local siLambatSec = UI.AddSection(farmFrame, "📦 SiLambat Express Delivery", 3)
	UI.AddToggle(siLambatSec, "Auto Farm SiLambat", Config.farm.siLambat, function(v)
		siLambatActive = v
		Config.farm.siLambat = v
		if v then
			UI.Notify("SiLambat Farm Active", "Starting automated parcel deliveries.", 3, "success")
			runSiLambatFarm()
		else
			UI.Notify("SiLambat Farm Stopped", "Farming paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	UI.AddSlider(siLambatSec, "Delivery Delay (Seconds)", 0.5, 5.0, siLambatDelay, function(v)
		siLambatDelay = v
		Config.farm.siLambatDelay = v
	end, 2, "s")

	-- Janji Jiwa Coffee Delivery
	local jjSec = UI.AddSection(farmFrame, "☕ Janji Jiwa Coffee Delivery", 3)
	UI.AddToggle(jjSec, "Auto Farm Janji Jiwa", Config.farm.janjiJiwa, function(v)
		janjiJiwaActive = v
		Config.farm.janjiJiwa = v
		if v then
			UI.Notify("Janji Jiwa Farm Active", "Starting coffee deliveries.", 3, "success")
			runJanjiJiwaFarm()
		else
			UI.Notify("Janji Jiwa Farm Stopped", "Farming paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	UI.AddSlider(jjSec, "Coffee Delay (Seconds)", 0.5, 5.0, janjiJiwaDelay, function(v)
		janjiJiwaDelay = v
		Config.farm.janjiJiwaDelay = v
	end, 2, "s")

	-- EMS / Hospital Medic
	local emsSec = UI.AddSection(farmFrame, "🚑 EMS Doctor / Ambulance", 4)
	UI.AddToggle(emsSec, "Auto Farm EMS Ambulance", Config.farm.ems, function(v)
		emsActive = v
		Config.farm.ems = v
		if v then
			UI.Notify("EMS Farm Active", "Starting paramedic auto heal.", 3, "success")
			runEmsFarm()
		else
			UI.Notify("EMS Farm Stopped", "Farming paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	-- Odometer Mileage Farm
	local odoSec = UI.AddSection(farmFrame, "🛣️ Odometer & Highway Mileage Farm", 5)
	UI.AddToggle(odoSec, "Auto Farm Mileage / Odometer", Config.farm.odometer, function(v)
		odometerActive = v
		Config.farm.odometer = v
		if v then
			UI.Notify("Mileage Farm Active", "Earning passive cash from driving simulation.", 3, "success")
			runOdometerFarm()
		else
			UI.Notify("Mileage Farm Stopped", "Mileage farm paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 1)

	UI.AddSlider(odoSec, "Simulated Speed", 60, 250, odoSpeed, function(v)
		odoSpeed = v
		Config.farm.odometerSpeed = v
	end, 2, " km/h")

	-- Rewards & Claim Tools
	local claimSec = UI.AddSection(farmFrame, "🎁 Auto Claim Rewards", 6)
	UI.AddToggle(claimSec, "Auto Claim Hourly Box & Salary", true, function(v)
		autoClaimActive = v
	end, 1)

	UI.AddButton(claimSec, "Claim Hourly Reward Box Now", function()
		fireRemote("Box", "Claim")
		fireRemote("PhoneJobSalary")
		UI.Notify("Reward Claimed", "Attempted to claim free reward box & salary!", 2, "success")
	end, 2)

	-- Export global farm API
	_G.HipHubFarm = {
		SetSiLambat = function(v) siLambatActive = v end,
		SetJanjiJiwa = function(v) janjiJiwaActive = v end,
		SetEMS = function(v) emsActive = v end,
		SetOdometer = function(v) odometerActive = v end,
		ClaimRewards = function()
			fireRemote("Box", "Claim")
			fireRemote("PhoneJobSalary")
		end
	}
end)

if not success then
	warn("[HipHub CDID Farm Error]:", err)
end
