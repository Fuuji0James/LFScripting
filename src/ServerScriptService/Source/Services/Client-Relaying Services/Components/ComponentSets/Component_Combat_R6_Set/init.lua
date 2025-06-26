local DataStoreService = game:GetService("DataStoreService")
local SSS = game:GetService("ServerScriptService")
local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")

local MathChecks = require(SSS.Packages.Utility.MathChecks)
local Promise = require(RS.Libraries.promise)
local GetCombatValuesFor = require(script.GetCombatValues)

local CombatSet = {}
CombatSet.__index = CombatSet

CombatSet.new = function(DataTable)
	local CombatDataValues = DataTable[`{DataTable.Name}DataValues`]
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

	return CombatDataValues
end

local function MovementChanger(WalkSpeed, JumpPower, Character)
	local hum = Character:FindFirstChild("Humanoid")

	hum.WalkSpeed = WalkSpeed
	hum.JumpPower = JumpPower
end

function CombatSet.Attack(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]

	if not MathChecks:timingCheck(DataTable.lastAttacked, DataTable.maxDuration) then
		DataTable.currentCombo = 1
	end

	DataTable.attackPromise = Promise.new(function(resolved, rejected, onCancel)
		DataTable.canBlock = false
		DataTable.canParry = false
		DataTable.canAttack = false

		DataTable.isAttacking = true
		DataTable.isStartUp = true

		onCancel(function()
			MovementChanger(16, 50, DataTable.currentChar)

			DataTable.canAttack = true
			DataTable.canBlock = true
			DataTable.canParry = true

			DataTable.isAttacking = false
			DataTable.isStartUp = false

			DataTable.currentCombo = 1
		end)

		task.wait(0.5)

		resolved()
	end)

	DataTable.attackPromise:andThen(function()
		DataTable.currentCombo += 1
		DataTable.canAttack = true
		DataTable.canBlock = true
		DataTable.canParry = true
		DataTable.lastAttacked = tick()

		if DataTable.currentCombo > 3 then
			DataTable.currentCombo = 1
		end
	end)

	return DataTable
end

function CombatSet.Feint(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]
end

function CombatSet.Critical(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]
end

function CombatSet.Parry(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]
end

function CombatSet.Block(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]
end

function CombatSet.BlockEnd(CurrentComponentTable)
	local DataTable = CurrentComponentTable[`{CurrentComponentTable.Name}DataValues`]
end

return CombatSet
