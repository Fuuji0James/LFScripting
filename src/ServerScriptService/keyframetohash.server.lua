local CS = game:GetService("CollectionService")
local RF = game:GetService("ReplicatedFirst")
local AnimsFolder = unpack(CS:GetTagged("Folder_Animations"))
local KeyFrameSeqLoader = require(RF._Client.Utility.KeyframeSeqLoader)

if not game:GetService("RunService"):IsStudio() then
	return
end

for _, KeyFrame in AnimsFolder:GetDescendants() do
	if KeyFrame:IsA("KeyframeSequence") then
		KeyFrameSeqLoader.createLocalPreview(KeyFrame, KeyFrame.Parent, false)
	end
end
