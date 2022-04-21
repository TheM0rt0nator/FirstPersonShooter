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

-- When a player dies, increment their deaths, check who killed them and increment this players kills - could use the weapon variable to keep track of amount of kills with that weapon
function FFA:playerKilled(killer, victim, weapon)
	-- Check if the game is over
	local gameOver = self:checkRoundEnded({
		kills = (Leaderboard.playerScores[tostring(killer.UserId)] and Leaderboard.playerScores[tostring(killer.UserId)].Kills) or 0;
	})
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