local CommsFolder = game.ReplicatedStorage:WaitForChild('Comms')
local HookBase = require(game:GetService('ReplicatedStorage').Module_Bases._HookBase)

local Signal = require(game.ReplicatedStorage.Libraries.FastSignal)

local SetupRemotes = require(script:FindFirstAncestor("Services").Helpers.SetupServiceComms.SetupRemotes)

local Service = {
	['Name'] = script.Name
}
Service.__index = Service
setmetatable(Service, HookBase)

local DefaultConfig = require(script.DefaultConfig)

-- Privates
function SetupVis()
	-- Setup visualizers & listen to signal 'OnTickChange'
end

function CheckIfResyncIsAllowed(self, isCheckingResync, accumulated)
	if isCheckingResync then return end -- so multiple resyncs don't run at a time

	isCheckingResync = true

	task.delay(.05, function()
		isCheckingResync = false

		accumulated += .05
		if self.Settings.TickDelta < (self['States']._TimeAccumulated - (self.Settings.TickDelta*(.85 + accumulated))) then
			self['States'].PendResyncs = false
			self:_emitHook('NoLongerPendingResyncs')
		else
			CheckIfResyncIsAllowed(self, isCheckingResync, accumulated)
			self:_emitHook('PendingResyncsAgain')
		end
	end)
end

function UpdateTimeSinceLastTick(self)
	self['States'].TimeSinceLastTick = 0

	if self.Connections['TimeSinceLastTick'] then self.Connections['TimeSinceLastTick']:Disconnect() end

	self.Connections['TimeSinceLastTick'] = game:GetService('RunService').Heartbeat:Connect(function(dt)
		self['States'].TimeSinceLastTick += dt
	end)
end

function UpdateServerTick(self, IsCheckingResync, dt)
	self['States']._TimeAccumulated += dt

	while (self['States']._TimeAccumulated >= self.Settings.TickDelta) do -- if its larger than the tD, it would run again
		if (self['States'].CurrentTick >= self.Settings.ResetAtTick) then self['States'].CurrentTick = 0 end

		self['States'].CurrentTick += 1
		self['States']._TimeAccumulated -= self.Settings.TickDelta -- this lowers it down so it would only run depending on the NEXT iteration
			
		-- check if we should allow resyncs, since we want the time since tick was updated variable to be as accurate as possible, even when the server spikes with lag and has to catch up to give a new tick update
		if (self.Settings.TickDelta < self['States']._TimeAccumulated - (self.Settings.TickDelta*.85)) then
			-- allow resyncs to only be sent here
			self['States'].PendResyncs = false			
			self:_emitHook('NoLongerPendingResyncs')
			
			--Remote:Fire(player, )
		else
			self['States'].PendResyncs = true
			self:_emitHook('PendingResyncs')			
			CheckIfResyncIsAllowed(self, IsCheckingResync, 0)
		end

		--if self.Settings['Debugging'] then
		--	print(`{script.Name} Tick: {self.CurrentTick}, Current.Δ: {self.Settings.TickDelta}, TimeSinceLastTick: {self.TimeSinceLastTick}`)
		--end
		UpdateTimeSinceLastTick(self)
		self:_emitHook('TickChanged', self, self['States'].CurrentTick) 
	end
end

function OnInvokeFromClient(self, player, context)
	local JOINED, RESYNC = 0, 1
	local ServerElapsedTime = self:GetElapsedTime()
	local package: {} = {}
	
	local function createFormalState()-- more like snapshot
		local stateSnapShot = {}
		
		local includeInSnapshot = { 
			['ServerElapsedTime'] = self:GetElapsedTime(),
		}

		for name, val in includeInSnapshot do
			stateSnapShot[name] = val
		end

		for name, val in self['States'] do
			stateSnapShot[name] = val
		end
		
		return stateSnapShot
	end
	
	if context == JOINED then
		local stateSnapShot = createFormalState() -- because i need things that may take an impossible amount of mem to do otherwise	
		
		package = {stateSnapShot, self['Settings'], self['__shared'], self:GetElapsedTime()}
		
		self:_emitHook("PlayerConnectedToService")
	elseif context == RESYNC then
		if self['States'].PendResyncs then
			-- wait until you can send resyncs again
			--Hook:wait()
		end
		
		self:_emitHook("ResyncSent", player)
		
		package = {self['States']}
	end	
	
	return package	
