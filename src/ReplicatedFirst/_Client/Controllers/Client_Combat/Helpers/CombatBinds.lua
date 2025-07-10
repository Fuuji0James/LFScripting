local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local UIS = game:GetService("UserInputService")

local Hitboxing = require(script.Parent.Hitboxing)
local Promise = require(RS.Libraries.promise)
local AnimationUtil = require(RF._Client.Utility.AnimationUtil)

local RemFunc: RemoteFunction = RS.Comms.Component_Combat_R6_Remotes.Component_Combat_R6_ClientToServer

return {
	Attack = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			local DataValues = self.ClientDataValues
			if DataValues.canAttack == true then
				local _Connection = nil
				local _promise = Promise.new(function(resolve, reject, onCancel)
					DataValues.canAttack = false

					local ServerValue = RemFunc:InvokeServer(ActionName)

					if not ServerValue then
						DataValues.canAttack = true
						reject("Server rejected the attack")
						return
					end
					local CachedAnims = AnimationUtil.Registry[self.Player.Name]
					local AttackTrack: AnimationTrack = CachedAnims.CachedTracks[`Attack{ServerValue}`]

					DataValues.currentAnim = AttackTrack
					AttackTrack:Play()
					task.delay(AttackTrack.Length, function()
						DataValues.canAttack = true
					end)

					_Connection = AttackTrack.KeyframeReached:Connect(function(kfname)
						local Character = self.Rig
						local ClientToServerRem: RemoteEvent =
							RS.Comms.Component_Combat_R6_Remotes.Component_Combat_R6_ClientToServerEvent

						if kfname == "Active" then
							local Hitbox = Hitboxing.Create()

							Hitbox.Character = Character
							Hitbox.CFrame = CFrame.new(0, 0, -4)
							Hitbox.Size = Vector3.new(5, 5, 5)
							Hitbox.Visualizer = true

							Hitbox:Visualize()
							local ene_hum = Hitbox:FindHum(Character)

							if ene_hum then
								print("zerp")
								ClientToServerRem:FireServer(ene_hum)
							end
							resolve(ServerValue)
						end
					end)
				end):andThen(function(ServerValue)
					if _Connection then
						DataValues.currentCombo = ServerValue
						_Connection:Disconnect()
					end
				end)
			end
		end
	end,

	BlockEnd = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.End then
			local DataValues = self.ClientDataValues
			if DataValues.isBlocking then
				if DataValues.parryConnection then
					DataValues.parryConnection:Disconnect()
				end

				local CachedAnims = AnimationUtil.Registry[self.Player.Name]

				local BlockTrack: AnimationTrack = CachedAnims.CachedTracks["BlockAnim"]
				BlockTrack:Stop()
				DataValues.isBlocking = false

				local _BlockEnd = RemFunc:InvokeServer(ActionName)
			end
		end
	end,

	Parry = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			local DataValues = self.ClientDataValues
			if DataValues.canParry == true then
				local CachedAnims = AnimationUtil.Registry[self.Player.Name]

				local ParryTrack: AnimationTrack = CachedAnims.CachedTracks["ParryAnim"]
				ParryTrack:Play()

				local ServerValue = RemFunc:InvokeServer(ActionName)
				if ServerValue then
					DataValues.parryConnection = ParryTrack.KeyframeReached:Connect(function(name)
						if name == "ParryEnd" and UIS:IsKeyDown(Enum.KeyCode.F) then
							local BlockTrack: AnimationTrack = CachedAnims.CachedTracks["BlockAnim"]

							DataValues.isBlocking = true
							ActionName = "Block"

							BlockTrack:Play()
							local _Block = RemFunc:InvokeServer(ActionName)
						end
					end)
				else
					ParryTrack:Stop()
				end
			end
		end
	end,

	Feint = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			local ServerValue = RemFunc:InvokeServer(ActionName)

			if ServerValue then
				local DataValues = self.ClientDataValues
				local currentAnim: AnimationTrack = DataValues.currentAnim
				if currentAnim then
					currentAnim:Stop()
				end
			end
		end
	end,

	Critical = function(ActionName, UserInputState, InputObject: InputObject, self)
		if UserInputState == Enum.UserInputState.Begin then
			print("critical")
		end
	end,
}
