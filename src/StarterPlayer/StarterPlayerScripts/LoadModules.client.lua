local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = table.unpack(require(ReplicatedStorage.Framework))

-- Requires every client module in the game (apart from Libraries) so that their initiating code can be executed
framework:loadAll()