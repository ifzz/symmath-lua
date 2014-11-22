require 'ext'
local BinaryOp = require 'symmath.BinaryOp'
local nodeCommutativeEqual = require 'symmath.nodeCommutativeEqual'

-- equality
-- I would use binary operators for this, but Lua's overloading requires the return value be a boolean
local EquationOp = class(BinaryOp)
EquationOp.__eq = nodeCommutativeEqual
EquationOp.solve = require 'symmath.solve'

function EquationOp:evaluateDerivative(...)
	local diff = require 'symmath'.diff
	local result = getmetatable(self)()
	for i=1,#self.xs do
		result.xs[i] = diff(self.xs[i]:clone(), ...)
	end
	return result
end

function EquationOp:lhs() return self.xs[1] end
function EquationOp:rhs() return self.xs[2] end

-- a = b => b = a
-- should probably overload this for >= and <= to switch the sides
function EquationOp:switch()
	local a,b = unpack(self.xs)
	return b:equals(a)
end

-- cause operators to apply immdiately, and to apply to both sides

-- TODO switch equality sign for non-equals equation ops? same with scaling by negatives?
function EquationOp.__unm(a)
	a = a:clone()
	a.xs = a.xs:map(function(x) return -x end)
	return a
end

for _,op in ipairs{
	{field = '__add', f = function(a,b) return a + b end},
	{field = '__sub', f = function(a,b) return a - b end},
	{field = '__mul', f = function(a,b) return a * b end},
	{field = '__div', f = function(a,b) return a / b end},
	{field = '__pow', f = function(a,b) return a ^ b end},
	{field = '__mod', f = function(a,b) return a % b end},
} do
	EquationOp[op.field] = function(a,b)
		local Constant = require 'symmath.Constant'
		if type(a) == 'number' then a = Constant(a) end
		if type(b) == 'number' then b = Constant(b) end
		if a:isa(EquationOp) and not b:isa(EquationOp) then
			a = a:clone()
			if a.xs then a.xs = a.xs:map(function(x) return op.f(x, b) end) end
			return a
		end
		if not a:isa(EquationOp) and b:isa(EquationOp) then
			b = b:clone()
			if b.xs then b.xs = b.xs:map(function(x) return op.f(a, x) end) end
			return b
		end
	end
end

return EquationOp

