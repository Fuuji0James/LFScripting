local Players = game:GetService("Players")
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Comms"):WaitForChild("PB_ConstructorService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local _registry = game:GetService("ReplicatedFirst")._Shared._registry

local DEFAULT, SLIDE = 0, 1 -- (default keeps it upright, slide lets it roll)
local DEFUALTOFFSET = Vector3.new(0, 1.1, 0)

--

local CAMERA = game.Workspace.CurrentCamera
local TERRAIN = game.Workspace:WaitForChild("Terrain")

local UP = Vector3.new(0, 1, 0)
local FLOOR_CHECK = 10e5
local CHR_HEIGHT = 3.5

local rayPerams = RaycastParams.new()
rayPerams.FilterType = Enum.RaycastFilterType.Exclude
rayPerams.RespectCanCollide = true
rayPerams.IgnoreWater = true

export type physBallClass = {
	control: {
		getInput: () -> Vector3,
		-- maybe add other funcs
	},
	char: {
		contents: Model | BasePart,
		hipHeight: number, -- figure out what ts is
		rootPart: BasePart,
		rootAttach: Attachment, --(this would be made in the position of the rootPart)
		contentsSize: Vector3,
	},
	physBall: {
		part: Part,
		force: VectorForce,
		offset: Vector3,

		_mass: number,
		_worldAttach: Attachment,
		_alignPosition: AlignPosition,
		_alignOrientation: AlignOrientation,
		_uprightAlginOri: AlignOrientation,

		--

		isActive: boolean,
		isGrounded: boolean,
		floorMaterial: Enum.Material,

		_floorNormal: Vector3,
		_targetVelocity: Vector3,
		orientation: CFrame,
		_mode: number,

		-- tuning

		acceleration: number,
		speed: number,
		jumpPower: number,
	},

	updateConnection: RBXScriptConnection,
	uprightChangedConnection: RBXScriptConnection,
}

export type PB_ClassRequirements = {
	control: {
		getInput: () -> Vector3,
		-- maybe add other funcs
	},
	char: {
		contents: Model | BasePart,
		hipHeight: number, -- figure out what ts is
		rootPart: BasePart,
		contentsSize: Vector3,
	},
	physBallPart: BasePart,

	customProps: PhysicalProperties,
	size: Vector3,
	shape: Enum.PartType,

	acceleration: number,
	speed: number,
	jumpPower: number,
}

--

local function initAttachments(self: physBallClass)
	local rootAttach = Instance.new("Attachment")
	rootAttach.Name = "_RootAttachment"
	rootAttach.Parent = self.char.rootPart

	local worldAttach = Instance.new("Attachment")
	worldAttach.Name = "diveAttachment"
	worldAttach.Parent = TERRAIN

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.RigidityEnabled = true
	alignPosition.Enabled = false
	alignPosition.Attachment0 = rootAttach
	alignPosition.Attachment1 = worldAttach
	alignPosition.Parent = self.physBall.part

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.RigidityEnabled = true
	alignOrientation.Enabled = false
	alignOrientation.Attachment0 = rootAttach
	alignOrientation.Attachment1 = worldAttach
	alignOrientation.Parent = self.physBall.part

	-- another solution may be to weld it to the character, but idk, this seems fine
	local uprightAlginOri = Instance.new("AlignOrientation")
	uprightAlginOri.RigidityEnabled = true
	uprightAlginOri.Enabled = true
	uprightAlginOri.Attachment0 = self.physBall.part:WaitForChild("Center")
	uprightAlginOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	uprightAlginOri.CFrame = CFrame.new(Vector3.zero, Vector3.zAxis)
	uprightAlginOri.Parent = self.physBall.part

	-- self.humanoid.Died:Once(function()
	-- 	worldAttach:Destroy()
	-- end)

	return worldAttach, alignPosition, alignOrientation, rootAttach, uprightAlginOri
end

local function handleFloor(self: physBallClass, dt)
	local sB_Pos = self.physBall.part.Position

	local result = workspace:Raycast(sB_Pos, -FLOOR_CHECK * self.physBall._floorNormal, rayPerams)
	local floorDist = if result then (result.Position - sB_Pos).Magnitude else math.huge

	self.physBall.isGrounded = floorDist <= CHR_HEIGHT
	self.physBall._floorMaterial = if floorDist <= self.char.hipHeight then result.Material else Enum.Material.Air
	self.physBall._floorNormal = if result
		then (self.physBall.isGrounded and result.Normal or self.physBall._floorNormal:Lerp(
			result.Normal,
			math.min(dt * 5, 1)
		))
		else self.physBall._floorNormal:Lerp(vector.create(0, 1, 0), math.min(dt, 1))

	-- floor CFrame
	local lookVector = (CAMERA.CFrame.LookVector * vector.create(1, 0, 1)).Unit
	local floorCFrame = CFrame.new(vector.zero, lookVector)
	local localFloor = floorCFrame:VectorToObjectSpace(self.physBall._floorNormal)

	local x, y = math.atan2(-localFloor.X, localFloor.Y), math.atan2(localFloor.Z, localFloor.Y)
	local cfA = CFrame.Angles(y, 0, 0) * CFrame.Angles(0, 0, x)
	local cfB = CFrame.Angles(0, 0, x) * CFrame.Angles(y, 0, 0)

	floorCFrame *= cfA:Lerp(cfB, 0.5)

	return floorCFrame
