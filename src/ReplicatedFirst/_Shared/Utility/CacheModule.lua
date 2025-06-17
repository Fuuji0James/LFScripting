-- {Most Recent: 16/5/2025} //FUUJI
-- Status: Prototype

local FastSignal = require(game:GetService(`ReplicatedStorage`).Libraries.FastSignal)
local CacheModule = {
	--[IndexCache] = {}
	[`OnAdded`] = FastSignal.new();
	[`OnRemove`] = FastSignal.new();
}

--*You can keep the ItemName nil if you want to get a cache.
local function getCachedItem(CacheIndexToCheck:string, ItemName:any):any
	if ItemName == nil then
		return CacheModule[CacheIndexToCheck]
	end
	
	return CacheModule[CacheIndexToCheck][ItemName]
end

--*You can keep the value nil if you want to just create a cache.
local function putInCache(CacheIndex:string, ItemName:string, Value:any)	
	if not CacheModule[CacheIndex] then
		CacheModule[CacheIndex] = {}	
	end 
	if not ItemName then return end
	
	if typeof(Value) == 'ModuleScript' then
		CacheModule[CacheIndex][ItemName] = require(Value)
	else
		CacheModule[CacheIndex][ItemName] = Value
	end
	
	if Value ~= nil and ItemName ~= nil then --If something is being assigned
		CacheModule.OnAdded:Fire(CacheIndex, ItemName, Value)
	else 
		CacheModule.OnRemove:Fire(CacheIndex, ItemName)
	end
end

--*If the Value variable is the Cache Index string, it'll remove the entire cache.
local function removeFromCache(CacheIndex:string, ItemName:any)
	if ItemName == CacheIndex then
		CacheModule[CacheIndex] = nil
		CacheModule.OnRemove:Fire(CacheIndex, ItemName)
		return
	end
	
	CacheModule[CacheIndex][ItemName] = nil
	CacheModule.OnRemove:Fire(CacheIndex, ItemName)
end

CacheModule.GetCachedItem = getCachedItem
CacheModule.PutInCache = putInCache
CacheModule.RemoveFromCache = removeFromCache

return CacheModule
