-- Explorer stuff
local RS = game:GetService('ReplicatedStorage')
local Comms = RS.Comms:WaitForChild("TickService")

---
local JOINED, RESYNC = 0, 1

--- Dependencies/Frameworks
local _HookBase = require(game:GetService('ReplicatedStorage').Module_Bases._HookBase)
local DefaultConfig = require(script.DefaultConfig)
---

--Privates
function IncludeInjectionsFromServer(self, __shared, __settings)
	-- keeping this the same is usually fine
	
	for name, fn_name in __shared['ClientAdapters'] do
		self:_attachHook('adapter', name, DefaultConfig.Adapters.KnownAdapters[name][fn_name])
	end
	
	-- We add in its settings with what the we have
	for name, value in __settings do
		if self.Settings[name] then continue end
		
		self.Settings[name] = value
	end
end
---

local Receiver = {}
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
	States.ClientStartTime		= -1
	States.ClientElapsedTime	= -1
	States.ServerTimeOffset		= -1
	States.LastResyncTime		= -1	-- keeping track of if you want to be resynced
	
	States.IsRunning 			= false
	
	---
	---	
	
	self.Connections = {}
	self.OnEvents	 = {}
	
	self['States']	 = States
	self['Settings'] = self._config.Settings

	return self
end

function Receiver:Run()
	local RequestServerInfo = Comms:WaitForChild("RequestInfoFromServer")
	local Resync = Comms:WaitForChild("ReSyncRemote")
	
	--Getting the current server state and parsing it
	local Package: {} = RequestServerInfo:InvokeServer(JOINED)
	
	IncludeInjectionsFromServer(self, Package[3], Package[2])	
	self['States'].LastReceivedServerState = Package[1]
	self['States'].LastResyncTime = self:_emitHook("TimeProvider") 
	
	---
	
	-- Ensuring personal states are made
	
	local TimeUntilNextTick = self['Settings'].TickDelta - (self['States'].LastReceivedServerState.TimeSinceLastTick + (self:_emitHook("PingProvider")))
	
	if TimeUntilNextTick == 0 then -- it basically already passed on the server, so wait until the next one
		TimeUntilNextTick = self['Settings'].TickDelta
	elseif TimeUntilNextTick < 0 then
		TimeUntilNextTick += self['Settings'].TickDelta
	end
	
	task.delay(TimeUntilNextTick, function()
		--game:GetService('RunService').Heartbeat:Wait()		
		local clientNow = self:_emitHook("TimeProvider")
		self['States'].ClientStartTime = clientNow

		local serverStart = self['States'].LastReceivedServerState.ServerElapsedTime + TimeUntilNextTick

		-- ServerTimeOffset is how much ahead the server is compared to this client
		self['States'].ServerTimeOffset = serverStart - clientNow
		self['States'].IsRunning = true
	end)
	
	local a = 0
	
	
	self.Connections['UpdateOnExpectedTickChange'] = game:GetService('RunService').Heartbeat:Connect(function(dt)
		if a >= self.Settings.TickDelta then
			a = 0
			self:_emitHook("ExpectedTickChanged", self, self:GetServerTick())
		else
			a += dt
		end
	end)
end

function Receiver.OnClose()
	print("Stopped Listening") -- then destroy connections etc.
end

function Receiver:GetClientElapsedTime()
	if not self['States'].IsRunning then return end
	return self:_emitHook("TimeProvider") - self['States'].ClientStartTime
end

function Receiver:GetServerElapsedTime()
	if not self['States'].IsRunning then return end
	return self:_emitHook("TimeProvider") + self['States'].ServerTimeOffset
end

function Receiver:GetClientTick()
	if not self['States'].IsRunning then return end
	return math.floor(self:GetClientElapsedTime()/self['Settings'].TickDelta)
end

function Receiver:GetServerTick()
	if not self['States'].IsRunning then return end
	return math.floor(self:GetServerElapsedTime()/self['Settings'].TickDelta)
end

return Receiver
