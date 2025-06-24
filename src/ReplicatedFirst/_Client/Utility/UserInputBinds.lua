-- {Most Recent: 12/5/2025} //FUUJI
-- Status: Prototype

--*Thank you ego moose!!*-- (fuuji)

--

local UIS = game:GetService("UserInputService")

--

local Utility = {}
Utility.__index = Utility

function Utility.new()
	local self = {}

	self.connections = {}

	return setmetatable(self, Utility)
end

--

-- The args after the callback are the keycodes and whatnot to bind to
function Utility:BindToInput(actionName, func, ...)
	local binds = { ... }
	self.connections[actionName] = {}

	for i = 1, #binds do
		local keycode = binds[i]
		self.connections[actionName][keycode] = {
			UIS.InputBegan:Connect(function(input, processed)
				if input.KeyCode == keycode or input.UserInputType == keycode then
					local _, E = pcall(function()
						func(actionName, input.UserInputState, input, processed)
					end)

					if E then
						print(E)
					end
				end
			end),

			UIS.InputChanged:Connect(function(input, processed)
				if input.KeyCode == keycode or input.UserInputType == keycode then
					local _, E = pcall(function()
						func(actionName, input.UserInputState, input, processed)
					end)

					if E then
						print(E)
					end
				end
			end),

			UIS.InputEnded:Connect(function(input, processed)
				if input.KeyCode == keycode or input.UserInputType == keycode then
					local _, E = pcall(function()
						func(actionName, input.UserInputState, input, processed)
					end)

					if E then
						print(E)
					end
				end
			end),
		}
	end
end

function Utility:BindDoubleTap(Timeout: number, ActionName: string, Callback: () -> (), ...)
	local BindList = { ... } -- table of keycodes

	if self.connections[ActionName] then
		warn(`Action name: "{ActionName}" is already in use by an unknown keycode. Expect errors.`)
	else
		self.connections[ActionName] = {}
	end

	for _, keycode: string in BindList do
		self.connections[ActionName][keycode] = {
			["LastPressed"] = 0,

			UIS.InputBegan:Connect(function(input, proccess)
				if
					(input.KeyCode == keycode)
					and (tick() - self.connections[ActionName][keycode].LastPressed) <= Timeout
				then
					Callback(proccess, ActionName, input.UserInputState, input)
				end

				self.connections[ActionName][keycode].LastPressed = tick()
			end),

			UIS.InputChanged:Connect(function(input, proccess)
				if
					(input.KeyCode == keycode)
					and (tick() - self.connections[ActionName][keycode].LastPressed) <= Timeout
				then
					Callback(proccess, ActionName, input.UserInputState, input)
				end

				self.connections[ActionName][keycode].LastPressed = tick()
			end),

			UIS.InputEnded:Connect(function(input, proccess)
				if
					(input.KeyCode == keycode)
					and (tick() - self.connections[ActionName][keycode].LastPressed) <= Timeout
				then
					Callback(proccess, ActionName, input.UserInputState, input)
				end

				self.connections[ActionName][keycode].LastPressed = tick()
			end),
		}
	end
end

function Utility:UnbindAction(ActionName)
	for keycode, array in next, self.connections[ActionName] do
		for _, connection in array do
			connection:Disconnect()
		end
	end

	self.connections[ActionName] = nil
end

--

return Utility.new()
