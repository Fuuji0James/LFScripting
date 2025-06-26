local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local CS = game:GetService("CollectionService")
local Players = game:GetService("Players")

local _ClientFolder = RF._Client
local _SharedFolder = RF._Shared

local Libraries = RS.Libraries

local ClientControllersFolder = _ClientFolder.Controllers
local ClientReceiversFolder = _ClientFolder.Receivers

local FindValueInTable = require(Libraries.FindValueInTable)
local TagList = require(_SharedFolder.TagList)
local TimeNow = require(Libraries["Debugging Tools"].Helpers.CurrentTime)

local CachedControllerModules = {} -- Exists for ones they've used before, and may use again
local RunningControllers = {}

---
local LiveMockTestsAllowed = true -- as in PUBLIC GAME mock tests

-- Privates

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
		Controller = CachedControllerModules[ComponentName].new()
	end)

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

local function InitHookedReceiver(LiveMockTestsAllowed, Receiver)
	--coroutine.wrap(function()
	if Receiver:IsA("ModuleScript") and not (string.match(Receiver.Name, "^__Template")) then
		local Ms = require(Receiver)

		if typeof(Ms) == "table" then
			if Ms.new and Ms.Run and not Ms.Tag then -- has a life cycle, and doesn't have a tag for components
				local MockTestMs = if Receiver:FindFirstChild("MockTests")
					then require(Receiver:WaitForChild("MockTests"))
					else nil
				local MockTestingConfig: {} = nil
				local TestThisService = false

				if MockTestMs then
					if Ms.TestingFlag then
						if
							LiveMockTestsAllowed
							or (LiveMockTestsAllowed == false and game:GetService("RunService"):IsStudio())
						then
							TestThisService = true

							if MockTestMs.SetupTestConfig then
								MockTestingConfig = MockTestMs:SetupTestConfig()

								if not MockTestingConfig then
									print(
										`Mock tests should return their config? | Take off the testing flag to silence. @{Receiver}`
									)
								end
							end
						end
					end

					local ReceiverMs = Ms.new(MockTestingConfig) -- using it (its nil if conditions arent met BTW)

					ReceiverMs:Run()

					if TestThisService then
						MockTestMs:StartTest(ReceiverMs) -- do ur own scenario or wtv
					end

					--Ms.IsRunning = true -- make sure all services have this
				end
			end
		end
	end
	--end)()
end

local function SetupRecievers()
	for _, Receiver in ClientReceiversFolder:GetDescendants() do
		InitHookedReceiver(LiveMockTestsAllowed, Receiver)
	end
end

---

-- Initialize Player

function Init(Character: Model)
	SetupRecievers()

	-- Upon Starting
	for _, Component in Character:GetTags() do
		if FindValueInTable(Character:GetTags(), Component) then
			-- check if we have a controller for it
			local ComponentName: string = FindValueInTable(TagList.Components, Component, true)

			if ClientControllersFolder:FindFirstChild(`Client_{ComponentName}`) then
				addToCachedControllerModules(ComponentName)

				local Controller

				local _, E = pcall(function()
					Controller = CachedControllerModules[ComponentName].new() -- Prone to hacks?
				end)

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
end

local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()

Init(Character)

print(`Controller Modules Cached:`, CachedControllerModules)
print(`Running Controllers Loaded at {TimeNow()}:`, RunningControllers)
