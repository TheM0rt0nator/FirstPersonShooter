-- Handles the storing and cleaning up of connections

local Maid = {}
Maid.__index = Maid

-- Creates a new maid object
function Maid.new()
	local self = setmetatable({}, Maid)

	self.connections = {}

	return self
end

-- Stores a task in the maid
function Maid:GiveTask(task)
	table.insert(self.connections, task)
end

-- Clears all tasks stored in the maid
function Maid:DoCleaning()
	for _, task in pairs(self.connections) do
		if typeof(task) == "RBXScriptConnection" then
			task:Disconnect()
		end
	end
	self.connections = {}
end

return Maid