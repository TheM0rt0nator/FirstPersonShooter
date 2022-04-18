-- Keeps track of every players kills, deaths etc
local Players = game:GetService("Players")

local Scoreboard = {
	playerScores = {};
}

-- Increments a players score of a certain type by the given amount
function Scoreboard:incrementScore(player, scoreType, amount)
	if not self.playerScores[tostring(player.UserId)] then return end
	local scores = self.playerScores[tostring(player.UserId)]
	if not scores[scoreType] then
		scores[scoreType] = amount
	else
		scores[scoreType] += amount
	end
end

-- Clears the scores from the scoreboard, ready for the next round
function Scoreboard:clearScores()
	for userId, _ in pairs(self.playerScores) do
		self.playerScores[userId] = {}
	end
end

-- When the player joins, create a table to keep track of their stats in the current round
function Scoreboard.playerAdded(player)
	Scoreboard.playerScores[tostring(player.UserId)] = {}
end

-- When the player leaves, get rid of their score table
function Scoreboard.playerRemoving(player)
	Scoreboard.playerScores[tostring(player.UserId)] = nil
end

for _, player in pairs(Players:GetPlayers()) do
	Scoreboard.playerAdded(player)
end

Players.PlayerAdded:Connect(Scoreboard.playerAdded)
Players.PlayerRemoving:Connect(Scoreboard.playerRemoving)

return Scoreboard