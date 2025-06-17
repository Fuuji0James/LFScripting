local NewMath = {}

----> built-in
NewMath["random"]=math["random"]
NewMath["huge"]=math["huge"]
NewMath["abs"]=math["abs"]
NewMath["sqrt"]=math["sqrt"]
NewMath["min"]=math["min"]
NewMath["rad"]=math["rad"]
NewMath["sign"]=math["sign"]
NewMath["max"]=math["max"]
NewMath["sin"]=math["sin"]
NewMath["fmod"]=math["fmod"]
NewMath["round"]=math["round"]
NewMath["pi"]=math["pi"]
NewMath["cos"]=math["cos"]
NewMath["deg"]=math["deg"]
NewMath["exp"]=math["exp"]
NewMath["log"]=math["log"]
NewMath["pow"]=math["pow"]
NewMath["tan"]=math["tan"]
NewMath["acos"]=math["acos"]
NewMath["asin"]=math["asin"]
NewMath["atan"]=math["atan"]
NewMath["ceil"]=math["ceil"]
NewMath["cosh"]=math["cosh"]
NewMath["modf"]=math["modf"]
NewMath["sinh"]=math["sinh"]
NewMath["tanh"]=math["tanh"]
NewMath["atan2"]=math["atan2"]
NewMath["clamp"]=math["clamp"]
NewMath["floor"]=math["floor"]
NewMath["frexp"]=math["frexp"]
NewMath["ldexp"]=math["ldexp"]
NewMath["log10"]=math["log10"]
NewMath["noise"]=math["noise"]
NewMath["randomseed"]=math["randomseed"]
----> constants
NewMath["tau"]=NewMath.pi*2
NewMath["null"]=-NewMath.huge
NewMath["e"]=NewMath.exp(1)
NewMath["phi"]=((1+(5^0.5))/2)
NewMath["nan"]=0/0
--> V3 constants
NewMath["px"]=0.264583333333333
NewMath["rt2"]=2^0.5
NewMath["g"]=9.807
NewMath["psi"]=(1/3*(1+(((29+3*((93)^0.5))/2)^(1/3))+(((29-3*((93)^0.5))/2)^(1/3))))
NewMath["p"]=(((9+(69^0.5))/18)^(1/3)+((9-(69^0.5))/18)^(1/3))
NewMath["eps"]=((8.854187817)*(10^-12))
--> V4 constants
NewMath["gel"]=NewMath.e^NewMath.pi
NewMath["gAngle"]=NewMath.tau/(NewMath.phi^2)
NewMath["ln2"]=NewMath.log(2)
NewMath["G"]=3.62560990822190822191^2/(2*((2*(NewMath.pi^3))^0.5))
NewMath["varpi"]=NewMath.pi*NewMath.G
NewMath["P"]=NewMath.log(1+NewMath.rt2)+NewMath.rt2
NewMath["mu"]=(2+2^0.5)^0.5
NewMath["C10"]=0.12345678910111213
NewMath["mAngle"]=NewMath.atan(NewMath.rt2)
NewMath["beta"]=(NewMath.pi^2)/(12*NewMath.ln2)
NewMath["ebeta"]=NewMath.e^NewMath.beta
----> functions
NewMath["circum"]=function(r: number)
	return NewMath.tau*r
end
NewMath["cbrt"]=function(x: number)
	return x^(1/3)
end
NewMath["root"]=function(x: number,root: number)
	return x^(1/root)
end
NewMath["fac"]=function(x: number)
	if x == 0 then
		return 1
	end
	local y = x
	for i = 1,x-1 do
		y=y*i
	end
	return y
end
NewMath["avg"]=function(...: number)
	local n = 0
	for _,i in {...} do
		n += i
	end
	n /= #{...}
	return n
end
NewMath["sum"]=function(min: number,max: number,formula: (number)->number?)
	local n = 0
	for i = min,max do
		if formula then
			n += formula(i)
		else
			n += i
		end
	end
	return n
end
NewMath["tetr"]=function(x: number,y: number)
	local n = x
	if not y then
		y = 2
	end
	if y == 0 then
		return 1
	elseif y == -1 then
		return 0
	end
	for i = 1,y-1 do
		n = x^n
	end
	return n
end
NewMath["pent"]=function(x: number,y: number)
	local n = x
	if not y then
		y = 2
	end
	for i = 1,y-1 do
		n = NewMath.tetr(x,n)
	end
	return n