end

function SetupFRS(States)

	local Folder = Instance.new("Folder", game:GetService('ReplicatedStorage').Comms)
	Folder.Name = `{script.Name}`

	SetupRemotes(nil, {
		[`ReSyncRemote`] = { `RemoteEvent`, nil },
		[`RequestInfoFromServer`] = { `RemoteFunction`, OnInvokeFromClient },
	}, Folder)
	
	return Folder
end

---

--- LifeCycle stuff

function Service.new(MockTestingConfig) -- Really just an initialize function, but i call it this since its a set paradigm
	
	local self = HookBase.new(MockTestingConfig, DefaultConfig)
	setmetatable(self, Service)
		
	--
	
	local States = {} -- Table of states (helps isolate the server's functions from its accumulators, properties etc.)
	
	States.CurrentTick		 = 1
	States.ServerStartTime	 = nil
	States.TimeSinceLastTick = 0
	States._TimeAccumulated	 = 0
	States.TimesReset 		 = 0
	
	States.PendResyncs   = false 
	States.RemotesFolder = SetupFRS(States) -- (Sets up Folders, Remotes & Signals)
	
	---
	
	self.Connections = {}
	self.Signals 	 = {} -- Server-Server 
	
	self['States']		= States
	self['Settings']	= self._config.Settings
	
	local formattedAdapters  = {}
	
	for name, val in self._adapters do
		if name == 'TimeProvider' then
			formattedAdapters[name] = 'os.clock'
		end
	end
	
	self['__shared']	= { -- custom things you want the client to access (consts)
		['ClientAdapters']	= formattedAdapters,
		['Settings'] 		= self._config.Settings
	}
	
	return self
end

function Service:Run() ---***Have to add in the visualizers stuff too
	--game:GetService('RunService').Heartbeat:Wait()
	local StartTime = self:_emitHook("TimeProvider")
	
	local IsCheckingResync = false
	
	self['States'].IsRunning = true
	self['States'].ServerStartTime = StartTime	
	self['States'].RemotesFolder['RequestInfoFromServer'].OnServerInvoke = function(player, context)
		return OnInvokeFromClient(self, player, context)
	end
	
	self.Connections['TimeSinceLastTick'] = nil --//SHOULD NOT BE AN ADAPTER
	
	self.Connections['ServerTickUpdater'] = game:GetService('RunService').Heartbeat:Connect(function(dt) 
		UpdateServerTick(self, IsCheckingResync, dt)
	end)
end

function Service:OnClose()
	self.Connections['ServerTickUpdater']:Disconnect()
end

---

---> Actual Service Stuff //Has to be finished//

function Service:GetCurrentTick()
	if not self['States'].IsRunning then return end
	return self.CurrentTick
end

function Service:GetElapsedTime()
	if not self['States'].IsRunning then return end
	return (self:_emitHook("TimeProvider") - self['States'].ServerStartTime) 
end

--***Only used by mockTime for testing
function Service:ArtificialAdvance(ResetAccumulatedTime: boolean, Time: number, Ticks: number, callback: ()->any)
	-- The first argument is to allow a 'rewind', of time since we want as much variety is desyncs as possible
	-- Smoothen the client experience when a spike happens
	
	if Time and Ticks then print("Make one of these variables nil please") return end
	if ResetAccumulatedTime then self._TimeAccumulated = 0 end
	
	self._TimeAccumulated += Time
	
	if Ticks then
		self.CurrentTick += Ticks
		self.Signals['OnTickChance']:Fire(self.CurrentTick)
	end
	
	self.CurrentTick += (Ticks ~= nil) and Ticks or 0
	
	if callback then
		callback(Time, Ticks) -- Eg. (Middleware/mock tests may want to log the time/ticks that have passed, so im doing it like this, to differentiate between mocks & live)
	end
end

return Service
