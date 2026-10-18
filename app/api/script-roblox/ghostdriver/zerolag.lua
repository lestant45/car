-- HipHub Ghost Driver — Zero Lag & FPS Booster Engine (Redfinger & Low-End Devices)
-- Extreme performance enhancements: strips rain particles, post-processing, heavy textures, and disables shadows

local success, err = pcall(function()
	local Lighting = game:GetService("Lighting")
	local Config = _G.HipHubConfig or { settings = {} }
	local UI = _G.HipHubUI

	local ZeroLag = {
		Active = false,
		Connections = {}
	}

	-- 1. Optimasi Lighting & Post-Processing (Matikan Bayangan & Efek Berat)
	local function optimizeLighting()
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			Lighting.Brightness = 1

			for _, effect in ipairs(Lighting:GetChildren()) do
				if effect:IsA("PostProcessEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect")
					or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("Atmosphere") then
					effect.Enabled = false
				end
			end
		end)
	end

	-- 2. Bersihkan Rain Particles (Pembunuh FPS nomor 1 di Ghost Driver!)
	local function cleanRain()
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v.Name:find("Rain") or v.Name:find("Emitter") then
					if v:IsA("ParticleEmitter") then
						v.Enabled = false
					elseif v:IsA("BasePart") and v.Name:find("Rain") then
						v.Transparency = 1
					end
				end
			end
		end)
	end

	-- 3. Strip Part Material, Textures, and Shadows (Potato Mode)
	local function stripPart(obj)
		if not ZeroLag.Active then return end
		pcall(function()
			if obj:IsA("BasePart") then
				obj.CastShadow = false
				if Config.settings.potatoMaterials ~= false then
					obj.Material = Enum.Material.SmoothPlastic
					obj.Reflectance = 0
				end
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				if Config.settings.potatoMaterials ~= false then
					obj.Transparency = 1
				end
			elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
				obj.Enabled = false
			end
		end)
	end

	-- 4. Apply ke seluruh Workspace
	local function applyPotatoWorkspace()
		pcall(function()
			for _, v in ipairs(workspace:GetDescendants()) do
				stripPart(v)
			end
		end)
	end

	-- 5. Set FPS Cap & Quality Level
	local function applyRenderSettings()
		pcall(function()
			if setfpscap then
				local cap = Config.settings.fpsCap or 60
				setfpscap(cap)
			end
			if settings and settings().Rendering then
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end
		end)
	end

	-- 6. Enable / Disable Zero Lag Mode
	function ZeroLag.SetEnabled(state)
		ZeroLag.Active = state
		Config.settings.zeroLag = state
		if _G.HipHub_GhostDriver_Settings then
			_G.HipHub_GhostDriver_Settings.Save()
		end

		if state then
			optimizeLighting()
			cleanRain()
			applyPotatoWorkspace()
			applyRenderSettings()

			-- Listener untuk part/mobil baru spawn
			if not ZeroLag.Connections["DescendantAdded"] then
				ZeroLag.Connections["DescendantAdded"] = workspace.DescendantAdded:Connect(function(child)
					if ZeroLag.Active then
						task.defer(function()
							stripPart(child)
						end)
					end
				end)
			end

			-- Periodic loop untuk memastikan rain & lighting tetap mati saat teleport antar map
			if not ZeroLag.Connections["LoopRunning"] then
				ZeroLag.Connections["LoopRunning"] = true
				task.spawn(function()
					while ZeroLag.Active do
						cleanRain()
						optimizeLighting()
						task.wait(4)
					end
					ZeroLag.Connections["LoopRunning"] = nil
				end)
			end

			if UI and UI.Notify then
				UI.Notify("Zero Lag Mode", "FPS Boost activated! Shadows, rain & heavy textures stripped.", 3, "success")
			end
		else
			if ZeroLag.Connections["DescendantAdded"] then
				ZeroLag.Connections["DescendantAdded"]:Disconnect()
				ZeroLag.Connections["DescendantAdded"] = nil
			end
			pcall(function()
				Lighting.GlobalShadows = true
				for _, effect in ipairs(Lighting:GetChildren()) do
					if effect:IsA("PostProcessEffect") then
						effect.Enabled = true
					end
				end
			end)
			if UI and UI.Notify then
				UI.Notify("Zero Lag Mode", "Normal graphics restored.", 3, "info")
			end
		end
	end

	-- Auto-start jika di config sudah true
	if Config.settings.zeroLag then
		task.delay(1, function()
			ZeroLag.SetEnabled(true)
		end)
	end

	_G.HipHub_GhostDriver_ZeroLag = ZeroLag
end)

if not success then
	warn("[HipHub Ghost Driver ZeroLag Error]:", err)
end
