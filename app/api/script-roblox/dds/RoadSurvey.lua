-- 🗺️ HipHub DDS — Road Geometry Surveyor & Diagnostic Engine (RoadSurvey.lua)
-- Drag Drive Simulator (Place ID: 131378148336503)
-- Purpose: Read-only audit, multi-signal classification, corridor grouping, connectivity detection,
--          elevation/ramp separation, and StreamingEnabled diagnostic analysis.
--
-- STRICT RESTRICTIONS:
--   - 100% READ-ONLY with respect to game state (no physics changes, no player/car teleportation).
--   - Does NOT modify farm.lua, movement controllers, or driveVehicleTo().
--   - Does NOT implement A* or Dijkstra routing yet.

local RoadSurvey = {}
RoadSurvey.__index = RoadSurvey

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

--------------------------------------------------------------------------------
-- 1. CONFIGURATION & HEURISTIC WEIGHTS
--------------------------------------------------------------------------------
local ROAD_FOLDER_PATTERNS = {
	"^JL_", "JALAN", "ROAD", "STREET", "FLYOVER", "BRIDGE", "RAMP", "TOL", "HIGHWAY", "BASEPLATE"
}

local CLASSIFICATION = {
	ROAD_SURFACE     = "ROAD_SURFACE",
	ROAD_MARKING     = "ROAD_MARKING",
	SIDEWALK         = "SIDEWALK",
	CURB             = "CURB",
	BARRIER          = "BARRIER",
	RAILING          = "RAILING",
	PILLAR           = "PILLAR",
	BRIDGE_STRUCTURE = "BRIDGE_STRUCTURE",
	GRASS_STRIP      = "GRASS_STRIP",
	DECORATION       = "DECORATION",
	UNKNOWN          = "UNKNOWN"
}

--------------------------------------------------------------------------------
-- 2. PHASE 1: WORKSPACE / HIERARCHY AUDIT
--------------------------------------------------------------------------------
function RoadSurvey.auditHierarchy()
	local audit = {
		discoveredFolders = {},
		totalDiscovered = 0,
		loadedFolders = 0,
		unloadedFolders = 0,
		totalLoadedParts = 0
	}

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Folder") or child:IsA("Model") then
			local name = child.Name
			local isMatch = false
			for _, pat in ipairs(ROAD_FOLDER_PATTERNS) do
				if name:find(pat) then
					isMatch = true
					break
				end
			end

			if isMatch then
				local descendants = child:GetDescendants()
				local basePartCount = 0
				for _, desc in ipairs(descendants) do
					if desc:IsA("BasePart") then
						basePartCount = basePartCount + 1
					end
				end

				local isLoaded = basePartCount > 0
				if isLoaded then
					audit.loadedFolders = audit.loadedFolders + 1
				else
					audit.unloadedFolders = audit.unloadedFolders + 1
				end
				audit.totalLoadedParts = audit.totalLoadedParts + basePartCount

				table.insert(audit.discoveredFolders, {
					name = name,
					className = child.ClassName,
					totalDescendants = #descendants,
					loadedParts = basePartCount,
					isLoaded = isLoaded,
					instance = child
				})
			end
		end
	end

	audit.totalDiscovered = #audit.discoveredFolders
	return audit
end

