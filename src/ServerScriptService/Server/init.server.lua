
local Source = game:GetService("ServerScriptService").Source

local LiveMockTestsAllowed = false -- as in PUBLIC GAME mock test

local MW = script.MW

local PlayerAdded = require(script.Testing.PlayerAdded)
PlayerAdded()

require(MW.InitServices) (Source, LiveMockTestsAllowed)
require(MW['ECS-Independent']) ()

print("Sever Running")

--if game:GetService("RunService"):IsStudio() then
--	local LocalPublisher = require(DebugFolder.Utility.LocalPublisher)
--	LocalPublisher:createLocalAnimationsStudio()
--end