end

local function handleModes(self: physBallClass, dt)
	local dot = UP:Dot(self.physBall._floorNormal)

	local input = self.control:getInput()
	local grounded = self.physBall.isGrounded

	local orientation: CFrame
	local speed = self.speed

	if input.Magnitude > 0 then
		input = input.Unit
	else
		input = vector.zero
	end

	if self.physBall._mode == SLIDE then
		-- Determine movement direction in world space
		local velocity = self.physBall.part.AssemblyLinearVelocity
		local moveVec

		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
			moveVec = (CAMERA.CFrame.LookVector * vector.create(1, 0, 1)).Unit
		else
			moveVec = if input:Dot(input) > 0
				then (self.char.rootPart.CFrame:VectorToWorldSpace(input * vector.create(1, 0, 1))).Unit
				else vector.zero
		end

		-- Calculate new velocity target
		if moveVec:Dot(moveVec) > 0 then
			local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
			local targetVelocity = moveVec * horizontalVelocity.Magnitude
			local blendedHorizontal = horizontalVelocity:Lerp(targetVelocity, dt * 3)

			velocity = Vector3.new(blendedHorizontal.X, velocity.Y, blendedHorizontal.Z)
			velocity = self.physBall.part.AssemblyLinearVelocity
		end

		local velMag = math.min(1000, velocity.Magnitude)

		speed = (dot < 1 or not grounded) and velMag or velMag * 0.1
		grounded = velocity.Magnitude > 0 and not (velocity.Unit:Dot(UP) < -0.8)

		if velocity.Magnitude > 0.75 then
			orientation = self.physBall.orientation:Lerp(CFrame.new(vector.zero, velocity), math.min(dt * 2, 1))
		else
			orientation = self.physBall.orientation
		end
	elseif self.physBall._mode == DEFAULT then
		-- keep the part upright
		-- Determine movement direction in world space
		local velocity = self.physBall.part.AssemblyLinearVelocity
		local moveVec

		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
			moveVec = (CAMERA.CFrame.LookVector * vector.create(1, 0, 1)).Unit
		else
			moveVec = if input:Dot(input) > 0
				then (self.char.rootPart.CFrame:VectorToWorldSpace(input * vector.create(1, 0, 1))).Unit
				else vector.zero
		end

		-- Calculate new velocity target
		if moveVec:Dot(moveVec) > 0 then
			local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
			local targetVelocity = moveVec * horizontalVelocity.Magnitude
			local blendedHorizontal = horizontalVelocity:Lerp(targetVelocity, dt * 3)

			velocity = Vector3.new(blendedHorizontal.X, velocity.Y, blendedHorizontal.Z)
			velocity = self.physBall.part.AssemblyLinearVelocity
		end

		local velMag = math.min(1000, velocity.Magnitude)

		speed = (dot < 1 or not grounded) and velMag or velMag * 0.1
		grounded = velocity.Magnitude > 0 and not (velocity.Unit:Dot(UP) < -0.8)

		if velocity.Magnitude > 0.75 then
			orientation = self.physBall.orientation:Lerp(CFrame.new(vector.zero, velocity), math.min(dt * 2, 1))
		else
			orientation = self.physBall.orientation
		end
	end

	return orientation, speed, input, grounded
end

-- class creation

local physBall = {}
physBall.__index = physBall

function physBall.new(requirements: PB_ClassRequirements)
	local self: physBallClass = {}
	setmetatable(self, physBall)

	local physBallPart = remotes.getPhysBall:InvokeServer()
	physBallPart.CustomPhysicalProperties = requirements.customProps

	self.control = requirements.control
	self.char = requirements.char
	self.physBall = {
		part = physBallPart,
		offset = DEFUALTOFFSET,
		force = physBallPart:WaitForChild("VectorForce"),

		_mass = physBallPart:GetMass(),

		-- later stuff
		-- _worldAttach = Attachment,
		-- _alignPosition = AlignPosition,
		-- _alignOrientation = AlignOrientation,

		--

		isActive = false,
		isGrounded = false,
		floorMaterial = Enum.Material.Air,

		_floorNormal = Vector3.new(0, 1, 0),
		_targetVelocity = Vector3.zero,
		orientation = CFrame.new(),
		_mode = DEFAULT,

		-- tuning

		acceleration = requirements.acceleration or 2,
		speed = requirements.speed or 50,
		jumpPower = requirements.jumpPower or 55,
	}

	self.physBall._worldAttach, self.physBall._alignPosition, self.physBall._alignOrientation, self.char.rootAttach, self.physBall._uprightAlginOri =
		initAttachments(self)

	rayPerams.FilterDescendantsInstances = { self.physBall.part, self.char.contents }

	return self
