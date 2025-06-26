local Proxy = {}

Proxy.__newindex = function(self, key, value)
	self.RealData[key] = value -- without this the key would need be set to the new value
end

Proxy.__iter = function(self)
	return next, self.RealData -- similar to pairs(table)
end

Proxy.__index = function(self, key)
	return self.RealData[key]
end

function Proxy.new(indexName, DataTable)
	return setmetatable({ RealData = DataTable or {} }, Proxy)
end

return Proxy
