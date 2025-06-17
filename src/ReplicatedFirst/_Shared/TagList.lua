-- {Most Recent: 10/5/2025} //FUUJI
-- Status: Proto

return {
	-- You don't really have to follow a spesific/rigid format, but don't make it stupid yfm?
		-- InputbufferingServerSide is a dumb name (yes you lucario)
	['PlayerTag'] = "Player_ConstructionService",
	
	Components = { -- Relay Services
		Template = "Component_Temp",
		Movement = "Component_Movement_R6",
		Combat = "Component_Combat_R6",
		Interaction = {
			['Interactable'] = "Interactable_InteractionService"
		}
	};
	Services = { -- Sending-Only Services
		AnimationService = "Service_Animation", 
		ConstructionService = {			
			['Mob'] = "Mob_ConstructionService"
		}
	};
	Folders = { -- So pathing is way easier for things that have multiple folders spread out
		-- I rather it this way so each package can be added and deleted simply, without having to search for anims, audio etc.
		AnimationFolder = "Folder_Animation"
	};
}
