local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")

local Helpers = script.Helpers

local MovementBinds = require(Helpers.CombatBinds)
local TagList = require(RF._Shared.TagList)
local BaseController = require(RS.Module_Bases.BaseController)

local MovementController = {
	Tag = TagList.Controllers.Movement,
}

MovementController.__index = MovementController

function MovementController.new()
	local self = BaseController.new(MovementController.Tag)
	self.Binds = MovementBinds
	self:Init()

	return self
end

return MovementController
