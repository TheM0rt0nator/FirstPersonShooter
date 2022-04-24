-- Runs the main game loop
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local spawnPlayerFunc = getDataStream("SpawnPlayerFunc", "RemoteFunction")

local updateLeaderboardUI = getDataStream("UpdateLeaderboardUI", "RemoteEvent")
local playerKilledRemote = getDataStream("PlayerKilled", "RemoteEvent")
local gameOverEvent = getDataStream("GameOverEvent", "RemoteEvent")
local localGameOverEvent = getDataStream("LocalGameOverEvent", "BindableEvent")
local playerKilledEvent = getDataStream("LocalPlayerKilled", "BindableEvent")

local MapHandler = loadModule("MapHandler")
local Gamemodes = loadModule("Gamemodes")
local Leaderboard = loadModule("Leaderboard")
local WeaponHandler = loadModule("WeaponHandler")

local MainGameLoop = {
	spawnedPlayers = {};
}

local VOTE_MAP_TIME = 250

-- Starts the main game loop which loads/unloads maps and starts/ends rounds (the initiate function is called when the module is loaded in ModuleScriptLoader)
function MainGameLoop:initiate()
	self:createGameValues()
	self.gameRunning = true
	task.spawn(function()
		while self.gameRunning do
			if #ServerStorage.Maps:GetChildren() > 1 then
				local maps = MapHandler:getMapsToVote()
				for _, map in pairs(maps) do
					local newMapVal = Instance.new("IntValue", self.mapsToVote)
					newMapVal.Name = map
				end
				self.gameStatus.Value = "MapVoting"
				self.mapVotesTimer.Value = VOTE_MAP_TIME
				while self.mapVotesTimer.Value > 0  do
					if self.mapVotes:FindFirstChild("SuperVote") then
						break
					end
					task.wait(1)
					self.mapVotesTimer.Value -= 1
				end
			end
			task.wait(1)
			self.gameStatus.Value = "ChoosingMap"
			-- Choose the map
			local mapLoaded, err = pcall(function()
				MapHandler:chooseMap(self.mapVotes:FindFirstChild("SuperVote"))
			end)
			if not mapLoaded then 
				-- If the maps fails to load, start a new round and hope it loads next time
				warn(err)
				continue
			end

			-- Clear the map votes
			self.mapsToVote:ClearAllChildren()
			if self.mapVotes:FindFirstChild("SuperVote") then
				task.wait(2)
				self.mapVotes:FindFirstChild("SuperVote"):Destroy()
			end

			self.gameStatus.Value = "ChoosingGamemode"
			local modeChosen, err = pcall(function()
				self.currentMode = Gamemodes:chooseGamemode()
				self.currentGamemode.Value = self.currentMode.name
				-- Loop through all players and create their leaderboard values for this gamemode
				for _, player in pairs(Players:GetPlayers()) do
					Leaderboard.createValues(ReplicatedStorage.Leaderboard:WaitForChild(player.Name))
				end
				updateLeaderboardUI:FireAllClients()
				self.roundType.Value = self.currentMode.roundType or "Kills"
			end)
			if not modeChosen then 
				-- If the gamemode fails to be chosen, start a new round
				warn(err)
				continue
			end

			self.gameStatus.Value = "GameRunning"

			-- Do game stuff
			local winner = localGameOverEvent.Event:Wait()

			-- Tell all players to display the winners, then if anyone new joins, they can just wait for gameStatus to change back to choosing map
			gameOverEvent:FireAllClients("ShowLeaderboard", winner)
			task.wait(2)
			self.gameStatus.Value = "GameOver"
			self.currentMode = nil
			self.currentGamemode.Value = ""

			task.wait(5)

			-- Tells players to hide leaderboard and go back to home screen
			gameOverEvent:FireAllClients("UnloadingMap", winner)

			task.wait(2)

			Leaderboard:clearScores()
			for _, plrInfo in pairs(self.spawnedPlayers) do
				if plrInfo.diedConnection then
					plrInfo.diedConnection:Disconnect()
					print("died connection cleaned up")
				end
			end
			self.spawnedPlayers = {}
			-- Unload the map
			local mapUnloaded, err = pcall(function()
				MapHandler:unloadMap()
			end)
			if not mapUnloaded then
				-- If this function fails, there can't be a map anyway so not too worried, just start a new round
				warn(err)
				continue
			end
		end
	end)
