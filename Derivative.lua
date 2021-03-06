--[[
self[1] is the expression
all subsequent children are variables
--]]

local class = require 'ext.class'
local table = require 'ext.table'
local Expression = require 'symmath.Expression'

local Derivative = class(Expression)
Derivative.precedence = 4

function Derivative:init(...)
	local Variable = require 'symmath.Variable'
	local vars = table{...}
	local expr = assert(vars:remove(1), "can't differentiate nil")
	assert(#vars > 0, "can't differentiate against nil")
	vars:sort(function(a,b) return a.name and b.name and a.name < b.name end)
	Derivative.super.init(self, expr, table.unpack(vars))
end

Derivative.visitorHandler = {
	Eval = function(eval, expr)
		error("cannot evaluate derivative"..tostring(expr)..".  try replace()ing derivatives.")
	end,

	Prune = function(prune, expr)
		local symmath = require 'symmath'
		local Constant = symmath.Constant
		local Array = symmath.Array
		local Variable = symmath.Variable

		-- d/dx{y_i} = {dy_i/dx}
		if Array.is(expr[1]) then
			local res = expr[1]:clone()
			for i=1,#res do
				res[i] = prune:apply(res[i]:diff(table.unpack(expr, 2)))
			end
			return res
		end

		-- d/dx c = 0
		if Constant.is(expr[1]) then
			return Constant(0)
		end

		-- d/dx d/dy = d/dxy
		if Derivative.is(expr[1]) then
			return prune:apply(Derivative(expr[1][1], table.unpack(
				table.append({table.unpack(expr, 2)}, {table.unpack(expr[1], 2)})
			)))
		end

		-- apply differentiation
		-- don't do so if it's a diff of a variable that requests not to
		-- [[
		if Variable.is(expr[1]) then
			local var = expr[1]
			-- dx/dx = 1
			if #expr == 2 and var == expr[2] then
				return Constant(1)
			end
			--dx/dy = 0 unless x is a function of y
			for i=2,#expr do
				local wrt = expr[i]

				-- and what about 2nd derivatives too?	
				
				if not var.dependentVars:find(wrt) then
					return Constant(0)
				end
			end
		end
		--]]

		if expr[1].evaluateDerivative then
			local result = expr[1]:clone()
			for i=2,#expr do
				-- TODO one at a time ...
				result = prune:apply(result:evaluateDerivative(expr[i]))
			end
			return result
		end
	end,
}

return Derivative
