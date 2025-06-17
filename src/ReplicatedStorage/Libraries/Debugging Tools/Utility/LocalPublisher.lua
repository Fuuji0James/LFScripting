-- {Most Recent: 10/5/2025} //FUUJI
-- Status: Prototype

--Used for pubulishing audio, anims | hence it can't be created in game
local CS = game:GetService('CollectionService')
local KeyframeSeqProv = game:GetService('KeyframeSequenceProvider')
local RF = game:GetService('ReplicatedFirst')

local AnimsFolder = unpack(CS:GetTagged("Folder_Animations"))
local DebugFolder = RF.Packs.BasicPackages_Shared.Debugging

local Taglist = require(RF.Packs.BasicPackages_Shared.Helpers.TagList)

local Utility = {
	--Settings
	['KeepKeyframeSequences'] = true
}

--

local function Pub(KeyframeSequence)
	if KeyframeSequence:IsA('KeyframeSequence') then
		local Hash = KeyframeSeqProv:RegisterKeyframeSequence(KeyframeSequence)
		local Anim = Instance.new("Animation", KeyframeSequence.Parent)

		Anim.Name = KeyframeSequence.Name
		Anim.AnimationId = Hash
		KeyframeSequence.Name = KeyframeSequence.Name.."_depricated"

		if not Utility.KeepKeyframeSequences then
			game.Debris:AddItem(KeyframeSequence,0)
		end				
	end
end

function Utility:createLocalAnimationsStudio()
	-- publishes everything (keyframe sequences, audio hopefully)
	for index, AnimFolder: Folder in CS:GetTagged("Folder_Animations") do		
		for _, KeyframeSequence in AnimFolder:GetDescendants() do
			Pub(KeyframeSequence)			
		end
	end
end

function Utility:publishAnimation(KeyframeSequence: KeyframeSequence)
	Pub(KeyframeSequence)
end

--

return Utility
