local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local MainInterface = loadModule("MainInterface")

local player = Players.LocalPlayer

local UserInterface = Roact.createElement(MainInterface)

-- When this module runs, mount the main interface
function UserInterface:initiate()
	Roact.mount(UserInterface, player:WaitForChild("PlayerGui"))
end

return UserInterface