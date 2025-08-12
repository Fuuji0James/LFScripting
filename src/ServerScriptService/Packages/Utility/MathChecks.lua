local Checks = {}

function Checks:timingCheck(lastTapped, maxDuration)
	if tick() - lastTapped <= maxDuration then
		return true
	end
	return false
end

function Checks:magnitudeCheck(Character, Ene_Character)
	local ourHRP = Character.HumanoidRootPart
	local ene_HRP = Ene_Character.HumanoidRootPart

	local Dist = (ourHRP.Position - ene_HRP.Position).Magnitude

	if Dist <= 8 then
		return true
	else
		return false
	end
end

function Checks:dotCheck(Character, Ene_Character)
	local ourHRP = Character.HumanoidRootPart
	local ene_HRP = Ene_Character.HumanoidRootPart

	local ourLookVector = ourHRP.CFrame.LookVector
	local plrtoEnemy = (ene_HRP.Position - ourHRP.Position).Unit

	local dotProduct = plrtoEnemy:Dot(ourLookVector)
	print(dotProduct)
	if dotProduct >= 0.5 then
		return true
	else
		return false
	end
end

return Checks
