local module = {
	['TestingFlag'] = false
}

local DefaultConfig = require(script.Parent.DefaultConfig)

function module:SetupTestConfig()
	-- hook stuff is setup here
	
	--[[
	DefaultConfig.Settings.TickDelta = 1/1.5
	DefaultConfig['Observers'].TickChanged = function(serviceClass, currentTick)
		print(`ElapsedTime is {DefaultConfig['Adapters'].TimeProvider() - serviceClass.States.ServerStartTime}`) 
	end
	
	--You can also have multiple observers in one function

	return DefaultConfig
	]]
end

function module:StartTest(parentService : ModuleScript)
	-- hook stuff can only be called here
end

return module