-- when im done this imma make it so that ongoing forces play when you join
-- Explorer stuff
local LocalizationService = game:GetService("LocalizationService")
local RS = game:GetService("ReplicatedStorage")
local Comms = RS.Comms:WaitForChild("ForcesService")
local Types = require(game:GetService("ReplicatedFirst")._Shared.Types)
local HelperFns = require(game:GetService("ReplicatedFirst")._Shared.Utility.ForcesUtil)
local initPhysBall = require(game:GetService("ReplicatedFirst")._Shared.Utility.InitPhysBall)
local _registry = game:GetService("ReplicatedFirst")._Shared._registry

---
local player = game.Players.LocalPlayer

--- Dependencies/Frameworks
local _HookBase = require(game:GetService("ReplicatedStorage").Module_Bases._HookBase)
local DefaultConfig = require(script.DefaultConfig)
---

--Privates
function IncludeInjectionsFromServer(self, __shared, __settings)
	-- keeping this the same is usually fine

	if __shared then
		for name, fn_name in __shared["ClientAdapters"] do
			self:_attachHook("adapter", name, DefaultConfig.Adapters.KnownAdapters[name][fn_name])
		end
	end

	if __settings then
		-- We add in its settings with what the we have
		for name, value in __settings do
			if self.Settings[name] then
				continue
			end

			self.Settings[name] = value
		end
	end
end

function SyncToServer(self, Package: {}, SyncType: number)
	-- when the tickservice recieves a resync, just sync this too
end

---

local Receiver = {
	["TestingFlag"] = true,
}

Receiver.__index = Receiver
setmetatable(Receiver, _HookBase)

function Receiver.new(MockTestingConfig)
	local self = _HookBase.new(MockTestingConfig, DefaultConfig)
	setmetatable(self, Receiver)

	-- Client only stuff:
	local States = {}

	States._registry = {}
	-- States.MyForces = {}
	-- States.Resultant = Vector3.zero
	States.IsRunning = false
	States.forceCount = 0

	---

	self.Connections = {}
	self.OnEvents = {}
	self.myPhysBall = nil

	self["States"] = States
	self["Settings"] = self._config.Settings

	return self
end

-- because this needs the character, which becomes nil upon death, this should be a controller, and the :run func should run when he respawns
function Receiver:Run()
	self["States"].IsRunning = true

	local req: initPhysBall.PB_ClassRequirements = {}
	req.char = {
		contents = (player.Character or game.Players.LocalPlayer.CharacterAdded:Wait()),
		contentsSize = player.Character:GetExtentsSize(),
		hipHeight = 0,
		rootPart = player.Character.PrimaryPart,
	}
	req.control = { getInput = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls().GetMoveVector }
	req.customProps = PhysicalProperties.new(0.2, 0, 0, 10, 10)

	self.myPhysBall = initPhysBall.new(req)

	local RequestServerInfo = Comms:WaitForChild("RequestInfoFromServer")

	local Package = RequestServerInfo:InvokeServer()
	IncludeInjectionsFromServer(self, nil, Package[2])
end

-- this function shouldnt make forces stop updating, since its a controller, only deal with out character's stuff
function Receiver.OnClose()
	print("Stopped Listening") -- then destroy connections etc.
end

---

function Receiver:applyRaycastForceToLocalPlayer(ForceRequirements: Types.ForceRequirements)
	-- compensate for the client and server seeing different things due to latency
	local ForceAppliedForPlayer: RemoteEvent = Comms:WaitForChild("ForceAppliedForPlayer")
	ForceAppliedForPlayer:FireServer(ForceRequirements)

	local att = Instance.new("Attachment", workspace.Terrain)
	local part = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
	-- part.CanCollide = false
	-- part.Name = "Client_ball " .. ForceRequirements.forceName
	-- part.Shape = Enum.PartType.Ball
	-- part.Color = Color3.fromRGB(103, 156, 255)

	local partAtt = Instance.new("Attachment", part)

	local alignPos, alignOri = self:_emitHook("getAlignments", part, partAtt, att) -- destroy them later

	function ForceRequirements.onUpdate(dt: number, oldPos: Vector3, newPos: Vector3, vel: Vector3)
		local forward = vel.Magnitude > 0.001 and vel.Unit or att.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -1))
		att.CFrame = CFrame.lookAt(newPos, newPos + forward)
	end

	--

	print("force created!")
	local force: Types.Force = HelperFns.applyRaycastForceTo(self, ForceRequirements)

	return force
end

function Receiver:applyPhysForceToLocalPlayer(
	mode: number,
	partProperies: { Size: Vector3, Shape: Enum.PartType, offset: Vector3 },
	targetVelocity: Vector3
)
	self.myPhysBall:setActive(true, mode, partProperies)
	self.myPhysBall.physBall.part.AssemblyLinearVelocity = targetVelocity
end

return Receiver
