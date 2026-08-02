-- 🌀 CAB Misc Tab Module
-- Misc features (FPS Booster / Texture Remover, Black Screen, Cap FPS, Movement: WalkSpeed & Fly)
-- Loaded by ui.lua via _G.HipHubUI shared references

local function initMisc()
	local refs = _G.HipHubUI
	if not refs then
		return
	end

	local TweenService = refs.TweenService
	local UserInputService = refs.UserInputService
	local player = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")

	local COLORS = refs.COLORS or {}
	local toggleOnColor = COLORS.toggleOn or Color3.fromRGB(0, 180, 230)
	local toggleOffColor = COLORS.toggleOff or Color3.fromRGB(40, 46, 70)

	local miscFrameContent = (refs.tabs and refs.tabs["Misc"] and refs.tabs["Misc"].Frame) or refs.miscFrameContent
	if not miscFrameContent then
		return
	end

	refs.applyListLayout(miscFrameContent, 10)

	------------------------------------------------
	-- ⚙️ MISC STATES & CONFIG
	------------------------------------------------
	local fpsBoostEnabled = false
	local blackScreenEnabled = false
	local capFpsEnabled = false
	local walkSpeedEnabled = false
	local walkSpeedValue = 16
	local flyEnabled = false

	------------------------------------------------
	-- ⚡ FPS BOOST ENGINE (Texture & Material Remover)
	------------------------------------------------
	local originalMaterials = {}
	local originalTextures = {}
	local originalShadows = nil
	local fpsBoostConnection = nil

	local function applyFpsBoostToInstance(desc)
		pcall(function()
			if desc:IsA("BasePart") then
				if not originalMaterials[desc] then
					originalMaterials[desc] = desc.Material
				end
				desc.Material = Enum.Material.SmoothPlastic
			elseif desc:IsA("Decal") or desc:IsA("Texture") then
				if not originalTextures[desc] then
					originalTextures[desc] = desc.Texture
				end
				desc.Texture = ""
			elseif desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Smoke") or desc:IsA("Fire") or desc:IsA("Sparkles") then
				if not originalTextures[desc] then
					originalTextures[desc] = desc.Enabled
				end
				desc.Enabled = false
			elseif desc:IsA("PostEffect") or desc:IsA("BloomEffect") or desc:IsA("BlurEffect") or desc:IsA("SunRaysEffect") or desc:IsA("DepthOfFieldEffect") then
				if not originalTextures[desc] then
					originalTextures[desc] = desc.Enabled
				end
				desc.Enabled = false
			end
		end)
	end

	local function enableFpsBoost()
		pcall(function()
			-- Lower lighting & shadows for maximum FPS boost
			if Lighting then
				if originalShadows == nil then
					originalShadows = Lighting.GlobalShadows
				end
				Lighting.GlobalShadows = false
				for _, effect in ipairs(Lighting:GetChildren()) do
					if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") then
						if not originalTextures[effect] then
							originalTextures[effect] = effect.Enabled
						end
						effect.Enabled = false
					end
				end
			end

			-- Optimize Terrain water
			local Terrain = Workspace:FindFirstChildOfClass("Terrain")
			if Terrain then
				pcall(function()
					Terrain.WaterWaveSize = 0
					Terrain.WaterWaveSpeed = 0
					Terrain.WaterReflectance = 0
					Terrain.WaterTransparency = 0
				end)
			end

			-- Process all existing workspace objects
			for _, desc in ipairs(Workspace:GetDescendants()) do
				applyFpsBoostToInstance(desc)
			end

			-- Hook newly added objects dynamically
			if not fpsBoostConnection then
				fpsBoostConnection = Workspace.DescendantAdded:Connect(function(desc)
					if fpsBoostEnabled then
						applyFpsBoostToInstance(desc)
					end
				end)
			end
		end)
	end

	local function disableFpsBoost()
		pcall(function()
			if fpsBoostConnection then
				fpsBoostConnection:Disconnect()
				fpsBoostConnection = nil
			end
			if Lighting and originalShadows ~= nil then
				Lighting.GlobalShadows = originalShadows
			end
			for part, mat in pairs(originalMaterials) do
				if part and part.Parent then
					pcall(function() part.Material = mat end)
				end
			end
			for inst, val in pairs(originalTextures) do
				if inst and inst.Parent then
					pcall(function()
						if typeof(val) == "boolean" then
							inst.Enabled = val
						else
							inst.Texture = val
						end
					end)
				end
			end
			table.clear(originalMaterials)
			table.clear(originalTextures)
		end)
	end

	------------------------------------------------
	-- 🚀 FLYING & MOVEMENT ENGINE
	------------------------------------------------
	local flyBv = nil
	local flyBg = nil
	local flyConnection = nil

	local function startFlying()
		pcall(function()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum then return end

			if not flyBv or not flyBv.Parent then
				flyBv = Instance.new("BodyVelocity")
				flyBv.Name = "HipHubUserFlyBV"
				flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				flyBv.Velocity = Vector3.zero
				flyBv.Parent = hrp
			end

			if not flyBg or not flyBg.Parent then
				flyBg = Instance.new("BodyGyro")
				flyBg.Name = "HipHubUserFlyBG"
				flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
				flyBg.P = 9000
				flyBg.CFrame = hrp.CFrame
				flyBg.Parent = hrp
			end

			hum.PlatformStand = true

			if not flyConnection then
				flyConnection = RunService.RenderStepped:Connect(function()
					if not flyEnabled then return end
					local cChar = player.Character
					local cHrp = cChar and cChar:FindFirstChild("HumanoidRootPart")
					local cHum = cChar and cChar:FindFirstChildOfClass("Humanoid")
					if not cHrp or not cHum then return end

					local cam = Workspace.CurrentCamera
					if not cam then return end

					cHum.PlatformStand = true

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
					if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E) then
						moveDir = moveDir + Vector3.new(0, 1, 0)
					end
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
						moveDir = moveDir - Vector3.new(0, 1, 0)
					end

					if moveDir.Magnitude > 0 then
						moveDir = moveDir.Unit
					end

					local flySpeed = math.max(walkSpeedValue, 40)
					if flyBv and flyBv.Parent then
						if moveDir.Magnitude > 0 then
							flyBv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
							flyBv.Velocity = moveDir * flySpeed
						else
							flyBv.MaxForce = Vector3.zero
							flyBv.Velocity = Vector3.zero
						end
					end
					if flyBg and flyBg.Parent then
						if moveDir.Magnitude > 0 then
							flyBg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
							flyBg.CFrame = cam.CFrame
						else
							flyBg.MaxTorque = Vector3.zero
						end
					end
				end)
			end
		end)
	end

	local function stopFlying()
		pcall(function()
			if flyConnection then
				flyConnection:Disconnect()
				flyConnection = nil
			end
			if flyBv then
				pcall(function() flyBv:Destroy() end)
				flyBv = nil
			end
			if flyBg then
				pcall(function() flyBg:Destroy() end)
				flyBg = nil
			end

			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.PlatformStand = false
			end
		end)
	end

	-- Multi-layer Robust Walk Speed Engine
	local walkSpeedConn = nil
	local function applyWalkSpeed(char)
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		if walkSpeedConn then
			pcall(function() walkSpeedConn:Disconnect() end)
			walkSpeedConn = nil
		end

		walkSpeedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if walkSpeedEnabled and walkSpeedValue and walkSpeedValue > 0 then
				if hum.WalkSpeed ~= walkSpeedValue then
					hum.WalkSpeed = walkSpeedValue
				end
			end
		end)

		if walkSpeedEnabled and walkSpeedValue and walkSpeedValue > 0 then
			hum.WalkSpeed = walkSpeedValue
		end
	end

	if player.Character then
		task.spawn(function() applyWalkSpeed(player.Character) end)
	end
	player.CharacterAdded:Connect(function(char)
		task.spawn(function() applyWalkSpeed(char) end)
	end)

	RunService.Stepped:Connect(function()
		if walkSpeedEnabled and walkSpeedValue and walkSpeedValue > 0 then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.WalkSpeed ~= walkSpeedValue then
				hum.WalkSpeed = walkSpeedValue
			end
		end
	end)

	------------------------------------------------
	-- 🏃 MOVEMENT SECTION UI
	------------------------------------------------
	local moveCollapsible = refs.createCollapsibleSection(miscFrameContent, "Movement", 1)
	local moveContainer = moveCollapsible.Content

	-- 1. Enable Custom Walk Speed Toggle
	local wsToggleCard, wsToggleTrack, wsToggleThumb = refs.createGlassToggle(moveContainer, "Enable Custom WalkSpeed", 1)
	local updateWalkSpeedVisuals = function()
		if walkSpeedEnabled then
			TweenService:Create(wsToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(wsToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = walkSpeedValue end
		else
			TweenService:Create(wsToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(wsToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = 16 end
		end
	end
	updateWalkSpeedVisuals()

	wsToggleTrack.MouseButton1Click:Connect(function()
		walkSpeedEnabled = not walkSpeedEnabled
		updateWalkSpeedVisuals()
		if refs.saveConfig then pcall(refs.saveConfig) end
	end)

	-- 2. Walk Speed Textfield Card
	local wsCard = Instance.new("Frame")
	wsCard.Size = UDim2.new(1, 0, 0, 32)
	wsCard.BackgroundColor3 = COLORS.glassCard
	wsCard.BackgroundTransparency = refs.TRANSPARENCY.glassCard
	wsCard.BorderSizePixel = 0
	wsCard.LayoutOrder = 2
	wsCard.Parent = moveContainer

	refs.applyGlass(wsCard, {
		corner = refs.CORNER.small,
		stroke = true,
		strokeColor = COLORS.borderGlass,
		strokeThickness = 1,
		strokeTransparency = 0.75
	})

	local wsTitle = Instance.new("TextLabel")
	wsTitle.Size = UDim2.new(0.5, 0, 1, 0)
	wsTitle.Position = UDim2.new(0, 12, 0, 0)
	wsTitle.BackgroundTransparency = 1
	wsTitle.Text = "Walk Speed Value"
	wsTitle.TextColor3 = COLORS.textPrimary or Color3.fromRGB(225, 235, 255)
	wsTitle.Font = Enum.Font.GothamMedium
	wsTitle.TextSize = 13
	wsTitle.TextXAlignment = Enum.TextXAlignment.Left
	wsTitle.Parent = wsCard

	local wsBox = Instance.new("TextBox")
	wsBox.Size = UDim2.new(0, 80, 0, 22)
	wsBox.Position = UDim2.new(1, -92, 0.5, -11)
	wsBox.BackgroundColor3 = COLORS.glassPrimary or Color3.fromRGB(20, 24, 44)
	wsBox.BackgroundTransparency = 0.2
	wsBox.BorderSizePixel = 0
	wsBox.Text = tostring(walkSpeedValue)
	wsBox.PlaceholderText = "16"
	wsBox.TextColor3 = COLORS.accentCyan or Color3.fromRGB(0, 200, 255)
	wsBox.Font = Enum.Font.GothamBold
	wsBox.TextSize = 12
	wsBox.ClearTextOnFocus = false
	wsBox.Parent = wsCard

	refs.applyGlass(wsBox, {
		corner = refs.CORNER.small,
		stroke = true,
		strokeColor = COLORS.accentCyan,
		strokeThickness = 1,
		strokeTransparency = 0.55
	})

	wsBox:GetPropertyChangedSignal("Text"):Connect(function()
		local num = tonumber(wsBox.Text)
		if num and num > 0 then
			walkSpeedValue = num
			if walkSpeedEnabled then
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum.WalkSpeed = num end
			end
		end
	end)

	wsBox.FocusLost:Connect(function()
		local num = tonumber(wsBox.Text)
		if num and num > 0 then
			walkSpeedValue = num
		else
			wsBox.Text = tostring(walkSpeedValue)
		end
		if refs.saveConfig then pcall(refs.saveConfig) end
	end)

	-- 2. Fly Toggle (Below Walk Speed)
	local flyCard, flyTrack, flyThumb = refs.createGlassToggle(moveContainer, "Fly (Fly Mode)", 2)
	local updateFlyVisuals = function()
		if flyEnabled then
			TweenService:Create(flyTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(flyThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			startFlying()
		else
			TweenService:Create(flyTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(flyThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			stopFlying()
		end
	end
	updateFlyVisuals()

	flyTrack.MouseButton1Click:Connect(function()
		flyEnabled = not flyEnabled
		updateFlyVisuals()
		if refs.saveConfig then pcall(refs.saveConfig) end
	end)

	------------------------------------------------
	-- 🖥️ PERFORMANCE OPTIMIZATIONS SECTION
	------------------------------------------------
	local perfCollapsible = refs.createCollapsibleSection(miscFrameContent, "Performance Optimizations", 2)
	local perfContainer = perfCollapsible.Content

	-- 1. FPS Boost Toggle (Remove Textures & Effects)
	local fpsCard, fpsTrack, fpsThumb = refs.createGlassToggle(perfContainer, "FPS Boost (Remove Textures & Effects)", 1)
	local updateFpsBoostVisuals = function()
		if fpsBoostEnabled then
			TweenService:Create(fpsTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(fpsThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			enableFpsBoost()
		else
			TweenService:Create(fpsTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(fpsThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			disableFpsBoost()
		end
	end

	fpsTrack.MouseButton1Click:Connect(function()
		fpsBoostEnabled = not fpsBoostEnabled
		updateFpsBoostVisuals()
		if refs.saveConfig then pcall(refs.saveConfig) end
	end)

	-- 2. Cap FPS Toggle (15 FPS Cap mode)
	local capCard, capTrack, capThumb = refs.createGlassToggle(perfContainer, "Cap FPS (Limit to 15 FPS)", 2)
	local updateCapFpsVisuals = function()
		if capFpsEnabled then
			TweenService:Create(capTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(capThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			if setfpscap then pcall(setfpscap, 15) end
		else
			TweenService:Create(capTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(capThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			if setfpscap then pcall(setfpscap, 240) end
		end
	end

	capTrack.MouseButton1Click:Connect(function()
		capFpsEnabled = not capFpsEnabled
		updateCapFpsVisuals()
		if refs.saveConfig then pcall(refs.saveConfig) end
	end)

	-- 3. Black Screen Toggle (Disable 3D Rendering)
	local bsCard, bsTrack, bsThumb = refs.createGlassToggle(perfContainer, "White Screen (Disable 3D Rendering)", 3)
	local updateBlackScreenVisuals = function()
		if blackScreenEnabled then
			TweenService:Create(bsTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOnColor }):Play()
			TweenService:Create(bsThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(1, -16, 0.5, -7) }):Play()
			pcall(function() RunService:Set3dRenderingEnabled(false) end)
		else
			TweenService:Create(bsTrack, TweenInfo.new(0.2), { BackgroundColor3 = toggleOffColor }):Play()
			TweenService:Create(bsThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, 2, 0.5, -7) }):Play()
			pcall(function() RunService:Set3dRenderingEnabled(true) end)
		end
	end

	bsTrack.MouseButton1Click:Connect(function()
		blackScreenEnabled = not blackScreenEnabled
		updateBlackScreenVisuals()
		if refs.saveConfig then pcall(refs.saveConfig) end
	end)

	------------------------------------------------
	-- 📤 EXPOSE STATE TO _G
	------------------------------------------------
	_G.HipHubMisc = {
		getState = function()
			return {
				fpsBoostEnabled = fpsBoostEnabled,
				capFpsEnabled = capFpsEnabled,
				blackScreenEnabled = blackScreenEnabled,
				walkSpeedEnabled = walkSpeedEnabled,
				walkSpeedValue = walkSpeedValue,
				flyEnabled = flyEnabled,
			}
		end,
		setState = function(s)
			if not s then return end
			if s.fpsBoostEnabled ~= nil then
				fpsBoostEnabled = (s.fpsBoostEnabled == true)
				updateFpsBoostVisuals()
			end
			if s.capFpsEnabled ~= nil then
				capFpsEnabled = (s.capFpsEnabled == true)
				updateCapFpsVisuals()
			end
			if s.blackScreenEnabled ~= nil then
				blackScreenEnabled = (s.blackScreenEnabled == true)
				updateBlackScreenVisuals()
			end
			if s.walkSpeedEnabled ~= nil then
				walkSpeedEnabled = (s.walkSpeedEnabled == true)
				updateWalkSpeedVisuals()
			end
			if s.walkSpeedValue ~= nil and tonumber(s.walkSpeedValue) then
				walkSpeedValue = tonumber(s.walkSpeedValue)
				wsBox.Text = tostring(walkSpeedValue)
			end
			if s.flyEnabled ~= nil then
				local newFly = (s.flyEnabled == true)
				if flyEnabled ~= newFly then
					flyEnabled = newFly
					updateFlyVisuals()
				end
			end
		end
	}
end

-- Initialize Misc module
task.spawn(function()
	task.wait(0.2)
	pcall(initMisc)
end)
