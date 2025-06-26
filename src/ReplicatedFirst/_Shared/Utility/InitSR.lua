-- Inits services/modules

local _Shared = game:GetService("ReplicatedFirst"):WaitForChild("_Shared")
local RunService = game:GetService("RunService")

local ProxyHandler	   = require(_Shared:WaitForChild("Utility"):WaitForChild("proxytable"))
local _registry 	   = require(_Shared:WaitForChild("_registry"))

local function InitHookedService_Receiver(LiveMockTestsAllowed, ModuleScript)
	--coroutine.wrap(function()
	if ModuleScript:IsA("ModuleScript") and not (string.match(ModuleScript.Name, "^__Template")) then
				local RequiredModule = require(ModuleScript)
	
				if (RequiredModule.new and RequiredModule.Run and (not RequiredModule.Tag)) then -- has a life cycle, and doesn't have a tag for components
					local MockTestMs 			= if ModuleScript:FindFirstChild("MockTests") then require(ModuleScript:WaitForChild('MockTests')) else nil
					local MockTestingConfig: {} =  nil
					local TestThisModule 		= false

					if MockTestMs then
						if RequiredModule.TestingFlag then
							if (LiveMockTestsAllowed) or (LiveMockTestsAllowed == false and game:GetService('RunService'):IsStudio()) then
								TestThisModule = true

								if (MockTestMs.SetupTestConfig) then 
									MockTestingConfig = MockTestMs:SetupTestConfig()

									if not MockTestingConfig then print(`Mock tests should return their config? | Take off the testing flag to silence. @{ModuleScript}`)
									end
								end
							end
						end

						-- making a proxy for them				
						local _moduleData = RequiredModule.new(MockTestingConfig) -- data gained from module
						local Module = ProxyHandler.new(ModuleScript.Name, _moduleData)
						
						_registry[ModuleScript.Name] = Module

						Module:Run()

						if TestThisModule then
							MockTestMs:StartTest(Module) -- do ur own scenario or wtv
						end

						--Ms.IsRunning = true -- make sure all modules have this
						
						if not (RunService:IsClient()) then
							if Module.OnClose then game:BindToClose(function() Module:OnClose() end) end -- some services use alot of mem, so they may need this so shutdown times are lower          
						end
					end
				end
			end
	--end)()
end

---

return function (Folder, LiveMockTestsAllowed)
	for _, ModuleScript in Folder:GetDescendants() do
		InitHookedService_Receiver(LiveMockTestsAllowed, ModuleScript)
	end
end