-- This just lets you bridge things you may want the client & server to know, while keeping the client & server isolated
-- If you create a really niche adapter function you want copied here, name it well and stuff

return {
	['TimeProvider'] = {
		['os.clock']	= os.clock,
		['math.random'] = math.random,
		['tick'] 		= tick,
		['os.time'] 	= os.time,
	}
}