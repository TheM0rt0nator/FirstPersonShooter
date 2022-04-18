local Maths = {}

-- Returns the linear interpolation between start and goal by alpha
function Maths.lerp(start, goal, alpha)
	return start + (goal - start) * alpha
end

return Maths