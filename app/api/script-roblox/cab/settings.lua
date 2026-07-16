-- ⚙️ CAB Settings Tab Module
-- Separate file for Settings functionality (Anti-AFK, Touch Fling, Noclip, Keybinds)
-- Loaded by ui.lua via _G.HipHubUI shared references

local function initSettings()
	local refs = _G.HipHubUI
	if not refs then
		return
	end

	local TweenService = refs.TweenService
	local UserInputService = refs.UserInputService
	local saveConfig = refs.saveConfig
	local player = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")

	local kbValue = refs.kbValue
	local keybindCard = refs.keybindCard
	local antiAfkCard = refs.antiAfkCard
	local afkToggleTrack = refs.afkToggleTrack
	local afkToggleThumb = refs.afkToggleThumb
	local touchFlingCard = refs.touchFlingCard
	local tfToggleTrack = refs.tfToggleTrack
	local tfToggleThumb = refs.tfToggleThumb
	local antiFlingCard = refs.antiFlingCard
	local afToggleTrack = refs.afToggleTrack
	local afToggleThumb = refs.afToggleThumb
	local noclipCard = refs.noclipCard
	local ncToggleTrack = refs.ncToggleTrack
	local ncToggleThumb = refs.ncToggleThumb
	local startMinimizedCard = refs.startMinimizedCard
	local smToggleTrack = refs.smToggleTrack
	local smToggleThumb = refs.smToggleThumb
	local discordButton = refs.discordButton

	local COLORS = refs.COLORS or {}
	local toggleOnColor = COLORS.toggleOn or Color3.fromRGB(0, 180, 230)
	local toggleOffColor = COLORS.toggleOff or Color3.fromRGB(40, 46, 70)

	------------------------------------------------
	-- ⚙️ CONFIG / STATE
	------------------------------------------------
	local state = {
		antiAfk = true,
		touchFling = false,
		antiFling = false,
		noclip = false,
		startMinimized = false,
		keybind = "RightShift"
	}

	_G.HipHubSettings = {
		getState = function()
			return state
		end
	}

	------------------------------------------------
	-- 🔄 UI VISUAL SYNCHRONIZATION HELPERS
	------------------------------------------------
	local function updateAntiAfkVisuals()
		if state.antiAfk then
			TweenService:Create(afkToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(afkToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			pcall(function() player:SetAttribute("AntiAfkIdleOverride", 99999999) end)
		else
			TweenService:Create(afkToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(afkToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			pcall(function() player:SetAttribute("AntiAfkIdleOverride", nil) end)
		end
	end

	local function updateTouchFlingVisuals()
		if state.touchFling then
			TweenService:Create(tfToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(tfToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
		else
			TweenService:Create(tfToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(tfToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
		end
	end

	local function updateAntiFlingVisuals()
		if state.antiFling then
			TweenService:Create(afToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(afToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
		else
			TweenService:Create(afToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(afToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
		end
	end

	local function updateNoclipVisuals()
		if state.noclip then
			TweenService:Create(ncToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(ncToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
		else
			TweenService:Create(ncToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(ncToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
		end
	end

	local function updateStartMinimizedVisuals()
		if state.startMinimized then
			TweenService:Create(smToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(smToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(1, -16, 0.5, -7) }):Play()
		else
			TweenService:Create(smToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(smToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.new(0, 2, 0.5, -7) }):Play()
		end
	end

	------------------------------------------------
	-- 🤖 TOUCH FLING MECHANICS
	------------------------------------------------
	local function runTouchFling()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
			local detection = Instance.new("Decal")
			detection.Name = "juisdfj0i32i0eidsuf0iok"
			detection.Parent = ReplicatedStorage
		end

		local lp = game:GetService("Players").LocalPlayer
		local c, hrp, vel, movel = nil, nil, nil, 0.1

		while state.touchFling do
			RunService.Heartbeat:Wait()
			c = lp.Character
			hrp = c and c:FindFirstChild("HumanoidRootPart")

			if hrp then
				vel = hrp.Velocity
				hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
				RunService.RenderStepped:Wait()
				hrp.Velocity = vel
				RunService.Stepped:Wait()
				hrp.Velocity = vel + Vector3.new(0, movel, 0)
				movel = -movel
			end
		end
	end

	local function restoreCollisions()
		local lp = game:GetService("Players").LocalPlayer
		local char = lp.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					pcall(function() part.CanTouch = true end)
					pcall(function() part.CanCollide = true end)
				end
			end
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				pcall(function() humanoid.PlatformStand = false end)
				pcall(function() humanoid.Sit = false end)
			end
		end
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			if player ~= lp and player.Character then
				for _, part in ipairs(player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						pcall(function() part.CanTouch = true end)
						pcall(function() part.CanCollide = true end)
					end
				end
			end
		end
	end

	local function runAntiFling()
		local lp = game:GetService("Players").LocalPlayer
		local connection

		-- Clean local character from ragdoll states & joints
		local function cleanCharacter(char)
			if not char then return end
			local humanoid = char:WaitForChild("Humanoid", 5)
			if not humanoid then return end

			-- Force humanoid state back if knocked down
			local s1 = humanoid.StateChanged:Connect(function(old, new)
				if state.antiFling and (new == Enum.HumanoidStateType.Physics or new == Enum.HumanoidStateType.Ragdoll) then
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)

			-- Prevent server forcing PlatformStand or Sit
			local s2 = humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
				if state.antiFling and humanoid.PlatformStand then
					humanoid.PlatformStand = false
				end
			end)
			local s3 = humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
				if state.antiFling and humanoid.Sit then
					humanoid.Sit = false
				end
			end)

			-- Instantly destroy newly created ragdoll constraints and re-enable motors
			local s4 = char.DescendantAdded:Connect(function(desc)
				if not state.antiFling then return end
				if desc:IsA("BallSocketConstraint") or desc:IsA("BallSocketJoint") or desc:IsA("Attachment") and desc.Name:lower():find("ragdoll") then
					task.defer(pcall, function() desc:Destroy() end)
				elseif desc:IsA("Motor6D") and not desc.Enabled then
					task.defer(pcall, function() desc.Enabled = true end)
				end
			end)

			-- Initial cleanup of existing joints
			for _, desc in ipairs(char:GetDescendants()) do
				if desc:IsA("BallSocketConstraint") or desc:IsA("BallSocketJoint") or desc:IsA("Attachment") and desc.Name:lower():find("ragdoll") then
					pcall(function() desc:Destroy() end)
				elseif desc:IsA("Motor6D") and not desc.Enabled then
					pcall(function() desc.Enabled = true end)
				end
			end

			-- Disconnect listeners when character dies or goes away
			char.Destroying:Connect(function()
				s1:Disconnect()
				s2:Disconnect()
				s3:Disconnect()
				s4:Disconnect()
			end)
		end

		-- Connect cleanCharacter to current and future characters
		local charAddedConn
		charAddedConn = lp.CharacterAdded:Connect(function(char)
			if not state.antiFling then
				charAddedConn:Disconnect()
				return
			end
			pcall(cleanCharacter, char)
		end)
		if lp.Character then
			pcall(cleanCharacter, lp.Character)
		end

		-- Run continuous stepped loop for collision, touch, and animations
		connection = RunService.Stepped:Connect(function()
			if not state.antiFling then
				connection:Disconnect()
				if charAddedConn then charAddedConn:Disconnect() end
				return
			end

			local char = lp.Character
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if char and humanoid then
				-- Keep local player velocity safe (unless touch flinging)
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp and not state.touchFling then
					local moveDir = humanoid.MoveDirection
					if moveDir.Magnitude == 0 then
						-- Lock horizontal velocity to 0 to prevent sliding/knockback
						hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
						hrp.RotVelocity = Vector3.new(0, 0, 0)
					end
					-- Limit maximum velocity spike magnitude to prevent launches/big shifts
					if hrp.Velocity.Magnitude > 40 then
						local limitSpeed = math.max(humanoid.WalkSpeed + 10, 40)
						hrp.Velocity = hrp.Velocity.Unit * limitSpeed
					end
				end

				-- Force no-touch state for ourselves, EXCLUDING equipped tools
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						if part:FindFirstAncestorOfClass("Tool") then
							pcall(function() part.CanTouch = true end)
						else
							pcall(function() part.CanTouch = false end)
						end
					end
				end

				-- Stop hit/fall/ragdoll animations
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
						local name = track.Name:lower()
						if name:find("hit") or name:find("fall") or name:find("ragdoll") or name:find("knock") or name:find("trip") then
							track:Stop()
						end
					end
				end

				-- Disable collision with other players (if not touch flinging)
				if not state.touchFling then
					for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
						if player ~= lp and player.Character then
							for _, part in ipairs(player.Character:GetDescendants()) do
								if part:IsA("BasePart") then
									pcall(function() part.CanCollide = false end)
									pcall(function() part.CanTouch = true end)
								end
							end
						end
					end
				end
			end
		end)
	end

	local function runNoclip()
		local lp = game:GetService("Players").LocalPlayer
		local connection
		connection = RunService.Stepped:Connect(function()
			if not state.noclip then
				connection:Disconnect()
				return
			end
			local char = lp.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						pcall(function() part.CanCollide = false end)
					end
				end
			end
		end)
	end

	------------------------------------------------
	-- ☕ ANTI-AFK MECHANICS
	------------------------------------------------
	local function simulateActivity()
		local VirtualUser = game:GetService("VirtualUser")
		pcall(function()
			VirtualUser:CaptureController()
			local cam = workspace.CurrentCamera
			local cf = cam and cam.CFrame or CFrame.new()
			VirtualUser:Button2Down(Vector2.new(0, 0), cf)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.new(0, 0), cf)
		end)

		pcall(function()
			local VirtualInputManager = game:GetService("VirtualInputManager")
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
			task.wait(0.1)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
		end)
	end

	local function disableIdleConnections()
		pcall(function()
			if getconnections then
				for _, conn in ipairs(getconnections(player.Idled)) do
					pcall(function() conn:Disable() end)
				end
			end
		end)
	end

	player.Idled:Connect(function()
		if state.antiAfk then
			simulateActivity()
		end
	end)

	task.spawn(function()
		while task.wait(120) do
			if state.antiAfk then
				simulateActivity()
			end
		end
	end)

	------------------------------------------------
	-- 🔌 CONTROLLERS & INTERACTIONS
	------------------------------------------------
	-- Keybind Card Click (Change Keybind)
	local isBinding = false
	if keybindCard then
		keybindCard.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if isBinding then return end
				isBinding = true
				kbValue.Text = "..."
				local connection
				connection = UserInputService.InputBegan:Connect(function(newinput)
					if newinput.UserInputType == Enum.UserInputType.Keyboard then
						local key = newinput.KeyCode.Name
						if key ~= "Unknown" and key ~= "Escape" then
							kbValue.Text = key
							state.keybind = key
							pcall(saveConfig)
						else
							kbValue.Text = state.keybind or "RightShift"
						end
						connection:Disconnect()
						isBinding = false
					end
				end)
			end
		end)
	end

	-- Anti-AFK Toggle click
	afkToggleTrack.MouseButton1Click:Connect(function()
		state.antiAfk = not state.antiAfk
		updateAntiAfkVisuals()
		if state.antiAfk then
			disableIdleConnections()
		end
		pcall(saveConfig)
	end)

	-- Touch Fling Toggle click
	tfToggleTrack.MouseButton1Click:Connect(function()
		state.touchFling = not state.touchFling
		updateTouchFlingVisuals()
		pcall(saveConfig)
		if state.touchFling then
			task.spawn(runTouchFling)
		end
	end)

	-- Anti-Fling Toggle click
	afToggleTrack.MouseButton1Click:Connect(function()
		state.antiFling = not state.antiFling
		updateAntiFlingVisuals()
		pcall(saveConfig)
		if state.antiFling then
			task.spawn(runAntiFling)
		else
			pcall(restoreCollisions)
		end
	end)

	-- Noclip Toggle click
	ncToggleTrack.MouseButton1Click:Connect(function()
		state.noclip = not state.noclip
		updateNoclipVisuals()
		pcall(saveConfig)
		if state.noclip then
			task.spawn(runNoclip)
		else
			pcall(restoreCollisions)
		end
	end)

	-- Start Minimized Toggle click
	smToggleTrack.MouseButton1Click:Connect(function()
		state.startMinimized = not state.startMinimized
		updateStartMinimizedVisuals()
		pcall(saveConfig)
	end)

	-- Discord Clipboard helper
	local function copyToClipboard(text)
		if setclipboard then
			setclipboard(text)
			return true
		elseif toclipboard then
			toclipboard(text)
			return true
		elseif syn and syn.write_clipboard then
			syn.write_clipboard(text)
			return true
		end
		return false
	end

	discordButton.MouseButton1Click:Connect(function()
		local link = "https://discord.gg/VmUs995Nd"
		if copyToClipboard(link) then
			discordButton.Text = "Discord Link Copied!"
		else
			discordButton.Text = "Failed to copy! Link: https://discord.gg/VmUs995Nd"
		end
		task.wait(2)
		discordButton.Text = "Join Discord"
	end)

	-- Reset Config Button
	local resetColor = Color3.fromRGB(220, 50, 70)
	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(1, 0, 0, 36)
	resetBtn.BackgroundColor3 = resetColor
	resetBtn.BackgroundTransparency = 0.15
	resetBtn.BorderSizePixel = 0
	resetBtn.Text = "Reset Config"
	resetBtn.TextColor3 = COLORS.textWhite or Color3.fromRGB(255, 255, 255)
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextSize = 13
	resetBtn.ZIndex = 2
	resetBtn.LayoutOrder = 100
	resetBtn.Parent = refs.settingsFrame or (discordButton and discordButton.Parent)

	if refs.applyGlass then
		refs.applyGlass(resetBtn, {
			corner = refs.CORNER and refs.CORNER.small,
			stroke = true,
			strokeColor = resetColor,
			strokeThickness = 1,
			strokeTransparency = 0.4
		})
	end

	-- Hover animation for Reset Button
	pcall(function()
		resetBtn.MouseEnter:Connect(function()
			TweenService:Create(resetBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
		end)
		resetBtn.MouseLeave:Connect(function()
			TweenService:Create(resetBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.15 }):Play()
		end)
	end)

	local isResetting = false
	resetBtn.MouseButton1Click:Connect(function()
		if isResetting then return end
		isResetting = true
		resetBtn.Text = "Resetting Config..."

		-- Reset settings.lua states & UI visuals
		state.antiAfk = false
		state.touchFling = false
		state.antiFling = false
		state.noclip = false
		state.startMinimized = false
		state.keybind = "RightShift"

		updateAntiAfkVisuals()
		updateTouchFlingVisuals()
		updateAntiFlingVisuals()
		updateNoclipVisuals()
		updateStartMinimizedVisuals()
		if kbValue then
			kbValue.Text = "RightShift"
		end
		pcall(restoreCollisions)

		-- Delete config files from filesystem
		pcall(function()
			if delfile then
				pcall(delfile, "HipHub/config.json")
			else
				if writefile then
					pcall(writefile, "HipHub/config.json", "{}")
				end
			end
		end)

		resetBtn.Text = "Config Reset! Rejoin/Reload"
		task.wait(3)
		resetBtn.Text = "Reset Config"
		isResetting = false
	end)

	------------------------------------------------
	-- ⚙️ CONFIG LOADING & SAVING INTEGRATION
	------------------------------------------------
	local function loadSettingsConfig()
		local config = _G.HipHubSettingsConfig
		if config and type(config) == "table" then
			if config.antiAfk ~= nil then
				state.antiAfk = (config.antiAfk == true)
			end
			if config.touchFling ~= nil then
				state.touchFling = (config.touchFling == true)
			end
			if config.antiFling ~= nil then
				state.antiFling = (config.antiFling == true)
			end
			if config.noclip ~= nil then
				state.noclip = (config.noclip == true)
			end
			if config.startMinimized ~= nil then
				state.startMinimized = (config.startMinimized == true)
			end
			if config.keybind and tostring(config.keybind) ~= "" then
				state.keybind = tostring(config.keybind)
				kbValue.Text = state.keybind
			end
		end

		updateAntiAfkVisuals()
		updateTouchFlingVisuals()
		updateAntiFlingVisuals()
		updateNoclipVisuals()
		updateStartMinimizedVisuals()

		if state.antiAfk then
			disableIdleConnections()
		end
		if state.touchFling then
			task.spawn(runTouchFling)
		end
		if state.antiFling then
			task.spawn(runAntiFling)
		end
		if state.noclip then
			task.spawn(runNoclip)
		end
	end

	-- Delay config load slightly
	task.spawn(function()
		task.wait(0.1)
		loadSettingsConfig()
	end)
end

-- Initialize Settings module
task.spawn(function()
	task.wait(0.2)
	pcall(initSettings)
end)
