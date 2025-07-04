-- BASE COMPONENT THAT OFFSHOOTS INTO INDIVIDUALS (Movement, Combat, etc.)
local SSS = game:GetService("ServerScriptService")
local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ComponentFolder = SSS.Source.Services["Client-Relaying Services"].Components
local ComponentSets = ComponentFolder.ComponentSets

local PromiseV4 = require(RS.Libraries.promise)
local Tags = require(RF._Shared.TagList)
local SetupServiceComms = require(SSS.Source.Services.Helpers.SetupServiceComms)

local BaseComponent = {}

BaseComponent.__index = BaseComponent

--keep the requires...

function BaseComponent.new(Name: string, Rig: Model, OnInvoke)
	local Component = {
		Name = Name,
		Connections = {},
		[`{Name}Set`] = require(ComponentSets[`{Name}_Set`]),
		IsClient = nil,
	}

	Component["IsClient"] = Rig:HasTag(Tags.PlayerTag)

	if Component["IsClient"] then
		Component["IsClient"] = game:GetService("Players"):GetPlayerFromCharacter(Rig)
	else
		Component["IsClient"] = Rig
	end

	Component[`{Name}DataValues`] = Component[`{Name}Set`].new(Component)

	print(Component)

	return setmetatable(Component, BaseComponent)
end

function BaseComponent:PerformInputOnRig(Input)
	if not Input then
		return
	end

	local Action = self[`{self.Name}Set`][Input]

	if not Action then
		print(`We gotta make this {Input} -System`)
		return
	end

	local ReturnValue

	local promise = PromiseV4.new(function(resolve, reject, onCancel)
		local _, ErrorMsg = pcall(function()
			ReturnValue = Action(self)
		end)

		if not ErrorMsg then
			resolve(ReturnValue)
		else
			reject(ErrorMsg)
		end
	end)

	return promise
end

function BaseComponent:Destroy(Message: string?)
	local Client = self["IsClient"]
	local Name = Client.Name

	-- Destroying Connections
	for _, Connection: RBXScriptConnection in self.Connections do
		if not Connection then
			continue
		end
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		end
	end

	setmetatable(self, nil)

	print(`[End] || {self.Name} Component for {Name} was Destroyed due to '{Message or "Unknown Disconnection"}'.`)
end

return BaseComponent
