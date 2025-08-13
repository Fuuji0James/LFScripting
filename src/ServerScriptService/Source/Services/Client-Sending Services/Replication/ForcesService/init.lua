local HookBase = require(game:GetService("ReplicatedStorage").Module_Bases._HookBase)
local HelperFns = require(game:GetService("ReplicatedFirst")._Shared.Utility.ForcesUtil)
local DefaultPathFuncs = require(script.DefaultPathFuncs)
local pathUtil = require(game:GetService("ReplicatedFirst")._Shared.Utility.BezierUtils)
local Types = require(game:GetService("ReplicatedFirst")._Shared.Types)

local SetupServiceComms = require(script:FindFirstAncestor("Services").Helpers.SetupServiceComms)

local Service = {
	["Name"] = script.Name,
	["TestingFlag"] = false,
}
Service.__index = Service
setmetatable(Service, HookBase)

local DefaultConfig = require(script.DefaultConfig)

-- Privates
local function giveClientInfo(self)
	return { self["States"], self["Settings"] }
end

local function SetupFRS(self)
	local Folder = Instance.new("Folder", game:GetService("ReplicatedStorage").Comms)
	Folder.Name = `{script.Name}`

	SetupServiceComms.SetupRemotes(nil, {
		["ApplyForceTo"] = { `RemoteEvent`, nil },
		["ForceAppliedForPlayer"] = { `RemoteEvent`, nil },

		-- pitch into the tickservice's thing
		[`ReSyncRemote`] = { `RemoteEvent`, nil },
		[`RequestInfoFromServer`] = {
			`RemoteFunction`,
			function()
				return giveClientInfo(self)
			end,
		},
	}, Folder)

	-- make a debris folder too

	return Folder
end

---

--- LifeCycle stuff

function Service.new(MockTestingConfig) -- Really just an initialize function, but i call it this since its a set paradigm
	local self = HookBase.new(MockTestingConfig, DefaultConfig)
	setmetatable(self, Service)

	--

	local States = {} -- Table of states (helps isolate the server's functions from its accumulators, properties etc.)

	States._registry = {}
	States.IsRunning = false
	States.RemotesFolder = SetupFRS(self) -- (Sets up Folders, Remotes & Signals)
	States.forceCount = 0

	---

	self.Connections = {}
	self.Signals = {} -- Server-Server
	self.DefaultPathFuncs = DefaultPathFuncs

	self["States"] = States
	self["Settings"] = self._config.Settings

	local formattedAdapters = {}

	self["__shared"] = { -- custom things you want the client to access (consts)
		["ClientAdapters"] = formattedAdapters,
		["Settings"] = self._config.Settings,
	}

	return self
end

function Service:Run()
	self["States"].IsRunning = true

	local FAPFP: RemoteEvent = self["States"].RemotesFolder.ForceAppliedForPlayer

	FAPFP.OnServerEvent:Connect(function(player, ForceRequirements: Types.ForceRequirements)
		-- ensure the model is in the correct place after X amount of time (i.e resync everyone)
		local function resyncPlayer()
			-- if the player ever gets away from where they should be, in the next tick resync, send the stuff
		end

		self:applyRaycastForceTo_Player(ForceRequirements, resyncPlayer)
	end)
end

function Service:OnClose() end

---

---> Actual Service Stuff

-- used by server only
function Service:applyRaycastForceTo_Server(ForceRequirements: Types.ForceRequirements) end

function Service:applyRaycastForceTo_Player(ForceRequirements: Types.ForceRequirements, resyncPlayer: () -> any?)
	local att = Instance.new("Attachment", workspace.Terrain)
	local part = Instance.new("Part", workspace)
	part.CanCollide = false
	part.Name = "Server_ball " .. ForceRequirements.forceName
	part.Shape = Enum.PartType.Ball
	part.Color = Color3.fromRGB(103, 255, 131)

	local partAtt = Instance.new("Attachment", part)

	local alignPos, alignOri = self:_emitHook("getAlignments", part, partAtt, att) -- destroy them later

	function ForceRequirements.onUpdate(dt: number, oldPos: Vector3, newPos: Vector3, vel: Vector3)
		local forward = vel.Magnitude > 0.001 and vel.Unit or att.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -1))
		att.CFrame = CFrame.lookAt(newPos, newPos + forward)
	end

	return HelperFns.applyRaycastForceTo(self, ForceRequirements, _, true)
end

function Service:StopForce(force: Types.Force)
	local obj, forceName = force.obj, force.forceName

	force.promise:cancel()
end

return Service