--------------------------------------------------------------------------------
-- 3. PHASE 2 & 3: MULTI-SIGNAL CANDIDATE CLASSIFICATION
--------------------------------------------------------------------------------
function RoadSurvey.classifyPart(part, parentFolderName)
	if not part:IsA("BasePart") then
		return CLASSIFICATION.UNKNOWN, 0.0, {}
	end

	local sz = part.Size
	local pos = part.Position
	local cf = part.CFrame
	local mat = part.Material
	local nameLower = part.Name:lower()

	-- Geometric signals
	local hArea = sz.X * sz.Z
	local vThickness = sz.Y
	local longestH = math.max(sz.X, sz.Z)
	local shortestH = math.min(sz.X, sz.Z)
	local aspectRatio = longestH / math.max(0.1, shortestH)
	local upVector = cf.UpVector
	local isHorizontal = upVector.Y >= 0.80

	local signals = {
		horizontalArea = hArea,
		verticalThickness = vThickness,
		longestDimension = longestH,
		shortestDimension = shortestH,
		aspectRatio = aspectRatio,
		upVectorY = upVector.Y,
		material = tostring(mat),
		canCollide = part.CanCollide,
		transparency = part.Transparency,
		elevation = pos.Y
	}

	-- 1. Trotoar / Curbs / Sidewalks (Name or Material specific)
	if nameLower:find("troto") or nameLower:find("sidewalk") or nameLower:find("curb") or mat == Enum.Material.Brick then
		return CLASSIFICATION.SIDEWALK, 0.92, signals
	end

	-- 2. Roadside Grass Strips
	if mat == Enum.Material.Grass then
		return CLASSIFICATION.GRASS_STRIP, 0.95, signals
	end

	-- 3. Lane Markings / Stripes
	if (mat == Enum.Material.Plastic or mat == Enum.Material.SmoothPlastic or mat == Enum.Material.Asphalt)
		and (vThickness <= 0.15 or not part.CanCollide or shortestH <= 1.2)
		and longestH >= 4.0
	then
		return CLASSIFICATION.ROAD_MARKING, 0.88, signals
	end

	-- 4. Sidewalk Pavement (Elevated concrete/pavement slabs)
	if mat == Enum.Material.Pavement then
		return CLASSIFICATION.SIDEWALK, 0.85, signals
	end

	-- 5. Barriers / Railings / Guardrails
	if part.CanCollide and vThickness >= 1.5 and shortestH <= 1.2 and longestH >= 5.0 and not isHorizontal then
		return CLASSIFICATION.BARRIER, 0.86, signals
	end

	-- 6. Vertical Bridge Pillars / Columns
	if sz.Y >= 6.0 and sz.X <= 6.0 and sz.Z <= 6.0 and not isHorizontal then
		return CLASSIFICATION.PILLAR, 0.84, signals
	end

	-- 7. Drivable Road Surface (Asphalt / Concrete wide slabs)
	local roadScore = 0.0

	if mat == Enum.Material.Asphalt then
		roadScore = roadScore + 0.40
	elseif mat == Enum.Material.Concrete then
		roadScore = roadScore + 0.25
	end

	if parentFolderName and (parentFolderName:sub(1, 3) == "JL_" or parentFolderName:find("FLYOVER") or parentFolderName:find("TOL")) then
		roadScore = roadScore + 0.25
	end

	if isHorizontal then
		roadScore = roadScore + 0.15
	end

	if vThickness <= 2.5 then
		roadScore = roadScore + 0.10
	end

	if shortestH >= 6.0 and longestH >= 12.0 and hArea >= 60.0 then
		roadScore = roadScore + 0.15
	end

	if part.CanCollide then
		roadScore = roadScore + 0.10
	else
		roadScore = roadScore - 0.40
	end

	if part.Transparency > 0.5 then
		roadScore = roadScore - 0.50
	end

	roadScore = math.clamp(roadScore, 0.0, 1.0)

	if roadScore >= 0.55 then
		return CLASSIFICATION.ROAD_SURFACE, roadScore, signals
	elseif roadScore >= 0.35 then
		return CLASSIFICATION.BRIDGE_STRUCTURE, roadScore, signals
	else
		return CLASSIFICATION.UNKNOWN, roadScore, signals
	end
end

