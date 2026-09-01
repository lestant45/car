-- 📊 RideGODiagnostic.lua — High-Precision Passive Telemetry & Causal Isolation Layer
-- Place ID: 131378148336503 (Drag Drive Simulator)
-- CRITICAL CONSTRAINT: Passive observation ONLY. No physics, CFrame, remote, or hierarchy modification.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local player = Players.LocalPlayer

local Diagnostic = {
	sessionStartTime        = os.clock(),
	lastPeriodicReportTime  = os.clock(),
	
	-- Concurrency Counters
	activeTripWorkers       = 0,
	activeDriveControllers  = 0,
	activeResetWorkers      = 0,
	activeMovementControllers = 0,
	activePollers           = 0,
	
	-- Metric Totals
	totalTripsStarted       = 0,
	totalTripsCompleted     = 0,
	totalTripsFailed        = 0,
	totalResets             = 0,
	totalVoidJumps          = 0,
	totalVoidJumpDistance   = 0,
	totalRaycasts           = 0,
	totalDestroyCalls       = 0,
	totalDisabledCalls      = 0,
	totalRemoteFires        = 0,
	totalDescendantsAdded   = 0,
	
	-- Live State
	currentTripNumber       = 0,
	currentTripToken        = "N/A",
	currentTripState        = "IDLE",
	lastSuccessfulInteraction = os.clock(),
	lastSuccessfulTripTime  = 0,
	
	-- Performance & Timing
	frameCount              = 0,
	worstFrameTimeMs        = 0,
	totalHeartbeatComputeTimeMs = 0,
	
	-- High-Resolution Ring Buffer (Last 250 timestamped events for Final 60s Analysis)
	eventRingBuffer         = {},
	maxRingBufferSize       = 250
}

_G.RideGODiagnostic = Diagnostic

-- Format elapsed wall-clock timestamp [MM:SS.ms]
local function getTimestampStr(t)
	t = t or os.clock()
	local elapsed = t - Diagnostic.sessionStartTime
	local mins = math.floor(elapsed / 60)
	local secs = elapsed % 60
	return string.format("[%02dm %05.2fs]", mins, secs), elapsed
end

-- Thread-safe, non-invasive structured event logging
local function logEvent(category, eventType, detail, metadata)
	local now = os.clock()
	local timeStr, elapsed = getTimestampStr(now)
	
	local entry = {
		timestamp = now,
		elapsed = elapsed,
		timeFormatted = timeStr,
		category = category,
		eventType = eventType,
		detail = detail or "",
		metadata = metadata or {},
		concurrency = {
			tripWorkers = Diagnostic.activeTripWorkers,
			driveControllers = Diagnostic.activeDriveControllers,
			resetWorkers = Diagnostic.activeResetWorkers,
			movementControllers = Diagnostic.activeMovementControllers
		}
	}
	
	table.insert(Diagnostic.eventRingBuffer, entry)
	if #Diagnostic.eventRingBuffer > Diagnostic.maxRingBufferSize then
		table.remove(Diagnostic.eventRingBuffer, 1)
	end
	
	-- Print real-time log
	local metaStr = ""
	if metadata and type(metadata) == "table" then
		local parts = {}
		for k, v in pairs(metadata) do
			table.insert(parts, tostring(k) .. "=" .. tostring(v))
		end
		if #parts > 0 then
			metaStr = " | " .. table.concat(parts, ", ")
		end
	elseif metadata then
		metaStr = " | " .. tostring(metadata)
	end
	
	print(string.format("🔍 %s [%s:%s] %s%s", timeStr, category, eventType, tostring(detail), metaStr))
	
	-- Real-time Concurrency Violation Warning
	if Diagnostic.activeTripWorkers > 1 or Diagnostic.activeDriveControllers > 1 or Diagnostic.activeResetWorkers > 1 then
		warn(string.format(
			"🚨 %s [CONCURRENCY VIOLATION] TripWorkers=%d | DriveControllers=%d | ResetWorkers=%d | MovementControllers=%d (Context: %s)",
			timeStr,
			Diagnostic.activeTripWorkers,
			Diagnostic.activeDriveControllers,
			Diagnostic.activeResetWorkers,
			Diagnostic.activeMovementControllers,
			tostring(detail)
		))
	end
