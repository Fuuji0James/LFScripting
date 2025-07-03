local Source = game:GetService("ServerScriptService").Source

local LiveMockTestsAllowed = true -- as in PUBLIC GAME mock tests
local ServerBasicPackages = script

local MW = script.MW

local PlayerAdded = require(script.Testing.PlayerAdded)
PlayerAdded()

wait(0.5)

require(MW.InitServices)(Source, LiveMockTestsAllowed)
require(MW["ECS-Independent"])()

print("Sever Running")

--if game:GetService("RunService"):IsStudio() then
--	local LocalPublisher = require(DebugFolder.Utility.LocalPublisher)
--	LocalPublisher:createLocalAnimationsStudio()
--end
