-- 🧠 CAB & HipHub CDID — Main Window Controller & Character Mods
-- Handles Character Physics, Anti-AFK, Flight, Noclip, Prompts, Server Utilities, and Window Controls

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Config = _G.HipHubConfig or { main = {} }
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local TeleportService = game:GetService("TeleportService")
	local VirtualUser = game:GetService("VirtualUser")
	local player = Players.LocalPlayer

	local mainFrame = UI.mainFrame
	local topBar = UI.topBar
	local closeButton = UI.closeButton
	local minimizeButton = UI.minimizeButton
	local fullscreenButton = UI.fullscreenButton
	local syncShadow = UI.SyncShadow

	------------------------------------------------
	-- 🖼️ WINDOW DRAGGING FUNCTIONALITY
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

	-- Minimize & Close
	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			UI.contentArea.Visible = false
			mainFrame:FindFirstChild("Sidebar", true).Visible = false
			TweenService:Create(mainFrame, TweenInfo.new(0.25), { Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 42) }):Play()
		else
			local tw = TweenService:Create(mainFrame, TweenInfo.new(0.25), { Size = origSize })
			tw.Completed:Connect(function()
				UI.contentArea.Visible = true
				mainFrame:FindFirstChild("Sidebar", true).Visible = true
			end)
			tw:Play()
		end
		task.delay(0.26, syncShadow)
	end)

	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		UI.shadowFrame.Visible = false
		UI.Notify("HipHub CDID Hidden", "Press [Right Shift] to show the menu again.", 3, "success")
	end)

	------------------------------------------------
	-- 🏃 CHARACTER MODIFICATIONS
	------------------------------------------------
	local walkSpeed = Config.main.walkSpeed or 16
	local jumpPower = Config.main.jumpPower or 50
	local infStamina = Config.main.infiniteStamina or false
	local noclipActive = Config.main.noclip or false
	local flyActive = Config.main.fly or false
	local flySpeed = Config.main.flySpeed or 50
	local infJump = false
	local antiRagdoll = Config.main.antiRagdoll or true
	local instantPrompt = Config.main.instantPrompt or false

	RunService.RenderStepped:Connect(function()
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then
			local hum = char.Humanoid
			if walkSpeed > 16 then hum.WalkSpeed = walkSpeed end
			if jumpPower > 50 then hum.JumpPower = jumpPower end
			if antiRagdoll and hum.PlatformStand then hum.PlatformStand = false end
		end
	end)

	-- Infinite Stamina
	task.spawn(function()
		while true do
			if infStamina then
				pcall(function()
					local stamina = player.Character and (player.Character:FindFirstChild("Stamina") or player.Character:FindFirstChild("Energy"))
					if stamina and stamina:IsA("NumberValue") then
						stamina.Value = 100
					end
				end)
			end
			task.wait(1)
		end
	end)

	-- Character Noclip
	RunService.Stepped:Connect(function()
		if noclipActive and player.Character then
			for _, part in pairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)

	-- Infinite Jump
	UserInputService.JumpRequest:Connect(function()
		if infJump and player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	-- Character Fly
	local charBv, charBg
	local function toggleCharFly(enable)
		flyActive = enable
		local char = player.Character
		if not enable then
			if charBv then charBv:Destroy(); charBv = nil end
			if charBg then charBg:Destroy(); charBg = nil end
			return
		end

		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local root = char.HumanoidRootPart

		charBv = Instance.new("BodyVelocity")
		charBv.Velocity = Vector3.zero
		charBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		charBv.Parent = root

		charBg = Instance.new("BodyGyro")
		charBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		charBg.P = 9000
		charBg.CFrame = root.CFrame
		charBg.Parent = root

		task.spawn(function()
			local cam = workspace.CurrentCamera
			while flyActive and char and char.Parent and root and root.Parent do
				local moveDir = Vector3.zero
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

				if charBv and charBg then
					charBv.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * flySpeed) or Vector3.zero
					charBg.CFrame = cam.CFrame
				end
				RunService.RenderStepped:Wait()
			end
			if charBv then charBv:Destroy(); charBv = nil end
			if charBg then charBg:Destroy(); charBg = nil end
		end)
	end

	-- Instant Proximity Prompts (Event-driven instant trigger without heavy workspace scanning or HoldDuration mutation)
	local ProximityPromptService = game:GetService("ProximityPromptService")
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		if instantPrompt and prompt and prompt.Enabled then
			pcall(function()
				if fireproximityprompt then
					fireproximityprompt(prompt, 0)
				end
			end)
		end
	end)

	-- Anti-AFK
	player.Idled:Connect(function()
		if Config.main.antiAfk then
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.zero)
		end
	end)

	------------------------------------------------
	-- 🎨 BUILD MAIN TAB UI
	------------------------------------------------
	local mFrame = UI.tabs["Main"].Frame

	-- Welcome Banner Card
	local wlCard = Instance.new("Frame")
	wlCard.Size = UDim2.new(1, 0, 0, 68)
	wlCard.BackgroundColor3 = UI.COLORS.glassCard
	wlCard.BackgroundTransparency = UI.TRANSPARENCY.glassCard
	wlCard.BorderSizePixel = 0
	wlCard.LayoutOrder = 1
	wlCard.Parent = mFrame

	local wlCorner = Instance.new("UICorner")
	wlCorner.CornerRadius = UI.CORNER.medium
	wlCorner.Parent = wlCard

	local wlStroke = Instance.new("UIStroke")
	wlStroke.Color = UI.COLORS.borderGlass
	wlStroke.Thickness = 1
	wlStroke.Transparency = 0.7
	wlStroke.Parent = wlCard

	local wlTitle = Instance.new("TextLabel")
	wlTitle.Size = UDim2.new(1, -20, 0, 24)
	wlTitle.Position = UDim2.new(0, 12, 0, 8)
	wlTitle.BackgroundTransparency = 1
	wlTitle.Text = "Welcome to HipHub CDID, " .. player.DisplayName .. "!"
	wlTitle.TextColor3 = UI.COLORS.textWhite
	wlTitle.Font = Enum.Font.GothamBold
	wlTitle.TextSize = 13
	wlTitle.TextXAlignment = Enum.TextXAlignment.Left
	wlTitle.Parent = wlCard

	local wlDesc = Instance.new("TextLabel")
	wlDesc.Size = UDim2.new(1, -20, 0, 26)
	wlDesc.Position = UDim2.new(0, 12, 0, 32)
	wlDesc.BackgroundTransparency = 1
	wlDesc.Text = "Fully loaded: Auto Farm, Vehicle Tuning, Teleports, ESP, and Character Enhancements."
	wlDesc.TextColor3 = UI.COLORS.textSecondary
	wlDesc.Font = Enum.Font.Gotham
	wlDesc.TextSize = 10
	wlDesc.TextXAlignment = Enum.TextXAlignment.Left
	wlDesc.TextWrapped = true
	wlDesc.Parent = wlCard

	-- Character Physics Section
	local charSec = UI.AddSection(mFrame, "🏃 Character Modifications", 2)

	UI.AddSlider(charSec, "WalkSpeed Modifier", 16, 150, walkSpeed, function(v)
		walkSpeed = v
		Config.main.walkSpeed = v
	end, 1, " studs/s")

	UI.AddSlider(charSec, "JumpPower Modifier", 50, 250, jumpPower, function(v)
		jumpPower = v
		Config.main.jumpPower = v
	end, 2, " studs/s")

	UI.AddToggle(charSec, "Infinite Stamina", infStamina, function(v)
		infStamina = v
		Config.main.infiniteStamina = v
	end, 3)

	UI.AddToggle(charSec, "Character Noclip (Pass through walls)", noclipActive, function(v)
		noclipActive = v
		Config.main.noclip = v
	end, 4)

	UI.AddToggle(charSec, "Infinite Jump (Jump mid-air)", infJump, function(v)
		infJump = v
	end, 5)

	-- Flight & Utility
	local flySec = UI.AddSection(mFrame, "🕊️ Flight & Character Utilities", 3)

	UI.AddToggle(flySec, "Character Fly", flyActive, function(v)
		toggleCharFly(v)
		Config.main.fly = v
	end, 1)

	UI.AddSlider(flySec, "Flight Speed", 20, 150, flySpeed, function(v)
		flySpeed = v
		Config.main.flySpeed = v
	end, 2, " studs/s")

	UI.AddToggle(flySec, "Instant Proximity Prompts (0s Hold)", instantPrompt, function(v)
		instantPrompt = v
		Config.main.instantPrompt = v
	end, 3)

	UI.AddToggle(flySec, "Anti-AFK (Prevent 20min kick)", Config.main.antiAfk, function(v)
		Config.main.antiAfk = v
	end, 4)

	-- Server & Position Tools
	local srvSec = UI.AddSection(mFrame, "🌐 Server Utilities & Diagnostics", 4)

	UI.AddButton(srvSec, "📋 Copy Current Coordinates (Vector3)", function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local pos = root.Position
			local posStr = string.format("Vector3.new(%.3f, %.3f, %.3f)", pos.X, pos.Y, pos.Z)
			if setclipboard then
				setclipboard(posStr)
				UI.Notify("Copied Coordinates", posStr, 3, "success")
			else
				UI.Notify("Position", posStr, 3, "success")
			end
		end
	end, 1)

	UI.AddButton(srvSec, "🔄 Rejoin Current Server", function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end, 2)

	UI.AddButton(srvSec, "🚀 Server Hop (Join New Server)", function()
		TeleportService:Teleport(game.PlaceId, player)
	end, 3)
end)

if not success then
	warn("[HipHub CDID Main Error]:", err)
end
