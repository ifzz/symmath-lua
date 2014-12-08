#!/usr/bin/env luajit
--[[
Hooke's spring law:
hamiltonian = (|x_1 - x_2| - restLength)

x'' = -(k/m)(x-s) = 
--]]

local dim = 1	-- or 2 or 3 or whatever
local numParticlesToCreate = 3

local vec
if dim >= 2 and dim <= 4 then
	vec = require('vec.vec'..dim)	-- ... includes special case stuff per dimension
else
	local createVectorClass = require 'vec.create'
	vec = createVectorClass(dim)	-- nothing extra
end

local symmath = require 'symmath'
symmath.tostring = require 'symmath.tostring.MathJax'
print(require'symmath.tostring.MathJax'.header)

local Particle = class()

-- underscores mean symmath variable, no-underscore means 'number' variable

-- index = index in EnergySystem.particles
function Particle:init(index)
	self.index = index
	self.qVar = vec()	-- position symbolic
	self.pVar = vec()	-- momentum symbolic
	for i=1,dim do
		self.qVar[i] = symmath.var('q_{'..self.index..','..i..'}', {t})
		self.pVar[i] = symmath.var('p_{'..self.index..','..i..'}', {t})
	end
	self.q = vec()	-- position numeric
	self.p = vec()	-- momentum numeric
	self.m = 1	-- constant, so might as well use a number  
end

local EnergySystem = class()

function EnergySystem:init()
	self.particles = table()
end

function EnergySystem:createParticle()
	local v = Particle(#self.particles+1)
	self.particles:insert(v)
	return v
end

function EnergySystem:buildSymbolicParams()
	local symbolicParams = table()
	for i,v in ipairs(self.particles) do
		for k=1,dim do
			symbolicParams:insert{[v.qVar[k]] = 'q_'..i..'_'..k}	-- position
			symbolicParams:insert{[v.pVar[k]] = 'p_'..i..'_'..k}	-- velocity
		end
	end
	return symbolicParams
end

-- matches the order above
function EnergySystem:buildNumericParams()
	local numericParams = table()
	for i,v in ipairs(self.particles) do
		for k=1,dim do
			numericParams:insert(v.q[k])	-- position
			numericParams:insert(v.p[k])	-- velocity
		end
	end
	return numericParams
end

-- define particles in the system
local system = EnergySystem()

for i=1,numParticlesToCreate do
	system:createParticle()
end

-- kinetic energy
local K = symmath.Constant(0)
for _,v in ipairs(system.particles) do
	K = K + v.pVar:lenSq() / (2 * v.m)
end
--K = K:simplify()
-- kinetic terms are all linear, so don't mess with it

-- potential energy
local restLength = 1
local k = .1	-- spring constant
local U = symmath.Constant(0) 

-- ... and then, upon evaluation, I'll calculate them and evaluate the system 
for i,v1 in ipairs(system.particles) do
	for j,v2 in ipairs(system.particles) do
		if v1 ~= v2 then
			U = U + (symmath.sqrt((v1.qVar - v2.qVar):lenSq()) - restLength)^2
		end
	end
end
U = k / 2 * U
--U = U:simplify()

-- Hamiltonian
local H = K + U

--[[
... if K is a function of of p alone ... and U is a function of q alone ... 
then there really isn't a need to add them together and say ...
	p' = -dH/dq, q' = dH/dp
because dH/dq is only dU/dq and dH/dp = dK/dp
so the system simplifies one step into
	p' = -dU/dq, q' = dK/dp
--]]
--system:setHamiltonian(H)

-- save params for later.
-- the upside to this is no math required -- the CAS does it all for you
-- the downside is, well, at the moment you have to recompile every time a new particle is added.
-- considering how linear an oscillator is, I'm sure this could be eliminated 
-- (esp if I was storing spring edges somewhere, rather than making all particles share)
local symbolicParams = system:buildSymbolicParams()
print('symbolic params',unpack(symbolicParams:map(function(v)
	local k = unpack(table.keys(v))
	return tostring(k)..'='..v[k]
end)))
print('<br>')

-- and now each particle has its evolution equations
print('Hamiltonian', H, '<br>')
-- compile evolution equations
for i,v in ipairs(system.particles) do
	-- dq/dt = dH/dp is a function of p1..pn ... and maybe q1..qn
	v.dq_dt = vec()
	v.dp_dt = vec()
	v.dq_dt_var = vec()
	v.dp_dt_var = vec()
	for k=1,dim do
		-- notice: each of these ends up with d[distance]/dq variables
		-- the best way to deal with them is substituting them for the linear components of their value 

		local dH_dp = H:diff(v.pVar[k]):simplify()
		v.dq_dt_var[k] = dH_dp
print('\\({{dq_{'..i..','..k..'}}\\over {dt}} = \\)', v.dq_dt_var[k], '<br>')
		v.dq_dt[k] = dH_dp:compile(symbolicParams)
	
		local _dH_dq = (-H):diff(v.qVar[k]):simplify()
		v.dp_dt_var[k] = _dH_dq
print('\\({{dp_{'..i..','..k..'}}\\over {dt}} = \\)', v.dp_dt_var[k], '<br>')
		v.dp_dt[k] = _dH_dq:compile(symbolicParams)
	end
end

-- and integrate ... forward Euler

local ts = table()
local columns = table()
for i,v in ipairs(system.particles) do 
	for j=1,dim do
		columns[v.qVar[j].name] = table()		-- graph for position
		columns[v.pVar[j].name] = table()		-- graph for velocity
	end
end

-- initialize the numeric side of things
system.particles[1].q[1] = 1
system.particles[2].q[1] = -1
system.particles[3].q[1] = 0

local dt = .1
local n = 10000
local t = 0

--[[

ODE:
dx/dt = f(t,x)

forward Euler integrator:
( x(t+dt) - x(t) ) / dt = f(t,x)
x(t+dt) = x(t) + dt * f(t,x)

backward Euler integrator:
x(t+dt) - dt * f(t+dt, x(t+dt)) = x(t)

...for multiple variables...
x_i(t+dt) - dt * f_i(t+dt, x_j(t+dt)) = x_i(t)
... makes a nonlinear system ...
... assume I - dt * f_i(x_j) (specifically f_i(x_j)) can be linearized as a_ij x_j + b_i 


--]]

for i=1,n do
	for _,v in ipairs(system.particles) do
		-- forward Euler integration
		for j=1,dim do
			v.q[j] = v.q[j] + dt * v.dq_dt[j](unpack(system:buildNumericParams()))
			v.p[j] = v.p[j] + dt * v.dp_dt[j](unpack(system:buildNumericParams()))
			columns[v.qVar[j].name]:insert(v.q[j])
			columns[v.pVar[j].name]:insert(v.p[j])
		end
	end
	t = t + dt
	ts:insert(t)
end

-- TODO replace with your own graphing output *here*, like pipe to a text file and render in gnuplot or something
-- TODO in the JS, replace plot2d with a canvas-based plotting mechanism
local plot2d = require 'plot2d'
plot2d(columns:map(function(v,k)
	return { enabled = true, ts, v}
end))