--------------------------------------------------------------------------------
-- 4. PHASE 4, 5 & 6: ROAD SEGMENT EXTRACTION & CENTERLINE SAMPLING
--------------------------------------------------------------------------------
function RoadSurvey.buildRoadSegments(hierarchyAudit)
	local segments = {}
	local samplePoints = {}
	local seqId = 0
	local sampleId = 0

	for _, folderInfo in ipairs(hierarchyAudit.discoveredFolders) do
		if folderInfo.isLoaded then
			for _, desc in ipairs(folderInfo.instance:GetDescendants()) do
				if desc:IsA("BasePart") then
					local classType, confidence, signals = RoadSurvey.classifyPart(desc, folderInfo.name)
					if classType == CLASSIFICATION.ROAD_SURFACE and confidence >= 0.55 then
						seqId = seqId + 1

						local sz = desc.Size
						local cf = desc.CFrame
						local pos = desc.Position
						local isXMajor = sz.X >= sz.Z

						local length = isXMajor and sz.X or sz.Z
						local width  = isXMajor and sz.Z or sz.X
						local longAxisVec = isXMajor and cf.RightVector or cf.LookVector

						local segment = {
							id = seqId,
							sourceFolder = folderInfo.name,
							sourcePart = desc,
							name = desc.Name,
							center = pos,
							cframe = cf,
							size = sz,
							length = length,
							width = width,
							elevation = pos.Y,
							orientation = desc.Orientation,
							majorAxis = isXMajor and "X" or "Z",
							longAxisVector = longAxisVec,
							confidence = confidence,
							classification = classType,
							signals = signals
						}
						table.insert(segments, segment)

						-- Centerline sampling along longitudinal axis
						local numSamples = math.max(1, math.floor(length / 25))
						local stepDist = length / (numSamples + 1)
						local halfLen = length / 2

						for i = 1, numSamples do
							sampleId = sampleId + 1
							local offsetDist = -halfLen + (i * stepDist)
							local sPos = pos + (longAxisVec * offsetDist)
							table.insert(samplePoints, {
								id = sampleId,
								segmentId = seqId,
								sourceFolder = folderInfo.name,
								position = sPos,
								elevation = sPos.Y,
								tangent = longAxisVec
							})
						end
					end
				end
			end
		end
	end

	return segments, samplePoints
end

--------------------------------------------------------------------------------
-- 5. PHASE 7: ROAD CORRIDOR GROUPING
--------------------------------------------------------------------------------
function RoadSurvey.groupCorridors(segments)
	local corridors = {}
	local assigned = {}

	for i, segA in ipairs(segments) do
		if not assigned[segA.id] then
			local corridor = {
				id = #corridors + 1,
				name = segA.sourceFolder,
				segments = { segA },
				totalLength = segA.length,
				minElevation = segA.elevation,
				maxElevation = segA.elevation,
				center = segA.center
			}
			assigned[segA.id] = true

			for j = i + 1, #segments do
				local segB = segments[j]
				if not assigned[segB.id] and segB.sourceFolder == segA.sourceFolder then
					local distH = Vector3.new(segA.center.X - segB.center.X, 0, segA.center.Z - segB.center.Z).Magnitude
					local deltaY = math.abs(segA.elevation - segB.elevation)
					local maxSpan = (segA.length + segB.length) / 2 + 30

					if distH <= maxSpan and deltaY <= 4.0 then
						assigned[segB.id] = true
						table.insert(corridor.segments, segB)
						corridor.totalLength = corridor.totalLength + segB.length
						corridor.minElevation = math.min(corridor.minElevation, segB.elevation)
						corridor.maxElevation = math.max(corridor.maxElevation, segB.elevation)
					end
				end
			end

			table.insert(corridors, corridor)
		end
	end

	return corridors
end

--------------------------------------------------------------------------------
-- 6. PHASE 8: CONNECTIVITY DETECTION & CANDIDATE EVALUATION
--------------------------------------------------------------------------------
function RoadSurvey.evaluateConnections(segments)
	local connections = {}
	local evaluatedPairs = {}

	for i = 1, #segments do
		local segA = segments[i]
		for j = i + 1, #segments do
			local segB = segments[j]
			local pairKey = segA.id .. "_" .. segB.id

			if not evaluatedPairs[pairKey] then
				evaluatedPairs[pairKey] = true

				local posA = segA.center
				local posB = segB.center
				local delta = posB - posA
				local dist3D = delta.Magnitude
				local distH = Vector3.new(delta.X, 0, delta.Z).Magnitude
				local deltaY = math.abs(posA.Y - posB.Y)

				local maxSpanH = (segA.length + segB.length) / 2 + 15

				if distH <= maxSpanH then
					local dotAlignment = math.abs(segA.longAxisVector:Dot(segB.longAxisVector))
					local status = "UNKNOWN"
					local confidence = 0.0

					if deltaY >= 12.0 then
						status = "ELEVATED_SEPARATION"
						confidence = 0.95
					elseif deltaY <= 2.5 and distH <= ((segA.length + segB.length) / 2 + 5) then
						if dotAlignment >= 0.80 or segA.sourceFolder == segB.sourceFolder then
							status = "CONNECTED"
							confidence = 0.92
						else
							status = "LIKELY_CONNECTED"
							confidence = 0.78
						end
					elseif deltaY <= 4.0 and distH <= maxSpanH then
						status = "LIKELY_CONNECTED"
						confidence = 0.68
					else
						status = "NEAR_BUT_DISCONNECTED"
						confidence = 0.75
					end

					table.insert(connections, {
						fromId = segA.id,
						toId = segB.id,
						fromFolder = segA.sourceFolder,
						toFolder = segB.sourceFolder,
						dist3D = dist3D,
						distH = distH,
						deltaY = deltaY,
						alignment = dotAlignment,
						status = status,
						confidence = confidence
					})
				end
			end
		end
	end

	return connections
