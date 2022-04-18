local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local DataStore = loadModule("DataStore")
local DefaultData = loadModule("DefaultData")
local Table = loadModule("Table")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerDataStore")

local PlayerDataManager = {
	loadedData = {};
	leftBools = {};
}

-- Sets up the check for when the rodux store changes to update the players data, and sets up the playerAdded/playerRemoving functions
function PlayerDataManager:initiate()
	task.spawn(function()
		for _, player in pairs(Players:GetPlayers()) do
			PlayerDataManager.playerAdded(player)
		end
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

-- When player joins, set their session data to their existing data or the default data table if they have no data
function PlayerDataManager.playerAdded(player)
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

Players.PlayerAdded:Connect(PlayerDataManager.playerAdded)
Players.PlayerRemoving:Connect(PlayerDataManager.playerRemoving)

return PlayerDataManager