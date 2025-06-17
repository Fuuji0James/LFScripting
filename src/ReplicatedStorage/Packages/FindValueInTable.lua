return function(Haystack: {}, Needle, ReturnIdentifier)
	for Identifier, Value in Haystack do
		if not ReturnIdentifier then
			if Value == Needle then
				return Value
			end
		else
			if Value == Needle then
				return Identifier
			end
		end
	end
end
