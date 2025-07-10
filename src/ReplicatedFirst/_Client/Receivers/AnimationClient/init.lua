-- Explorer stuff
local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")

local Comms = RS.Comms:WaitForChild("AnimationService")

local AnimationUtil = require(RF._Client.Utility.AnimationUtil)

local Reciever = {
	["TestingFlag"] = false,
}

Reciever.__index = Reciever

-- Bind to server event

function BindToRecievers()
	local RemEvent = Comms:WaitForChild("PlayAnimationOnRig")

	RemEvent.OnClientEvent:Connect(function(animationName, targetRig)
		local Player = game.Players.LocalPlayer
		local AnimsCache = AnimationUtil.Registry[Player.Name]
		if not targetRig then
			local AnimTrack = AnimsCache.CachedTracks[animationName]

			AnimTrack:Play()
		else
			local Anim = AnimsCache.CachedAnims[animationName]
			local Animator = targetRig.Humanoid.Animator
			print(AnimsCache.CachedAnims)
			local AnimTrack = Animator:LoadAnimation(Anim)
			AnimTrack:Play()
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
