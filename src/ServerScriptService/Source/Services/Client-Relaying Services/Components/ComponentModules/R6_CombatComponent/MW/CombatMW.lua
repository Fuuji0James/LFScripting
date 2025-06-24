--[[This is the middleware for the combat, it will handle all of the server sided checks to
 verify the client's requests and info]]

local CombatMW = {}

local function valueCheck(Value) -- Utility
	if typeof(Value) == "table" then
		local count = 0

		for i, v in Value do
			if v == true then
				count += 1
				if count == #Value then
					return true
				end
			end
		end
	elseif typeof(Value) == "boolean" then
		if Value then
			return true
		end
	end

	return false
end

local function GetValuesToCheck(CurrentComponent) -- returns needed values from component
	local DataValues = CurrentComponent["Component_Combat_R6DataValues"]

	return {
		["Attack"] = DataValues.canAttack,
		["Feint"] = { DataValues.canFeint, DataValues.isStartUp },
		["Parry"] = DataValues.canParry,
		["Block"] = DataValues.canBlock,
		["BlockEnd"] = DataValues.isBlocking,
		["Critical"] = DataValues.canAttack,
	}
end

function CombatMW:CheckValues(CurrentComponent)
	local ValuesToCheck = GetValuesToCheck(CurrentComponent)

	if not ValuesToCheck then
		warn(`No combat data values were created for player {CurrentComponent.Player}`)
		return
	end

	if valueCheck(ValuesToCheck) and CurrentComponent["Component_Combat_R6DataValues"].isEquipped then
		return true
	else
		return false
	end
end

function CombatMW:VerifyHitbox() end

return CombatMW
