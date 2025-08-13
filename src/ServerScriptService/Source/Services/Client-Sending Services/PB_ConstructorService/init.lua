-- make it so that players' physballs cant collide with other players
-- This just exists so that you can get your Physball instances

local Players = game:GetService("Players")
local HookBase = require(game:GetService("ReplicatedStorage").Module_Bases._HookBase)

local SetupServiceComms = require(script:FindFirstAncestor("Services").Helpers.SetupServiceComms)

local Service = {
	["Name"] = script.Name,
	["TestingFlag"] = false,
}
Service.__index = Service
setmetatable(Service, HookBase)

local DefaultConfig = require(script.DefaultConfig)

-- Privates
local COLLISIONKEY = "physBall"

local physicsService = game:GetService("PhysicsService")
physicsService:RegisterCollisionGroup(COLLISIONKEY)
physicsService:CollisionGroupSetCollidable(COLLISIONKEY, COLLISIONKEY, false)

--

local function setCollisionGroup(children, key)
	for i = 1, #children do
		local child = children[i]
		if child:IsA("BasePart") or child:IsA("MeshPart") or child:IsA("Part") then
			child.CollisionGroup = COLLISIONKEY
		end
		setCollisionGroup(child:GetChildren(), key)
	end
end

local function getPhysBall(self, plr)
	local pb: BasePart = self["States"].__TemplatePhysBall:Clone()
	pb.Name = "physBall"
	pb.Parent = plr.Character or plr.CharacterAdded:Wait()
	pb:SetNetworkOwner(plr)

	pb.CollisionGroup = COLLISIONKEY
	setCollisionGroup(plr.Character:GetChildren(), COLLISIONKEY)

	return pb
end

function SetupFRS(self)
	local Folder = Instance.new("Folder", game:GetService("ReplicatedStorage").Comms)
	Folder.Name = `{script.Name}`

	SetupServiceComms.SetupRemotes(nil, {
		[`getPhysBall`] = {
			`RemoteFunction`,
			function(plr)
				return self["States"].allPhysBalls[plr]
			end,
		},
	}, Folder)

	return Folder
end

local function setupPhysBall(self)
	local p = Instance.new("Part", game:GetService("ReplicatedStorage"))
	p.Transparency = 0.3
	p.BrickColor = BrickColor.random()
	p.Size = vector.create(4, 5, 1)
	p.Name = "__TemplatePhysBall"
	p.Shape = Enum.PartType.Block
	p.CustomPhysicalProperties = PhysicalProperties.new(0.2, 0, 0, 10, 10)

	local a = Instance.new("Attachment", p)
	a.Name = "Center"
	a.Axis = vector.create(1, 0, 0)
	a.SecondaryAxis = vector.create(0, 1, 0)

	local vF = Instance.new("VectorForce", p)
	vF.Enabled = true
	vF.Attachment0 = a
	vF.RelativeTo = Enum.ActuatorRelativeTo.World
	vF.Force = vector.zero
	vF.ApplyAtCenterOfMass = true

	self["States"].__TemplatePhysBall = p
end

---

--- LifeCycle stuff

function Service.new(MockTestingConfig) -- Really just an initialize function, but i call it this since its a set paradigm
	local self = HookBase.new(MockTestingConfig, DefaultConfig)
	setmetatable(self, Service)

	--

	local States = {} -- Table of states (helps isolate the server's functions from its accumulators, properties etc.)

	States.IsRunning = false
	States.RemotesFolder = SetupFRS(self) -- (Sets up Folders, Remotes & Signals)
	States.allPhysBalls = {}

	---

	self.Connections = {}
	self.Signals = {} -- Server-Server

	-- for npc's we would need a whole service to init & construct everything, but idc rn
	local function onCharacterAdded(Chr)
		local plr = Players:GetPlayerFromCharacter(Chr)
		local pb = getPhysBall(self, plr)

		States.allPhysBalls[plr] = pb
	end

	local function OnPlayerAdded(Player: Player)
		if Player.Character then
			onCharacterAdded(Player.Character)
		end

		Player.CharacterAdded:Connect(onCharacterAdded)
	end

	local function safePlayerAdded(callback: (Player) -> ())
		for _, player in Players:GetPlayers() do
			task.spawn(callback, player)
		end

		return Players.PlayerAdded:Once(callback)
	end

	--

	self["States"] = States
	self["Settings"] = self._config.Settings

	setupPhysBall(self)
	safePlayerAdded(OnPlayerAdded)

	self["__shared"] = { -- custom things you want the client to access (consts)
		["ClientAdapters"] = {},
		["Settings"] = self._config.Settings,
	}

	return self
end

function Service:Run()
	self["States"].IsRunning = true
end

function Service:OnClose() end

---

-- only used by the server
function Service:getPhysBallClass(
	root: BasePart | Model,
	getInput: () -> Vector3,
	description: {
		["Shape"]: Enum.PartType?,
		["CustomPhysicalProperties"]: PhysicalProperties?,
		["Size"]: Vector3?,
	}
)
	local initPhysBall = require(game:GetService("ReplicatedFirst")._Shared.Utility.InitPhysBall)

	local pb = self["States"].__TemplatePhysBall:Clone()
	return initPhysBall.new(root, getInput, pb)
end

return Service
