-- 💰 HipHub DDS — RideGO Taxi Auto-Farm Engine
-- Drag Drive Simulator (Place ID: 131378148336503)
-- Features: Fully Autonomous RideGO Taxi Farming, Void Bridging & Anti-Accident Stabilization

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"].content
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local player = Players.LocalPlayer

	------------------------------------------------
	-- 🛡️ SAFE PLATFORM IDLE NUDGE
	------------------------------------------------
	if not _G.HipHubNativeInputHeartbeatRunning then
		_G.HipHubNativeInputHeartbeatRunning = true
		task.spawn(function()
			while true do
				task.wait(25)
				pcall(function()
					-- 1. Universal Camera Nudge (Reset Engine Idle Timer)
					local cam = workspace.CurrentCamera
					if cam then
						local cf = cam.CFrame
						cam.CFrame = cf * CFrame.Angles(0, 0.0001, 0)
						task.delay(0.04, function()
							if cam then cam.CFrame = cf end
						end)
					end

					-- 2. Hardware OS Input Micro-Nudge (Cross-platform Android / Windows)
					if mousemoverel then
						pcall(mousemoverel, 0, 0)
					end
					if mouse1click then
						pcall(mouse1click)
					end
					if keypress and keyrelease then
						pcall(function()
							keypress(0x20)
							task.wait(0.02)
							keyrelease(0x20)
						end)
					end
				end)
			end
		end)
	end

	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		selectedVehicle = "",
		autoRideGO = false,
		taxiSpeed = 90,
		passengerBoardDelay = 3,
		tripPacing = true,
		autoRejoinOrders = 30,
		autoCourier = false,
		courierSpeed = 85,
		courierDropDelay = 4,
		courierPacing = true,
		courierAutoRejoinOrders = 10
	}
	if Config.selectedVehicle == nil then Config.selectedVehicle = "" end
	Config.tripPacing = true
	if _G.HipHubConfig and _G.HipHubConfig.farm then
		_G.HipHubConfig.farm.tripPacing = true
	end
	if Config.autoRejoinOrders == nil then Config.autoRejoinOrders = 30 end
	if Config.courierPacing == nil then Config.courierPacing = true end
	if Config.courierSpeed == nil then Config.courierSpeed = 85 end
	if Config.courierDropDelay == nil then Config.courierDropDelay = 4 end
	if Config.courierAutoRejoinOrders == nil then Config.courierAutoRejoinOrders = 10 end

	------------------------------------------------
	-- 🛵 DYNAMIC OWNED VEHICLE MANAGER
	------------------------------------------------
	local ownedVehiclesList = {}
	local vehicleDisplayToName = {}
	local vehicleNameToDisplay = {}
	local selectedFarmVehicle = (_G.HipHubConfig and _G.HipHubConfig.farm and _G.HipHubConfig.farm.selectedVehicle) or (Config.selectedVehicle) or ""
	local farmVehicleDropdown = nil

	local function getFarmVehicleName()
		if selectedFarmVehicle and selectedFarmVehicle ~= "" and selectedFarmVehicle ~= "Loading..." and selectedFarmVehicle ~= "No Vehicles Found" and selectedFarmVehicle ~= "Select Vehicle" then
			if vehicleDisplayToName[selectedFarmVehicle] then
				return vehicleDisplayToName[selectedFarmVehicle]
			end
			return selectedFarmVehicle
		end
		if #ownedVehiclesList > 0 then
			local first = ownedVehiclesList[1]
			return vehicleDisplayToName[first] or first
		end
		return "Yamahax-MioSporty"
	end

	local function fetchFarmOwnedVehicles(silent)
		pcall(function()
			local initCar = ReplicatedStorage:FindFirstChild("DealershipEvents") and ReplicatedStorage.DealershipEvents:FindFirstChild("InitializeCarData")
			if initCar then
				local data = initCar:InvokeServer()
				if data and type(data) == "table" then
					local newList = {}
					local d2n = {}
					local n2d = {}
					for _, car in ipairs(data) do
						local internalName = nil
						local displayName = nil
						if type(car) == "table" then
							internalName = car.Name or car.CarName or car.VehicleName or car.ModelName or car[1]
							displayName = car.DisplayName or internalName
						elseif type(car) == "string" then
							internalName = car
							displayName = car
						end
						if internalName and tostring(internalName) ~= "" then
							internalName = tostring(internalName)
							displayName = tostring(displayName or internalName)
							table.insert(newList, internalName)
							d2n[displayName] = internalName
							d2n[internalName] = internalName
							n2d[internalName] = displayName
						end
					end

					if #newList > 0 then
						ownedVehiclesList = newList
						vehicleDisplayToName = d2n
						vehicleNameToDisplay = n2d
						_G.HipHubOwnedVehicles = newList

						local found = false
						for _, v in ipairs(ownedVehiclesList) do
							if v == selectedFarmVehicle or d2n[selectedFarmVehicle] == v then
								found = true
								break
							end
						end
						if not found or selectedFarmVehicle == "" then
							selectedFarmVehicle = ownedVehiclesList[1]
							Config.selectedVehicle = selectedFarmVehicle
							if _G.HipHubConfig and _G.HipHubConfig.farm then
								_G.HipHubConfig.farm.selectedVehicle = selectedFarmVehicle
							end
							if _G.HipHubSaveConfig then
								_G.HipHubSaveConfig(true)
							end
						end

						if farmVehicleDropdown and farmVehicleDropdown.Refresh then
							farmVehicleDropdown.Refresh(ownedVehiclesList)
						end
						if not silent and UI and UI.Notify then
							UI.Notify("Kendaraan Terdeteksi", string.format("Ditemukan %d kendaraan milik akun.", #ownedVehiclesList), 2.5, "success")
						end
					end
				end
			end
		end)
	end
	task.spawn(function()
		task.wait(0.5)
		fetchFarmOwnedVehicles(true)
	end)

	------------------------------------------------
	-- 🚕 SHARED RIDEGO TAXI STATE & REMOTE CONTROLLER
	------------------------------------------------
	local TaxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 10)
	local TaxiEvent = TaxiAssets and TaxiAssets:WaitForChild("Events", 10) and TaxiAssets.Events:WaitForChild("TaxiEvent", 10)

	local function getTaxiEvent()
		if TaxiEvent then return TaxiEvent end
		local assets = ReplicatedStorage:FindFirstChild("TaxiAssets")
		local ev = assets and assets:FindFirstChild("Events") and assets.Events:FindFirstChild("TaxiEvent")
		TaxiEvent = ev
		return ev
	end

	local taxiActive          = false
	local taxiBusy            = false
	local taxiState           = "IDLE"
	local taxiToken           = nil
	local lastCompletedToken  = nil
	local taxiPickupPos       = nil
	local taxiDropPos         = nil
	local passengerSeated     = false
	local taxiOverlayPoller   = nil
	local isResettingTaxi     = false
	local isRespawning        = false
	local dropoffStuckTime    = nil
	local taxiPickupAddr      = ""
	local taxiDropAddr        = ""
	local isRideGoDutyOnline  = false

	local courierActive           = false
	local autoRideGoToggle        = nil
	local restartAutoRideGoToggle = nil
	local autoCourierToggle       = nil
	local toggleAutoCourier       = nil
	local toggleAutoRideGO        = nil

	local triggerSafeRespawn      = nil
	local getPlayerVehicle        = nil
	local spawnFarmVehicle        = nil
	local spawnTaxiBike           = nil
	local changeTeam              = nil
	local mountBike               = nil
	local ensureDriverSeated      = nil
	local recoverRideGoDuty       = nil
	local cancelActiveDrive       = nil
	local getActiveCourierTarget  = nil
	local hasCourierPackage       = nil
	local glidePlayerAcrossVoid = nil
	local ensureCarrierSeat     = nil
	local destroyCarrierSeat    = nil
	local persistentCarrierSeat = nil
	local persistentCarrierWeld = nil
	local arrivedViaSeatCarrier = false
	local startPhoneOverlayPoller = nil

	local function updateBotActivity(statusText, customColor)
		_G.HipHubBotActivityStatus = statusText or "Menunggu Orderan Masuk..."
		_G.HipHubBotActivityColor  = customColor or Color3.fromRGB(0, 255, 170)
	end

	local function setTaxiState(newState, customText, customColor)
		taxiState = newState
		if customText then
			updateBotActivity(customText, customColor)
		elseif newState == "CONNECTING" then
			updateBotActivity("Menghubungkan ke RideGO...", Color3.fromRGB(255, 200, 50))
		elseif newState == "WAITING_FOR_NEXT_ORDER" then
			updateBotActivity("Menunggu Orderan Masuk...", Color3.fromRGB(0, 255, 170))
		elseif newState == "PICKING_UP" then
			updateBotActivity("Sedang Menjemput Penumpang...", Color3.fromRGB(0, 212, 255))
		elseif newState == "DRIVING_TO_DESTINATION" then
			updateBotActivity("Mengantar Penumpang ke Tujuan...", Color3.fromRGB(0, 212, 255))
		elseif newState == "PACING" then
			updateBotActivity("Pacing Waktu Sah Server...", Color3.fromRGB(255, 180, 50))
		elseif newState == "DROPPING_OFF" then
			updateBotActivity("Menunggu Penumpang Turun...", Color3.fromRGB(150, 110, 255))
		elseif newState == "IDLE" then
			updateBotActivity("Bot Idle (Auto-Farm OFF)", Color3.fromRGB(160, 175, 200))
		end
	end

	local function isSasanaKridaTrip()
		local pAddr = tostring(taxiPickupAddr or ""):lower()
		local dAddr = tostring(taxiDropAddr or ""):lower()
		if pAddr:find("sasana") or pAddr:find("krida") or dAddr:find("sasana") or dAddr:find("krida") then
			return true
		end

		local isSasana = false
		pcall(function()
			local pg = player:FindFirstChild("PlayerGui")
			local phone = pg and pg:FindFirstChild("Phone")
			local rideGO = phone and phone:FindFirstChild("RideGO", true)
			local appFrame = rideGO and rideGO:FindFirstChild("AppFrame")
			local ordersPage = appFrame and appFrame:FindFirstChild("PageContainer") and appFrame.PageContainer:FindFirstChild("OrdersPage")
			if ordersPage and ordersPage.Visible then
				local routeCard = ordersPage:FindFirstChild("RouteCard", true)
				if routeCard then
					for _, desc in ipairs(routeCard:GetDescendants()) do
						if desc:IsA("TextLabel") and desc.Visible then
							local txt = desc.Text:lower()
							if txt:find("sasana") or txt:find("krida") then
								isSasana = true
								return
							end
						end
					end
				end
			end
		end)
		return isSasana
	end

	local function isRouteVerificationStuck()
		local found = false

		-- 1. Scan NotificationFrame di PlayerGui (Sangat cepat & zero-lag)
		pcall(function()
			local pGui = player:FindFirstChild("PlayerGui")
			local notifFrame = pGui and (pGui:FindFirstChild("NotificationFrame", true) or pGui:FindFirstChild("Notification", true))
			if notifFrame then
				for _, g in ipairs(notifFrame:GetDescendants()) do
					if (g:IsA("TextLabel") or g:IsA("TextButton")) and g.Visible then
						local txt = (g.Text or ""):lower()
						if txt:find("verifying your trip route")
							or txt:find("memverifikasi rute")
							or (txt:find("verif") and txt:find("route"))
							or (txt:find("verif") and txt:find("rute"))
						then
							found = true
							return
						end
					end
				end
			end
		end)
		if found then return true end

		-- 2. Scan StatusStrip di Phone RideGO OrdersPage
		pcall(function()
			local pGui = player:FindFirstChild("PlayerGui")
			local phone = pGui and pGui:FindFirstChild("Phone")
			local rideGO = phone and phone:FindFirstChild("RideGO", true)
			local appFrame = rideGO and rideGO:FindFirstChild("AppFrame")
			local ordersPage = appFrame and appFrame:FindFirstChild("PageContainer") and appFrame.PageContainer:FindFirstChild("OrdersPage")
			if ordersPage and ordersPage.Visible then
				local statusStrip = ordersPage:FindFirstChild("StatusStrip", true)
				local subText = statusStrip and statusStrip:FindFirstChild("SubText")
				if subText and subText.Visible then
					local txt = (subText.Text or ""):lower()
					if txt:find("verifying your trip route")
						or txt:find("memverifikasi rute")
						or (txt:find("verif") and txt:find("route"))
						or (txt:find("verif") and txt:find("rute"))
					then
						found = true
						return
					end
				end
			end
		end)
		if found then return true end

		-- 3. Fallback scan ringkas di PlayerGui Notification / Dialog frames
		pcall(function()
			local pGui = player:FindFirstChild("PlayerGui")
			if pGui then
				for _, name in ipairs({ "NotificationGui", "Notification", "DialogGui", "AlertGui" }) do
					local sg = pGui:FindFirstChild(name)
					if sg and sg:IsA("ScreenGui") and sg.Enabled then
						for _, g in ipairs(sg:GetDescendants()) do
							if (g:IsA("TextLabel") or g:IsA("TextButton")) and g.Visible then
								local txt = (g.Text or ""):lower()
								if txt:find("verifying your trip route")
									or txt:find("memverifikasi rute")
									or (txt:find("verif") and txt:find("route"))
									or (txt:find("verif") and txt:find("rute"))
								then
									found = true
									return
								end
							end
						end
					end
				end
			end
		end)

		return found
	end

	-- 🔄 Unified Toggle Restart Engine (Mematikan toggle UI -> tunggu 1.2s -> nyalakan lagi)
	restartAutoRideGoToggle = function(reason)
		if isResettingTaxi or courierActive or _G.HipHubCourierActive then return end
		isResettingTaxi = true

		-- 1. Hentikan pergerakan motor seketika
		if cancelActiveDrive then
			cancelActiveDrive()
		end

		-- 2. Matikan toggle di UI & jalankan shutdown sequence (CancelTrip, CancelOrder, GoOffline, Citizen)
		if autoRideGoToggle and autoRideGoToggle.Set then
			autoRideGoToggle.Set(false)
		elseif toggleAutoRideGO then
			toggleAutoRideGO(false)
		end

		-- 3. Jeda 1.2 detik agar server memproses dan penumpang benar-benar hilang
		task.wait(1.2)

		-- 4. Nyalakan kembali toggle di UI HANYA jika Courier tidak sedang aktif!
		if not courierActive and not _G.HipHubCourierActive then
			if autoRideGoToggle and autoRideGoToggle.Set then
				autoRideGoToggle.Set(true)
			elseif toggleAutoRideGO then
				toggleAutoRideGO(true)
			end
		end

		isResettingTaxi = false
	end

	local function resetTaxiDutyCycle(specificToken, reason)
		restartAutoRideGoToggle(reason)
	end

	------------------------------------------------
	-- 🛠️ 1. VEHICLE & MOVEMENT CORE ENGINE
	------------------------------------------------
	local currentDriveConn = nil
	local isDrivingActive  = false

	-- 🛡️ Adonis-Safe Anti-AFK Engine (Zero Disallowed Services, 100% Undetectable)
	task.spawn(function()
		while true do
			task.wait(35)
			pcall(function()
				if mousemoverel then
					mousemoverel(0, 1)
					task.wait(0.03)
					mousemoverel(0, -1)
				elseif mouse1press then
					mouse1press()
					task.wait(0.03)
					mouse1release()
				else
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum and hum.SeatPart then
						local seat = hum.SeatPart
						if seat:IsA("VehicleSeat") then
							seat.SteerFloat = 0.001
							task.wait(0.03)
							seat.SteerFloat = 0
						end
					elseif hum then
						hum:ChangeState(Enum.HumanoidStateType.Running)
					end
				end
			end)
		end
	end)

	-- 🌊 GLOBAL WATER GUARD: Heartbeat independen yang selalu aktif (bahkan di luar loop drive)
	-- Memastikan motor & player TIDAK PERNAH menyentuh Terrain Water dalam kondisi apapun.
	-- Ini adalah lapisan pertahanan pertama (pre-drive) untuk mencegah Error 263 Connection Timed Out.
	if not _G.HipHubWaterGuardRunning then
		_G.HipHubWaterGuardRunning = true
		local waterGuardParams = RaycastParams.new()
		waterGuardParams.FilterType = Enum.RaycastFilterType.Exclude
		waterGuardParams.IgnoreWater = false

		local cachedWaterFilter = table.create(2)

		RunService.Heartbeat:Connect(function()
			pcall(function()
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				-- Disable Swimming state setiap frame agar tidak ada fluid physics sama sekali
				if hum then
					hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
				end

				local seat = hum and hum.SeatPart
				local car = seat and seat:FindFirstAncestorOfClass("Model")
				if not car or not seat then return end

				local carPos = car:GetPivot().Position

				-- Deteksi air di bawah motor (0 - 4 stud di bawah posisi saat ini)
				cachedWaterFilter[1] = car
				cachedWaterFilter[2] = char
				waterGuardParams.FilterDescendantsInstances = cachedWaterFilter
				local wHit = workspace:Raycast(
					Vector3.new(carPos.X, carPos.Y + 2, carPos.Z),
					Vector3.new(0, -6, 0),
					waterGuardParams
				)
				if wHit and wHit.Material == Enum.Material.Water then
					-- Air terdeteksi! Angkat motor ke atas permukaan air seketika
					local safeY = wHit.Position.Y + 3.0
					local safePos = Vector3.new(carPos.X, safeY, carPos.Z)
					-- Buat safety plate agar motor tidak jatuh lagi
					local plate = workspace:FindFirstChild("__DdsSafetyPlate")
					if not plate then
						plate = Instance.new("Part")
						plate.Name = "__DdsSafetyPlate"
						plate.Anchored = true
						plate.CanCollide = true
						plate.Transparency = 1
						plate.CastShadow = false
						plate.Material = Enum.Material.Concrete
						pcall(function() plate.Parent = workspace end)
					end
					plate.Size = Vector3.new(80, 4, 80)
					plate.CFrame = CFrame.new(carPos.X, safeY - 2, carPos.Z)
					-- Teleport motor ke atas plate
					pcall(function() car:PivotTo(CFrame.new(safePos)) end)
					-- Zero semua kecepatan untuk menghindari NaN physics
					for _, part in ipairs(car:GetDescendants()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = Vector3.zero
							part.AssemblyAngularVelocity = Vector3.zero
						end
					end
				end
			end)
		end)
	end


	cancelActiveDrive = function()
		if currentDriveConn then
			pcall(function() currentDriveConn:Disconnect() end)
			currentDriveConn = nil
		end
		isDrivingActive = false
	end

	triggerSafeRespawn = function(reason)
		if isRespawning then return false end
		isRespawning = true

		local ok, err = pcall(function()
			updateBotActivity("Menunggu Respawn Karakter...", Color3.fromRGB(255, 180, 50))

			-- 1. Hentikan total navigasi & gerak kendaraan lama
			if cancelActiveDrive then
				cancelActiveDrive()
			end
			pcall(function()
				local car, seat = getPlayerVehicle()
				if car then
					for _, part in ipairs(car:GetDescendants()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = Vector3.zero
							part.AssemblyAngularVelocity = Vector3.zero
						end
					end
				end
			end)

			-- 2. Despawn motor lama agar tidak tersisa di bibir jurang / void
			pcall(function()
				local car, _ = getPlayerVehicle()
				local sc = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
				local despawnEvent = sc and sc:FindFirstChild("DespawnCar")
				if despawnEvent then
					despawnEvent:FireServer()
				end
				if car and car.Parent then
					car:Destroy()
				end
			end)

			-- 3. Reset karakter via Humanoid (legal native Roblox reset, bypass HealthGuard)
			local oldChar = player.Character
			pcall(function()
				local hum = oldChar and oldChar:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = 0
				end
				if oldChar then
					oldChar:BreakJoints()
				end
			end)

			-- 4. FOKUS TUNGGU RESPAWN: Tunggu hingga karakter baru benar-benar muncul dan hidup stabil
			local t0 = os.clock()
			while true do
				local curChar = player.Character
				if curChar and curChar ~= oldChar and curChar.Parent then
					local hum = curChar:FindFirstChildOfClass("Humanoid")
					local hrp = curChar:FindFirstChild("HumanoidRootPart")
					if hum and hrp and hum.Health > 0 then
						break
					end
				end
				if os.clock() - t0 > 12.0 then
					warn("[HipHub DDS] triggerSafeRespawn: Timeout menunggu respawn karakter baru")
					break
				end
				task.wait(0.25)
			end

			-- Jeda 1.5 detik agar physics karakter dan streaming map kota asal stabil
			updateBotActivity("Menstabilkan Posisi Karakter...", Color3.fromRGB(255, 200, 50))
			task.wait(1.5)

			-- 5. SPAWN MOTOR BARU: Karakter sudah respawn, panggil motor baru
			updateBotActivity("Memanggil Motor Baru...", Color3.fromRGB(0, 212, 255))
			if spawnTaxiBike then
				spawnTaxiBike()
			end

			-- 6. DUDUK DI DRIVER SEAT MOTOR: Segera dudukkan karakter ke motor
			updateBotActivity("Menaiki Kursi Pengemudi...", Color3.fromRGB(0, 212, 255))
			local seated = false
			for sitAttempt = 1, 6 do
				if ensureDriverSeated and ensureDriverSeated(true) then
					seated = true
					break
				elseif mountBike and mountBike(true) then
					local curChar = player.Character
					local curHum = curChar and curChar:FindFirstChildOfClass("Humanoid")
					if curHum and curHum.SeatPart then
						seated = true
						break
					end
				end
				task.wait(0.5)
			end

			-- 7. Jika sedang Kurir & belum punya target, refresh job agar server memberi target baru
			if courierActive then
				local hasTarget = (getActiveCourierTarget and getActiveCourierTarget() ~= nil)
				local hasPkg = (hasCourierPackage and hasCourierPackage())
				if not hasTarget and not hasPkg then
					pcall(function()
						local deliverySys = ReplicatedStorage:FindFirstChild("Delivery System")
						local deliverySettingsFolder = deliverySys and deliverySys:FindFirstChild("Settings")
						local reqJob = deliverySettingsFolder and (deliverySettingsFolder:FindFirstChild("RequestJobUpdate") or deliverySettingsFolder:FindFirstChild("ServiceEvent"))
						if reqJob then
							if reqJob.Name == "RequestJobUpdate" then
								reqJob:FireServer()
							else
								reqJob:FireServer("RequestJobUpdate")
							end
						end
					end)
				end
			end
		end)

		if not ok then
			warn("[HipHub DDS] triggerSafeRespawn error:", tostring(err))
		end

		task.wait(0.5)
		isRespawning = false
		return true
	end



	local function getRootPart()
		local char = player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function despawnUnwantedVehicle(model)
		pcall(function()
			local sc = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
			local despawnEvent = sc and sc:FindFirstChild("DespawnCar")
			if despawnEvent then
				despawnEvent:FireServer()
			end
			if model and model.Parent then
				model:Destroy()
			end
		end)
	end

	local function getVehicleRootModel(inst)
		if not inst then return nil end
		local cur = inst
		while cur and cur.Parent and cur.Parent ~= workspace and cur.Parent ~= game do
			cur = cur.Parent
		end
		if cur and cur:IsA("Model") and cur ~= player.Character then
			return cur
		end
		return nil
	end

	local function despawnUnwantedVehicle(model)
		pcall(function()
			local sc = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
			local despawnEvent = sc and sc:FindFirstChild("DespawnCar")
			if despawnEvent then
				despawnEvent:FireServer()
			end
			if model and model.Parent then
				model:Destroy()
			end
		end)
	end

	local function isUnwantedVehicle(inst)
		local model = getVehicleRootModel(inst) or inst
		if not model or not model:IsA("Model") or model == player.Character then return false end
		local mName = model.Name:lower()
		local pName = player.Name:lower()
		local isOwner = (mName:sub(1, #pName) == pName) or (mName:find(pName, 1, true) ~= nil)
		if not isOwner then return false end

		local carNameData = (model:GetAttribute("CarNameData") or ""):lower()
		local activeVehicle = getFarmVehicleName():lower()

		-- Jika cocok dengan kendaraan yang dipilih user, whitelist 100%
		if activeVehicle ~= "" and activeVehicle ~= "loading..." and activeVehicle ~= "no vehicles found" and activeVehicle ~= "select vehicle" then
			if carNameData ~= "" and (carNameData == activeVehicle or carNameData:find(activeVehicle, 1, true) or activeVehicle:find(carNameData, 1, true)) then
				return false
			end
			if mName:find(activeVehicle, 1, true) or activeVehicle:find(mName, 1, true) then
				return false
			end
		end

		-- Jika bukan kendaraan yang dipilih dan ada kendaraan lain yang jelas truk / canter saat user memilih motor:
		if activeVehicle ~= "" and not (activeVehicle:find("canter") or activeVehicle:find("truk") or activeVehicle:find("truck") or activeVehicle:find("fuso") or activeVehicle:find("bus")) then
			if carNameData:find("canter") or carNameData:find("truk") or carNameData:find("truck") or carNameData:find("fuso") or carNameData:find("bus") then
				return true
			end
			if mName:find("canter") or mName:find("truk") or mName:find("truck") or mName:find("fuso") or mName:find("bus") then
				return true
			end
		end

		return false
	end

	local function isMotorcycle(model)
		if not model or not model:IsA("Model") or model == player.Character then return false end
		local mName = model.Name:lower()
		local pName = player.Name:lower()
		local isOwner = (mName:sub(1, #pName) == pName) or (mName:find(pName, 1, true) ~= nil)
		if not isOwner then return false end
		if isUnwantedVehicle(model) then return false end

		local hasDriveSeat = model:FindFirstChild("DriveSeat", true) ~= nil or model:FindFirstChildWhichIsA("VehicleSeat", true) ~= nil
		if not hasDriveSeat then return false end

		return true
	end

	getPlayerVehicle = function()
		local char = player.Character
		if not char then return nil, nil end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart then
			local seat = humanoid.SeatPart
			local model = getVehicleRootModel(seat) or seat:FindFirstAncestorOfClass("Model")
			if model and not isUnwantedVehicle(model) then
				return model, seat
			else
				humanoid.Sit = false
				if model and model ~= char then
					despawnUnwantedVehicle(model)
				end
			end
		end

		-- 1. Cari kendaraan milik player di workspace (dalam radius wajar <= 200 studs)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local pName = player.Name:lower()
		local bestModel, bestSeat, bestDist = nil, nil, 999999

		for _, c in ipairs(workspace:GetChildren()) do
			if c:IsA("Model") and c ~= char then
				local mName = c.Name:lower()
				local isOwner = (mName:sub(1, #pName) == pName) or (mName:find(pName, 1, true) ~= nil)
				if isOwner then
					if not isUnwantedVehicle(c) then
						local seat = c:FindFirstChild("DriveSeat", true)
							or c:FindFirstChildWhichIsA("VehicleSeat", true)
						if seat then
							local dist = hrp and (c:GetPivot().Position - hrp.Position).Magnitude or 0
							if dist < bestDist and dist <= 200 then
								bestDist = dist
								bestModel = c
								bestSeat = seat
							end
						end
					else
						despawnUnwantedVehicle(c)
					end
				end
			end
		end

		if bestModel and bestSeat then
			return bestModel, bestSeat
		end

		return nil, nil
	end

	local MOTOR_PIVOT_HEIGHT_OFFSET = 2.05

	-- Spawns an invisible collision safety plate underneath destination/vehicle
	local function ensureSafetyPlate(pos, width)
		width = width or 80
		local plate = workspace:FindFirstChild("__DdsSafetyPlate")
		if not plate then
			plate = Instance.new("Part")
			plate.Name = "__DdsSafetyPlate"
			plate.Anchored = true
			plate.CanCollide = true
			plate.Transparency = 1
			plate.CastShadow = false
			plate.Material = Enum.Material.Concrete
			pcall(function() plate.Parent = workspace end)
		end
		plate.Size = Vector3.new(width, 4, width)
		-- Posisikan permukaan atas safety plate tepat 0.2 stud di bawah permukaan tanah / ban motor:
		-- pos.Y adalah target pivot motor, sehingga ground level = pos.Y - MOTOR_PIVOT_HEIGHT_OFFSET
		local groundLevel = pos.Y - MOTOR_PIVOT_HEIGHT_OFFSET
		local plateTopY = groundLevel - 0.2
		plate.CFrame = CFrame.new(pos.X, plateTopY - 2.0, pos.Z)
		return plate
	end

	local function destroySafetyPlate()
		pcall(function()
			local plate = workspace:FindFirstChild("__DdsSafetyPlate")
			if plate then
				plate:Destroy()
			end
		end)
	end

	spawnFarmVehicle = function()
		local SpawnCarEvt = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
		local remote = SpawnCarEvt and SpawnCarEvt:FindFirstChild("SpawnCar")
		if not remote then return end
		local targetBike = getFarmVehicleName()
		if not targetBike or targetBike == "" or targetBike == "Loading..." or targetBike == "No Vehicles Found" or targetBike == "Select Vehicle" then
			return
		end
		pcall(function() remote:FireServer(targetBike) end)
		task.wait(1.5)
	end
	spawnTaxiBike = spawnFarmVehicle

	local function findRidePrompt()
		local car, seat = getPlayerVehicle()
		if not car or not seat then
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local pName = player.Name:lower()
			for _, c in ipairs(workspace:GetChildren()) do
				if c:IsA("Model") and c ~= player.Character then
					local mName = c.Name:lower()
					local isOwner = (mName:sub(1, #pName) == pName) or (mName:find(pName, 1, true) ~= nil)
					if isOwner and not isUnwantedVehicle(c) then
						local s = c:FindFirstChild("DriveSeat", true) or c:FindFirstChildWhichIsA("VehicleSeat", true)
						if s then
							local dist = hrp and (c:GetPivot().Position - hrp.Position).Magnitude or 0
							if dist <= 200 then
								car = c
								seat = s
								break
							end
						end
					end
				end
			end
		end

		if not car then return nil, nil end

		local seatPart = (car and car:FindFirstChild("DriveSeat", true)) or seat or (car and (car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)))
		if not seatPart then return nil, nil end

		-- 1. Search prompt inside DriveSeat directly
		local prompt = seatPart:FindFirstChildWhichIsA("ProximityPrompt", true)

		-- 2. Search prompt in entire car prioritizing driver action text
		if not prompt and car then
			for _, p in ipairs(car:GetDescendants()) do
				if p:IsA("ProximityPrompt") then
					local pn = p.Name:lower()
					local an = (p.ActionText or ""):lower()
					local on = (p.ObjectText or ""):lower()
					if not (pn:find("lock") or pn:find("tuner") or pn:find("trunk") or pn:find("bagasi") or pn:find("kickstand") or an:find("lock") or on:find("lock") or an:find("penumpang") or an:find("passenger")) then
						prompt = p
						break
					end
				end
			end
		end

		return prompt, seatPart
	end

	local function neutralizeBikeHazards(car)
		pcall(function()
			local char = player.Character
			if char then
				for _, s in ipairs(char:GetDescendants()) do
					if s:IsA("BasePart") then
						s.CanCollide = false
					end
				end
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
					if hum.Health < hum.MaxHealth then
						pcall(function() hum.Health = hum.MaxHealth end)
					end
				end
			end
		end)
	end

	-- 🛡️ Anti-Death & Godmode Health Guard Engine (100% Zero-Damage Assurance)
	local function initHealthGuard()
		local function bindCharacter(char)
			if not char then return end
			local hum = char:WaitForChild("Humanoid", 5) or char:FindFirstChildOfClass("Humanoid")
			if not hum then return end

			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)

			hum.HealthChanged:Connect(function(newH)
				if isRespawning then return end
				if newH < hum.MaxHealth and (courierActive or taxiActive) then
					pcall(function() hum.Health = hum.MaxHealth end)
				end
			end)
		end

		if player.Character then
			task.spawn(function() bindCharacter(player.Character) end)
		end
		player.CharacterAdded:Connect(function(char)
			task.spawn(function() bindCharacter(char) end)
		end)
	end
	task.spawn(initHealthGuard)

	mountBike = function(ignoreRespawning)
		if isRespawning and not ignoreRespawning then return false end
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return false end

		-- Jika sudah duduk di kendaraan yang sah:
		if hum.SeatPart then
			local rootModel = getVehicleRootModel(hum.SeatPart)
			if rootModel and not isUnwantedVehicle(rootModel) then
				return true
			else
				hum.Sit = false
				if rootModel then despawnUnwantedVehicle(rootModel) end
				task.wait(0.3)
			end
		end

		-- Reset sitting state palsu di udara
		hum.Sit = false

		local prompt, seatPart = findRidePrompt()
		if not seatPart then
			spawnFarmVehicle()
			local spawnWait = os.clock()
			while not seatPart and (os.clock() - spawnWait < 4.0) do
				task.wait(0.25)
				prompt, seatPart = findRidePrompt()
			end
			if not seatPart then
				warn("[HipHub DDS] mountBike: seatPart tetap tidak ditemukan setelah spawnFarmVehicle")
				return false
			end
		end

		local car = getVehicleRootModel(seatPart) or seatPart.Parent
		if car then
			neutralizeBikeHazards(car)
		end

		pcall(function() seatPart.Disabled = false end)

		-- Pindahkan posisi player tepat menempel di atas kursi motor
		root.CFrame = seatPart.CFrame + Vector3.new(0, 0.5, 0)
		task.wait(0.08)

		-- Loop agresif verifikasi duduk (maksimal 3.0 detik)
		local sitStart = os.clock()
		while not hum.SeatPart and (os.clock() - sitStart < 3.0) do
			-- 1. Trigger ProximityPrompt pengemudi jika ada
			if prompt then
				pcall(function()
					if fireproximityprompt then
						fireproximityprompt(prompt)
					elseif prompt.InputHoldBegin then
						prompt:InputHoldBegin()
						task.wait(0.05)
						prompt:InputHoldEnd()
					end
				end)
			end

			-- 2. Trigger native touch event via firetouchinterest
			pcall(function()
				if firetouchinterest then
					firetouchinterest(root, seatPart, 0)
					task.wait(0.02)
					firetouchinterest(root, seatPart, 1)
				end
			end)

			-- 3. Native seat sit call
			pcall(function()
				seatPart:Sit(hum)
			end)

			root.CFrame = seatPart.CFrame + Vector3.new(0, 0.5, 0)
			task.wait(0.2)
		end

		local isSeated = (hum.SeatPart ~= nil)
		return isSeated
	end

	-- Safety check: pastikan player duduk di kursi pengemudi.
	ensureDriverSeated = function(ignoreRespawning)
		if isRespawning and not ignoreRespawning then return false end
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart then return true end

		for attempt = 1, 3 do
			local ok = mountBike(ignoreRespawning)
			if ok then
				task.wait(0.3)
				local h2 = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if h2 and h2.SeatPart then
					return true
				end
			end
			task.wait(0.5)
		end

		warn("[HipHub DDS] ensureDriverSeated: gagal duduk setelah 3 percobaan")
		return false
	end

	-- 🔄 Auto-Duty Health & Seat Recovery Engine (Anti-AFK & Redfinger Duty Reconnector)
	recoverRideGoDuty = function()
		if not taxiActive or taxiBusy or isResettingTaxi or isRespawning then return end

		pcall(function()
			-- 1. Pastikan Tim adalah "RideGO Driver"
			local curTeam = player.Team and player.Team.Name or ""
			if not curTeam:lower():find("ridego") then
				updateBotActivity("Bergabung ke Tim RideGO...", Color3.fromRGB(0, 212, 255))
				if changeTeam then
					changeTeam("RideGO Driver")
				end
				-- Tunggu konfirmasi server bahwa player.Team benar-benar sudah menjadi RideGO Driver
				local waitStart = os.clock()
				while taxiActive and (os.clock() - waitStart < 4.5) do
					local tName = player.Team and player.Team.Name or ""
					if tName:lower():find("ridego") then
						break
					end
					task.wait(0.25)
				end
			end

			-- 🛡️ Verifikasi Mutlak: Jika masih belum berada di tim RideGO Driver, JANGAN tembak GoOnline!
			local verifyTeam = player.Team and player.Team.Name or ""
			if not verifyTeam:lower():find("ridego") then
				updateBotActivity("Menunggu Cooldown Tim RideGO...", Color3.fromRGB(255, 180, 50))
				task.delay(2.0, function()
					if taxiActive and not taxiBusy and recoverRideGoDuty then
						recoverRideGoDuty()
					end
				end)
				return
			end

			-- 2. Pastikan Motor Ada & Pengemudi Duduk di Kursi
			local char = player.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if not (hum and hum.SeatPart) then
				updateBotActivity("Redfinger: Menaiki Motor...", Color3.fromRGB(0, 212, 255))
				local ok = ensureDriverSeated()
				if not ok then
					spawnTaxiBike()
					task.wait(1.5)
					ensureDriverSeated()
				end
				task.wait(0.5)
			end

			-- Verifikasi duduk: pastikan player benar-benar duduk sebelum mengaktifkan duty
			char = player.Character
			hum  = char and char:FindFirstChildOfClass("Humanoid")
			if not (hum and hum.SeatPart) then
				task.delay(1.5, function()
					if taxiActive and not taxiBusy and recoverRideGoDuty then
						recoverRideGoDuty()
					end
				end)
				return
			end

			-- 3. Kirim Remote Duty Activation
			local ev = getTaxiEvent()
			if ev then
				ev:FireServer("DismissIntro")
				task.wait(0.4)
				ev:FireServer("GoOnline")
				isRideGoDutyOnline = true
				updateBotActivity("RideGO Online (Menunggu Order)", Color3.fromRGB(0, 255, 140))
			end
		end)
	end

	local function requestStreamAsync(pos)
		pcall(function()
			if player and player.RequestStreamAroundAsync then
				task.spawn(function()
					pcall(function() player:RequestStreamAroundAsync(pos, 2) end)
				end)
			end
		end)
	end

	-- 🧹 UNIVERSAL DESTROY ALL BUILDINGS & OBSTACLES (Ground & Roads Only Mode)
	local function isObstacleName(name)
		if not name then return false end
		local n = name:upper()
		-- 🛡️ PROTEKSI MUTLAK KLATEN & SAWAH: BUKAN RINTANGAN!
		if n:find("KLATEN") or n:find("SAWAH") then
			return false
		end
		if n:find("BANGUNAN") or n:find("BUILDING") or n:find("RUMAH") or n:find("GEDUNG")
			or n:find("HOUSE") or n:find("HOTEL") or n:find("HARRIZON") or n:find("POHON")
			or n:find("TREE") or n:find("LAMPU") or n:find("LAMP") or n:find("PROPS")
			or n:find("SETTING") or n:find("BENDERA") or n:find("CANOPY") or n:find("TENT")
			or n:find("JOB") or n:find("POLICE") or n:find("BARISTA") or n:find("PIC")
			or n:find("EVENT") or n:find("BOARD") or n:find("DONATION") or n:find("SHOP")
			or n:find("CAFE") or n:find("RESTAURANT") or n:find("KFC") or n:find("MALL")
			or n:find("TOWN") or n:find("SQUARE") or n:find("MOLDING") or n:find("MEJA")
			or n:find("KURSI") or n:find("TABLE") or n:find("GATE") or n:find("GARAGE")
			or n:find("DEALER") or n:find("PAGAR") or n:find("FENCE") or n:find("BARRIER")
			or n:find("WALL") or n:find("DINDING") or n:find("ROOF")
			or n:find("ATAP") or n:find("TV") or n:find("COMPUTER") or n:find("PENJUAL")
			or n:find("SATLANTAS") or n == "RS" or n:find("INDOMART") or n:find("PLATINUM")
			or n:find("GATAU") or n:find("PJL") or n:find("STOPPER") or n:find("MACHINE")
			or n:find("WARUNG") or n:find("TOKO") or n:find("JOGLO") or n:find("STADION")
			or n:find("SHIRT") or n:find("MEDKIT") or n:find("BILLBOARD") or n:find("CONE")
			or n:find("PANGGUNG") or n:find("HELMET") or n:find("SHOWCASE") or n:find("TITIK_KUMPUL")
			or n:find("FLAG") or n:find("SIGN") or n:find("KANOPY")
		then
			return true
		end
		return false
	end

	local function isRoadOrGround(obj)
		if not obj then return false end
		if obj:IsA("Terrain") then return true end
		if obj.Name == "__DdsSafetyPlate" then return true end

		-- 🛡️ Proteksi Mutlak Klaten & Sawah sebagai Ground Sah
		local fullName = obj:GetFullName():upper()
		if fullName:find("JL_KLATEN") or fullName:find("SAWAH") or (fullName:find("BUILDING_KLATEN") and not fullName:find("WATER") and not fullName:find("AIR")) then
			if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then return false end
			local name = obj.Name:upper()
			if name:find("AIR") or name:find("WATER") or name:find("SUNGAI") or name:find("RIVER") then return false end
			return true
		end

		local name = obj.Name:upper()
		-- JIKA nama atau induknya mengandung unsur rintangan / gedung / pohon, BUKAN JALAN!
		if isObstacleName(name) then return false end

		local cur = obj.Parent
		while cur and cur ~= workspace and cur ~= game do
			if isObstacleName(cur.Name) then
				return false
			end
			cur = cur.Parent
		end

		-- 🚫 AIR / SUNGAI / DANAU BUKAN JALAN! Jangan pernah dianggap sebagai tanah pijakan!
		if obj:IsA("BasePart") and obj.Material == Enum.Material.Water then return false end
		if name:find("AIR") or name:find("WATER") or name:find("SUNGAI") or name:find("RIVER") or name:find("DANAU") or name:find("KOLAM") then
			return false
		end

		if name == "BASEPLATE" or name == "OTHER_GRASS" or name == "ROADSNEW" or name == "TROTOARNEW"
			or name == "ZEBRA_CROSS" or name == "OTHER_FLYOVER_PURWOSARI" or name:find("GROUND") or name:find("TERRAIN")
			or name:find("GRASS") or name == "FLYOVER" or name:find("JEMBATAN") or name:find("BRIDGE")
			or name:find("OVERPASS") or name:find("RAMP") or name:find("HIGHWAY") or name:find("TOLL")
			or name:find("TROTO") or name:find("ROAD") or name:find("JALAN") or name:find("ASPHALT")
			or name:find("ASPAL") or name:find("LANTAI") or name:find("FLOOR") or name:find("SEMEN")
			or name:find("SAWAH") or name:find("KLATEN")
		then
			return true
		end

		if obj:IsA("BasePart") then
			local mat = obj.Material
			local sz = obj.Size
			-- Drivable road / sidewalk slab
			if (mat == Enum.Material.Asphalt or mat == Enum.Material.Pavement) and (sz.X * sz.Z >= 25) and (sz.Y <= 3.5) then
				return true
			end
		end

		return false
	end

	local function isVehicleOrSeatOrPlayer(obj)
		if not obj then return false end
		local char = player.Character
		if char and (obj == char or obj:IsDescendantOf(char)) then return true end
		if obj:IsA("VehicleSeat") or obj:IsA("Seat") or obj:IsA("ProximityPrompt") then return true end

		local rootModel = getVehicleRootModel(obj)
		if rootModel then
			local rName = rootModel.Name:upper()
			if rName:find("MONTOR") or rName:find("MOTOR") or rName:find("CAR") or rName:find("VEHICLE") or rName:find("BIKE") or rName:find(player.Name:upper()) or rootModel:GetAttribute("CarNameData") or rootModel:FindFirstChild("DriveSeat", true) or rootModel:FindFirstChildWhichIsA("VehicleSeat", true) then
				return true
			end
		end

		-- Check if obj is or is inside any Vehicle/Motor model in workspace
		local cur = obj
		while cur and cur ~= workspace and cur ~= game do
			if cur:IsA("Model") then
				if cur:FindFirstChildWhichIsA("VehicleSeat", true) or cur:FindFirstChild("DriveSeat", true) or cur:GetAttribute("CarNameData") then
					return true
				end
				local n = cur.Name:upper()
				if n:find("MONTOR") or n:find("YAMAHA") or n:find("MIO") or n:find("HONDA") or n:find("BEAT")
					or n:find("VARIO") or n:find("NMAX") or n:find("PCX") or n:find("MOTOR") or n:find("BIKE")
					or n:find("CAR") or n:find("MOBIL") or n:find("VEHICLE") or n:find("HANDO") or n:find("HEREX") or n:find("TIGER") or n:find(player.Name:upper())
				then
					return true
				end
			end
			cur = cur.Parent
		end

		return false
	end

	local function shouldDestroyBuilding(obj)
		if not obj or not obj.Parent then return false end
		if obj:IsA("Terrain") or obj:IsA("Camera") then return false end
		if obj.Name == "__DdsSafetyPlate" then return false end
		if isVehicleOrSeatOrPlayer(obj) then return false end

		-- 🛡️ PROTEKSI TOTAL TITIK PENGANTARAN KURIR:
		-- JANGAN PERNAH destroy apapun di dalam folder Livrason atau dalam radius 75 stud dari semua titik delivery!
		local liv = workspace:FindFirstChild("Livrason")
		if liv and (obj == liv or obj:IsDescendantOf(liv)) then
			return false
		end

		if liv and liv:FindFirstChild("Location") then
			local objPos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj:GetPivot().Position)
			if objPos then
				for _, loc in ipairs(liv.Location:GetChildren()) do
					local blk = loc:FindFirstChild("Block")
					if blk and (objPos - blk.Position).Magnitude <= 75 then
						return false
					end
				end
			end
		end

		-- 🛡️ PROTEKSI MUTLAK AREA KLATEN & SAWAH:
		-- DILARANG KERAS destroy apapun di daerah Klaten (BUILDING_KLATEN, JL_KLATEN, SAWAH)!
		local fullName = obj:GetFullName():upper()
		if fullName:find("KLATEN") or fullName:find("SAWAH") then
			return false
		end

		local name = obj.Name:upper()
		if name:find("LANTAI") or name:find("FLOOR") or name:find("GROUND") or name:find("BASE") or name:find("SEMEN") then
			return false
		end

		-- Explicit non-road obstacle keywords
		if isObstacleName(name) then
			return true
		end

		-- Check if inside any obstacle folder/model (e.g. BangunanAfterFlyover, harrizon, etc.)
		local cur = obj.Parent
		while cur and cur ~= workspace and cur ~= game do
			if isObstacleName(cur.Name) then
				return true
			end
			cur = cur.Parent
		end

		if isRoadOrGround(obj) then return false end

		-- Models inside road folders (JL_* / MANAHAN) that are building / prop models
		if obj:IsA("Model") and obj.Parent and (obj.Parent.Name:sub(1, 3) == "JL_" or obj.Parent.Name:find("MANAHAN")) then
			return true
		end

		-- Roof and wall parts
		if obj:IsA("BasePart") then
			local mat = obj.Material
			if mat == Enum.Material.ClayRoofTiles or mat == Enum.Material.WoodPlanks or mat == Enum.Material.Fabric or mat == Enum.Material.Glass then
				return true
			end
		end

		return false
	end

	local function destroyAllBuildings()
		if not (_G.HipHubConfig and _G.HipHubConfig.misc and _G.HipHubConfig.misc.destroyBuildings) then return end
		pcall(function()
			for _, c in ipairs(workspace:GetChildren()) do
				if isVehicleOrSeatOrPlayer(c) then
					-- Proteksi mutlak: Jangan pernah sentuh kendaraan atau player!
				elseif shouldDestroyBuilding(c) then
					pcall(function() c:Destroy() end)
				elseif c:IsA("Folder") or c:IsA("Model") then
					for _, ch in ipairs(c:GetDescendants()) do
						if not isVehicleOrSeatOrPlayer(ch) and shouldDestroyBuilding(ch) then
							pcall(function() ch:Destroy() end)
						end
					end
				end
			end
		end)
	end
	_G.HipHubDestroyAllBuildings = destroyAllBuildings

	-- Auto-destroy newly streamed buildings & obstacles across all districts (hanya jika toggle aktif)
	workspace.DescendantAdded:Connect(function(descendant)
		if not (_G.HipHubConfig and _G.HipHubConfig.misc and _G.HipHubConfig.misc.destroyBuildings) then return end
		if not isVehicleOrSeatOrPlayer(descendant) and shouldDestroyBuilding(descendant) then
			task.wait(0.05)
			if descendant and descendant.Parent and not isVehicleOrSeatOrPlayer(descendant) and shouldDestroyBuilding(descendant) then
				pcall(function() descendant:Destroy() end)
			end
		end
	end)

	task.spawn(destroyAllBuildings)


	local function getGroundExcludeFilter(car)
		local filter = { car, player.Character }
		local existingPlate = workspace:FindFirstChild("__DdsSafetyPlate")
		if existingPlate then
			table.insert(filter, existingPlate)
		end
		for _, c in ipairs(workspace:GetChildren()) do
			if not isRoadOrGround(c) then
				table.insert(filter, c)
			end
		end
		return filter
	end

	local function safelySettleAndUnanchor(car, safePos)
		if not car then return end
		neutralizeBikeHazards(car)
		pcall(function()
			if safePos then
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = getGroundExcludeFilter(car)
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				local hit = workspace:Raycast(Vector3.new(safePos.X, safePos.Y + 30, safePos.Z), Vector3.new(0, -60, 0), rayParams)
				local groundY = hit and hit.Position.Y or (safePos.Y - MOTOR_PIVOT_HEIGHT_OFFSET)
				local bikePos = Vector3.new(safePos.X, groundY + MOTOR_PIVOT_HEIGHT_OFFSET, safePos.Z)

				-- Spawn safety plate under parked bike only
				ensureSafetyPlate(bikePos, 35)
				local curPiv = car:GetPivot()
				car:PivotTo(CFrame.new(bikePos) * (curPiv - curPiv.Position))
			end
			-- Restore collision parts on the DDS motorcycle so tires firmly touch the road trigger
			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					local name = part.Name:lower()
					if name == "dds_collision" or name == "primarypart" or name:find("tire") or name:find("wheel") or name == "paint" or name == "foot" or name == "p" then
						part.CanCollide = true
					else
						part.CanCollide = false
					end
				end
			end
			local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChild("DriveSeat", true)
			if seat then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
				seat.AssemblyLinearVelocity = Vector3.zero
			end

			-- Ensure player stays firmly seated on the motorcycle
			local char = player.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and seat and hum then
				if not hum.Sit or hum.SeatPart ~= seat then
					root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0)
					hum.Sit = true
					seat:Sit(hum)
				end
			end
		end)
	end

	local function getPassengerSeat(car)
		if not car then return nil end
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("Seat") and not part:IsA("VehicleSeat") and part.Name ~= "DriveSeat" then
				return part
			end
		end
		return nil
	end

	-- 🛡️ Synchronized Atomic Pivot & Physics Stabilization Leap
	local function teleportVehicleAcrossVoid(car, landPos, baseDir, jumpDist)
		-- 1. Pre-stream daratan seberang & bentangkan Safety Plate kokoh (di bawah tanah seberang)
		requestStreamAsync(landPos)
		ensureSafetyPlate(landPos, 80)

		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		-- 🎯 Selalu prioritaskan DriveSeat (bukan VehicleSeat kursi penumpang!)
		local seat = car:FindFirstChild("DriveSeat", true)
			or car:FindFirstChildWhichIsA("VehicleSeat", true)
		local prim = car.PrimaryPart or seat or car:FindFirstChildWhichIsA("BasePart")

		local activeMissions = workspace:FindFirstChild("ActiveMissions")
		local passengerNpc = (activeMissions and activeMissions:FindFirstChild("RideGO_Passenger")) or workspace:FindFirstChild("RideGO_Passenger")
		local passRoot = passengerNpc and passengerNpc:FindFirstChild("HumanoidRootPart")

		local targetYaw = math.atan2(baseDir.X, baseDir.Z)
		local targetRot = CFrame.Angles(0, targetYaw, 0)
		local targetCF  = CFrame.new(landPos) * targetRot

		-- 2. Matikan total collision pada motor dan player agar tidak terjadi ledakan impuls / unseat
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.AssemblyLinearVelocity  = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.AssemblyLinearVelocity  = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
		if passengerNpc then
			for _, part in ipairs(passengerNpc:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.AssemblyLinearVelocity  = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end

		-- 3. Proteksi status humanoid & anti-damage sebelum teleport
		if hum then
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			if hum.Health < hum.MaxHealth then
				pcall(function() hum.Health = hum.MaxHealth end)
			end
		end

		-- 4. Pastikan pengemudi terpasang di kursi sebelum teleport
		if hum and seat and hum.SeatPart ~= seat then
			if root then root.CFrame = seat.CFrame + Vector3.new(0, 0.3, 0) end
			pcall(function() seat:Sit(hum) end)
		end

		-- 5. Instant Ground-to-Ground Leap dengan Anchor sementara untuk meniadakan impuls tumbukan
		if prim then prim.Anchored = true end
		car:PivotTo(targetCF)
		RunService.Heartbeat:Wait()
		car:PivotTo(targetCF)
		if prim then prim.Anchored = false end

		local pSeat = getPassengerSeat(car)
		if passRoot and (pSeat or seat) then
			passRoot.CFrame = (pSeat and pSeat.CFrame or seat.CFrame) + Vector3.new(0, 0.3, 0)
			local passHum = passengerNpc and passengerNpc:FindFirstChildOfClass("Humanoid")
			if passHum and pSeat then
				pcall(function() pSeat:Sit(passHum) end)
			end
		end

		-- 6. Pastikan driver tetap duduk di DriveSeat (BUKAN kursi penumpang!) dan pulihkan darah seketika
		if hum and seat then
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			if hum.Health < hum.MaxHealth then
				pcall(function() hum.Health = hum.MaxHealth end)
			end
			if not hum.SeatPart or hum.SeatPart ~= seat then
				if root then root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0) end
				pcall(function() seat:Sit(hum) end)
			end
			task.wait(0.04)
			if hum.SeatPart and hum.SeatPart ~= seat then
				hum.Sit = false
				task.wait(0.04)
				if root then root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0) end
				pcall(function() seat:Sit(hum) end)
			end
		end

		-- 7. Nol-kan kembali seluruh kecepatan di posisi baru
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.AssemblyLinearVelocity  = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
		if seat then
			seat.AssemblyLinearVelocity = Vector3.zero
			seat.AssemblyAngularVelocity = Vector3.zero
		end
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end

		-- 8. ⏱️ ZERO FREEZE LANDING: Langsung tancap gas tanpa jeda diam!
		return landPos
	end

	-- Helper penghitung ketinggian Y adaptif (menempel di tanah jika ada, atau lereng lurus halus di atas jurang)
	local function calculateAdaptiveY(currentY, nextX, nextZ, startPos, destPos, flatDist, totalDist, char, ignoreList, dt)
		local rayParams = RaycastParams.new()
		local filter = { char }
		if ignoreList then
			for _, it in ipairs(ignoreList) do
				if it and it.Parent then table.insert(filter, it) end
			end
		end
		rayParams.FilterDescendantsInstances = filter
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = false

		local rayStartY = currentY + 10
		local hit = workspace:Raycast(
			Vector3.new(nextX, rayStartY, nextZ),
			Vector3.new(0, -45, 0),
			rayParams
		)

		local isSolidGround = false
		local groundY = currentY

		if hit and hit.Instance then
			local mat = hit.Material
			local n = hit.Instance.Name:lower()
			local isWater = (mat == Enum.Material.Water) or n:find("water") or n:find("air") or n:find("laut")
			if not isWater then
				isSolidGround = true
				groundY = hit.Position.Y
			end
		end

		if isSolidGround then
			-- Ada jalan/tanah sah! Tempelkan di atas permukaan tanah (ground + 3.0 stud)
			local targetY = groundY + 3.0
			local maxStep = math.max(60 * dt, 1.5)
			return currentY + math.clamp(targetY - currentY, -maxStep, maxStep), true
		else
			-- Di atas jurang laut (void): slope garis lurus bertahap dari startY ke destPos.Y
			local progress = math.clamp(1 - (flatDist / math.max(totalDist, 1)), 0, 1)
			local slopeY = startPos.Y + (destPos.Y - startPos.Y) * progress
			local minVoidY = 16.5
			if flatDist <= 50 or (totalDist - flatDist) <= 50 then
				minVoidY = math.min(startPos.Y + 3.0, destPos.Y + 3.0)
			end
			local safeVoidY = math.max(slopeY, minVoidY)
			local maxStep = math.max(50 * dt, 1.5)
			return currentY + math.clamp(safeVoidY - currentY, -maxStep, maxStep), false
		end
	end

	-- 🪑 Seat Carrier Engine: Navigasi Halus Bebas Ban & Bebas Strike 100%
	-- Solusi 1: Murni Duduk Permanen (Zero-Unseat)
	-- Karakter selalu duduk di kursi sepanjang sesi kurir, sehingga server tidak pernah
	-- memicu modul deteksi pejalan kaki (Anti-Speed/Anti-Fly) saat menapak!

	ensureCarrierSeat = function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (char and hum and hrp) then return nil end

		if persistentCarrierSeat and persistentCarrierSeat.Parent == workspace 
			and persistentCarrierWeld and persistentCarrierWeld.Parent == persistentCarrierSeat 
			and persistentCarrierWeld.Part1 == hrp then
			if not hum.Sit or hum.SeatPart ~= persistentCarrierSeat then
				hum.Sit = true
				pcall(function() persistentCarrierSeat:Sit(hum) end)
			end
			return persistentCarrierSeat
		end

		-- Bersihkan jika ada kursi lama tidak sinkron
		pcall(function()
			if persistentCarrierWeld then persistentCarrierWeld:Destroy() end
			if persistentCarrierSeat then persistentCarrierSeat:Destroy() end
			local oldSeat = workspace:FindFirstChild("__DdsCourierSeat")
			if oldSeat then oldSeat:Destroy() end
			local oldWeld = workspace:FindFirstChild("__DdsSeatWeld")
			if oldWeld then oldWeld:Destroy() end
		end)
		persistentCarrierWeld = nil
		persistentCarrierSeat = nil

		local carrierSeat = Instance.new("Seat")
		carrierSeat.Name = "__DdsCourierSeat"
		carrierSeat.Size = Vector3.new(2.5, 0.6, 2.5)
		carrierSeat.CanCollide = true
		carrierSeat.Anchored = true
		carrierSeat.Disabled = false
		carrierSeat.Transparency = 1
		carrierSeat.Material = Enum.Material.Plastic
		carrierSeat.CFrame = hrp.CFrame - Vector3.new(0, 1.5, 0)
		carrierSeat.Parent = workspace

		hum.Sit = false
		hum.PlatformStand = false
		task.wait(0.04)

		hrp.CFrame = carrierSeat.CFrame + Vector3.new(0, 0.4, 0)
		task.wait(0.04)
		pcall(function() carrierSeat:Sit(hum) end)
		task.wait(0.1)

		local carrierWeld = Instance.new("WeldConstraint")
		carrierWeld.Name = "__DdsSeatWeld"
		carrierWeld.Part0 = carrierSeat
		carrierWeld.Part1 = hrp
		carrierWeld.Parent = carrierSeat

		hum.Sit = true

		persistentCarrierSeat = carrierSeat
		persistentCarrierWeld = carrierWeld
		return carrierSeat
	end

	destroyCarrierSeat = function()
		if persistentCarrierWeld and persistentCarrierWeld.Parent then
			pcall(function() persistentCarrierWeld:Destroy() end)
			persistentCarrierWeld = nil
		end
		if persistentCarrierSeat and persistentCarrierSeat.Parent then
			pcall(function() persistentCarrierSeat:Destroy() end)
			persistentCarrierSeat = nil
		end
		pcall(function()
			local s = workspace:FindFirstChild("__DdsCourierSeat")
			if s then s:Destroy() end
			local w = workspace:FindFirstChild("__DdsSeatWeld")
			if w then w:Destroy() end
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
			if hum then
				hum.Sit = false
				hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end

	glidePlayerAcrossVoid = function(targetPos, speed)
		if typeof(targetPos) == "CFrame" then
			targetPos = targetPos.Position
		end
		if typeof(targetPos) ~= "Vector3" then return false end

		local char = player.Character
		if not char then return false end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return false end

		local carrierSeat = ensureCarrierSeat()
		if not carrierSeat then return false end

		local effectiveSpeed = math.clamp(speed or Config.courierSpeed or 95, 30, 200)

		updateBotActivity("Menuju Titik Tujuan...", Color3.fromRGB(0, 212, 255))

		-- NoClip pada part tubuh player selama penerbangan (selain kursi)
		local noclipConn = RunService.Stepped:Connect(function()
			if char and char.Parent then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") and p ~= carrierSeat then
						p.CanCollide = false
					end
				end
			end
		end)

		local startPos = hrp.Position
		local curPos = startPos
		local lastStreamPos = startPos
		local lastNotifyTime = 0
		local startTime = os.clock()

		local totalDist = (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
		local maxWait = (totalDist / math.max(effectiveSpeed, 50)) + 30.0

		-- Pre-stream titik awal & tujuan
		requestStreamAsync(startPos)
		requestStreamAsync(targetPos)

		-- Meluncur Frame demi Frame dengan Ketinggian Adaptif (Tanpa Terbang ke Langit)
		while (courierActive or _G.HipHubCourierActive) do
			local dt = RunService.Heartbeat:Wait()

			-- Validasi karakter masih hidup & ada di workspace
			if not (char and char.Parent and hrp and hrp.Parent and hum and hum.Parent) then
				break
			end

			-- Safety timeout
			if (os.clock() - startTime) > maxWait then
				warn("[HipHub DDS Seat Carrier] Timeout tercapai, menyelesaikan luncuran...")
				break
			end

			local flatDelta = Vector3.new(targetPos.X - curPos.X, 0, targetPos.Z - curPos.Z)
			local flatDist = flatDelta.Magnitude

			-- Tiba di radius rapat (<= 2.5 stud) dari target
			if flatDist <= 2.5 then
				break
			end

			local moveDir = flatDelta.Unit
			local stepDist = math.min(effectiveSpeed * dt, flatDist)

			local nextX = curPos.X + moveDir.X * stepDist
			local nextZ = curPos.Z + moveDir.Z * stepDist

			local nextY, isGround = calculateAdaptiveY(curPos.Y, nextX, nextZ, startPos, targetPos, flatDist, totalDist, char, { carrierSeat }, dt)
			curPos = Vector3.new(nextX, nextY, nextZ)

			-- Orientasi hadap ke arah tujuan
			local lookAt = Vector3.new(targetPos.X, nextY, targetPos.Z)
			if carrierSeat and carrierSeat.Parent then
				carrierSeat.CFrame = CFrame.new(curPos - Vector3.new(0, 1.5, 0), lookAt)
			end
			hrp.CFrame = CFrame.new(curPos, lookAt)
			hum.Sit = true

			-- Sinkronkan velocity tubuh dengan arah meluncur
			hrp.AssemblyLinearVelocity = moveDir * effectiveSpeed
			hrp.AssemblyAngularVelocity = Vector3.zero

			-- Pre-stream chunk secara berkala setiap 120 stud perjalanan
			if (curPos - lastStreamPos).Magnitude >= 120 then
				lastStreamPos = curPos
				requestStreamAsync(curPos)
				requestStreamAsync(curPos + moveDir * 250)
			end

			-- Update status UI setiap 0.5 detik
			local now = os.clock()
			if now - lastNotifyTime >= 0.5 then
				lastNotifyTime = now
				updateBotActivity(string.format("Seat Carrier: sisa %.0fm...", flatDist), Color3.fromRGB(0, 212, 255))
			end
		end

		if noclipConn then
			pcall(function() noclipConn:Disconnect() end)
			noclipConn = nil
		end

		-- 🛑 ZERO-UNSEAT ARRIVAL (Solusi 1: TETAP DUDUK DI KURSI):
		-- Nol-kan kecepatan dan pertahankan posisi duduk di atas kursi rapat di target.
		-- JANGAN PERNAH unseat! JANGAN hancurkan kursi! JANGAN ubah state ke GettingUp!
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			local lookAtTarget = Vector3.new(targetPos.X, curPos.Y, targetPos.Z)
			if carrierSeat and carrierSeat.Parent then
				carrierSeat.CFrame = CFrame.new(curPos - Vector3.new(0, 1.5, 0), lookAtTarget)
			end
			hrp.CFrame = CFrame.new(curPos, lookAtTarget)
			hum.Sit = true
		end)

		task.wait(0.2)
		return true
	end

	local nonDrivableMats = {
		[Enum.Material.ClayRoofTiles] = true,
		[Enum.Material.WoodPlanks] = true,
		[Enum.Material.Fabric] = true,
		[Enum.Material.Glass] = true,
		[Enum.Material.Water] = true
	}

	-- 🚀 ZERO-ALLOCATION RAYCAST PARAMS & BUFFERS
	local sharedProbeRayParams = RaycastParams.new()
	sharedProbeRayParams.FilterType = Enum.RaycastFilterType.Exclude
	sharedProbeRayParams.IgnoreWater = false

	local function probeGroundFile(probePos, refY, optCar, optFilter)
		local car = optCar or (getPlayerVehicle and select(1, getPlayerVehicle()))
		local carPivot = car and car:GetPivot()
		local carPos2D = carPivot and Vector3.new(carPivot.Position.X, 0, carPivot.Position.Z) or Vector3.new(probePos.X, 0, probePos.Z)
		local distFromCar = (Vector3.new(probePos.X, 0, probePos.Z) - carPos2D).Magnitude

		local startY
		local rayDepth
		if isSasanaKridaTrip() then
			startY = (refY or 0) + 7
			rayDepth = -30
		elseif distFromCar <= 15 then
			startY = (refY or (carPivot and carPivot.Position.Y) or 0) + 14
			rayDepth = -160
		else
			startY = math.max((refY or 0) + 14 + distFromCar * 0.35, 25)
			rayDepth = -math.max(distFromCar * 0.6 + 60, 160)
		end

		local baseFilter = optFilter or { car, player.Character }
		local safetyPlate = workspace:FindFirstChild("__DdsSafetyPlate")
		if safetyPlate and not table.find(baseFilter, safetyPlate) then
			local t = table.clone(baseFilter)
			table.insert(t, safetyPlate)
			baseFilter = t
		end

		local offsets = {
			Vector3.zero,
			Vector3.new(2, 0, 0),
			Vector3.new(-2, 0, 0),
			Vector3.new(0, 0, 2),
			Vector3.new(0, 0, -2)
		}

		for offIdx, off in ipairs(offsets) do
			local pos = probePos + off
			local rayOrigin = Vector3.new(pos.X, startY, pos.Z)
			local localFilter = table.clone(baseFilter)

			for attempt = 1, 5 do
				sharedProbeRayParams.FilterDescendantsInstances = localFilter
				local hit = workspace:Raycast(rayOrigin, Vector3.new(0, rayDepth, 0), sharedProbeRayParams)
				if not hit then break end

				local inst = hit.Instance
				local mat = inst.Material
				local nameLower = inst.Name:lower()
				local parent = inst.Parent
				local parentName = parent and parent.Name:lower() or ""
				local grandParent = parent and parent.Parent
				local grandParentName = grandParent and grandParent.Name:lower() or ""

				local isFlyover = nameLower:find("flyover") or nameLower:find("tol") or nameLower:find("jembatan") or nameLower:find("bridge")
					or parentName:find("flyover") or parentName:find("tol") or parentName:find("jembatan") or parentName:find("bridge")

				-- 1. Daratan Sah / Jalan Raya (Direct fast name check)
				local isRoadOrTerrain = isFlyover
					or nameLower:find("jl_klaten")
					or nameLower:find("jl_")
					or nameLower:find("jalan")
					or nameLower:find("road")
					or nameLower:find("street")
					or nameLower:find("aspal")
					or nameLower:find("sawah")
					or parentName:find("jl_")
					or parentName:find("jalan")
					or parentName:find("road")
					or parentName:find("sawah")
					or grandParentName:find("sawah")
					or inst:IsA("Terrain")

				-- 2. Air / Sungai
				local isWater = (mat == Enum.Material.Water) or nameLower:find("water") or nameLower:find("air") or nameLower:find("sungai") or nameLower:find("river") or nameLower:find("danau") or nameLower:find("kolam")

				-- 3. Atap / Rintangan Fisik / Gedung Sungguhan
				local isRoofOrObstacle = false
				local isBuildingModel = false

				if not isRoadOrTerrain then
					isRoofOrObstacle = nonDrivableMats[mat]
						or nameLower:find("roof") or nameLower:find("atap") or nameLower:find("genteng")
						or nameLower:find("wall") or nameLower:find("dinding") or nameLower:find("pagar")
						or parentName:find("roof") or parentName:find("atap") or parentName:find("genteng")
						or (inst.Position.Y >= 8 and (mat == Enum.Material.Brick or mat == Enum.Material.Wood))

					local hasBuildingKeyword = parentName:find("rumah") or parentName:find("house")
						or parentName:find("gedung") or parentName:find("bangunan")
						or parentName:find("ruko") or parentName:find("gudang")
						or parentName:find("indamart") or parentName:find("indahmart")
						or parentName:find("karoseri") or parentName:find("billboard")
						or parentName:find("excavator") or parentName:find("adiputro")
						or grandParentName:find("ruko") or grandParentName:find("gudang")
						or grandParentName:find("indamart") or grandParentName:find("indahmart")
						or grandParentName:find("karoseri") or grandParentName:find("billboard")
						or grandParentName:find("adiputro")

					isBuildingModel = hasBuildingKeyword and inst.Position.Y >= 6
				end

				if isWater then
					break
				elseif isRoofOrObstacle or isBuildingModel then
					table.insert(localFilter, inst)
					rayOrigin = Vector3.new(pos.X, hit.Position.Y - 0.4, pos.Z)
				else
					local hitY = hit.Position.Y
					local isOverheadObstacle = false
					if refY and distFromCar <= 15 then
						if hitY > (refY + 16) then
							isOverheadObstacle = true
						end
					end

					if not isOverheadObstacle and hitY >= -45 and hitY <= (startY + 10) and (not hit.Normal or hit.Normal.Y >= 0.10) then
						return hitY + MOTOR_PIVOT_HEIGHT_OFFSET
					elseif isOverheadObstacle then
						table.insert(localFilter, inst)
						rayOrigin = Vector3.new(pos.X, hit.Position.Y - 0.4, pos.Z)
					else
						break
					end
				end
			end

			-- ⚡ Fast-Path: Jika titik tengah (center) sudah jelas mengenai aspal / terrain valid di jarak normal,
			-- tidak perlu mengecek 4 offset samping (menghemat 80% raycast per frame)
			if offIdx == 1 and distFromCar > 6 then
				-- Jika titik tengah void, lanjut periksa 4 offset samping
			end
		end

		return nil
	end

	-- 🌉 Void Bridge Engine: scan daratan seberang jurang (hanya sudut maju ke arah tujuan),
	-- lalu teleport vehicle ke ground seberang dengan safety plate.
	local function attemptVoidBridge(car, fromPos, toPos)
		local flatDiff = Vector3.new(toPos.X - fromPos.X, 0, toPos.Z - fromPos.Z)
		local totalDistToDest = flatDiff.Magnitude
		if totalDistToDest < 25 then return nil end
		local baseDir = flatDiff.Unit

		-- Pre-stream koridor daratan seberang jurang secara bertahap
		requestStreamAsync(toPos)
		if totalDistToDest > 200 then
			requestStreamAsync(fromPos + baseDir * math.min(totalDistToDest, 400))
			requestStreamAsync(fromPos + baseDir * math.min(totalDistToDest, 800))
			requestStreamAsync(fromPos + baseDir * math.min(totalDistToDest, 1200))
		end

		local brp = RaycastParams.new()
		local safetyPlate = workspace:FindFirstChild("__DdsSafetyPlate")
		local filter = { car, player.Character }
		if safetyPlate then table.insert(filter, safetyPlate) end
		brp.FilterDescendantsInstances = filter
		brp.FilterType = Enum.RaycastFilterType.Exclude

		-- Scan sampai jarak penuh ke destination (maksimal 3000 stud)
		local maxScan = math.min(totalDistToDest * 1.05, 3000)
		local stepSize = 25

		-- 🌉 Void Bridge Scan: Cari daratan seberang celah jurang lokal.
		-- JANGAN PERNAH teleport langsung ribuan stud ke toPos pengantaran paket (menyebabkan strike/kick)!
		-- Semua mode (termasuk kurir) harus melompati celah jurang lokal ke daratan seberang terdekat,
		-- lalu melanjutkan perjalanan secara mulus di atas jalan raya Klaten.

		-- Scan HANYA sudut maju ke arah tujuan (0, ±10, ±20, ±30 deg).
		-- JANGAN PERNAH SCAN KE SAMPING / BELAKANG (±45, ±60, ±75, ±90) agar tidak melompat liar ke pulau lain!
		local scanAngles = { 0, 10, -10, 20, -20, 30, -30 }

		for _, ang in ipairs(scanAngles) do
			local scanRot = CFrame.Angles(0, math.rad(ang), 0)
			local flatDir = (scanRot * Vector3.new(baseDir.X, 0, baseDir.Z)).Unit

			local refY = fromPos.Y
			local inVoid = false
			local voidEnteredAt = nil

			for i = 1, math.ceil(maxScan / stepSize) do
				local curDist = i * stepSize
				local px = fromPos.X + flatDir.X * curDist
				local pz = fromPos.Z + flatDir.Z * curDist
				local testPos = Vector3.new(px, 0, pz)

				-- Request stream chunk setiap 100 stud pemindaian jurang
				if inVoid and curDist % 100 == 0 then
					requestStreamAsync(testPos)
				end

				local scanStartY = isSasanaKridaTrip() and math.max(refY + 7, 10) or math.max(refY + 85, 120)
				local rayDepth = -math.max(scanStartY + 40, 350)
				local origin = Vector3.new(px, scanStartY, pz)
				local solidY = nil
				local localFilter = table.clone(filter)

				for attempt = 1, 5 do
					sharedProbeRayParams.FilterDescendantsInstances = localFilter
					local hit = workspace:Raycast(origin, Vector3.new(0, rayDepth, 0), sharedProbeRayParams)
					if not hit then break end

					local inst = hit.Instance
					local mat = inst.Material
					local nameLower = inst.Name:lower()
					local parent = inst.Parent
					local parentName = parent and parent.Name:lower() or ""
					local grandParent = parent and parent.Parent
					local grandParentName = grandParent and grandParent.Name:lower() or ""

					local isFlyover = nameLower:find("flyover") or nameLower:find("tol") or nameLower:find("jembatan") or nameLower:find("bridge")
						or parentName:find("flyover") or parentName:find("tol") or parentName:find("jembatan") or parentName:find("bridge")

					-- 1. Daratan Sah / Jalan Raya (Direct fast name check)
					local isRoadOrTerrain = isFlyover
						or nameLower:find("jl_klaten")
						or nameLower:find("jl_")
						or nameLower:find("jalan")
						or nameLower:find("road")
						or nameLower:find("street")
						or nameLower:find("aspal")
						or nameLower:find("sawah")
						or parentName:find("jl_")
						or parentName:find("jalan")
						or parentName:find("road")
						or parentName:find("sawah")
						or grandParentName:find("sawah")
						or inst:IsA("Terrain")

					-- 2. Air / Sungai / Laut (Bukan daratan)
					local isWater = (mat == Enum.Material.Water) or nameLower:find("water") or nameLower:find("air") or nameLower:find("sungai") or nameLower:find("river") or nameLower:find("danau") or nameLower:find("kolam") or nameLower:find("laut") or nameLower:find("sea") or nameLower:find("ocean")

					-- 3. Atap / Rintangan Fisik / Gedung Sungguhan
					local isRoofOrObstacle = false
					local isBuildingModel = false

					if not isRoadOrTerrain then
						isRoofOrObstacle = nonDrivableMats[mat]
							or nameLower:find("roof") or nameLower:find("atap") or nameLower:find("genteng")
							or nameLower:find("wall") or nameLower:find("dinding") or nameLower:find("pagar")
							or parentName:find("roof") or parentName:find("atap") or parentName:find("genteng")
							or (inst.Position.Y >= 8 and (mat == Enum.Material.Brick or mat == Enum.Material.Wood))

						local hasBuildingKeyword = parentName:find("rumah") or parentName:find("house")
							or parentName:find("gedung") or parentName:find("bangunan")
							or parentName:find("ruko") or parentName:find("gudang")
							or parentName:find("indamart") or parentName:find("indahmart")
							or parentName:find("karoseri") or parentName:find("billboard")
							or parentName:find("excavator") or parentName:find("adiputro")
							or grandParentName:find("ruko") or grandParentName:find("gudang")
							or grandParentName:find("indamart") or grandParentName:find("indahmart")
							or grandParentName:find("karoseri") or grandParentName:find("billboard")
							or grandParentName:find("adiputro")

						isBuildingModel = hasBuildingKeyword and inst.Position.Y >= 6
					end

					if isWater then
						-- Air sungai adalah jurang cair! Jangan pernah jadikan solidY
						solidY = nil
						break
					elseif isRoofOrObstacle or isBuildingModel then
						table.insert(localFilter, inst)
						origin = Vector3.new(px, hit.Position.Y - 0.4, pz)
					else
						if hit.Position.Y >= -30 and hit.Position.Y <= 350 and (not hit.Normal or hit.Normal.Y >= 0.12) then
							solidY = hit.Position.Y
						end
						break
					end
				end

				local isGround = solidY ~= nil

				if isGround then
					refY = solidY
					local isVoidGap = (inVoid and voidEnteredAt and (curDist - voidEnteredAt >= 15))
					local isElevatedLedge = (solidY >= fromPos.Y + 2.5 and curDist >= 4 and curDist <= 150)

					if isVoidGap or isElevatedLedge then
						local landDistToDest = (Vector3.new(toPos.X, 0, toPos.Z) - Vector3.new(px, 0, pz)).Magnitude
						-- 🛡️ Forward Progress Gate:
						-- Untuk elevated ledge (tebing/tanggul): cukup maju 4 stud karena tujuan utamanya adalah naik ke daratan atas!
						-- Untuk jurang samudra: adaptif berdasarkan jarak total
						local minProgress = isElevatedLedge and 4 or (totalDistToDest > 200 and 35 or 5)
						if landDistToDest < totalDistToDest - minProgress then
							-- 🛡️ STRICT ANTI-DROPOFF SKIP:
							-- Jika perjalanan jarak jauh (> 300 stud), DILARANG KERAS mendarat langsung di radius pengantaran (< 120 stud)!
							-- Motor WAJIB mendarat di TEPI DARATAN SEBERANG TERDEKAT (coastline / edge), lalu melanjutkan berkendara di aspal.
							if not (totalDistToDest > 300 and landDistToDest < 120) then
								local landPos = Vector3.new(px, solidY + MOTOR_PIVOT_HEIGHT_OFFSET, pz)
								local jumpDist = (Vector3.new(landPos.X, 0, landPos.Z) - Vector3.new(fromPos.X, 0, fromPos.Z)).Magnitude
								local landed = teleportVehicleAcrossVoid(car, landPos, baseDir, jumpDist)
								return landed, jumpDist
							end
						end
					end
				else
					if not inVoid then
						inVoid = true
						voidEnteredAt = curDist
					end
				end
			end
		end

		-- 🛑 DILARANG KERAS TELEPORT LANGSUNG KE TITIK DROPOFF (toPos)!
		-- Jika daratan seberang belum ter-stream, kembalikan nil agar motor menunggu di tebing
		-- sampai chunk tepi daratan seberang ter-load secara legal, lalu melompat HANYA ke tepi ground seberang tersebut.
		return nil
	end

	-- 🛣️ Pure Road Navigation Engine
	local function driveVehicleTo(targetPos, speed, stopRadius, destroyPlateAfterStuds, abortCheck)
		if typeof(targetPos) == "CFrame" then
			targetPos = targetPos.Position
		end
		if typeof(targetPos) ~= "Vector3" then return false end

		local car, seat = getPlayerVehicle()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")

		if not car or not seat or not (hum and hum.SeatPart) then
			local ok = ensureDriverSeated()
			if not ok then
				warn("[HipHub DDS] driveVehicleTo: Pengemudi belum duduk, membatalkan jalan untuk keselamatan player")
				return false
			end
			car, seat = getPlayerVehicle()
			if not car or not seat then
				return false
			end
		end

		cancelActiveDrive()
		isDrivingActive = true
		neutralizeBikeHazards(car)

		local plateDestroyedDeferred = false
		if not destroyPlateAfterStuds or destroyPlateAfterStuds <= 0 then
			destroySafetyPlate()
		end

		-- 🗺️ Pre-stream terrain tujuan agar probeGround tidak salah deteksi void
		requestStreamAsync(targetPos)
		-- Khusus mode Kurir: jika jarak jauh (>200 stud), beri waktu lebih agar terrain Klaten ter-load
		-- sebelum void scanner mulai scan. Tanpa ini, jalan Klaten dianggap void → teleport → kick!
		if courierActive then
			local distToTarget = (car:GetPivot().Position - targetPos).Magnitude
			if distToTarget > 200 then
				task.wait(0.5)
			else
				task.wait(0.2)
			end
		end

		speed = tonumber(speed) or tonumber(Config.taxiSpeed) or 60
		local startCF = car:GetPivot()
		local startP  = startCF.Position
		local destP   = targetPos

		if (startP - destP).Magnitude <= 6 then
			safelySettleAndUnanchor(car, destP)
			isDrivingActive = false
			return true
		end

		local rayFilter = { car, player.Character }
		local existingPlate = workspace:FindFirstChild("__DdsSafetyPlate")
		if existingPlate then table.insert(rayFilter, existingPlate) end

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = rayFilter
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = false -- 🌊 Terrain Water HARUS terdeteksi sebagai solid oleh semua raycast agar motor tidak menembusnya!

		local function probeGround(probePos, refY)
			return probeGroundFile(probePos, refY, car, rayFilter)
		end


		-- Selective Noclip on vehicle parts
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = false
			end
		end

		local totalDist = (startP - destP).Magnitude
		local driveFinished = false
		local lastTick = os.clock()
		local lastGroundY = startP.Y

		local stuckLastDist   = totalDist
		local stuckLastTime   = os.clock()
		local stuckNudgeCount = 0

		local navHeading = nil
		local edgeFollowSign = 1
		local curHeadingAngle = math.atan2(((destP - startP).Unit).X, ((destP - startP).Unit).Z)
		local lastBridgeScanTime = 0
		local driveStartTime = os.clock()
		local currentSmoothSpeed = 0
		local cliffWaitStartTime = nil
		local lastSolidCF = startCF

		currentDriveConn = RunService.Heartbeat:Connect(function()
			if not isDrivingActive then
				if currentDriveConn then currentDriveConn:Disconnect() end
				driveFinished = true
				return
			end

			local now = os.clock()
			local dt = math.clamp(now - lastTick, 0.001, 0.1)
			lastTick = now

			local carCF = car:GetPivot()
			local carPos = carCF.Position

			-- 🔒 Enforced Frame-Level Seat Lock & Swimming Neutralizer:
			if hum and seat then
				pcall(function()
					hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				end)
				if not hum.SeatPart or hum.SeatPart ~= seat then
					pcall(function() seat:Sit(hum) end)
				end
			end

			-- 🌊 PROACTIVE FORWARD WATER SCANNER:
			-- Sebelum motor bergerak, scan area di depan dan di bawah motor saat ini.
			-- Jika ada Terrain Water terdeteksi dalam jarak dekat, langsung rescue & tahan posisi!
			do
				sharedProbeRayParams.FilterDescendantsInstances = { car, player.Character }
				-- Cek tepat di bawah posisi motor saat ini (threshold 0.5 stud)
				local belowHit = workspace:Raycast(Vector3.new(carPos.X, carPos.Y + 1.5, carPos.Z), Vector3.new(0, -4.5, 0), sharedProbeRayParams)
				if belowHit and belowHit.Material == Enum.Material.Water then
					-- Motor sudah di atas/dalam air! Rescue SEKETIKA ke lastGroundY
					local rescueY = math.max(lastGroundY, belowHit.Position.Y + 2.5)
					local rescuePos = Vector3.new(carPos.X, rescueY, carPos.Z)
					ensureSafetyPlate(rescuePos, 80)
					pcall(function() car:PivotTo(CFrame.new(rescuePos)) end)
					for _, part in ipairs(car:GetDescendants()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = Vector3.zero
							part.AssemblyAngularVelocity = Vector3.zero
						end
					end
					lastGroundY = rescueY
				end
			end

			-- 🛡️ Anti-Water Submersion & NaN Physics Shield:
			-- Jika motor turun bahkan sedikit saja (0.5 stud), cek apakah itu karena air sungai!
			if (carPos.Y < (lastGroundY - 0.5)) then
				pcall(function()
					local checkOrigin = Vector3.new(carPos.X, carPos.Y + 3, carPos.Z)
					sharedProbeRayParams.FilterDescendantsInstances = { car, player.Character }
					local wHit = workspace:Raycast(checkOrigin, Vector3.new(0, -8, 0), sharedProbeRayParams)
					if wHit and (wHit.Material == Enum.Material.Water
						or wHit.Instance.Name:upper():find("AIR")
						or wHit.Instance.Name:upper():find("SUNGAI")
						or wHit.Instance.Name:upper():find("RIVER")
						or wHit.Instance.Name:upper():find("DANAU")
					) then
						local rescueY = math.max(lastGroundY, wHit.Position.Y + 2.5)
						local rescuePos = Vector3.new(carPos.X, rescueY, carPos.Z)
						ensureSafetyPlate(rescuePos, 80)
						car:PivotTo(CFrame.new(rescuePos))
						for _, part in ipairs(car:GetDescendants()) do
							if part:IsA("BasePart") then
								part.AssemblyLinearVelocity = Vector3.zero
								part.AssemblyAngularVelocity = Vector3.zero
							end
						end
						lastGroundY = rescueY
					end
				end)
			end

			-- 🦺 Emergency Void Fall Recovery: Jaring pengaman jika jatuh bebas (sebelum mencapai ketinggian kick server)
			if carPos.Y < (lastGroundY - 18) or carPos.Y < -15 then
				local rescueY = math.max(lastGroundY, 5)
				local rescuePos = Vector3.new(carPos.X, rescueY, carPos.Z)
				ensureSafetyPlate(rescuePos, 80)
				car:PivotTo(CFrame.new(rescuePos))
				lastGroundY = rescueY
				if hum and seat and (not hum.SeatPart or hum.SeatPart ~= seat) then
					mountBike()
				end
			end

			local delta = destP - carPos
			local flatDelta = Vector3.new(delta.X, 0, delta.Z)
			local dist = flatDelta.Magnitude

			-- Deferred safetyPlate removal
			if not plateDestroyedDeferred and destroyPlateAfterStuds and destroyPlateAfterStuds > 0 then
				local flatTravelled = Vector3.new(carPos.X - startP.X, 0, carPos.Z - startP.Z).Magnitude
				if flatTravelled >= destroyPlateAfterStuds then
					plateDestroyedDeferred = true
					destroySafetyPlate()
				end
			end

			if abortCheck and abortCheck() then
				driveFinished = true
				if currentDriveConn then currentDriveConn:Disconnect() end
				return
			end

			local arrivalDist = tonumber(stopRadius) or (courierActive and 4.5 or 3.5)
			if dist <= arrivalDist then
				driveFinished = true
				if currentDriveConn then currentDriveConn:Disconnect() end
				return
			end

			-- Stuck Recovery
			local nowClock = os.clock()
			if dist < stuckLastDist - 2.5 then
				stuckLastDist = dist
				stuckLastTime = nowClock
			elseif (nowClock - stuckLastTime) >= 2.5 and stuckNudgeCount < 10 and not cliffWaitStartTime then
				stuckNudgeCount = stuckNudgeCount + 1
				stuckLastTime   = nowClock
				stuckLastDist   = dist

				local nudgeDir = flatDelta.Magnitude > 0.1 and flatDelta.Unit or Vector3.new(0, 0, -1)
				local nudgeDist = math.min(30, dist - 4)
				if nudgeDist > 0 then
					local nudgePos2D = Vector3.new(
						carPos.X + nudgeDir.X * nudgeDist,
						0,
						carPos.Z + nudgeDir.Z * nudgeDist
					)
					local solidNudgeY = probeGround(nudgePos2D, lastGroundY)
					if solidNudgeY then
						local nudgeLand = Vector3.new(nudgePos2D.X, solidNudgeY, nudgePos2D.Z)

						pcall(function()
							ensureSafetyPlate(nudgeLand, 40)
							local yaw = math.atan2(nudgeDir.X, nudgeDir.Z)
							car:PivotTo(CFrame.new(nudgeLand) * CFrame.Angles(0, yaw, 0))
							for _, part in ipairs(car:GetDescendants()) do
								if part:IsA("BasePart") then
									part.AssemblyLinearVelocity  = Vector3.zero
									part.AssemblyAngularVelocity = Vector3.zero
								end
							end
							lastGroundY = solidNudgeY
						end)

						return -- Selesaikan frame ini agar posisi bypass tidak ter-override
					else
						stuckLastTime = nowClock
					end
				end
			end

			-- 🏎️ 3-Stage Progressive Aerodynamic Braking Curve (Mulai dari 800 Studs):
			-- Stage 1 (800 -> 50 stud): Kecepatan turun mulus dari speed (300 stud/s) ke 28 stud/s (~25 km/h)
			-- Stage 2 (50 -> 10 stud): Kecepatan merayap pelan dari 28 stud/s ke 4.0 stud/s
			-- Stage 3 (< 10 stud): Meluncur lembut ke 0 stud/s dan berhenti tepat di titik tujuan (dist <= 3.5)
			local targetSpeed = speed

			if dist < 10 then
				local ratio = math.clamp(dist / 10, 0, 1)
				targetSpeed = math.max(0, 4.0 * ratio)
			elseif dist < 50 then
				local creepFactor = math.clamp((dist - 10) / 40, 0, 1)
				targetSpeed = 4.0 + (28.0 - 4.0) * creepFactor
			elseif dist < 800 then
				local factor = math.clamp((dist - 50) / 750, 0, 1)
				-- Smoothstep S-Curve: Transisi eksponensial sangat empuk tanpa sentakan inersia
				local sFactor = factor * factor * (3 - 2 * factor)
				targetSpeed = 28.0 + (speed - 28.0) * sFactor
			end

			local directGoalDir = flatDelta.Magnitude > 0.1 and flatDelta.Unit or Vector3.new(0, 0, -1)

			-- 🛑 STRICT VOID SAFETY SCANNER:
			-- Memindai kesinambungan daratan di depan secara efisien
			local solidAheadDist = 800
			local checkSteps = { 3, 6, 12, 25, 45, 80, 150, 300, 500, 800 }
			for _, lookDist in ipairs(checkSteps) do
				if lookDist >= dist then
					break
				end
				local testPos = carPos + directGoalDir * lookDist
				if not probeGround(testPos, lastGroundY) then
					solidAheadDist = lookDist
					break
				end
			end

			-- 🛑 Pengereman Menjelang Tepi Jurang (Berhenti di solidAheadDist <= 3):
			-- Kendaraan merayap mendekati tepi hingga jarak 3 stud (tepat di ujung aspal),
			-- ban depan tetap 100% menapak di daratan asal tanpa menggantung di ruang hampa.
			local isImmediateVoidAhead = (solidAheadDist <= 3) and (dist > solidAheadDist)

			if isImmediateVoidAhead then
				targetSpeed = 0
				currentSmoothSpeed = 0
			elseif solidAheadDist < 600 and solidAheadDist < dist then
				local cliffTargetSpeed = speed
				if solidAheadDist <= 3 then
					cliffTargetSpeed = 0
				elseif solidAheadDist < 8 then
					local creepRatio = math.clamp((solidAheadDist - 3) / 5, 0, 1)
					cliffTargetSpeed = 3.5 + (10.0 - 3.5) * creepRatio
				elseif solidAheadDist < 25 then
					local ratio = math.clamp((solidAheadDist - 8) / 17, 0, 1)
					cliffTargetSpeed = 10.0 + (28.0 - 10.0) * ratio
				else
					local factor = math.clamp((solidAheadDist - 25) / 575, 0, 1)
					local sFactor = factor * factor * (3 - 2 * factor)
					cliffTargetSpeed = 28.0 + (speed - 28.0) * sFactor
				end
				targetSpeed = math.min(targetSpeed, cliffTargetSpeed)
			end

			-- 🛡️ Slew-Rate Limiter (Zero-Damage Smooth Acceleration & Deceleration):
			-- Jika jurang dekat (< 25 stud), kurangi kecepatan secara instan agar tidak bablas ke bibir jurang!
			local maxAccelRate = math.max(45, speed * 0.4) * dt
			local maxDecelRate = (solidAheadDist < 25) and 9999 or (math.max(50, speed * 0.45) * dt)
			if currentSmoothSpeed < targetSpeed then
				currentSmoothSpeed = math.min(targetSpeed, currentSmoothSpeed + maxAccelRate)
			elseif currentSmoothSpeed > targetSpeed then
				currentSmoothSpeed = math.max(targetSpeed, currentSmoothSpeed - maxDecelRate)
			end

			local curSpeed = isImmediateVoidAhead and 0 or currentSmoothSpeed
			local stepDist = curSpeed * dt
			local probeDist = math.max(stepDist * 1.6, 4)

			local directProbePos = carPos + directGoalDir * probeDist
			local directHitY = (not isImmediateVoidAhead) and probeGround(directProbePos, lastGroundY) or nil

			local actualMoveDir = directGoalDir
			local targetElevY = lastGroundY

			if directHitY and not isImmediateVoidAhead then
				cliffWaitStartTime = nil
				actualMoveDir = directGoalDir
				navHeading = directGoalDir
				targetElevY = directHitY
				lastSolidCF = car:GetPivot()
			else
				-- 🛑 TEPI JURANG / PULAU SEMPIT: DILARANG KERAS BERJALAN MAJU KE ATAS RUANG HAMPA UDARA!
				-- Motor WAJIB diam total di atas aspal daratan asal sambil memindai daratan seberang.
				actualMoveDir = Vector3.zero
				stepDist = 0
				currentSmoothSpeed = 0
				curSpeed = 0
				targetElevY = lastGroundY

				-- 🛡️ ANTI-MELAYANG DI UDARA (Cliff Edge Snap-Back):
				-- Jika posisi motor saat ini sudah terlanjur melewati bibir tebing,
				-- seketika tarik kembali posisi motor ke lastSolidCF agar tetap 100% di atas daratan solid!
				if lastSolidCF and not probeGround(carPos, lastGroundY) then
					car:PivotTo(lastSolidCF)
					for _, part in ipairs(car:GetDescendants()) do
						if part:IsA("BasePart") then
							part.AssemblyLinearVelocity = Vector3.zero
							part.AssemblyAngularVelocity = Vector3.zero
						end
					end
					carPos = lastSolidCF.Position
				end

				local nowClock = os.clock()
				cliffWaitStartTime = cliffWaitStartTime or nowClock

				-- ⏱️ Waktu tunggu di tepi jurang:
				local cliffWaitDuration = nowClock - cliffWaitStartTime

				-- 1. 🌉 Prioritas Utama: Coba lompati jurang dengan motor jika memungkinkan!
				if (nowClock - lastBridgeScanTime) >= 0.15 then
					lastBridgeScanTime = nowClock
					local bridgeLanding, jumpDist = attemptVoidBridge(car, carPos, destP)
					if bridgeLanding then
						cliffWaitStartTime = nil
						lastGroundY = bridgeLanding.Y
						targetElevY = bridgeLanding.Y
						stuckLastDist = (destP - bridgeLanding).Magnitude
						local newDir = (destP - bridgeLanding).Unit
						curHeadingAngle = math.atan2(newDir.X, newDir.Z)
						stuckLastTime = os.clock()
						currentSmoothSpeed = 0
						return -- 🛑 Selesaikan frame ini setelah mendarat dan hold selesai!
					end
				end


				-- 3. ⏱️ Timeout di Tepi Jurang (Tunggu chunk terrain seberang streaming-in):
				if (nowClock - (lastChunkStreamReq or 0)) >= 2.0 then
					lastChunkStreamReq = nowClock
					requestStreamAsync(destP)
				end

				if cliffWaitDuration >= 10.0 then
					cliffWaitStartTime = nil
					cancelActiveDrive()
					if courierActive then
						task.spawn(function()
							triggerSafeRespawn("Jurang Luas & Ground Belum Render")
						end)
						return
					else
						task.spawn(function()
							restartAutoRideGoToggle("Jurang Terlalu Luas")
						end)
						return
					end
				end
			end

			-- Smooth vertical descent/ascent rate
			local maxVertStep = math.max(50 * dt, 2.5)
			local chosenY = lastGroundY
			if chosenY > targetElevY then
				chosenY = math.max(targetElevY, chosenY - maxVertStep)
			elseif chosenY < targetElevY then
				chosenY = math.min(targetElevY, chosenY + maxVertStep)
			end
			lastGroundY = chosenY

			local newX = carPos.X + actualMoveDir.X * stepDist
			local newZ = carPos.Z + actualMoveDir.Z * stepDist
			local newPos = Vector3.new(newX, chosenY, newZ)

			-- Smooth Angular Steering
			if actualMoveDir.Magnitude > 0.05 then
				local targetAngle = math.atan2(actualMoveDir.X, actualMoveDir.Z)
				local angleDiff = (targetAngle - curHeadingAngle + math.pi) % (2 * math.pi) - math.pi
				curHeadingAngle = curHeadingAngle + math.clamp(angleDiff, -12 * dt, 12 * dt)
			end

			local currentRot = CFrame.Angles(0, curHeadingAngle, 0)
			local currentCF  = CFrame.new(newPos) * currentRot

			pcall(function()
				car:PivotTo(currentCF)

				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.Anchored = false
					end
				end

				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
					local h = char:FindFirstChildOfClass("Humanoid")
					if h then
						h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
						h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
						h:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
					end
				end

				local activeMissions = workspace:FindFirstChild("ActiveMissions")
				local passengerNpc = (activeMissions and activeMissions:FindFirstChild("RideGO_Passenger")) or workspace:FindFirstChild("RideGO_Passenger")
				if passengerNpc then
					for _, part in ipairs(passengerNpc:GetDescendants()) do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end

				local velocityVec = actualMoveDir * curSpeed
				if seat:IsA("VehicleSeat") then
					seat.Throttle = actualMoveDir.Magnitude > 0 and 1 or 0
					seat.ThrottleFloat = actualMoveDir.Magnitude > 0 and 1 or 0
					seat.AssemblyLinearVelocity = velocityVec
				end
				local prim = car.PrimaryPart or seat
				if prim then
					prim.AssemblyLinearVelocity = velocityVec
				end

				-- 🔒 Sinkronisasi Momentum Tubuh Pengemudi & Penumpang
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and seat and hum then
					if not hum.SeatPart or hum.SeatPart ~= seat then
						mountBike()
					end
					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
					root.AssemblyLinearVelocity = velocityVec
					root.AssemblyAngularVelocity = Vector3.zero
				end

				if passengerNpc then
					local passHrp = passengerNpc:FindFirstChild("HumanoidRootPart")
					if passHrp then
						passHrp.AssemblyLinearVelocity = velocityVec
						passHrp.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end)
		end)

		while not driveFinished and isDrivingActive do
			task.wait(0.03)
		end

		if currentDriveConn then
			pcall(function() currentDriveConn:Disconnect() end)
			currentDriveConn = nil
		end

		-- Natural smooth stop on road: spawn safety plate and restore tire collision
		pcall(function()
			local curPos = car:GetPivot().Position
			ensureSafetyPlate(curPos, 45)

			for _, part in ipairs(car:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					local name = part.Name:lower()
					if name == "dds_collision" or name == "primarypart" or name:find("tire") or name:find("wheel") or name == "paint" or name == "foot" or name == "p" then
						part.CanCollide = true
					else
						part.CanCollide = false
					end
				end
			end
			local seat = car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChild("DriveSeat", true)
			if seat then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
				seat.AssemblyLinearVelocity = Vector3.zero
				seat.AssemblyAngularVelocity = Vector3.zero
			end
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and seat then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end
		end)

		isDrivingActive = false
		local endPos = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position) or (car and car:GetPivot().Position) or Vector3.zero
		return (endPos - destP).Magnitude <= 25
	end

	local function resolveTeamName(targetName)
		if not targetName then return nil end
		local Teams = game:GetService("Teams")
		if Teams then
			-- 1. Exact match
			local exact = Teams:FindFirstChild(targetName)
			if exact then return exact.Name end

			-- 2. Case-insensitive / partial search
			local targetLower = targetName:lower()
			for _, t in ipairs(Teams:GetTeams()) do
				local tLower = t.Name:lower()
				if tLower == targetLower or tLower:find(targetLower) then
					return t.Name
				end
			end

			-- 3. Pencarian tim default non-job (Warga / Pengendara / Civilian / dsb)
			if targetLower:find("citizen") or targetLower:find("civil") or targetLower:find("warga") then
				for _, t in ipairs(Teams:GetTeams()) do
					local tLower = t.Name:lower()
					if tLower:find("warga") or tLower:find("pengendara") or tLower:find("civil") or tLower:find("masyarakat") or tLower:find("player") or tLower:find("default") then
						return t.Name
					end
				end
			end
		end
		return nil
	end

	changeTeam = function(teamName)
		pcall(function()
			local actualTeamName = resolveTeamName(teamName) or teamName
			if not actualTeamName then
				return
			end

			local nameLower = actualTeamName:lower()
			local jobEvents = ReplicatedStorage:FindFirstChild("JobEvents")
			local teamReq = jobEvents and jobEvents:FindFirstChild("TeamChangeRequest")

			if teamReq then
				if nameLower:find("ridego") or nameLower:find("taxi") then
					teamReq:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")
				elseif nameLower:find("courier") or nameLower:find("kurir") then
					teamReq:FireServer("Courier", 11378976, 0, 0, "Detector")
				elseif nameLower:find("barista") then
					teamReq:FireServer("Barista", 11378976, 1, 0, "Detector")
				elseif nameLower:find("civil") or nameLower:find("warga") or nameLower:find("masyarakat") then
					teamReq:FireServer("Civilian", 0, 0, 0, "MainMenu")
				else
					teamReq:FireServer(actualTeamName, 11378976, 1, 0, "Detector")
				end
			end

			local legacyTeamChange = ReplicatedStorage:FindFirstChild("teamChangeRequest")
			if legacyTeamChange then
				legacyTeamChange:FireServer(actualTeamName)
			end
		end)
	end

	------------------------------------------------
	-- 🚕 2. AUTO RIDEGO TAXI CONTROLLER
	------------------------------------------------

	local function getLiveMoneyRaw()
		local playerData = player:FindFirstChild("PlayerData")
		if playerData then
			local rpValue = playerData:FindFirstChild("RPValue")
			if rpValue and rpValue:IsA("NumberValue") then
				return math.floor(rpValue.Value)
			end
		end
		for _, folderName in ipairs({"leaderstats", "Data", "Stats"}) do
			local stats = player:FindFirstChild(folderName)
			if stats then
				for _, v in ipairs(stats:GetChildren()) do
					if v:IsA("NumberValue") or v:IsA("IntValue") then
						local n = v.Name:lower()
						if n:find("rp") or n:find("money") or n:find("cash") or n:find("rupiah") or n:find("balance") then
							return math.floor(tonumber(v.Value) or 0)
						end
					end
				end
			end
		end
		return 0
	end

	local function formatRupiah(val)
		local n = math.floor(val or 0)
		local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
		return "Rp " .. formatted
	end

	local function parsePosition(val)
		if typeof(val) == "Vector3" then return val end
		if typeof(val) == "CFrame" then return val.Position end
		if type(val) == "table" then
			if val.X and val.Y and val.Z then
				return Vector3.new(tonumber(val.X) or 0, tonumber(val.Y) or 0, tonumber(val.Z) or 0)
			end
			if val[1] and val[2] and val[3] then
				return Vector3.new(tonumber(val[1]) or 0, tonumber(val[2]) or 0, tonumber(val[3]) or 0)
			end
		end
		return nil
	end

	local function getPassengerSeat(car)
		if not car then return nil end
		for _, d in ipairs(car:GetDescendants()) do
			if (d:IsA("Seat") or d:IsA("VehicleSeat")) and d.Name ~= "DriveSeat" and not d.Name:find("Drive") then
				return d
			end
		end
		return nil
	end

	local function isPassengerOnboard()
		local activeMissions = workspace:FindFirstChild("ActiveMissions")
		local passenger = (activeMissions and activeMissions:FindFirstChild("RideGO_Passenger")) or workspace:FindFirstChild("RideGO_Passenger")
		if not (passenger and passenger.Parent) then
			passengerSeated = false
			return false
		end

		local car, driveSeat = getPlayerVehicle()
		local pSeat = getPassengerSeat(car)
		local hum = passenger:FindFirstChildOfClass("Humanoid")
		local hrp = passenger:FindFirstChild("HumanoidRootPart")

		-- 1. Cek apakah Humanoid penumpang terhubung ke SeatPart motor
		if hum and hum.SeatPart then
			passengerSeated = true
			return true
		end

		-- 2. Cek apakah kursi penumpang memiliki Occupant
		if pSeat and pSeat.Occupant then
			passengerSeated = true
			return true
		end

		-- 3. Cek apakah ada SeatWeld / weld pengait di kursi atau badan penumpang
		if passenger:FindFirstChild("SeatWeld", true) or (pSeat and pSeat:FindFirstChild("SeatWeld", true)) then
			passengerSeated = true
			return true
		end

		-- 4. Cek jarak fisik antara posisi penumpang dan kursi motor (harus sangat dekat <= 3.0 studs)
		local refPos = pSeat and pSeat.Position or (driveSeat and driveSeat.Position)
		if refPos and hrp then
			local dist = (hrp.Position - refPos).Magnitude
			if dist <= 3.0 then
				passengerSeated = true
				return true
			end
		end

		passengerSeated = false
		return false
	end

	local function executeTripAsync(token, name, initialPickup, initialDrop, initialPickupAddr, initialDropAddr, isAnomaly)
		if taxiBusy then return end
		if not token or token == lastCompletedToken then return end

		taxiBusy = true
		taxiToken = token
		passengerSeated = false
		taxiPickupPos = parsePosition(initialPickup)
		taxiDropPos   = parsePosition(initialDrop)
		taxiPickupAddr = tostring(initialPickupAddr or "")
		taxiDropAddr   = tostring(initialDropAddr or "")

		local tripStartTime = nil
		local tripDistance  = 0

		local isAnomalyTrip = (isAnomaly == true)
		if isAnomalyTrip then
			updateBotActivity("Mengantar Anomali (+Rp 25M)...", Color3.fromRGB(255, 100, 100))
			UI.Notify("ANOMALY ORDER AKTIF", "Mode Proteksi Anomali Aktif (+Rp 25M)...", 4, "warning")
		else
			updateBotActivity("Menjemput Penumpang (" .. tostring(name or "Passenger") .. ")...", Color3.fromRGB(0, 212, 255))
		end

		setTaxiState("NEW_ORDER_DETECTED")
		setTaxiState("PICKING_UP")

		-- 1. Accept Order
		TaxiEvent:FireServer("AcceptOrder", token)
		task.wait(0.3)
		UI.Notify("Order Diterima", "Penumpang: " .. tostring(name or "Passenger"), 2, "info")

		-- 2. Mount bike
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not (hum and hum.SeatPart) then
			local seated = ensureDriverSeated()
			if not seated then
				taxiBusy = false
				taxiToken = nil
				setTaxiState("WAITING_FOR_NEXT_ORDER")
				return
			end
		end

		-- 3. Wait for pickup coordinates
		local waitStart = tick()
		while not taxiPickupPos and taxiActive and (tick() - waitStart < 5) do
			task.wait(0.2)
		end

		-- 4. Drive to Pickup (Kecepatan aman untuk Anomaly agar verifikasi server valid)
		local tripSpeed = isAnomalyTrip and math.min(tonumber(Config.taxiSpeed) or 90, 85) or (tonumber(Config.taxiSpeed) or 90)

		if taxiPickupPos and taxiActive then
			driveVehicleTo(taxiPickupPos, tripSpeed)
		end

		-- 5. Wait for passenger boarding
		if taxiPickupPos and taxiActive then
			updateBotActivity("Menunggu Penumpang Naik Motor...", Color3.fromRGB(255, 200, 50))

			local car, seat = getPlayerVehicle()
			if car then
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
			if seat then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
			end
			ensureDriverSeated()

			local waitStartBoard = tick()
			while not isPassengerOnboard() and taxiActive and (tick() - waitStartBoard < 25) do
				local checkHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if not (checkHum and checkHum.SeatPart) then
					mountBike()
				end
				task.wait(0.4)
			end

			if isPassengerOnboard() then
				tripStartTime = tick()
				if taxiPickupPos and taxiDropPos then
					tripDistance = (Vector3.new(taxiDropPos.X, 0, taxiDropPos.Z) - Vector3.new(taxiPickupPos.X, 0, taxiPickupPos.Z)).Magnitude
				end

				local settleDelay = isAnomalyTrip and math.max(tonumber(Config.passengerBoardDelay) or 3, 3.5) or (tonumber(Config.passengerBoardDelay) or 3)
				task.wait(settleDelay)
			else
				resetTaxiDutyCycle(token, "Boarding Timeout")
				return
			end
		end

		task.wait(0.3)

		-- 6. Drive to Drop-off
		if not taxiDropPos and taxiActive then
			local dropWait = tick()
			while not taxiDropPos and taxiActive and (tick() - dropWait < 5) do
				task.wait(0.2)
			end
		end

		if taxiDropPos and taxiActive then
			if isAnomalyTrip then
				setTaxiState("DRIVING_TO_DESTINATION", "Mengantar Penumpang Anomali...", Color3.fromRGB(255, 100, 100))
			else
				setTaxiState("DRIVING_TO_DESTINATION", "Mengantar Penumpang ke Titik Tujuan...", Color3.fromRGB(0, 212, 255))
			end

			-- Smart Adaptive Pre-Arrival Pacing Guard:
			-- Menyesuaikan kecepatan safe secara dinamis sesuai jarak order dan limit motor (Mio ~90 km/h)
			-- Ditambah Random Human Jitter (74 - 86 km/h) agar variasi statistik di database terlihat 100% organik
			if Config.tripPacing and tripStartTime and tripDistance and tripDistance > 150 then
				local baseSafeSpeed = 89.0 -- Base safe speed Mio (~80 km/h)
				if isAnomalyTrip then
					baseSafeSpeed = 75.0 -- Mode ekstra proteksi untuk Anomali (+Rp 25M)
				elseif tripDistance <= 2000 then
					baseSafeSpeed = 92.0 -- Jarak dekat (~83 km/h)
				elseif tripDistance <= 4000 then
					baseSafeSpeed = 89.0 -- Jarak menengah (~80 km/h)
				else
					baseSafeSpeed = 86.0 -- Jarak jauh (~77 km/h)
				end

				-- Acak variasi kecepatan per-order (-6 s/d +5 stud/s) -> Range: 75 s/d 95 stud/s (74 - 86 km/h)
				local randomJitter = math.random(-60, 50) / 10.0
				local safeSpeed = math.clamp(baseSafeSpeed + randomJitter, 75.0, 95.0)
				_G.HipHubCurrentTripSafeSpeed = safeSpeed

				local minSafeTime = tripDistance / safeSpeed
				local elapsed = tick() - tripStartTime

				if elapsed < minSafeTime then
					-- Berkendara hingga mendekati titik tujuan (jarak ~32 studs di luar zona trigger)
					local dirToDest = (taxiDropPos - (taxiPickupPos or taxiDropPos)).Unit
					if dirToDest.Magnitude < 0.1 then dirToDest = Vector3.new(0, 0, 1) end
					local perimeterPos = taxiDropPos - (dirToDest * 32.0)
					driveVehicleTo(perimeterPos, tripSpeed, 8.0)

					-- Tahan di luar lingkaran tujuan sampai waktu tempuh sah tercapai
					local nowElapsed = tick() - tripStartTime
					if nowElapsed < minSafeTime then
						local remainingWait = minSafeTime - nowElapsed
						if remainingWait > 0.1 then
							setTaxiState("PACING")
							local car, seat = getPlayerVehicle()
							if car then
								for _, part in ipairs(car:GetDescendants()) do
									if part:IsA("BasePart") then
										part.AssemblyLinearVelocity = Vector3.zero
										part.AssemblyAngularVelocity = Vector3.zero
									end
								end
							end
							if seat then
								seat.Throttle = 0
								seat.ThrottleFloat = 0
							end
							local pacingStart = tick()
							while (tick() - pacingStart < remainingWait) and taxiActive and not isResettingTaxi do
								local rem = math.max(0, math.floor((remainingWait - (tick() - pacingStart)) * 10) / 10)
								updateBotActivity(string.format("Mengantar Penumpang (%.1fs)...", rem), Color3.fromRGB(0, 212, 255))
								task.wait(0.2)
							end
						end
					end
					if isAnomalyTrip then
						setTaxiState("DRIVING_TO_DESTINATION", "Mengantar Penumpang Anomali...", Color3.fromRGB(255, 100, 100))
					else
						setTaxiState("DRIVING_TO_DESTINATION", "Mengantar Penumpang ke Titik Tujuan...", Color3.fromRGB(0, 212, 255))
					end
				end
			end

			-- Masuk tepat ke tengah titik tujuan utama (radius <= 4.0 studs) agar trigger penumpang turun otomatis aktif!
			driveVehicleTo(taxiDropPos, tripSpeed, 4.0)

			setTaxiState("DROPPING_OFF", "Menunggu Penumpang Turun...", Color3.fromRGB(150, 110, 255))
			local car, seat = getPlayerVehicle()
			if car then
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
			if seat then
				seat.Throttle = 0
				seat.ThrottleFloat = 0
			end
			ensureDriverSeated()

			local disembarkWait = tick()

			while isPassengerOnboard() and taxiActive and not isResettingTaxi do
				local nowT = tick()

				-- Deteksi notifikasi "Memverifikasi rute" / "Verifying your trip route"
				if isRouteVerificationStuck() then
					updateBotActivity("Memverifikasi Rute... Menunggu...", Color3.fromRGB(255, 180, 50))
					-- Berikan jeda waktu server menyelesaikan verifikasi tanpa melakukan pembatalan paksa
					if (nowT - disembarkWait > 20.0) then
						break
					end
				else
					-- Fail-safe disembark: Beri waktu wajar (15s) agar animasi/desync server turun penumpang selesai
					if (nowT - disembarkWait > 15.0) then
						break
					end
				end

				task.wait(0.4)
			end

			task.wait(0.5)
		end

		-- 7. Complete Trip & Acknowledge (Dengan Pacing Kecepatan Rata-Rata Aman Server untuk SEMUA Order)
		if taxiActive then
			-- Server Average Velocity Pacing (Hanya jika Smart Pacing ON)
			if Config.tripPacing and tripStartTime and tripDistance and tripDistance > 150 then
				local safeMaxSpeed = _G.HipHubCurrentTripSafeSpeed or 88.0
				local minSafeTripTime = tripDistance / safeMaxSpeed
				local elapsed = tick() - tripStartTime
				if elapsed < minSafeTripTime then
					local pacingWait = minSafeTripTime - elapsed
					if pacingWait > 0.1 then
						task.wait(pacingWait)
					end
				end
			end

			-- Jeda natural bervariasi sebelum menyelesaikan trip (0.8s s/d 1.8s)
			local randomHumanDelay = (isAnomalyTrip and 2.0 or 0.8) + (math.random(0, 10) / 10.0)
			task.wait(randomHumanDelay)
			TaxiEvent:FireServer("AckTripComplete")
			_G.HipHubCompletedTrips = (_G.HipHubCompletedTrips or 0) + 1
			local totalDone = _G.HipHubCompletedTrips
			UI.Notify("Trip Selesai", string.format("Order #%d selesai.", totalDone), 2.5, "success")

			-- Scheduled Auto-Rejoin Cycle (Reset Strike & Session Memory di Server)
			local autoRejoinCount = tonumber(Config.autoRejoinOrders) or 30
			if autoRejoinCount > 0 and totalDone > 0 and (totalDone % autoRejoinCount == 0) then
				UI.Notify("Auto-Rejoin", "Menghubungkan ulang ke server...", 3, "info")
				updateBotActivity("Offline & Rejoining Server...", Color3.fromRGB(0, 212, 255))

				lastCompletedToken = token
				taxiBusy = false
				taxiToken = nil
				taxiPickupPos = nil
				taxiDropPos = nil
				taxiPickupAddr = ""
				taxiDropAddr = ""
				passengerSeated = false

				-- 🛡️ Pastikan status kerja RideGO benar-benar GoOffline & Team Warga sebelum Rejoin
				pcall(function()
					local ev = getTaxiEvent()
					if ev then
						ev:FireServer("GoOffline")
					end
					if changeTeam then
						changeTeam("Warga")
					end
				end)

				-- 🛡️ Inject queue_on_teleport untuk Auto-Resume RideGO di server baru
				local queueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
				if queueTeleport then
					pcall(function()
						queueTeleport([[
							getgenv().AUTO_RESUME_RIDEGO = true
							task.spawn(function()
								pcall(function()
									local Lighting = game:GetService("Lighting")
									local blur = Lighting:FindFirstChild("menuBlur")
									if blur then blur.Enabled = false blur.Size = 0 end
									local player = game:GetService("Players").LocalPlayer
									if player and player:FindFirstChild("PlayerGui") then
										local mainUI = player.PlayerGui:FindFirstChild("MainUI")
										if mainUI and mainUI:FindFirstChild("Holder") then
											mainUI.Holder.Visible = false
										end
									end
									local menuEvent = game:GetService("ReplicatedStorage"):WaitForChild("menuToggleRequest", 5)
									if menuEvent and menuEvent:IsA("RemoteEvent") then
										menuEvent:FireServer()
									end
									game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
								end)
							end)
						]])
					end)
				end

				-- Pastikan autoRideGO tetap AKTIF di config agar saat rejoin langsung lanjut otomatis
				if _G.HipHubConfig and _G.HipHubConfig.farm then
					_G.HipHubConfig.farm.autoRideGO = true
				end
				if _G.HipHubSaveConfig then
					_G.HipHubSaveConfig(true)
				end

				-- Reconnect via TeleportService
				task.wait(1.0)
				pcall(function()
					local TeleportService = game:GetService("TeleportService")
					TeleportService:Teleport(game.PlaceId, player)
				end)

				task.wait(4.0)
				pcall(function()
					local TeleportService = game:GetService("TeleportService")
					TeleportService:Teleport(game.PlaceId, player)
				end)
				return
			end

			-- Cooldown Istirahat 1 Menit setiap kelipatan 10 orderan (Hanya jika pacing aktif & tidak pas saat rejoin)
			if Config.tripPacing and totalDone > 0 and (totalDone % 10 == 0) then
				UI.Notify("Istirahat", "Jeda istirahat 1 menit.", 4, "info")
				lastCompletedToken = token
				taxiBusy = false
				taxiToken = nil
				taxiPickupPos = nil
				taxiDropPos = nil
				taxiPickupAddr = ""
				taxiDropAddr = ""
				passengerSeated = false

				if autoRideGoToggle and autoRideGoToggle.Set then
					autoRideGoToggle.Set(false)
				elseif toggleAutoRideGO then
					toggleAutoRideGO(false)
				end

				task.spawn(function()
					local restStart = tick()
					while (tick() - restStart < 60) do
						local remSec = 60 - math.floor(tick() - restStart)
						updateBotActivity(string.format("Istirahat (%ds)...", remSec), Color3.fromRGB(255, 170, 50))
						task.wait(1)
					end
					UI.Notify("Lanjut Farm", "Melanjutkan order.", 2.5, "info")
					if autoRideGoToggle and autoRideGoToggle.Set then
						autoRideGoToggle.Set(true)
					elseif toggleAutoRideGO then
						toggleAutoRideGO(true)
					end
				end)
				return
			end
		end

		lastCompletedToken = token
		taxiBusy = false
		taxiToken = nil
		taxiPickupPos = nil
		taxiDropPos = nil
		taxiPickupAddr = ""
		taxiDropAddr = ""
		passengerSeated = false

		-- Target Earn Check: Jika target uang tercapai, otomatis matikan Auto-Farm
		local targetEarn = _G.HipHubConfig and _G.HipHubConfig.misc and tonumber(_G.HipHubConfig.misc.targetEarn) or 0
		if targetEarn > 0 then
			local curM = getLiveMoneyRaw()
			if curM >= targetEarn then
				UI.Notify("Target Tercapai", string.format("Total: %s. Auto-Farm selesai.", formatRupiah(curM)), 4, "success")
				if autoRideGoToggle and autoRideGoToggle.Set then
					autoRideGoToggle.Set(false)
				end
				return
			end
		end

		setTaxiState("WAITING_FOR_NEXT_ORDER")
	end

	-- Taxi Remote Events Listener
	if TaxiEvent then
		_G.HipHubTaxiLog = {}

		TaxiEvent.OnClientEvent:Connect(function(...)
			local raw = { ... }
			table.insert(_G.HipHubTaxiLog, { t = tick(), args = raw })

			if not taxiActive then return end

			local eventType = tostring(raw[1] or "")
			local payload   = type(raw[2]) == "table" and raw[2] or nil

			if eventType == "DutyStarted" then
				isRideGoDutyOnline = true
				UI.Notify("RideGO Online", "Driver aktif & siap menerima order.", 2.5, "success")
				if not taxiBusy then
					setTaxiState("WAITING_FOR_NEXT_ORDER")
				end

			elseif eventType == "OrderOffer" and not taxiBusy then
				local token = payload and (payload.Token or payload.token or payload.OrderId)
				local name  = payload and (payload.PassengerName or payload.Name) or "Passenger"
				local isAnom = payload and payload.IsAnomaly or false
				local fare  = payload and (payload.Fare or payload.Price) or 0
				local pickPos  = payload and (payload.PickupPos or payload.PickupPosition or payload.Pickup or payload.StartPos)
				local dropP    = payload and (payload.DropPos or payload.DropPosition or payload.Destination or payload.Drop or payload.TargetPos)
				local pickAddr = payload and (payload.PickupAddr or payload.PickupName or payload.PickupLocation or payload.StartAddr or payload.Pickup)
				local dropAddr = payload and (payload.DropAddr or payload.DestinationAddr or payload.DropName or payload.TargetAddr or payload.Destination)

				if not token or token == lastCompletedToken then return end

				UI.Notify("Order Baru", name .. " - Rp " .. tostring(fare), 2.5, "info")

				task.spawn(executeTripAsync, token, name, pickPos, dropP, pickAddr, dropAddr, isAnom)

			elseif eventType == "OrderAccepted" then
				if payload then
					local pick = payload.PickupPos or payload.PickupPosition or payload.Pickup or payload.StartPos
					local drop = payload.DropPos or payload.DropPosition or payload.Destination or payload.Drop or payload.TargetPos
					if pick then taxiPickupPos = parsePosition(pick) end
					if drop then taxiDropPos   = parsePosition(drop) end
					if payload.PickupAddr then taxiPickupAddr = tostring(payload.PickupAddr) end
					if payload.DropAddr then taxiDropAddr = tostring(payload.DropAddr) end
				end

			elseif eventType == "PassengerBoarding" then
				-- Passenger boarding silently

			elseif eventType == "TripStarted" or eventType == "PassengerSeated" then
				passengerSeated = true
				if payload then
					local drop = payload.DropPos or payload.DropPosition or payload.Destination or payload.Drop or payload.TargetPos
					if drop then taxiDropPos = parsePosition(drop) end
					if payload.DropAddr then taxiDropAddr = tostring(payload.DropAddr) end
				end

			elseif eventType == "DutyEnded" then
				isRideGoDutyOnline = false
				if taxiActive and not taxiBusy and not isResettingTaxi then
					updateBotActivity("Menghubungkan Kembali ke RideGO...", Color3.fromRGB(255, 200, 50))
					task.spawn(function()
						task.wait(1.2)
						if taxiActive and not taxiBusy and not isRideGoDutyOnline and not isResettingTaxi then
							if recoverRideGoDuty then
								recoverRideGoDuty()
							end
						end
					end)
				end

			elseif eventType == "OrderCompleted" or eventType == "TripComplete" then
				passengerSeated = false
				UI.Notify("Order Selesai", "Pembayaran diterima.", 2.5, "success")
				task.wait(0.5)
				TaxiEvent:FireServer("AckTripComplete")
				if not taxiBusy then
					if isRideGoDutyOnline then
						setTaxiState("WAITING_FOR_NEXT_ORDER")
					else
						setTaxiState("CONNECTING", "Menghubungkan ke RideGO...", Color3.fromRGB(255, 200, 50))
					end
					if taxiActive then
						task.wait(1.2)
						if recoverRideGoDuty then
							recoverRideGoDuty()
						else
							local curT = player.Team and player.Team.Name or ""
							if curT:lower():find("ridego") and TaxiEvent then
								TaxiEvent:FireServer("GoOnline")
							end
						end
					end
				end

			elseif eventType == "OrderExpired" or eventType == "OrderCancelled" or eventType == "OrderDeclined" then
				taxiBusy = false
				taxiToken = nil
				taxiPickupPos = nil
				taxiDropPos = nil
				passengerSeated = false
				cancelActiveDrive()
				if isRideGoDutyOnline then
					setTaxiState("WAITING_FOR_NEXT_ORDER")
				else
					setTaxiState("CONNECTING", "Menghubungkan ke RideGO...", Color3.fromRGB(255, 200, 50))
				end
				if taxiActive then
					task.wait(1.5)
					if recoverRideGoDuty then
						recoverRideGoDuty()
					else
						local curT = player.Team and player.Team.Name or ""
						if curT:lower():find("ridego") and TaxiEvent then
							TaxiEvent:FireServer("GoOnline")
						end
					end
				end
			end
		end)
	end

	-- Phone Screen Overlay Poller & Auto-Dismiss Complete Screen & Verification Watchdog
	startPhoneOverlayPoller = function()
		if taxiOverlayPoller then return end
		taxiOverlayPoller = task.spawn(function()
			local lastKeepAliveTime = tick()
			local lastAfkCameraTime = tick()
			local lastTrackedPos = nil
			local lastPosMovedTime = tick()

			while taxiActive do
				task.wait(0.25)
				if taxiActive and not isResettingTaxi then
					pcall(function()
						-- 0. Watchdog Macet Cerdas (HANYA saat sedang aktif berkendara):
						local isDriving = (isDrivingActive or taxiState == "DRIVING_TO_DESTINATION")
						if isDriving then
							local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
							local curPos = root and root.Position
							if curPos then
								if not lastTrackedPos then
									lastTrackedPos = curPos
									lastPosMovedTime = tick()
								else
									local dPos = (curPos - lastTrackedPos).Magnitude
									if dPos > 3.5 then
										lastTrackedPos = curPos
										lastPosMovedTime = tick()
									else
										-- Hanya reset jika diam > 18 detik saat posisi seharusnya berkendara (terjebak void/tembok)
										if (tick() - lastPosMovedTime >= 18.0) and not isResettingTaxi then
											lastPosMovedTime = tick()
											lastTrackedPos = nil
											task.spawn(function()
												if restartAutoRideGoToggle then
													restartAutoRideGoToggle("Stuck saat Berkendara (18s)")
												end
											end)
											return
										end
									end
								end
							end
						else
							-- Saat menganggur / menunggu orderan, segarkan timer dan biarkan bot tetap Online dengan tenang
							lastPosMovedTime = tick()
							lastTrackedPos = nil
							dropoffStuckTime = nil
						end

						local pg = player:FindFirstChild("PlayerGui")
						local phone = pg and pg:FindFirstChild("Phone")
						local rideGO = phone and phone:FindFirstChild("RideGO", true)
						local appFrame = rideGO and rideGO:FindFirstChild("AppFrame")
						local complete = appFrame and appFrame:FindFirstChild("CompleteOverlay")
						local overlay = appFrame and appFrame:FindFirstChild("OrderOverlay")

						-- 1. Auto-Dismiss Complete Screen agar UI tidak pernah nyangkut di ringkasan trip
						if complete and complete.Visible then
							complete.Visible = false
							if TaxiEvent then
								TaxiEvent:FireServer("AckTripComplete")
							end
						end

						-- 2. Auto-Accept orderan baru yang masuk
						if overlay and overlay.Visible and not taxiBusy then
							if #_G.HipHubTaxiLog > 0 then
								local last = _G.HipHubTaxiLog[#_G.HipHubTaxiLog]
								local args = last.args or {}
								if args[1] == "OrderOffer" and type(args[2]) == "table" and args[2].Token then
									if args[2].Token ~= lastCompletedToken then
										overlay.Visible = false
										task.spawn(executeTripAsync, args[2].Token, args[2].PassengerName, args[2].PickupPos, args[2].DropPos, args[2].PickupAddr, args[2].DropAddr, args[2].IsAnomaly)
									end
								end
							end
						end

						-- 3. Active Duty & Redfinger Seat-Recovery Engine (setiap 12s saat menganggur)
						if not taxiBusy and (tick() - lastKeepAliveTime >= 12) then
							lastKeepAliveTime = tick()
							local char = player.Character
							local hum  = char and char:FindFirstChildOfClass("Humanoid")
							local isSeated = (hum and hum.SeatPart ~= nil)
							local curT = player.Team and player.Team.Name or ""

							if not isSeated or not isRideGoDutyOnline or not curT:lower():find("ridego") then
								if recoverRideGoDuty then
									recoverRideGoDuty()
								end
							else
								-- Jika sudah duduk & online di tim RideGO, kirim keep-alive santai ke server
								if TaxiEvent then
									TaxiEvent:FireServer("GoOnline")
								end
							end
						end

						-- 4. Anti-AFK Camera Keep-Alive (setiap 25s tanpa disallowed service)
						if (tick() - lastAfkCameraTime >= 25) then
							lastAfkCameraTime = tick()
							pcall(function()
								local cam = workspace.CurrentCamera
								if cam then
									local cf = cam.CFrame
									cam.CFrame = cf * CFrame.Angles(0, 0.0004, 0)
									task.wait(0.04)
									if cam then
										cam.CFrame = cf
									end
								end
							end)
						end

						-- 5. Target Earn Check Periodik
						local targetEarn = _G.HipHubConfig and _G.HipHubConfig.misc and tonumber(_G.HipHubConfig.misc.targetEarn) or 0
						if targetEarn > 0 then
							local curM = getLiveMoneyRaw()
							if curM >= targetEarn then
								UI.Notify("Target Earn Tercapai!", string.format("Total Uang: %s (Target: %s). Auto-Farm selesai!", formatRupiah(curM), formatRupiah(targetEarn)), 5, "success")
								if autoRideGoToggle and autoRideGoToggle.Set then
									autoRideGoToggle.Set(false)
								end
								return
							end
						end
					end)
				end
			end
			taxiOverlayPoller = nil
		end)
	end

	toggleAutoRideGO = function(state)
		taxiActive         = state
		_G.HipHubTaxiActive = state
		taxiBusy           = false
		taxiToken          = nil
		lastCompletedToken = nil
		taxiPickupPos      = nil
		taxiDropPos        = nil
		taxiPickupAddr      = ""
		taxiDropAddr        = ""
		passengerSeated    = false
		isRideGoDutyOnline = false
		taxiState          = state and "CONNECTING" or "IDLE"
		Config.autoRideGO  = state
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.autoRideGO = state
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end

		if state then
			-- Mutual exclusion: matikan Auto Courier jika sedang aktif
			Config.autoCourier = false
			courierActive = false
			_G.HipHubCourierActive = false
			if _G.HipHubConfig and _G.HipHubConfig.farm then
				_G.HipHubConfig.farm.autoCourier = false
			end
			if autoCourierToggle and autoCourierToggle.Get and autoCourierToggle.Get() then
				pcall(function() autoCourierToggle.Set(false) end)
			end
			if _G.HipHubSaveConfig then
				_G.HipHubSaveConfig(true)
			end
			setTaxiState("CONNECTING", "Menghubungkan ke RideGO...", Color3.fromRGB(255, 200, 50))

			if startPhoneOverlayPoller then
				startPhoneOverlayPoller()
			end

			task.spawn(function()
				if recoverRideGoDuty then
					recoverRideGoDuty()
				end
			end)

			UI.Notify("Auto-Farm ON", "RideGO Auto-Farm aktif.", 2.5, "success")
		else
			isRideGoDutyOnline = false
			setTaxiState("IDLE")
			if taxiOverlayPoller then
				task.cancel(taxiOverlayPoller)
				taxiOverlayPoller = nil
			end
			if cancelActiveDrive then
				cancelActiveDrive()
			end
			local ev = getTaxiEvent()
			if ev then
				ev:FireServer("CancelTrip")
				ev:FireServer("CancelOrder")
				ev:FireServer("GoOffline")
			end
			-- Hapus model NPC penumpang dari workspace agar tidak tersangkut di motor
			pcall(function()
				local activeMissions = workspace:FindFirstChild("ActiveMissions")
				local pNpc = (activeMissions and activeMissions:FindFirstChild("RideGO_Passenger")) or workspace:FindFirstChild("RideGO_Passenger")
				if pNpc then pNpc:Destroy() end
			end)
			if not courierActive and not Config.autoCourier then
				updateBotActivity("Bot Idle (Auto-Farm OFF)", Color3.fromRGB(160, 175, 200))
				UI.Notify("Auto-Farm OFF", "RideGO Auto-Farm dinonaktifkan.", 2, "info")
			end
		end
	end

	------------------------------------------------
	-- 3. AUTO COURIER DELIVERY CONTROLLER
	------------------------------------------------
	courierActive                = false
	local activeCourierDestId    = nil
	local courierLoopThread      = nil
	local courierShiftLimit      = false
	local courierLastJobTime     = os.clock()
	local courierResetFlag       = false
	local courierStartTime       = os.clock()
	local courierTotalEarn       = 0
	local courierRejoinPending   = false

	local function formatCourierTime(sec)
		local h = math.floor(sec / 3600)
		local m = math.floor((sec % 3600) / 60)
		local s = math.floor(sec % 60)
		return string.format("%02dh %02dm %02ds", h, m, s)
	end

	local function formatRupiah(n)
		return "Rp. " .. tostring(math.floor(n)):reverse():gsub("%d%d%d", "%1."):reverse():gsub("^%.", "")
	end

	local function rejoinCourierServer(reason)
		if courierRejoinPending then return end
		courierRejoinPending = true

		UI.Notify("Auto-Rejoin", "Menghubungkan ulang ke server...", 3, "info")
		updateBotActivity("Auto-Rejoining Server...", Color3.fromRGB(255, 120, 50))

		-- 🛑 Hentikan loop kurir lokal tanpa mematikan config auto-resume
		courierActive = false
		_G.HipHubCourierActive = false

		-- 1. Berhenti total motor di tempat & turunkan driver secara bersih (Mencegah mobile teleport crash)
		pcall(function()
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.SeatPart then
				hum.Sit = false
				task.wait(0.2)
			end
			local car, seat = getPlayerVehicle()
			if car then
				for _, part in ipairs(car:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity  = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
						part.Anchored = true
					end
				end
			end
		end)

		-- 2. Pastikan autoCourier tetap AKTIF di Config agar saat auto-rejoin langsung jalan lagi
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.autoCourier = true
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end

		-- 3. Inject queue_on_teleport untuk Auto-Resume Courier di server baru
		local queueTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
		if queueTeleport then
			pcall(function()
				queueTeleport([[
					getgenv().AUTO_RESUME_COURIER = true
					task.spawn(function()
						pcall(function()
							local Lighting = game:GetService("Lighting")
							local blur = Lighting:FindFirstChild("menuBlur")
							if blur then blur.Enabled = false blur.Size = 0 end
							local player = game:GetService("Players").LocalPlayer
							if player and player:FindFirstChild("PlayerGui") then
								local mainUI = player.PlayerGui:FindFirstChild("MainUI")
								if mainUI and mainUI:FindFirstChild("Holder") then
									mainUI.Holder.Visible = false
								end
							end
							local menuEvent = game:GetService("ReplicatedStorage"):WaitForChild("menuToggleRequest", 5)
							if menuEvent and menuEvent:IsA("RemoteEvent") then
								menuEvent:FireServer()
							end
							game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
						end)
					end)
				]])
			end)
		end

		-- 4. Reconnect via TeleportService
		task.wait(1.0)
		pcall(function()
			local TeleportService = game:GetService("TeleportService")
			TeleportService:Teleport(game.PlaceId, player)
		end)

		task.wait(4.0)
		pcall(function()
			local TeleportService = game:GetService("TeleportService")
			TeleportService:Teleport(game.PlaceId, player)
		end)
	end

	-- Listener untuk ServiceEvent dari Delivery System
	local deliverySys = ReplicatedStorage:FindFirstChild("Delivery System")
	local deliverySettingsFolder = deliverySys and deliverySys:FindFirstChild("Settings")
	local deliveryServiceEvent = deliverySettingsFolder and deliverySettingsFolder:FindFirstChild("ServiceEvent")

	if deliveryServiceEvent then
		deliveryServiceEvent.OnClientEvent:Connect(function(action, eventType, locId)
			if action == "ServiceEvent" and eventType == "Create" and locId then
				activeCourierDestId = tostring(locId)
				courierLastJobTime = os.clock()
				courierResetFlag = false
			elseif eventType ~= "Create" and eventType ~= "ServiceEvent" then
				activeCourierDestId = nil
			end
		end)
	end

	-- Deteksi Shift Limit via NotifEvent & NOTIF text (Otomatis Auto-Rejoin di belakang layar)
	local function handleCourierShiftLimit()
		if courierShiftLimit then return end
		courierShiftLimit = true

		rejoinCourierServer("Batas Shift Kurir Server Tercapai")
	end

	pcall(function()
		local notifFolder = ReplicatedStorage:WaitForChild("Notification", 5)
		local notifEvt = notifFolder and notifFolder:WaitForChild("NotifEvent", 5)
		if notifEvt then
			notifEvt.OnClientEvent:Connect(function(k, v)
				if not (courierActive or _G.HipHubCourierActive) then return end
				local isLimit = false
				if typeof(v) == "string" and (v:find("NC_SHIFT_LIMIT") or v:find("shift kurir tercapai") or v:lower():find("courier shift")) then
					isLimit = true
				elseif typeof(v) == "table" and (v.k == "NC_SHIFT_LIMIT" or (v.a and tostring(v.a):find("NC_SHIFT_LIMIT"))) then
					isLimit = true
				elseif typeof(k) == "string" and (k:find("NC_SHIFT_LIMIT") or k:lower():find("courier shift")) then
					isLimit = true
				end
				if isLimit then
					task.spawn(handleCourierShiftLimit)
				end
			end)
		end
	end)

	-- Monitor NOTIF UI untuk pelacakan akumulasi pendapatan real-time & shift limit (Non-blocking)
	task.spawn(function()
		pcall(function()
			local pg = player:WaitForChild("PlayerGui", 10)
			if not pg then return end
			local mainUI = pg:WaitForChild("MainUI", 10)
			if not mainUI then return end
			local frame4 = mainUI:WaitForChild("Frame4", 10)
			if not frame4 then return end
			local notif = frame4:WaitForChild("NOTIF", 10)
			if not notif then return end

			local lastNotifText = ""
			notif:GetPropertyChangedSignal("Text"):Connect(function()
				if not (courierActive or _G.HipHubCourierActive) then return end
				local text = notif.Text
				if text == "" or text == lastNotifText then return end
				lastNotifText = text

				if text:find("NC_SHIFT_LIMIT") or text:find("shift kurir tercapai") or text:lower():find("courier shift") then
					task.spawn(handleCourierShiftLimit)
					return
				end

				local digits = text:gsub("[^%d]", "")
				if digits ~= "" then
					local amount = tonumber(digits) or 0
					if amount > 1000 and amount < 15000000 then
						courierTotalEarn = courierTotalEarn + amount
					end
				end
			end)
		end)
	end)


	local function getCourierPackageTool()
		local char = player.Character
		if char then
			local t = char:FindFirstChild("Box") or char:FindFirstChild("Package") or char:FindFirstChild("Paket")
			if t and t:IsA("Tool") then return t end
		end
		local bp = player:FindFirstChild("Backpack")
		if bp then
			local t = bp:FindFirstChild("Box") or bp:FindFirstChild("Package") or bp:FindFirstChild("Paket")
			if t and t:IsA("Tool") then return t end
		end
		return nil
	end

	hasCourierPackage = function()
		return getCourierPackageTool() ~= nil
	end

	local function equipCourierPackage()
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		local bp   = player:FindFirstChild("Backpack")
		if hum and bp then
			local tool = bp:FindFirstChild("Box") or bp:FindFirstChild("Package") or bp:FindFirstChild("Paket")
			if tool and tool:IsA("Tool") then
				hum:EquipTool(tool)
				task.wait(0.2)
			end
		end
		local active = char and (char:FindFirstChild("Box") or char:FindFirstChild("Package") or char:FindFirstChild("Paket"))
		return active and active:IsA("Tool") and active or nil
	end

	-- 🛵 Official Vehicle Courier Navigation (Ground-to-Ground & Road Driving)
	local function driveCourierTo(targetCF, speed, stopRadius, abortCheck)
		if isRespawning then return false end
		local char = player.Character
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not char or not hum or hum.Health <= 0 then return false end

		local car, seat = getPlayerVehicle()
		if not (car and seat and hum.SeatPart == seat) then
			local ok = ensureDriverSeated()
			if not ok then
				spawnTaxiBike()
				task.wait(1.5)
				ensureDriverSeated()
			end
			car, seat = getPlayerVehicle()
		end

		local targetPos = typeof(targetCF) == "CFrame" and targetCF.Position or targetCF
		local driveSpeed = tonumber(speed) or tonumber(Config.courierSpeed) or 85.0
		driveSpeed = math.clamp(driveSpeed, 60.0, 95.0)

		local radius = tonumber(stopRadius) or 15.0
		return driveVehicleTo(targetPos, driveSpeed, radius, nil, abortCheck)
	end

	getActiveCourierTarget = function()
		local curDeliveryAttr = player:GetAttribute("CurrentDelivery")
		if curDeliveryAttr and tostring(curDeliveryAttr) ~= "" and tostring(curDeliveryAttr) ~= "0" then
			return tostring(curDeliveryAttr)
		end
		return activeCourierDestId
	end

	local function getCourierDestination()
		local livrason = workspace:FindFirstChild("Livrason")
		local locFolder = livrason and livrason:FindFirstChild("Location")
		if not locFolder then return nil, nil, nil end

		local targetId = getActiveCourierTarget()

		if targetId then
			local child = locFolder:FindFirstChild(targetId)
			local block = child and child:FindFirstChild("Block")
			if block then
				local crate = block:FindFirstChild("Dust Food Crates 56") or block:FindFirstChild("Meshes/Rac1ks_Cylinder.023")
				local dropCF = crate and crate.CFrame or block.CFrame
				local prompt = block:FindFirstChildOfClass("ProximityPrompt")
				return dropCF, prompt, targetId
			end
		end

		for _, child in ipairs(locFolder:GetChildren()) do
			local block = child:FindFirstChild("Block")
			local prompt = block and block:FindFirstChildOfClass("ProximityPrompt")
			local point = child:FindFirstChild("POINT")
			local bg = point and point:FindFirstChildOfClass("BillboardGui")

			if (prompt and prompt.Enabled) or (bg and bg.Enabled) then
				local crate = block and (block:FindFirstChild("Dust Food Crates 56") or block:FindFirstChild("Meshes/Rac1ks_Cylinder.023"))
				local dropCF = crate and crate.CFrame or (block and block.CFrame)
				return dropCF, prompt, child.Name
			end
		end

		return nil, nil, nil
	end

	local function triggerCourierPrompt(prompt)
		if not prompt then return false end
		pcall(function()
			prompt.HoldDuration = 0
			if fireproximityprompt then
				fireproximityprompt(prompt)
			elseif prompt.InputHoldBegin then
				prompt:InputHoldBegin()
				task.wait(0.1)
				prompt:InputHoldEnd()
			end
		end)
		return true
	end

	toggleAutoCourier = function(state)
		courierActive = state
		_G.HipHubCourierActive = state
		Config.autoCourier = state
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.autoCourier = state
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end

		if state then
			-- Mutual exclusion: matikan RideGO jika sedang aktif
			Config.autoRideGO = false
			taxiActive = false
			_G.HipHubTaxiActive = false
			if _G.HipHubConfig and _G.HipHubConfig.farm then
				_G.HipHubConfig.farm.autoRideGO = false
			end
			if autoRideGoToggle and autoRideGoToggle.Get and autoRideGoToggle.Get() then
				pcall(function() autoRideGoToggle.Set(false) end)
			end
			if _G.HipHubSaveConfig then
				_G.HipHubSaveConfig(true)
			end

			courierStartTime = os.clock()
			courierRejoinPending = false
			updateBotActivity("Memulai Auto Kurir...", Color3.fromRGB(0, 212, 255))
			UI.Notify("Auto-Courier ON", "Courier Auto-Worker aktif.", 2.5, "success")

			task.spawn(function()
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not (hum and hum.SeatPart) then
					updateBotActivity("Mempersiapkan Kendaraan...", Color3.fromRGB(0, 212, 255))
					local ok = ensureDriverSeated()
					if not ok then
						spawnFarmVehicle()
						task.wait(1.5)
						ensureDriverSeated()
					end
				end
			end)

			if courierLoopThread then
				pcall(function() task.cancel(courierLoopThread) end)
				courierLoopThread = nil
			end
			courierLoopThread = task.spawn(function()
				local restarting = false
				while courierActive do
					task.wait(0.5)
					if not courierActive then break end
					if isRespawning then
						task.wait(0.5)
					else
						if courierResetFlag then
							task.wait(2)
							courierResetFlag = false
							restarting = false
							activeCourierDestId = nil
						end

						local char = player.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if char and hum and hum.Health > 0 and not courierShiftLimit then
							local cycleOk, cycleErr = pcall(function()
						-- 1. Pastikan Tim adalah "Courier"
						local curTeam = player.Team and player.Team.Name or ""
						if not curTeam:lower():find("courier") then
							updateBotActivity("Ganti Tim ke Kurir...", Color3.fromRGB(0, 212, 255))
							pcall(function()
								local jobEvents = ReplicatedStorage:FindFirstChild("JobEvents")
								local teamReq = jobEvents and jobEvents:FindFirstChild("TeamChangeRequest")
								if teamReq then
									teamReq:FireServer("Courier", 11378976, 0, 0, "Detector")
								end
							end)
							task.wait(1.5)
							return
						end

						-- 2. Jika Belum Ada Job / Paket -> Ambil di Depot
						local currentTarget = getActiveCourierTarget()
						if not currentTarget and not hasCourierPackage() then
							if not restarting then
								local takeCF = CFrame.new(-5105.6, 4.5, -3759.0)
								updateBotActivity("Menuju Depot Paket...", Color3.fromRGB(0, 212, 255))
								
								-- Berkendara motor ke Depot
								local takeArrived = driveCourierTo(takeCF, Config.courierSpeed or 85, 14, function()
									return getActiveCourierTarget() ~= nil or hasCourierPackage()
								end)

								if not courierActive or courierShiftLimit then return end

								-- Jika sudah mendapat pesanan/paket di perjalanan, lewati interaksi depot
								if getActiveCourierTarget() or hasCourierPackage() then
									restarting = false
									return
								end

								if not takeArrived then
									warn("[HipHub DDS Courier] Belum sampai di depot, mencoba kembali...")
									task.wait(1.0)
									return
								end

								-- Ambil paket di Depot langsung dari atas motor (Tetap duduk di jok kemudi)
								ensureDriverSeated()

								pcall(function()
									local livrason = workspace:FindFirstChild("Livrason")
									local takePrompt = livrason and livrason:FindFirstChild("Take1") and livrason.Take1:FindFirstChild("Take") and livrason.Take1.Take:FindFirstChildOfClass("ProximityPrompt")
									if takePrompt then
										triggerCourierPrompt(takePrompt)
									end
								end)
								restarting = true
							end

							local waited = 0
							while courierActive and not getActiveCourierTarget() and not hasCourierPackage() and not courierShiftLimit and waited < 6 do
								task.wait(0.5)
								waited = waited + 0.5
							end

							if courierActive and not getActiveCourierTarget() and not hasCourierPackage() and not courierShiftLimit then
								restarting = false
							end

							if courierActive and not getActiveCourierTarget() and not hasCourierPackage() then
								local idle = os.clock() - courierLastJobTime
								if idle > 15 and not courierResetFlag then
									courierResetFlag = true
								end
								if idle > 30 then
									if deliveryServiceEvent then
										deliveryServiceEvent:FireServer("RequestJobUpdate")
									end
									courierLastJobTime = os.clock()
								end
							end
						else
							-- 3. Antar Paket ke Titik Pengantaran
							updateBotActivity("Mencari Titik Pengantaran...", Color3.fromRGB(0, 212, 255))
							local dropCF, dropPrompt, destId = getCourierDestination()

							local tWaitDest = tick()
							while not dropCF and courierActive and (tick() - tWaitDest < 4.0) do
								task.wait(0.3)
								dropCF, dropPrompt, destId = getCourierDestination()
							end

							if not dropCF then
								if deliveryServiceEvent then
									deliveryServiceEvent:FireServer("RequestJobUpdate")
								end
								task.wait(1.0)
								activeCourierDestId = nil
								return
							end

							local hrp = char:FindFirstChild("HumanoidRootPart")
							local tripDist = hrp and (dropCF.Position - hrp.Position).Magnitude or 0
							local courierTripStartTime = tick()

							-- 🛡️ Smart Adaptive Pre-Arrival Pacing Guard untuk Kurir:
							-- Pacing aman motor (~80 km/h) agar waktu tempuh 1.5 - 2.5 menit organik
							local baseSafeSpeed = 86.0
							local randomJitter = math.random(-50, 40) / 10.0
							local safeSpeed = math.clamp(baseSafeSpeed + randomJitter, 75.0, 92.0)
							local minSafeTime = math.clamp(tripDist / safeSpeed, 45.0, 150.0)

							updateBotActivity(string.format("Mengantar ke Lokasi %s (%.0fm) - %s - %s", tostring(destId or "?"), tripDist, formatCourierTime(os.clock() - courierStartTime), formatRupiah(courierTotalEarn)), Color3.fromRGB(0, 212, 255))

							-- Berkendara motor ke titik dropoff
							local dropArrived = driveCourierTo(dropCF, Config.courierSpeed or 85, 14)

							if not courierActive or courierShiftLimit then return end

							if not dropArrived then
								warn("[HipHub DDS Courier] Belum sampai di lokasi pengantaran, membatalkan serah terima paket.")
								task.wait(1.0)
								return
							end

							-- Tahan di luar lingkaran jika waktu tempuh organik belum terpenuhi (Smart Pacing)
							if Config.courierPacing then
								local elapsed = tick() - courierTripStartTime
								if elapsed < minSafeTime then
									local remainingWait = minSafeTime - elapsed
									if remainingWait > 0.5 then
										local pacingStart = tick()
										while (tick() - pacingStart < remainingWait) and courierActive and not courierShiftLimit do
											local rem = math.max(0, math.floor((remainingWait - (tick() - pacingStart)) * 10) / 10)
											updateBotActivity(string.format("Mengantar Paket (%.1fs)...", rem), Color3.fromRGB(255, 180, 50))
											task.wait(0.25)
										end
									end
								end
							end

							-- Tetap duduk aman di atas motor saat serah terima paket (100% Anti-Jatuh ke void)
							ensureDriverSeated()

							-- Jeda dropoff alami
							local dropDelay = tonumber(Config.courierDropDelay) or 4
							updateBotActivity(string.format("Menyerahkan Paket (%ds)...", dropDelay), Color3.fromRGB(255, 200, 50))
							task.wait(dropDelay)

							-- Pegang paket (Equip Box Tool)
							equipCourierPackage()
							task.wait(0.5)

							-- Tembak Prompt Pengantaran
							if not dropPrompt or not dropPrompt.Parent then
								local _, np, _ = getCourierDestination()
								dropPrompt = np
							end
							if dropPrompt then
								triggerCourierPrompt(dropPrompt)
							end

							task.wait(0.8)
							_G.HipHubCompletedCourier = (_G.HipHubCompletedCourier or 0) + 1
							local totalDoneCourier = _G.HipHubCompletedCourier
							UI.Notify("Paket Terkirim", string.format("Paket #%d sukses terantar.", totalDoneCourier), 2.5, "success")
							updateBotActivity("Paket Sukses Diserahkan!", Color3.fromRGB(80, 255, 120))

							-- Scheduled Auto-Rejoin Cycle (Reset Strike & Session Memory di Server per Paket Selesai)
							local autoRejoinCourierCount = tonumber(Config.courierAutoRejoinOrders) or 10
							if autoRejoinCourierCount > 0 and totalDoneCourier > 0 and (totalDoneCourier % autoRejoinCourierCount == 0) then
								rejoinCourierServer(string.format("Siklus Auto-Rejoin (%d Paket Selesai)", totalDoneCourier))
								return
							end

							-- Pastikan driver tetap duduk stabil untuk orderan berikutnya
							ensureDriverSeated()

							-- Menunggu server menetapkan order berikutnya (1-3.5s) agar langsung lanjut tanpa pulang ke depot
							local lastCompletedId = tostring(destId or "")
							updateBotActivity("Menunggu Pesanan Paket Berikutnya...", Color3.fromRGB(255, 200, 50))
							local tWaitNext = os.clock()
							local nextFound = false
							while (os.clock() - tWaitNext < 3.5) and courierActive and not courierShiftLimit do
								local curTarget = getActiveCourierTarget()
								if (curTarget and curTarget ~= lastCompletedId) or hasCourierPackage() then
									activeCourierDestId = curTarget
									nextFound = true
									break
								end
								task.wait(0.25)
							end

							if not nextFound then
								activeCourierDestId = nil
							end
							restarting = false
						end
					end)

					if not cycleOk then
						warn("[HipHub DDS Courier Error]:", cycleErr)
						task.wait(1.5)
					end
						end
					end
				end
			end)
		else
			if courierLoopThread then
				pcall(function() task.cancel(courierLoopThread) end)
				courierLoopThread = nil
			end
			-- Bersihkan dummy seat jika tertinggal
			pcall(function()
				local s = workspace:FindFirstChild("courier_seat")
				if s then s:Destroy() end
				local s2 = workspace:FindFirstChild("__HipHubCourierSeat")
				if s2 then s2:Destroy() end
			end)
			if not taxiActive and not Config.autoRideGO then
				updateBotActivity("Bot Idle (Auto-Farm OFF)", Color3.fromRGB(160, 175, 200))
				UI.Notify("Auto-Courier OFF", "Auto Courier dihentikan.", 2, "info")
			end
		end
	end


	------------------------------------------------
	-- 🖼️ 3. UI COMPONENTS IN FARM TAB
	------------------------------------------------
	------------------------------------------------
	-- 🛵 1. FARM VEHICLE CONFIGURATION
	------------------------------------------------
	UI.AddSection(tab, "Farm Vehicle Configuration")

	local initialList = #ownedVehiclesList > 0 and ownedVehiclesList or { (selectedFarmVehicle ~= "" and selectedFarmVehicle) or "Loading..." }
	local initialSelected = (selectedFarmVehicle ~= "" and selectedFarmVehicle) or (ownedVehiclesList[1] or "Select Vehicle")

	farmVehicleDropdown = UI.AddDropdown(tab, "Selected Farm Vehicle", initialList, initialSelected, function(chosen)
		if chosen and chosen ~= "Loading..." and chosen ~= "No Vehicles Found" and chosen ~= "Select Vehicle" then
			selectedFarmVehicle = chosen
			Config.selectedVehicle = chosen
			if _G.HipHubConfig and _G.HipHubConfig.farm then
				_G.HipHubConfig.farm.selectedVehicle = chosen
			end
			if _G.HipHubSaveConfig then
				_G.HipHubSaveConfig(true)
			end
			UI.Notify("Vehicle Selected", "Kendaraan Auto-Farm: " .. tostring(chosen), 2.5, "success")
		end
	end)

	UI.AddButton(tab, "Refresh Owned Vehicles", "Refresh List", function()
		fetchFarmOwnedVehicles(false)
	end)

	UI.AddButton(tab, "Spawn Farm Vehicle", "Spawn Car", function()
		spawnFarmVehicle()
		UI.Notify("Spawn Vehicle", "Memanggil: " .. tostring(getFarmVehicleName()), 2.5, "success")
	end)

	UI.AddButton(tab, "Despawn Vehicle", "Despawn Car", function()
		pcall(function()
			local sc = ReplicatedStorage:FindFirstChild("SpawnCarEvents")
			local despawnEvent = sc and sc:FindFirstChild("DespawnCar")
			if despawnEvent then
				despawnEvent:FireServer()
				UI.Notify("Despawn Vehicle", "Kendaraan dimasukkan ke garasi.", 2, "warning")
			end
		end)
	end)

	UI.AddSection(tab, "RideGO Taxi Auto-Driver")
	autoRideGoToggle = UI.AddToggle(tab, "Auto RideGO Taxi", "Goes online, auto-accepts orders & smoothly navigates to drops", Config.autoRideGO, function(state)
		toggleAutoRideGO(state)
	end)
	_G.HipHubAutoRideGoToggle = autoRideGoToggle

	UI.AddSlider(tab, "Taxi Speed (Studs/s)", 30, 300, math.floor(Config.taxiSpeed or 90), function(val)
		Config.taxiSpeed = val
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.taxiSpeed = val
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	UI.AddSlider(tab, "Auto Rejoin Per Orders", 0, 60, math.floor(Config.autoRejoinOrders or 30), function(val)
		Config.autoRejoinOrders = val
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.autoRejoinOrders = val
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	UI.AddSlider(tab, "Boarding Pause Delay (s)", 1, 8, math.floor(Config.passengerBoardDelay or 3), function(val)
		Config.passengerBoardDelay = val
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.passengerBoardDelay = val
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	UI.AddToggle(tab, "RideGO Smart Pacing", "Menyesuaikan waktu tempuh taxi agar sesuai kecepatan organik server", Config.tripPacing, function(state)
		Config.tripPacing = state
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.tripPacing = state
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	------------------------------------------------
	-- 📦 COURIER DELIVERY UI SECTION
	------------------------------------------------
	UI.AddSection(tab, "Courier Delivery Auto-Worker")
	autoCourierToggle = UI.AddToggle(tab, "Auto Courier Delivery", "Pengantaran paket otomatis dengan rute cerdas", Config.autoCourier, function(state)
		toggleAutoCourier(state)
	end)
	_G.HipHubAutoCourierToggle = autoCourierToggle

	UI.AddSlider(tab, "Courier Driving Speed (Studs/s)", 40, 120, math.floor(Config.courierSpeed or 85), function(val)
		Config.courierSpeed = val
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.courierSpeed = val
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	UI.AddToggle(tab, "Courier Smart Pacing", "Menahan penyerahan paket sesaat jika perjalanan terlalu cepat agar bebas ban server", Config.courierPacing, function(state)
		Config.courierPacing = state
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.courierPacing = state
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	UI.AddSlider(tab, "Auto Rejoin Per Packages", 0, 60, math.floor(Config.courierAutoRejoinOrders or 10), function(val)
		Config.courierAutoRejoinOrders = val
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.courierAutoRejoinOrders = val
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	UI.AddSlider(tab, "Dropoff Delay (s)", 1, 10, math.floor(Config.courierDropDelay or 4), function(val)
		Config.courierDropDelay = val
		if _G.HipHubConfig and _G.HipHubConfig.farm then
			_G.HipHubConfig.farm.courierDropDelay = val
		end
		if _G.HipHubSaveConfig then
			_G.HipHubSaveConfig(true)
		end
	end)

	-- 🚀 Auto-resume Auto RideGO / Courier jika aktif pada config tersimpan atau dari queue_on_teleport
	task.defer(function()
		-- 🛡️ Tunggu karakter dan HumanoidRootPart siap agar tidak gagal akses physics / seat
		local char = player.Character
		if not char then
			local t0 = os.clock()
			while not char and (os.clock() - t0 < 8) do
				char = player.Character
				task.wait(0.5)
			end
		end
		if char then
			pcall(function() char:WaitForChild("HumanoidRootPart", 5) end)
		end
		task.wait(2)

		-- 🛡️ Dismiss Main Menu DDS jika masih ada menuBlur / Holder
		pcall(function()
			local Lighting = game:GetService("Lighting")
			local blur = Lighting:FindFirstChild("menuBlur")
			if blur then blur.Enabled = false blur.Size = 0 end
			if player and player:FindFirstChild("PlayerGui") then
				local mainUI = player.PlayerGui:FindFirstChild("MainUI")
				if mainUI and mainUI:FindFirstChild("Holder") then
					mainUI.Holder.Visible = false
				end
			end
			local menuEvent = ReplicatedStorage:FindFirstChild("menuToggleRequest")
			if menuEvent and menuEvent:IsA("RemoteEvent") then
				menuEvent:FireServer()
			end
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)

		local shouldResumeCourier = (getgenv().AUTO_RESUME_COURIER == true)
		if shouldResumeCourier then
			getgenv().AUTO_RESUME_COURIER = false
			UI.Notify("Auto-Resume", "Melanjutkan sesi farm kurir...", 3, "info")
		end

		local shouldResumeRideGO = (getgenv().AUTO_RESUME_RIDEGO == true)
		if shouldResumeRideGO then
			getgenv().AUTO_RESUME_RIDEGO = false
			UI.Notify("Auto-Resume", "Melanjutkan sesi farm RideGO...", 3, "info")
		end

		if shouldResumeCourier or (_G.HipHubConfig and _G.HipHubConfig.farm and _G.HipHubConfig.farm.autoCourier) then
			if autoCourierToggle and autoCourierToggle.Set then
				autoCourierToggle.Set(true, true)
			elseif not courierActive and toggleAutoCourier then
				toggleAutoCourier(true)
			end
		elseif shouldResumeRideGO or (_G.HipHubConfig and _G.HipHubConfig.farm and _G.HipHubConfig.farm.autoRideGO) then
			if autoRideGoToggle and autoRideGoToggle.Set then
				autoRideGoToggle.Set(true, true)
			elseif not taxiActive and toggleAutoRideGO then
				toggleAutoRideGO(true)
			end
		end
	end)
end)

if not success then
	warn("[HipHub DDS Farm Error]:", err)
end
