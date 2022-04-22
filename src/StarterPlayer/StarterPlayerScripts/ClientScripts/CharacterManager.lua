-- Handles all character related things like sprinting and crouching
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local crouchEvent = getDataStream("CrouchEvent", "BindableEvent")
local sprintEvent = getDataStream("SprintEvent", "BindableEvent")

local UserInput = loadModule("UserInput")
local Keybinds = loadModule("Keybinds")

local CharacterManager = {
	crouching = false;
}

-- When the module loads, setup the connections
function CharacterManager:initiate()
	self:setupConnections()
end

-- Sets up the spring and crouch connections separately from the guns so we can tell the guns and they can set the walkspeed etc accordingly
function CharacterManager:setupConnections()
	-- Connect the sprint inputs
	for bindNum, keybind in pairs(Keybinds.Sprint) do
		local inputType = (string.find(keybind.Name, "Button") and Enum.UserInputType.Gamepad1) or Enum.UserInputType.Keyboard
		UserInput.connectInput(inputType, keybind, "Sprint" .. bindNum, {
			beganFunc = function()
				sprintEvent:Fire(true)
			end;
			endedFunc = function()
				sprintEvent:Fire(false)
			end;
		}, true)
	end

	-- Connect the crouch inputs
	for bindNum, keybind in pairs(Keybinds.Crouch) do
		local inputType = (string.find(keybind.Name, "Button") and Enum.UserInputType.Gamepad1) or Enum.UserInputType.Keyboard
		UserInput.connectInput(inputType, keybind, "Crouch" .. bindNum, {
			beganFunc = function()
				crouchEvent:Fire(not self.crouching)
			end;
		}, true)
	end
end

return CharacterManager