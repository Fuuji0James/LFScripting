local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local CS = game:GetService("CollectionService")

local _ClientFolder = RF._Client
local _SharedFolder = RF._Shared

local Libraries = RS.Libraries

local ClientControllersFolder = _ClientFolder.Controllers

local FindValueInTable = require(Libraries.FindValueInTable)
local TagList = require(_SharedFolder.TagList)
local TimeNow = require(game:GetService("ReplicatedStorage").Libraries["Debugging Tools"].Helpers.CurrentTime)

local ProxyHandler	   = require(_SharedFolder:WaitForChild("Utility"):WaitForChild("proxytable"))
local _registry 	   = require(_SharedFolder:WaitForChild("_registry"))

local CachedControllerModules = {} -- Exists for ones they've used before, and may use again
local RunningControllers = {}

local function addToCachedControllerModules(ComponentName: string): ModuleScript
	local RequiredControllerModule = CachedControllerModules[ComponentName]
		or require(ClientControllersFolder[`Client_{ComponentName}`])

	if not CachedControllerModules[ComponentName] then
		CachedControllerModules[ComponentName] = RequiredControllerModule
	end
	
	return RequiredControllerModule
end

local function instanceAddedToComponent(Component: string)
	local ComponentName: string = FindValueInTable(TagList.Components, Component, true)
	if RunningControllers[ComponentName] then
		return
	end
	addToCachedControllerModules(ComponentName)

	local Controller

	local _, E = pcall(function()
		Controller = ProxyHandler.new(ComponentName, CachedControllerModules[ComponentName].new()) -- Prone to hacks?
	end)
	
	_registry[ComponentName] = Controller

	if E then
		warn(E)
	end

	RunningControllers[ComponentName] = Controller
end

local function instanceRemovedFromComponent(Component: string)
	local ComponentName: string = FindValueInTable(TagList.Components, Component, true)
	if not RunningControllers[ComponentName] then
		return
	end

	if CachedControllerModules[ComponentName] then
		if not RunningControllers[ComponentName].Destroy then
			print(`Destroy is not a valid member of controller: {RunningControllers[ComponentName].Name}`)
		else
			RunningControllers[ComponentName]:Destroy()
		end
	end

	RunningControllers[ComponentName] = nil
end

return function (Character: Model)
	
	-- Upon Starting
	for _, Component in Character:GetTags() do
		if FindValueInTable(Character:GetTags(), Component) then
			-- check if we have a controller for it
			local ComponentName: string = FindValueInTable(TagList.Components, Component, true)

			if ClientControllersFolder:FindFirstChild(`Client_{ComponentName}`) then
				addToCachedControllerModules(ComponentName)

				local Controller

				local _, E = pcall(function()
					Controller = ProxyHandler.new(ComponentName, CachedControllerModules[ComponentName].new()) -- Prone to hacks?
				end)
				
				_registry[ComponentName] = Controller

				if E then
					warn(E)
				end

				RunningControllers[ComponentName] = Controller
			end
		end
	end

	local function AddTags(Components)
		for _, Component in Components do
			if typeof(Component) == "table" then
				AddTags(Component)
				break
			end

			CS:GetInstanceAddedSignal(Component):Connect(function()
				instanceAddedToComponent(Component)
			end)
			CS:GetInstanceRemovedSignal(Component):Connect(function()
				instanceRemovedFromComponent(Component)
			end)
		end
	end

	-- Added during runtime
	AddTags(TagList.Components)

	print(`Controller Modules Cached:`, CachedControllerModules)
	print(`Running Controllers Loaded at {TimeNow()}:`, RunningControllers)
end

