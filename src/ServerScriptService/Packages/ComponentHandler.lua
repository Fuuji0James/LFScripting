-- {Most Recent: 13/5/2025} //FUUJI
-- Status: Proto
--///This is bad because it does not have realm access to the instances with components, so if another script requires it and calls the util funcs
-- 		It won't know what it's talking about. Using _G would be better

local CS = game:GetService("CollectionService")

local ComponentHandler = {}
local InstancesWithComponents = {}
local ModuleScriptsLoadedInGame = {}

local function loadComponents(Inputs)
	for _, ModuleScript in Inputs do
		if typeof(ModuleScript) ~= "Instance" then
			continue
		end
		---

		if ModuleScript:IsA("Folder") then
			loadComponents(ModuleScript:GetChildren())
		end
		if not ModuleScript:IsA("ModuleScript") then
			continue
		end

		local ModuleScriptComponent

		local _, E = pcall(function()
			ModuleScriptComponent = require(ModuleScript) -- component itself
		end)

		if E then
			warn(E)
		end

		if not ModuleScriptComponent.Tag then
			warn(`Tag doesn't exist for {ModuleScript}`)
			continue
		end

		---

		local Tag = ModuleScriptComponent.Tag

		ModuleScriptsLoadedInGame[Tag] = ModuleScriptComponent

		local function instanceRemovedFromTagList(instance)
			-- removing it from the list of instances with a component
			for Tag, Component in InstancesWithComponents[instance] do
				if Component.Destroy then
					Component:Destroy() -- Calls the cleanup method
				end

				local CachedComponent = InstancesWithComponents[instance][Tag]

				CachedComponent = nil
			end
		end

		local function instanceAddedToTagList(instance: Instance)
			-- adding it to the list of instances with a component
			InstancesWithComponents[instance] = InstancesWithComponents[instance] or {} -- ?
			local ComponentForInstance

			--local _, E = pcall(function()
			ComponentForInstance = ModuleScriptComponent.new(instance) -- new component for the instance
			--end)

			--if E then warn(E) end

			print(`Adding {instance.Name} to {Tag} with component {ComponentForInstance}`)

			InstancesWithComponents[instance][Tag] = ComponentForInstance -- adding the component functions to the instance
		end

		for _, instance in CS:GetTagged(Tag) do
			instanceAddedToTagList(instance)
		end
		CS:GetInstanceAddedSignal(Tag):Connect(instanceAddedToTagList)
		CS:GetInstanceRemovedSignal(Tag):Connect(instanceRemovedFromTagList)
	end
end

---

ComponentHandler.AddComponentToGame = function(Input: any)
	if typeof(Input) == "table" then
		-- add keys
		loadComponents(Input)
	elseif typeof(Input) == "Instance" then
		-- add children
		loadComponents(Input:GetChildren())
	end
end

ComponentHandler.GetComponentFromGame = function(Tag: string)
	if not Tag then
		warn("No component name provided")
		return
	end

	return ModuleScriptsLoadedInGame[Tag]
end

ComponentHandler.GetComponentsFromInstance = function(instance: Instance, Tag: string)
	if Tag then
		if not InstancesWithComponents[instance] then
			return
		end

		return InstancesWithComponents[instance][Tag]
	else
		if not InstancesWithComponents[instance] then
			return
		end
		return InstancesWithComponents[instance]
	end
end

return ComponentHandler
