-- {Most Recent: 10/5/2025} //FUUJI
-- Status: Proto

local CS = game:GetService('CollectionService')

return function(Tag: string)
	for _, instance in CS:GetTagged(Tag) do
		if instance:IsA("Folder") then
			return instance
		end
	end
end