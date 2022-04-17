local ReplicatedStorage = game:GetService("ReplicatedStorage")

local framework = table.unpack(require(ReplicatedStorage.Framework))

-- Requires every server module in the game (apart from Libraries) so that their initiating code can be executed
framework:loadAll()