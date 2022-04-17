local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptLoader = require(ReplicatedStorage.ModuleScriptLoader)
local DataStreamHandler = require(ReplicatedStorage.DataStreamHandler)

-- Get a new module script loader and data stream handler, and return them in a table - allows scripts to require any module in the game and create Remotes and Bindables
local newLoader = ModuleScriptLoader.new(RunService:IsServer() and "Server" or "Client")
local dataStreamHandler = DataStreamHandler.new()

return {newLoader, dataStreamHandler}