end

--------------------------------------------------------------------------------
-- 7. PHASE 9: INTERSECTION DETECTION
--------------------------------------------------------------------------------
function RoadSurvey.detectIntersections(segments, corridors)
	local intersections = {}
	local clusters = {}

	for i = 1, #segments do
		local segA = segments[i]
		for j = i + 1, #segments do
			local segB = segments[j]
			if segA.sourceFolder ~= segB.sourceFolder then
				local distH = Vector3.new(segA.center.X - segB.center.X, 0, segA.center.Z - segB.center.Z).Magnitude
				local deltaY = math.abs(segA.elevation - segB.elevation)

				if deltaY <= 3.5 and distH <= 45.0 then
					local interPos = (segA.center + segB.center) / 2
					local key = string.format("%.0f_%.0f", interPos.X / 40, interPos.Z / 40)

					if not clusters[key] then
						clusters[key] = {
							positions = { interPos },
							participatingFolders = { [segA.sourceFolder] = true, [segB.sourceFolder] = true },
							participatingSegments = { segA.id, segB.id },
							elevations = { interPos.Y }
						}
					else
						table.insert(clusters[key].positions, interPos)
						table.insert(clusters[key].participatingSegments, segA.id)
						table.insert(clusters[key].participatingSegments, segB.id)
						table.insert(clusters[key].elevations, interPos.Y)
						clusters[key].participatingFolders[segA.sourceFolder] = true
						clusters[key].participatingFolders[segB.sourceFolder] = true
					end
				end
			end
		end
	end

	local interId = 0
	for _, cluster in pairs(clusters) do
		interId = interId + 1
		local sumPos = Vector3.zero
		for _, p in ipairs(cluster.positions) do sumPos = sumPos + p end
		local avgPos = sumPos / #cluster.positions

		local folderList = {}
		for fName, _ in pairs(cluster.participatingFolders) do
			table.insert(folderList, fName)
		end

		local numBranches = #folderList
		local inferType = "UNKNOWN"
		if numBranches == 2 then
			inferType = "Crossing / Junction (2 Corridors)"
		elseif numBranches == 3 then
			inferType = "3-Way Intersection (T/Y-Junction)"
		elseif numBranches == 4 then
			inferType = "4-Way Crossroad"
		elseif numBranches > 4 then
			inferType = "Complex Multi-Way Intersection"
		end

		table.insert(intersections, {
			id = interId,
			position = avgPos,
			elevation = avgPos.Y,
			roads = folderList,
			type = inferType,
			confidence = math.clamp(0.70 + (numBranches * 0.08), 0.70, 0.95)
		})
	end

	return intersections
end

--------------------------------------------------------------------------------
-- 8. PHASE 10: ELEVATED CORRIDORS & RAMPS
--------------------------------------------------------------------------------
function RoadSurvey.detectElevatedAndRamps(segments, corridors)
	local elevatedSpans = {}
	local ramps = {}

	for _, corr in ipairs(corridors) do
		if corr.maxElevation >= 15.0 then
			local deltaElev = corr.maxElevation - corr.minElevation
			if deltaElev >= 10.0 and corr.totalLength >= 60.0 then
				table.insert(ramps, {
					id = #ramps + 1,
					corridorName = corr.name,
					minElevation = corr.minElevation,
					maxElevation = corr.maxElevation,
					grade = deltaElev / corr.totalLength,
					type = "RAMP_CORRIDOR",
					confidence = 0.89
				})
			else
				table.insert(elevatedSpans, {
					id = #elevatedSpans + 1,
					corridorName = corr.name,
					averageElevation = (corr.minElevation + corr.maxElevation) / 2,
					type = "ELEVATED_FLYOVER",
					confidence = 0.93
				})
			end
		end
	end

	return elevatedSpans, ramps