end

-- Creates the game values to be replicated to all clients to tell them the current status of the game
function MainGameLoop:createGameValues()
	local gameValues = Instance.new("Folder", ReplicatedStorage)
	gameValues.Name = "GameValues"
	local gameStatus = Instance.new("StringValue", gameValues)
	gameStatus.Name = "GameStatus"
	local currentMode = Instance.new("StringValue", gameValues)
	currentMode.Name = "CurrentMode"
	local roundType = Instance.new("StringValue", gameValues)
	roundType.Name = "RoundType"

	self.gameStatus = gameStatus
	self.currentGamemode = currentMode
	self.roundType = roundType

	local mapVotes = Instance.new("Folder", ReplicatedStorage)
	mapVotes.Name = "MapVotes"
	local timer = Instance.new("IntValue", mapVotes)
	timer.Name = "Timer"
	local totalVotes = Instance.new("IntValue", mapVotes)
	totalVotes.Name = "TotalVotes"
	local maps = Instance.new("Folder", mapVotes)
	maps.Name = "Maps"

	self.mapVotes = mapVotes
	self.mapVotesTimer = timer
	self.mapsToVote = maps
end

-- When the player clicks spawn on their kit selection screen, spawn them into the game with their chosen kit
function MainGameLoop:spawnPlayer(player, chosenKit)
	if player.Character and self.gameStatus.Value == "GameRunning" and not self.spawnedPlayers[tostring(player.UserId)] then
		local success = WeaponHandler.setEquippedKit(player, chosenKit)
	
		-- Check if they are allowed to use the kit they chose
		if success and self.currentMode and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			-- We want to filter accessories from bullet hits
			for _, accessory in pairs(player.Character:GetChildren()) do
				if accessory:IsA("Accessory") then
					CollectionService:AddTag(accessory, "Accessory")
				end
			end
			local diedConnection
			diedConnection = player.Character.Humanoid.Died:Connect(function()
				if self.gameStatus.Value == "GameRunning" then
					Leaderboard:incrementScore(player, "Deaths", 1)
				end
				playerKilledRemote:FireAllClients(player.Name, player.Name)
				diedConnection:Disconnect()
				diedConnection = nil
				self.spawnedPlayers[tostring(player.UserId)] = nil
			end)
			self.spawnedPlayers[tostring(player.UserId)] = {
				diedConnection = diedConnection;
			}
			self.currentMode:spawnPlayer(player)
		end
		return success
	end
end

-- When a player is killed, we run the playerKilled function for the current gamemode
function MainGameLoop.playerKilled(killer, victim, weapon)
	if not killer or not victim or MainGameLoop.gameStatus.Value ~= "GameRunning" then return end
	-- Won't let you kill yourself to get kills
	if killer == victim then return end
	-- Increment the killer and victims scores
	if Players:FindFirstChild(killer.Name) then
		Leaderboard:incrementScore(Players:FindFirstChild(killer.Name), "Kills", 1)
	end
	playerKilledRemote:FireAllClients(killer.Name, victim.Name, weapon)
	if MainGameLoop.currentMode and MainGameLoop.currentMode.playerKilled then
		MainGameLoop.currentMode.playerKilled(MainGameLoop.currentMode, killer, victim, weapon)
	end
end

-- When a player leaves, disconnect their connections and then remove them from spawned players table
function MainGameLoop.playerRemoving(player)
	if MainGameLoop.spawnedPlayers[tostring(player.UserId)] and MainGameLoop.spawnedPlayers[tostring(player.UserId)].diedConnection then
		local spawnedPlayerTable = MainGameLoop.spawnedPlayers[tostring(player.UserId)]
		spawnedPlayerTable.diedConnection:Disconnect()
		MainGameLoop.spawnedPlayers[tostring(player.UserId)] = nil
	end
end

spawnPlayerFunc.OnServerInvoke = function(player, chosenKit)
	return MainGameLoop:spawnPlayer(player, chosenKit)
end

playerKilledEvent.Event:Connect(MainGameLoop.playerKilled)
Players.PlayerRemoving:Connect(MainGameLoop.playerRemoving)

return MainGameLoop