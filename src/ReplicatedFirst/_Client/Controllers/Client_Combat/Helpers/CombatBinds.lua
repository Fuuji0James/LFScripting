local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local UIS = game:GetService("UserInputService")

local AnimationUtil = require(RF._Client.Utility.AnimationUtil)
local Promise = require(RS.Libraries.promise)

local RemFunc: RemoteFunction = RS.Comms.Component_Combat_R6_Remotes.Component_Combat_R6_ClientToServer

return {
	Attack = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			local DataValues = self.ClientDataValues
			if DataValues.canAttack == true then
				local _Connection = nil
				local _promise = Promise.new(function(resolve, reject, onCancel)
					DataValues.canAttack = false
					DataValues.canBlock = false
					DataValues.canParry = false
					DataValues.canFeint = true

					local ServerValue = RemFunc:InvokeServer(ActionName)
					local AttackTrack: AnimationTrack = AnimationUtil.CachedTracks[`Attack{ServerValue}`]
					AttackTrack:Play()

					task.delay(AttackTrack.Length, function()
						DataValues.canAttack = true
						DataValues.canBlock = true
						DataValues.canParry = true
						DataValues.canFeint = false
					end)

					_Connection = AttackTrack.KeyframeReached:Connect(function(kfname)
						if kfname == "Active" then
							resolve(ServerValue)
						end
					end)
				end):andThen(function(ServerValue)
					if _Connection then
						print(ServerValue)
						DataValues.currentCombo = ServerValue
						_Connection:Disconnect()
					end
				end)
			end
		end
	end,

	Block = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			print("block")
		end
	end,

	BlockEnd = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.End then
			print("blocking ended")
		end
	end,

	Parry = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			print("parry")
		end
	end,

	Feint = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			print("feint")
		end
	end,

	Critical = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			print("critical")
		end
	end,
}
