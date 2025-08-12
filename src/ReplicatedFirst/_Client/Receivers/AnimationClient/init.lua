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
	local PlayRemEvent: RemoteEvent = Comms:WaitForChild("PlayAnimationOnRig")
	local StopRemEvent: RemoteEvent = Comms:WaitForChild("StopAnimationOnRig")

	local NPCCachedTracks = {}

	PlayRemEvent.OnClientEvent:Connect(function(animationName, targetRig)
		local Player = game.Players.LocalPlayer
		local AnimsCache = AnimationUtil.Registry[Player.Name]
		if not targetRig then
			local AnimTrack = AnimsCache.CachedTracks[animationName]

			AnimTrack:Play()
		else
			local Anim = AnimsCache.CachedAnims[animationName]
			local Animator = targetRig.Humanoid.Animator

			local AnimTrack = Animator:LoadAnimation(Anim)
			AnimTrack:Play()

			NPCCachedTracks[targetRig.Parent.Name] = AnimTrack
		end
	end)

	StopRemEvent.OnClientEvent:Connect(function(animationName, targetRig)
		local Player = game.Players.LocalPlayer
		local AnimsCache = AnimationUtil.Registry[Player.Name]
		if not targetRig then
			local AnimTrack = AnimsCache.CachedTracks[animationName]
			print("hufdsd")
			AnimTrack:Stop()
		else
			local AnimTrack = NPCCachedTracks[targetRig.Parent.Name]
			AnimTrack:Stop()

			NPCCachedTracks[targetRig.Parent.Name] = nil
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
