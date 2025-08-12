local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")

local TagList = require(ReplicatedFirst._Shared.TagList)
local SetupServiceComms = require(SSS.Source.Services.Helpers.SetupServiceComms)
local FireTo = require(SSS.Packages.Utility.FireTo)

local Service = {
	["Name"] = script.Name,
	["TestingFlag"] = false,
}

Service.__index = Service

function SetupFRS()
	local Folder = Instance.new("Folder", game:GetService("ReplicatedStorage").Comms)
	Folder.Name = `{script.Name}`

	SetupServiceComms.SetupRemotes(nil, {
		[`PlayAnimationOnRig`] = { `RemoteEvent`, nil },
		[`StopAnimationOnRig`] = { `RemoteEvent`, nil },
	}, Folder)

	return Folder
end

function Service.new()
	local self = setmetatable({
		Name = script.Name,
		RemotesFolder = nil,

		CreatedListeners = {
			Remote = {},
		},
	}, Service)

	return self
end

function Service:Run()
	self.RemotesFolder = SetupFRS()

	for i, RemEvent in self.RemotesFolder:GetChildren() do
		self.CreatedListeners["Remote"][RemEvent.Name] = RemEvent
	end
end

function Service:PlayAnimationOnRig(TargetRig: Model, animationName: string)
	local Player = Players:GetPlayerFromCharacter(TargetRig) or nil

	if not Player then
		-- Play the animation on the target rig
		local DOS = require(SSS.Server.Testing.GetDOS).DOS
		local NPC = TargetRig

		local CharactersNearNPC = DOS.Tree:RadiusSearch(NPC.PrimaryPart.Position, 50)
		local PlrsNearNPC = {}

		for _, Character in CharactersNearNPC do
			if Character:HasTag(TagList.PlayerTag) then
				PlrsNearNPC[Character.Name] = game.Players:GetPlayerFromCharacter(Character)
			end
		end

		FireTo(self["CreatedListeners"]["Remote"], PlrsNearNPC, "PlayAnimationOnRig", animationName, TargetRig)
	else
		-- Play the animation on the Player's own rig

		FireTo(self["CreatedListeners"]["Remote"], { Player }, "PlayAnimationOnRig", animationName)
	end
end

function Service:StopAnimationOnRig(targetRig, animationName)
	local Player = Players:GetPlayerFromCharacter(targetRig) or nil

	if Player then
		-- stop anim on player

		FireTo(self["CreatedListeners"]["Remote"], { Player }, "StopAnimationOnRig", animationName)
	else
		-- stop anim for npc

		local DOS = require(SSS.Server.Testing.GetDOS).DOS
		local NPC = targetRig

		local CharactersNearNPC = DOS.Tree:RadiusSearch(NPC.PrimaryPart.Position, 50)
		local PlrsNearNPC = {}

		for _, Character in CharactersNearNPC do
			if Character:HasTag(TagList.PlayerTag) then
				PlrsNearNPC[Character.Name] = game.Players:GetPlayerFromCharacter(Character)
			end
		end

		FireTo(self["CreatedListeners"]["Remote"], PlrsNearNPC, "StopAnimationOnRig", animationName, targetRig)
	end
end

return Service
