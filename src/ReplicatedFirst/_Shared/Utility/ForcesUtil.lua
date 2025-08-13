--[[ GOALS

1. Resultant forces // the latest position is found within the registry
2. Regualar forces w/o bezier
3. Bezier Forces -> Regular forces
-- 4. Optimization
5. server upd with ticks, client upd with heartbeat (at the same pos at time x)

]]
--consts
local HIGH, MED, LOW = 0, 1, 2
local RAYCASTING, PHYSICS = 0, 1

local rayPerams = RaycastParams.new()
rayPerams.RespectCanCollide = true
rayPerams.IgnoreWater = true

local futil = {
	updateGroups = {}, -- { [1] = {}, [2] = {}, ..., [framesPerCycle] = {} }
	currentGroup = 1, -- current upd grp
	allForces = {}, -- [id] = force // updates only
	forceCount = 0,
}
--consts

--requires
local pathUtil = require(game:GetService("ReplicatedFirst")._Shared.Utility.BezierUtils)
local promise = require(game:GetService("ReplicatedStorage").Libraries.promise)
local types = require(game:GetService("ReplicatedFirst")._Shared.Types)
local tblUtil = require(game:GetService("ReplicatedStorage").Libraries.TableUtil)
local _serviceRegistry = game:GetService("ReplicatedFirst")._Shared._registry

local RunService = game:GetService("RunService")
--requires

--privs
local function _addForce(self, force) --//make it only add to the update group if its raycasting ;-;
	local obj = force.obj
	local name = force.forceName
	local localname: string

	if self.States._registry[obj] then
		local count = 0
		-- print(self.States._registry[obj])
		for _, myForce: types.Force in self.States._registry[obj] do
			if (_ ~= "ResultantPos") and string.match(myForce.forceName, name) then
				count += 1
			end
		end

		if count > 0 then
			-- add in the force under a new name
			for _, force: types.Force in self.States._registry[obj] do
				if (_ ~= "ResultantPos") and force.forceName == name then
					count += 1
				end
			end

			localname = `{name}_{count}`

			self.States._registry[obj][localname] = force -- force
		else
			-- just use the name we have rn
			localname = name
			self.States._registry[obj][localname] = force
		end
	else
		-- make a new table
		localname = name
		self.States._registry[obj] = { [localname] = force, ["ResultantPos"] = Vector3.new() }
	end

	futil.forceCount += 1
	local id = futil.forceCount

	force._updID = id
	futil.allForces[id] = force

	-- Determine group assignment
	local groupIndex = ((id - 1) % futil.framesPerCycle) + 1 -- ////

	table.insert(futil.updateGroups[groupIndex], force)
end

local function _removeForce(self, force)
	local obj, forceName = force.obj, force.forceName
	self.States._registry[obj][forceName] = nil

	if tblUtil.IsEmpty(self.States._registry[obj]) then
		self.States._registry[obj] = nil
	end

	futil.forceCount -= 1
	futil.allForces[force._updID] = nil

	-- Remove from its update group
	for _, group in futil.updateGroups do
		for i = #group, 1, -1 do
			if group[i]._updID == force._updID then
				table.remove(group, i)
				break
			end
		end
	end
end

local function checkNearbyCollisionBox(force: types.Force): boolean
	-- use dynamic octree for ts
	return false
end

local function computePositionWithCollision(force: types.Force, dist: number)
	local dir = force.pathTable.Gradient(dist)
	local pos = force.pathTable.Bezier(dist)

	return workspace:Raycast(pos, dir * settings.ForwardCheck, rayPerams)
end

local function calculateResultantForObj(self, obj)
	local forces = self.States._registry[obj]

	if forces then
		-- do maths as long as all forces are in raycast phase
		-- if even one of them requires it to be in physball phase, then don't recalc

		local deb = true

		for _, force: types.Force in forces do
			if force.currentPhase == PHYSICS then
				deb = false
				return
			end
		end
	end
end

