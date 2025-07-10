return function(Remote: {}, To: {}, From: string, ...)
	if type(To) == "table" then
		for _, Client in To do
			Remote[From]:FireClient(Client, ...)
		end
	else
		warn(`{To} does not contain a player instance`)
	end
end
