local module = {}

local DefaultConfig = require(script.Parent.DefaultConfig)
local Types = require(game:GetService("ReplicatedFirst")._Shared.Types)

local function makeRequest(parentReceiver, dir, origin)
	local req: Types.ForceRequirements = {}
	local _ = Vector3.new

	req.controlPoints = { origin, dir.Unit * 20 + _(0, 20, 0), dir.Unit * 40 }
	req.forceName = "test"
	req.obj = game.Players.LocalPlayer.Character
	req.raycastTime = 3
	req.getSpeed = {
		Start = 30,
	}
	req.canCollideWith = RaycastParams.new()
	req.partDescription = {}

	-- local force = parentReceiver:applyRaycastForceToLocalPlayer(req)

	-- force.promise:andThen(function()
	local targetVelocity = (dir * 10 + (Vector3.new(0, 0, 0))).Unit * 20
	local force = parentReceiver:applyPhysForceToLocalPlayer(
		1,
		{ Size = Vector3.one*4.4, Shape = Enum.PartType.Ball },
		targetVelocity
	)
	-- end)
end

function module:SetupTestConfig()
	-- hook stuff is setup here, if you want to use _emitHook, just use config.Adapters.[name]() instead

	return DefaultConfig
end

function module:StartTest(parentReceiver: {})
	-- hook stuff can only be called here
	task.wait(3)
	local origin = Vector3.new(0, 1, 0)

	local function parametricEqn(t, radius)
		local x = origin.X + radius * math.cos(t)
		local z = origin.Z + radius * math.sin(t)

		return Vector3.new(x, origin.Y, z)
	end

	while true do
		task.wait(1)
		local dir = parametricEqn(math.random(1, 350), math.random(1, 5))
		makeRequest(parentReceiver, dir, origin)
	end
end

return module
