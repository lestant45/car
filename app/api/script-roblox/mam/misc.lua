-- 🌀 CAB Misc Tab Module
-- Misc features (FPS Booster / Texture Remover, Black Screen, Cap FPS)
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
	-- 🖥️ MISC UI CARDS & TOGGLES
	------------------------------------------------
	-- Collapsible Section: Performance Optimizations
	local perfCollapsible = refs.createCollapsibleSection(miscFrameContent, "Performance Optimizations", 1)
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

	_G.HipHubMisc = {
		getState = function()
			return {
				fpsBoostEnabled = fpsBoostEnabled,
				capFpsEnabled = capFpsEnabled,
				blackScreenEnabled = blackScreenEnabled,
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
		end
	}
end

-- Initialize Misc module
task.spawn(function()
	task.wait(0.2)
	pcall(initMisc)
end)
