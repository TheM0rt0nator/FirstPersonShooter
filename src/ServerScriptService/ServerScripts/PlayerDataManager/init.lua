local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local DataStore = loadModule("DataStore")
local DefaultData = loadModule("DefaultData")
local Table = loadModule("Table")
local WeaponHandler = loadModule("WeaponHandler")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerDataStore")

local PlayerDataManager = {
	loadedData = {};
	leftBools = {};
}

-- Run player added for any players in the game already
function PlayerDataManager:initiate()
	task.spawn(function()
		for _, player in pairs(Players:GetPlayers()) do
			PlayerDataManager.playerAdded(player)
		end
		Players.PlayerAdded:Connect(PlayerDataManager.playerAdded)
		Players.PlayerRemoving:Connect(PlayerDataManager.playerRemoving)
	end)
end

-- Sets the players data to the default data table
function PlayerDataManager:resetData(userId)
	DataStore.setSessionData(PlayerDataStore, "User_" .. userId, DefaultData)
end

-- Yields until the players data has been sorted
function PlayerDataManager:waitForLoadedData(player)
	while not PlayerDataManager.loadedData[tostring(player.UserId)] do
		task.wait()
	end
end

-- Returns the session data for the given player
function PlayerDataManager:getSessionData(player)
	return DataStore.getData(PlayerDataStore, "User_" .. player.UserId, Table.clone(DefaultData)) or {}
end

-- Changes a players session data to then be changed in the datastore (merges the given table into their current data)
function PlayerDataManager:changeSessionData(player, dataTable)
	local playerDataIndex = "User_" .. player.UserId
	local currentData = DataStore.getData(PlayerDataStore, playerDataIndex, Table.clone(DefaultData)) or {}
	DataStore.setSessionData(PlayerDataStore, playerDataIndex, Table.merge(currentData, dataTable))
end

-- When player joins, set their session data to their existing data or the default data table if they have no data
function PlayerDataManager.playerAdded(player)
	WeaponHandler.setEquippedKit(player, "Assault")
	local userId = player.UserId
	local playerDataIndex = "User_" .. userId
	local playersData = DataStore.getData(PlayerDataStore, playerDataIndex, Table.clone(DefaultData))
	DataStore.setSessionData(PlayerDataStore, "User_" .. userId, playersData)
	PlayerDataManager.loadedData[tostring(player.UserId)] = true
end

-- When player leaves, remove their session data
function PlayerDataManager.playerRemoving(player)
	local userId = player.UserId
	DataStore.removeSessionData(PlayerDataStore, "User_" .. userId, true)
	PlayerDataManager.loadedData[tostring(player.UserId)] = nil
end

return PlayerDataManager