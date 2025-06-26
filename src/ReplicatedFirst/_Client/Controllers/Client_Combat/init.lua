local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")

local Helpers = script.Helpers

local CombatBinds = require(Helpers.CombatBinds)
local TagList = require(RF._Shared.TagList)
local BaseController = require(RS.Module_Bases.BaseController)
local Client_CombatDataValues = require(script.Helpers.Client_CombatDataValues)

local CombatController = {
	Tag = TagList.Controllers.Combat,
}

CombatController.__index = CombatController

function CombatController.new()
	local self = BaseController.new(TagList.Controllers.Combat)

	self.Binds = CombatBinds
	self.ClientDataValues = Client_CombatDataValues

	self:Init()

	return self
end

return CombatController
