local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Table = loadModule("Table")
local WeaponKits = loadModule("WeaponKits")

local setEquippedKit = getDataStream("SetEquippedKit", "RemoteEvent")

local WeaponHandler = {
	MAX_WEAPONS = 2;
	players = {};
}

-- When player asks server to set their equipped kit, make sure the kit exists and then equip the weapons in the kit
function WeaponHandler.setEquippedKit(player, kit)
	if WeaponKits[kit] and #WeaponKits[kit].Weapons <= WeaponHandler.MAX_WEAPONS then
		WeaponHandler.players[tostring(player.UserId)] = WeaponKits[kit]
	end
end

-- When the player joins, create a table for them so we can store the weapons they currently have equipped
function WeaponHandler.playerAdded(player)
	WeaponHandler.players[tostring(player.UserId)] = {}
end

-- When the player leaves, delete their weapon table
function WeaponHandler.playerRemoving(player)
	if WeaponHandler.players[tostring(player.UserId)] then
		WeaponHandler.players[tostring(player.UserId)] = nil
	end
end

if RunService:IsServer() then
	setEquippedKit.OnServerEvent:Connect(WeaponHandler.setEquippedKit)
end

Players.PlayerAdded:Connect(WeaponHandler.playerAdded)
Players.PlayerRemoving:Connect(WeaponHandler.playerRemoving)

return WeaponHandler