local function createForce(settings, forceReq: types.ForceRequirements, root)
	local pathTable: types.BezierTable

	local startingPhase: number
	local startingPosition: Vector3
	local hasCollison = true

	if
		(
			not forceReq.raycastTime
			or not forceReq.easing
			or not forceReq.controlPoints
			or not forceReq.canCollideWith
			or forceReq.raycastTime == 0
		) and forceReq.physBallClass
	then
		startingPhase = PHYSICS
		startingPosition = root.Position
	else
		pathTable = pathUtil:CreateBezierFunc(forceReq.controlPoints, forceReq.LUT_Size or settings.LUT_Size)

		startingPhase = RAYCASTING
		startingPosition = pathTable.Bezier(0)
	end
	print(startingPhase)
	if forceReq.raycastTime < 0 or not forceReq.canCollideWith then
		hasCollison = false
	end

	local force: types.Force = {
		-- identification
		forceName = `{forceReq.obj.Name}'s {forceReq.forceName}`,
		pathTable = pathTable,
		obj = forceReq.obj,

		-- currently
		_currentPosition = startingPosition,
		_currentVelocity = Vector3.zero,
		currentDistance = 0,
		currentPriority = LOW, -- LOW, MED, HIGH
		currentPhase = startingPhase, -- RAYCASTING, PHYSICS

		-- rendering/update stuff
		_hasCollision = hasCollison,
		-- _updID = number,  // gets set later
		maxUpdateDistance = forceReq.maxUpdateDistance or settings.maxUpdateDistance,
		mediumUpdateDistance = forceReq.mediumUpdateDistance or settings.mediumUpdateDistance,
		easing = forceReq.easing or 1,
		canCollideWith = forceReq.canCollideWith,
		spatialCollisionCheck = forceReq.spatialCollisionCheck or settings.spatialCollisionCheck,
		_accumulatedDeltaTime = 0,
		_goesIndefinitely = if forceReq.raycastTime < 0 and hasCollison == false then true else false,

		--

		-- will always exist
		getPositionFast = if startingPhase == RAYCASTING then pathTable.Bezier else nil,
		getSpeed = function()
			if not forceReq.getSpeed then
				return 1
			end

			if forceReq.getSpeed["Easing"] then
				-- use the easing function with tweenservice
			elseif forceReq.getSpeed["Start"] and not forceReq.getSpeed["End"] then
				return forceReq.getSpeed["Start"]
			else
				return 1
			end
		end,

		onUpdate = forceReq.onUpdate or function() end,

		-- pB
		physBallClass = forceReq.physBallClass,
	}

	if hasCollison then
		-- may not be exist if it doesn't collide
		function force.isNearAnyCollision()
			-- spatial broadphase check (use Region3 or spatial hash)
			return checkNearbyCollisionBox(force)
		end

		function force.getPositionWithRaycast(dist: number)
			-- Costlier but more accurate
			return computePositionWithCollision(dist)
		end
	end

	if not forceReq.getSpeed then
		print("default speed used, why?")
	end

	-- this force is missing its promise and updID
	return force
end

local function needsRaycast(force: types.Force)
	return ((force._hasCollision and force.isNearAnyCollision) and force.isNearAnyCollision())
end

local function getPriority(force: types.Force)
	local dist: number
	local priority: number
	local pos = force._currentPosition

	if RunService:IsClient() then
		-- use cam
		dist = (pos - game.Workspace.CurrentCamera.CFrame.Position).Magnitude
	else
		-- use closest player
		local positions = {}
		local lowest = math.huge

		for _, plr: Player in game:GetService("Players"):GetPlayers() do
			if plr.Character then
				local myPos = plr.Character.PrimaryPart.CFrame.Position
				local myDist = (pos - myPos).Magnitude

				table.insert(positions, myDist)
			end
		end

		for _, distance in positions do
			if distance < lowest then
				lowest = distance
			end
		end

		dist = lowest
	end

	if dist > force.mediumUpdateDistance then
		priority = LOW
	elseif dist > force.maxUpdateDistance then
		priority = MED
	elseif dist <= force.maxUpdateDistance then
		priority = HIGH
	end

	return priority
