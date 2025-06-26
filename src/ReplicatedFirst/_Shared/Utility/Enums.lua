local TagList = require(game:GetService("ReplicatedFirst")._Shared.TagList)

local _controllers = TagList['Controllers']

return {
	[_controllers.Combat] = {
		["Attack"] = Enum.UserInputType.MouseButton1,
		["Feint"] = Enum.UserInputType.MouseButton2,
		["Parry"] = Enum.KeyCode.F,
		["Block"] = Enum.KeyCode.F,
		["BlockEnd"] = Enum.KeyCode.F,
		["Critical"] = Enum.KeyCode.R,
	},

	[_controllers.Movement] = {
		-- ['JumpBind'] = 
	},
}
