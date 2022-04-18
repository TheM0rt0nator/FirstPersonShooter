local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Weapon = loadModule("Weapon")
local UserInput = loadModule("UserInput")
local Keybinds = loadModule("Keybinds")

local TestWeapons = {}

task.delay(5, function()
	local newWeapon = Weapon.new("M4A1")
	newWeapon:equip()

	local function update(dt)
		newWeapon:update(dt)
	end

	RunService.RenderStepped:Connect(update)
end)

return TestWeapons