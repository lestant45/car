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

	local lastSafeGroundCFrame = CFrame.new(1866.5, 24, -4874.45)

	-- Spawns an invisible, anchored collision safety plate underneath destination so character & car never fall through unrendered chunks
	local function ensureSafetyPlate(pos, width)
		width = width or 50
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
		plate.CFrame = CFrame.new(pos.X, pos.Y - 1.2, pos.Z)
		return plate
	end

	-- Tells Roblox server in the background to prioritize streaming destination chunks without yielding
	local function requestStreamAsync(pos)
		pcall(function()
			if player and player.RequestStreamAroundAsync then
				task.spawn(function()
					pcall(function() player:RequestStreamAroundAsync(pos, 2) end)
				end)
			end
		end)
	end

	-- Safe Character Teleport Function with StreamingEnabled & Anti-Void Protection
	local function safeTeleport(cframe, useTween, speed)
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		-- 1. Ensure invisible safety plate exists at destination before teleporting
		ensureSafetyPlate(cframe.Position, 40)
		requestStreamAsync(cframe.Position)

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		if useTween then
			speed = speed or 120
			local dist = (root.Position - cframe.Position).Magnitude
			local time = math.clamp(dist / speed, 0.2, 3)
			local tw = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), { CFrame = cframe })
			tw:Play()
			tw.Completed:Wait()
		else
			root.CFrame = cframe
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		if cframe.Position.Y > 15 then
			lastSafeGroundCFrame = cframe
		end
	end

	-- Find player's vehicle
	local function getPlayerCar()
		local vehicles = workspace:FindFirstChild("Vehicles")
		if not vehicles then return nil end
		return vehicles:FindFirstChild(player.Name .. "sCar") or vehicles:FindFirstChild(player.Name .. "'s Car")
	end

	-- Universal Safe Ground CFrame Calculator with Streaming Protection
	local function getSafeGroundCFrame(targetPos, desiredAngle)
		requestStreamAsync(targetPos)
		ensureSafetyPlate(targetPos, 50)

		local rayParams = RaycastParams.new()
		local car = getPlayerCar()
		local char = player.Character
		rayParams.FilterDescendantsInstances = { car, char, workspace:FindFirstChild("__SafetyPlate") }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		-- Raycast downward from +14 studs above target
		local hit = workspace:Raycast(targetPos + Vector3.new(0, 14, 0), Vector3.new(0, -45, 0), rayParams)
		local groundY = hit and hit.Position.Y or targetPos.Y
		local safeY = groundY + 2.0 -- exact suspension clearance so tires touch road perfectly

		local rot = desiredAngle and CFrame.Angles(0, math.rad(desiredAngle), 0) or CFrame.new()
		return CFrame.new(targetPos.X, safeY, targetPos.Z) * rot
	end

	local function getGroundPosition(targetPos)
		local cf = getSafeGroundCFrame(targetPos)
		return cf.Position
	end

	-- Background Anti-Void Guardian: Rescues character immediately if falling through unrendered chunks
	task.spawn(function()
		while true do
			pcall(function()
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local humanoid = char and char:FindFirstChild("Humanoid")
				if root and humanoid and humanoid.Health > 0 then
					if root.Position.Y > 15 then
						lastSafeGroundCFrame = root.CFrame
					elseif root.Position.Y < 5 then
						-- Falling into the void! Instantly rescue to safe road!
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						local rescueCF = lastSafeGroundCFrame or CFrame.new(1866.5, 24, -4874.45)
						ensureSafetyPlate(rescueCF.Position, 60)
						root.CFrame = rescueCF + Vector3.new(0, 3, 0)
						local car = getPlayerCar()
						if car then
							car:PivotTo(rescueCF)
							for _, p in ipairs(car:GetDescendants()) do
								if p:IsA("BasePart") then
									p.AssemblyLinearVelocity = Vector3.zero
								end
							end
						end
					end
				end
			end)
			task.wait(0.1)
		end
	end)

	-- Teleport Player & Vehicle together safely directly on the ground
	local function safeTeleportCar(cframe)
		local safeCF = getSafeGroundCFrame(cframe.Position) * (cframe - cframe.Position)
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
		safeTeleport(safeCF + Vector3.new(0, 1.0, 3), false)
	end

	local function isInBankMinigame()
		local pgui = player:FindFirstChild("PlayerGui")
		local jobGui = pgui and pgui:FindFirstChild("Job") and pgui.Job:FindFirstChild("BankCourier")
		if not jobGui then return false end
		local timing = jobGui:FindFirstChild("Timing")
		local skill = jobGui:FindFirstChild("Skill")
		if (timing and timing.Visible) or (skill and skill.Visible) then
			return true
		end
		return false
	end

	-- Function to safely seat player in DriveSeat so client gets full Network Ownership for server replication
	local function enterDriveSeat(car)
		if not car or isInBankMinigame() then return false end
		local seat = car:FindFirstChild("DriveSeat")
		local char = player.Character
		if not seat or not char or not char:FindFirstChild("Humanoid") then return false end

		if char.Humanoid.Sit and char.Humanoid.SeatPart == seat then
			return true
		end

		pcall(function()
			char.HumanoidRootPart.CFrame = seat.CFrame + Vector3.new(0, 1.5, 0)
			seat:Sit(char.Humanoid)
		end)

		local t0 = os.clock()
		while (not char.Humanoid.Sit or char.Humanoid.SeatPart ~= seat) and os.clock() - t0 < 1.5 do
			task.wait(0.05)
		end

		return char.Humanoid.Sit and char.Humanoid.SeatPart == seat
	end

	-- Function to safely exit DriveSeat
	local function exitDriveSeat()
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Sit then
			char.Humanoid.Sit = false
			pcall(function()
				char.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
			task.wait(0.2)
		end
	end

	-- Smooth Tween Car & Player to Destination (Seated in DriveSeat for 100% Server Physics Replication)
	local function safeTweenCar(targetCF, speed)
		while isInBankMinigame() and bcaCourierActive do
			task.wait(0.2)
		end
		local car = getPlayerCar()
		if not car then
			safeTeleport(targetCF, true, speed)
			return
		end

		-- Ensure invisible safety platform is created and map chunks are streamed before moving
		ensureSafetyPlate(targetCF.Position, 55)
		requestStreamAsync(targetCF.Position)

		-- 1. Enter Driver Seat before moving to claim Network Ownership on the server
		enterDriveSeat(car)
		task.wait(0.2)

		local destCF = getSafeGroundCFrame(targetCF.Position) * (targetCF - targetCF.Position)
		local startCF = car:GetPivot()
		local dist = (startCF.Position - destCF.Position).Magnitude

		speed = speed or 180
		local duration = math.clamp(dist / speed, 0.5, 6.0)

		-- Zero out physics velocities before tween
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

		task.wait(0.25)

		-- 2. Exit Driver Seat now that vehicle has physically traveled to destination on server
		exitDriveSeat()
		task.wait(0.2)
		local bagasi = car:FindFirstChild("BagasiPoint")
		local exitPos = bagasi and (bagasi.CFrame + Vector3.new(0, 1.0, 0)) or (destCF + Vector3.new(0, 1.0, 3))
		safeTeleport(exitPos, false)
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
						local nearbyParts = workspace:GetPartBoundsInRadius(targetPos, 25)
						for _, p in ipairs(nearbyParts) do
							for _, prompt in ipairs(p:GetChildren()) do
								if prompt:IsA("ProximityPrompt") and prompt.Enabled then
									if prompt.ActionText:lower():find("deliver") or prompt.ObjectText:lower():find("package") or prompt.ActionText:lower():find("ambil") then
										if fireproximityprompt then fireproximityprompt(prompt, 0) end
									end
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
	local bcaCourierActive = Config.farm.bcaCourier or false
	local bcaCourierDelay = Config.farm.bcaCourierDelay or 1.0
	local bcaAppSyncActive = false
	local bcaDepotPos = Vector3.new(1866.502, 24, -4874.451)
	local bcaKoperPos = Vector3.new(1779.29, 21.5, -4643.79)

	local function getBankCourierGui()
		local pgui = player:FindFirstChild("PlayerGui")
		return pgui and pgui:FindFirstChild("Job") and pgui.Job:FindFirstChild("BankCourier")
	end

	local bcaCurKoper, bcaTotKoper = 0, 0
	local bcaCurAtm, bcaTotAtm = 0, 0
	local bcaIsCarrying = false
	local bcaJobPhase = ""
	local bcaJobComplete = false
	local bcaTargetEarning = tonumber(Config.farm.bcaTargetEarning) or 0
	local bcaTargetEarningLabel = nil

	local function parseRupiahNumber(str)
		if not str then return 0 end
		local cleaned = string.gsub(str, "[^%d]", "")
		return tonumber(cleaned) or 0
	end

	local function formatRupiah(num)
		local str = tostring(math.floor(num or 0))
		local formatted = str:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
		return "Rp. " .. formatted
	end

	local function getPocketRupiahCash()
		local pgui = player:FindFirstChild("PlayerGui")
		if not pgui then return 0 end
		local phone = pgui:FindFirstChild("ACTUAL NEW PHONE") or pgui:FindFirstChild("Phone")
		if not phone then return 0 end

		-- 1. Check PoketRupiah Accumulated & CashAmount
		local poketRupiah = phone:FindFirstChild("PoketRupiah", true)
		if poketRupiah then
			local acc = poketRupiah:FindFirstChild("Accumulated", true)
			if acc and acc:IsA("TextLabel") and acc.Text ~= "" then
				local val = parseRupiahNumber(acc.Text)
				if val > 0 then return val end
			end
			local cash = poketRupiah:FindFirstChild("CashAmount", true)
			if cash and cash:IsA("TextLabel") and cash.Text ~= "" then
				local val = parseRupiahNumber(cash.Text)
				if val > 0 then return val end
			end
		end

		-- 2. Check 3b_POCKETRUPIAH EventPocket Saldo
		local eventPocket = phone:FindFirstChild("EventPocket", true)
		if eventPocket then
			local saldo = eventPocket:FindFirstChild("Saldo", true)
			if saldo and saldo:IsA("TextLabel") and saldo.Text ~= "" then
				local val = parseRupiahNumber(saldo.Text)
				if val > 0 then return val end
			end
		end

		-- 3. Check any Accumulated label under Phone
		local accGlobal = phone:FindFirstChild("Accumulated", true)
		if accGlobal and accGlobal:IsA("TextLabel") and accGlobal.Text ~= "" then
			local val = parseRupiahNumber(accGlobal.Text)
			if val > 0 then return val end
		end

		return 0
	end

	local function checkTargetEarningAndDisconnect()
		if bcaTargetEarning and bcaTargetEarning > 0 then
			local targetCash = bcaTargetEarning * 1000000
			local currentCash = getPocketRupiahCash()
			if currentCash > 0 and currentCash >= targetCash then
				bcaCourierActive = false
				Config.farm.bcaCourier = false
				if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end

				local formattedTarget = formatRupiah(targetCash)
				local formattedCurrent = formatRupiah(currentCash)

				local kickMsg = string.format("DUIT LU UDAH NYENTUH %s\n(Saldo Poket: %s)", formattedTarget, formattedCurrent)
				updateBcaActivity("🛑 Target Earning Reached! Disconnecting...")
				UI.Notify("Target Earning Reached!", kickMsg, 5, "success")
				task.wait(1.5)
				player:Kick(kickMsg)
				return true
			end
		end
		return false
	end

	local function resetBcaState()
		bcaCurKoper = 0
		bcaTotKoper = 0
		bcaCurAtm = 0
		bcaTotAtm = 0
		bcaIsCarrying = false
		bcaJobPhase = ""
		bcaJobComplete = false
	end

	pcall(function()
		player.CharacterAdded:Connect(function()
			resetBcaState()
		end)
	end)

	local function updateBcaActivity(activity)
		currentBcaActivity = activity
		if bcaActivityLabel then
			bcaActivityLabel.Text = "📍 Action: " .. activity
		end
	end

	-- Hook BankCourier Remote to auto-solve ATM Skill Checks and track Koper state with 100% precision
	pcall(function()
		if Network and Network.OnClientEvent then
			Network.OnClientEvent("BankCourier", function(action, data, arg2, arg3, arg4)
				if not bcaCourierActive then return end

				if action == "Koper" then
					bcaCurKoper = tonumber(data) or 0
					bcaCurAtm = tonumber(arg2) or 0
					bcaTotAtm = tonumber(arg3) or 0
					bcaTotKoper = bcaTotAtm
					bcaIsCarrying = (arg4 == true)
					if bcaTotAtm > 0 and bcaCurAtm >= bcaTotAtm then
						bcaJobComplete = true
					end
				elseif action == "Phase" then
					bcaJobPhase = tostring(data)
					if bcaJobPhase == "Returning" then
						bcaJobComplete = true
					end
				elseif action == "Complete" then
					bcaJobComplete = true
				elseif action == "Start" then
					bcaJobComplete = false
					if typeof(data) == "table" then
						bcaTotKoper = data.totalKoper or 0
						bcaTotAtm = bcaTotKoper
					end
				elseif action == "SkillCheck" and typeof(data) == "table" then
					task.spawn(function()
						local warnLead = data.warnLead or 0.04
						local speed = data.speed or 360
						local zoneStart = data.zoneStart or 0
						local zoneSize = data.zoneSize or 40
						local greatSize = data.greatSize or (zoneSize / 2)
						local sweetAngle = (zoneStart + (greatSize / 2)) % 360

						-- Wait until the needle reaches the exact center of the Great zone
						local timeToSweet = (sweetAngle / speed)
						task.wait(warnLead + timeToSweet)

						-- Fire precision press once
						Network:FireServer("BankCourier", "SkillPress", sweetAngle)

						local jobGui = getBankCourierGui()
						local keyBtn = jobGui and jobGui:FindFirstChild("Skill") and jobGui.Skill:FindFirstChild("Key")
						if keyBtn and firesignal then
							firesignal(keyBtn.Activated)
							firesignal(keyBtn.MouseButton1Click)
						end
					end)
				elseif action == "LoadRound" and typeof(data) == "table" then
					task.spawn(function()
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
		if not prompt or not prompt.Enabled then return end
		local duration = (holdTime and holdTime > 0) and holdTime or (prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.15) or 0.15)
		local keyCode = prompt.KeyboardKeyCode or Enum.KeyCode.F

		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			vim:SendKeyEvent(true, keyCode, false, game)
			task.wait(duration)
			vim:SendKeyEvent(false, keyCode, false, game)
		end)

		pcall(function()
			if fireproximityprompt then
				fireproximityprompt(prompt, duration)
			elseif prompt.InputHoldBegin then
				prompt:InputHoldBegin()
				task.wait(duration)
				prompt:InputHoldEnd()
			end
		end)
	end

	-- Function to simulate screen clicks to skip dialogue typewriter text and auto-select choices (Yes / Claim / Finish)
	local function skipAndConfirmNpcDialog(timeout)
		timeout = timeout or 3.5
		local vim = game:GetService("VirtualInputManager")
		local cam = workspace.CurrentCamera
		local t0 = os.clock()

		while os.clock() - t0 < timeout do
			local pgui = player:FindFirstChild("PlayerGui")
			local dialog = pgui and pgui:FindFirstChild("NpcDialog")
			if dialog then
				local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
				local clickX = math.floor(vp.X / 2)
				local clickY = math.floor(vp.Y * 0.78)

				-- 1. Tap screen to skip dialogue typewriter animation
				pcall(function()
					vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
					task.wait(0.02)
					vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
				end)

				-- 2. Check for choices buttons (Yes / Claim / Finish / Spawn)
				local choices = dialog:FindFirstChild("Choices")
				local yesBtn = (choices and choices:FindFirstChild("Yes")) or dialog:FindFirstChild("Yes", true)
				if yesBtn and yesBtn.Visible then
					pcall(function()
						if firesignal then
							firesignal(yesBtn.Activated)
							firesignal(yesBtn.MouseButton1Click)
						end
						if getconnections then
							for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
							for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
						end
					end)
				end

				-- Check if dialog closed
				local textLabel = dialog:FindFirstChild("Text")
				if textLabel and not textLabel.Visible and not (choices and choices.Visible) then
					break
				end
			end
			task.wait(0.1)
		end
	end

	-- Background NPC Dialog Auto-Skipper: Taps screen whenever dialog is active
	task.spawn(function()
		local vim = game:GetService("VirtualInputManager")
		local cam = workspace.CurrentCamera
		while true do
			pcall(function()
				local pgui = player:FindFirstChild("PlayerGui")
				local dialog = pgui and pgui:FindFirstChild("NpcDialog")
				local textLabel = dialog and dialog:FindFirstChild("Text")
				local hintLabel = dialog and dialog:FindFirstChild("Hint")
				local choices = dialog and dialog:FindFirstChild("Choices")

				if dialog and ((textLabel and textLabel.Visible) or (hintLabel and hintLabel.Visible) or (choices and choices.Visible)) then
					local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
					local clickX = math.floor(vp.X / 2)
					local clickY = math.floor(vp.Y * 0.78)

					vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
					task.wait(0.02)
					vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)

					local yesBtn = (choices and choices:FindFirstChild("Yes")) or dialog:FindFirstChild("Yes", true)
					if yesBtn and yesBtn.Visible then
						if firesignal then
							firesignal(yesBtn.Activated)
							firesignal(yesBtn.MouseButton1Click)
						end
						if getconnections then
							for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
							for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
						end
					end
				end
			end)
			task.wait(0.15)
		end
	end)

	local function spawnBankCar()
		updateBcaActivity("🚶 Tweening to Putra NPC (200 studs/s)")
		local npc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("CAR_SPAWNER_NPC")
		local npcRoot = npc and npc:FindFirstChild("HumanoidRootPart")

		-- 1. Smooth tween right in front of Putra NPC at 200 studs/s
		if npcRoot then
			safeTeleport(npcRoot.CFrame + npcRoot.CFrame.LookVector * 3 + Vector3.new(0, 0.5, 0), true, 200)
		else
			safeTeleport(CFrame.new(bcaDepotPos), true, 200)
		end
		task.wait(0.4)

		-- 2. Trigger Putra Dialog Prompt
		if npc then
			local prompt = npc:FindFirstChild("DialogPrompt", true)
			triggerPrompt(prompt)
		end

		-- 3. Click screen to skip dialog text and confirm vehicle spawn
		updateBcaActivity("🚐 Spawning Armored Bank Van (Skipping Dialog)...")
		skipAndConfirmNpcDialog(3.5)

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

		-- 5. Sit in car and smoothly drive from NPC spawn point to the Koper driveway lane
		if car then
			updateBcaActivity("🚗 Cruising from Spawn to Koper Driveway (160 studs/s)")
			task.wait(1.5) -- Wait 1.5s after spawning before moving car
			local koperParkCFrame = getSafeGroundCFrame(Vector3.new(1780.0, 20.0, -4615.0), 20)
			safeTweenCar(koperParkCFrame, 160)
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

		car = car or getPlayerCar()

		-- Ensure car is parked right on the asphalt driveway
		local koperParkCFrame = getSafeGroundCFrame(Vector3.new(1780.0, 20.0, -4615.0), 20)
		if car and (car:GetPivot().Position - Vector3.new(1780.0, 22.0, -4615.0)).Magnitude > 25 then
			updateBcaActivity("🚗 Cruising from Spawn to Koper Driveway (160 studs/s)")
			task.wait(1.5)
			safeTweenCar(koperParkCFrame, 160)
			task.wait(0.5)
		end

		while bcaCourierActive do
			if checkTargetEarningAndDisconnect() then return end

			jobGui = getBankCourierGui()
			local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
			if not hasActiveJobGui then break end

			local koperText = jobGui.Status.Koper.Text or ""
			local stepText = jobGui.Status.Step.Text or ""
			local curKoper, totKoper = parseProgress(koperText)

			-- If already full or in step 2 (delivering), stop loading
			if (totKoper > 0 and curKoper >= totKoper) or stepText:find("2)") or stepText:find("Antar") then
				break
			end

			-- 1. Teleport to Koper Stack & Pickup
			updateBcaActivity(string.format("🧳 Grabbing Suitcase from Stack (%d/%d)", curKoper, totKoper))
			if koperPart then
				safeTeleport(koperPart.CFrame + Vector3.new(0, 1.2, 0))
				task.wait(0.3)
				local prompt = koperPart:FindFirstChild("Prompt", true) or koperPart:FindFirstChildWhichIsA("ProximityPrompt", true)
				triggerPrompt(prompt, 0.45)
			else
				safeTeleport(CFrame.new(bcaKoperPos))
			end

			task.wait(0.4)

			-- 2. Teleport to Car Bagasi & Trigger Muat
			updateBcaActivity("📦 Loading Suitcase into Trunk (Timing Minigame)")
			car = getPlayerCar() or car
			local bagasi = car and car:FindFirstChild("BagasiPoint")
			if bagasi then
				safeTeleport(bagasi.CFrame + Vector3.new(0, 1, 0))
				task.wait(0.3)
				local muatPrompt = bagasi:FindFirstChild("MuatPrompt") or bagasi:FindFirstChildWhichIsA("ProximityPrompt", true)
				triggerPrompt(muatPrompt, 0.35)
			end

			-- 3. Precise Timing Drop into Slot (matching Picture 2)
			timing = jobGui and jobGui:FindFirstChild("Timing")
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
							Network:FireServer("BankCourier", "LoadPress")
							break
						end
					end
					task.wait(0.02)
				end
			end

			task.wait(0.8)
		end
	end

	-- Safe Open Parking Spots for Vehicle (Clear sky, open asphalt, no pillars or ceilings)
	local ATM_PARKING_SPOTS = {
		["ATM1"] = Vector3.new(1860.0, 24.5, -4850.0),
		["ATM2"] = Vector3.new(2212.55, 27.5, -4594.36),
		["ATM3"] = Vector3.new(825.0, 24.2, -3810.0),
		["ATM4"] = Vector3.new(2291.25, 27.96, -4882.77),
		["ATM7"] = Vector3.new(-475.64, 26.27, 8732.79),
		["ATM8"] = Vector3.new(-223.75, 21.93, 10705.88),
		["ATM9"] = Vector3.new(1585.46, 51.14, 870.47),
		["ATM10"] = Vector3.new(2023.20, 21.44, -3538.69),
	}

	-- Exact Stand Positions for Character Directly in Front of ATM Screen (< 3 studs)
	local ATM_STAND_SPOTS = {
		["ATM1"] = Vector3.new(1860.0, 24.5, -4850.0),
		["ATM2"] = Vector3.new(2224.71, 29.29, -4596.95),
		["ATM3"] = Vector3.new(833.32, 24.23, -3825.72),
		["ATM4"] = Vector3.new(2291.25, 27.96, -4882.77),
		["ATM7"] = Vector3.new(-475.64, 26.27, 8732.79),
		["ATM8"] = Vector3.new(-223.75, 21.93, 10705.88),
		["ATM9"] = Vector3.new(1585.46, 51.14, 870.47),
		["ATM10"] = Vector3.new(1988.32, 24.44, -3531.15),
	}

	local function getBankCourierTargetPos()
		-- 1. Check BankCourierRoute Beam in workspace
		local route = workspace:FindFirstChild("BankCourierRoute")
		if route and route:FindFirstChild("To") then
			local pos = route.To.WorldPosition
			if pos and (pos - bcaDepotPos).Magnitude > 30 then
				return pos
			end
		end

		-- 2. Check __BankCourierTarget
		local targetPart = workspace:FindFirstChild("__BankCourierTarget")
		if targetPart and (targetPart.Position - bcaDepotPos).Magnitude > 30 then
			return targetPart.Position
		end

		-- 3. Check Waypoints
		local waypoints = workspace:FindFirstChild("Etc") and workspace.Etc:FindFirstChild("Waypoint")
		if waypoints and #waypoints:GetChildren() > 0 then
			for _, wp in ipairs(waypoints:GetChildren()) do
				if wp:IsA("BasePart") and (wp.Position - bcaDepotPos).Magnitude > 30 then
					return wp.Position
				end
			end
		end

		return nil
	end

	local function deliverToAtms(car)
		local jobGui = getBankCourierGui()
		local bagasi = car:FindFirstChild("BagasiPoint")

		while bcaCourierActive do
			if checkTargetEarningAndDisconnect() then return end

			local atmText = jobGui and jobGui.Status.Atm.Text or ""
			local stepText = jobGui and jobGui.Status.Step.Text or ""
			local curAtm, totAtm = parseProgress(atmText)

			-- If all ATMs filled, stop delivering
			if (totAtm > 0 and curAtm >= totAtm) or stepText:find("3)") or stepText:find("Selesai") then
				break
			end

			local targetPos = getBankCourierTargetPos()
			if not targetPos then
				local tWait = os.clock()
				while not targetPos and os.clock() - tWait < 6 and bcaCourierActive do
					task.wait(0.5)
					targetPos = getBankCourierTargetPos()
					local curA, totA = parseProgress(jobGui and jobGui.Status.Atm.Text or "")
					if bcaJobComplete or (totA > 0 and curA >= totA) then break end
				end
				if not targetPos then break end
			end

			-- 1. Match destination to designated safe open parking spot
			local safeAtmCF = nil
			local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
			if atms then
				for atmName, spotPos in pairs(ATM_PARKING_SPOTS) do
					local atm = atms:FindFirstChild(atmName)
					local p = atm and atm:FindFirstChildWhichIsA("BasePart", true)
					if (p and (p.Position - targetPos).Magnitude < 50) or (spotPos - targetPos).Magnitude < 80 then
						safeAtmCF = CFrame.new(spotPos)
						break
					end
				end
			end

			if not safeAtmCF then
				safeAtmCF = getSafeGroundCFrame(targetPos + Vector3.new(-12, 0, 10))
			end

			updateBcaActivity("🎯 Cruising to Destination ATM (180 studs/s)")
			safeTweenCar(safeAtmCF, 180)
			task.wait(1.5) -- Wait 1.5s after moving car near ATM before grabbing koper

			-- Check if game enforces an arrival cooldown (e.g. "TUNGGU 32s")
			local respawnBtn = jobGui and jobGui:FindFirstChild("Status") and jobGui.Status:FindFirstChild("RespawnCar")
			if respawnBtn and respawnBtn.Visible and respawnBtn.Text:find("TUNGGU") then
				local waitSeconds = tonumber(respawnBtn.Text:match("(%d+)"))
				if waitSeconds and waitSeconds > 0 then
					updateBcaActivity("⏳ Waiting Arrival Cooldown (" .. waitSeconds .. "s)")
					local t0 = os.clock()
					while os.clock() - t0 < (waitSeconds + 1) and bcaCourierActive do
						task.wait(1)
					end
				end
			end

			-- 2. Take Koper from Bagasi on the ground (Verify suitcase is in hand before proceeding)
			local function isCarryingKoper()
				local char = player.Character
				if not char then return false end
				if char:FindFirstChild("KoperUang") or char:FindFirstChildWhichIsA("Tool") then return true end
				if char:GetAttribute("BankCourierCarryAnim") ~= nil then return true end
				if player:GetAttribute("HidePrompt") == true then return true end
				return false
			end

			if bagasi then
				updateBcaActivity("✋ Taking Suitcase from Trunk (2s Hold)")
				local ambilPrompt = bagasi:FindFirstChild("AmbilPrompt")
				local t0 = os.clock()
				while not isCarryingKoper() and os.clock() - t0 < 8 and bcaCourierActive do
					-- Stand right next to the trunk (< 3 studs)
					safeTeleport(bagasi.CFrame + bagasi.CFrame.LookVector * -2 + Vector3.new(0, 1, 0))
					task.wait(0.2)

					if ambilPrompt and ambilPrompt.Enabled then
						triggerPrompt(ambilPrompt, ambilPrompt.HoldDuration)
					end

					-- Wait for server confirmation
					local tCheck = os.clock()
					while not isCarryingKoper() and os.clock() - tCheck < 1.5 do
						task.wait(0.1)
					end
				end
			end

			task.wait(0.5)

			-- 3. Teleport character directly in front of ATM Screen (< 3 studs away)
			local atmFrontPos = nil
			local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
			if atms then
				for _, atm in ipairs(atms:GetChildren()) do
					local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
					local screen = atm:FindFirstChild("Screen_ATM_01", true) or (prompt and prompt.Parent) or atm:FindFirstChildWhichIsA("BasePart", true)
					if screen and (screen.Position - targetPos).Magnitude < 100 then
						atmFrontPos = screen.Position + screen.CFrame.LookVector * 2.5
						break
					end
				end
			end

			if not atmFrontPos then
				for atmName, standPos in pairs(ATM_STAND_SPOTS) do
					if (standPos - targetPos).Magnitude < 90 then
						atmFrontPos = standPos
						break
					end
				end
			end

			if not atmFrontPos then
				atmFrontPos = getGroundPosition(targetPos)
			end

			updateBcaActivity("🏧 Stepping in Front of ATM Machine")
			safeTeleport(CFrame.new(atmFrontPos))
			task.wait(0.4)

			local nearbyParts = workspace:GetPartBoundsInRadius(atmFrontPos, 25)
			for _, p in ipairs(nearbyParts) do
				for _, prompt in ipairs(p:GetChildren()) do
					if prompt:IsA("ProximityPrompt") and prompt.Enabled and (prompt.ActionText:lower():find("isi") or prompt.ObjectText:lower():find("atm") or prompt.Name:find("Isi")) then
						triggerPrompt(prompt, prompt.HoldDuration)
					end
				end
			end
			updateBcaActivity("⚡ Filling ATM Machine (Skill Check Rounds)")
			fireRemote("BankCourier", "FillStart")

			-- 4. Wait for all 3 Skill Check rounds to complete (Strictly do not interrupt while minigame is open!)
			local skill = jobGui and jobGui:FindFirstChild("Skill")
			local tOpen = os.clock()
			while (not skill or not skill.Visible) and os.clock() - tOpen < 2.5 and bcaCourierActive do
				skill = jobGui and jobGui:FindFirstChild("Skill")
				task.wait(0.1)
			end

			local tSolve = os.clock()
			while (skill and skill.Visible) and os.clock() - tSolve < 20 and bcaCourierActive do
				task.wait(0.2)
			end

			task.wait(1.2)

			-- Check if all assigned ATMs are filled (e.g. 2/2, 3/3, 4/4) or Step 3 reached
			jobGui = getBankCourierGui()
			local curA, totA = parseProgress(jobGui and jobGui.Status.Atm.Text or "")
			local stepT = jobGui and jobGui.Status.Step.Text or ""
			if (totA > 0 and curA >= totA) or bcaJobComplete or stepT:find("3)") or stepT:find("Kembali") or stepT:find("Selesai") then
				bcaJobComplete = true
				break
			end
		end
	end

	local function runBcaCourierFarm()
		task.spawn(function()
			while bcaCourierActive do
				pcall(function()
					-- If in minigame, DO ABSOLUTELY NOTHING and wait for minigame to finish
					while isInBankMinigame() and bcaCourierActive do
						task.wait(0.2)
					end

					local char = player.Character
					if not char or not char:FindFirstChild("HumanoidRootPart") then
						task.wait(1)
						return
					end

					if checkTargetEarningAndDisconnect() then return end

					local jobGui = getBankCourierGui()
					local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
					if not hasActiveJobGui then
						resetBcaState()
					end

					local hintText = hasActiveJobGui and jobGui.Status.Hint.Text or ""
					local koperText = hasActiveJobGui and jobGui.Status.Koper.Text or ""
					local atmText = hasActiveJobGui and jobGui.Status.Atm.Text or ""
					local stepText = hasActiveJobGui and jobGui.Status.Step.Text or ""

					local curKoper, totKoper = parseProgress(koperText)
					local curAtm, totAtm = parseProgress(atmText)

					-- STEP 1: Ensure Bank Courier Job is active (ONLY when starting completely fresh)
					if not hasActiveJobGui then
						updateBcaActivity("🚶 Tweening to Andhini NPC (200 studs/s)")
						local andhiniPos = Vector3.new(1807.269, 23.362, -4635.745)
						safeTeleport(CFrame.new(andhiniPos + Vector3.new(0, 0, 3)), true, 200)
						task.wait(0.5)

						local andhiniNpc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("NPC_START_JOB")
						local andhiniPrompt = andhiniNpc and andhiniNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
						if andhiniPrompt then
							triggerPrompt(andhiniPrompt, 0.2)
						end

						skipAndConfirmNpcDialog(3.0)

						fireRemote("Job", "BankCourier")
						fireRemote("NpcDialog", "Finish", 1)
						fireRemote("NpcDialog", "Finish", "BankCourier")
						task.wait(1.5)
						jobGui = getBankCourierGui()
						hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
						if not hasActiveJobGui then return end
					end

					-- STEP 5: Return to Depot & Approach Andhini NPC to Claim Salary (PRIORITY #1 when all ATMs are filled / GAJIAN!)
					local isAtmDone = bcaJobComplete
						or (totAtm > 0 and curAtm >= totAtm)
						or stepText:find("3)")
						or stepText:find("Kembali")
						or stepText:find("GAJIAN")
						or stepText:find("gaji")
						or hintText:find("terima gaji")
						or hintText:find("Andhini")

					if isAtmDone then
						updateBcaActivity("🏁 Cruising Back to BCA Depot (180 studs/s)")
						safeTweenCar(getSafeGroundCFrame(Vector3.new(1780.0, 20.0, -4615.0), 20), 180)
						task.wait(0.5)

						-- Walk/Tween inside lobby to approach Andhini (Koordinator Kurir BCA) at 200 studs/s
						updateBcaActivity("🚶 Tweening to Andhini NPC (200 studs/s)")
						local andhiniPos = Vector3.new(1807.269, 23.362, -4635.745)
						safeTeleport(CFrame.new(andhiniPos + Vector3.new(0, 0, 3)), true, 200)
						task.wait(0.5)

						-- Trigger Andhini's DialogPrompt
						updateBcaActivity("💰 Speaking to Andhini & Claiming Salary")
						local andhiniNpc = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("NPC_START_JOB")
						local andhiniPrompt = andhiniNpc and andhiniNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
						if andhiniPrompt then
							triggerPrompt(andhiniPrompt, 0.2)
						end

						-- Tap screen to skip dialog text and confirm salary payout
						skipAndConfirmNpcDialog(4.0)

						fireRemote("NpcDialog", "Finish", 1)
						fireRemote("NpcDialog", "Finish", "BankCourier")
						fireRemote("BankCourier", "Complete")
						fireRemote("PhoneJobSalary")
						fireRemote("MyBcaAppOpened")
						resetBcaState()
						updateBcaActivity("🎉 Contract Completed! Salary Claimed")
						task.wait(1.5)
						if checkTargetEarningAndDisconnect() then return end
						task.wait(1.5)
						return
					end

					-- STEP 2: Ensure Bank Car is spawned via Putra NPC
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

					-- STEP 3: Load Kopers into Car Trunk (ONLY when in Step 1: Angkut koper uang)
					local isKoperFull = (totKoper > 0 and curKoper >= totKoper) or stepText:find("2)") or stepText:find("Antar")
					if not isKoperFull and (stepText:find("1)") or stepText:find("Angkut") or hintText:find("tumpukan")) then
						loadKopersIntoCar(car)
						task.wait(0.5)
						return
					end

					-- STEP 4: Deliver to marked ATMs (When in Step 2: Antar uang ke ATM)
					if (stepText:find("2)") or stepText:find("Antar") or isKoperFull) and not isAtmDone then
						deliverToAtms(car)
						task.wait(0.5)
						return
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

	-- Real-Time Status & Live Stats Display
	bcaActivityLabel = UI.AddLabel(bcaSec, "📍 Action: Idle (Toggle Auto Farm to start)", 1, UI.COLORS.accentCyan)
	bcaProgressLabel = UI.AddLabel(bcaSec, "📦 Van Kopers: 0/0  |  🏧 ATMs Filled: 0/0", 2, UI.COLORS.textSecondary)
	bcaTargetLabel = UI.AddLabel(bcaSec, "🎯 Target: Standby / None", 3, UI.COLORS.textMuted)
	bcaSalaryLabel = UI.AddLabel(bcaSec, "💵 Est. Salary: Rp 0  |  Pocket: Rp 0", 4, UI.COLORS.successGreen)
	bcaTargetEarningLabel = UI.AddLabel(bcaSec, "🎯 Target Earning: Disabled  |  Live Poket: Rp 0", 5, UI.COLORS.accentViolet)

	-- Live Stats Auto-Updater Task
	task.spawn(function()
		while true do
			pcall(function()
				local jobGui = getBankCourierGui()
				local hasActiveJobGui = (jobGui and jobGui:FindFirstChild("Status") and jobGui.Status.Visible == true)
				local kText = hasActiveJobGui and jobGui.Status.Koper.Text or ""
				local aText = hasActiveJobGui and jobGui.Status.Atm.Text or ""
				local sText = hasActiveJobGui and jobGui.Status.Salary.Text or ""
				local pText = hasActiveJobGui and jobGui.Status:FindFirstChild("Pocket") and jobGui.Status.Pocket.Text or ""
				local curK, totK = parseProgress(kText)
				local curA, totA = parseProgress(aText)

				local livePocket = getPocketRupiahCash()
				if bcaTargetEarningLabel then
					if bcaTargetEarning > 0 then
						local targetCash = bcaTargetEarning * 1000000
						local pct = math.clamp(math.floor((livePocket / targetCash) * 100), 0, 100)
						bcaTargetEarningLabel.Text = string.format("🎯 Target: %s  |  Live Poket: %s (%d%%)", formatRupiah(targetCash), formatRupiah(livePocket), pct)
					else
						bcaTargetEarningLabel.Text = string.format("🎯 Target: Disabled  |  Live Poket: %s", formatRupiah(livePocket))
					end
				end

				-- Real-time auto-disconnect when target earning is reached
				if bcaCourierActive and checkTargetEarningAndDisconnect() then
					return
				end

				if bcaCourierActive then
					if bcaActivityLabel then
						bcaActivityLabel.Text = "📍 Action: " .. currentBcaActivity
					end

					if bcaProgressLabel then
						bcaProgressLabel.Text = string.format("📦 Van Kopers: %d/%d  |  🏧 ATMs Filled: %d/%d", curK, totK, curA, totA)
					end

					if bcaTargetLabel then
						local targetPos = getBankCourierTargetPos()
						if targetPos and hasActiveJobGui then
							local char = player.Character
							local root = char and char:FindFirstChild("HumanoidRootPart")
							local dist = root and math.floor((root.Position - targetPos).Magnitude) or 0
							local matchedAtm = "Destination ATM"
							local atms = workspace:FindFirstChild("MY_BCA_COLLAB") and workspace.MY_BCA_COLLAB:FindFirstChild("Job") and workspace.MY_BCA_COLLAB.Job:FindFirstChild("BankCourier") and workspace.MY_BCA_COLLAB.Job.BankCourier:FindFirstChild("ATMs")
							if atms then
								for atmName, spotPos in pairs(ATM_PARKING_SPOTS) do
									if (spotPos - targetPos).Magnitude < 80 then
										matchedAtm = atmName
										break
									end
								end
							end
							bcaTargetLabel.Text = string.format("🎯 Target: %s (%dm away)", matchedAtm, dist)
						else
							bcaTargetLabel.Text = hasActiveJobGui and "🎯 Target: Standby / Generating Route" or "🎯 Target: None (Starting Job...)"
						end
					end

					if bcaSalaryLabel and sText ~= "" then
						bcaSalaryLabel.Text = string.format("💵 %s %s", sText, (pText ~= "" and (" | " .. pText) or ""))
					end
				else
					if bcaActivityLabel then
						bcaActivityLabel.Text = "📍 Action: Idle (Toggle Auto Farm to start)"
					end
				end
			end)
			task.wait(0.5)
		end
	end)

	UI.AddToggle(bcaSec, "Auto Farm Bank Courier (ATMs & Briefcases)", Config.farm.bcaCourier, function(v)
		bcaCourierActive = v
		Config.farm.bcaCourier = v
		if v then
			UI.Notify("BCA Courier Farm Active", "Automating money briefcases & 10 ATMs deliveries!", 3, "success")
			runBcaCourierFarm()
		else
			updateBcaActivity("Paused (Toggle off)")
			UI.Notify("BCA Courier Farm Stopped", "Bank courier paused.", 2, "warning")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 5)

	UI.AddSlider(bcaSec, "Delivery Delay (Seconds)", 0.5, 5.0, bcaCourierDelay, function(v)
		bcaCourierDelay = v
		Config.farm.bcaCourierDelay = v
	end, 6, "s")

	UI.AddTextbox(bcaSec, "Target Earning (Million IDR)", tostring(bcaTargetEarning or 0), function(val)
		local num = tonumber(val) or 0
		bcaTargetEarning = num
		Config.farm.bcaTargetEarning = num
		if num > 0 then
			local fullIdr = num * 1000000
			UI.Notify("Target Earning Set", string.format("Target: %s (%d Juta). Will disconnect when reached!", formatRupiah(fullIdr), num), 3, "success")
			checkTargetEarningAndDisconnect()
		else
			UI.Notify("Target Earning Disabled", "No earning limit set (runs continuously).", 2, "info")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 7)

	UI.AddLabel(bcaSec, "💡 Type in millions: 1 = Rp 1.000.000, 10 = Rp 10.000.000, 68 = Rp 68.000.000 (0 = No limit)", 8, UI.COLORS.textMuted)

	UI.AddToggle(bcaSec, "Auto Sync myBCA App (Pocket Rupiah)", Config.farm.bcaAppSync or true, function(v)
		bcaAppSyncActive = v
		Config.farm.bcaAppSync = v
		if v then
			fireRemote("MyBcaAppOpened")
			UI.Notify("myBCA Synced", "Synced Pocket Rupiah & NFC status!", 2, "success")
		end
		if _G.HipHubSaveConfig then _G.HipHubSaveConfig() end
	end, 7)

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
	end, 8)

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

	-- Launch BCA Courier thread immediately if enabled in saved config
	if bcaCourierActive then
		runBcaCourierFarm()
	end

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
