#!/usr/bin/env luajit

--[[
I thought it'd be a good idea to show off how to use expression compiling for symbolic+numeric integration
It looks like I need to integrate a function that depends on the state variable (y) as well as the parameter (x) in order to take advantage of implicit integration
--]]

-- explicit integration:

--[[
f = function
x = dependent variable
x0 = start
x1 = end
n = number of divisions (default 200)
--]]

local function euler(f, x, x0, x1, n)
	n = n or 200
	local y = f(x0)
	local dx = (x1 - x0) / n
	for i=1,n do
		local xv = i / n * (x1 - x0) + x0
		-- dy/dx = f(x)
		-- (y(x+dx) - y(x))/dx = f(x)
		-- y(x+dx) = y(x) + dx * f(x)
		y = y + dx * f(xv)
	end
	return y
end

local function midpoint(f, x, x0, x1, n)
	n = n or 200
	local y = f(x0)
	local dx = (x1 - x0) / n
	for i=1,n do
		local xv = (i + .5) / n * (x1 - x0) + x0
		y = y + dx * f(xv)
	end
	return y
end

local function trapezoid(f, x, x0, x1, n)
	n = n or 200
	local y = f(x0)
	local dx = (x1 - x0) / n
	for i=1,n do
		local xv = i / n * (x1 - x0) + x0
		local ytilde = y + dx * f(xv)
		y = y + dx/2 * (f(xv) + f(xv + dx))
	end
	return y
end

local function simpson(f, x, x0, x1, n)
	n = math.floor((n or 200) / 2) * 2
	local dx = (x1 - x0) / n
	local y = dx/3 * (f(x0) + 4 * f(x0+dx))
	for i=2,n-1,2 do
		local xv = i/n * (x1 - x0) + x0
		y = y + dx/3 * (2 * f(xv) + 4 * f(xv+dx))
	end
	y = y + dx/3 * f(x1)
	return y
end

local symmath = require 'symmath'
local x = symmath.var'x'		-- x-variable
local f = x^2					-- symbolic function
local df = f:diff(x)()			-- symbolic function derivative
local t0 = 0					-- start time
local t1 = 1					-- end time
local n = 100					-- number of iterations
local norm = math.abs			-- norm

local _f = f:compile{x}			-- numeric function

for _,method in ipairs{
	euler,
	midpoint,
	trapezoid,
	simpson,
} do
	local dt = (t1 - t0) / n
	local t = t0
	local _x = _f(t)			-- numeric value
	local err = 0
	for i=1,n do
		local correctX = _f(t)
		local diffX = _x - correctX
		local normDiff = norm(diffX)
		err = err + normDiff
print(t,_x,correctX,err,'<br>')
		
		_x = method(_f, _x, _x+dt, n)
		t = t + dt
	end
end

