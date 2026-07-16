-- 🧠 CAB Main Window Controller
-- Core UI wire logic (dragging, resizing, closing, minimizing, keybind toggle, and config persistence)

local success, err = pcall(function()
	local refs = _G.HipHubUI
	if not refs then
		return
	end

	local COLORS = refs.COLORS or {
		textWhite = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(150, 160, 190),
		glassActive = Color3.fromRGB(34, 40, 68),
		glassSurface = Color3.fromRGB(16, 20, 36),
		accentCyan = Color3.fromRGB(0, 200, 255),
	}

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = refs.UserInputService
	local TweenService = refs.TweenService
	local player = Players.LocalPlayer

	-- UI References
	local gui = refs.gui
	local mainFrame = refs.mainFrame
	local shadowFrame = refs.shadowFrame
	local topBar = refs.topBar
	local closeButton = refs.closeButton
	local minimizeButton = refs.minimizeButton
	local fullscreenButton = refs.fullscreenButton
	local restoreButton = refs.restoreButton
	local resizeHandle = refs.resizeHandle
	local avatarLabel = refs.avatarLabel
	local selectTab = refs.selectTab
	local syncShadow = refs.syncShadow
	local kbValue = refs.kbValue

	-- Design tokens
	local toggleOnColor = COLORS.toggleOn or Color3.fromRGB(0, 180, 230)
	local toggleOffColor = COLORS.toggleOff or Color3.fromRGB(40, 46, 70)

	local saveConfig

	------------------------------------------------
	-- 🖼️ DRAGGING FUNCTIONALITY
	------------------------------------------------
	local dragging, dragInput, dragStart, startPos
	local function updateDrag(input)
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		if syncShadow then pcall(syncShadow) end
	end

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then updateDrag(input) end
	end)

	------------------------------------------------
	-- ⬜ FULLSCREEN TOGGLE
	------------------------------------------------
	local isFullscreen = false
	local windowedSize = mainFrame.Size
	local windowedPos = mainFrame.Position

	if fullscreenButton then
		fullscreenButton.MouseButton1Click:Connect(function()
			isFullscreen = not isFullscreen
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

			if isFullscreen then
				-- Save windowed state
				windowedSize = mainFrame.Size
				windowedPos = mainFrame.Position

				TweenService:Create(mainFrame, tweenInfo, {
					Size = UDim2.new(1, 0, 1, 0),
					Position = UDim2.new(0, 0, 0, 0),
				}):Play()

				if shadowFrame then
					TweenService:Create(shadowFrame, tweenInfo, {
						Size = UDim2.new(1, 12, 1, 12),
						Position = UDim2.new(0, -6, 0, -6),
					}):Play()
				end

				if refs.updateFullscreenIcon then
					pcall(refs.updateFullscreenIcon, true)
				else
					fullscreenButton.Text = "❐"
				end
				if resizeHandle then resizeHandle.Visible = false end
			else
				TweenService:Create(mainFrame, tweenInfo, {
					Size = windowedSize,
					Position = windowedPos,
				}):Play()

				if shadowFrame then
					TweenService:Create(shadowFrame, tweenInfo, {
						Size = UDim2.new(windowedSize.X.Scale, windowedSize.X.Offset + 12, windowedSize.Y.Scale, windowedSize.Y.Offset + 12),
						Position = UDim2.new(windowedPos.X.Scale, windowedPos.X.Offset - 6, windowedPos.Y.Scale, windowedPos.Y.Offset - 6),
					}):Play()
				end

				if refs.updateFullscreenIcon then
					pcall(refs.updateFullscreenIcon, false)
				else
					fullscreenButton.Text = "⬜"
				end
				if resizeHandle then resizeHandle.Visible = true end
			end
		end)
	end

	------------------------------------------------
	-- 📐 RESIZE HANDLE DRAG
	------------------------------------------------
	if resizeHandle then
		local resizing = false
		local resizeDragStart, resizeStartSize
		local MIN_W, MIN_H = 400, 280

		resizeHandle.InputBegan:Connect(function(input)
			if isFullscreen then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				resizeDragStart = input.Position
				resizeStartSize = mainFrame.Size
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then resizing = false end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - resizeDragStart
				local newW = math.max(MIN_W, resizeStartSize.X.Offset + delta.X)
				local newH = math.max(MIN_H, resizeStartSize.Y.Offset + delta.Y)
				mainFrame.Size = UDim2.new(0, newW, 0, newH)
				if syncShadow then pcall(syncShadow) end
			end
		end)
	end

	------------------------------------------------
	-- 🔽 MINIMIZE / RESTORE CONTROLS
	------------------------------------------------
	local function minimizeUI(instant)
		if instant then
			mainFrame.Visible = false
			if shadowFrame then shadowFrame.Visible = false end
			restoreButton.Visible = true
		else
			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
			if shadowFrame then TweenService:Create(shadowFrame, tweenInfo, { BackgroundTransparency = 1 }):Play() end
			task.delay(0.2, function()
				mainFrame.Visible = false
				if shadowFrame then shadowFrame.Visible = false end
				mainFrame.BackgroundTransparency = 0.08
				if shadowFrame then shadowFrame.BackgroundTransparency = 0.45 end
				restoreButton.Visible = true
			end)
		end
	end
	refs.minimizeUI = minimizeUI

	minimizeButton.MouseButton1Click:Connect(function()
		minimizeUI(false)
	end)

	restoreButton.MouseButton1Click:Connect(function()
		restoreButton.Visible = false
		mainFrame.Visible = true
		if shadowFrame then shadowFrame.Visible = true end
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		mainFrame.BackgroundTransparency = 0.6
		TweenService:Create(mainFrame, tweenInfo, { BackgroundTransparency = 0.08 }):Play()
	end)

	------------------------------------------------
	-- ⌨️ KEYBIND TOGGLE
	------------------------------------------------
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local currentKeyText = (kbValue and kbValue.Text) or "RightShift"
		local successKey, currentKeyCode = pcall(function()
			return Enum.KeyCode[currentKeyText]
		end)
		if not successKey or not currentKeyCode then
			currentKeyCode = Enum.KeyCode.RightShift
		end

		if input.KeyCode == currentKeyCode then
			if restoreButton.Visible then
				restoreButton.Visible = false
				mainFrame.Visible = true
				if shadowFrame then shadowFrame.Visible = true end
			else
				mainFrame.Visible = not mainFrame.Visible
				if shadowFrame then shadowFrame.Visible = mainFrame.Visible end
			end
		end
	end)

	------------------------------------------------
	-- ✕ CLOSE BUTTON
	------------------------------------------------
	closeButton.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	-- Profile image fetch background task
	task.spawn(function()
		local successThumbnail, thumbContent = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if successThumbnail then avatarLabel.Image = thumbContent end
	end)

	------------------------------------------------
	-- ⚙️ CONFIGURATION SAVING & LOADING
	------------------------------------------------
	saveConfig = function()
		if not writefile then return end
		pcall(function()
			if makefolder then pcall(makefolder, "HipHub") end
			local data = {}
			if _G.HipHubSettings and _G.HipHubSettings.getState then
				local settingsState = _G.HipHubSettings.getState()
				data.antiAfk = settingsState.antiAfk
				data.touchFling = settingsState.touchFling
				data.antiFling = settingsState.antiFling
				data.noclip = settingsState.noclip
				data.startMinimized = settingsState.startMinimized
				data.keybind = settingsState.keybind
			else
				data.keybind = kbValue.Text
			end
			writefile("HipHub/config.json", game:GetService("HttpService"):JSONEncode(data))
		end)
	end

	-- Expose saveConfig callback
	refs.saveConfig = function() pcall(saveConfig) end

	-- Load saved configuration on startup
	pcall(function()
		local content = nil
		if isfile and readfile then
			if isfile("HipHub/config.json") then
				content = readfile("HipHub/config.json")
			elseif isfile("hiphub_config.json") then
				content = readfile("hiphub_config.json")
			end
		end

		if content then
			local data = game:GetService("HttpService"):JSONDecode(content)
			if data and type(data) == "table" then
				if data.keybind and tostring(data.keybind) ~= "" then kbValue.Text = tostring(data.keybind) end

				-- Load settings config variables for settings.lua
				if data.antiAfk ~= nil or data.touchFling ~= nil or data.antiFling ~= nil or data.noclip ~= nil or data.startMinimized ~= nil or data.keybind ~= nil then
					_G.HipHubSettingsConfig = {
						antiAfk = data.antiAfk,
						touchFling = data.touchFling,
						antiFling = data.antiFling,
						noclip = data.noclip,
						startMinimized = data.startMinimized,
						keybind = data.keybind or "RightShift"
					}
				end
			end
		end
	end)

	-- Minimize UI on startup if Start Minimized config is set
	task.spawn(function()
		task.wait(0.6)
		local settingsState = _G.HipHubSettings and _G.HipHubSettings.getState and _G.HipHubSettings.getState()
		if settingsState and settingsState.startMinimized then
			pcall(minimizeUI, true)
		end
	end)

	-- Write current execution key to disk
	local currentKey = _G.hiphub_key or hiphub_key
	if currentKey and writefile then
		pcall(function()
			if makefolder then pcall(makefolder, "HipHub") end
			writefile("HipHub/key.txt", tostring(currentKey):gsub("%s+", ""))
		end)
	end
end)

if not success then
	warn("CAB UI Main Wire Init Error: " .. tostring(err))
end
