--[[
	This is for the server to validate the client's stuff
]]

return {
	currentCombo = 1,
	maxCombo = 3,
	AnimTime = 0,
	maxDuration = 0.2,

	currentAnimationTrack = nil,
	currentChar = Instance.new("Model"),
	attackPromise = nil,
	parryPromise = nil,
	lastAttacked = tick(),

	isBlocking = false,
	isParrying = false,
	isAttacking = false,
	isWhiffCanceling = false,
	isFeinting = false,
	isStartUp = false,
	isEquipped = false,

	canBlock = true,
	canParry = true,
	canAttack = true,
	canFeint = true,
	WPNmetatable = {},
}
