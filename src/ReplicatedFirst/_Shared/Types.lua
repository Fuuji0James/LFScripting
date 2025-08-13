local promise = require(game:GetService("ReplicatedStorage").Libraries.promise)

local Types = {}

-- visualizer cache stuff
export type AdornmentData = {
	Adornment: LineHandleAdornment,
	LastUse: number,
}

-- bezier stuff
export type RealBezierFunc = (Time: number) -> Vector3
export type UsableBezier = (Distance: number) -> Vector3

export type BezierTable = {
	["Bezier"]: (Distance: number) -> Vector3,
	["TotalLength"]: number,
	["BezierID"]: Vector3,
	["Gradient"]: Vector3,
	["ControlPoints"]: { Vector3 },
} -- Differentiate for readability in the Mathfuncs script

export type CompositeBezierTable = {
	["CompositeBezier"]: (Distance: number) -> Vector3,
	["TotalLength"]: number,
	["BezierStartEndList"]: { BezierID: number, StartDist: number, EndDist: number },
	["CompositeGradient"]: (distance: number) -> Vector3,
} -- Differentiate for readability in the Mathfuncs script

export type ArrayPointProperties = { ["BezierID"]: number, ["Pos"]: Vector3, ["Distance"]: number }
export type LUT = { { ["BezierID"]: Vector2, ["Time"]: number, ["Distance"]: number } }

-- forces stuff
export type ForceRequirements = { -- table explaining what you need to create a force
	forceName: string,
	obj: Model | BasePart,

	-- raycasting
	controlPoints: { Vector3 }?,
	getSpeed: { ['Easing']: string?, ['Start']: number, ['End']: number? }, -- so you can tween it if u want
	LUT_Size: number?,

	raycastTime: number?, -- if the number is negative, it'll go infinitely, and hence the physball wont exist

	canCollideWith: RaycastParams?,
	spatialCollisionCheck: number?,
	-- recomputesEachUpdate: boolean, -- learn the auto tracking bezier for this

	maxUpdateDistance: number?,
	mediumUpdateDistance: number?,
	collisionCheckRadius: number?,
	raycastForward: number?,

	-- fns
	onFirstBounce: (oldPos: Vector3, newPos: Vector3, vel: Vector3, hit: RaycastResult) -> any?,
	onUpdate: (dt: number, oldPos: Vector3, newPos: Vector3, vel: Vector3) -> any?,

	-- pB
	physBallClass: {}?,
}

export type Force = { -- what's stored in the registry
	-- identification
	forceName: string,
	pathTable: {
		["Bezier"]: (Distance: number) -> Vector3,
		["TotalLength"]: number,
		["BezierID"]: Vector3,
		["Gradient"]: Vector3,
		["ControlPoints"]: { Vector3 },
	},
	obj: Model | BasePart,

	-- currently
	_currentPosition: Vector3,
	_currentVelocity: Vector3,
	currentDistance: number,
	currentPriority: number, -- LOW, MED, HIGH
	currentPhase: number, -- RAYCASTING, PHYSICS

	-- rendering/update stuff
	_hasCollision: boolean,
	_accumulatedDeltaTime: number,
	_updID: number,
	_goesIndefinitely: boolean,

	maxUpdateDistance: number,
	mediumUpdateDistance: number,
	canCollideWith: RaycastParams | nil,
	spatialCollisionCheck: number,

	_keepServerAlive: boolean, -- there are 3 different scenarios, so we have to account for them with tis

	-- may not be exist if it doesn't collide
	isNearAnyCollision: (() -> boolean) | nil --[[ function()
			-- spatial broadphase check (use Region3 or spatial hash)
			return CheckNearbyCollisionBox(self.Position)
		end]],
	getPositionWithRaycast: ((dist: number) -> Vector3 & RaycastResult) | nil --[[function(dist)
					-- Costlier but more accurate
					return ComputePositionWithPhysics(dist)
				end]],
	--
	-- will always exist
	onFirstBounce: (oldPos: Vector3, newPos: Vector3, vel: Vector3, hit: RaycastResult) -> any?,
	onUpdate: (dt: number, oldPos: Vector3, newPos: Vector3, vel: Vector3) -> any?,
	getPositionFast: (dist: number) -> Vector3 --[[function(dist)
			-- Use LUT or simplified math
			return LUTs[self.Id][math.floor(dist * LUT_SIZE)]
		end]],
	getSpeed: (dist: number) -> number, -- so you can tween it if u want
	jumpToDistance: (dist: number) -> any?, -- jumps to points along the curve

	-- pB

	partDescription: Enum.PartType | nil,
	physBallClass: {}?,
	promise: typeof(promise.new()),
}

return Types
