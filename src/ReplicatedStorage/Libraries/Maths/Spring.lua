-- This is a public library for creating springs, I just edited it a little bit to make it look nicer

local Spring = {}
Spring.__index = Spring

local ITERATIONS = 8

-- Create a new spring 
function Spring.new(mass, force, damping, speed)
	local self = {
		target = Vector3.new();
		position = Vector3.new();
		velocity = Vector3.new();
		
		mass = mass or 5;
		force = force or 50;
		damping	= damping or 4;
		speed = speed or 4;
	}

	setmetatable(self, Spring)
	
	return self
end

-- Shove the spring a certain amount in a certain direction
function Spring:shove(force)
	local x, y, z = force.X, force.Y, force.Z
	if x ~= x or x == math.huge or x == -math.huge then
		x = 0
	end
	if y ~= y or y == math.huge or y == -math.huge then
		y = 0
	end
	if z ~= z or z == math.huge or z == -math.huge then
		z = 0
	end
	self.velocity += Vector3.new(x, y, z)
end

-- Updates the springs current position based on it's velocity and the time that has passed
function Spring:update(dt)
	local scaledDeltaTime = math.min(dt, 1) * self.speed
	local acceleration = ((-self.position * self.force) / self.mass) - (self.velocity * self.damping)
	
	self.velocity += acceleration * scaledDeltaTime
	self.position += self.velocity * scaledDeltaTime
	
	return self.position
end

return Spring