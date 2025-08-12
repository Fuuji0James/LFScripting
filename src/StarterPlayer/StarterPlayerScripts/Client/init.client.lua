local RF = game:GetService("ReplicatedFirst")

local Source = RF._Client
local Shared = RF._Shared
local Players = game:GetService("Players")

local LiveMockTestsAllowed = false -- as in PUBLIC GAME mock tests

local MW = script.MW
local ClientReceiversFolder = Source.Receivers

local Char = Players.LocalPlayer.Character or nil

function CharacterAdded(Character)
	if not Character then
		return
	end

	local InitControllers = require(MW:WaitForChild("InitControllers"))

	local Misc = require(MW.Misc)

	InitControllers(Character)

	Misc()

	print("Client Running")

	print(require(Shared._registry))
end

CharacterAdded(Char)

Players.LocalPlayer.CharacterAdded:Connect(CharacterAdded)

local InitReceivers = require(Shared.Utility.InitSR)
InitReceivers(ClientReceiversFolder, LiveMockTestsAllowed)