end

--------------------------------------------------------------------------------
-- 9. PHASE 11 & 12: STREAMINGENABLED AUDIT & FULL SURVEY RUNNER
--------------------------------------------------------------------------------
function RoadSurvey.runSurvey()
	local startTime = os.clock()
	local hierarchyAudit = RoadSurvey.auditHierarchy()
	local segments, samplePoints = RoadSurvey.buildRoadSegments(hierarchyAudit)
	local corridors = RoadSurvey.groupCorridors(segments)
	local connections = RoadSurvey.evaluateConnections(segments)
	local intersections = RoadSurvey.detectIntersections(segments, corridors)
	local elevatedSpans, ramps = RoadSurvey.detectElevatedAndRamps(segments, corridors)
	local duration = os.clock() - startTime

	local connectedCount = 0
	local elevatedSepCount = 0
	for _, c in ipairs(connections) do
		if c.status == "CONNECTED" or c.status == "LIKELY_CONNECTED" then
			connectedCount = connectedCount + 1
		elseif c.status == "ELEVATED_SEPARATION" then
			elevatedSepCount = elevatedSepCount + 1
		end
	end

	local result = {
		metadata = {
			placeId = game.PlaceId,
			jobId = game.JobId,
			streamingEnabled = Workspace.StreamingEnabled,
			surveyDurationSeconds = duration,
			timestamp = os.date("%Y-%m-%d %H:%M:%S")
		},
		hierarchy = hierarchyAudit,
		statistics = {
			discoveredRoadFolders = hierarchyAudit.totalDiscovered,
			loadedRoadFolders = hierarchyAudit.loadedFolders,
			unloadedRoadFolders = hierarchyAudit.unloadedFolders,
			totalLoadedParts = hierarchyAudit.totalLoadedParts,
			classifiedRoadSurfaces = #segments,
			centerlineSamples = #samplePoints,
			corridors = #corridors,
			evaluatedConnections = #connections,
			confirmedConnections = connectedCount,
			elevatedSeparations = elevatedSepCount,
			intersections = #intersections,
			elevatedSpans = #elevatedSpans,
			ramps = #ramps
		},
		roadSegments = segments,
		samplePoints = samplePoints,
		corridors = corridors,
		connections = connections,
		intersections = intersections,
		elevatedSpans = elevatedSpans,
		ramps = ramps
	}

	_G.HipHubRoadSurveyResult = result
	return result
end

