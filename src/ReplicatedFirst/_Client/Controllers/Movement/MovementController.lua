-- {Most Recent: 10/5/2025} //FUUJI
-- Status: Must Edit
-- This is going to house all of the basic moveset input handling, where the server parses the packets sent

local core = script:FindFirstAncestorWhichIsA("LocalScript")
local CS = game:GetService("CollectionService")
local AnimsFolder = unpack(CS:GetTagged("Folder_Animations")).Movement_R6
local InputEnums = require(game.ReplicatedStorage.Utility.Movement.Enums)
local UISBinds = require(game.ReplicatedStorage.Utility.GLOBAL.UserInputBind)
local Types = require(game.ReplicatedStorage.Utility.GLOBAL.Types)
local Helpers = core.Helpers
local UIS = game:GetService("UserInputService")

local Listeners: Folder = nil

--Modules
local Mod_DoubleTap = require(Helpers.Global.DoubleTap)

-- Getting Helpers
local HumanoidControl = require(Helpers.Movement.HumanoidControl)
local AnimationLoader = require(Helpers.Global.AnimationLoader)
local ReturnIdentifier = require(Helpers.Global.FindValueInTable)

local TellServerAboutInput = function(ActionName: string, ...)
	return Listeners["Movement_ClientToServer"]:InvokeServer(ActionName, ...)
end
--Modules

local Controller = {}
Controller.__index = Controller
Controller._controllerMetaTable = nil

function Controller.new()
	local Animations = {}

	local self = setmetatable({
		["Initialized"] = false, -- Has the controller initialized
		["Name"] = `{script.Name}_Controller`, --Incase i want to use this

		["Connections"] = {},
		["Animations"] = nil,

		["Rig"] = game.Players.LocalPlayer.Character,
		["Player"] = game.Players.LocalPlayer,
	}, Controller)

	-- Setup
	self:Init()
	Controller._controllerMetaTable = self

	return self
end

-- Movement stuff
MoveSet = {}

function MoveSet.Dash(ActionName, UserInputState, InputObject)
	if UserInputState == Enum.UserInputState.Begin or UserInputState == Enum.UserInputState.Cancel then
		local TimeInputted = tick()
		local Performed: boolean = TellServerAboutInput(ActionName, TimeInputted)
	end
end

function MoveSet.Run(ActionName, UserInputState, InputObject)
	local TimeInputted = tick()
	local Performed: boolean = TellServerAboutInput(ActionName, TimeInputted)

	if not Performed then
		return
	end
	--// Check when you press something other than W
	Controller._controllerMetaTable["Connections"]["RunConnection"] = UIS.InputEnded:Connect(function(inp, gpe)
		if gpe then
			return
		end

		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
			if inp.KeyCode.Name == "W" then
				--// Should prolly add a run-keys table in the input enums but wtv
				if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.D) then
					TellServerAboutInput("RunCancel")
					Controller._controllerMetaTable["Connections"]["RunConnection"]:Disconnect()
				end
			end
		end
	end)
end

function MoveSet.Jump(ActionName)
	local TimeInputted = tick()
	local Performed: boolean = TellServerAboutInput(ActionName, TimeInputted)
end

function MoveSet.Crouch_or_Slide(ActionName, UserInputState, InputObject)
	if UserInputState == Enum.UserInputState.Begin or UserInputState == Enum.UserInputState.Cancel then
		local TimeInputted = tick()
		local Performed: boolean = TellServerAboutInput(ActionName, TimeInputted)
	end
end

function MoveSet.CancelAction(ActionName, UserInputState, InputObject)
	if UserInputState == Enum.UserInputState.Begin or UserInputState == Enum.UserInputState.Cancel then
		local TimeInputted = tick()
		local Performed: boolean = TellServerAboutInput(ActionName, TimeInputted)
	end
end

-- Class stuff

function Controller:Init()
	if self["Initialized"] then
		return false
	end

	self["Initialized"] = true

	local CanInit, ErrorMsg = pcall(function()
		Listeners = game.Players.LocalPlayer:WaitForChild("Movement_Remotes/Listeners")
		-- Other stuff if needed
	end)

	if not CanInit then
		warn(`{script.Name} for {game.Players.LocalPlayer} cannot be initialized for reason '{ErrorMsg}'`)
		self["Initialized"] = false
	else
		-- All listeners and everything was setup so we...
		self:BindAllInputs()
		self:BindToRenderStep()
		self:LoadAnimations()

		print(`{script.Name} is Initialized [Controller]`)
		self["Initialized"] = true
	end

	return self["Initialized"]
end

function Controller:LoadAnimations()
	self["Animations"] = AnimationLoader:LoadAnimsOnTrack(AnimsFolder:GetDescendants(), self["Rig"].Humanoid.Animator)
	--print(self['Animations'])
end

function Controller:BindToRenderStep()
	local HumanController = HumanoidControl.new(self["Player"])
	local Character: Types.Rig_R6 = self["Player"].Character or self["Player"].CharacterAdded:Wait()
	local Connection

	Connection = game:GetService("RunService"):BindToRenderStep(script.Name, 100, function()
		if not Character then
			-- Stop the function
			game:GetService("RunService"):UnbindFromRenderStep(script.Name)
		end

		Character.Humanoid:Move(HumanController:getWorldMoveDirection(), false)
	end)

	table.insert(self["Connections"], Connection)
end

function Controller:BindAllInputs()
	for Index, Func in MoveSet do
		local KeyCode = InputEnums.MovementInputs[Index]

		if not KeyCode then
			warn(
				`InputEnums.MovementInputs.{Index} doesn't exist: See MovementInputs for more:`,
				InputEnums.MovementInputs
			)
			continue
		end

		if Index == "Jump" then
			table.insert(
				self["Connections"],
				UIS.JumpRequest:Connect(function()
					Func(Index)
				end)
			)
			continue
		end

		if KeyCode == -1 then
			if Index == "Run" then
				table.insert(
					self["Connections"],
					Mod_DoubleTap:BindDoubleTap(
						Index,
						{ "W", "S", "A", "D" },
						0.45, -- TapTimeout
						"Began",
						Func
					)
				)
			end
		end

		UISBinds:BindToInput(Index, Func, KeyCode)
	end
end

function Controller:Destroy()
	for Index, _ in MoveSet do
		UISBinds:UnbindAction(Index)
	end

	local DeepClean = function()
		for _, c: RBXScriptConnection in self["Connections"] do
			if typeof(c) == "table" then
				for _, C: RBXScriptConnection in c do
					C:Disconnect()
				end
			elseif typeof(c) == "RBXScriptConnection" then
				c:Disconnect()
			end
		end
	end

	DeepClean()

	Controller._controllerMetaTable = nil
	setmetatable(self, nil)

	print(`Movement Controller for {game.Players.LocalPlayer} was Destroyed`)
end

--

return Controller
