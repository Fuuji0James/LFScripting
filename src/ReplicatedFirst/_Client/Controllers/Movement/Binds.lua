local _inputState = Enum.UserInputState

return {
	Sprint = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == _inputState.Begin then
			print("attack")
		end
	end,

	Dodge = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == _inputState.Begin then
			print("block")
		end
	end,

	DodgeCancel = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == _inputState.End then
			print("blocking ended")
		end
	end,

	Slide = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == _inputState.Begin then
			print("parry")
		end
	end,

	Vault = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == _inputState.Begin then
			print("feint")
		end
	end,

	Critical = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == _inputState.Begin then
			print("critical")
		end
	end,
}
