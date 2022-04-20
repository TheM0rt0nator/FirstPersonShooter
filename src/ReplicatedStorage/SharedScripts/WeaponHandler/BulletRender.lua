-- Module which raycasts along the path of a projectile to see when and where it hits something
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local ProjectileMotion = loadModule("ProjectileMotion")
local Raycast = loadModule("Raycast")

local BulletRender = {}
BulletRender.__index = BulletRender

-- Create a new hit detector for a weapon which can be used to cast projectiles
function BulletRender.new()
	local self = {
		hitEvent = Instance.new("BindableEvent");
		bulletConnections = {};
	}
	setmetatable(self, BulletRender)
	return self
end

-- Fires a projectile with the given velocity and acceleration, and detects what it hits (can use whitelist or blacklist)
function BulletRender:fire(origin, initialVelocity, acceleration, maxDist, filterType, filterObjects, bulletPart, isReplicated)
	local timePassed = 0
	filterType = filterType or "Blacklist"
	filterObjects = filterObjects or {}

	if bulletPart then
		self.renderBulletEvent = Instance.new("BindableEvent")
		self:renderBullet(bulletPart)
	end

	local connectionType = if RunService:IsClient() then RunService.RenderStepped elseif RunService:IsServer() then RunService.Heartbeat else nil
	local castConnection
	castConnection = connectionType:Connect(function(dt)
		local position = ProjectileMotion.getPositionAtTime(timePassed, origin, initialVelocity, acceleration)
		local velocity = ProjectileMotion.getVelocityAtTime(timePassed, initialVelocity, acceleration)
		local raycastResult = Raycast.new(filterObjects, filterType, position, velocity.Unit, velocity.Magnitude * dt)
		if raycastResult and raycastResult.Instance then
			castConnection:Disconnect()
			if not isReplicated then
				self.hitEvent:Fire(raycastResult.Instance)
			end
			self:destroyBullet(bulletPart)
			return
		end
		if bulletPart then
			self.renderBulletEvent:Fire(bulletPart, position, velocity)
		end
		timePassed += dt
		if (position - origin).Magnitude > maxDist then
			castConnection:Disconnect()
			self:destroyBullet(bulletPart)
		end
	end)
end

-- If we want to, can render the bullet based on where the ray currently is
function BulletRender:renderBullet(bulletPart)
	self.bulletConnections[bulletPart] = self.renderBulletEvent.Event:Connect(function(bullet, position, velocity)
		bullet.Size = Vector3.new(0.05, 0.05, velocity.Magnitude / 200)
		bullet.CFrame = CFrame.new(position + velocity.Unit * bullet.Size.Z, position + velocity.Unit * bullet.Size.Z * 2)
	end)
end	

-- Destroys the bullet and disconnects it's connections
function BulletRender:destroyBullet(bulletPart)
	if bulletPart then
		self.bulletConnections[bulletPart]:Disconnect()
		self.bulletConnections[bulletPart] = nil
		bulletPart:Destroy()
	end
end

return BulletRender