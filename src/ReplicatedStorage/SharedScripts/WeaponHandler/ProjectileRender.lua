-- Module which raycasts along the path of a projectile to see when and where it hits something
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local ProjectileMotion = loadModule("ProjectileMotion")
local Raycast = loadModule("Raycast")
local Table = loadModule("Table")

local ProjectileRender = {}
ProjectileRender.__index = ProjectileRender

-- Create a new hit detector for a weapon which can be used to cast projectiles
function ProjectileRender.new()
	local self = {
		hitEvent = Instance.new("BindableEvent");
		bulletConnections = {};
	}
	setmetatable(self, ProjectileRender)
	return self
end

-- Fires a projectile with the given velocity and acceleration, and detects what it hits (can use whitelist or blacklist)
function ProjectileRender:fire(origin, initialVelocity, acceleration, maxDist, filterType, filterObjects, bulletPart, isReplicated)
	local timePassed = 0
	filterType = filterType or "Blacklist"
	filterObjects = filterObjects or {}

	if bulletPart then
		self.renderBulletEvent = Instance.new("BindableEvent")
		self:renderBullet(bulletPart)
	end

	-- Need to remove the viewmodel from filter objects for the server because these are client based
	local serverFilterObjects = Table.clone(filterObjects)
	table.remove(serverFilterObjects, 1)
	-- Creates the path of the raycast, to be sent on for checks
	local path = {
		segments = {};
		filterObjects = serverFilterObjects;
	}

	local connectionType = if RunService:IsClient() then RunService.RenderStepped elseif RunService:IsServer() then RunService.Heartbeat else nil
	local castConnection
	castConnection = connectionType:Connect(function(dt)
		local position = ProjectileMotion.getPositionAtTime(timePassed, origin, initialVelocity, acceleration)
		local velocity = ProjectileMotion.getVelocityAtTime(timePassed, initialVelocity, acceleration)
		local raycastResult = Raycast.new(filterObjects, filterType, position, velocity.Unit, velocity.Magnitude * dt)
		table.insert(path.segments, {
			position = position;
			direction = velocity.Unit;
			length = velocity.Magnitude * dt;
			hitPoint = raycastResult and raycastResult.Position;
		})
		if raycastResult and raycastResult.Instance then
			castConnection:Disconnect()
			if not isReplicated then
				self.hitEvent:Fire(raycastResult.Instance, path)
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

-- Raycasts along the given path and checks there are no collisions
function ProjectileRender:checkPath(path)
	local pathSucceeded = true
	local filterObjects = path.filterObjects
	for _, segment in pairs(path.segments) do
		-- Want to filter players and bullets as well in this check
		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character then
				table.insert(filterObjects, plr.Character)
			end
		end
		local length = not segment.hitPoint and segment.length or (segment.position - segment.hitPoint).Magnitude
		local raycastResult = Raycast.new(filterObjects, "Blacklist", segment.position, segment.direction, length)
		if raycastResult and raycastResult.Instance then
			pathSucceeded = false
			break
		end
	end
	return pathSucceeded
end

-- If we want to, can render the bullet based on where the ray currently is
function ProjectileRender:renderBullet(bulletPart)
	self.bulletConnections[bulletPart] = self.renderBulletEvent.Event:Connect(function(bullet, position, velocity)
		bullet.Size = Vector3.new(0.05, 0.05, velocity.Magnitude / 200)
		bullet.CFrame = CFrame.new(position + velocity.Unit * bullet.Size.Z, position + velocity.Unit * bullet.Size.Z * 2)
	end)
end	

-- Destroys the bullet and disconnects it's connections
function ProjectileRender:destroyBullet(bulletPart)
	if bulletPart then
		self.bulletConnections[bulletPart]:Disconnect()
		self.bulletConnections[bulletPart] = nil
		bulletPart:Destroy()
	end
end

return ProjectileRender