end
Diagnostic.Log = logEvent

----------------------------------------------------------------------
-- 1. CONCURRENCY & WORKER LIFECYCLE HOOKS (Passive Counter Registry)
----------------------------------------------------------------------
function Diagnostic.EnterTripWorker(token, orderInfo)
	Diagnostic.activeTripWorkers = Diagnostic.activeTripWorkers + 1
	Diagnostic.currentTripNumber = Diagnostic.currentTripNumber + 1
	Diagnostic.totalTripsStarted = Diagnostic.totalTripsStarted + 1
	Diagnostic.currentTripToken  = tostring(token or "N/A")
	Diagnostic.currentTripState  = "TRIP_STARTED"
	logEvent("WORKER", "ENTER_TRIP", string.format("Trip #%d Token: %s", Diagnostic.currentTripNumber, tostring(token)), orderInfo)
end

function Diagnostic.ExitTripWorker(token, outcome, duration)
	Diagnostic.activeTripWorkers = math.max(0, Diagnostic.activeTripWorkers - 1)
	if outcome == "SUCCESS" then
		Diagnostic.totalTripsCompleted = Diagnostic.totalTripsCompleted + 1
		Diagnostic.lastSuccessfulTripTime = os.clock()
		Diagnostic.lastSuccessfulInteraction = os.clock()
	else
		Diagnostic.totalTripsFailed = Diagnostic.totalTripsFailed + 1
	end
	Diagnostic.currentTripState = "TRIP_FINISHED_" .. tostring(outcome)
	logEvent("WORKER", "EXIT_TRIP", string.format("Trip #%d Outcome: %s (Duration: %.2fs)", Diagnostic.currentTripNumber, tostring(outcome), duration or 0), {
		token = token,
		remainingTripWorkers = Diagnostic.activeTripWorkers
	})
end

function Diagnostic.EnterDriveController(targetPos, speed)
	Diagnostic.activeDriveControllers = Diagnostic.activeDriveControllers + 1
	Diagnostic.activeMovementControllers = Diagnostic.activeMovementControllers + 1
	logEvent("DRIVE", "ENTER_DRIVE_CONTROLLER", "Drive started", {
		target = tostring(targetPos),
		speed = speed,
		activeControllers = Diagnostic.activeDriveControllers
	})
end

function Diagnostic.ExitDriveController(outcome, distRemaining)
	Diagnostic.activeDriveControllers = math.max(0, Diagnostic.activeDriveControllers - 1)
	Diagnostic.activeMovementControllers = math.max(0, Diagnostic.activeMovementControllers - 1)
	logEvent("DRIVE", "EXIT_DRIVE_CONTROLLER", "Drive ended: " .. tostring(outcome), {
		distRemaining = distRemaining,
		remainingControllers = Diagnostic.activeDriveControllers
	})
end

function Diagnostic.EnterResetWorker(reason)
	Diagnostic.activeResetWorkers = Diagnostic.activeResetWorkers + 1
	Diagnostic.totalResets = Diagnostic.totalResets + 1
	logEvent("RESET", "ENTER_RESET_WORKER", "Reset triggered: " .. tostring(reason), {
		activeResetWorkers = Diagnostic.activeResetWorkers,
		concurrentTripWorkers = Diagnostic.activeTripWorkers,
		concurrentDriveControllers = Diagnostic.activeDriveControllers
	})
end

function Diagnostic.ExitResetWorker()
	Diagnostic.activeResetWorkers = math.max(0, Diagnostic.activeResetWorkers - 1)
	logEvent("RESET", "EXIT_RESET_WORKER", "Reset finished", {
		remainingResetWorkers = Diagnostic.activeResetWorkers
	})
end

function Diagnostic.RecordVoidJump(dist, fromPos, toPos)
	Diagnostic.totalVoidJumps = Diagnostic.totalVoidJumps + 1
	Diagnostic.totalVoidJumpDistance = Diagnostic.totalVoidJumpDistance + (dist or 0)
	logEvent("PHYSICS", "VOID_JUMP", string.format("Jump Distance: %.1f studs", dist or 0), {
		from = tostring(fromPos),
		to = tostring(toPos),
		totalJumps = Diagnostic.totalVoidJumps
	})
