return {
	Attack = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == Enum.UserInputState.Begin then
			print("attack")
		end
	end,

	Block = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == Enum.UserInputState.Begin then
			print("block")
		end
	end,

	BlockEnd = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == Enum.UserInputState.End then
			print("blocking ended")
		end
	end,

	Parry = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == Enum.UserInputState.Begin then
			print("parry")
		end
	end,

	Feint = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == Enum.UserInputState.Begin then
			print("feint")
		end
	end,

	Critical = function(ActionName, UserInputState, InputObject: InputObject)
		if UserInputState == Enum.UserInputState.Begin then
			print("critical")
		end
	end,
}
