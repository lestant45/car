-- 🧠 HipHub DE -- Window Controller & Anti-AFK
-- Driving Empire (Place ID: 9694510481)
-- Handles: drag, minimize, fullscreen, close/restore, RightShift toggle,
--          resize handle, anti-AFK

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local Players         = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService    = game:GetService("TweenService")
	local VirtualUser     = game:GetService("VirtualUser")
	local player          = Players.LocalPlayer

	local mainFrame   = UI.mainFrame
	local topBar      = UI.topBar
	local closeButton = UI.closeButton
	local minimizeButton  = UI.minimizeButton
	local fullscreenButton = UI.fullscreenButton
	local restoreButton   = UI.restoreButton
	local shadowFrame     = UI.shadowFrame
	local syncShadow      = UI.syncShadow
	local updateFsIcon    = UI.updateFullscreenIcon

	local isFullscreen = false
	local isMinimized  = false
	local origPos  = mainFrame.Position
	local origSize = mainFrame.Size

	------------------------------------------------
	-- 🖱️ WINDOW DRAGGING
	------------------------------------------------
	local dragging, dragInput, dragStart, startPos

	local function applyDrag(input)
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		syncShadow()
	end

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			if not isFullscreen then
				dragging  = true
				dragStart = input.Position
				startPos  = mainFrame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			applyDrag(input)
		end
	end)

	------------------------------------------------
	-- ➖ MINIMIZE / RESTORE
	------------------------------------------------
	minimizeButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			TweenService:Create(mainFrame,
				TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 44)}
			):Play()
		else
			local tw = TweenService:Create(mainFrame,
				TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Size = origSize})
			tw:Play()
		end
		task.delay(0.24, syncShadow)
	end)

	------------------------------------------------
	-- ⛶ FULLSCREEN TOGGLE
	------------------------------------------------
	fullscreenButton.MouseButton1Click:Connect(function()
		isFullscreen = not isFullscreen
		if updateFsIcon then pcall(updateFsIcon, isFullscreen) end
		if isFullscreen then
			TweenService:Create(mainFrame,
				TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Position = UDim2.new(0.5, -450, 0.5, -310),
				 Size     = UDim2.new(0, 900, 0, 620)}
			):Play()
		else
			TweenService:Create(mainFrame,
				TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Position = origPos, Size = origSize}
			):Play()
		end
		task.delay(0.26, syncShadow)
	end)

	------------------------------------------------
	-- ✕ CLOSE (hide) & RESTORE BUTTON
	------------------------------------------------
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible  = false
		shadowFrame.Visible = false
		restoreButton.Visible = true
	end)

	restoreButton.MouseButton1Click:Connect(function()
		mainFrame.Visible  = true
		shadowFrame.Visible = true
		restoreButton.Visible = false
		syncShadow()
	end)

	------------------------------------------------
	-- ⌨️ RIGHT SHIFT KEYBIND TOGGLE
	------------------------------------------------
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			local visible = not mainFrame.Visible
			mainFrame.Visible   = visible
			shadowFrame.Visible = visible
			restoreButton.Visible = not visible
			if visible then syncShadow() end
		end
	end)

	------------------------------------------------
	-- 📐 RESIZE HANDLE
	------------------------------------------------
	pcall(function()
		local resizeHandle = UI.resizeHandle
		if not resizeHandle then return end

		local rDragging = false
		local rStart, rStartSize

		resizeHandle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				rDragging  = true
				rStart     = input.Position
				rStartSize = mainFrame.AbsoluteSize
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						rDragging = false
					end
				end)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if rDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - rStart
				local newW  = math.clamp(rStartSize.X + delta.X, 420, 1100)
				local newH  = math.clamp(rStartSize.Y + delta.Y, 280, 720)
				mainFrame.Size = UDim2.new(0, newW, 0, newH)
				syncShadow()
			end
		end)
	end)

	------------------------------------------------
	-- 🛡️ ANTI-AFK
	------------------------------------------------
	pcall(function()
		player.Idled:Connect(function()
			local cfg = _G.HipHubConfig
			if cfg and cfg.misc and cfg.misc.antiAfk ~= false then
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end
		end)
	end)

	print("[HipHub DE Main] Window controls & anti-AFK ready!")
end)

if not success then
	warn("[HipHub DE Main Error]:", err)
end
