-- 👁️ HipHub DE -- ESP System
-- Driving Empire (Place ID: 9694510481)
-- Features: Player ESP, Car/Vehicle ESP, Cash Bag ESP
--           Distance labels, Name labels, per-type color coding
-- Exports: _G.HipHubESP

local success, err = pcall(function()
	local Players    = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local player     = Players.LocalPlayer

	------------------------------------------------
	-- 📦 STATE
	------------------------------------------------
	local State = {
		playerEsp    = false,
		carEsp       = false,
		cashEsp      = false,
		showDistance = true,
		showName     = true,
	}

	-- Tracked ESP entries: {adornee=BasePart, billboard=BillboardGui, type=string}
	local espEntries = {}

	-- Cash object name keywords (same as farm.lua for consistency)
	local CASH_KEYWORDS = {
		"cashbag", "moneybag", "cash", "money", "dollar",
		"bill", "coin", "reward", "loot", "prize", "pickup",
	}

	local function matchesCash(name)
		local n = name:lower()
		for _, kw in ipairs(CASH_KEYWORDS) do
			if n:find(kw, 1, true) then return true end
		end
		return false
	end

	-- Returns true if a Model has a VehicleSeat (i.e. it is a driveable car)
	local function isVehicleModel(obj)
		return obj:IsA("Model") and obj:FindFirstChildOfClass("VehicleSeat") ~= nil
	end

	------------------------------------------------
	-- 🏷️ CREATE BILLBOARD ESP
	-- Attaches a BillboardGui to a BasePart
	------------------------------------------------
	local function createBillboard(adornee, labelText, color)
		if not adornee or not adornee.Parent then return nil end

		-- Remove old billboard if present
		local old = adornee:FindFirstChild("HipHubESP")
		if old then old:Destroy() end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "HipHubESP"
		billboard.Size = UDim2.new(0, 130, 0, 42)
		billboard.StudsOffset = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop = true
		billboard.Adornee = adornee
		billboard.MaxDistance = 400
		billboard.Parent = adornee

		-- Glass background frame
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
		frame.BackgroundTransparency = 0.30
		frame.BorderSizePixel = 0
		frame.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 1
		stroke.Transparency = 0.25
		stroke.Parent = frame

		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -6, 0.55, 0)
		nameLabel.Position = UDim2.new(0, 3, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = labelText
		nameLabel.TextColor3 = color
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 10
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Visible = State.showName
		nameLabel.Parent = frame

		-- Distance label
		local distLabel = Instance.new("TextLabel")
		distLabel.Name = "DistLabel"
		distLabel.Size = UDim2.new(1, -6, 0.45, 0)
		distLabel.Position = UDim2.new(0, 3, 0.55, 0)
		distLabel.BackgroundTransparency = 1
		distLabel.Text = ""
		distLabel.TextColor3 = Color3.fromRGB(180, 195, 225)
		distLabel.Font = Enum.Font.Gotham
		distLabel.TextSize = 9
		distLabel.TextXAlignment = Enum.TextXAlignment.Center
		distLabel.Visible = State.showDistance
		distLabel.Parent = frame

		return billboard
	end

	------------------------------------------------
	-- 🗑️ REMOVE ESP FROM ONE OBJECT
	------------------------------------------------
	local function removeESP(adornee)
		if adornee and adornee.Parent then
			local bb = adornee:FindFirstChild("HipHubESP")
			if bb then bb:Destroy() end
		end
	end

	------------------------------------------------
	-- 🗑️ CLEAR ALL ESP
	------------------------------------------------
	local function clearAll()
		for _, entry in ipairs(espEntries) do
			pcall(removeESP, entry.adornee)
		end
		espEntries = {}
	end

	------------------------------------------------
	-- 🔄 REFRESH / REBUILD ALL ESP
	-- Called on toggle change or periodic scan
	------------------------------------------------
	local function refreshESP()
		clearAll()

		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

		-- ── Player ESP ──────────────────────────────
		if State.playerEsp then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local hrp = p.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						-- Team color when available, else default red-ish
						local color = Color3.fromRGB(255, 110, 110)
						pcall(function()
							if p.Team and p.TeamColor then
								color = p.TeamColor.Color
							end
						end)
						local lbl = State.showName and p.Name or "Player"
						local bb = createBillboard(hrp, lbl, color)
						if bb then
							table.insert(espEntries, {adornee = hrp, billboard = bb, target = p, type = "player"})
						end
					end
				end
			end
		end

		-- ── Car / Vehicle ESP ────────────────────────
		if State.carEsp then
			for _, obj in ipairs(workspace:GetDescendants()) do
				if isVehicleModel(obj) then
					local ppart = obj.PrimaryPart
					if not ppart then
						ppart = obj:FindFirstChildOfClass("BasePart")
					end
					if ppart then
						local lbl = State.showName and obj.Name or "Vehicle"
						local bb = createBillboard(ppart, lbl, Color3.fromRGB(0, 200, 255))
						if bb then
							table.insert(espEntries, {adornee = ppart, billboard = bb, target = obj, type = "car"})
						end
					end
				end
			end
		end

		-- ── Cash Bag ESP ─────────────────────────────
		if State.cashEsp then
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") and matchesCash(obj.Name) then
					local lbl = State.showName and obj.Name or "Cash"
					local bb = createBillboard(obj, lbl, Color3.fromRGB(255, 210, 0))
					if bb then
						table.insert(espEntries, {adornee = obj, billboard = bb, target = obj, type = "cash"})
					end
				end
			end
		end
	end

	------------------------------------------------
	-- 🔁 DISTANCE UPDATE LOOP (Heartbeat)
	-- Updates distance labels & removes dead entries
	------------------------------------------------
	local updateConn = RunService.Heartbeat:Connect(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local toRemove = {}

		for i, entry in ipairs(espEntries) do
			local adornee = entry.adornee
			if not adornee or not adornee.Parent then
				table.insert(toRemove, i)
				continue
			end

			local bb = entry.billboard
			if not bb or not bb.Parent then
				table.insert(toRemove, i)
				continue
			end

			if State.showDistance then
				local dist = (adornee.Position - root.Position).Magnitude
				local frame = bb:FindFirstChildOfClass("Frame")
				if frame then
					local distLbl = frame:FindFirstChild("DistLabel")
					if distLbl then
						distLbl.Text = string.format("%.1f m", dist)
						distLbl.Visible = true
					end
				end
			else
				local frame = bb:FindFirstChildOfClass("Frame")
				if frame then
					local distLbl = frame:FindFirstChild("DistLabel")
					if distLbl then distLbl.Visible = false end
				end
			end

			-- Update name label visibility
			local frame = bb:FindFirstChildOfClass("Frame")
			if frame then
				local nameLbl = frame:FindFirstChild("NameLabel")
				if nameLbl then nameLbl.Visible = State.showName end
			end
		end

		-- Remove dead entries (reverse order to preserve indices)
		for i = #toRemove, 1, -1 do
			table.remove(espEntries, toRemove[i])
		end
	end)

	------------------------------------------------
	-- ⏱️ PERIODIC REFRESH LOOP
	-- Picks up new objects/players that spawned after init
	------------------------------------------------
	task.spawn(function()
		while true do
			task.wait(3)
			if State.playerEsp or State.carEsp or State.cashEsp then
				pcall(refreshESP)
			end

			-- Update ESP status label in UI
			pcall(function()
				if _G.HipHubDE and _G.HipHubDE.UI and _G.HipHubDE.UI.esp then
					local label = _G.HipHubDE.UI.esp.statusLabel
					if label then
						local anyActive = State.playerEsp or State.carEsp or State.cashEsp
						local color = anyActive and "#00e6ff" or "#ff4d4d"
						label.Text =
							"Status: <font color='" .. color .. "'>" ..
							(anyActive and "Active" or "Disabled") .. "</font>" ..
							"\nActive highlights: " .. #espEntries
					end
				end
			end)
		end
	end)

	-- Re-render ESP for newly joining players
	Players.PlayerAdded:Connect(function(p)
		if State.playerEsp then
			p.CharacterAdded:Connect(function(char)
				task.wait(0.5)
				pcall(refreshESP)
			end)
		end
	end)

	------------------------------------------------
	-- 🔧 STATE SETTER
	------------------------------------------------
	local function setState(newState)
		for k, v in pairs(newState) do
			State[k] = v
		end
		pcall(refreshESP)
	end

	------------------------------------------------
	-- 📤 EXPORT
	------------------------------------------------
	_G.HipHubESP = {
		setState = setState,
		getState = function() return State end,
		refresh  = refreshESP,
		clearAll = clearAll,
	}

	-- Apply persisted config & auto-start if enabled
	if _G.HipHubConfig and _G.HipHubConfig.esp then
		local cfg = _G.HipHubConfig.esp
		State.playerEsp    = cfg.playerEsp or false
		State.carEsp       = cfg.carEsp or false
		State.cashEsp      = cfg.cashEsp or false
		State.showDistance = cfg.showDistance ~= false
		State.showName     = cfg.showName ~= false
		if State.playerEsp or State.carEsp or State.cashEsp then
			pcall(refreshESP)
		end
	end

	print("[HipHub DE ESP] ESP system initialized!")
end)

if not success then
	warn("[HipHub DE ESP Error]:", err)
end
