--[[
	This is for the server to validate the client's stuff
]]

return {
	currentCombo = 1,
	maxCombo = 3,
	maxDuration = 1,

	attackWalkspeed = 8,
	attackJumpPower = 25,

	postureAmount = 0,
	maxPosture = 100,

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
	isCounterable = false,

	canBlock = true,
	canParry = true,
	canAttack = true,
	canFeint = true,

	-- Weapon Specific Values
	wpnType = "Greatsword", -- Type of weapon, add later
	wpnName = "Greatsword",
	wpnAnimationSet = {},
	wpnHitboxSize = Vector3.new(5, 5, 5),
}
