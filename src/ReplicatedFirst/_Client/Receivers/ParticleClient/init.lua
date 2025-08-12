-- Explorer stuff
local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")
local Debris = game:GetService("Debris")

local Comms = RS.Comms:WaitForChild("ParticleService")

local VFXUtil = require(RF._Client.Utility.VFXUtil)

local Reciever = {
	["TestingFlag"] = false,
}

Reciever.__index = Reciever

-- Bind to server event

function BindToRecievers()
	local RemEvent = Comms:WaitForChild("PlayVFXAtPosition")

	RemEvent.OnClientEvent:Connect(function(VFXName, VFXOffset, VFXParticleCount, DestroyTime, Position)
		local Player = game:GetService("Players").LocalPlayer

		local VFX: BasePart = VFXUtil.Registry[Player.Name].CachedVFX[VFXName]:Clone()

		if typeof(Position) == "table" then
			-- Play the VFX on the attachment
			for i, v in Position do
				local Attachment = v

				for index, particle in VFX:GetDescendants() do
					if not particle:IsA("ParticleEmitter") then
						continue
					end
					local NewParticle: ParticleEmitter = particle:Clone()
					NewParticle.Parent = Attachment

					if VFXParticleCount then
						NewParticle:Emit(VFXParticleCount)
						Debris:AddItem(NewParticle, DestroyTime)
					else
						NewParticle.Enabled = true

						task.delay(DestroyTime, function()
							NewParticle.Enabled = false
							Debris:AddItem(NewParticle, 0.2)
						end)
					end
				end
			end
		elseif typeof(Position) == "Vector3" then
			-- Play the VFX at the position
			VFX.Position = Position
			VFX.Anchored = true
			VFX.Parent = workspace

			for i, v in VFX:GetDescendants() do
				if v:IsA("ParticleEmitter") then
					if VFXParticleCount then
						v:Emit(VFXParticleCount)
					else
						v.Enabled = true

						task.delay(DestroyTime, function()
							v.Enabled = false
						end)
					end
				end
			end

			Debris:AddItem(VFX, DestroyTime + 0.5)
		else
			-- Play VFX on the model with a weld
			local Character = Position
			if Character then
				VFX.Parent = Character.HumanoidRootPart

				local VFXWeld = Instance.new("Motor6D")
				VFXWeld.Parent = VFX.Parent
				VFXWeld.Part0 = Character.HumanoidRootPart
				VFXWeld.Part1 = VFX
				VFXWeld.C0 = VFXOffset

				Debris:AddItem(VFXWeld, DestroyTime + 0.5)
			else
				VFX.Parent = workspace
			end

			for i, v in VFX:GetDescendants() do
				if v:IsA("ParticleEmitter") then
					if VFXParticleCount then
						v:Emit(VFXParticleCount)
					else
						v.Enabled = true

						task.delay(DestroyTime, function()
							v.Enabled = false
						end)
					end
				end
			end

			Debris:AddItem(VFX, DestroyTime + 0.5)
		end
	end)
end

function Reciever.new()
	local self = setmetatable({
		Name = script.Name,
	}, Reciever)

	return self
end

-- Client Util

function Reciever:Run()
	BindToRecievers()
end

return Reciever
