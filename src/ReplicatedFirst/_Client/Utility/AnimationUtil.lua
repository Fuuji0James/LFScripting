local CS = game:GetService("ContentProvider")

local LoadAnims = {
	Registry = {},
}

LoadAnims.__index = LoadAnims

function LoadAnims.new(Player)
	local self = setmetatable({
		Name = Player.Name,
		CachedAnims = {},
		CachedTracks = {},
	}, LoadAnims)

	LoadAnims.Registry[self.Name] = self

	return self
end

function LoadAnims:PreloadAnims(AnimationsList)
	-- clear cached anims
	self.CachedAnims = {}

	local LoadedAnims = {}

	if typeof(AnimationsList) == "table" then
		for _, Animation in AnimationsList do
			if Animation:IsA("Animation") then
				CS:PreloadAsync(AnimationsList)
				LoadedAnims[Animation.Name] = Animation
				self.CachedAnims[Animation.Name] = Animation
			end
		end
	elseif typeof(AnimationsList) == "Instance" then
		for _, Animation in pairs(AnimationsList:GetDescendants()) do
			if Animation:IsA("Animation") then
				LoadedAnims[Animation.Name] = Animation
				self.CachedAnims[Animation.Name] = Animation
			end
		end
	end

	print(self)

	--[[AnimationsAdded.OnClientEvent:Connect(function(Animation: Animation, State: string)
		if State == "LoadTrack" then
			return
		end
		CS:PreloadAsync({ Animation })
		LoadedAnims[Animation.Name] = Animation
		self.CachedAnims[Animation.Name] = Animation
	end)]]

	return LoadedAnims
end

function LoadAnims:LoadAnimsOnTrack(AnimationsList, Animator)
	-- clear cached tracks
	self.CachedTracks = {}

	local LoadedAnims = {}
	print(Animator.Parent.Parent)
	AnimationsList = self:PreloadAnims(AnimationsList)

	if typeof(AnimationsList) == "table" then
		print(AnimationsList)
		for _, Animation in AnimationsList do
			if Animation:IsA("Animation") then
				local AnimTrack = Animator:LoadAnimation(Animation)
				LoadedAnims[Animation.Name] = AnimTrack
				self.CachedTracks[Animation.Name] = AnimTrack
			end
		end
	elseif typeof(AnimationsList) == "Instance" then
		for _, Animation: Instance in AnimationsList:GetDescendants() do
			if Animation:IsA("Animation") then
				local AnimTrack = Animator:LoadAnimation(Animation)
				LoadedAnims[Animation.Name] = AnimTrack
				self.CachedTracks[Animation.Name] = AnimTrack
			end
		end
	end

	--[[AnimationsAdded.OnClientEvent:Connect(function(Animation: Animation, State: string)
		if State ~= "LoadTrack" then
			return
		end
		local AnimTrack = Animator:LoadAnimation(Animation)
		LoadedAnims[Animation.Name] = AnimTrack
		LoadAnims.CachedTracks[Animation.Name] = AnimTrack
	end)]]

	print(LoadedAnims)

	return LoadedAnims
end

return LoadAnims
