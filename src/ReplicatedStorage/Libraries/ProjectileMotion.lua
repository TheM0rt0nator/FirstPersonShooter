-- Useful functions to calculate values to do with projectile motion

local ProjectileMotion = {}

-- Returns the position of a projectile after existing for a certain amount of time that was fired from a set origin at a set velocity, can add acceleration to simulate gravity or something
function ProjectileMotion.getPositionAtTime(time, origin, initialVelocity, acceleration)
	local velocityFactor = (initialVelocity * time)
	local accelerationFactor = (acceleration * (time ^ 2)) / 2
	local totalDist = velocityFactor + accelerationFactor
	return origin + totalDist
end

-- Returns the velocity of a projectile after the given amount of time and the given acceleration
function ProjectileMotion.getVelocityAtTime(time, initialVelocity, acceleration)
	return initialVelocity + acceleration * time
end

return ProjectileMotion