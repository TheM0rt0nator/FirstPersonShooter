-- Runs the main game loop
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local MapHandler = loadModule("MapHandler")
local Gamemodes = loadModule("Gamemodes")
local Leaderboard = loadModule("Leaderboard")

local spawnPlayerEvent = getDataStream("SpawnPlayerEvent", "RemoteEvent")
local gameOverEvent = getDataStream("GameOverEvent", "BindableEvent")

local MainGameLoop = {}

-- Starts the main game loop which loads/unloads maps and starts/ends rounds (the initiate function is called when the module is loaded in ModuleScriptLoader)
function MainGameLoop:initiate()
	self:createGameValues()
	self.gameRunning = true
	task.spawn(function()
		while self.gameRunning do
			task.wait(1)
			self.gameStatus.Value = "ChoosingMap"
			-- Choose the map
			local mapLoaded, err = pcall(function()
				MapHandler:chooseMap()
			end)
			if not mapLoaded then 
				-- If the maps fails to load, start a new round and hope it loads next time
				warn(err)
				continue
			end

			self.gameStatus.Value = "ChoosingGamemode"
			local modeChosen, err = pcall(function()
				self.currentMode = Gamemodes:chooseGamemode()
				self.currentGamemode.Value = self.currentMode.name
				-- Loop through all players and create their leaderboard values for this gamemode
				for _, player in pairs(Players:GetPlayers()) do
					Leaderboard.createValues(ReplicatedStorage.Leaderboard:WaitForChild(player.Name))
				end
				self.roundType.Value = self.currentMode.roundType or "Kills"
			end)
			if not modeChosen then 
				-- If the gamemode fails to be chosen, start a new round
				warn(err)
				continue
			end

			self.gameStatus.Value = "GameRunning"

			-- Do game stuff
			gameOverEvent.Event:Wait()

			-- Tell all players to display the winners, then if anyone new joins, they can just wait for gameStatus to change back to choosing map
			self.gameStatus.Value = "GameOver"
			self.currentMode = nil
			self.currentGamemode.Value = ""

			Leaderboard:clearScores()
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
end

-- When the player clicks spawn on their kit selection screen, spawn them into the game with their chosen kit
function MainGameLoop:spawnPlayer(player, chosenKit)
	-- Check if they are allowed to use the kit they chose
	if self.currentMode then
		self.currentMode:spawnPlayer(player)
	end
end

spawnPlayerEvent.OnServerEvent:Connect(function(player, chosenKit)
	MainGameLoop:spawnPlayer(player, chosenKit)
end)

return MainGameLoop