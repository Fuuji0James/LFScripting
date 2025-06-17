-- BASE COMPONENT THAT OFFSHOOTS INTO INDIVIDUALS (Movement, Combat, etc.)
local SSS = game:GetService("ServerScriptService")
local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ComponentFolder = SSS.Source.Services["Client-Relaying Services"].Components
local CommsFolder = RS.Comms
local ComponentSets = ComponentFolder.ComponentSets


local Tags = require(RF._Shared.TagList)
local SetupFolders = require(SSS.Source.Services.Helpers.SetupServiceComms.SetupFolders)
local SetupRemotes = require(SSS.Source.Services.Helpers.SetupServiceComms.SetupRemotes)


local BaseComponent = {}

function BaseComponent.new(Name: string, Rig: Model, OnInvoke)
	local Component = {
		Name = Name,
		Connections = nil,
		[`{Name}Set`] = require(ComponentSets[`{Name}_Set`]),
		[`{Name}DataValues`] = nil,

		IsClient = nil
	}

	-- Determining the Client

	local Prefix
	local RemoteType

	local isPlayer = Rig:HasTag(Tags.PlayerTag)

	if isPlayer then
		Component["Player"] = Players:GetPlayerFromCharacter(Rig) -- For easy syntax

		Prefix = "Client"
		RemoteType = "Remote"
	else
		Component["Bot"] = Rig

		Prefix = "Server"
		RemoteType = "Bindable"
	end

	-- Setting up folders/listeners


	return Component
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
