local hitbox = {}

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

hitbox.__index = hitbox

local adornment_form = { -- Uses parameters given to figure out what data type to use for other functions.
	["Proportion"] = {
		[Enum.PartType.Ball] = "Radius", -- If the shape is a ball, use radius
		[Enum.PartType.Block] = "Size", -- If shape is a block, use size
	},

	["Shape"] = {
		[Enum.PartType.Ball] = "Part", -- This just returns a part and based on the value, the parttype will be different.
		[Enum.PartType.Block] = "Part", --  same here ^
	},
}

hitbox.Create = function() -- returns a metatable with a list of parameters for the hitbox.
	return setmetatable({
		Character = Instance.new("Model"),
		Visualizer = true, -- Whether or not you want it to visualize

		OverlapParams = OverlapParams.new(),
		HitCallBack = function() end,
		Hitlist = {},

		Size = Vector3.new(0, 0, 0), -- Size of the radius/box
		CFrame = CFrame.new(0, 0, 0), -- CFrame of the hitbox
		Shape = Enum.PartType.Block, -- Shape of the hitbox
		ActiveTime = 0.2,
	}, hitbox)
end

function hitbox:Visualize() -- Visualizes the hitbox if the parameter is set to true.
	if not self.Visualizer then
		return
	end

	local hitboxvis
	if self.Shape == Enum.PartType.Block then
		hitboxvis = Instance.new(adornment_form.Shape[self.Shape], workspace)
		hitboxvis.Shape = Enum.PartType.Block
	elseif self.Shape == Enum.PartType.Ball then
		hitboxvis = Instance.new(adornment_form[self.Shape], workspace)
		hitboxvis.Shape = Enum.PartType.Ball
	end
	hitboxvis.Size = self.Size
	RunService:BindToRenderStep("VisUpdHitbox", 50, function()
		hitboxvis.CFrame = self.Character.HumanoidRootPart.CFrame * self.CFrame
	end)

	hitboxvis.BrickColor = BrickColor.new("Really red")
	hitboxvis.CanCollide = false
	hitboxvis.Anchored = true
	hitboxvis.Transparency = 0.5

	task.delay(self.ActiveTime, function()
		Debris:AddItem(hitboxvis, 0)
		RunService:UnbindFromRenderStep("VisUpdHitbox")
	end)
end

-- Returns a spatial query array of parts within the set paramaters.

local spatial_query = {
	[Enum.PartType.Ball] = function(self, chr: Model) -- If the hitbox is a ball.
		local hbCFrame = self.CFrame
		local hbSize = self.Size

		self.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
		self.OverlapParams.FilterDescendantsInstances = chr:GetChildren()

		local inboundparts = workspace:GetPartBoundsInRadius(
			self.Character.HumanoidRootPart.CFrame * hbCFrame,
			hbSize,
			self.OverlapParams
		)

		return inboundparts -- Returns
	end,
	[Enum.PartType.Block] = function(self, chr: Model) -- If the hitbox is a block.
		local hbCFrame = self.CFrame
		local hbSize = self.Size

		self.OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
		self.OverlapParams.FilterDescendantsInstances = chr:GetChildren()

		local inboundparts =
			workspace:GetPartBoundsInBox(self.Character.HumanoidRootPart.CFrame * hbCFrame, hbSize, self.OverlapParams)

		return inboundparts -- Returns
	end,
}

function hitbox:ReturnParts(chr: Model)
	local inboundparts = spatial_query[self.Shape](self, chr) -- Calls the function based on the data that the metatable was given (Shape, etc.)

	return inboundparts -- returns the final array of parts within the radius/box.
end

function hitbox:FindHum(chr: Model)
	local inboundparts = self:ReturnParts(chr) -- gets the returned parts from the function above ^^

	for i, v in pairs(inboundparts) do -- loops through these parts ^
		local e_chr = v.Parent
		local e_hum = e_chr:FindFirstChild("Humanoid")

		if e_hum then -- if the humanoid exists then
			if not self.Hitlist[e_hum] then -- Checks if the humanoid has already been hit
				self.Hitlist[e_hum] = true -- Makes it so that the hitbox only hits once
				return e_hum -- Returns the enemy humanoid that you can act upon in the server script.
			end
		end
	end
	return
end

function hitbox:Start()
	if not self.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local startTime = tick()

	RunService:BindToRenderStep("HitboxActive_" .. tostring(self), Enum.RenderPriority.Last.Value, function()
		local now = tick()
		if now - startTime >= self.ActiveTime then
			RunService:UnbindFromRenderStep("HitboxActive_" .. tostring(self))
			return
		end

		local e_hum = self:FindHum(self.Character)
		if e_hum then
			self.HitCallBack(e_hum) -- Calls the callback function with the enemy humanoid as a parameter.
		end
	end)
end

return hitbox

-- EXAMPLE

--[[

local hitbox = hitbox.Create()

** your hitbox properties ** 
hitbox.Size = Vector3.new(5,4,4)
hitbox.CFrame = HRP.CFrame * CFrame.new(0,0,-5)
hitbox.OverlapParams = OverlapParams.new()
hitbox.Visualizer = false
hitbox.Shape = Enum.PartType.Block / Ball depends on what you want.

** IF YOU WANT VISUALIZER**
hitbox.Visualizer = true
hitbox:Visualize()

** Finding the enemy humanoid

local enemy_humanoid : Humanoid = hitbox:FindHum()

BOOM you get yo enemy humanoid then you can do as you please with it

so like:

    enemy_humanoid:TakeDamage(15)

would be in the server script btw^

]]
