#! /usr/bin/env luajit

local symmath = require 'symmath'
local Tensor = require 'symmath.Tensor'
local MathJax = require 'symmath.tostring.MathJax'
symmath.tostring = MathJax
print(MathJax.header)

local var = symmath.var
local vars = symmath.vars

local function printbr(...)
	print(...)
	print'<br>'
end

local t,x,y,z = vars('t', 'x', 'y', 'z')
local coords = {t,x,y,z}

Tensor.coords{
	{
		variables = coords,
	},
	{
		variables = {x,y,z},
		symbols = 'ijklmn',
		metric = {{1,0,0},{0,1,0},{0,0,1}},
	},
}

local alpha = 1
printbr('lapse = '..alpha)

local v = var('v', {t,x,y,z})
printbr('warp bubble velocity = '..v)

local f = var('f', {t,x,y,z})
printbr('some function = '..f)

local betaVar = var'\\beta'
local beta = Tensor('^i', -v*f, 0, 0)
printbr('shift '..betaVar'^i':eq(beta'^i'()))

local gammaVar = var'\\gamma'
local gamma = Tensor('_ij', {1,0,0}, {0,1,0}, {0,0,1})
printbr'spatial metric:'
printbr(gammaVar'_ij':eq(gamma'_ij'()))
printbr(gammaVar'^ij':eq(gamma'^ij'()))

local gVar = var'g'
local g = Tensor'_ab'
--[[
g['_tt'] = -alpha^2 + beta'^i' * beta'^j' * gamma'_ij'
g['_it'] = beta'^i' / alpha^2
g['_ti'] = beta'^i' / alpha^2
g['_ij'] = gamma'^ij' - beta'^i' * beta'^j' / alpha^2
--]]
g[{1,1}] = -alpha^2
for i=1,3 do
	g[{i+1,1}] = beta[i] / alpha^2
	g[{1,i+1}] = beta[i] / alpha^2
	for j=1,3 do
		g[{1,1}] = g[{1,1}] + beta[i] * beta[j] * gamma[{i,j}]
		g[{i+1,j+1}] = gamma'^ij'()[{i,j}] - beta[i] * beta[j] / alpha^2
	end
end
g=g()

Tensor.metric(g)

printbr'4-metric:'
printbr(gVar'_ab':eq(g'_ab'()))
printbr(gVar'^ab':eq(g'^ab'()))

local GammaVar = var'\\Gamma'
local Gamma = ((g'_ab,c' + g'_ac,b' - g'_bc,a') / 2)()
printbr(GammaVar'_abc':eq(Gamma'_abc'()))
Gamma = Gamma'^a_bc'()
printbr(GammaVar'^a_bc':eq(Gamma'^a_bc'()))

local dx = Tensor('^u', function(u) return var('\\dot{x}^'..coords[u].name) end)
local d2x = Tensor('^u', function(u) return var('\\ddot{x}^'..coords[u].name) end)
printbr'geodesic:'
-- TODO unravel equaliy, or print individual assignments
printbr(((d2x'^a' + Gamma'^a_bc' * dx'^b' * dx'^c'):eq(Tensor('^u',0,0,0,0)))())
printbr()

print(MathJax.footer)
