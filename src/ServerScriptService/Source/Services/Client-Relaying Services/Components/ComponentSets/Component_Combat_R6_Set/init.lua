local ContentProvider = game:GetService("ContentProvider")
local SSS = game:GetService("ServerScriptService")
local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")

local TagList = require(RF._Shared.TagList)
local MathChecks = require(SSS.Packages.Utility.MathChecks)
local Promise = require(RS.Libraries.promise)
local ComponentHandler = require(SSS.Packages.ComponentHandler)
local _registry = require(RF._Shared._registry)
local GetCombatValuesFor = require(script.GetCombatValues)
local PreloadAnimations = require(SSS.Packages.Utility.PreloadAnimations)

local CombatSet = {}
CombatSet.__index = CombatSet

CombatSet.new = function(DataTable)
	local CombatDataValues = DataTable[`{DataTable.Name}DataValues`]
	local AnimationFolder = RF._Client.Animations[TagList.Controllers.Combat]
	local CombatValues = GetCombatValuesFor(DataTable["IsClient"])
	local ProxyCombatValues = {}

	if not CombatDataValues then
		CombatDataValues = setmetatable({ Proxy = ProxyCombatValues }, {
			__index = function(self, index)
				local ProxyCombatValues = rawget(self, "Proxy") -- gets the result from the 'self/proxy table'

				if ProxyCombatValues[index] ~= nil then
					--print(`{index} was accessed`)
				else
					--error(`{index} is not a valid member of `..tostring(self), tostring(self)) -- errors the table & index
				end

				return ProxyCombatValues[index]
			end,
			__newindex = function(self, index, value)
				local ProxyCombatValues = rawget(self, "Proxy") -- gets the result from the 'self/proxy table'

				if ProxyCombatValues[index] == nil then
					if value == nil then
						--print(`{index} was unset`)
					elseif ProxyCombatValues[index] ~= value then
						--print(`{index} was changed`)
					end
				else
					--print(`{index} was set`)
				end

				ProxyCombatValues[index] = value

				return value
			end,
		}) -- Initializes it if it didnt exist before
	end

	--rawset(ProxyCombatValues, 'Changed', DataTable['Listeners']['DataValuesChanged'].Event)

	for i, v in CombatValues do
		CombatDataValues[i] = v -- Cant set the values to eachother for obv reasons
	end

	local WPNAnimations = AnimationFolder[CombatDataValues.wpnName] -- WPN animation
	if WPNAnimations then
		CombatDataValues.wpnAnimationSet = PreloadAnimations(
			WPNAnimations,
			DataTable["IsClient"].Character.Humanoid.Animator
				or DataTable["IsClient"].Character:FindFirstChildOfClass("Animator")
		) -- Preload the animations
	else
		warn(`Weapon animations for {CombatDataValues.wpnName} not found!`)
	end

	return CombatDataValues
end

local function MovementChanger(WalkSpeed, JumpPower, Character)
	local hum = Character:FindFirstChild("Humanoid")

	hum.WalkSpeed = WalkSpeed
	hum.JumpPower = JumpPower
end

