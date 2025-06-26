local RF = game:GetService("ReplicatedFirst")

local Source = RF._Client
local Shared = RF._Shared
local Players = game:GetService("Players")


local LiveMockTestsAllowed = false -- as in PUBLIC GAME mock tests

local MW = script.MW
local ClientReceiversFolder = Source.Receivers


local Character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()

local InitControllers = require(MW:WaitForChild("InitControllers"))
local InitReceivers   = require(Shared.Utility.InitSR)
local Misc            = require(MW.Misc)

InitControllers(Character)
InitReceivers(ClientReceiversFolder, LiveMockTestsAllowed)
Misc()

print("Client Running")

print(require(Shared._registry))