end
--> V3 functions
NewMath["product"]=function(min: number,max: number,formula: (number)->number?)
	local n = 1
	for i = min,max do
		if formula then
			n *= formula(i)
		else
			n *= i
		end
	end
	return n
end
NewMath["rec"]=function(x: number)
	return 1/x
end
NewMath["zer"]=function(z: number)
	return 10^z
end
NewMath["gamma"]=function(x: number)
	return NewMath.fac(x-1)
end
NewMath["dgt"]=function(x: number)
	local nums = {0,1,2,3,4,5,6,7,8,9}
	local digits = {}
	for i,v in tostring(x):split("") do
		if table.find(nums,tonumber(v)) then
			table.insert(digits,tonumber(v))
		end
	end
	return digits
end
NewMath["chance"]=function(x: number)
	local rnd = NewMath.random(1,NewMath.clamp(x,1,10^32))
	if rnd == 1 then
		return rnd
	else
		return rnd*0
	end
end
NewMath["range"]=function(...: number)
	return NewMath.max(...)-NewMath.min(...)
end
NewMath["note"]=function(x: number)
	local rlen = NewMath.floor(NewMath.log10(NewMath.floor(x)))
	local rlen2 = rlen
	rlen2 -= rlen2%3
	return ("%.f"):format(tostring(NewMath.floor(x))):sub(1,(rlen%3)+1)..require(14327149989)[rlen2]
end
NewMath["prime"]=function(x: number)
	for i = 1,x do
		if i ~= 1 and i ~= x then
			if x%i==0 then
				return false
			end
		end
	end
	return true
end
NewMath["yrandom"]=function(x: number)
	return NewMath.random(NewMath.random(0,x),x)
end
NewMath["xrandom"]=function(x: number)
	return NewMath.random(0,NewMath.random(0,x))
end
NewMath["zeta"]=function(x: number)
	local y = 0
	for i = 1,NewMath.clamp(x*10^4,1,10^10) do
		y += (NewMath.rec(i^x))
	end
	return y
end
--> V4 Functions
NewMath["frac"]=function(x: number)
	return x-NewMath.floor(x)
end
NewMath["binary"]=function(x: number)
	local s = ''
	local y = x
	while NewMath.floor(y) > 0 do
		local data = y/2
		y = NewMath.floor(data)
		s ..= NewMath.sign(NewMath.frac(data))
	end
	if NewMath.floor(y) == 0 then
		s = s:reverse()
	end
	return tonumber(s)
end
NewMath["frombinary"]=function(x: number)
	local s = tostring(NewMath.floor(x)):reverse():split('')
	local n = 0
	for x,v in s do
		local i = tonumber(v)
		if i==1 then
			n += 2^(x-1)
		end
	end
	return n
end
NewMath["pct"]=function(x: number, p: number)
	return x*(p/100)
end
NewMath["coprime"]=function(x: number,y: number)
	for i = 1,NewMath.min(x,y) do
		if i ~= 1 then
			if x%i == 0 and y%i == 0 then
				return false
			end
		end
	end
	return true
end
NewMath["slope"]=function(x: number, y: number, formula: (number)->number?)
	return (formula(y)-formula(x))/(y-x)
end
NewMath["superfac"]=function(x: number)
	if x == 0 then
		return 1
	end
	local y = NewMath.fac(x)
	for i = 1,x-1 do
		y=y*(NewMath.fac(i))
	end
	return y
end
NewMath["hyperfac"]=function(x: number)
	if x == 0 then
		return 1
	end
	local y = x^x
	for i = 1,x-1 do
		y=y*(i^i)
	end
	return y
end
NewMath["approx"]=function(x: number,y: number,range: number)
	return NewMath.abs(x-y)<=range
end
NewMath["primecount"]=function(x: number)
	local p = 0
	for i = 1,x do
		if i ~= 1 then
			if NewMath.prime(i)==true then
				p=p+1
			end
		end
	end
	return p
end
NewMath["rep"]=function(x: number,t: number,formula: (number)->number?)
	for i = 1,t do
		x = formula(x)
	end
	return x
end
NewMath["arcfac"]=function(x: number)
	local y = 0
	for i = 1,x do
		x=x/i
		y+=1
		if x == 1 then
			return y
		end
	end
	return NewMath.nan
end
NewMath["diag"]=function(...: number)
	local q = 0
	for _,n in {...} do q+=n^2 end
	return q^.5
