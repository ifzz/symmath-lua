--[[
I'm sure there's a better way to do this
for now - since prune() leaves things in a div -> add - > mul state,
I'll just have this around to convert things to an add -> div -> mul state
--]]
local class = require 'ext.class'
local Visitor = require 'symmath.visitor.Visitor'
local DistributeDivision = class(Visitor)
DistributeDivision.name = 'DistributeDivision' 

-- prune beforehand to undo tidy(), to undo subtractions and unary - signs
function DistributeDivision:apply(expr, ...)
	return DistributeDivision.super.apply(self, expr:simplify():prune(), ...)
end

return DistributeDivision 
