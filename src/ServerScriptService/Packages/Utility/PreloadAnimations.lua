local ContentProvider = game:GetService("ContentProvider")

return function(AnimationFolder, Animator: Animator) -- DataTable is the component, AnimationFolder is the folder containing animations
	if AnimationFolder then
		local LoadedAnims = {}
		for i, v in AnimationFolder:GetChildren() do
			if v:IsA("Animation") then
				ContentProvider:PreloadAsync({ v }) -- Preloads the animation
				LoadedAnims[v.Name] = Animator:LoadAnimation(v) -- Loads the animation on the animator
			end
		end
		return LoadedAnims
	else
		warn(`Animations for {AnimationFolder.Name} not found!`)
		return nil
	end
end
