-- Loads and unloads the map, including voting and random map selection
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local maps = ServerStorage:WaitForChild("Maps")
local rand = Random.new()

local MapHandler = {}

-- Chooses the map to load based on votes or, if it is a tie, random selection
function MapHandler:chooseMap()
	-- Add code here for votes
	self:loadMap(self:chooseRandom())
end

-- Creates a map holder in the workspace if it doesn't exist, clears it incase it hasn't been cleared for any reason and loads in the new map
function MapHandler:loadMap(map)
	if not map then return end
	local newMap = map:Clone()
	local mapHolder = self:getMapHolder()
	newMap:SetPrimaryPartCFrame(CFrame.new(0, 100, 0))
	self:unloadMap()

	local lagNum = 0
	for _, part in pairs(newMap:GetDescendants()) do
		if not part:IsA("BasePart") then continue end
		-- Wait every 5 iterations to ensure the game doesn't lag
		lagNum += 1
		if lagNum % 5 == 0 then
			task.wait(.01)
		end
		part.Parent = mapHolder
	end
end

-- Unloads the map from map holder
function MapHandler:unloadMap()
	local mapHolder = self:getMapHolder()
	local lagNum = 0
	for _, part in pairs(mapHolder:GetChildren()) do
		if not part:IsA("BasePart") then continue end
		-- Wait every 5 iterations to ensure the game doesn't lag
		lagNum += 1
		if lagNum % 5 == 0 then
			task.wait(.01)
		end
		part:Destroy()
	end
end

-- Gets the map holder or creates it if it doesn't exist
function MapHandler:getMapHolder()
	local mapHolder = workspace:FindFirstChild("MapHolder")
	if not mapHolder then
		mapHolder = Instance.new("Model", workspace)
		mapHolder.Name = "MapHolder"
	end
	return mapHolder
end

-- Chooses a random map from the maps in the map folder, ensuring the same map isn't loaded twice
function MapHandler:chooseRandom()
	local mapsTable = CollectionService:GetTagged("Map")
	for i = #mapsTable, 1, -1 do
		-- Remove any maps which aren't in the maps folder or were chosen last round
		if mapsTable[i].Parent ~= ServerStorage.Maps or (self.prevMap == mapsTable[i].Name and #mapsTable > 1) then
			table.remove(mapsTable, i)
		end
	end
	assert(#mapsTable >= 1, "Needs to be at least one map in ServerStorage")
	return mapsTable[rand:NextInteger(1, #mapsTable)]
end

return MapHandler