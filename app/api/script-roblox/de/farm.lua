-- 💰 HipHub DE -- Auto Farm System
-- Driving Empire (Place ID: 9694510481)
-- Features: Auto Collect Cash Bags, Auto Bank Rob, Auto Delivery, One-shot Collect
-- Exports: _G.HipHubFarm

local success, err = pcall(function()
	local Players    = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local player     = Players.LocalPlayer

	------------------------------------------------
	-- 📦 STATE
	------------------------------------------------
	local State = {
		autoCollectCash = false,
		autoBankRob     = false,
		autoDelivery    = false,
		collectDelay    = 0.3,
		totalCollected  = 0,
	}

	-- Keywords used to detect cash objects in workspace
	-- These cover common naming patterns across DE versions
	local CASH_KEYWORDS = {
		"cashbag", "moneybag", "cash", "money", "dollar",
		"bill", "coin", "reward", "loot", "prize", "bonus",
		"pickup", "collectible", "earn", "income",
	}

	-- Keywords for bank / robbery interaction
	local BANK_KEYWORDS = {
		"bank", "vault", "safe", "treasury", "deposit", "rob",
	}

	-- ProximityPrompt action texts that indicate a rob interaction
	local ROB_PROMPT_KEYWORDS = {
		"rob", "vault", "steal", "break", "crack", "loot", "hack",
	}

	-- Keywords for delivery objects / NPCs
	local DELIVERY_KEYWORDS = {
		"deliver", "package", "cargo", "parcel", "order", "shipment",
		"pickup", "dropoff", "drop", "deliver",
	}

	------------------------------------------------
	-- 🔍 HELPERS
	------------------------------------------------
	local function getCharRoot()
		local char = player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function nameLower(obj)
		return obj.Name:lower()
	end

	local function matchesKeywords(name, keywords)
		local n = name:lower()
		for _, kw in ipairs(keywords) do
			if n:find(kw, 1, true) then return true end
		end
		return false
	end

	local function getCFrame(obj)
		if obj:IsA("BasePart") then
			return obj.CFrame
		elseif obj:IsA("Model") then
			if obj.PrimaryPart then
				return obj.PrimaryPart.CFrame
			end
			-- Fallback: first BasePart
			for _, v in ipairs(obj:GetChildren()) do
				if v:IsA("BasePart") then return v.CFrame end
			end
		end
		return nil
	end

	local function teleportTo(cf)
		local root = getCharRoot()
		if root then
			root.CFrame = cf + Vector3.new(0, 3, 0)
			return true
		end
		return false
	end

	------------------------------------------------
	-- 🔎 SCAN WORKSPACE FOR CASH OBJECTS
	-- Returns list sorted by distance (nearest first)
	------------------------------------------------
	local function findCashObjects()
		local list = {}
		local root = getCharRoot()

		for _, obj in ipairs(workspace:GetDescendants()) do
			if matchesKeywords(obj.Name, CASH_KEYWORDS) then
				if obj:IsA("BasePart") or obj:IsA("Model") then
					local cf = getCFrame(obj)
					if cf then
						local dist = root and (cf.Position - root.Position).Magnitude or math.huge
						table.insert(list, {obj = obj, cf = cf, dist = dist})
					end
				end
			end
		end

		-- Sort nearest first
		table.sort(list, function(a, b) return a.dist < b.dist end)
		return list
	end

	------------------------------------------------
	-- 🏦 FIND BANK LOCATION
	------------------------------------------------
	local function findBankCFrame()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if matchesKeywords(obj.Name, BANK_KEYWORDS) then
				local cf = getCFrame(obj)
				if cf then return cf end
			end
		end
		return nil
	end

	local function goToBank()
		local cf = findBankCFrame()
		if cf then
			return teleportTo(cf)
		end
		warn("[HipHub DE Farm] Bank not found in workspace")
		return false
	end

	------------------------------------------------
	-- ⚡ COLLECT ALL CASH (one-shot)
	------------------------------------------------
	-- collectAllCash: runs in full when called as one-shot (fromLoop=false),
	-- or aborts mid-run when auto collect is disabled (fromLoop=true).
	local function collectAllCash(fromLoop)
		local list = findCashObjects()
		local collected = 0

		for _, item in ipairs(list) do
			-- If running inside the auto-loop, bail when toggled off
			if fromLoop and not State.autoCollectCash then break end

			if item.obj and item.obj.Parent then
				teleportTo(item.cf)
				collected = collected + 1
				State.totalCollected = State.totalCollected + 1

				-- Interact with any ProximityPrompt on the object
				pcall(function()
					for _, pp in ipairs(item.obj:GetDescendants()) do
						if pp:IsA("ProximityPrompt") and pp.Enabled then
							if fireproximityprompt then
								fireproximityprompt(pp)
							end
						end
					end
				end)

				task.wait(math.max(State.collectDelay, 0.05))
			end
		end

		return collected
	end

	------------------------------------------------
	-- 🔁 AUTO COLLECT LOOP THREAD
	------------------------------------------------
	local collectThread = nil

	local function startCollectLoop()
		if collectThread then task.cancel(collectThread) end
		collectThread = task.spawn(function()
			while State.autoCollectCash do
				pcall(collectAllCash, true)  -- fromLoop=true: allows mid-run abort
				task.wait(math.max(State.collectDelay, 0.1))
			end
		end)
	end

	local function stopCollectLoop()
		if collectThread then
			task.cancel(collectThread)
			collectThread = nil
		end
	end

	------------------------------------------------
	-- 🏦 AUTO BANK ROB LOOP
	------------------------------------------------
	local bankThread = nil

	local function startBankRobLoop()
		if bankThread then task.cancel(bankThread) end
		bankThread = task.spawn(function()
			while State.autoBankRob do
				pcall(function()
					-- Teleport to bank area
					goToBank()
					task.wait(1.5)

					-- Fire any rob-related ProximityPrompts in range
					local root = getCharRoot()
					if not root then return end

					for _, obj in ipairs(workspace:GetDescendants()) do
						if obj:IsA("ProximityPrompt") and obj.Enabled then
							local actionText = (obj.ActionText or ""):lower()
							local objText    = (obj.Parent and obj.Parent.Name or ""):lower()

							local isRob = false
							for _, kw in ipairs(ROB_PROMPT_KEYWORDS) do
								if actionText:find(kw, 1, true) or objText:find(kw, 1, true) then
									isRob = true
									break
								end
							end

							if isRob then
								local promptPart = obj.Parent
								if promptPart and promptPart:IsA("BasePart") then
									local dist = (promptPart.Position - root.Position).Magnitude
									if dist < 50 then
										pcall(function()
											if fireproximityprompt then
												fireproximityprompt(obj)
											end
										end)
										task.wait(0.5)
									end
								end
							end
						end
					end
				end)
				task.wait(6) -- Cooldown between attempts
			end
		end)
	end

	local function stopBankRobLoop()
		if bankThread then
			task.cancel(bankThread)
			bankThread = nil
		end
	end

	------------------------------------------------
	-- 📦 AUTO DELIVERY LOOP
	-- Scans for delivery-related ProximityPrompts and interacts with them
	------------------------------------------------
	local deliveryThread = nil

	local function startDeliveryLoop()
		if deliveryThread then task.cancel(deliveryThread) end
		deliveryThread = task.spawn(function()
			while State.autoDelivery do
				pcall(function()
					local root = getCharRoot()
					if not root then return end

					for _, obj in ipairs(workspace:GetDescendants()) do
						if obj:IsA("ProximityPrompt") and obj.Enabled then
							local label = (obj.ActionText or ""):lower()
							local pname = (obj.Parent and obj.Parent.Name or ""):lower()
							local isDelivery = false

							for _, kw in ipairs(DELIVERY_KEYWORDS) do
								if label:find(kw, 1, true) or pname:find(kw, 1, true) then
									isDelivery = true
									break
								end
							end

							if isDelivery then
								local part = obj.Parent
								if part and part:IsA("BasePart") then
									-- Teleport to pickup/dropoff point
									teleportTo(part.CFrame)
									task.wait(0.3)
									pcall(function()
										if fireproximityprompt then
											fireproximityprompt(obj)
										end
									end)
									task.wait(0.5)
								end
							end
						end
					end
				end)
				task.wait(2)
			end
		end)
	end

	local function stopDeliveryLoop()
		if deliveryThread then
			task.cancel(deliveryThread)
			deliveryThread = nil
		end
	end

	------------------------------------------------
	-- 📊 STATUS UI UPDATER
	------------------------------------------------
	local function updateStatusUI()
		if not (_G.HipHubDE and _G.HipHubDE.UI and _G.HipHubDE.UI.farm) then return end
		local label = _G.HipHubDE.UI.farm.statusLabel
		if not label then return end

		local anyActive = State.autoCollectCash or State.autoBankRob or State.autoDelivery
		local color = anyActive and "#00e6ff" or "#ff4d4d"
		local statusText = anyActive and "Active" or "Inactive"

		label.Text =
			"Status: <font color='" .. color .. "'>" .. statusText .. "</font>" ..
			"\nTotal Collected: " .. State.totalCollected
	end

	-- Status loop (every second)
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(updateStatusUI)
		end
	end)

	------------------------------------------------
	-- 🔧 STATE SETTER
	------------------------------------------------
	local function setState(newState)
		for k, v in pairs(newState) do
			local prev = State[k]
			State[k] = v

			if k == "autoCollectCash" then
				if v then startCollectLoop() else stopCollectLoop() end
			elseif k == "autoBankRob" then
				if v then startBankRobLoop() else stopBankRobLoop() end
			elseif k == "autoDelivery" then
				if v then startDeliveryLoop() else stopDeliveryLoop() end
			end
		end
		pcall(updateStatusUI)
	end

	------------------------------------------------
	-- 📤 EXPORT
	------------------------------------------------
	_G.HipHubFarm = {
		setState       = setState,
		getState       = function() return State end,
		collectAllCash = collectAllCash,
		goToBank       = goToBank,
		findCashObjects = findCashObjects,
	}

	-- Apply persisted config
	if _G.HipHubConfig and _G.HipHubConfig.farm then
		local cfg = _G.HipHubConfig.farm
		State.collectDelay = cfg.collectDelay or 0.3
		-- Do NOT auto-start loops here — user must enable from UI
	end

	print("[HipHub DE Farm] Auto farm system initialized!")
end)

if not success then
	warn("[HipHub DE Farm Error]:", err)
end