end

local function update(thisForce: types.Force, dt: number)
	if thisForce._goesIndefinitely then
		thisForce.currentDistance %= thisForce.pathTable.TotalLength
	else
		if thisForce.currentDistance >= thisForce.pathTable.TotalLength then
			thisForce.promise:_resolve(thisForce._currentPosition, thisForce._currentPosition, thisForce._currentVelocity)
		end
	end

	local distance = thisForce.currentDistance
	local oldPos = thisForce._currentPosition
	local newPos: Vector3
	local hit: RaycastResult

	if needsRaycast(thisForce) then
		newPos, hit = thisForce.getPositionWithRaycast(distance)
	else
		newPos = thisForce.getPositionFast(distance)
	end

	thisForce._currentPosition = newPos
	thisForce._currentVelocity = newPos - oldPos
	thisForce.currentDistance += dt * thisForce.getSpeed(distance)
	thisForce._accumulatedDeltaTime = 0

	if hit then
		thisForce.currentPhase = PHYSICS
		thisForce.onFirstBounce(oldPos, newPos, newPos - oldPos, hit)
	end

	thisForce.onUpdate(dt, oldPos, newPos, newPos - oldPos)
end

local function _updateForces(global_dt: number)
	if tblUtil.IsEmpty(futil.updateGroups) then
		return
	end

	local started = os.clock()
	local lastFrameTime = if RunService:IsClient() then math.clamp(game.Stats.FrameTime, 10e-10, 0.5) else (1 / 20) -- time the last frame probably took to render
	local group = futil.updateGroups[futil.currentGroup]

	-- updating the high priority ones
	for _, thisForce: types.Force in futil.allForces do
		if thisForce.currentPhase == PHYSICS then
			-- we dont care
			continue
		end

		if (os.clock() - started) > lastFrameTime then
			-- dont call update, just change the dt and go to the next frame
			thisForce._accumulatedDeltaTime += global_dt
			continue
		end

		-- priority first
		local priority = getPriority(thisForce)
		thisForce.currentPriority = priority

		if priority ~= HIGH then
			continue
		end

		if thisForce._accumulatedDeltaTime == 0 then
			-- meaning it hasn't accumulated anything from a laggy frame
			update(thisForce, global_dt)
		else
			update(thisForce, thisForce._accumulatedDeltaTime)
		end
	end

	for _, thisForce in group do
		if thisForce.currentPhase == PHYSICS then
			-- we dont care
			continue
		end

		if (os.clock() - started) > lastFrameTime then
			-- dont call update, just change the dt and go to the next frame
			thisForce._accumulatedDeltaTime += global_dt
			continue
		end

		-- Update priority first

		local priority = getPriority(thisForce)
		thisForce.currentPriority = priority

		if priority == HIGH then
			continue
		end

		-- Always accumulate time for lower priorities
		thisForce._accumulatedDeltaTime += global_dt

		local metMedRequirements = (priority == MED and thisForce._accumulatedDeltaTime >= (5 * lastFrameTime))
		local metLowRequirements = (priority == LOW and thisForce._accumulatedDeltaTime >= (10 * lastFrameTime))

		if metLowRequirements or metMedRequirements then
			update(thisForce, thisForce._accumulatedDeltaTime)
		end
	end

	-- Cycle group
	futil.currentGroup = (futil.currentGroup % futil.framesPerCycle) + 1
end

