-- Functions to select a random gamemode and set up that gamemode
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local rand = Random.new()

local Gamemodes = {
	modes = {
		"FFA"
	};
}

-- Just basic random selection, would be easy to add more gamemodes in the future
function Gamemodes:chooseGamemode()
	local chosenMode = self.modes[rand:NextInteger(1, #self.modes)]
	self.currentMode = loadModule(chosenMode)
	return self.currentMode
end

-- More code could be added here to make choosing gamemodes more weight-based or something (e.g. choose TDM more than FFA)

return Gamemodes