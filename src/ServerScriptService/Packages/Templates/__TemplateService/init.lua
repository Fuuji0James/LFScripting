local HookBase = require(game:GetService("ReplicatedStorage").Module_Bases._HookBase)

local SetupServiceComms = require(script:FindFirstAncestor("Services").Helpers.SetupServiceComms)

local Service = {
	["Name"] = script.Name,
	['TestingFlag'] = false
}

Service.__index = Service
setmetatable(Service, HookBase)

local DefaultConfig = require(script.DefaultConfig)

-- Privates


function SetupFRS(States)
	--[[ Eg. Usage
	local Folder = Instance.new("Folder", game:GetService("ReplicatedStorage").Comms)
	Folder.Name = `{script.Name}`
	
	SetupServiceComms.SetupRemotes(nil, {
		[`ReSyncRemote`] = { `RemoteEvent`, nil },
		[`RequestInfoFromServer`] = { `RemoteFunction`, OnInvokeFromClient },
	}, Folder)
	
	return Folder
	]]
end

---

--- LifeCycle stuff

function Service.new(MockTestingConfig) -- Really just an initialize function, but i call it this since its a set paradigm
	local self = HookBase.new(MockTestingConfig, DefaultConfig)
	setmetatable(self, Service)

	--

	local States = {} -- Table of states (helps isolate the server's functions from its accumulators, properties etc.) // You can then easily send a snapshot to the client

	States.CurrentTick = 1
	States.ServerStartTime = nil
	States.TimeSinceLastTick = 0
	States._TimeAccumulated = 0
	States.TimesReset = 0

	States.PendResyncs = false
	States.RemotesFolder = SetupFRS(States) -- (Sets up Folders, Remotes & Signals)

	---

	self.Connections = {}
	self.Signals = {} -- Server-Server

	self["States"] = States
	self["Settings"] = self._config.Settings

	local formattedAdapters = {}

	for name, val in self._adapters do
		--[[Eg. Usage
		if name == "TimeProvider" then
			formattedAdapters[name] = "os.clock"
		end
		]]
	end

	self["__shared"] = { -- custom things you want the client to access (consts)
		["ClientAdapters"] = formattedAdapters,
		["Settings"] = self._config.Settings,
	}

	return self
end

function Service:Run()
	self["States"].IsRunning = true
end

--***Cleanup whatever you made, so that the server has less load on shutdown/close
function Service:OnClose()
	
end

---

---> Actual Service Stuff

return Service
