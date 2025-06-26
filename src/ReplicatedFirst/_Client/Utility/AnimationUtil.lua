local CS = game:GetService("ContentProvider")

local LoadAnims = {
	CachedTracks = {},
	CachedAnims = {},
}

function LoadAnims:PreloadAnims(AnimationsList: {})
	-- clear cached anims
	LoadAnims.CachedAnims = {}

	local LoadedAnims = {}

	if typeof(AnimationsList) == "table" then
		for _, Animation in AnimationsList do
			if Animation:IsA("Animation") then
				CS:PreloadAsync(AnimationsList)
				LoadedAnims[Animation.Name] = Animation
				LoadAnims.CachedAnims[Animation.Name] = Animation
			end
		end
	elseif typeof(AnimationsList) == "Instance" then
		for _, Animation: Instance in AnimationsList:GetDescendants() do
			if Animation:IsA("Animation") then
				CS:PreloadAsync({ Animation })
				LoadedAnims[Animation.Name] = Animation
				LoadAnims.CachedAnims[Animation.Name] = Animation
			end
		end
	end

	--[[AnimationsAdded.OnClientEvent:Connect(function(Animation: Animation, State: string)
		if State == "LoadTrack" then
			return
		end
		CS:PreloadAsync({ Animation })
		LoadedAnims[Animation.Name] = Animation
		LoadAnims.CachedAnims[Animation.Name] = Animation
	end)]]

	return LoadedAnims
end

function LoadAnims:LoadAnimsOnTrack(AnimationsList: {}, Animator: Animator)
	-- clear cached tracks
	LoadAnims.CachedTracks = {}

	local LoadedAnims = {}

	AnimationsList = LoadAnims:PreloadAnims(AnimationsList)

	if typeof(AnimationsList) == "table" then
		for _, Animation in AnimationsList do
			if Animation:IsA("Animation") then
				local AnimTrack = Animator:LoadAnimation(Animation)
				LoadedAnims[Animation.Name] = AnimTrack
				LoadAnims.CachedTracks[Animation.Name] = AnimTrack
			end
		end
	elseif typeof(AnimationsList) == "Instance" then
		for _, Animation: Instance in AnimationsList:GetDescendants() do
			if Animation:IsA("Animation") then
				local AnimTrack = Animator:LoadAnimation(Animation)
				LoadedAnims[Animation.Name] = AnimTrack
				LoadAnims.CachedTracks[Animation.Name] = AnimTrack
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

	return LoadedAnims
end

return LoadAnims
