local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Weapon = loadModule("Weapon")
local UserInput = loadModule("UserInput")
local Keybinds = loadModule("Keybinds")
local ProjectileMotion = loadModule("ProjectileMotion")
local Raycast = loadModule("Raycast")

local TestWeapons = {}

task.delay(5, function()
	local newWeapon = Weapon.new("M4A1")
	newWeapon:equip()

	local function update(dt)
		newWeapon:update(dt)
	end

	RunService.RenderStepped:Connect(update)
end)

--[[local origin = Vector3.new(0, 20, 0)
local initialVelocity = Vector3.new(200, 100, 0)
local acceleration = Vector3.new(0, -196.2, 0)

local testPart = Instance.new("Part", workspace)
testPart.Name = "ProjectileTest"
testPart.Size = Vector3.new(1, 1, 1)
testPart.CanCollide = false
testPart.Anchored = true
testPart.Material = Enum.Material.Neon

local totalDelta = 0
local connection
connection = RunService.RenderStepped:Connect(function(dt)
	local position = ProjectileMotion.getPositionAtTime(totalDelta, origin, initialVelocity, acceleration)
	local velocity = ProjectileMotion.getVelocityAtTime(totalDelta, initialVelocity, acceleration)
	local raycastResult  = Raycast.new({workspace.Baseplate}, "Whitelist", position, velocity.Unit, velocity.Magnitude * dt)
	if raycastResult and raycastResult.Instance then
		print(raycastResult.Instance:GetFullName())
		connection:Disconnect()
	end
	totalDelta += dt
	if (position - origin).Magnitude > 5000 then
		connection:Disconnect()
	end
end)]]

return TestWeapons