end

function Diagnostic.RecordRaycast(count, durationMs, caller)
	Diagnostic.totalRaycasts = Diagnostic.totalRaycasts + (count or 1)
	if durationMs and durationMs > 5.0 then
		logEvent("PERF", "RAYCAST_SPIKE", string.format("Raycast batch (%d rays) took %.2fms", count or 1, durationMs), {
			caller = caller
		})
	end
end

function Diagnostic.RecordDestroyCall(instName, instClass, category)
	Diagnostic.totalDestroyCalls = Diagnostic.totalDestroyCalls + 1
	logEvent("HIERARCHY", "DESTROY_CALL", string.format("Destroyed %s (%s)", tostring(instName), tostring(instClass)), {
		category = category,
		totalDestroys = Diagnostic.totalDestroyCalls
	})
end

function Diagnostic.RecordDisabledCall(scriptName, oldVal, newVal)
	Diagnostic.totalDisabledCalls = Diagnostic.totalDisabledCalls + 1
	logEvent("INTEGRITY", "SCRIPT_DISABLED_MUTATION", string.format("%s.Disabled = %s (was %s)", tostring(scriptName), tostring(newVal), tostring(oldVal)), {
		totalDisabledMutations = Diagnostic.totalDisabledCalls
	})
end

----------------------------------------------------------------------
-- 2. PASSIVE HEARTBEAT & WORKLOAD MONITOR
----------------------------------------------------------------------
local lastHb = os.clock()
local hbConnection = RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local dt = now - lastHb
	lastHb = now
	Diagnostic.frameCount = Diagnostic.frameCount + 1
	local dtMs = dt * 1000
	if dtMs > Diagnostic.worstFrameTimeMs then
		Diagnostic.worstFrameTimeMs = dtMs
	end
end)

----------------------------------------------------------------------
-- 3. PASSIVE STREAMING & DESCENDANT ADDED MONITOR
----------------------------------------------------------------------
local descConn = workspace.DescendantAdded:Connect(function(desc)
	Diagnostic.totalDescendantsAdded = Diagnostic.totalDescendantsAdded + 1
end)

----------------------------------------------------------------------
-- 4. PASSIVE REMOTE EVENT TELEMETRY
----------------------------------------------------------------------
task.spawn(function()
	local taxiAssets = ReplicatedStorage:WaitForChild("TaxiAssets", 10)
	local taxiEvent = taxiAssets and taxiAssets:FindFirstChild("Events") and taxiAssets.Events:FindFirstChild("TaxiEvent")
	if taxiEvent then
		taxiEvent.OnClientEvent:Connect(function(...)
			local args = { ... }
			local evType = tostring(args[1] or "Unknown")
			Diagnostic.totalRemoteFires = Diagnostic.totalRemoteFires + 1
			Diagnostic.lastSuccessfulInteraction = os.clock()
			
			local meta = {}
			if type(args[2]) == "table" then
				meta.token = args[2].Token or args[2].token
				meta.fare = args[2].Fare or args[2].Price
				meta.passenger = args[2].PassengerName or args[2].Name
			elseif args[2] then
				meta.payload = tostring(args[2])
			end
			
			logEvent("REMOTE_IN", evType, "Server -> Client TaxiEvent", meta)
		end)
	end
end)

