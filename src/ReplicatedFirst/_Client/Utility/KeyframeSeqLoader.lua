local module = {}
local KeyframeSeqProv = game:GetService("KeyframeSequenceProvider")

module.createHashId = function(KeyframeSequence: KeyframeSequence)
	return KeyframeSeqProv:RegisterKeyframeSequence(KeyframeSequence)
end

module.createLocalPreview = function(KeyframeSequence: KeyframeSequence, Parent: Instance, Save: boolean)
	local Hash = module.createHashId(KeyframeSequence)
	local Anim = Instance.new("Animation", Parent)

	Anim.Name = KeyframeSequence.Name
	Anim.AnimationId = Hash

	if not Save then
		game.Debris:AddItem(KeyframeSequence, 0)
	end

	return Anim
end

return module
