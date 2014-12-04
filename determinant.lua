--[[ iterates through all permutations of the provided table
args:
	elements = what elements to permute
	callback = what to call back with
	[internal]
	index = constructed index to be passed to the callback
	[optional]
	size = how many elements to return.  default is the length
--]]
function permutations(args)
	local parity = args.parity or 1
	local p = args.elements
	local callback = args.callback
	local index = args.index
	if args.size then
		if index and #index == args.size then
			return callback(index, parity)
		end
	else
		if #p == 0 then
			return callback(index, parity)
		end
	end
	for i=1,#p do
		local subset = table(p)
		local subindex = table(index)
		subindex:insert(subset:remove(i))
		parity = parity * -1		-- TODO times -1 or times the distance of the swap?
		if permutations{
			elements = subset, 
			callback = callback, 
			index = subindex,
			size = args.size,
			parity = parity,
		} then 
			return true 
		end
	end
end

return function(m)
	local Matrix = require 'symmath.Matrix'
	local Constant = require 'symmath.Constant'

	-- non-matrix?  return itself
	if type(m) ~= 'table' or not m.isa or not m:isa(Matrix) then return m end

	local n = #m

	-- 0x0 matrix?
	if n == 0 then return Constant(1) end

	-- cycle through all permutations of 1..n for n == #m
	-- if the # of flips is odd then scale by -1, if even then by +1 
	-- 1x1 matrix? 
	if n == 1 then
		return m[1][1]
	end

	-- any further -- use recursive case
	local result = Constant(0)
	permutations{
		elements=range(n),
		callback = function(index, parity)
			local product
			for i=1,n do
				local entry = m[i][index[i]]
				if not product then
					product = entry
				else
					product = product * entry
				end
			end
			result = result + parity * product
			--print(parity, unpack(index))
		end,
	}
	local simplify = require 'symmath.simplify'
	return simplify(result)
end
