local provider = {}
local defaultPing = 50 / 1000 -- 50ms

function provider:Spike(basePing)
	return (basePing + Random.new():NextNumber(0, 1))
end

function provider:Stablize()
	return defaultPing
end

return provider