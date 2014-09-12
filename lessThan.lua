require 'ext'
local EquationOp = require 'symmath.EquationOp'
local lessThan = class(EquationOp)
lessThan.name = '<'
function lessThan:switch()
	local a,b = unpack(self.xs)
	return b:greaterThan(a)
end
return lessThan
