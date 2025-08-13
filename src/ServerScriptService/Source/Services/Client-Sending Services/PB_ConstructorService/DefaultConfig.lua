local LoggedData = {}

return {
	['Settings'] = {
		
	}, 
	['Adapters'] = { -- change underlying code & would produce a different effect
	
	},
	['Observers'] = { -- doesn't affect operation of code, and simply visualizes/logs whatever
		['Logger'] = function(data) 
			table.insert(LoggedData, data)
			print(data) 
		end,
	}
}