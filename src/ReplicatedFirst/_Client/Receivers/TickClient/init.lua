-- Explorer stuff
local RS = game:GetService("ReplicatedStorage")
local Comms = RS.Comms:WaitForChild("TickService")
local TimerUtil = require(RS.Libraries.Timer)

---
local JOINED, RESYNC = 0, 1

--- Dependencies/Frameworks
local _HookBase = require(game:GetService("ReplicatedStorage").Module_Bases._HookBase)
local DefaultConfig = require(script.DefaultConfig)
---

--Privates
function IncludeInjectionsFromServer(self, __shared, __settings)
	-- keeping this the same is usually fine

	for name, fn_name in __shared["ClientAdapters"] do
		self:_attachHook("adapter", name, DefaultConfig.Adapters.KnownAdapters[name][fn_name])
	end

	-- We add in its settings with what the we have
	for name, value in __settings do
		if self.Settings[name] then
			continue
		end

		self.Settings[name] = value
	end
end

function SyncToServer(self, Package: {}, SyncType: number)
	local TickDelta = self["Settings"].TickDelta

	-- Create new timer
	if self.Connections["UpdateOnExpectedTickChange"] then
		self.Connections["UpdateOnExpectedTickChange"]:Stop()
	end

	local clientTimer = TimerUtil.new(TickDelta)
	clientTimer.AllowDrift = false

	clientTimer.TimeFunction = self._adapters["TimeProvider"]
	clientTimer.UpdateSignal = game:GetService("RunService").Heartbeat

	clientTimer.Tick:Connect(function()
		self:_emitHook("ExpectedTickChanged", self, self:GetServerTick())
	end)

	self.Connections["UpdateOnExpectedTickChange"] = clientTimer

	-- Ensuring personal states are made
	self["States"].LastReceivedServerState = Package[1]
	self["States"].LastResyncTime = self:_emitHook("TimeProvider")

	local accumulatedTime = (
		self["States"].LastReceivedServerState.TimeSinceLastTick + (self:_emitHook("PingProvider"))
	)
	local TimeUntilNextTick = TickDelta - (accumulatedTime % TickDelta)

	task.delay(TimeUntilNextTick, function()
		local clientNow = self:_emitHook("TimeProvider")
		local serverNow = self["States"].LastReceivedServerState.ServerElapsedTime + TimeUntilNextTick

		-- ServerTimeOffset is how much ahead the server is compared to this client
		self["States"].ServerTimeOffset = serverNow - clientNow

		if SyncType == JOINED then
			self["States"].ClientStartTime = clientNow
			self["States"].IsRunning = true
		end

		clientTimer:Start()
	end)
end

---

local Receiver = {
	["TestingFlag"] = true,
}

Receiver.__index = Receiver
setmetatable(Receiver, _HookBase)

function Receiver.new(MockTestingConfig) -- Client sided mock tests too obv // Config doesn't have to be redundant if the server sends over __shared stuff
	local self = _HookBase.new(MockTestingConfig, DefaultConfig)
	setmetatable(self, Receiver)

	-- Client only stuff:
	local States = {}

	--Ping, CurrentTick, CurrentTime could be an adapter

	-- Things received from server
	States.LastReceivedServerState = nil -- really a table with the last state update

	-- Personal states (derived from server package or otherwise)
	States.ClientStartTime = -1
	States.ClientElapsedTime = -1
	States.ServerTimeOffset = -1
	States.LastResyncTime = -1 -- keeping track of if you want to be resynced
	States.AwaitingResync = false

	States.IsRunning = false

	---
	---

	self.Connections = {}
	self.OnEvents = {}

	self["States"] = States
	self["Settings"] = self._config.Settings

	return self
end

function Receiver:Run()
	local RequestServerInfo = Comms:WaitForChild("RequestInfoFromServer")
	local Resync: RemoteEvent = Comms:WaitForChild("ReSyncRemote") -- server may have lagged, so it'll send a proper resync right away

	--Getting the current server state and parsing it on join
	local Package = RequestServerInfo:InvokeServer(JOINED)
	IncludeInjectionsFromServer(self, Package[3], Package[2])

	SyncToServer(self, Package, JOINED)

	--For future resyncs
	local ResyncTimeout = (3 * self["Settings"].TickDelta)
	
	task.delay(ResyncTimeout, function()
		self.Connections["ResyncConnection"] = TimerUtil.Simple(ResyncTimeout, function()
			if
				((self:_emitHook("TimeProvider") - self["States"].LastResyncTime) >= ResyncTimeout)
				and (self["States"].AwaitingResync == false)
			then
				local Package = RequestServerInfo:InvokeServer(RESYNC)
				SyncToServer(self, Package, RESYNC)
				self:_emitHook("ResyncPackageReceived", self)
			end
		end, false, game:GetService("RunService").Heartbeat, os.clock)
	end)

	Resync.OnClientEvent:Connect(function(Package)
		self:_emitHook("ResyncPackageReceived", self)
		SyncToServer(self, Package, RESYNC)
	end)
end

function Receiver.OnClose()
	print("Stopped Listening") -- then destroy connections etc.
end

---

function Receiver:GetClientElapsedTime()
	if not self["States"].IsRunning then
		return
	end
	return self:_emitHook("TimeProvider") - self["States"].ClientStartTime
end

function Receiver:GetServerElapsedTime()
	if not self["States"].IsRunning then
		return
	end
	local tR = self["States"].LastReceivedServerState.TimesReset
	local settings = self.Settings

	return (self:_emitHook("TimeProvider") + self["States"].ServerTimeOffset)
		- (tR * (settings.TickDelta * settings.ResetAtTick))
end

function Receiver:GetClientTick()
	if not self["States"].IsRunning then
		return
	end
	return math.floor(self:GetClientElapsedTime() / self["Settings"].TickDelta)
end

function Receiver:GetServerTick()
	if not self["States"].IsRunning then
		return
	end
	return math.floor(self:GetServerElapsedTime() / self["Settings"].TickDelta)
end

return Receiver