--------------------------------------------------------------------------------
-- 10. PHASE 13 & 14: FORMATTED TEXT REPORT GENERATION
--------------------------------------------------------------------------------
function RoadSurvey.generateReport(surveyResult)
	local res = surveyResult or _G.HipHubRoadSurveyResult or RoadSurvey.runSurvey()
	local s = res.statistics
	local m = res.metadata

	local lines = {}
	local function add(txt) table.insert(lines, txt) end

	add("================================================================================")
	add("               🚗 DRAG DRIVE SIMULATOR (DDS) ROAD SURVEY REPORT                ")
	add("================================================================================")
	add(string.format("Place ID           : %s", tostring(m.placeId)))
	add(string.format("StreamingEnabled   : %s", tostring(m.streamingEnabled)))
	add(string.format("Survey Execution   : %.3f seconds at %s", m.surveyDurationSeconds, m.timestamp))
	add("--------------------------------------------------------------------------------")
	add("1. WORKSPACE HIERARCHY DISCOVERY")
	add(string.format("   • Road Folders Discovered : %d", s.discoveredRoadFolders))
	add(string.format("   • Folders Loaded in Mem   : %d", s.loadedRoadFolders))
	add(string.format("   • Folders Streamed Out    : %d (Empty on client due to distance)", s.unloadedRoadFolders))
	add(string.format("   • Total Parts Loaded      : %d", s.totalLoadedParts))
	add("")
	add("2. ROAD CLASSIFICATION & GEOMETRY")
	add(string.format("   • Valid Road Surfaces     : %d parts", s.classifiedRoadSurfaces))
	add(string.format("   • Centerline Samples      : %d points", s.centerlineSamples))
	add(string.format("   • Physical Corridors      : %d corridors", s.corridors))
	add("")
	add("3. CONNECTIVITY & INTERSECTIONS")
	add(string.format("   • Total Connection Pairs  : %d", s.evaluatedConnections))
	add(string.format("   • Confirmed Connections   : %d", s.confirmedConnections))
	add(string.format("   • Elevated Separations    : %d (Flyover over ground road)", s.elevatedSeparations))
	add(string.format("   • Detected Intersections  : %d junctions", s.intersections))
	add("")
	add("4. ELEVATION & BRIDGES")
	add(string.format("   • Elevated Flyover Spans  : %d", s.elevatedSpans))
	add(string.format("   • Sloped Ramps            : %d", s.ramps))
	add("--------------------------------------------------------------------------------")
	add("DISCOVERED ROAD FOLDERS INVENTORY:")

	for i, f in ipairs(res.hierarchy.discoveredFolders) do
		local status = f.isLoaded and string.format("[LOADED: %d parts]", f.loadedParts) or "[STREAMED OUT: 0 parts loaded]"
		add(string.format("   %02d. %-32s %-20s %s", i, f.name, f.className, status))
	end

	if #res.intersections > 0 then
		add("--------------------------------------------------------------------------------")
		add("SAMPLE DETECTED INTERSECTIONS:")
		for i = 1, math.min(8, #res.intersections) do
			local it = res.intersections[i]
			add(string.format("   #%02d Position: (X: %7.1f, Y: %5.1f, Z: %7.1f) | Type: %-25s | Conf: %.2f",
				it.id, it.position.X, it.position.Y, it.position.Z, it.type, it.confidence))
			add(string.format("        Connecting: %s", table.concat(it.roads, " <-> ")))
		end
	end

	add("--------------------------------------------------------------------------------")
	add("ARCHITECTURAL ASSESSMENT & RECOMMENDATION:")
	if m.streamingEnabled then
		add("   ⚠️  STREAMING ENABLED IS ACTIVE:")
		add("       Client memory only contains road geometry within ~500 studs of player.")
		add("       Dynamic runtime graph generation will miss unstreamed distant roads.")
		add("   💡  RECOMMENDED NEXT STEP: STATIC MAP SURVEY / PRECOMPILED GRAPH")
		add("       Export all surveyed road corridors into a static Lua coordinate graph.")
		add("       This enables 100% offline A* pathfinding with ZERO streaming limits!")
	else
		add("   ✅  FEASIBILITY: HIGH - Graph can be fully built in runtime.")
	end
	add("================================================================================")

	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- 11. PHASE 15: VISUALIZATION & LIGHTWEIGHT DEBUG UI
--------------------------------------------------------------------------------
local activeVisualsFolder = nil

function RoadSurvey.clearVisuals()
	if activeVisualsFolder then
		activeVisualsFolder:Destroy()
		activeVisualsFolder = nil
	end
end

function RoadSurvey.visualizeSurvey(surveyResult)
	RoadSurvey.clearVisuals()
	local res = surveyResult or _G.HipHubRoadSurveyResult
	if not res then return end

	local f = Instance.new("Folder")
	f.Name = "__DdsSurveyVisuals"
	f.Parent = Workspace

	-- 1. Visualize Centerline Samples (Green Spheres)
	for _, pt in ipairs(res.samplePoints) do
		local p = Instance.new("Part")
		p.Name = "Sample_" .. pt.id
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(1.8, 1.8, 1.8)
		p.Position = pt.position + Vector3.new(0, 1.0, 0)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(0, 230, 120)
		p.Transparency = 0.25
		p.Parent = f
	end

	-- 2. Visualize Intersections (Red Cylinders / Markers)
	for _, it in ipairs(res.intersections) do
		local p = Instance.new("Part")
		p.Name = "Intersection_" .. it.id
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(8.0, 12.0, 12.0)
		p.CFrame = CFrame.new(it.position + Vector3.new(0, 4.0, 0)) * CFrame.Angles(0, 0, math.rad(90))
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 60, 60)
		p.Transparency = 0.35
		p.Parent = f

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 160, 0, 30)
		bb.StudsOffset = Vector3.new(0, 8, 0)
		bb.AlwaysOnTop = true
		bb.Parent = p

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, 0, 1, 0)
		tl.BackgroundTransparency = 1
		tl.TextColor3 = Color3.fromRGB(255, 255, 255)
		tl.TextStrokeTransparency = 0
		tl.TextScaled = true
		tl.Font = Enum.Font.SourceSansBold
		tl.Text = "🛑 " .. it.type
		tl.Parent = bb
	end

	activeVisualsFolder = f
