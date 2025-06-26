local ComponentHandler = require(game:GetService('ServerScriptService').Packages.ComponentHandler)

local InitHookedServices = require(game:GetService("ReplicatedFirst")._Shared.Utility.InitSR)

return function(Source, LiveMockTestsAllowed)
	local ClientRelaying = Source.Services["Client-Relaying Services"]
	local ClientSending = Source.Services["Client-Sending Services"]
	
	-- Client Relaying servies
	local ComponentsToLoad = ClientRelaying.Components.ComponentModules:GetChildren()
	
	for _, moduleScript in ComponentsToLoad do
		local reqMS = require(moduleScript)
		if reqMS.Init then reqMS:Init() end
	end
	
	ComponentHandler.AddComponentToGame(ComponentsToLoad)
	
	InitHookedServices(ClientRelaying.Misc, LiveMockTestsAllowed)
	
	-- Client sending services
	InitHookedServices(ClientSending, LiveMockTestsAllowed)
end