function CombatSet.Attack(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]
	local RecieveHumanoidEvent =
		RS.Comms[`{TagList.Components.Combat}_Remotes`][`{TagList.Components.Combat}_ClientToServerEvent`]
	if not MathChecks:timingCheck(DataTable.lastAttacked, DataTable.maxDuration) then
		DataTable.currentCombo = 1
	end

	DataTable.attackPromise = Promise.new(function(resolved, rejected, onCancel)
		DataTable.canBlock = false
		DataTable.canParry = false
		DataTable.canAttack = false

		DataTable.isAttacking = true
		DataTable.isStartUp = true

		DataTable.currentAnimationTrack = DataTable.wpnAnimationSet[`Attack{DataTable.currentCombo}`]

		print(DataTable.currentAnimationTrack)

		onCancel(function() -- If feinted
			DataTable.canAttack = true
			DataTable.canBlock = true
			DataTable.canParry = true

			DataTable.isAttacking = false
			DataTable.isStartUp = false

			DataTable.currentCombo = 1
		end)

		CurrentComponentTable["Connections"]["Attack"] = RecieveHumanoidEvent.OnServerEvent:Connect( -- When server recieves the humanoid from attack
			function(plr, ene_humanoid)
				local ParticleService = _registry["ParticleService"]
				local AnimationService = _registry["AnimationService"]
				print("attack received")
				if
					not MathChecks:dotCheck(CurrentComponentTable.IsClient.Character, ene_humanoid.Parent)
					or not MathChecks:magnitudeCheck(CurrentComponentTable.IsClient.Character, ene_humanoid.Parent)
				then
					print("attack rejected")
					return
				end
				local Ene_CombatComponent =
					ComponentHandler.GetComponentsFromInstance(ene_humanoid.Parent.Parent, TagList.Components.Combat)
				local Ene_CombatDataValues = Ene_CombatComponent["Component_Combat_R6DataValues"]
				if Ene_CombatDataValues.isParrying then
					rejected(Ene_CombatDataValues, Ene_CombatComponent)
				elseif Ene_CombatDataValues.isBlocking then
					print("you got blocked")
				else
					local ene_HRP = ene_humanoid.Parent:FindFirstChild("HumanoidRootPart")

					AnimationService:PlayAnimationOnRig(CurrentComponentTable["IsClient"], ene_humanoid.Parent, "Stun1")
					ParticleService:PlayVFXAt(
						{ ene_HRP.RootAttachment },
						"DismantleProjectile",
						CFrame.new(0, 0, 0),
						10,
						10
					)
					ene_humanoid.Health -= 5
				end
			end
		)

		local Active = DataTable.currentAnimationTrack:GetTimeOfKeyframe("Active")
		local ActiveEnd = DataTable.currentAnimationTrack:GetTimeOfKeyframe("ActiveEnd")

		task.wait(Active)

		DataTable.isStartUp = false

		task.wait(ActiveEnd - Active)

		resolved()
	end)

	DataTable.attackPromise:andThen(function()
		if CurrentComponentTable["Connections"]["Attack"] then
			CurrentComponentTable["Connections"]["Attack"]:Disconnect()
		end

		DataTable.currentCombo += 1
		DataTable.canAttack = true
		DataTable.canBlock = true
		DataTable.canParry = true
		DataTable.lastAttacked = tick()
		DataTable.currentAnimationTrack = nil
		if DataTable.currentCombo > 3 then
			DataTable.currentCombo = 1
		end
	end)

	return DataTable
end

function CombatSet.Feint(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]

	if DataTable.canFeint and DataTable.isStartUp then
		DataTable.attackPromise:cancel()
		local _promise = Promise.new(function(resolve, reject, onCancel)
			DataTable.canFeint = false
			task.wait(2.5)
			DataTable.canFeint = true
			resolve()
		end)
	end

	return DataTable
end

function CombatSet.Critical(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]

	return DataTable
end

function CombatSet.Parry(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]

	DataTable.parryPromise = Promise.new(function(resolve, reject, onCancel)
		DataTable.canParry = false
		DataTable.canAttack = false

		DataTable.isParrying = true
		DataTable.currentAnimationTrack = DataTable.wpnAnimationSet["ParryAnim"]

		onCancel(function() -- Start Blocking
			DataTable.isParrying = false
			DataTable.isBlocking = true

			DataTable.currentAnimationTrack = DataTable.wpnAnimationSet["BlockAnim"]

			DataTable.canBlock = false
			DataTable.canParry = false
			DataTable.canAttack = false
		end)

		task.wait(DataTable.currentAnimationTrack.Length + 0.2)
		resolve()
	end)

	DataTable.parryPromise:andThen(function()
		DataTable.canParry = true
		DataTable.canAttack = true
		DataTable.isParrying = false

		DataTable.currentAnimationTrack = nil
	end)

	return DataTable
end

function CombatSet.Block(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]

	if DataTable.parryPromise then
		DataTable.parryPromise:cancel()
	end

	return DataTable
end

function CombatSet.BlockEnd(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]

	DataTable.isBlocking = false

	DataTable.canBlock = true
	DataTable.canParry = true
	DataTable.canAttack = true

	return DataTable
end

return CombatSet
