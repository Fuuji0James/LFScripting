local CS = game:GetService("ContentProvider")

local LoadVFX = {
	Registry = {},
}

LoadVFX.__index = LoadVFX

function LoadVFX.new(Player)
	local self = setmetatable({
		Name = Player.Name,
		CachedVFX = {},
	}, LoadVFX)

	LoadVFX.Registry[self.Name] = self

	return self
end

function LoadVFX:PreLoadVFX(VFXList)
	-- clear cached anims
	self.CachedVFX = {}

	local LoadedVFX = {}

	if typeof(VFXList) == "table" then
		for _, VFX in VFXList do
			if VFX:IsA("BasePart") then
				CS:PreloadAsync(VFXList)
				LoadedVFX[VFX.Name] = VFX
				self.CachedVFX[VFX.Name] = VFX
			end
		end
	elseif typeof(VFXList) == "Instance" then
		for _, VFX in pairs(VFXList:GetDescendants()) do
			if VFX:IsA("BasePart") then
				LoadedVFX[VFX.Name] = VFX
				self.CachedVFX[VFX.Name] = VFX
			end
		end
	end

	print(self)

	return LoadedVFX
end

return LoadVFX
