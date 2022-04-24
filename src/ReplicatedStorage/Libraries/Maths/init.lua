local Maths = {}

-- Returns the linear interpolation between start and goal by alpha
function Maths.lerp(start, goal, alpha)
	return start + (goal - start) * alpha
end

-- Returns the point on the sine wave with the given manipulation values
function Maths.getSine(a, b, c, x)
	a = a or 1
	b = b or 1
	c = c or 0
	x = x or tick()
	return a * math.sin((b * x) + c)
end

-- Returns the mode index-value pairs from a given table (supports multiple modes)
function Maths.mode(tab)
	local modes = {}
	for index, val in pairs(tab) do
		if not modes[1] or modes[1].val < val then
			modes = {}
			table.insert(modes, {
				index = index;
				val = val;
			})
		elseif modes[1].val == val then
			table.insert(modes, {
				index = index;
				val = val;
			})
		end
	end
	return modes
end

return Maths