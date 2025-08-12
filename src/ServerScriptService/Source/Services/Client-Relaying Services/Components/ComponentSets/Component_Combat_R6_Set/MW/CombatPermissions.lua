-- an abstraction to make the changing of different data values look cleaner

local Permissions = {}

function Permissions:AttackStart(DataValues)
	DataValues.canBlock = false
	DataValues.canParry = false
	DataValues.canAttack = false

	DataValues.isAttacking = true
	DataValues.isStartUp = true

	DataValues.currentAnimationTrack = DataValues.wpnAnimationSet[`Attack{DataValues.currentCombo}`]
end

return Permissions