end

function physBall.setActive(
	self: physBallClass,
	bool: boolean,
	mode: number,
	partProperies: { Size: Vector3, Shape: Enum.PartType, offset: Vector3 }
)
	if bool == self.physBall.isActive then
		return
	end

	if bool then
		self.physBall.part.Parent = self.char.contents
		self.char.rootPart.AssemblyLinearVelocity = Vector3.zero
	else
		self.physBall.part.Parent = game:GetService("ReplicatedStorage")
		self.char.rootPart.AssemblyLinearVelocity = self.char.rootPart.AssemblyLinearVelocity
	end

	if partProperies then
		if not partProperies.offset then
			self.physBall.offset = DEFUALTOFFSET
		end

		for name, value in partProperies do
			if name == "offset" then
				-- sanitize rq
				if value.Magnitude > 3 then
					self.physBall.offset = DEFUALTOFFSET
				end
				self.physBall.offset = value
				continue
			end
			self.physBall.part[name] = value
		end
	end

	self.physBall.part.Anchored = not bool
	self.physBall.part.CFrame = self.char.rootPart.CFrame
	self.physBall.part.Velocity = Vector3.zero

	self.physBall._alignPosition.RigidityEnabled = not bool
	self.physBall._alignPosition.Enabled = bool
	self.physBall._alignOrientation.Enabled = bool

	self.physBall.orientation = self.char.rootPart.CFrame - self.char.rootPart.CFrame.Position

	self.physBall._mode = mode or DEFAULT
	self.physBall.isActive = bool

	-- handle modes
	if mode == DEFAULT then
		self.physBall._uprightAlginOri.Enabled = bool
	elseif mode == SLIDE then
		self.physBall._uprightAlginOri.Enabled = false
	end

	-- most likely have to do the same time sharing and fake update stuff to optimize it but this script is only 1 class, so i need a
	--	 class manager

	if mode == DEFAULT and bool then
		self.physBall._uprightAlginOri.Enabled = true
		self.uprightChangedConnection = self.char.rootPart.Changed:Connect(function(property)
			if property == "CFrame" then
				self.physBall._uprightAlginOri.CFrame = CFrame.new(
					self.char.rootPart.CFrame.Position,
					self.char.rootPart.CFrame.Position + self.char.rootPart.CFrame.LookVector
				)
			end
		end)

		print("stated tracking!")
	else
		if self.uprightChangedConnection and self.uprightChangedConnection.Connected then
			self.uprightChangedConnection:Disconnect()
			self.physBall._uprightAlginOri.Enabled = false
		end
	end

	if bool then
		self.updateConnection = RunService:BindToRenderStep("", Enum.RenderPriority.Input.Value, function(dt)
			self:update(dt)
		end)
	else
		if self.updateConnection and self.updateConnection.Connected then
			self.updateConnection:Disconnect()
		end
	end
end

function physBall.update(self: physBallClass, dt)
	if not self.physBall.isActive then
		return
	end

	local floorCFrame = handleFloor(self, dt)
	local orientation, speed, input, grounded = handleModes(self, dt)

	if input ~= Vector3.zero then
		print(floorCFrame:VectorToWorldSpace(input * speed))
	end

	-- print(self.physBall.part.AssemblyLinearVelocity.Magnitude)

	-- set values
	self.physBall.orientation = orientation
	self.physBall._targetVelocity = floorCFrame:VectorToWorldSpace(input * speed)

	if self.physBall._targetVelocity.Magnitude > 1000 then
		self.physBall._targetVelocity = self.physBall._targetVelocity.Unit * 1000
	end

	local force = grounded
			and (self.physBall._targetVelocity - self.physBall.part.AssemblyLinearVelocity) * self.physBall._mass * self.physBall.acceleration
		or Vector3.zero

	if force.Magnitude <= 4.5 then -- if it can only barely move that mass acutally*
		force = Vector3.zero
	end

	if force ~= Vector3.zero then
		-- print(force)
	end

	self.physBall.force.Force = force

	local cf = CFrame.new(self.physBall.part.Position + self.physBall.offset) * self.physBall.orientation

	self.char.rootPart.CFrame = cf
	self.physBall._worldAttach.CFrame = cf

	if self.physBall._floorMaterial == Enum.Material.Water then
		self.physBall.part.Anchored = true
	end
end

-- for deleting attachments & connections // Only call when the life cycle is 100% over
function physBall.bindCleanUp(self: physBallClass, signal: RBXScriptSignal)
	self.physBall._worldAttach:Destroy()
	self.physBall.part:Destroy()
end

return physBall
