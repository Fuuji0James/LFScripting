-- Have Name & Prefix, one or the other
return function(Name, Parent, Prefix)
	-- This sets up all the folders that a given rig/client would use
	
	local AddListenerFolder = function(parent)
		local Folder = Instance.new("Folder")
		Folder.Name = if Prefix then `{Prefix}_Remotes` else Name
		Folder.Parent = parent
		return Folder
	end
	
	return {AddListenerFolder(Parent)}
end