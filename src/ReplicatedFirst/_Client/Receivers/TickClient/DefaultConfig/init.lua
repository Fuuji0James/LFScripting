-- Use this to fall back on
local KnownAdapters = require(script.KnownAdapters)
local LoggedData = {}

return {
	['Settings'] = {}, -- Sent from server 
	['Adapters'] = { -- change underlying code & would produce a different effect
		['KnownAdapters'] = KnownAdapters,

		['PingProvider'] = function()
			return game.Players.LocalPlayer:GetNetworkPing()
		end,
	},
	['Observers'] = { -- doesn't affect operation of code, and simply visualizes/logs whatever
		['Logger'] = function(data) 
			table.insert(LoggedData, data)
			print(data) 
		end,
		['ResyncPackageReceived'] = function()

		end,
		['StartedCounting'] = function()

		end,
		['JoinPackageReceived'] = function()

		end,
		['ExpectedTickChanged'] = function(parentReceiver, currentTick)
			
		end,
	}
}