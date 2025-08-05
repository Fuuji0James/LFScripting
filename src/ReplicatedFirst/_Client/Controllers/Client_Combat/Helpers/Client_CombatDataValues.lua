--[[This is for the data values that the CLIENT verifies, 
the server has access to these and more in order to validate everything]]

return {
	-- Combo Tracking
	currentCombo = 1, -- Predictive combo index (corrected by server)
	maxCombo = 3, -- Max combo allowed (copied from server)

	-- Cooldowns & Timing
	lastAttackTime = 0, -- Timestamp of last attack

	-- Ability Flags (used for UI / control responsiveness)
	canAttack = true, -- Can attack (set by server or inferred)
	canBlock = true,
	canParry = true,
	canFeint = false,

	-- Equip State (for visuals or UI restrictions)
	isEquipped = true,

	-- Optional Predictive Flags (used for animations or VFX)
	isAttacking = false,
	isBlocking = false,
	isParrying = false,

	-- Animation
	currentAnim = nil, -- Track current playing animation if needed

	-- Parry Connection
	parryConnection = nil,
}
