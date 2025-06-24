local module = {}

local DefaultConfig = require(script.Parent.DefaultConfig)

function module:SetupTestConfig()
	-- hook stuff is setup here
	
	DefaultConfig.Settings.TickDelta = 1/30
	DefaultConfig.Settings.ResetAtTick = 30
	DefaultConfig['Observers'].TickChanged = function(_, currentTick)
		-- print(`CurrentTick is {currentTick}`) 
	end
	
	return DefaultConfig
end

function module:StartTest(parentService : ModuleScript)
	-- hook stuff can only be called here
end

return module