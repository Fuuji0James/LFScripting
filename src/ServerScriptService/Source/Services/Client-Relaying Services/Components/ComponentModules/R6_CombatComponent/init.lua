local SSS = game:GetService("ServerScriptService")
local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")

local Libraries = RS.Libraries
local Packages = SSS.Packages
local CommsFolder = RS.Comms

local Promise = require(Libraries.PromiseV4)
local Tags = require(RF._Shared.TagList)
local BaseComponent = require(Packages._BaseComponent)

local SetupServiceComms = require(SSS.Source.Services.Helpers.SetupServiceComms)

local Combat = {
	Tag = Tags.Components.Combat,
}

local function OnInvoke()
	print("hopefully it works")
end

function Combat.Init()
	local CombatCommsFolder = SetupServiceComms.SetupFolders(`{Combat.Tag}_Remotes`, CommsFolder)

	SetupServiceComms.SetupRemotes(Combat.Tag, {
		[`ClientToServerEvent`] = { `RemoteEvent` },
		[`ClientToServer`] = { `RemoteFunction`, OnInvoke },
	}, CombatCommsFolder[1])
end

function Combat.new(Rig: Model)
	local self = BaseComponent.new(Combat.Tag, Rig, OnInvoke)
end

return Combat
