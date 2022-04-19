-- Module which raycasts along the path of a projectile to see when and where it hits something
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local ProjectileMotion = loadModule("ProjectileMotion")
local Raycast = loadModule("Raycast")

local HitDetector = {}
HitDetector.__index = HitDetector

-- Create a new hit detector for a weapon which can be used to cast projectiles
function HitDetector.new()
	local self = {
		hitEvent = Instance.new("BindableEvent");
	}
	setmetatable(self, HitDetector)
	return self
end

-- Fires a projectile with the given velocity and acceleration, and detects what it hits (can use whitelist or blacklist)
function HitDetector:fire(origin, initialVelocity, acceleration, maxDist, filterType, filterObjects)
	local timePassed = 0
	filterType = filterType or "Blacklist"
	filterObjects = filterObjects or {}

	local connectionType = if RunService:IsClient() then RunService.RenderStepped elseif RunService:IsServer() then RunService.Heartbeat else nil
	local connection
	connection = connectionType:Connect(function(dt)
		local position = ProjectileMotion.getPositionAtTime(timePassed, origin, initialVelocity, acceleration)
		local velocity = ProjectileMotion.getVelocityAtTime(timePassed, initialVelocity, acceleration)
		local raycastResult = Raycast.new(filterObjects, filterType, position, velocity.Unit, velocity.Magnitude * dt)
		if raycastResult and raycastResult.Instance then
			connection:Disconnect()
			self.hitEvent:Fire(raycastResult.Instance)
			return
		end
		timePassed += dt
		if (position - origin).Magnitude > maxDist then
			connection:Disconnect()
		end
	end)
end

return HitDetector