local function updateForces(global_dt: number)
	if tblUtil.IsEmpty(futil.updateGroups) then
		return
	end

	local lastFrameTime = if RunService:IsClient() then math.clamp(game.Stats.FrameTime, 1e-5, 0.5) else global_dt -- time the last frame probably took to render
	local group = futil.updateGroups[futil.currentGroup]
	local startTime = os.clock()

	-- High priority updates: always try to update every frame
	for _, thisForce: types.Force in futil.allForces do
		if thisForce.currentPhase == PHYSICS then
			continue
		end

		thisForce._accumulatedDeltaTime += global_dt
		thisForce.currentPriority = getPriority(thisForce)

		if thisForce.currentPriority == HIGH then
			update(thisForce, thisForce._accumulatedDeltaTime)
		end
	end

	-- Medium & Low priority forces: update on cadence thresholds
	for _, thisForce: types.Force in group do
		if thisForce.currentPhase == PHYSICS then
			continue
		end

		thisForce._accumulatedDeltaTime += global_dt
		thisForce.currentPriority = getPriority(thisForce)

		if thisForce.currentPriority == HIGH then
			continue -- already updated above
		end

		local priority = thisForce.currentPriority
		local enoughTime = (priority == MED and thisForce._accumulatedDeltaTime >= (5 * lastFrameTime))
			or (priority == LOW and thisForce._accumulatedDeltaTime >= (10 * lastFrameTime))

		if enoughTime then
			if os.clock() - startTime <= lastFrameTime then
				update(thisForce, thisForce._accumulatedDeltaTime)
			end
			-- If we're over budget, skip the update this frame — but time is still accumulating
		end
	end

	-- Cycle update group for next frame
	futil.currentGroup = (futil.currentGroup % futil.framesPerCycle) + 1
end

--privs

RunService.Heartbeat:Connect(function(deltaTime)
	updateForces(deltaTime)
end)

function futil.applyRaycastForceTo(
	self,
	ForceRequirements: types.ForceRequirements,
	startDistance: number?,
	usedOnPlayer: boolean
)
	local PB_ConstructorService = require(_serviceRegistry)["PB_ConstructorService"]
	local settings = self.Settings

	if tblUtil.IsEmpty(futil.updateGroups) then
		futil.framesPerCycle = settings.framesPerCycle

		for i = 1, settings.framesPerCycle do
			futil.updateGroups[i] = {}
		end
	end

	--

	local obj = ForceRequirements.obj
	local root
	local physBallClass = ForceRequirements.physBallClass

	-- creating physball
	if obj:IsA("BasePart") then
		root = obj
	else
		root = obj.PrimaryPart
	end

	-- simulating/doing the initial force
	local force: types.Force = createForce(settings, ForceRequirements, root)
	force.physBallClass = physBallClass

	-- raycast promise
	local raycastPromise = promise
		.new(function(resolve, _, onCancel)
			function force.onFirstBounce(oldPos: Vector3, newPos: Vector3, vel: Vector3, hit: RaycastResult)
				ForceRequirements.onFirstBounce(oldPos, newPos, vel, hit)
				resolve(oldPos, newPos, vel, hit)
			end

			---

			onCancel(function()
				-- for certain forces, have a check to see what kind of "stop" you want

				-- stop updating, tell clients too
				_removeForce(self, force)
			end)
		end)
		:catch(function(msg)
			warn(tostring(msg))
		end)

	raycastPromise:andThen(function()
		force.currentPhase = PHYSICS

		local physicsPromise = promise.new(function(resolve, _, onCancel)
			onCancel(function()
				--set physball to
				force.physBallClass:setActive(false)
				_removeForce(self, force)
			end)
		end)

		self["States"]._registry[obj][force.forceName].promise = physicsPromise
	end)

	force.promise = raycastPromise

	function force.jumpToDistance(dist: number)
		force.currentDistance = dist
	end

	-- allows upd to occur
	_addForce(self, force)

	return force
end

function futil.applyPhysForceTo(
	self,
	ForceRequirements: types.ForceRequirements,
	startDistance: number?,
	usedOnPlayer: boolean
)
	local PB_ConstructorService = require(_serviceRegistry)["PB_ConstructorService"]
	local settings = self.Settings
	local force: types.Force = createForce(settings, ForceRequirements)
end

return futil
