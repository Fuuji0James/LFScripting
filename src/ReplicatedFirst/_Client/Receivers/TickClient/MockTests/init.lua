local module = {}

local DefaultConfig = require(script.Parent.DefaultConfig)
local BubbleHeadVis = require(script["BubbleHead Vis"])
-- local BadPingSim = require(script.BadPingSim)

function module:SetupTestConfig()
	-- hook stuff is setup here, if you want to use _emitHook, just use config.Adapters.[name]() instead

	DefaultConfig["Observers"].ExpectedTickChanged = function(parentReceiverClass, currentTick)
		
	end

	DefaultConfig.Observers.ResyncPackageReceived = function(parentReceiverClass)
		-- print("ResyncPackageReceived")
		BubbleHeadVis.updateBubble(parentReceiverClass:GetServerTick(), parentReceiverClass.States.LastReceivedServerState.CurrentTick)
	end
	
	DefaultConfig["Adapters"].PingProvider = function()
		return game.Players.LocalPlayer:GetNetworkPing() + Random.new():NextNumber(0, .5)
	end

	return DefaultConfig
end

function module:StartTest(parentReceiver: ModuleScript)
	-- hook stuff can only be called here
end

return module
