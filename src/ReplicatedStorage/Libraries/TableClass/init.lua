-- Creates a new table with the defined metamethods below

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Table = loadModule("Table")

local TableClass = {}

-- Metatable with customizable metamethods; can currently use the == and .. operators on a created table
local Metatable = {
	__index = TableClass;

	__eq = function(tab1, tab2)
		return Table.deepCheckEquality(tab1, tab2)
	end;

	__concat = function(tab1, tab2)
		assert(typeof(tab1) == "table" and typeof(tab2) == "table", "Cannot concatenate " .. typeof(tab1) .. " with " .. typeof(tab2))

		for index, val in pairs(tab2) do
			tab1[index] = val
		end

		return tab1
	end;
}

-- Creates a new table with metamethods defined above, useful for making tables easier to use for example
function TableClass.new(initTab)
	assert(typeof(initTab == "table"), "Argument needs to be a table")

	local startTable = Table.clone(initTab) or {}
	local self = setmetatable(startTable, Metatable)

	return self
end

-- Uses functions from Table module but can be called on the table object directly

function TableClass:deepCheckEquality(tab2)
	return Table.deepCheckEquality(self, tab2)
end

function TableClass:contains(value)
	return Table.contains(self, value)
end

function TableClass:length()
	return Table.length(self)
end

function TableClass:getIndex(value)
	return Table.getIndex(self, value)
end

function TableClass:removeListDuplicates()
	return Table.removeListDuplicates(self)
end

return TableClass