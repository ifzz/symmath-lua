--[[
base class for all symmath.tostring options
example usage:
symmath.tostring = require 'symmath.tostring.***' for *** any subclass of ToString

I made this before I made the symmath.Visitor parent class, so consider merging those.
--]]

require 'ext'

local ToString = class()

function ToString:apply(expr, ...)
	if type(expr) ~= 'table' then return tostring(expr) end
	local lookup = expr.class
	-- traverse class parentwise til a key in the lookup table is found
	while lookup and not self.lookupTable[lookup] do
		lookup = lookup.super
	end
	if not lookup then error("expected to find a lookup") end
	return (self.lookupTable[lookup])(self, expr, ...)
end

-- separate the __call function to allow child classes to permute the final output without permuting intermediate results
-- this means internally classes should call self:apply() rather than self() to prevent extra intermediate permutations 
function ToString.__call(self, ...)
	return self:apply(...)
end

local function precedence(x)
	if x.precedence then return x.precedence end
	return 10
end

function ToString:testWrapStrOfChildWithParenthesis(parentNode, childIndex)
	local subOp = require 'symmath.subOp'
	if parentNode:isa(subOp) and childIndex > 1 then
		return precedence(parentNode.xs[childIndex]) <= precedence(parentNode)
	else
		return precedence(parentNode.xs[childIndex]) < precedence(parentNode)
	end
end

function ToString:wrapStrOfChildWithParenthesis(parentNode, childIndex)
	local node = parentNode.xs[childIndex]
	
	-- tostring() needed to call MultiLine's conversion to tables ...
	--local s = tostring(node)
	local s = self:apply(node)
	
	if self:testWrapStrOfChildWithParenthesis(parentNode, childIndex) then
		s = '(' .. s .. ')'
	end
	return s
end

return ToString

