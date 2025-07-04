local module = {}
local SYNCED, HALF_SYNCED, UN_SYNCED = Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 0)

--adapter, observer in one
function module.updateBubble(clientTick, serverTick)
	local character = game.Players.LocalPlayer.Character
	--local bubble    = character:WaitForChild("BubbleHolder")['Desync Bubble']

	local syncMode = nil
	local drift = serverTick - clientTick

	if math.abs(drift) == 3 then
		syncMode = HALF_SYNCED
	elseif math.abs(drift) > 3 then
		print(drift)
		syncMode = UN_SYNCED
	elseif math.abs(drift) < 3 then
		syncMode = SYNCED
	end

	--bubble['Color'].BackgroundColor3 = syncMode
end

return module
