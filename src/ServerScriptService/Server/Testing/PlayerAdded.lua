-- {Most Recent: 13/5/2025} //FUUJI
-- Status: Proto

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GetDOS = require(script.Parent.GetDOS)
local Tags = require(game:GetService("ReplicatedFirst")._Shared.TagList)

local function onCharacterAdded(Chr)
	local player = Players:GetPlayerFromCharacter(Chr)

	if not player then
		return
	end

	while not Workspace:GetAttribute("ServerLoaded") do
		warn("Server not loaded yet, delaying tag addition for: " .. player.Name)
		Workspace:GetAttributeChangedSignal("ServerLoaded"):Wait()
	end

	print("Player added: " .. player.Name)

	-- Track the character with the Dynamic Octree System

	GetDOS.DOS:Track(Chr, 0.1)

	-- Adds tags to the character model
	Chr:AddTag(Tags.PlayerTag)
	Chr:AddTag(Tags.Components.Combat)

	Chr:SetAttribute("UserId", player.UserId)

	Chr:FindFirstChildOfClass("Humanoid").Died:Once(function()
		for index, componentTag in Chr:GetTags() do
			for _, comparisonTag in Tags.Components do
				if componentTag == componentTag then
					Chr:RemoveTag(componentTag)
				end
			end
		end
	end)
end

local function OnPlayerAdded(Player: Player)
	local RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = Player

	Player.CharacterAdded:Connect(onCharacterAdded)
end

local function safePlayerAdded(callback: (Player) -> ())
	for _, player in Players:GetPlayers() do
		task.spawn(callback, player)
	end

	return Players.PlayerAdded:Connect(callback)
end

return function()
	safePlayerAdded(OnPlayerAdded)
end