end

function RoadSurvey.createDebugUI()
	pcall(function()
		local oldGui = CoreGui:FindFirstChild("DdsRoadSurveyUI") or (player.PlayerGui and player.PlayerGui:FindFirstChild("DdsRoadSurveyUI"))
		if oldGui then oldGui:Destroy() end
	end)

	local sg = Instance.new("ScreenGui")
	sg.Name = "DdsRoadSurveyUI"
	sg.ResetOnSpawn = false

	local parentContainer = CoreGui:FindFirstChild("RobloxGui") or player:FindFirstChild("PlayerGui") or CoreGui
	sg.Parent = parentContainer

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 340, 0, 260)
	main.Position = UDim2.new(0.02, 0, 0.45, 0)
	main.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = main

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 32)
	title.Position = UDim2.new(0, 12, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = "🗺️ DDS Road Geometry Surveyor"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = main

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -24, 0, 80)
	statusLabel.Position = UDim2.new(0, 12, 0, 40)
	statusLabel.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	statusLabel.TextColor3 = Color3.fromRGB(180, 200, 220)
	statusLabel.Font = Enum.Font.Code
	statusLabel.TextSize = 11
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Top
	statusLabel.Text = " Status: Ready to survey.\n Click 'Scan Roads' to audit workspace."
	statusLabel.Parent = main
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 6); sc.Parent = statusLabel

	local function makeBtn(text, pos, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.46, 0, 0, 30)
		btn.Position = pos
		btn.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.SourceSansBold
		btn.TextSize = 13
		btn.Text = text
		btn.Parent = main
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	makeBtn("🔍 Scan Roads", UDim2.new(0.04, 0, 0, 130), function()
		statusLabel.Text = " Scanning road hierarchy..."
		task.wait(0.05)
		local res = RoadSurvey.runSurvey()
		local s = res.statistics
		statusLabel.Text = string.format(" Discovered: %d folders (%d loaded)\n Surfaces: %d parts | Samples: %d\n Connections: %d | Intersections: %d\n Duration: %.3fs",
			s.discoveredRoadFolders, s.loadedRoadFolders, s.classifiedRoadSurfaces, s.centerlineSamples, s.confirmedConnections, s.intersections, res.metadata.surveyDurationSeconds)
	end)

	makeBtn("👁️ Toggle Visuals", UDim2.new(0.50, 0, 0, 130), function()
		if activeVisualsFolder then
			RoadSurvey.clearVisuals()
			statusLabel.Text = statusLabel.Text .. "\n Visuals: Cleared."
		else
			RoadSurvey.visualizeSurvey()
			statusLabel.Text = statusLabel.Text .. "\n Visuals: Rendered (Green/Red)."
		end
	end)

	makeBtn("📄 Print Full Report", UDim2.new(0.04, 0, 0, 170), function()
		local report = RoadSurvey.generateReport()
		print(report)
		statusLabel.Text = statusLabel.Text .. "\n Full report printed to console!"
	end)

	makeBtn("❌ Close", UDim2.new(0.50, 0, 0, 170), function()
		RoadSurvey.clearVisuals()
		sg:Destroy()
	end)

	local closeTop = Instance.new("TextButton")
	closeTop.Size = UDim2.new(0, 24, 0, 24)
	closeTop.Position = UDim2.new(1, -28, 0, 4)
	closeTop.BackgroundTransparency = 1
	closeTop.Text = "✕"
	closeTop.TextColor3 = Color3.fromRGB(200, 80, 80)
	closeTop.Font = Enum.Font.SourceSansBold
	closeTop.TextSize = 16
	closeTop.Parent = main
	closeTop.MouseButton1Click:Connect(function()
		RoadSurvey.clearVisuals()
		sg:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- 12. AUTO-EXECUTION / GLOBAL EXPORT
--------------------------------------------------------------------------------
_G.HipHubRoadSurvey = RoadSurvey

-- Execute standalone survey when run
pcall(function()
	local report = RoadSurvey.generateReport()
	print(report)
	RoadSurvey.createDebugUI()
end)

return RoadSurvey
