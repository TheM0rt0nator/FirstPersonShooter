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
		-- Run playerAdded for any players already in-game
		for _, player in pairs(Players:GetPlayers()) do
			Leaderboard.playerAdded(player)
		end
		Players.PlayerAdded:Connect(Leaderboard.playerAdded)
		Players.PlayerRemoving:Connect(Leaderboard.playerRemoving)
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
end

-- When the player joins, create a table to keep track of their stats in the current round
function Leaderboard.playerAdded(player)
	Leaderboard.playerScores[tostring(player.UserId)] = {}
end

-- When the player leaves, get rid of their score table
function Leaderboard.playerRemoving(player)
	Leaderboard.playerScores[tostring(player.UserId)] = nil
end

return Leaderboard