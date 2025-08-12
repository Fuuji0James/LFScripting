local Workspace = game:GetService("Workspace")
local Source = game:GetService("ServerScriptService").Source

local LiveMockTestsAllowed = false -- as in PUBLIC GAME mock test

local MW = script.MW

local PlayerAdded = require(script.Testing.PlayerAdded)
PlayerAdded()

require(MW.InitServices)(Source, LiveMockTestsAllowed)
require(MW["ECS-Independent"])()

print("Sever Running")
Workspace:SetAttribute("ServerLoaded", true)

--if game:GetService("RunService"):IsStudio() then
--	local LocalPublisher = require(DebugFolder.Utility.LocalPublisher)
--	LocalPublisher:createLocalAnimationsStudio()
--end

local ComponentHandler = require(game:GetService("ServerScriptService").Packages.ComponentHandler)
local NPCHB = game.Workspace.NPCHitbox

wait(3)

local component = ComponentHandler.GetComponentsFromInstance(
	NPCHB,
	require(game:GetService("ReplicatedFirst")._Shared.TagList).Components.Combat
)

component.Component_Combat_R6DataValues.isParrying = true

while true do
	task.wait(1)
	component = ComponentHandler.GetComponentsFromInstance(
		NPCHB,
		require(game:GetService("ReplicatedFirst")._Shared.TagList).Components.Combat
	)

	print(component.Component_Combat_R6DataValues.postureAmount)
end
