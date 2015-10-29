#!/usr/bin/env luajit
--[[

    File: linearized_euler_hydrodyanamic_equations.lua

    Copyright (C) 2013-2014 Christopher Moore (christopher.e.moore@gmail.com)
	  
    This software is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.
  
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  
    You should have received a copy of the GNU General Public License along
    with this program; if not, write the Free Software Foundation, Inc., 51
    Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

--]]

local symmath = require 'symmath'
local MathJax = require 'symmath.tostring.MathJax'
symmath.tostring = MathJax
MathJax.usePartialLHSForDerivative = true

local function printbr(...)
	print(...)
	print('<br>')
end

-- dimension variables
local t, x, y, z = symmath.vars('t', 'x', 'y', 'z')

-- primitive variables
local rho = symmath.var('\\rho', {t,x,y,z})	-- density
local ux = symmath.var('u_x', {t,x,y,z})		-- velocity
local uy = symmath.var('u_y', {t,x,y,z})
local uz = symmath.var('u_z', {t,x,y,z})
local e = symmath.var('e', {t,x,y,z})		-- total specific energy 

-- state variable
local q1 = symmath.var('q_1', {t,x,y,z})
local q2 = symmath.var('q_2', {t,x,y,z})
local q3 = symmath.var('q_3', {t,x,y,z})
local q4 = symmath.var('q_4', {t,x,y,z})
local q5 = symmath.var('q_5', {t,x,y,z})

local gamma = symmath.var('\\gamma')
local ek = .5 * (ux * ux + uy * uy + uz * uz)	-- kinetic specific energy
local ei = e - ek								-- internal specific energy
local P = (gamma - 1) * rho * ei				-- pressure
local E = rho * e								-- total energy

print(MathJax.header)

-- ...equal zero
printbr('original equations:')
local diff = symmath.diff
local eqns = table{
	symmath.equals(diff(rho     , t) + diff(rho * ux         , x) + diff(rho * uy         , y) + diff(rho * uz         , z), 0),
	symmath.equals(diff(rho * ux, t) + diff(rho * ux * ux + P, x) + diff(rho * ux * uy    , y) + diff(rho * ux * uz    , z), 0),
	symmath.equals(diff(rho * uy, t) + diff(rho * uy * ux    , x) + diff(rho * uy * uy + P, y) + diff(rho * uy * uz    , z), 0),
	symmath.equals(diff(rho * uz, t) + diff(rho * uz * ux    , x) + diff(rho * uz * uy    , y) + diff(rho * uz * uz + P, z), 0),
	symmath.equals(diff(rho * e , t) + diff((E + P) * ux     , x) + diff((E + P) * uy     , y) + diff((E + P) * uz     , z), 0),
}
-- TODO don't simplify differentiation
eqns = eqns:map(function(eqn) 
	return symmath.simplify(eqn)--, {exclude={symmath.Derivative}}) 
end)
eqns:map(function(eqn) printbr(eqn) end)

printbr('substituting state variables:')
eqns = eqns:map(function(eqn)
	eqn = symmath.replace(eqn, rho, q1)
	eqn = symmath.replace(eqn, ux, q2 / q1)
	eqn = symmath.replace(eqn, uy, q3 / q1)
	eqn = symmath.replace(eqn, uz, q4 / q1)
	eqn = symmath.replace(eqn, e, q5 / q1)
	--eqn = symmath.simplify(eqn)
	return eqn
end)
eqns:map(function(eqn) printbr(eqn) end)

printbr('simplify & expand')
eqns = eqns:map(symmath.simplify)
eqns:map(function(eqn) printbr(eqn) end)

-- [[
printbr('factor derivatives')
eqns = eqns:map(function(eqn)
	return symmath.factor(eqn, {
		symmath.diff(q1, x),
		symmath.diff(q2, x),
		symmath.diff(q3, x),
		symmath.diff(q4, x),
		symmath.diff(q5, x)
	})
end)
eqns:map(function(eqn) printbr(eqn) end)
--]]

print(MathJax.footer)

-- ... factor?  provide a list of expressions to factor by ... to get our matrix?
