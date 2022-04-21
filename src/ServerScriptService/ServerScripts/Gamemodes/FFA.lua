-- Free for all gamemode - everyone vs everyone
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Leaderboard = loadModule("Leaderboard")

local gameOverEvent = getDataStream("GameOverEvent", "BindableEvent")

local FFA = {
	name = "FFA";
	killGoal = 25;
	-- Added a roundType value incase a gamemode is time-based rather than kill-based
	roundType = "Kills";
}

-- When a player dies, increment their deaths, check who killed them and increment this players kills
function FFA:playerKilled(player)
	-- Get the round type, and only ask for round end conditions if the game type is kills (or could add score-based rounds too)
	Leaderboard:incrementScore(player, "Deaths", 1)
	if not player:FindFirstChild("ShotTags") then return end
	
	-- Collect all the players with the highest damage dealt to the killed player, and add one kill to all of their scores (2 or more players could have dealt the same damage to 1 player)
	local highestDamage = 0
	local killers = {}
	for _, tag in pairs(player:FindFirstChild("ShotTags"):GetChildren()) do
		if tag.Value > highestDamage then
			killers = {}
			highestDamage = tag.Value
			table.insert(killers, tag.Name)
		elseif tag.Value == highestDamage then
			table.insert(killers, tag.Name)
		end
	end

	-- Loops through the killers, add 1 kill to their scores and if any of them have enough kills, tell the game loop to end the round
	local gameOver
	for _, killer in pairs(killers) do
		if Players:GetPlayerByUserId(tonumber(killer)) then
			Leaderboard:incrementScore(Players:GetPlayerByUserId(tonumber(killer)), "Kills", 1)
		end
		if gameOver then continue end
		gameOver = self:checkRoundEnded({
			kills = (Leaderboard.playerScores[killer] and Leaderboard.playerScores[killer].Kills) or 0;
		})
	end
	if gameOver then
		gameOverEvent:Fire()
	end
end

-- Checks if the round has ended and returns true of false if it has/hasn't
function FFA:checkRoundEnded(info)
	return info.kills >= self.killGoal
end

-- Chooses a spawn for the player to spawn at (this may differ for different gamemodes, where players spawn in teams in TDM for example)
function FFA:spawnPlayer(player)
	-- Get all spawns
	local spawns = CollectionService:GetTagged("Spawn")
	-- Remove any spawns which aren't in the map holder
	for i = #spawns, 1, -1 do
		if spawns[i].Parent ~= workspace:FindFirstChild("MapHolder") then
			spawns[i] = nil
		end
	end

	task.spawn(function()
		Leaderboard:incrementScore(player, "Kills", 1)
		local scores = Leaderboard.playerScores[tostring(player.UserId)]
		while scores and scores.Kills and scores.Kills < 25 do
			Leaderboard:incrementScore(player, "Kills", 1)
			local gameOver = self:checkRoundEnded({
				kills = (Leaderboard.playerScores[tostring(player.UserId)] and Leaderboard.playerScores[tostring(player.UserId)].Kills) or 0;
			}) 
			if gameOver then
				gameOverEvent:Fire()
			end
			task.wait(1)
		end
	end)

	-- Choose a spawn 
	local chosenSpawn
	local chosenDist
	-- This loops through the spawns and gets the closest player to that spawn
	-- It then chooses the spawn which is furthest away from any player, to try and avoid players spawning on top of eachother
	for _, spawn in pairs(spawns) do
		local leastDist = math.huge
		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (spawn.Position - plr.Character.HumanoidRootPart.Position).Magnitude
				if dist < leastDist then
					leastDist = dist
				end
			end
		end	
		if not chosenSpawn or chosenDist < leastDist then
			chosenSpawn, chosenDist = spawn, leastDist
		end
	end
	-- Teleport the player to this spawn
	if not player.Character or not player.Character.PrimaryPart then return end
	player.Character:SetPrimaryPartCFrame(chosenSpawn.CFrame)
end

return FFA