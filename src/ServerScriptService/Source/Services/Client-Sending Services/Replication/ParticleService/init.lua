local ReplicatedFirst = game:GetService("ReplicatedFirst")
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
		[`PlayVFXAtPosition`] = { `RemoteEvent`, nil },
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

	local RemEvent = self.RemotesFolder:FindFirstChildOfClass("RemoteEvent")

	self.CreatedListeners["Remote"][RemEvent.Name] = RemEvent
end

function Service:PlayVFXAt( -- Maybe we can dumb this down to just a DOS search and then play VFX with specified parameters?
	VFXPosition, -- Vector3 or table of Attachments or character model
	VFXName: string,
	VFXOffset: CFrame,
	VFXParticleCount: number,
	DestroyTime: number
)
	local DOS = require(SSS.Server.Testing.GetDOS).DOS
	local PlrsNearNPC = {}
	local CharactersNearVFX = nil

	if typeof(VFXPosition) == "table" then
		CharactersNearVFX = DOS.Tree:RadiusSearch(VFXPosition[1].WorldPosition, 50)
	elseif typeof(VFXPosition) == "Vector3" then
		CharactersNearVFX = DOS.Tree:RadiusSearch(VFXPosition, 50)
	elseif VFXPosition:IsA("Model") then
		CharactersNearVFX = DOS.Tree:RadiusSearch(VFXPosition.PrimaryPart.Position, 50)
	else
		warn("VFXPosition is not correct type (table, vector, or model)")
	end

	for _, Character in CharactersNearVFX do
		if Character:HasTag(TagList.PlayerTag) then
			PlrsNearNPC[Character.Name] = game.Players:GetPlayerFromCharacter(Character)
		end
	end

	FireTo(
		self["CreatedListeners"]["Remote"],
		PlrsNearNPC,
		"PlayVFXAtPosition",
		VFXName,
		VFXOffset,
		VFXParticleCount,
		DestroyTime,
		VFXPosition
	)
end

return Service
