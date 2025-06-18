-- {Most Recent: 10/5/2025} //FUUJI
-- Status: Proto

-- For Debugging
return function()
	local Date = os.date("*t")

	-- Get the time and format it
	local Hour = (Date.hour) % 24
	local AmOrPm = Hour < 12 and "AM" or "PM"
	local Time = string.format("%02i:%02i %s", ((Hour - 1) % 12) + 1, Date.min, AmOrPm)
	
	return Time
end