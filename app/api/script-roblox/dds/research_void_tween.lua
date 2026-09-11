-- 🔬 HipHub DDS — Standalone Void Tween & Anti-Kick Research Suite
-- Script riset mandiri untuk meneliti metode penyeberangan jurang laut (Yogya -> Klaten)
-- secara aman, halus mengikuti permukaan tanah (tanpa loncat ke langit tinggi), dan bebas kick 267.

local success, err = pcall(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local Workspace = game:GetService("Workspace")
	local CoreGui = game:GetService("CoreGui")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players.LocalPlayer

	-- Hapus UI riset lama jika sudah terbuka
	pcall(function()
		local oldUi = CoreGui:FindFirstChild("HipHub_VoidResearch_UI")
		if oldUi then oldUi:Destroy() end
		local oldUiPlayer = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("HipHub_VoidResearch_UI")
		if oldUiPlayer then oldUiPlayer:Destroy() end
	end)

	-- State Riset
	local isTesting = false
	local currentMode = "MoveTo" -- "MoveTo", "IncrementalCFrame", "LinearVelocity", "DirectTween"
	local testSpeed = 95
	local activeThreads = {}
	local activeConnections = {}
	local targetPosition = Vector3.new(-17057, 105, 6568) -- Default: Klaten Location 8
	local plateInstance = nil
	local magicSeatInstance = nil
	local magicWeldInstance = nil

	-- Presets Koordinat Populer
	local PRESETS = {
		{ name = "Klaten Loc 8 (Jauh 10km)", pos = Vector3.new(-17057, 105, 6568) },
		{ name = "Klaten Loc 3 (-8773, 3, 643)", pos = Vector3.new(-8773, 3, 643) },
		{ name = "Klaten Kardus 5 (-6738, 4, 2977)", pos = Vector3.new(-6738, 4, 2977) },
		{ name = "Tebing Yogya Awal (-5105, 15, -3750)", pos = Vector3.new(-5105, 15, -3750) },
		{ name = "Uji Coba (2000 stud ke depan)", pos = nil }, -- Dihitung 2000 stud ke depan
	}

	-- 🖥️ GUI Creation (Modern Dark Theme)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HipHub_VoidResearch_UI"
	screenGui.ResetOnSpawn = false
	pcall(function() screenGui.Parent = CoreGui end)
	if not screenGui.Parent then screenGui.Parent = player:WaitForChild("PlayerGui") end

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 520, 0, 640)
	mainFrame.Position = UDim2.new(0.5, -260, 0.5, -320)
	mainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 212, 255)
	stroke.Thickness = 1.5
	stroke.Parent = mainFrame

	-- Dragging Logic
	local dragging, dragInput, dragStart, startPos
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 42)
	titleBar.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 10)
	titleCorner.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 1, 0)
	titleLabel.Position = UDim2.new(0, 15, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🔬 HipHub DDS — Void Tween & Anti-Kick Research"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -36, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = titleBar
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Scroll Content
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -52)
	scroll.Position = UDim2.new(0, 10, 0, 48)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 212, 255)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	local function createSection(titleText, order)
		local sec = Instance.new("Frame")
		sec.Size = UDim2.new(1, 0, 0, 26)
		sec.BackgroundTransparency = 1
		sec.LayoutOrder = order or 1
		sec.Parent = scroll

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "  " .. titleText
		lbl.TextColor3 = Color3.fromRGB(0, 212, 255)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = sec

		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 1, -1)
		line.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
		line.BorderSizePixel = 0
		line.Parent = sec
		return sec
	end

	-- 1. Telemetry Dashboard
	createSection("📊 LIVE TELEMETRY & STATUS", 1)

	local telemCard = Instance.new("Frame")
	telemCard.Size = UDim2.new(1, 0, 0, 125)
	telemCard.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
	telemCard.BorderSizePixel = 0
	telemCard.LayoutOrder = 2
	telemCard.Parent = scroll
	Instance.new("UICorner", telemCard).CornerRadius = UDim.new(0, 8)

	local telemText = Instance.new("TextLabel")
	telemText.Size = UDim2.new(1, -20, 1, -10)
	telemText.Position = UDim2.new(0, 10, 0, 5)
	telemText.BackgroundTransparency = 1
	telemText.TextColor3 = Color3.fromRGB(220, 220, 220)
	telemText.Font = Enum.Font.Code
	telemText.TextSize = 11
	telemText.TextXAlignment = Enum.TextXAlignment.Left
	telemText.TextYAlignment = Enum.TextYAlignment.Top
	telemText.Text = "Memuat data telemetri..."
	telemText.Parent = telemCard

	-- 2. Mode Riset Selection
	createSection("⚙️ PILIH METODE BYPASS VOID", 3)

	local modeContainer = Instance.new("Frame")
	modeContainer.Size = UDim2.new(1, 0, 0, 116)
	modeContainer.BackgroundTransparency = 1
	modeContainer.LayoutOrder = 4
	modeContainer.Parent = scroll

	local modeLayout = Instance.new("UIGridLayout")
	modeLayout.CellSize = UDim2.new(0.485, 0, 0, 52)
	modeLayout.CellPadding = UDim2.new(0.03, 0, 0, 6)
	modeLayout.Parent = modeContainer

	local modeButtons = {}
	local MODES = {
		{
			id = "MoveTo",
			name = "🥈 Waypoint + Humanoid:MoveTo()",
			desc = "Lebih mendekati movement normal karakter.\nLayak diuji untuk melihat apakah server lebih konsisten menerima pergerakannya.\nKekurangannya: kalau benar-benar melewati void tanpa permukaan, MoveTo() sendiri tidak menjamin karakter bisa sampai."
		},
		{
			id = "IncrementalCFrame",
			name = "🥉 Heartbeat + incremental CFrame",
			desc = "Posisi diperbarui sedikit demi sedikit setiap frame.\nBagus sebagai baseline untuk membandingkan metode transform langsung.\nTetap termasuk manipulasi posisi, jadi bukan berarti otomatis aman dari validasi server."
		},
		{
			id = "LinearVelocity",
			name = "AssemblyLinearVelocity / LinearVelocity",
			desc = "Menarik untuk diuji karena berbasis physics.\nHasilnya sangat bergantung pada network ownership dan sistem movement DDS."
		},
		{
			id = "DirectTween",
			name = "TweenService → CFrame langsung",
			desc = "Mudah dan smooth.\nTapi untuk pengujian crossing jurang, aku justru tidak menjadikannya pilihan pertama karena secara konsep masih merupakan perpindahan CFrame langsung."
		},
	}

	-- Kartu Info Karakteristik & Analisis Metode Terpilih
	local descCard = Instance.new("Frame")
	descCard.Name = "ModeDescCard"
	descCard.Size = UDim2.new(1, 0, 0, 88)
	descCard.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
	descCard.BorderSizePixel = 0
	descCard.LayoutOrder = 5
	descCard.Parent = scroll
	Instance.new("UICorner", descCard).CornerRadius = UDim.new(0, 8)
	local descStroke = Instance.new("UIStroke", descCard)
	descStroke.Color = Color3.fromRGB(45, 55, 75)
	descStroke.Thickness = 1

	local descTitle = Instance.new("TextLabel")
	descTitle.Size = UDim2.new(1, -20, 0, 20)
	descTitle.Position = UDim2.new(0, 10, 0, 6)
	descTitle.BackgroundTransparency = 1
	descTitle.TextColor3 = Color3.fromRGB(0, 212, 255)
	descTitle.Font = Enum.Font.GothamBold
	descTitle.TextSize = 11
	descTitle.TextXAlignment = Enum.TextXAlignment.Left
	descTitle.Parent = descCard

	local descBody = Instance.new("TextLabel")
	descBody.Size = UDim2.new(1, -20, 1, -28)
	descBody.Position = UDim2.new(0, 10, 0, 25)
	descBody.BackgroundTransparency = 1
	descBody.TextColor3 = Color3.fromRGB(210, 215, 225)
	descBody.Font = Enum.Font.Gotham
	descBody.TextSize = 10
	descBody.TextXAlignment = Enum.TextXAlignment.Left
	descBody.TextYAlignment = Enum.TextYAlignment.Top
	descBody.TextWrapped = true
	descBody.Parent = descCard

	local function updateModeInfo()
		for _, m in ipairs(MODES) do
			if m.id == currentMode then
				descTitle.Text = "ℹ️ " .. m.name
				descBody.Text = m.desc
				break
			end
		end
	end

	local function updateModeButtons()
		for id, btn in pairs(modeButtons) do
			if id == currentMode then
				btn.BackgroundColor3 = Color3.fromRGB(0, 160, 220)
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				btn.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
				btn.TextColor3 = Color3.fromRGB(180, 180, 180)
			end
		end
		updateModeInfo()
	end

	for _, m in ipairs(MODES) do
		local btn = Instance.new("TextButton")
		btn.Name = "Mode_" .. m.id
		btn.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
		btn.Text = m.name
		btn.TextColor3 = Color3.fromRGB(180, 180, 180)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 10.5
		btn.TextWrapped = true
		btn.BorderSizePixel = 0
		btn.Parent = modeContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			currentMode = m.id
			updateModeButtons()
		end)
		modeButtons[m.id] = btn
	end
	updateModeButtons()

	-- 3. Kecepatan Uji Coba
	createSection("⚡ KECEPATAN UJI COBA (STUDS / DETIK)", 5)

	local speedContainer = Instance.new("Frame")
	speedContainer.Size = UDim2.new(1, 0, 0, 36)
	speedContainer.BackgroundTransparency = 1
	speedContainer.LayoutOrder = 6
	speedContainer.Parent = scroll

	local speedLayout = Instance.new("UIListLayout")
	speedLayout.FillDirection = Enum.FillDirection.Horizontal
	speedLayout.Padding = UDim.new(0, 8)
	speedLayout.Parent = speedContainer

	local speedButtons = {}
	local SPEEDS = { 35, 60, 95, 150, 200, 230 }
	local function updateSpeedButtons()
		for spd, btn in pairs(speedButtons) do
			if spd == testSpeed then
				btn.BackgroundColor3 = Color3.fromRGB(0, 212, 130)
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				btn.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
				btn.TextColor3 = Color3.fromRGB(180, 180, 180)
			end
		end
	end

	for _, spd in ipairs(SPEEDS) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 75, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
		btn.Text = tostring(spd) .. " s/s"
		btn.TextColor3 = Color3.fromRGB(180, 180, 180)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.BorderSizePixel = 0
		btn.Parent = speedContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			testSpeed = spd
			updateSpeedButtons()
		end)
		speedButtons[spd] = btn
	end
	updateSpeedButtons()

	-- 4. Target Lokasi
	createSection("📍 TITIK TUJUAN PENYEBERANGAN", 7)

	local presetContainer = Instance.new("Frame")
	presetContainer.Size = UDim2.new(1, 0, 0, 115)
	presetContainer.BackgroundTransparency = 1
	presetContainer.LayoutOrder = 8
	presetContainer.Parent = scroll

	local pGrid = Instance.new("UIGridLayout")
	pGrid.CellSize = UDim2.new(0.485, 0, 0, 32)
	pGrid.CellPadding = UDim2.new(0.03, 0, 0, 6)
	pGrid.Parent = presetContainer

	for _, p in ipairs(PRESETS) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
		btn.Text = p.name
		btn.TextColor3 = Color3.fromRGB(220, 220, 220)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 10
		btn.BorderSizePixel = 0
		btn.Parent = presetContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			if p.pos then
				targetPosition = p.pos
				if _G.HipHubLogMessage then
					_G.HipHubLogMessage("📍 Target diset ke: " .. p.name, Color3.fromRGB(0, 212, 255))
				end
			else
				-- 🎯 Uji Coba 2000 Stud ke Depan
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					targetPosition = hrp.Position + hrp.CFrame.LookVector * 2000
					if _G.HipHubLogMessage then
						_G.HipHubLogMessage(string.format("📍 Target diset: 2000 stud ke depan (X: %.0f, Z: %.0f)", targetPosition.X, targetPosition.Z), Color3.fromRGB(0, 255, 170))
					end
				end
			end
		end)
	end

	-- 5. Tombol Pembantu Kursi (Manual Seat Controls)
	createSection("🪑 KONTROL KURSI MANUAL", 9)

	local seatToolContainer = Instance.new("Frame")
	seatToolContainer.Size = UDim2.new(1, 0, 0, 36)
	seatToolContainer.BackgroundTransparency = 1
	seatToolContainer.LayoutOrder = 10
	seatToolContainer.Parent = scroll

	local sitBtn = Instance.new("TextButton")
	sitBtn.Size = UDim2.new(0.485, 0, 1, 0)
	sitBtn.BackgroundColor3 = Color3.fromRGB(45, 90, 160)
	sitBtn.Text = "🪑 Duduk di Kursi Sekarang"
	sitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sitBtn.Font = Enum.Font.GothamBold
	sitBtn.TextSize = 11
	sitBtn.BorderSizePixel = 0
	sitBtn.Parent = seatToolContainer
	Instance.new("UICorner", sitBtn).CornerRadius = UDim.new(0, 6)

	local unsitBtn = Instance.new("TextButton")
	unsitBtn.Size = UDim2.new(0.485, 0, 1, 0)
	unsitBtn.Position = UDim2.new(0.515, 0, 0, 0)
	unsitBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	unsitBtn.Text = "🚪 Berdiri dari Kursi"
	unsitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	unsitBtn.Font = Enum.Font.GothamBold
	unsitBtn.TextSize = 11
	unsitBtn.BorderSizePixel = 0
	unsitBtn.Parent = seatToolContainer
	Instance.new("UICorner", unsitBtn).CornerRadius = UDim.new(0, 6)

	-- 6. Tombol Eksekusi & Kontrol
	createSection("🚀 KONTROL EKSEKUSI RISET", 11)

	local ctrlContainer = Instance.new("Frame")
	ctrlContainer.Size = UDim2.new(1, 0, 0, 45)
	ctrlContainer.BackgroundTransparency = 1
	ctrlContainer.LayoutOrder = 12
	ctrlContainer.Parent = scroll

	local startBtn = Instance.new("TextButton")
	startBtn.Size = UDim2.new(0.62, 0, 1, 0)
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
	startBtn.Text = "▶️ JALANKAN RISET TWEEN"
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.Font = Enum.Font.GothamBold
	startBtn.TextSize = 13
	startBtn.BorderSizePixel = 0
	startBtn.Parent = ctrlContainer
	Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

	local stopBtn = Instance.new("TextButton")
	stopBtn.Size = UDim2.new(0.35, 0, 1, 0)
	stopBtn.Position = UDim2.new(0.65, 0, 0, 0)
	stopBtn.BackgroundColor3 = Color3.fromRGB(210, 45, 45)
	stopBtn.Text = "🛑 EMERGENCY STOP"
	stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopBtn.Font = Enum.Font.GothamBold
	stopBtn.TextSize = 11
	stopBtn.BorderSizePixel = 0
	stopBtn.Parent = ctrlContainer
	Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

	-- 7. Log Console
	createSection("📜 LIVE EVENT & DIAGNOSTIC LOG", 13)

	local logBox = Instance.new("ScrollingFrame")
	logBox.Size = UDim2.new(1, 0, 0, 140)
	logBox.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
	logBox.BorderSizePixel = 0
	logBox.ScrollBarThickness = 4
	logBox.LayoutOrder = 14
	logBox.Parent = scroll
	Instance.new("UICorner", logBox).CornerRadius = UDim.new(0, 6)

	local logLayout = Instance.new("UIListLayout")
	logLayout.Padding = UDim.new(0, 2)
	logLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logLayout.Parent = logBox

	local function addLog(msg, color)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -10, 0, 16)
		lbl.Position = UDim2.new(0, 5, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = color or Color3.fromRGB(200, 200, 200)
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = string.format("[%s] %s", os.date("%X"), tostring(msg))
		lbl.Parent = logBox
		logBox.CanvasPosition = Vector2.new(0, logBox.CanvasPosition.Y + 20)
	end
	_G.HipHubLogMessage = addLog

	addLog("Suite Riset Void Tween v2 dimuat. Elevasi tanah adaptif aktif.", Color3.fromRGB(0, 255, 170))

	-- 📡 Loop Telemetri Real-time
	task.spawn(function()
		while screenGui.Parent do
			pcall(function()
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local hrp = char and char:FindFirstChild("HumanoidRootPart")

				local posStr = hrp and string.format("X: %.1f, Y: %.1f, Z: %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"
				local stateStr = hum and tostring(hum:GetState().Name) or "N/A"
				local floorStr = hum and tostring(hum.FloorMaterial.Name) or "N/A"
				local seatStr = (hum and hum.SeatPart) and hum.SeatPart.Name or "None (On Foot)"
				local distToTarget = (hrp and targetPosition) and math.floor((Vector3.new(targetPosition.X, 0, targetPosition.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude) or 0
				local velStr = hrp and string.format("%.1f stud/s", hrp.AssemblyLinearVelocity.Magnitude) or "0"

				local activeModeName = currentMode
				for _, m in ipairs(MODES) do
					if m.id == currentMode then activeModeName = m.name break end
				end

				telemText.Text = string.format(
					"Status Uji      : %s\n" ..
					"Metode Aktif    : %s\n" ..
					"Kecepatan Uji   : %d stud/detik\n" ..
					"Posisi Karakter : %s\n" ..
					"Humanoid State  : %s\n" ..
					"Floor Material  : %s  (Kunci Anti-Fly!)\n" ..
					"Duduk di Kursi  : %s\n" ..
					"Kecepatan Fisik : %s\n" ..
					"Jarak ke Target : %d stud (%s)",
					isTesting and "🟢 SEDANG BERJALAN..." or "⚪ IDLE",
					activeModeName,
					testSpeed,
					posStr,
					stateStr,
					floorStr,
					seatStr,
					velStr,
					distToTarget,
					(floorStr == "Air" and "⚠️ AIRBORNE/VOID" or "✅ GROUNDED")
				)
			end)
			task.wait(0.1)
		end
	end)

	-- =========================================================================
	-- ⛰️ HELPER ELEVASI ADAPTIF: MENEMPEL DI TANAH & MENYEBERANG MULUS DI JURANG
	-- =========================================================================
	-- Fungsi ini TIDAK AKAN PERNAH meloncatkan karakter ke langit tinggi!
	-- Jika ada jalan/tanah di bawah: mengikuti elevasi tanah secara natural.
	-- Jika di atas jurang/laut (void): bergerak lurus secara gradual dari startY ke destPos.Y.
	local function calculateAdaptiveY(currentY, nextX, nextZ, startPos, destPos, flatDist, totalDist, char, excludeParts, dt)
		local rayParams = RaycastParams.new()
		local filterList = { char }
		if excludeParts then
			for _, p in ipairs(excludeParts) do
				if p and p.Parent then table.insert(filterList, p) end
			end
		end
		rayParams.FilterDescendantsInstances = filterList
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = false

		-- Raycast ke bawah untuk mendeteksi tanah di depan
		local hit = Workspace:Raycast(
			Vector3.new(nextX, currentY + 6, nextZ),
			Vector3.new(0, -35, 0),
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
			-- Pastikan tidak tenggelam ke dalam air laut (level laut DDS ~ Y = 10-14)
			local safeVoidY = math.max(slopeY, 16.5)
			local maxStep = math.max(50 * dt, 1.5)
			return currentY + math.clamp(safeVoidY - currentY, -maxStep, maxStep), false
		end
	end

	-- Helper verifikasi keberadaan daratan/jalan asli milik server (BUKAN part lokal buatan client)
	local function hasServerGroundUnderneath(pos, char)
		local rayParams = RaycastParams.new()
		local filter = { char }
		if plateInstance and plateInstance.Parent then table.insert(filter, plateInstance) end
		if magicSeatInstance and magicSeatInstance.Parent then table.insert(filter, magicSeatInstance) end
		local emPlate = Workspace:FindFirstChild("__DdsEmergencyPlate")
		if emPlate then table.insert(filter, emPlate) end

		rayParams.FilterDescendantsInstances = filter
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = false

		local hit = Workspace:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), rayParams)
		if hit and hit.Instance then
			local mat = hit.Material
			local n = hit.Instance.Name:lower()
			local isWater = (mat == Enum.Material.Water) or n:find("water") or n:find("air") or n:find("laut")
			if not isWater then
				return true, hit.Position.Y
			end
		end
		return false, nil
	end

	-- 🛑 Emergency Stop Helper
	local function haltTest(reason)
		isTesting = false
		for _, th in ipairs(activeThreads) do pcall(function() task.cancel(th) end) end
		table.clear(activeThreads)
		for _, conn in ipairs(activeConnections) do pcall(function() conn:Disconnect() end) end
		table.clear(activeConnections)

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if hrp and hum then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero

			local isRealGround, groundY = hasServerGroundUnderneath(hrp.Position, char)

			if isRealGround then
				-- Ada daratan/jalan asli server di bawah kaki! Aman untuk unseat & berdiri
				if magicWeldInstance and magicWeldInstance.Parent then magicWeldInstance:Destroy() magicWeldInstance = nil end
				if magicSeatInstance and magicSeatInstance.Parent then magicSeatInstance:Destroy() magicSeatInstance = nil end
				if plateInstance and plateInstance.Parent then plateInstance:Destroy() plateInstance = nil end

				hum.Sit = false
				hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				addLog("✅ Tiba di daratan asli server! Aman berdiri di atas tanah.", Color3.fromRGB(0, 255, 120))
			else
				-- Karakter MASIH BERADA DI ATAS VOID / LAUT!
				-- ⚠️ JANGAN UNSEAT! JANGAN HANCURKAN KURSI!
				-- Tetap duduk di kursi agar server mendeteksi hum.SeatPart != nil (Bypass Anti-Fly)
				if magicSeatInstance and magicSeatInstance.Parent then
					magicSeatInstance.Anchored = true
					hum.Sit = true
					addLog("🛡️ Berhenti di atas void: TETAP DUDUK DI KURSI agar bebas kick Anti-Fly server!", Color3.fromRGB(255, 200, 50))
				else
					local p = Instance.new("Part")
					p.Name = "__DdsEmergencyPlate"
					p.Size = Vector3.new(30, 3, 30)
					p.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 3.1, hrp.Position.Z)
					p.Anchored = true
					p.CanCollide = true
					p.Material = Enum.Material.Plastic
					p.Transparency = 0.5
					p.BrickColor = BrickColor.new("Bright red")
					p.Parent = Workspace
					addLog("⚠️ Berhenti di atas void (Plat lokal - berdiri di udara memicu kick server jika lama).", Color3.fromRGB(255, 120, 50))
				end
			end
		end

		addLog("🛑 Test dihentikan: " .. tostring(reason or "Manual Stop"), Color3.fromRGB(255, 80, 80))
	end
	stopBtn.MouseButton1Click:Connect(function() haltTest("User Klik Stop") end)

	-- =========================================================================
	-- 🪑 SISTEM KURSI RELIABEL (DAPAT DIUJI SECARA LANGSUNG)
	-- =========================================================================
	local function forceSitOnSeat()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return false end

		-- Hapus kursi & weld lama jika ada
		if magicWeldInstance and magicWeldInstance.Parent then magicWeldInstance:Destroy() end
		if magicSeatInstance and magicSeatInstance.Parent then magicSeatInstance:Destroy() end

		-- Buat kursi valid dengan CanCollide = true (WAJIB agar Humanoid mendeteksi Seat!)
		magicSeatInstance = Instance.new("Seat")
		magicSeatInstance.Name = "__DdsMagicSeat"
		magicSeatInstance.Size = Vector3.new(2.5, 0.6, 2.5)
		magicSeatInstance.CanCollide = true
		magicSeatInstance.Anchored = true
		magicSeatInstance.Disabled = false
		magicSeatInstance.Transparency = 0.4
		magicSeatInstance.BrickColor = BrickColor.new("Bright yellow")
		magicSeatInstance.Material = Enum.Material.Plastic
		-- Posisikan tepat 1.5 stud di bawah HRP (tinggi pinggul normal)
		magicSeatInstance.CFrame = hrp.CFrame - Vector3.new(0, 1.5, 0)
		magicSeatInstance.Parent = Workspace

		hum.Sit = false
		hum.PlatformStand = false
		task.wait(0.05)

		-- Posisikan HRP rapat di atas kursi & dudukkan
		hrp.CFrame = magicSeatInstance.CFrame + Vector3.new(0, 0.4, 0)
		task.wait(0.05)
		pcall(function() magicSeatInstance:Sit(hum) end)
		task.wait(0.15)

		-- Buat WeldConstraint agar karakter dijamin 100% menempel di kursi saat meluncur
		magicWeldInstance = Instance.new("WeldConstraint")
		magicWeldInstance.Name = "__DdsSeatWeld"
		magicWeldInstance.Part0 = magicSeatInstance
		magicWeldInstance.Part1 = hrp
		magicWeldInstance.Parent = magicSeatInstance

		hum.Sit = true

		if hum.SeatPart then
			addLog("✅ Berhasil duduk di kursi! (SeatPart: " .. hum.SeatPart.Name .. ")", Color3.fromRGB(0, 255, 120))
			return true
		else
			addLog("🪑 Karakter di-weld di kursi (Sitting: " .. tostring(hum.Sit) .. ")", Color3.fromRGB(255, 215, 0))
			return true
		end
	end

	sitBtn.MouseButton1Click:Connect(function() forceSitOnSeat() end)

	unsitBtn.MouseButton1Click:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Sit = false end
		if magicWeldInstance and magicWeldInstance.Parent then magicWeldInstance:Destroy() magicWeldInstance = nil end
		if magicSeatInstance and magicSeatInstance.Parent then magicSeatInstance:Destroy() magicSeatInstance = nil end
		addLog("🚪 Berdiri dari kursi.", Color3.fromRGB(200, 200, 200))
	end)

	-- =========================================================================
	-- 🧪 IMPLEMENTASI 4 METODE RISET PERGERAKAN
	-- =========================================================================

	-- =========================================================================
	-- 🥈 METODE 1: Waypoint + Humanoid:MoveTo()
	-- =========================================================================
	-- Lebih mendekati movement normal karakter.
	-- Layak diuji untuk melihat apakah server lebih konsisten menerima pergerakannya.
	-- Kekurangannya: kalau benar-benar melewati void tanpa permukaan, MoveTo() sendiri tidak menjamin karakter bisa sampai.
	local function runMoveTo(destPos, speed)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return end

		hum.Sit = false
		hum.PlatformStand = false
		local oldWalkSpeed = hum.WalkSpeed
		hum.WalkSpeed = speed

		addLog("🥈 Menjalankan Waypoint + Humanoid:MoveTo() (Speed: " .. speed .. " stud/s)...", Color3.fromRGB(0, 212, 255))
		addLog("ℹ️ Lebih mendekati movement normal karakter. Menguji konsistensi server.", Color3.fromRGB(180, 200, 220))
		addLog("⚠️ Catatan: Jika melewati void tanpa permukaan, MoveTo() tidak menjamin karakter bisa sampai.", Color3.fromRGB(255, 200, 80))

		local startPos = hrp.Position
		local totalDist = (Vector3.new(destPos.X, 0, destPos.Z) - Vector3.new(startPos.X, 0, startPos.Z)).Magnitude

		-- Bagi rute menjadi beberapa waypoint bertahap (setiap 100 stud) agar MoveTo() tidak timeout
		local segmentDist = 100
		local numWaypoints = math.max(1, math.ceil(totalDist / segmentDist))
		local lastLogTime = 0

		for i = 1, numWaypoints do
			if not isTesting then break end
			if not (char and char.Parent and hrp and hrp.Parent and hum) then break end

			local alpha = i / numWaypoints
			local targetWP = startPos:Lerp(destPos, alpha)

			-- Cari elevasi tanah jika ada
			local hit = Workspace:Raycast(Vector3.new(targetWP.X, 500, targetWP.Z), Vector3.new(0, -1000, 0))
			if hit and hit.Instance and hit.Material ~= Enum.Material.Water then
				targetWP = Vector3.new(targetWP.X, hit.Position.Y + 3.0, targetWP.Z)
			end

			-- Kirim perintah MoveTo ke waypoint
			hum:MoveTo(targetWP)

			local wpStart = os.clock()
			while isTesting do
				RunService.Heartbeat:Wait()
				if not (char and char.Parent and hrp and hrp.Parent and hum) then break end

				local distToWp = (Vector3.new(targetWP.X, 0, targetWP.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
				if distToWp <= 6.0 then
					break
				end

				-- Deteksi jika karakter berada di atas void tanpa pijakan
				if hum.FloorMaterial == Enum.Material.Air and hrp.Position.Y < 15 then
					addLog("⚠️ Karakter airborne di atas void (MoveTo() kehilangan pijakan permukaan).", Color3.fromRGB(255, 120, 50))
				end

				-- Refresh MoveTo setiap 3.5 detik (timeout default Roblox = 8s)
				if (os.clock() - wpStart) > 3.5 then
					hum:MoveTo(targetWP)
					wpStart = os.clock()
				end

				if os.clock() - lastLogTime >= 2.0 then
					lastLogTime = os.clock()
					local remaining = (Vector3.new(destPos.X, 0, destPos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
					addLog(string.format("MoveTo: WP %d/%d | Sisa: %d stud | Floor: %s | State: %s", i, numWaypoints, math.floor(remaining), hum.FloorMaterial.Name, hum:GetState().Name), Color3.fromRGB(180, 220, 255))
				end
			end
		end

		hum.WalkSpeed = oldWalkSpeed or 16
		haltTest("MoveTo Selesai")
	end

	-- =========================================================================
	-- 🥉 METODE 2: Heartbeat + incremental CFrame
	-- =========================================================================
	-- Posisi diperbarui sedikit demi sedikit setiap frame.
	-- Bagus sebagai baseline untuk membandingkan metode transform langsung.
	-- Tetap termasuk manipulasi posisi, jadi bukan berarti otomatis aman dari validasi server.
	local function runIncrementalCFrame(destPos, speed)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return end

		hum.Sit = false
		hum.PlatformStand = false

		-- BodyVelocity penahan gravitasi vertikal agar tidak jatuh ke laut selama frame-stepping
		local bv = Instance.new("BodyVelocity")
		bv.Name = "__ResearchIncCF_BV"
		bv.MaxForce = Vector3.new(0, 9e9, 0)
		bv.Velocity = Vector3.zero
		bv.Parent = hrp

		local startPos = hrp.Position
		local curPos = startPos
		local totalDist = (Vector3.new(destPos.X, 0, destPos.Z) - Vector3.new(startPos.X, 0, startPos.Z)).Magnitude

		addLog("🥉 Menjalankan Heartbeat + incremental CFrame (Speed: " .. speed .. " stud/s)...", Color3.fromRGB(255, 180, 100))
		addLog("ℹ️ Baseline transform: posisi diperbarui sedikit demi sedikit setiap frame Heartbeat.", Color3.fromRGB(210, 180, 140))
		addLog("⚠️ Tetap manipulasi posisi langsung, bukan berarti otomatis aman dari validasi server.", Color3.fromRGB(255, 200, 80))

		local lastLogTime = 0
		while isTesting do
			local dt = RunService.Heartbeat:Wait()
			if not (char and char.Parent and hrp and hrp.Parent and hum) then break end

			local flatDelta = Vector3.new(destPos.X - curPos.X, 0, destPos.Z - curPos.Z)
			local flatDist = flatDelta.Magnitude
			if flatDist <= 4.0 then
				addLog("✅ Sampai di target dengan Heartbeat + incremental CFrame!", Color3.fromRGB(0, 255, 120))
				break
			end

			local moveDir = flatDelta.Unit
			local stepDist = math.min(speed * dt, flatDist)

			local nextX = curPos.X + moveDir.X * stepDist
			local nextZ = curPos.Z + moveDir.Z * stepDist

			-- Hitung ketinggian tanah secara adaptif
			local nextY, isGround = calculateAdaptiveY(curPos.Y, nextX, nextZ, startPos, destPos, flatDist, totalDist, char, nil, dt)
			curPos = Vector3.new(nextX, nextY, nextZ)

			local lookTarget = Vector3.new(destPos.X, nextY, destPos.Z)
			hrp.CFrame = CFrame.new(curPos, lookTarget)
			hrp.AssemblyLinearVelocity = moveDir * speed

			if os.clock() - lastLogTime >= 2.0 then
				lastLogTime = os.clock()
				addLog(string.format("IncCFrame: sisa %d stud | Y: %.1f (%s) | Floor: %s | Vel: %.1f", math.floor(flatDist), nextY, isGround and "Tanah" or "Jurang", hum.FloorMaterial.Name, hrp.AssemblyLinearVelocity.Magnitude), Color3.fromRGB(255, 210, 150))
			end
		end

		if bv and bv.Parent then bv:Destroy() end
		haltTest("Incremental CFrame Selesai")
	end

	-- =========================================================================
	-- ⚡ METODE 3: AssemblyLinearVelocity / LinearVelocity
	-- =========================================================================
	-- Menarik untuk diuji karena berbasis physics.
	-- Hasilnya sangat bergantung pada network ownership dan sistem movement DDS.
	local function runLinearVelocity(destPos, speed)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return end

		hum.Sit = false
		hum.PlatformStand = false

		-- Nonaktifkan ragdoll/jatuh agar dorongan fisika murni menggerakkan karakter
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end)

		-- Constraint BodyVelocity / LinearVelocity untuk menghasilkan physical velocity murni
		local bv = Instance.new("BodyVelocity")
		bv.Name = "__ResearchPhysVelocity"
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bv.Velocity = Vector3.zero
		bv.Parent = hrp

		addLog("⚡ Menjalankan AssemblyLinearVelocity / LinearVelocity (Speed: " .. speed .. " stud/s)...", Color3.fromRGB(0, 212, 255))
		addLog("ℹ️ Berbasis physics murni: menggerakkan karakter via physical force & velocity.", Color3.fromRGB(150, 220, 255))
		addLog("ℹ️ Mengandalkan Network Ownership client dan sistem movement DDS.", Color3.fromRGB(180, 220, 255))

		local startPos = hrp.Position
		local totalDist = (Vector3.new(destPos.X, 0, destPos.Z) - Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
		local lastLogTime = 0

		while isTesting do
			local dt = RunService.Heartbeat:Wait()
			if not (char and char.Parent and hrp and hrp.Parent and hum) then break end

			local curPos = hrp.Position
			local flatDelta = Vector3.new(destPos.X - curPos.X, 0, destPos.Z - curPos.Z)
			local flatDist = flatDelta.Magnitude

			if flatDist <= 6.0 then
				addLog("✅ Sampai di target dengan LinearVelocity!", Color3.fromRGB(0, 255, 120))
				break
			end

			local moveDir = flatDelta.Unit

			-- Posisikan arah hadap karakter ke target secara halus tanpa manipulasi posisi CFrame
			hrp.CFrame = CFrame.new(curPos, Vector3.new(destPos.X, curPos.Y, destPos.Z))

			-- Kendalikan pergerakan murni melalui dorongan fisika (LinearVelocity)
			local nextY, isGround = calculateAdaptiveY(curPos.Y, curPos.X, curPos.Z, startPos, destPos, flatDist, totalDist, char, nil, dt)
			local yVel = math.clamp((nextY - curPos.Y) / math.max(dt, 0.016), -35, 35)

			local targetVelocity = Vector3.new(moveDir.X * speed, yVel, moveDir.Z * speed)
			bv.Velocity = targetVelocity
			hrp.AssemblyLinearVelocity = targetVelocity
			hrp.AssemblyAngularVelocity = Vector3.zero

			if os.clock() - lastLogTime >= 2.0 then
				lastLogTime = os.clock()
				addLog(string.format("Velocity: sisa %d stud | Y: %.1f (%s) | Floor: %s | RealVel: %.1f", math.floor(flatDist), curPos.Y, isGround and "Tanah" or "Jurang", hum.FloorMaterial.Name, hrp.AssemblyLinearVelocity.Magnitude), Color3.fromRGB(150, 230, 255))
			end
		end

		if bv and bv.Parent then bv:Destroy() end

		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
		end)

		haltTest("LinearVelocity Selesai")
	end

	-- =========================================================================
	-- 🎬 METODE 4: TweenService → CFrame langsung
	-- =========================================================================
	-- Mudah dan smooth.
	-- Tapi untuk pengujian crossing jurang, secara konsep masih merupakan perpindahan CFrame langsung.
	local function runDirectTween(destPos, speed)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not hrp then return end

		hum.Sit = false
		hum.PlatformStand = false

		-- BodyVelocity penahan gravitasi selama TweenService
		local bv = Instance.new("BodyVelocity")
		bv.Name = "__ResearchTweenBV"
		bv.Velocity = Vector3.zero
		bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		bv.Parent = hrp

		-- NoClip agar tidak tersangkut gedung/pohon
		local noclipConn = RunService.Stepped:Connect(function()
			if char and char.Parent then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)

		local startPos = hrp.Position
		local totalDist = (destPos - startPos).Magnitude
		local duration = math.max(totalDist / math.max(speed, 30), 0.2)

		addLog(string.format("🎬 Menjalankan TweenService → CFrame langsung (Dist: %d stud, Time: %.1fs, Speed: %d)...", math.floor(totalDist), duration, speed), Color3.fromRGB(220, 150, 255))
		addLog("ℹ️ Mudah dan smooth: perpindahan CFrame langsung via Engine TweenService.", Color3.fromRGB(230, 180, 255))
		addLog("⚠️ Secara konsep masih merupakan perpindahan CFrame langsung.", Color3.fromRGB(240, 200, 150))

		local targetCF = CFrame.new(destPos + Vector3.new(0, 2.0, 0), destPos + (destPos - startPos).Unit)
		local twInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
		local tw = TweenService:Create(hrp, twInfo, { CFrame = targetCF })

		local twDone = false
		local twConn = tw.Completed:Connect(function() twDone = true end)
		tw:Play()

		local twStart = os.clock()
		local lastLogTime = 0

		while isTesting and not twDone do
			task.wait(0.1)
			if not (char and char.Parent and hrp and hrp.Parent and hum) then break end
			if os.clock() - twStart > (duration + 5.0) then break end

			if os.clock() - lastLogTime >= 2.0 then
				lastLogTime = os.clock()
				local rem = (destPos - hrp.Position).Magnitude
				addLog(string.format("Tween: sisa %d stud | Y: %.1f | Floor: %s | State: %s", math.floor(rem), hrp.Position.Y, hum.FloorMaterial.Name, hum:GetState().Name), Color3.fromRGB(240, 180, 255))
			end
		end

		if twConn then twConn:Disconnect() end
		if noclipConn then noclipConn:Disconnect() end
		pcall(function() tw:Cancel() end)
		if bv and bv.Parent then bv:Destroy() end

		haltTest("Direct TweenService Selesai")
	end

	-- Tombol Eksekusi
	startBtn.MouseButton1Click:Connect(function()
		if isTesting then
			addLog("⚠️ Tes sedang berjalan! Hentikan dulu sebelum mulai baru.", Color3.fromRGB(255, 180, 50))
			return
		end

		isTesting = true
		local activeModeName = currentMode
		for _, m in ipairs(MODES) do
			if m.id == currentMode then activeModeName = m.name break end
		end
		addLog(string.format("=== MEMULAI RISET METODE: %s (Speed: %d, Target: %.0f, %.0f, %.0f) ===", activeModeName, testSpeed, targetPosition.X, targetPosition.Y, targetPosition.Z), Color3.fromRGB(255, 255, 255))

		local th = task.spawn(function()
			if currentMode == "MoveTo" then
				runMoveTo(targetPosition, testSpeed)
			elseif currentMode == "IncrementalCFrame" then
				runIncrementalCFrame(targetPosition, testSpeed)
			elseif currentMode == "LinearVelocity" then
				runLinearVelocity(targetPosition, testSpeed)
			elseif currentMode == "DirectTween" then
				runDirectTween(targetPosition, testSpeed)
			end
		end)
		table.insert(activeThreads, th)
	end)

end)

if not success then
	warn("[HipHub DDS Research Suite Error]:", err)
end
