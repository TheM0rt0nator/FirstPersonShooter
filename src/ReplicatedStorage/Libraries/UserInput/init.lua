local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if RunService:IsServer() then return {} end

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Table = loadModule("Table")

local UserInput = {}

--[[for _, module in pairs(script:GetChildren()) do
	UserInput[module.Name] = require(module)
end]]

-- Connects a certain input and runs a function when this input starts / changes / ends
function UserInput.connectInput(inputType, keycode, inputId, functions, gameProcessedBool)
	if not UserInput[inputType] then
		UserInput[inputType] = {}
	end

	-- Make sure the functions argument is a table
	if typeof(functions) == "table" then
		-- If we have the function for the corresponding input, then connect it and save the connection in the module
		if typeof(functions.beganFunc) == "function" then
			UserInput[inputType][inputId .. "Began"] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if (gameProcessedBool or not gameProcessed) and input.UserInputType == inputType and (not keycode or input.KeyCode == keycode) then
					functions.beganFunc(input)
				end
			end)
		end

		if typeof(functions.changedFunc) == "function" then
			UserInput[inputType][inputId .. "Changed"] = UserInputService.InputChanged:Connect(function(input, gameProcessed)
				if (gameProcessedBool or not gameProcessed) and input.UserInputType == inputType and (not keycode or input.KeyCode == keycode) then
					functions.changedFunc(input)
				end
			end)
		end

		if typeof(functions.endedFunc) == "function" then
			UserInput[inputType][inputId .. "Ended"] = UserInputService.InputEnded:Connect(function(input, gameProcessed)
				if (gameProcessedBool or not gameProcessed) and input.UserInputType == inputType and (not keycode or input.KeyCode == keycode) then
					functions.endedFunc(input)
				end
			end)
		end
	end
end

-- Disconnects a certain input with a given id
function UserInput.disconnectInput(inputType, inputId)
	if UserInput[inputType] then
		if UserInput[inputType][inputId .. "Began"] then
			UserInput[inputType][inputId .. "Began"]:Disconnect()
			UserInput[inputType][inputId .. "Began"] = nil
		end

		if UserInput[inputType][inputId .. "Changed"] then
			UserInput[inputType][inputId .. "Changed"]:Disconnect()
			UserInput[inputType][inputId .. "Changed"] = nil
		end

		if UserInput[inputType][inputId .. "Ended"] then
			UserInput[inputType][inputId .. "Ended"]:Disconnect()
			UserInput[inputType][inputId .. "Ended"] = nil
		end

		if Table.length(UserInput[inputType]) == 0 then
			UserInput[inputType] = nil
		end
	end
end

return UserInput