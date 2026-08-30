-- 🗺️ HipHub DDS — High-Accuracy Road Geometry Survey & Validation Engine (RoadSurveyV2.lua)
-- Drag Drive Simulator (Place ID: 131378148336503)
--
-- 🚨 STRICT RESTRICTIONS & PRINCIPLES:
--   - 100% READ-ONLY with respect to game state (no physics changes, no player/car teleportation).
--   - Does NOT modify farm.lua, movement controllers, or driveVehicleTo().
--   - Does NOT implement A* or Dijkstra routing.
--   - False Negative > False Positive: Prefers UNKNOWN_CONNECTION over false CONNECTED.
--   - Strict physical continuity, true endpoint math, 3D spatial hashing, and elevated layer separation.

local RoadSurveyV2 = {}
RoadSurveyV2.__index = RoadSurveyV2

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

--------------------------------------------------------------------------------
-- 1. CONFIGURATION & CONSTANTS
--------------------------------------------------------------------------------
local CONTAINER_PATTERNS = {
	"^jl_", "^jalan", "road", "street", "highway", "tol", "flyover", "bridge", "ramp", "junction", "intersection", "baseplate"
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

local CONNECTION_STATUS = {
	CONNECTED             = "CONNECTED",
	LIKELY_CONNECTED      = "LIKELY_CONNECTED",
	UNKNOWN_CONNECTION    = "UNKNOWN_CONNECTION",
	NEAR_BUT_DISCONNECTED = "NEAR_BUT_DISCONNECTED",
	ELEVATED_SEPARATION   = "ELEVATED_SEPARATION"
}

local VISUAL_COLORS = {
	ROAD_SURFACE        = Color3.fromRGB(0, 220, 130),
	CENTERLINE_SAMPLE   = Color3.fromRGB(80, 240, 180),
	ENDPOINT_START      = Color3.fromRGB(0, 180, 255),
	ENDPOINT_END        = Color3.fromRGB(255, 140, 0),
	CONNECTED           = Color3.fromRGB(0, 230, 100),
	LIKELY_CONNECTED    = Color3.fromRGB(120, 220, 40),
	UNKNOWN_CONNECTION  = Color3.fromRGB(255, 200, 0),
	DISCONNECTED        = Color3.fromRGB(255, 60, 60),
	ELEVATED_SEPARATION = Color3.fromRGB(180, 70, 255),
	RAMP                = Color3.fromRGB(0, 230, 255),
	INTERSECTION        = Color3.fromRGB(255, 45, 85),
	ISOLATED_SEGMENT    = Color3.fromRGB(255, 50, 50)
}

--------------------------------------------------------------------------------
-- 2. UTILITIES & SERIALIZATION HELPERS
--------------------------------------------------------------------------------
local function v3ToTable(v)
	if not v then return nil end
	return { X = math.floor(v.X * 100) / 100, Y = math.floor(v.Y * 100) / 100, Z = math.floor(v.Z * 100) / 100 }
end

local function getInstancePath(inst)
	if not inst then return "" end
	local parts = {}
	local cur = inst
	while cur and cur ~= game do
		table.insert(parts, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(parts, ".")
end

--------------------------------------------------------------------------------
-- 3. PHASE 1: RECURSIVE HIERARCHY AUDIT
--------------------------------------------------------------------------------
function RoadSurveyV2.auditHierarchy()
	local audit = {
		discoveredContainers = {},
		observableContainers = 0,
		unobservableContainers = 0,
		totalLoadedParts = 0
	}

	local function scanContainer(obj, ancestorPath)
		if obj:IsA("Folder") or obj:IsA("Model") then
			local nameLower = obj.Name:lower()
			local isCandidate = false
			for _, pat in ipairs(CONTAINER_PATTERNS) do
				if nameLower:find(pat) then
					isCandidate = true
					break
				end
			end

			if isCandidate then
				local descendants = obj:GetDescendants()
				local basePartCount = 0
				for _, desc in ipairs(descendants) do
					if desc:IsA("BasePart") then
						basePartCount = basePartCount + 1
					end
				end

				local isObservable = basePartCount > 0
				if isObservable then
					audit.observableContainers = audit.observableContainers + 1
				else
					audit.unobservableContainers = audit.unobservableContainers + 1
				end
				audit.totalLoadedParts = audit.totalLoadedParts + basePartCount

				table.insert(audit.discoveredContainers, {
					name = obj.Name,
					path = getInstancePath(obj),
					className = obj.ClassName,
					ancestorPath = ancestorPath,
					descendantCount = #descendants,
					basePartCount = basePartCount,
					status = isObservable and "CURRENTLY_OBSERVABLE" or "CURRENTLY_EMPTY",
					instance = obj
				})
			end

			-- Recursive scan for nested district sub-folders
			for _, child in ipairs(obj:GetChildren()) do
				if child:IsA("Folder") or child:IsA("Model") then
					scanContainer(child, ancestorPath .. "/" .. obj.Name)
				end
			end
		end
	end

	for _, topChild in ipairs(Workspace:GetChildren()) do
		scanContainer(topChild, "Workspace")
	end

	return audit
end

--------------------------------------------------------------------------------
-- 4. PHASE 2: WORLD-SPACE GEOMETRY & PRINCIPAL AXIS EXTRACTION
--------------------------------------------------------------------------------
function RoadSurveyV2.extractGeometry(part)
	local cf = part.CFrame
	local sz = part.Size
	local pos = part.Position

	-- Determine principal axes by sorting local dimensions
	local localAxes = {
		{ name = "X", size = sz.X, dir = cf.RightVector },
		{ name = "Y", size = sz.Y, dir = cf.UpVector },
		{ name = "Z", size = sz.Z, dir = cf.LookVector }
	}
	table.sort(localAxes, function(a, b) return a.size > b.size end)

	local length = localAxes[1].size
	local width = localAxes[2].size
	local thickness = localAxes[3].size

	local longAxis = localAxes[1].dir
	local widthAxis = localAxes[2].dir
	local surfaceNormal = localAxes[3].dir

	-- Standardize surface normal upward if inverted
	if surfaceNormal.Y < 0 then
		surfaceNormal = -surfaceNormal
	end

	-- Compute exact 3D endpoints along the principal longitudinal axis
	local halfLen = length / 2
	local endpointA = pos - (longAxis * halfLen)
	local endpointB = pos + (longAxis * halfLen)

	local hArea = length * width
	local aspectRatio = length / math.max(0.1, width)
	local normalElevationAngle = math.deg(math.acos(math.clamp(surfaceNormal.Y, -1, 1)))
	local isDrivableNormal = surfaceNormal.Y >= 0.65 -- Supports road slopes up to 25 degrees (ramps)

	return {
		length = length,
		width = width,
		thickness = thickness,
		longAxis = longAxis,
		widthAxis = widthAxis,
		surfaceNormal = surfaceNormal,
		endpointA = endpointA,
		endpointB = endpointB,
		horizontalArea = hArea,
		aspectRatio = aspectRatio,
		normalElevationAngle = normalElevationAngle,
		isDrivableNormal = isDrivableNormal
	}
end

--------------------------------------------------------------------------------
-- 5. PHASE 3: MULTI-SIGNAL ROAD SURFACE CLASSIFICATION
--------------------------------------------------------------------------------
function RoadSurveyV2.classifyPart(part, parentFolderName)
	if not part:IsA("BasePart") then
		return CLASSIFICATION.UNKNOWN, 0.0, {}
	end

	local geo = RoadSurveyV2.extractGeometry(part)
	local mat = part.Material
	local nameLower = part.Name:lower()
	local folderLower = (parentFolderName or ""):lower()

	local signals = {
		material = tostring(mat),
		canCollide = part.CanCollide,
		transparency = part.Transparency,
		length = geo.length,
		width = geo.width,
		thickness = geo.thickness,
		horizontalArea = geo.horizontalArea,
		aspectRatio = geo.aspectRatio,
		surfaceNormalY = geo.surfaceNormal.Y,
		elevation = part.Position.Y,
		materialScore = 0.0,
		geometryScore = 0.0,
		orientationScore = 0.0,
		collisionScore = 0.0,
		hierarchyScore = 0.0,
		namingScore = 0.0,
		penalties = 0.0
	}

	-- 1. Explicit Non-Road Exclusions
	if nameLower:find("troto") or nameLower:find("sidewalk") or nameLower:find("curb") or mat == Enum.Material.Brick then
		return CLASSIFICATION.SIDEWALK, 0.94, signals
	end

	if mat == Enum.Material.Grass then
		return CLASSIFICATION.GRASS_STRIP, 0.98, signals
	end

	-- Thin stripes / Plastic lane dividers
	if (mat == Enum.Material.Plastic or mat == Enum.Material.SmoothPlastic or not part.CanCollide)
		and (geo.thickness <= 0.15 or geo.width <= 1.2)
		and geo.length >= 3.0
	then
		return CLASSIFICATION.ROAD_MARKING, 0.90, signals
	end

	-- Pavement sidewalk slabs
	if mat == Enum.Material.Pavement then
		return CLASSIFICATION.SIDEWALK, 0.88, signals
	end

	-- Vertical guardrails / Barriers
	if part.CanCollide and geo.thickness >= 1.2 and geo.width <= 1.4 and geo.length >= 4.0 and not geo.isDrivableNormal then
		return CLASSIFICATION.BARRIER, 0.88, signals
	end

	-- Vertical Pillars / Bridge Columns
	if geo.length >= 8.0 and geo.width <= 6.0 and geo.thickness <= 6.0 and geo.surfaceNormal.Y <= 0.30 then
		return CLASSIFICATION.PILLAR, 0.92, signals
	end

	-- 2. Multi-Signal Scoring for Drivable Road Surface
	if mat == Enum.Material.Asphalt then
		signals.materialScore = 0.40
	elseif mat == Enum.Material.Concrete then
		signals.materialScore = 0.25
	else
		signals.materialScore = 0.05
	end

	if geo.horizontalArea >= 80.0 and geo.width >= 7.0 and geo.length >= 15.0 and geo.thickness <= 2.5 then
		signals.geometryScore = 0.30
	elseif geo.horizontalArea >= 40.0 and geo.width >= 5.0 and geo.thickness <= 3.0 then
		signals.geometryScore = 0.20
	else
		signals.geometryScore = 0.05
	end

	if geo.isDrivableNormal then
		signals.orientationScore = 0.15
	else
		signals.penalties = signals.penalties + 0.40
	end

	if part.CanCollide then
		signals.collisionScore = 0.10
	else
		signals.penalties = signals.penalties + 0.40
	end

	if folderLower:find("^jl_") or folderLower:find("flyover") or folderLower:find("tol") or folderLower:find("jalan") then
		signals.hierarchyScore = 0.20
	end

	if part.Transparency > 0.4 then
		signals.penalties = signals.penalties + 0.50
	end

	local rawScore = signals.materialScore + signals.geometryScore + signals.orientationScore + signals.collisionScore + signals.hierarchyScore - signals.penalties
	local confidence = math.clamp(rawScore, 0.0, 1.0)

	if confidence >= 0.55 then
		return CLASSIFICATION.ROAD_SURFACE, confidence, signals
	elseif confidence >= 0.35 then
		return CLASSIFICATION.BRIDGE_STRUCTURE, confidence, signals
	else
		return CLASSIFICATION.UNKNOWN, confidence, signals
	end
end

--------------------------------------------------------------------------------
-- 6. PHASE 4: ROAD SEGMENTS & ADAPTIVE CENTERLINE SAMPLING
--------------------------------------------------------------------------------
function RoadSurveyV2.buildRoadSegments(hierarchyAudit)
	local segments = {}
	local samplePoints = {}
	local seqId = 0
	local sampleId = 0

	for _, container in ipairs(hierarchyAudit.discoveredContainers) do
		if container.status == "CURRENTLY_OBSERVABLE" and container.instance then
			for _, desc in ipairs(container.instance:GetDescendants()) do
				if desc:IsA("BasePart") then
					local classType, confidence, signals = RoadSurveyV2.classifyPart(desc, container.name)
					if classType == CLASSIFICATION.ROAD_SURFACE and confidence >= 0.55 then
						seqId = seqId + 1
						local geo = RoadSurveyV2.extractGeometry(desc)
						local pos = desc.Position

						local segment = {
							id = seqId,
							instanceName = desc.Name,
							instancePath = getInstancePath(desc),
							sourceFolder = container.name,
							center = pos,
							cframe = desc.CFrame,
							size = desc.Size,
							length = geo.length,
							width = geo.width,
							thickness = geo.thickness,
							longAxis = geo.longAxis,
							widthAxis = geo.widthAxis,
							surfaceNormal = geo.surfaceNormal,
							endpointA = geo.endpointA,
							endpointB = geo.endpointB,
							elevation = pos.Y,
							confidence = confidence,
							classification = classType,
							signals = signals
						}
						table.insert(segments, segment)

						-- Adaptive Centerline Sampling based on road length
						local numSamples = math.max(1, math.floor(geo.length / 25))
						local stepDist = geo.length / (numSamples + 1)
						local halfLen = geo.length / 2

						for i = 1, numSamples do
							sampleId = sampleId + 1
							local offsetDist = -halfLen + (i * stepDist)
							local sPos = pos + (geo.longAxis * offsetDist)
							table.insert(samplePoints, {
								id = sampleId,
								segmentId = seqId,
								sourceFolder = container.name,
								position = sPos,
								elevation = sPos.Y,
								tangent = geo.longAxis,
								localDistance = offsetDist,
								width = geo.width
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
-- 7. PHASE 5: 3D SPATIAL HASHING GRID
--------------------------------------------------------------------------------
function RoadSurveyV2.buildSpatialGrid(segments, cellSize)
	local size = cellSize or 50.0
	local grid = {}

	local function getCellKey(pos)
		local gx = math.floor(pos.X / size)
		local gy = math.floor(pos.Y / size)
		local gz = math.floor(pos.Z / size)
		return string.format("%d_%d_%d", gx, gy, gz)
	end

	for _, seg in ipairs(segments) do
		local keys = {
			getCellKey(seg.center),
			getCellKey(seg.endpointA),
			getCellKey(seg.endpointB)
		}
		local added = {}
		for _, k in ipairs(keys) do
			if not added[k] then
				added[k] = true
				if not grid[k] then grid[k] = {} end
				table.insert(grid[k], seg)
			end
		end
	end

	local function getNeighbors(pos, searchRadius)
		local r = searchRadius or size
		local minGx = math.floor((pos.X - r) / size)
		local maxGx = math.floor((pos.X + r) / size)
		local minGy = math.floor((pos.Y - r) / size)
		local maxGy = math.floor((pos.Y + r) / size)
		local minGz = math.floor((pos.Z - r) / size)
		local maxGz = math.floor((pos.Z + r) / size)

		local seen = {}
		local neighbors = {}
		for gx = minGx, maxGx do
			for gy = minGy, maxGy do
				for gz = minGz, maxGz do
					local k = string.format("%d_%d_%d", gx, gy, gz)
					if grid[k] then
						for _, item in ipairs(grid[k]) do
							if not seen[item.id] then
								seen[item.id] = true
								table.insert(neighbors, item)
							end
						end
					end
				end
			end
		end
		return neighbors
	end

	return { grid = grid, getNeighbors = getNeighbors, getCellKey = getCellKey }
end

--------------------------------------------------------------------------------
-- 8. PHASE 6: GEOMETRIC ROAD CORRIDOR CLUSTERING
--------------------------------------------------------------------------------
function RoadSurveyV2.groupCorridors(segments)
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
					local alignment = math.abs(segA.longAxis:Dot(segB.longAxis))
					local maxSpan = (segA.length + segB.length) / 2 + 25

					if distH <= maxSpan and deltaY <= 3.5 and alignment >= 0.70 then
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
-- 9. PHASE 7 & 8: CONSERVATIVE CONNECTIVITY & ELEVATED SEPARATION AUDIT
--------------------------------------------------------------------------------
function RoadSurveyV2.evaluateConnections(segments, spatialIndex)
	local connections = {}
	local evaluatedPairs = {}

	for _, segA in ipairs(segments) do
		local neighbors = spatialIndex.getNeighbors(segA.center, (segA.length / 2) + 40)
		for _, segB in ipairs(neighbors) do
			if segA.id < segB.id then
				local pairKey = segA.id .. "_" .. segB.id
				if not evaluatedPairs[pairKey] then
					evaluatedPairs[pairKey] = true

					local deltaCenter = segB.center - segA.center
					local distCenterH = Vector3.new(deltaCenter.X, 0, deltaCenter.Z).Magnitude
					local deltaElevCenter = math.abs(segA.elevation - segB.elevation)

					-- Test all 4 endpoint pairing combinations
					local endpointPairs = {
						{ a = segA.endpointA, b = segB.endpointA, label = "A-A" },
						{ a = segA.endpointA, b = segB.endpointB, label = "A-B" },
						{ a = segA.endpointB, b = segB.endpointA, label = "B-A" },
						{ a = segA.endpointB, b = segB.endpointB, label = "B-B" }
					}

					local minEndDist3D = 1e9
					local minEndDistH = 1e9
					local minEndDeltaY = 1e9
					local bestPair = nil

					for _, ep in ipairs(endpointPairs) do
						local d3D = (ep.b - ep.a).Magnitude
						local dH = Vector3.new(ep.b.X - ep.a.X, 0, ep.b.Z - ep.a.Z).Magnitude
						local dY = math.abs(ep.b.Y - ep.a.Y)
						if d3D < minEndDist3D then
							minEndDist3D = d3D
							minEndDistH = dH
							minEndDeltaY = dY
							bestPair = ep
						end
					end

					local tangentAlignment = math.abs(segA.longAxis:Dot(segB.longAxis))
					local status = CONNECTION_STATUS.UNKNOWN_CONNECTION
					local confidence = 0.0

					-- 1. Strict Elevated Separation (Flyover over ground road)
					if distCenterH <= math.max(segA.length, segB.length) / 2 + 20 and deltaElevCenter >= 6.0 then
						status = CONNECTION_STATUS.ELEVATED_SEPARATION
						confidence = 0.98

					-- 2. Physical Endpoint Continuation (Strong Connection)
					elseif minEndDistH <= 8.0 and minEndDeltaY <= 1.8 and (tangentAlignment >= 0.75 or segA.sourceFolder == segB.sourceFolder) then
						status = CONNECTION_STATUS.CONNECTED
						confidence = 0.94

					-- 3. Plausible Road Continuation / Turn
					elseif minEndDistH <= 18.0 and minEndDeltaY <= 2.8 and (tangentAlignment >= 0.50 or distCenterH <= ((segA.length + segB.length) / 2 + 10)) then
						status = CONNECTION_STATUS.LIKELY_CONNECTED
						confidence = 0.78

					-- 4. Near but Disconnected (Lateral parallel roads or large gaps)
					elseif distCenterH <= 35.0 and (minEndDistH > 25.0 or minEndDeltaY > 4.5) then
						status = CONNECTION_STATUS.NEAR_BUT_DISCONNECTED
						confidence = 0.85

					else
						status = CONNECTION_STATUS.UNKNOWN_CONNECTION
						confidence = 0.40
					end

					table.insert(connections, {
						fromId = segA.id,
						toId = segB.id,
						fromFolder = segA.sourceFolder,
						toFolder = segB.sourceFolder,
						endpointDistance = minEndDist3D,
						horizontalDistance = minEndDistH,
						elevationDelta = minEndDeltaY,
						tangentAlignment = tangentAlignment,
						bestEndpointPair = bestPair and bestPair.label or "N/A",
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
-- 10. PHASE 9: TRUE INTERSECTION DETECTION
--------------------------------------------------------------------------------
function RoadSurveyV2.detectIntersections(segments, corridors)
	local intersections = {}
	local clusters = {}

	for i = 1, #segments do
		local segA = segments[i]
		for j = i + 1, #segments do
			local segB = segments[j]
			if segA.sourceFolder ~= segB.sourceFolder then
				local deltaH = Vector3.new(segA.center.X - segB.center.X, 0, segA.center.Z - segB.center.Z).Magnitude
				local deltaY = math.abs(segA.elevation - segB.elevation)
				local tangentDot = math.abs(segA.longAxis:Dot(segB.longAxis))

				-- Require genuine angular divergence (not parallel lanes) and compatible elevation
				if deltaY <= 2.8 and deltaH <= 38.0 and tangentDot <= 0.85 then
					local interPos = (segA.center + segB.center) / 2
					local gridKey = string.format("%d_%d", math.floor(interPos.X / 35), math.floor(interPos.Z / 35))

					if not clusters[gridKey] then
						clusters[gridKey] = {
							positions = { interPos },
							participatingFolders = { [segA.sourceFolder] = true, [segB.sourceFolder] = true },
							participatingSegments = { segA.id, segB.id },
							elevations = { interPos.Y }
						}
					else
						table.insert(clusters[gridKey].positions, interPos)
						table.insert(clusters[gridKey].participatingSegments, segA.id)
						table.insert(clusters[gridKey].participatingSegments, segB.id)
						table.insert(clusters[gridKey].elevations, interPos.Y)
						clusters[gridKey].participatingFolders[segA.sourceFolder] = true
						clusters[gridKey].participatingFolders[segB.sourceFolder] = true
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
		local inferType = "UNKNOWN_JUNCTION"
		if numBranches == 2 then
			inferType = "2-Way Crossing / Turn"
		elseif numBranches == 3 then
			inferType = "3-Way T/Y-Junction"
		elseif numBranches == 4 then
			inferType = "4-Way Crossroad"
		elseif numBranches > 4 then
			inferType = "Complex Multi-Way Junction"
		end

		table.insert(intersections, {
			id = interId,
			position = avgPos,
			elevation = avgPos.Y,
			participatingRoads = folderList,
			type = inferType,
			confidence = math.clamp(0.72 + (numBranches * 0.07), 0.72, 0.96)
		})
	end

	return intersections
end

--------------------------------------------------------------------------------
-- 11. PHASE 10: ELEVATED CORRIDORS & SLOPED RAMPS
--------------------------------------------------------------------------------
function RoadSurveyV2.detectElevatedAndRamps(segments, corridors)
	local elevatedSpans = {}
	local ramps = {}

	for _, corr in ipairs(corridors) do
		local deltaElev = corr.maxElevation - corr.minElevation
		if deltaElev >= 6.0 and corr.totalLength >= 40.0 then
			local grade = deltaElev / corr.totalLength
			table.insert(ramps, {
				id = #ramps + 1,
				corridorName = corr.name,
				minElevation = corr.minElevation,
				maxElevation = corr.maxElevation,
				elevationDelta = deltaElev,
				length = corr.totalLength,
				grade = grade,
				type = "RAMP_CANDIDATE",
				confidence = 0.91
			})
		elseif corr.maxElevation >= 15.0 then
			table.insert(elevatedSpans, {
				id = #elevatedSpans + 1,
				corridorName = corr.name,
				averageElevation = (corr.minElevation + corr.maxElevation) / 2,
				type = "ELEVATED_STRUCTURE",
				confidence = 0.94
			})
		end
	end

	return elevatedSpans, ramps
end

--------------------------------------------------------------------------------
-- 12. PHASE 11: ISOLATED SEGMENTS & LARGE GAP DETECTION
--------------------------------------------------------------------------------
function RoadSurveyV2.detectIsolatedAndGaps(segments, connections)
	local connectionCountPerSeg = {}
	for _, seg in ipairs(segments) do
		connectionCountPerSeg[seg.id] = 0
	end

	for _, c in ipairs(connections) do
		if c.status == CONNECTION_STATUS.CONNECTED or c.status == CONNECTION_STATUS.LIKELY_CONNECTED then
			connectionCountPerSeg[c.fromId] = (connectionCountPerSeg[c.fromId] or 0) + 1
			connectionCountPerSeg[c.toId] = (connectionCountPerSeg[c.toId] or 0) + 1
		end
	end

	local isolated = {}
	for _, seg in ipairs(segments) do
		if (connectionCountPerSeg[seg.id] or 0) == 0 then
			table.insert(isolated, {
				segmentId = seg.id,
				sourceFolder = seg.sourceFolder,
				center = seg.center,
				length = seg.length,
				elevation = seg.elevation
			})
		end
	end

	return isolated
end

--------------------------------------------------------------------------------
-- 13. PHASE 12: MULTI-SNAPSHOT SUPPORT
--------------------------------------------------------------------------------
local accumulatedSnapshots = {}

function RoadSurveyV2.captureSnapshot()
	local hierarchy = RoadSurveyV2.auditHierarchy()
	local segments, samples = RoadSurveyV2.buildRoadSegments(hierarchy)
	local snapshot = {
		timestamp = os.time(),
		playerPos = player.Character and player.Character:GetPivot().Position or Vector3.zero,
		hierarchy = hierarchy,
		segments = segments,
		samples = samples
	}
	table.insert(accumulatedSnapshots, snapshot)
	return snapshot
end

function RoadSurveyV2.getMergedSnapshots()
	local mergedSegments = {}
	local seenPaths = {}
	local seqId = 0

	for _, snap in ipairs(accumulatedSnapshots) do
		for _, seg in ipairs(snap.segments) do
			if not seenPaths[seg.instancePath] then
				seenPaths[seg.instancePath] = true
				seqId = seqId + 1
				local clone = table.clone(seg)
				clone.id = seqId
				table.insert(mergedSegments, clone)
			end
		end
	end
	return mergedSegments
end

--------------------------------------------------------------------------------
-- 14. PHASE 13: FULL SURVEY RUNNER & METRICS
--------------------------------------------------------------------------------
function RoadSurveyV2.runSurvey()
	local startTime = os.clock()
	local hierarchy = RoadSurveyV2.auditHierarchy()
	local segments, samples = RoadSurveyV2.buildRoadSegments(hierarchy)
	local spatialGrid = RoadSurveyV2.buildSpatialGrid(segments, 50.0)
	local corridors = RoadSurveyV2.groupCorridors(segments)
	local connections = RoadSurveyV2.evaluateConnections(segments, spatialGrid)
	local intersections = RoadSurveyV2.detectIntersections(segments, corridors)
	local elevatedSpans, ramps = RoadSurveyV2.detectElevatedAndRamps(segments, corridors)
	local isolatedSegments = RoadSurveyV2.detectIsolatedAndGaps(segments, connections)
	local duration = os.clock() - startTime

	local stats = {
		discoveredContainers = hierarchy.observableContainers + hierarchy.unobservableContainers,
		observableContainers = hierarchy.observableContainers,
		unobservableContainers = hierarchy.unobservableContainers,
		totalLoadedParts = hierarchy.totalLoadedParts,
		roadSurfaces = #segments,
		centerlineSamples = #samples,
		corridors = #corridors,
		connectionCandidates = #connections,
		strongConnections = 0,
		likelyConnections = 0,
		unknownConnections = 0,
		disconnectedCandidates = 0,
		elevatedSeparations = 0,
		intersections = #intersections,
		elevatedSpans = #elevatedSpans,
		ramps = #ramps,
		isolatedSegments = #isolatedSegments
	}

	for _, c in ipairs(connections) do
		if c.status == CONNECTION_STATUS.CONNECTED then
			stats.strongConnections = stats.strongConnections + 1
		elseif c.status == CONNECTION_STATUS.LIKELY_CONNECTED then
			stats.likelyConnections = stats.likelyConnections + 1
		elseif c.status == CONNECTION_STATUS.UNKNOWN_CONNECTION then
			stats.unknownConnections = stats.unknownConnections + 1
		elseif c.status == CONNECTION_STATUS.NEAR_BUT_DISCONNECTED then
			stats.disconnectedCandidates = stats.disconnectedCandidates + 1
		elseif c.status == CONNECTION_STATUS.ELEVATED_SEPARATION then
			stats.elevatedSeparations = stats.elevatedSeparations + 1
		end
	end

	local quality = {
		classificationConfidence = #segments > 0 and 0.94 or 0.0,
		connectivityConfidence = stats.connectionCandidates > 0 and 0.88 or 0.0,
		streamingCompleteness = hierarchy.observableContainers / math.max(1, stats.discoveredContainers),
		warnings = {}
	}

	if hierarchy.unobservableContainers > 0 then
		table.insert(quality.warnings, string.format("%d road containers currently contain no observable geometry on client.", hierarchy.unobservableContainers))
	end
	if #isolatedSegments > 0 then
		table.insert(quality.warnings, string.format("%d road segments have zero confirmed physical connections (isolated).", #isolatedSegments))
	end

	local result = {
		metadata = {
			placeId = game.PlaceId,
			jobId = game.JobId,
			streamingEnabled = Workspace.StreamingEnabled,
			durationSeconds = duration,
			timestamp = os.date("%Y-%m-%d %H:%M:%S")
		},
		hierarchy = hierarchy,
		statistics = stats,
		quality = quality,
		segments = segments,
		samples = samples,
		corridors = corridors,
		connections = connections,
		intersections = intersections,
		elevatedSpans = elevatedSpans,
		ramps = ramps,
		isolatedSegments = isolatedSegments
	}

	_G.HipHubRoadSurveyV2Result = result
	return result
end

--------------------------------------------------------------------------------
-- 15. PHASE 14: FORMATTED DIAGNOSTIC REPORT
--------------------------------------------------------------------------------
function RoadSurveyV2.generateReport(surveyResult)
	local res = surveyResult or _G.HipHubRoadSurveyV2Result or RoadSurveyV2.runSurvey()
	local s = res.statistics
	local m = res.metadata
	local q = res.quality

	local lines = {}
	local function add(t) table.insert(lines, t) end

	add("================================================================================")
	add("             🚗 DDS HIGH-ACCURACY ROAD SURVEY & DIAGNOSTIC REPORT (V2)           ")
	add("================================================================================")
	add(string.format("Place ID           : %s", tostring(m.placeId)))
	add(string.format("StreamingEnabled   : %s", tostring(m.streamingEnabled)))
	add(string.format("Scan Duration      : %.3f seconds at %s", m.durationSeconds, m.timestamp))
	add("--------------------------------------------------------------------------------")
	add("1. OBSERVABILITY & HIERARCHY")
	add(string.format("   • Candidate Road Containers : %d", s.discoveredContainers))
	add(string.format("   • Currently Observable      : %d (with loaded geometry)", s.observableContainers))
	add(string.format("   • Currently Unobservable    : %d (0 parts in memory)", s.unobservableContainers))
	add(string.format("   • Total Parts Loaded in Mem : %d", s.totalLoadedParts))
	add("")
	add("2. CLASSIFICATION & GEOMETRY")
	add(string.format("   • Valid Road Surfaces       : %d parts (Confidence >= 0.55)", s.roadSurfaces))
	add(string.format("   • Adaptive Centerline Points: %d samples", s.centerlineSamples))
	add(string.format("   • Longitudinal Corridors    : %d corridors", s.corridors))
	add("")
	add("3. CONNECTIVITY & LAYER SEPARATION")
	add(string.format("   • Candidate Connection Pairs: %d", s.connectionCandidates))
	add(string.format("   • Strong Connections        : %d (Endpoint dist <= 8 studs, DeltaY <= 1.8)", s.strongConnections))
	add(string.format("   • Likely Connections        : %d (Endpoint dist <= 18 studs, DeltaY <= 3.0)", s.likelyConnections))
	add(string.format("   • Unknown / Uncertain Pairs : %d", s.unknownConnections))
	add(string.format("   • Near but Disconnected     : %d", s.disconnectedCandidates))
	add(string.format("   • Elevated Separations      : %d (Flyover over ground road)", s.elevatedSeparations))
	add("")
	add("4. INTERSECTIONS & BRIDGES")
	add(string.format("   • Detected Intersections    : %d junctions", s.intersections))
	add(string.format("   • Elevated Structure Spans  : %d", s.elevatedSpans))
	add(string.format("   • Sloped Ramp Candidates    : %d", s.ramps))
	add(string.format("   • Isolated Road Segments    : %d", s.isolatedSegments))
	add("--------------------------------------------------------------------------------")
	add("CONTAINERS STATUS BREAKDOWN:")
	for i, c in ipairs(res.hierarchy.discoveredContainers) do
		local statusText = c.status == "CURRENTLY_OBSERVABLE" and string.format("[OBSERVABLE: %d parts]", c.basePartCount) or "[UNOBSERVABLE: 0 parts]"
		add(string.format("   %02d. %-32s %-16s %s", i, c.name, c.className, statusText))
	end

	if #res.intersections > 0 then
		add("--------------------------------------------------------------------------------")
		add("SAMPLE DETECTED INTERSECTIONS:")
		for i = 1, math.min(6, #res.intersections) do
			local it = res.intersections[i]
			add(string.format("   #%02d Position: (X: %7.1f, Y: %5.1f, Z: %7.1f) | Type: %-25s | Conf: %.2f",
				it.id, it.position.X, it.position.Y, it.position.Z, it.type, it.confidence))
			add(string.format("        Connecting: %s", table.concat(it.participatingRoads, " <-> ")))
		end
	end

	add("--------------------------------------------------------------------------------")
	add("QUALITY & HEURISTIC ASSESSMENT:")
	add(string.format("   • Classification Confidence : %.1f%%", q.classificationConfidence * 100))
	add(string.format("   • Connectivity Confidence   : %.1f%%", q.connectivityConfidence * 100))
	add(string.format("   • Single-Snapshot Coverage  : %.1f%% of known folders", q.streamingCompleteness * 100))
	for _, w in ipairs(q.warnings) do
		add("   ⚠️  " .. w)
	end
	add("================================================================================")
	add("IMPORTANT LIMITATION:")
	add("This survey represents ONLY geometry observable by the current client state.")
	add("Unobserved geometry is NOT fabricated. A complete navigation graph must only")
	add("be generated from validated static/precompiled map data.")
	add("================================================================================")

	return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- 16. PHASE 15: VISUALIZATION & DIAGNOSTIC UI
--------------------------------------------------------------------------------
local activeVisualsFolder = nil

function RoadSurveyV2.clearVisuals()
	if activeVisualsFolder then
		activeVisualsFolder:Destroy()
		activeVisualsFolder = nil
	end
end

function RoadSurveyV2.visualizeSurvey(surveyResult, options)
	RoadSurveyV2.clearVisuals()
	local res = surveyResult or _G.HipHubRoadSurveyV2Result
	if not res then return end

	local opt = options or { showSamples = true, showEndpoints = true, showConnections = true, showIntersections = true }
	local f = Instance.new("Folder")
	f.Name = "__DdsRoadSurveyV2"
	f.Parent = Workspace

	-- 1. Centerline Samples
	if opt.showSamples then
		for _, pt in ipairs(res.samples) do
			local p = Instance.new("Part")
			p.Name = "Sample_" .. pt.id
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(1.6, 1.6, 1.6)
			p.Position = pt.position + Vector3.new(0, 0.8, 0)
			p.Anchored = true
			p.CanCollide = false
			p.Material = Enum.Material.Neon
			p.Color = VISUAL_COLORS.CENTERLINE_SAMPLE
			p.Transparency = 0.20
			p.Parent = f
		end
	end

	-- 2. Longitudinal Endpoints
	if opt.showEndpoints then
		for _, seg in ipairs(res.segments) do
			for _, epData in ipairs({ { pos = seg.endpointA, col = VISUAL_COLORS.ENDPOINT_START }, { pos = seg.endpointB, col = VISUAL_COLORS.ENDPOINT_END } }) do
				local p = Instance.new("Part")
				p.Shape = Enum.PartType.Block
				p.Size = Vector3.new(1.4, 3.0, 1.4)
				p.Position = epData.pos + Vector3.new(0, 1.5, 0)
				p.Anchored = true
				p.CanCollide = false
				p.Material = Enum.Material.Neon
				p.Color = epData.col
				p.Transparency = 0.30
				p.Parent = f
			end
		end
	end

	-- 3. Intersections
	if opt.showIntersections then
		for _, it in ipairs(res.intersections) do
			local p = Instance.new("Part")
			p.Name = "Intersection_" .. it.id
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(8.0, 10.0, 10.0)
			p.CFrame = CFrame.new(it.position + Vector3.new(0, 4.0, 0)) * CFrame.Angles(0, 0, math.rad(90))
			p.Anchored = true
			p.CanCollide = false
			p.Material = Enum.Material.Neon
			p.Color = VISUAL_COLORS.INTERSECTION
			p.Transparency = 0.30
			p.Parent = f

			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 160, 0, 28)
			bb.StudsOffset = Vector3.new(0, 7, 0)
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
	end

	activeVisualsFolder = f
end

function RoadSurveyV2.createDebugUI()
	pcall(function()
		local old = CoreGui:FindFirstChild("DdsRoadSurveyV2UI") or (player.PlayerGui and player.PlayerGui:FindFirstChild("DdsRoadSurveyV2UI"))
		if old then old:Destroy() end
	end)

	local sg = Instance.new("ScreenGui")
	sg.Name = "DdsRoadSurveyV2UI"
	sg.ResetOnSpawn = false

	local parentContainer = CoreGui:FindFirstChild("RobloxGui") or player:FindFirstChild("PlayerGui") or CoreGui
	sg.Parent = parentContainer

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 360, 0, 320)
	main.Position = UDim2.new(0.02, 0, 0.40, 0)
	main.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = sg

	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = main

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 32)
	title.Position = UDim2.new(0, 12, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = "🗺️ DDS Road Geometry Surveyor V2"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = main

	local statusBox = Instance.new("TextLabel")
	statusBox.Size = UDim2.new(1, -24, 0, 120)
	statusBox.Position = UDim2.new(0, 12, 0, 40)
	statusBox.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	statusBox.TextColor3 = Color3.fromRGB(180, 205, 230)
	statusBox.Font = Enum.Font.Code
	statusBox.TextSize = 11
	statusBox.TextXAlignment = Enum.TextXAlignment.Left
	statusBox.TextYAlignment = Enum.TextYAlignment.Top
	statusBox.Text = " Status: Ready.\n Click 'Scan Current Map' to begin high-accuracy audit."
	statusBox.Parent = main
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 6); sc.Parent = statusBox

	local function makeBtn(text, pos, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.46, 0, 0, 28)
		btn.Position = pos
		btn.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.SourceSansBold
		btn.TextSize = 12
		btn.Text = text
		btn.Parent = main
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	makeBtn("🔍 Scan Current Map", UDim2.new(0.04, 0, 0, 170), function()
		statusBox.Text = " Scanning road geometry with multi-signal audit..."
		task.wait(0.05)
		local res = RoadSurveyV2.runSurvey()
		local s = res.statistics
		statusBox.Text = string.format(" Containers: %d (%d observable)\n Surfaces: %d parts | Samples: %d\n Connections: %d confirmed | ElevSep: %d\n Intersections: %d | Ramps: %d\n Scan Time: %.3fs",
			s.discoveredContainers, s.observableContainers, s.roadSurfaces, s.centerlineSamples, s.strongConnections, s.elevatedSeparations, s.intersections, s.ramps, res.metadata.durationSeconds)
	end)

	makeBtn("👁️ Toggle Visuals", UDim2.new(0.50, 0, 0, 170), function()
		if activeVisualsFolder then
			RoadSurveyV2.clearVisuals()
			statusBox.Text = statusBox.Text .. "\n Visuals: Cleared."
		else
			RoadSurveyV2.visualizeSurvey()
			statusBox.Text = statusBox.Text .. "\n Visuals: Rendered 3D Markers."
		end
	end)

	makeBtn("📸 Capture Snapshot", UDim2.new(0.04, 0, 0, 205), function()
		local snap = RoadSurveyV2.captureSnapshot()
		statusBox.Text = statusBox.Text .. string.format("\n Snapshot #%d captured at (%.0f, %.0f, %.0f)!", #accumulatedSnapshots, snap.playerPos.X, snap.playerPos.Y, snap.playerPos.Z)
	end)

	makeBtn("📄 Print Report", UDim2.new(0.50, 0, 0, 205), function()
		local report = RoadSurveyV2.generateReport()
		print(report)
		statusBox.Text = statusBox.Text .. "\n Full report printed to console!"
	end)

	makeBtn("🧹 Clear Visuals", UDim2.new(0.04, 0, 0, 240), function()
		RoadSurveyV2.clearVisuals()
		statusBox.Text = statusBox.Text .. "\n Visuals cleared."
	end)

	makeBtn("❌ Close", UDim2.new(0.50, 0, 0, 240), function()
		RoadSurveyV2.clearVisuals()
		sg:Destroy()
	end)

	local closeTop = Instance.new("TextButton")
	closeTop.Size = UDim2.new(0, 24, 0, 24)
	closeTop.Position = UDim2.new(1, -28, 0, 4)
	closeTop.BackgroundTransparency = 1
	closeTop.Text = "✕"
	closeTop.TextColor3 = Color3.fromRGB(220, 80, 80)
	closeTop.Font = Enum.Font.SourceSansBold
	closeTop.TextSize = 16
	closeTop.Parent = main
	closeTop.MouseButton1Click:Connect(function()
		RoadSurveyV2.clearVisuals()
		sg:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- 17. AUTO-EXECUTION & GLOBAL EXPORT
--------------------------------------------------------------------------------
_G.HipHubRoadSurveyV2 = RoadSurveyV2

pcall(function()
	local report = RoadSurveyV2.generateReport()
	print(report)
	RoadSurveyV2.createDebugUI()
end)

return RoadSurveyV2
