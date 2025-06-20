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

function BaseComponent.new(Name: string, Rig: Model, OnInvoke)
	local Component = {
		Name = Name,
		Connections = nil,
		[`{Name}Set`] = require(ComponentSets[`{Name}_Set`]),
		[`{Name}DataValues`] = nil,

		IsClient = nil,
	}

	return Component
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

function BaseComponent:Destroy(Message: string, Component)
	local Name = Component.Rig.Name

	-- Destroying remotes
	for _, Remote: Instance in Component["Listeners"] do
		if not Remote then
			continue
		end
		if typeof(Remote) == "Instance" then
			Remote:Destroy()
		end
	end

	-- Destroying Folders
	for _, Folder: Folder in Component.CreatedFolders do
		if not Folder then
			continue
		end
		if typeof(Folder) == "Instance" then
			Folder:Destroy()
		end
	end

	-- Destroying Connections
	for _, Connection: RBXScriptConnection in Component.Connections do
		if not Connection then
			continue
		end
		if typeof(Connection) == "RBXScriptConnection" then
			Connection:Disconnect()
		end
	end

	setmetatable(Component, nil)

	print(`[End] || {Component.Name} Component for {Name} was Destroyed due to '{Message or "Unknown Disconnection"}'.`)
end

return BaseComponent
