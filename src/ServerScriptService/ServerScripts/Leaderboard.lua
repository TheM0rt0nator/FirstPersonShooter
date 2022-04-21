-- Keeps track of every players kills, deaths etc
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local PlayerDataManager = loadModule("PlayerDataManager")

local Leaderboard = {
	playerScores = {};
}

function Leaderboard:initiate()
	task.spawn(function()
		self.leaderboardVals = Instance.new("Folder", ReplicatedStorage)
		self.leaderboardVals.Name = "Leaderboard"

		-- Run playerAdded for any players already in-game
		for _, player in pairs(Players:GetPlayers()) do
			self.playerAdded(player)
		end
		Players.PlayerAdded:Connect(self.playerAdded)
		Players.PlayerRemoving:Connect(self.playerRemoving)
	end)
end

-- Increments a players score of a certain type by the given amount
function Leaderboard:incrementScore(player, scoreType, amount, save)
	if not self.playerScores[tostring(player.UserId)] then return end
	local scores = self.playerScores[tostring(player.UserId)]
	if not scores[scoreType] then
		scores[scoreType] = amount
	else
		scores[scoreType] += amount
	end
	-- Increment the players data to keep track of kills, deaths, and any other scores
	local currentData = PlayerDataManager:getSessionData(player)
	PlayerDataManager:changeSessionData(player, {
		[scoreType] = (currentData[scoreType] or 0) + amount;
	})
end

-- Clears the scores from the scoreboard, ready for the next round
function Leaderboard:clearScores()
	for userId, _ in pairs(self.playerScores) do
		self.playerScores[userId] = {}
	end
	-- Clear out the players leaderstats table
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(function()
			if ReplicatedStorage.Leaderboard:WaitForChild(player.Name, 2) then
				ReplicatedStorage.Leaderboard[player.Name]:ClearAllChildren()
			end
		end)
	end
end

-- Creates the leaderboard values for a player depending on the gamemode (might have deaths in one gamemode but not another)
function Leaderboard.createValues(playersFolder)
	local gamemode = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("CurrentMode").Value
	if gamemode == "FFA" then
		local kills = Instance.new("IntValue", playersFolder)
		kills.Name = "Kills"
		local deaths = Instance.new("IntValue", playersFolder)
		deaths.Name = "Deaths"
	end
end

-- When the player joins, create a table to keep track of their stats in the current round
function Leaderboard.playerAdded(player)
	Leaderboard.playerScores[tostring(player.UserId)] = {}
	local playerLeaderstats = Instance.new("Folder", Leaderboard.leaderboardVals)
	playerLeaderstats.Name = player.Name
	Leaderboard.createValues(playerLeaderstats)
end

-- When the player leaves, get rid of their score table
function Leaderboard.playerRemoving(player)
	Leaderboard.playerScores[tostring(player.UserId)] = nil
	if Leaderboard.leaderboardVals:FindFirstChild(player.Name) then
		Leaderboard.leaderboardVals:FindFirstChild(player.Name):Destroy()
	end
end

return Leaderboard