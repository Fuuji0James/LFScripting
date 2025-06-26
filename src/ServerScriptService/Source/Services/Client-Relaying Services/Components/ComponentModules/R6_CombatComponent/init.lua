local SSS = game:GetService("ServerScriptService")
local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")

local Packages = SSS.Packages
local CommsFolder = RS.Comms

local Tags = require(RF._Shared.TagList)
local BaseComponent = require(Packages._BaseComponent)
local ComponentHandler = require(SSS.Packages.ComponentHandler)
local CombatMW = require(script.MW.CombatMW)

local SetupServiceComms = require(SSS.Source.Services.Helpers.SetupServiceComms)

local Combat = {
	Tag = Tags.Components.Combat,
}

local function OnInvoke(Plr, Input)
	local CurrentComponent = ComponentHandler.GetComponentsFromInstance(Plr.Character, Combat.Tag)

	if not CombatMW:CheckValues(CurrentComponent, Input) then
		return
	end

	local promise = CurrentComponent:PerformInputOnRig(Input)
	local ReturnedCombatDataValues

	promise
		:andThen(function(ReturnedValue)
			print(ReturnedValue)
			ReturnedCombatDataValues = ReturnedValue
		end)
		:catch(function(ErrorMsg)
			warn(ErrorMsg)
		end)
		:await()

	CurrentComponent["Component_Combat_R6DataValues"] = ReturnedCombatDataValues

	print(CurrentComponent["Component_Combat_R6DataValues"].currentCombo)
	return CurrentComponent["Component_Combat_R6DataValues"].currentCombo
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

	return self
end

return Combat
