local SSS = game:GetService("ServerScriptService")

local DefaultCombatValues =
	SSS.Source.Services["Client-Relaying Services"].Components.ComponentModules.R6_CombatComponent.Component_Combat_R6_DataValues

return function(IsClient)
	if IsClient:IsA("Player") then
		--local plr = IsClient.Player
		-- Get the values from datastore...
		-- But for now we just return the default values
		return require(DefaultCombatValues)
	else
		-- Return default values for all npcs // Might change later
		return require(DefaultCombatValues)
	end
end
