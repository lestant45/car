-- 🧠 HipHub BXI — Main Window Controller & Character Modifications
-- Bus X Indonesia (Place ID: 137806249434874)
-- Handles Character Physics, Flight, Noclip, Window Controls & Hotkeys

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Main"].content
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local VirtualUser = game:GetService("VirtualUser")
	local player = Players.LocalPlayer

	local mainFrame = UI.mainFrame
	local topBar = UI.topBar
	local closeButton = UI.closeButton
	local minimizeButton = UI.minimizeButton
	local fullscreenButton = UI.fullscreenButton
	local syncShadow = UI.SyncShadow

	local Config = _G.HipHubConfig and _G.HipHubConfig.main or {
		walkSpeed = 16,
		jumpPower = 50,
		flySpeed = 60,
		noclip = false,
		infiniteStamina = false,
		antiAfk = true,
		hideNametag = false
	}

	------------------------------------------------
	-- 🖼️ WINDOW DRAGGING & CONTROLS
	------------------------------------------------
	local dragging, dragInput, dragStart, startPos
	local isFullscreen = false
	local isMinimized = false
	local origPos = mainFrame.Position
	local origSize = mainFrame.Size

	local function update(input)
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		syncShadow()
	end

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not isFullscreen then
				dragging = true
				dragStart = input.Position
				startPos = mainFrame.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)

	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			if UI.contentArea then UI.contentArea.Visible = false end
			if UI.sidebar then UI.sidebar.Visible = false end
			TweenService:Create(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 44) }):Play()
		else
			local tw = TweenService:Create(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = origSize })
			tw.Completed:Connect(function()
				if UI.contentArea then UI.contentArea.Visible = true end
				if UI.sidebar then UI.sidebar.Visible = true end
			end)
			tw:Play()
		end
		task.delay(0.24, syncShadow)
	end)

	fullscreenButton.MouseButton1Click:Connect(function()
		isFullscreen = not isFullscreen
		if isFullscreen then
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, -450, 0.5, -300),
				Size = UDim2.new(0, 900, 0, 600)
			}):Play()
		else
			TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = origPos,
				Size = origSize
			}):Play()
		end
		task.delay(0.26, syncShadow)
	end)

	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		UI.shadowFrame.Visible = false
		UI.Notify("HipHub BXI Hidden", "Press [Right Shift] to toggle menu.", 3, "success")
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			mainFrame.Visible = not mainFrame.Visible
			UI.shadowFrame.Visible = mainFrame.Visible
			if mainFrame.Visible then
				syncShadow()
			end
		end
	end)

	------------------------------------------------
	-- 🛡️ ANTI-AFK SYSTEM
	------------------------------------------------
	player.Idled:Connect(function()
		if Config.antiAfk then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end
	end)

	------------------------------------------------
	-- 🏃 CHARACTER MODIFICATIONS
	------------------------------------------------
	local customSpeed = 16
	local customJump = 50
	local noclipActive = false
	local flyActive = false
	local flySpeed = 60
	local noclipConn = nil
	local flyConn = nil

	local function getHumanoid()
		local char = player.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	RunService.Heartbeat:Connect(function()
		local hum = getHumanoid()
		if hum then
			if customSpeed > 16 then
				hum.WalkSpeed = customSpeed
			end
			if customJump > 50 then
				hum.JumpPower = customJump
			end
		end
	end)

	local function toggleNoclip(state)
		noclipActive = state
		Config.noclip = state
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end

		if state then
			noclipConn = RunService.Stepped:Connect(function()
				local char = player.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					local root = char:FindFirstChild("HumanoidRootPart")
					local isSeated = hum and hum.SeatPart ~= nil

					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("BasePart") then
							v.CanCollide = false
						end
					end

					if isSeated and hum and hum.SeatPart and hum.Sit == false then
						hum.Sit = true
					end

					-- Anti-Void protection for on-foot Noclip
					if not isSeated and not flyActive and root then
						local rayParams = RaycastParams.new()
						rayParams.FilterDescendantsInstances = { char }
						rayParams.FilterType = Enum.RaycastFilterType.Exclude
						local hit = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -6, 0), rayParams)
						if hit and root.AssemblyLinearVelocity.Y < -5 then
							root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
							root.CFrame = CFrame.new(root.Position.X, hit.Position.Y + 3.0, root.Position.Z) * (root.CFrame - root.Position)
						end
					end
				end
			end)
			UI.Notify("Noclip Active", "You can now walk through obstacles.", 2, "success")
		else
			UI.Notify("Noclip Disabled", "Collision restored.", 2, "warning")
		end
	end

	local function toggleFly(state)
		flyActive = state
		if flyConn then
			flyConn:Disconnect()
			flyConn = nil
		end

		if state then
			flyConn = RunService.RenderStepped:Connect(function()
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not (root and hum) then return end

				local cam = workspace.CurrentCamera
				local moveDir = Vector3.zero

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + cam.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - cam.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - cam.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + cam.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDir = moveDir + Vector3.new(0, 1, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					moveDir = moveDir - Vector3.new(0, 1, 0)
				end

				if moveDir.Magnitude > 0 then
					root.AssemblyLinearVelocity = moveDir.Unit * flySpeed
				else
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end)
			UI.Notify("Flight Active", "Fly with WASD + Space/Ctrl.", 2, "success")
		else
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				root.AssemblyLinearVelocity = Vector3.zero
			end
			UI.Notify("Flight Disabled", "Physics restored.", 2, "warning")
		end
	end

	------------------------------------------------
	-- 📋 MAIN UI BUILDER
	------------------------------------------------

	-- 1. Character Physics
	UI.AddSection(tab, "Character Movement & Speeds")

	UI.AddSlider(tab, "WalkSpeed Multiplier", 16, 150, 16, function(val)
		customSpeed = val
		local hum = getHumanoid()
		if hum then hum.WalkSpeed = val end
	end, "studs/s")

	UI.AddSlider(tab, "JumpPower Multiplier", 50, 200, 50, function(val)
		customJump = val
		local hum = getHumanoid()
		if hum then hum.JumpPower = val end
	end, "")

	-- 2. Movement Exploits
	UI.AddSection(tab, "Flight & Collision Controls")

	UI.AddToggle(tab, "Noclip (Walk Through Walls)", false, function(state)
		toggleNoclip(state)
	end)

	UI.AddToggle(tab, "Character Fly Mode", false, function(state)
		toggleFly(state)
	end)

	UI.AddSlider(tab, "Character Fly Speed", 20, 200, 60, function(val)
		flySpeed = val
	end, "studs/s")

	-- 3. Utility Actions
	UI.AddSection(tab, "Player Utilities")

	UI.AddButton(tab, "☠️ Reset Character", function()
		local hum = getHumanoid()
		if hum then hum.Health = 0 end
		UI.Notify("Character Reset", "Character respawning...", 2, "warning")
	end, "danger")

	UI.AddButton(tab, "🔄 Rejoin Game", function()
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end, "warning")
end)

if not success then
	warn("[HipHub BXI Main Controller Error]:", err)
end
