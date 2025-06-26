local LoggedData = {}

return {
	['Settings'] = {
		['TickDelta'] = 1/10,
		['ResetAtTick'] = math.floor(3600/(1/10)),
		-- ['ResyncTimeout'] = 
	}, 
	['Adapters'] = { -- change underlying code & would produce a different effect
		['TimeProvider'] = os.clock,
	},
	['Observers'] = { -- doesn't affect operation of code, and simply visualizes/logs whatever
		['Logger'] = function(data) 
			table.insert(LoggedData, data)
			print(data) 
		end,
		['ResyncSent'] = function()

		end,
		['PlayerConnectedToService'] = function()
			
		end,
		['PendingResyncs'] = function()

		end,
		['PendingResyncsAgain'] = function()

		end,
		['NoLongerPendingResyncs'] = function()

		end,
		['TickChanged'] = function(self, CurrentTick)
			
		end,
	}
}