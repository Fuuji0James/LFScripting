local module = {
	['TestingFlag'] = false
}

local DefaultConfig = require(script.Parent.DefaultConfig)
local BadPingSim 	= require(script.BadPingSim)

function module:SetupTestConfig()
	-- hook stuff is setup here, if you want to use _emitHook, just use config.Adapters.[name]() instead 
	
	DefaultConfig['Observers'].ExpectedTickChanged = function(parentReceiverClass, currentTick)
		print(`ElapsedTime is {parentReceiverClass:GetServerElapsedTime() - parentReceiverClass['States'].LastReceivedServerState.ServerElapsedTime}`) 
	end
	DefaultConfig['Adapters'].PingProvider = function ()
		return game.Players.LocalPlayer:GetNetworkPing()
	end

	return DefaultConfig
end

function module:StartTest(parentReceiver : ModuleScript)
	-- hook stuff can only be called here
end

return module