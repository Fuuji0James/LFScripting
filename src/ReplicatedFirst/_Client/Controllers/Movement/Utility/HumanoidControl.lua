-- {Most Recent: 9/5/2025} //FUUJI
-- Status: Proto

--*Not a priority rn so I, went to server management on 8/5/2025*-- (fuuji) | other devs cant do ts btw

local Core = game:GetService('ReplicatedFirst').MovementPackages
local Helpers = Core.Shared:WaitForChild('Helpers')
local Enum = require(Helpers.Enums)

--

local CAMERA = game.Workspace.CurrentCamera

--

local HumanoidControl = {}
HumanoidControl.__index = HumanoidControl


function HumanoidControl.new(player)
	local self = {}
	
	self.Character = player.Character
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.HRP = self.Character:WaitForChild("HumanoidRootPart")
	
	self._lockedMoveVector = self.Humanoid.MoveDirection
	self._forcedMoveVector = self.Humanoid.MoveDirection
	self._mode = Enum.HumanoidControlType.Default
	
	return setmetatable(self, HumanoidControl)
end

--

function HumanoidControl:SetMode(newMode: number, moveVec: vector)
	self._mode = newMode
	
	if (newMode == Enum.HumanoidControlType.Locked) then
		self._lockedMoveVector = moveVec
	end
end

function HumanoidControl:GetWorldMoveDirection(wantedMode)
	local currentMode = wantedMode or self._mode
	
	if (currentMode == Enum.HumanoidControlType.Default) then
		return self.Humanoid.MoveDirection
	elseif (currentMode == Enum.HumanoidControlType.Locked) then
		return self._lockedMoveVector
	elseif (currentMode == Enum.HumanoidControlType.Forced or currentMode == Enum.HumanoidControlType.ForcedRespectCamera) then
		local worldMove = self.Humanoid.MoveDirection
		local worldMoveSq = worldMove:Dot(worldMove)
		
		if (currentMode == Enum.HumanoidControlType.ForcedRespectCamera and worldMoveSq == 0) then
			worldMove = (CAMERA.CFrame.lookVector * Vector3.new(1, 0, 1)).unit
			worldMoveSq = 1
		end
		
		local look = self.HRP.CFrame.lookVector
		local realTheta = math.atan2(-look.z, look.x)
		local worldTheta = worldMoveSq > 0 and math.atan2(-worldMove.z, worldMove.x) or realTheta
		
		self._forcedMoveVector = CFrame.fromEulerAnglesYXZ(0, worldTheta, 0) * Vector3.new(1, 0, 0)
		
		return self._forcedMoveVector
	end
end

--

return HumanoidControl