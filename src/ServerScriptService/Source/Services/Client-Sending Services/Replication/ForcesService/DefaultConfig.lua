local LoggedData = {}

return {
	["Settings"] = {
		["ForwardCheck"] = 3,
		["spatialCollisionCheck"] = 10,
		["LUT_Size"] = 1000,

		["framesPerCycle"] = 5, -- frames each cycle will take to complete
		["maxUpdateDistance"] = 100,
		["mediumUpdateDistance"] = 300,
		["collisionCheckRadius"] = 5,
	},
	["Adapters"] = { -- change underlying code & would produce a different effect
		["getAlignments"] = function(part, att0, att1)
			local alignPos, alignOri = Instance.new("AlignPosition", part), Instance.new("AlignOrientation", part)

			alignPos.Attachment0 = att0
			alignPos.Attachment1 = att1
			alignPos.Responsiveness = 500
			alignPos.MaxForce = math.huge
			-- alignPos.RigidityEnabled = true

			alignOri.Attachment0 = att0
			alignOri.Attachment1 = att1
			alignOri.Responsiveness = 50
			-- alignOri.RigidityEnabled = true

			return alignPos, alignOri
		end,
	},
	["Observers"] = { -- doesn't affect operation of code, and simply visualizes/logs whatever
		["Logger"] = function(data)
			table.insert(LoggedData, data)
			print(data)
		end,
		["ResyncSent"] = function() end,
		["PlayerConnectedToService"] = function() end,
		["PendingResyncs"] = function() end,
		["PendingResyncsAgain"] = function() end,
		["NoLongerPendingResyncs"] = function() end,
		["TickChanged"] = function(self, CurrentTick) end,
	},
}
