--[[
	This is for the server to validate the client's stuff
]]

return {
	currentCombo = 1,
	maxCombo = 3,
	AnimTime = 0,
	maxDuration = 1,

	currentAnimationTrack = nil,
	currentChar = Instance.new("Model"),
	attackPromise = nil,
	parryPromise = nil,
	lastAttacked = tick(),

	isBlocking = false,
	isParrying = false,
	isAttacking = false,
	isFeinting = false,
	isStartUp = false,
	isEquipped = true,

	canBlock = true,
	canParry = true,
	canAttack = true,
	canFeint = true,

	-- Weapon Specific Values
	-- wpnType = "Greatsword", -- Type of weapon, add later
	wpnName = "Greatsword",
	wpnAnimationSet = {},
	wpnHitboxSize = Vector3.new(5, 5, 5),
}
