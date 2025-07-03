-- {Most Recent: 13/5/2025} //FUUJI
-- Status: Proto

local Players = game:GetService("Players")
local Tags = require(game:GetService("ReplicatedFirst")._Shared.TagList)

local function onCharacterAdded(Chr)
	local player = Players:GetPlayerFromCharacter(Chr)

	print("duh")

	if not player then
		return
	end

	Chr:AddTag(Tags.PlayerTag)
	Chr:AddTag(Tags.Components.Combat)
	--Chr:AddTag(Tags.Components.Template)

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

	print("du")

	return Players.PlayerAdded:Connect(callback)
end

return function()
	safePlayerAdded(OnPlayerAdded)
end
