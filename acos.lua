local class = require 'ext.class'
local Function = require 'symmath.Function'
local acos = class(Function)
acos.name = 'acos'
acos.func = math.acos
function acos:evaluateDerivative(...)
	local x = table.unpack(self):clone()
	local sqrt = require 'symmath.sqrt'
	local diff = require 'symmath'.diff
	return -diff(x, ...) / sqrt(1 - x^2)
end
return acos
