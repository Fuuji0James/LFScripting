-- {Most Recent: 26/05/2025} // FUUJI
-- Status: Must Edit
-- FP

export type RealBezierFunc = (Time: number) -> vector
export type UsableBezier = (Distance:number) -> vector


export type BezierTable = { ['Bezier'] : UsableBezier, ['TotalLength'] : number, ['BezierID'] : vector, ['Gradient']: vector }	-- Differentiate for readability in the Mathfuncs script
export type CompositeBezierTable = {
	['CompositeBezier']: UsableBezier, 
	['TotalLength'] : number, 
	['BezierStartEndList'] : {BezierID:number, StartDist:number, EndDist: number},
	['CompositeGradient']: (distance:number) -> vector
}																-- Differentiate for readability in the Mathfuncs script

export type ArrayPointProperties = { ['BezierID'] : number, ['Pos'] : vector, ['Distance'] : number }
export type LUT = { {['BezierID']:vector, ['Time']:number, ['Distance']:number} }


--

local Utility = {
	['LUT_Size'] = 300 -- this is PER bezier btw
}
local MathLibrary = require(game.ReplicatedStorage.Libraries.MathModuleV4)

local function GetBinomialCoefficientForControlPoint(n,i): number
	return MathLibrary.fac(n) / (MathLibrary.fac(i) * MathLibrary.fac(n-i))
end

local function isVectorValid(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and v.Magnitude < 1e6
end

--***So binary searches are possible. Adding more values to the LUT makes it smoother
local function CreateLookUpTableForBezier(Bezier: RealBezierFunc, No_Samples, BezierID: number): LUT -- B(t) btw
	local LUT:LUT = {}
	local prevPoint = Bezier(0)
	local AccumulatedLength = 0
	
	for i = 1, No_Samples do
		local t = i / No_Samples
		local p = Bezier(t)
		local dist = (p - prevPoint).Magnitude

		AccumulatedLength += dist
		
		table.insert(LUT, {
			BezierID = BezierID,
			Time = t,
			Distance = AccumulatedLength
		})
		
		prevPoint = p
	end
	
	return LUT, AccumulatedLength
end

--*** This returns the local time for the bezier.
local function DistanceTo_time(LUT: LUT, Distance: number, BezierLength: number): number
	-- Do binary searches here (I actually used chatgpt for this as im still lost on how to do ts)
	
	if Distance <= 0 then return 0 end
	if Distance >= BezierLength then return 1 end
	
	local low, high = 1, #LUT
	
	while low <= high do
		local mid = math.floor((low + high) / 2)		
		local entry = LUT[mid]
		
		if Distance < entry.Distance then
			high = mid - 1
		elseif Distance > entry.Distance then
			low = mid + 1
		else
			return entry.Time
		end
	end

	low = math.clamp(low, 1, #LUT)
	high = math.clamp(high, 1, #LUT)

	local lower = LUT[high]
	local upper = LUT[low]

	local segmentDist = upper.Distance - lower.Distance
	if segmentDist == 0 then
		return lower.Time -- avoid division by zero
	end

	local alpha = (Distance - lower.Distance) / segmentDist
	local t = lower.Time + (upper.Time - lower.Time) * alpha
	
	return t
end

--*** First/Last ControlPointIndex are to be used together at once.
function Utility:CreateBezierFunc(ControlPoints: {vector}, LUT_Size, FirstControlPointIndex: number, LastControlPointIndex: number): BezierTable
	local n = (LastControlPointIndex and FirstControlPointIndex and (LastControlPointIndex - FirstControlPointIndex)) or (#ControlPoints - 1)
	-- recall that "and" only goes to the next check once the previous is true, making the above possible
	
	local binomials = {} -- binomial for each pos. (weighted avarge basically)
	
	for i = 0, n do
		binomials[i] = GetBinomialCoefficientForControlPoint(n, i)
	end
	
	local Bezier: RealBezierFunc = function(t : number)
		if #ControlPoints == 1 then return ControlPoints[1] end
		
		local startIndex = FirstControlPointIndex or 1
		local endIndex = LastControlPointIndex or #ControlPoints
		
		if t == 0 then return ControlPoints[startIndex]
		elseif t == 1 then return ControlPoints[endIndex] end

		local p = vector.zero

		for i = 0, n do
			local controlIndex = startIndex + i
			if not ControlPoints[controlIndex] then continue end

			local WeightAtTime_t = binomials[i] * (t^i) * ((1 - t)^(n - i))
			p += ControlPoints[controlIndex] * WeightAtTime_t
		end

		return p
	end

	local LUT, AccumulatedLength = CreateLookUpTableForBezier(Bezier, LUT_Size or Utility.LUT_Size, FirstControlPointIndex or 1)
	
	local ID = vector.create( 			-- Describes where it starts and ends
		FirstControlPointIndex or 1,			
		LastControlPointIndex or #ControlPoints
	)
	
	local savedSelf = {} -- sometimes small values return nan vectors
	
	return {
		['Bezier'] = function(distance: number) : vector	
			local calculatedPos = Bezier( DistanceTo_time(LUT, distance, AccumulatedLength) )
			
			if not isVectorValid(calculatedPos) then return savedSelf.Position
			else savedSelf.Position = calculatedPos return calculatedPos end
		end,
		['Gradient'] = function(distance: number)
			local curveResolution = #LUT
			local eps = AccumulatedLength / curveResolution / 2 -- half step

			local t1 = DistanceTo_time(LUT, math.clamp(distance - eps, 0, AccumulatedLength), AccumulatedLength)
			local t2 = DistanceTo_time(LUT, math.clamp(distance + eps, 0, AccumulatedLength), AccumulatedLength)
			
			local calculatedGradient = (Bezier(t2) - Bezier(t1)).Unit
			
			if not isVectorValid(calculatedGradient)then return savedSelf.Gradient 
			else savedSelf.Gradient = calculatedGradient return calculatedGradient end			
		end,
		['BezierID'] = ID,
		['TotalLength'] = AccumulatedLength
	}
end


function Utility:CreateCompositeBezier(Beziers: {BezierTable}): CompositeBezierTable
	local AccumulatedLength = 0
	local StartsAndEnds = {}
	
	for i, BezierTable: BezierTable in Beziers do
		local startDist = AccumulatedLength
		local endDist = AccumulatedLength + BezierTable.TotalLength
		
		StartsAndEnds[i] = {['BezierID'] = BezierTable.BezierID, ['StartDist'] = startDist, ['EndDist'] = endDist}
		
		AccumulatedLength += BezierTable.TotalLength
	end
	
	return {
		['CompositeBezier'] = function(distance: number): vector
			
			distance %= AccumulatedLength
			-- Find the segment this distance falls into
			for i, arc in Beziers do
				if distance >= StartsAndEnds[i].StartDist and distance <= StartsAndEnds[i].EndDist then	
					return arc.Bezier(distance - StartsAndEnds[i].StartDist)
				end
			end
	
			-- Fallback //shouldnt reach btw
			warn("Looping distance did not match any Bezier segment")
			return Beziers[#Beziers].Bezier(Beziers[#Beziers].TotalLength)
		end,
		['CompositeGradient'] = function(distance: number): vector
			distance %= AccumulatedLength
			
			for i, arc in Beziers do
				if distance >= StartsAndEnds[i].StartDist and distance <= StartsAndEnds[i].EndDist then			
					return arc.Gradient(distance - StartsAndEnds[i].StartDist)
				end
			end
		end,
		
		['TotalLength'] = AccumulatedLength,
		['BezierStartEndList'] = StartsAndEnds
	}
end

return Utility