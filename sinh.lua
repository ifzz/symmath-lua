local class = require 'ext.class'
local Function = require 'symmath.Function'
local sinh = class(Function)
sinh.name = 'sinh'
sinh.func = math.sinh
function sinh:evaluateDerivative(...)
	local x = table.unpack(self):clone()
	local cosh = require 'symmath.cosh'
	local diff = require 'symmath'.diff
	return diff(x,...) * cosh(x)
end
return sinh