----------------------------------------------------------------------
-- 5. COREGUI DISCONNECT MODAL INTERCEPTOR & FINAL 60S DUMP
----------------------------------------------------------------------
task.spawn(function()
	local cGui = game:GetService("CoreGui")
	local promptGui = cGui:WaitForChild("RobloxPromptGui", 10)
	local overlay = promptGui and promptGui:WaitForChild("promptOverlay", 10)
	
	local function onDisconnectPromptDetected(child)
		local titleText = ""
		local bodyText = ""
		pcall(function()
			for _, d in ipairs(child:GetDescendants()) do
				if d:IsA("TextLabel") and d.Visible then
					if d.Name:lower():find("title") or d.Text:lower():find("disconnect") or d.Text:lower():find("kick") then
						titleText = titleText .. " [" .. d.Text .. "]"
					else
						bodyText = bodyText .. " " .. d.Text
					end
				end
			end
		end)
		
		logEvent("CRITICAL", "DISCONNECT_DETECTED", string.format("Modal: %s | Title: %s | Body: %s", child.Name, titleText, bodyText))
		
		-- FINAL 60-SECOND FORENSIC DUMP
		print("\n" .. string.rep("=", 80))
		print("🚨 [FINAL 60-SECOND PRE-DISCONNECT EVENT DUMP]")
		print(string.rep("=", 80))
		
		local cutoffTime = os.clock() - 60
		local recentEvents = {}
		for _, ev in ipairs(Diagnostic.eventRingBuffer) do
			if ev.timestamp >= cutoffTime then
				table.insert(recentEvents, ev)
			end
		end
		
		for idx, ev in ipairs(recentEvents) do
			print(string.format(
				"[%03d] %s [%s:%s] %s (Workers: Trips=%d, Drives=%d, Resets=%d)",
				idx,
				ev.timeFormatted,
				ev.category,
				ev.eventType,
				ev.detail,
				ev.concurrency.tripWorkers,
				ev.concurrency.driveControllers,
				ev.concurrency.resetWorkers
			))
		end
		
		print(string.rep("=", 80))
		print(string.format(
			"📊 TOTAL LIFECYCLE SUMMARY: Elapsed: %.1fs | Trips Started: %d | Trips Completed: %d | Resets: %d | VoidJumps: %d (%.1f studs) | Remotes: %d | Raycasts: %d | Destroys: %d | DisabledCalls: %d",
			os.clock() - Diagnostic.sessionStartTime,
			Diagnostic.totalTripsStarted,
			Diagnostic.totalTripsCompleted,
			Diagnostic.totalResets,
			Diagnostic.totalVoidJumps,
			Diagnostic.totalVoidJumpDistance,
			Diagnostic.totalRemoteFires,
			Diagnostic.totalRaycasts,
			Diagnostic.totalDestroyCalls,
			Diagnostic.totalDisabledCalls
		))
		print(string.rep("=", 80) .. "\n")
	end
	
	if overlay then
		overlay.ChildAdded:Connect(onDisconnectPromptDetected)
		for _, ch in ipairs(overlay:GetChildren()) do
			if ch.Name == "ErrorPrompt" or ch.Name:find("Prompt") then
				onDisconnectPromptDetected(ch)
			end
		end
	end
end)

----------------------------------------------------------------------
-- 6. PERIODIC 30-SECOND METRIC TELEMETRY DUMP
----------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(30)
		local now = os.clock()
		local timeStr, elapsed = getTimestampStr(now)
		
		local memMb = 0
		pcall(function()
			memMb = StatsService:GetTotalMemoryUsageMb()
		end)
		
		local avgFps = Diagnostic.frameCount > 0 and math.floor(Diagnostic.frameCount / 30) or 0
		Diagnostic.frameCount = 0
		
		print(string.format(
			"📊 %s [TELEMETRY] FPS: %d (Spike: %.1fms) | Mem: %.1fMB | Trips: %d/%d (Active: %d) | Drives: %d | Resets: %d | VJumps: %d | Remotes: %d | Raycasts: %d",
			timeStr,
			avgFps,
			Diagnostic.worstFrameTimeMs,
			memMb,
			Diagnostic.totalTripsCompleted,
			Diagnostic.totalTripsStarted,
			Diagnostic.activeTripWorkers,
			Diagnostic.activeDriveControllers,
			Diagnostic.totalResets,
			Diagnostic.totalVoidJumps,
			Diagnostic.totalRemoteFires,
			Diagnostic.totalRaycasts
		))
		Diagnostic.worstFrameTimeMs = 0
	end
end)

logEvent("SYSTEM", "INITIALIZED", "RideGODiagnostic passive telemetry active and running")
return Diagnostic
