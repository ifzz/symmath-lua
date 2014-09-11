require 'ext'
require 'symmath'
symmath.toStringMethod = symmath.ToLaTeX
symmath.simplifyDivisionByPower = true

local oldPrint = print
local function print(...)
	local str = table{...}:map(function(s)
		if type(s) == 'table'
		and s.isa
		and s:isa(symmath.Expression)
		then
			return "\\("..tostring(s).."\\)"
		end
		return tostring(s)
	end):concat('\t')
	oldPrint(str..'<br>')
end

-- header 

print[[
<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8">
        <title>MHD Symmetrization</title>
        <script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>
    </head>
    <body>
]]

-- functions

function sum(f,first,last,step)
	step = step or 1
	local total
	for i=first,last,step do
		if not total then 
			total = f(i)
		else
			total = total + f(i)
		end
	end
	return total
end

-- variables

do
	local isGreek = ('rho gamma mu'):split('%s+'):map(function(v) return true,v end)
	local varNames = 'x y z t rho vx vy vz p P Z E Bx By Bz gamma mu c cs cf ca'
	print('variables:', varNames)
	for _,var in ipairs(varNames:split('%s+')) do
		local varname = var
		-- LaTeX greek symbols
		if isGreek[varname] then varname = '\\' .. varname end
		-- subscript
		if #varname > 1 and varname:match('[xyz]$') then varname = varname:sub(1,-2)..'_'..varname:sub(-1) end
		_G[var] = symmath.Variable(varname, nil, true)
	end
end

local vs = table{vx, vy, vz}
local Bs = table{Bx, By, Bz}
local xs = table{x,y,z}

local vDotB = sum(function(i) return vs[i] * Bs[i] end, 1, 3)
local divB = sum(function(i) return symmath.diff(Bs[i], xs[i]) end, 1, 3)
local BSq = sum(function(i) return Bs[i]^2 end, 1, 3)
local vSq = sum(function(i) return vs[i]^2 end, 1, 3)

-- relations

print('relations')

local Z_from_E_B_rho_mu = symmath.equals(Z, E + 1 / (2 * rho * mu) * BSq)
print(Z_from_E_B_rho_mu)

local P_from_p_B_mu = symmath.equals(P, p + 1 / (2 * mu) * BSq)
print(P_from_p_B_mu)

local p_from_E_rho_v_gamma = symmath.equals(p, (gamma - 1) * rho * (E - 1/symmath.Constant(2) * vSq))
print(p_from_E_rho_v_gamma)

local cSq_from_p_rho_gamma = symmath.equals(c^2, gamma * p / rho)
print(cSq_from_p_rho_gamma)

-- equations

local continuityEqn = symmath.equals(symmath.diff(rho, t) + sum(function(j) 
	return symmath.diff(rho*vs[j], xs[j])
end,1,3), 0)

print()
print('continuity')
print(continuityEqn)

local momentumEqns = range(3):map(function(i)
	return symmath.equals(
		symmath.diff(rho * vs[i], t) + sum(function(j)
			return symmath.diff(rho * vs[i] * vs[j] - 1/mu * Bs[i] * Bs[j], xs[j])
		end, 1,3)
		+ symmath.diff(P, xs[i]),
		-- ... equals ...
		-1/mu * Bs[i] * divB)
end)

print()
print('momentum')
momentumEqns:map(function(eqn) print(eqn) end)

local magneticFieldEqns = range(3):map(function(i)
	return symmath.equals(
		symmath.diff(Bs[i], t) + sum(function(j)
			return symmath.diff(vs[j] * Bs[i] - vs[i] * Bs[j], xs[j])
		end, 1,3),
		-- ... equals ...
		-vs[i] * divB)
end)

print()
print('magnetic field')
magneticFieldEqns:map(function(eqn) print(eqn) end)

local energyTotalEqn = symmath.equals(
	symmath.diff(rho * Z, t) + sum(function(j)
		return (rho * Z + p) * vs[j] - 1/mu * vDotB * Bs[j]
	end, 1, 3),
	-- ... equals ...
	-1/mu * vDotB * divB)

print()
print('energy total')
print(energyTotalEqn)

-- expand system

local allEqns = table()
	:append{continuityEqn}
	:append(momentumEqns)
	:append(magneticFieldEqns)
	:append{energyTotalEqn}
	:map(function(eqn)
		return symmath.simplify(eqn)
	end)

print()
print('all')
allEqns:map(function(eqn) print(eqn) end)

-- conservative variables



-- footer

print[[
	</body>
</html>
]]