local ComponentHandler = require(game:GetService('ServerScriptService').Packages.ComponentHandler)

local function InitHookedServies(LiveMockTestsAllowed, Service)
	--coroutine.wrap(function()
		if Service:IsA("ModuleScript") and not (string.match(Service.Name, "^__Template")) then
			local Ms = require(Service)

			if typeof(Ms) == 'table' then
				if (Ms.new and Ms.Run and (not Ms.Tag)) then -- has a life cycle, and doesn't have a tag for components
					local MockTestMs 			= if Service:FindFirstChild("MockTests") then require(Service:WaitForChild('MockTests')) else nil
					local MockTestingConfig: {} =  nil
					local TestThisService 		= false

					if MockTestMs then
						if Ms.TestingFlag then
							if (LiveMockTestsAllowed) or (LiveMockTestsAllowed == false and game:GetService('RunService'):IsStudio()) then
								TestThisService = true

								if (MockTestMs.SetupTestConfig) then 
									MockTestingConfig = MockTestMs:SetupTestConfig()

									if not MockTestingConfig then print(`Mock tests should return their config? | Take off the testing flag to silence. @{Service}`)
									end
								end	
							end
						end

						local ServiceMs = Ms.new(MockTestingConfig) -- using it (its nil if conditions arent met BTW)

						ServiceMs:Run()


						if TestThisService then
							MockTestMs:StartTest(ServiceMs) -- do ur own scenario or wtv
						end

						--Ms.IsRunning = true -- make sure all services have this

					if ServiceMs.OnClose then game:BindToClose(function() ServiceMs:OnClose() end) end -- some services use alot of mem, so they may need this so shutdown times are lower
					
					end
				end
			end
		end
	--end)()	
end	

return function(Source, LiveMockTestsAllowed)
	local ClientRelaying = Source.Services["Client-Relaying Services"]
	local ClientSending = Source.Services["Client-Sending Services"]
	
	-- Client Relaying servies
	local ComponentsToLoad = ClientRelaying.Components.ComponentModules:GetChildren()
	
	for _, moduleScript in ComponentsToLoad do
		local reqMS = require(moduleScript)
		if reqMS.Init then reqMS:Init() end
	end
	
	ComponentHandler.AddComponentToGame(ComponentsToLoad)
	
	
	for _, Service in ClientRelaying.Misc:GetDescendants() do
		InitHookedServies(LiveMockTestsAllowed, Service)
	end
	
	-- Client sending services
	for _, Service in ClientSending:GetDescendants() do
		InitHookedServies(LiveMockTestsAllowed, Service)
	end
end