end
NewMath["lambertW"]=function(x: number)
	local epsilon = NewMath.eps
	local result = x
	local var = x
	local limit = NewMath.zer(3)
	local r = 0
	while r < limit do
		local exp = NewMath.e^result
		local xexp = result * exp
		local f = xexp - x
		local fPrime = exp * (result + 1)
		var = result
		result = result - f / fPrime
		if NewMath.abs(result-var) < epsilon then
			return result
		end
		r += 1
	end
	return result
end
NewMath["ssrt"]=function(x: number)
	return NewMath.exp(NewMath.lambertW(NewMath.log(x,NewMath.e)))
end
--> Converting [V4]
NewMath["toFah"]=function(x: number)
	return (x-32)*(5/9)
end
NewMath["toCel"]=function(x: number)
	return x*(5/9)+32
end
NewMath["toIn"]=function(x: number)
	return x*0.3937007874
end
NewMath["toCm"]=function(x: number)
	return x/0.3937007874
end
NewMath["toLb"]=function(x: number)
	return x*2.20462262
end
NewMath["toKg"]=function(x: number)
	return x/2.20462262
end
--> Trigonometry [V4]
NewMath["cot"]=function(x: number)
	return 1/NewMath.tan(x)
end
NewMath["sec"]=function(x: number)
	return 1/NewMath.cos(x)
end
NewMath["csc"]=function(x: number)
	return 1/NewMath.sin(x)
end
NewMath["acot"]=function(x: number)
	return (-NewMath.atan(x))+NewMath.pi/2
end
NewMath["asec"]=function(x: number)
	return NewMath.acos(1/x)
end
NewMath["acsc"]=function(x: number)
	return NewMath.asin(1/x)
end
NewMath["coth"]=function(x: number)
	return NewMath.cosh(x)/NewMath.sinh(x)
end
NewMath["sech"]=function(x: number)
	return 1/NewMath.cosh(x)
end
NewMath["csch"]=function(x: number)
	return 1/NewMath.sinh(x)
end
NewMath["asinh"]=function(x: number)
	return NewMath.log(x+NewMath.sqrt(x^2+1))
end
NewMath["acosh"]=function(x: number)
	return NewMath.log(x+NewMath.sqrt(x^2-1))
end
NewMath["atanh"]=function(x: number)
	return NewMath.log((1+x)/(1-x))/2
end
NewMath["acoth"]=function(x: number)
	return NewMath.log((x+1)/(x-1))/2
end
NewMath["asech"]=function(x: number)
	return NewMath.log(NewMath.rec(x)+NewMath.sqrt(1/(x^2)-1))
end
NewMath["acsch"]=function(x: number)
	return NewMath.log(NewMath.rec(x)+NewMath.sqrt(1/(x^2)+1))
end
----> Sequences [V4]
NewMath["harmonic"]=function(x: number)
	return NewMath.sum(1,x,NewMath.rec)
end
NewMath["fibonacci"]=function(x: number)
	local r,f,y,z = x-1,0,1,0
	for i = 0,r do
		z = f
		f = (f+y)
		y = z
	end
	return f
end
NewMath["triangular"]=function(x: number)
	return NewMath.sum(0,NewMath.floor(x))
end
NewMath["leonardo"]=function(x: number)
	if x == 0 or x == 1 then
		return 1
	else
		return NewMath.leonardo(x-1)+NewMath.leonardo(x-2)+1
	end
end
NewMath["pell"]=function(x: number)
	if NewMath.floor(x) == 0 or NewMath.floor(x) == 1 then
		return NewMath.floor(x)
	else
		return 2*NewMath.pell(NewMath.floor(x)-1)+NewMath.pell(NewMath.floor(x)-2)
	end
end
NewMath["tetrahedral"]=function(x: number)
	return NewMath.sum(1,NewMath.floor(x),NewMath.triangular)
end
NewMath["pentatope"]=function(x: number)
	return NewMath.sum(1,NewMath.floor(x),NewMath.tetrahedral)
end
NewMath["sylvester"]=function(x: number)
	if NewMath.floor(x) == 0 or NewMath.floor(x) == 1 then return 2+NewMath.floor(x) end
	return NewMath.product(1,NewMath.floor(x)-1,NewMath.sylvester)+1
end
--> Calculus [V4]
NewMath["derivative"]=function(formula: (number)->number?): <formula>(number)-> number?
	return (function(x: number) return NewMath.slope(x,x+NewMath.eps/10,formula) end)
end
NewMath["integral"]=function(min: number, max: number, formula: (number)->number?)
	local c = 1e-5
	local a = 0
	for v = min,max,c do
		a += formula(v)*c
	end
	return a
end

return NewMath