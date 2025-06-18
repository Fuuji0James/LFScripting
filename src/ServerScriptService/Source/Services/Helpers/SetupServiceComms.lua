local module = {}

-- Have Name & Prefix, one or the other
function module.SetupFolders (Name, Parent, Prefix)
	-- This sets up all the folders that a given rig/client would use
	
	local AddListenerFolder = function(parent)
		local Folder = Instance.new("Folder")
		Folder.Name = if Prefix then `{Prefix}_Remotes` else Name
		Folder.Parent = parent
		return Folder
	end
	
	return {AddListenerFolder(Parent)}
end

function module.SetupRemotes (Prefix, ListOfEvents: {}, Parent)
	local Remotes = {}

	for Suffix_Name, Type in ListOfEvents do
		local Event = Instance.new(Type[1])

		if Type[1] == "RemoteFunction" then
			local Callback: () -> () = Type[2]
			Event.OnServerInvoke = Callback
		end

		if Type[1] == "BindableFunction" then
			local Callback: () -> () = Type[2]
			Event.OnInvoke = Callback
		end

		Event.Name = if Prefix then `{Prefix}_{Suffix_Name}` else `{Suffix_Name}`
		Remotes[Suffix_Name] = Event
		Event.Parent = Parent
	end

	return Remotes
end

return module
