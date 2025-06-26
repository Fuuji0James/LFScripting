local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

local Enums = require(RF._Shared.Utility.Enums)
local UISBinds = require(RF._Client.Utility.UserInputBinds)
local TagList = require(RF._Shared.TagList)

local Controller = {}

Controller.__index = Controller

function Controller.new(Tag)
	local self = setmetatable({
		Initialized = false,
		Name = Tag,

		Connections = {},
		Animations = {},
		Binds = {},

		Rig = Players.LocalPlayer.Character,
		Player = Players.LocalPlayer,
	}, Controller)

	return self
end

function BindAllInputs(Binds, Tag)
	for ActionName, Bind in Binds do
		local Input = Enums[Tag][ActionName]
		-- print(Input)
		UISBinds:BindToInput(ActionName, Bind, Input)
	end
end

function Controller:Init()
	if self["Initialized"] then
		return
	end

	local CanInit, ErrorMsg = pcall(function()
		local _Listeners = RS.Comms[`{TagList.Components.Combat}_Remotes`]
		-- Other stuff if needed
	end)

	-- print(self.Binds)

	if not CanInit then
		warn(`{self.Name} for {self.Player} cannot be initialized for reason '{ErrorMsg}'`)
		self["Initialized"] = false
	else
		-- All listeners and everything was setup so we...
		BindAllInputs(self.Binds, self.Name)

		print(`{self.Name} is Initialized [Controller]`)
		self["Initialized"] = true
	end

	return self["Initialized"]
end

function Controller:Destroy()
	local DeepClean = function()
		for _, c: RBXScriptConnection in self["Connections"] do
			if typeof(c) == "table" then
				c:Disconnect()
			elseif typeof(c) == "RBXScriptConnection" then
				c:Disconnect()
			end
		end
	end

	DeepClean()

	print(`{self.Name} Controller for {self.Player} was Destroyed`)

	setmetatable(self, nil)
end

return Controller
