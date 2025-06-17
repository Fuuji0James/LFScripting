-- To help explain, this provides a base set of config options, both for hook points and service related constants
-- This doesn't hold states, the service itself creates its own states.
-- Really all you ever need to change is the default config option
-- Mock tests are ran automatically, and they'll change/run artificial scenarios so its easy to find problems later down the line
local Signal = require(game.ReplicatedStorage.Libraries.FastSignal)

local BaseService = {}
BaseService.__index = BaseService

--*** If args not sent, then use nothing instead
function BaseService.new(MockTestingConfig: {}, DefaultConfig: {}) 

	local Config = if (not MockTestingConfig) then DefaultConfig else MockTestingConfig

	for category, tab in DefaultConfig do
		if not Config[category] then Config[category] = {} end

		for name, value in tab do			
			if not (Config[category][name]) then
				Config[category][name] = value
			end
		end
	end

	local self = setmetatable({}, BaseService)

	self._config = Config

	self.__throttledHooks = {}

	self._adapters		= Config.Adapters  or {} -- plain funcs
	self._observers 	= Config.Observers or {} -- plain funcs

	self._convertedAdapters  = {} -- converted to signals
	self._convertedObservers = {} -- converted to signals

	for name, callback in self._adapters do
		if typeof(callback) == 'function' then
			self:_attachHook('adapter', name, callback)
		end
	end

	for name, callback in self._observers do
		if typeof(callback) == 'function' then
			self:_attachHook('observer', name, callback)
		end	
	end

	return self
end


--*** Lets you add in your own adapters, without care really 
function BaseService:_emitHook(name, ...)	
	local signals = {
		self._adapters[name],
		self._convertedObservers[name]
	}

	if #signals ~= 0 then
		if signals[1] then return signals[1](...) end
		if signals[2] and self['States'].IsRunning then signals[2]:Fire(...) end -- the self['States'].IsRunning part is lowk optional
	elseif not (self.__throttledHooks[name]) then 
		self.__throttledHooks[name] = true
	end
end


function BaseService:_waitOnEmit()

end

--*** Used by the testing script to customize the adapters/observers (if there are even any already) // You can wait on these hooks to be emitted btw
function BaseService:_attachHook(Type, name, callback)

	if Type == 'adapter' then
		self._adapters[name] = callback
		self._convertedAdapters[name] = callback

	elseif Type == 'observer' then
		local hook = Signal.new()

		self._observers[name] = callback
		self._convertedObservers[name] = hook
		hook:Connect(callback)
	end
end

function BaseService:_debug(fmt, ...)
	if self._log then
		self._log(string.format(fmt, ...))
	end
end

return BaseService