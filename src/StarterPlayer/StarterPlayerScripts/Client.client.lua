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
local LiveMockTestsAllowed = false -- as in PUBLIC GAME mock tests

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

local function SetupRecievers()
	for _, Receiver in ClientReceiversFolder:GetDescendants() do
		coroutine.wrap(function()
			if Receiver:IsA("ModuleScript") and not (string.match(Receiver.Name, "^__Template")) then
				local Ms = require(Receiver)

				if typeof(Ms) == "table" then
					if Ms.new and Ms.Run then -- has this life cycle
						local MockTestMs = require(Receiver:WaitForChild("MockTests"))
						local MockTestingConfig: {} = nil
						local TestThisReceiver = false

						if MockTestMs.TestingFlag then
							if
								LiveMockTestsAllowed
								or (LiveMockTestsAllowed == false and game:GetService("RunService"):IsStudio())
							then
								TestThisReceiver = true

								if MockTestMs.SetupTestConfig then
									MockTestingConfig = MockTestMs:SetupTestConfig()
								end
							end
						end

						local ReceiverMs = Ms.new(MockTestingConfig) -- using it (its nil if conditions arent met BTW)

						ReceiverMs:Run()

						if TestThisReceiver then
							MockTestMs:StartTest(ReceiverMs) -- do ur own scenario or wtv
						end

						--Ms.IsRunning = true -- make sure all rec. have this

						if ReceiverMs.OnClose then
							game.Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
								if not parent then
									ReceiverMs:OnClose()
								end
							end)
						else
							print(
								`Why does module '{Receiver.Name}' not have an OnClose Function if it initializes with .new()?`
							)
						end
					end
				end
			end
		end)()
	end
end

---

-- Initialize Player

function Init(Character: Model)
	SetupRecievers()

	print(Character:GetTags())

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
print(`Running Controllers Loaded at {TimeNow}:`, RunningControllers)
