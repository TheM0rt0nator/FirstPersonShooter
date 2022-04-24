-- Loads and unloads the map, including voting and random map selection
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local mapVotesChanged = getDataStream("MapVotesChanged", "RemoteEvent")
local superVoteFunc = getDataStream("SuperVoteFunc", "RemoteFunction")

local Maths = loadModule("Maths")

local maps = ServerStorage:WaitForChild("Maps")
local rand = Random.new()

local MapHandler = {
	votes = {};
	superVotes = {};
}

-- Chooses the map to load based on votes or, if it is a tie, random selection
function MapHandler:chooseMap(supervote)
	if supervote then
		self:loadMap(maps:FindFirstChild(supervote.Value))
		return
	end
	local mapVotes = ReplicatedStorage:WaitForChild("MapVotes")
	local mapsToVote = mapVotes:WaitForChild("Maps")
	local isVotes = #mapsToVote:GetChildren() > 0

	-- If there is no votes, just choose a map randomly
	if not isVotes or mapVotes:WaitForChild("TotalVotes").Value == 0 then
		self:loadMap(self:chooseRandom())
	else
	-- If there is votes, need to check for a winner, or choose randomly between the tied maps
		local votes = {}
		for _, map in ipairs(mapsToVote:GetChildren()) do
			votes[map.Name] = map.Value
		end
		local modeVote = Maths.mode(votes)
		if #modeVote == 1 then
			self:loadMap(maps:FindFirstChild(modeVote[1].index))
		else
			local mapsTab = {}
			for _, mapInfo in pairs(modeVote) do
				table.insert(mapsTab, maps:FindFirstChild(mapInfo.index))
			end
			self:loadMap(self:chooseRandom(mapsTab))
		end
	end

	mapVotes:WaitForChild("TotalVotes").Value = 0
	-- Reset the votes table
	MapHandler.votes = {}
	MapHandler.superVotes = {}
end

-- Creates a map holder in the workspace if it doesn't exist, clears it incase it hasn't been cleared for any reason and loads in the new map
function MapHandler:loadMap(map)
	if not map then return end
	local newMap = map:Clone()
	local mapHolder = self:getMapHolder()
	newMap:SetPrimaryPartCFrame(CFrame.new(200, 100, 200))
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

-- Gets the maps to be included in the next vote
function MapHandler:getMapsToVote()
	MapHandler.canSuperVote = true
	local mapsToVote = {}
	for _, map in pairs(maps:GetChildren()) do
		table.insert(mapsToVote, map.Name)
	end
	return mapsToVote
end

-- Chooses a random map from the maps in the map folder, ensuring the same map isn't loaded twice
function MapHandler:chooseRandom(mapsTab)
	local mapsTable = mapsTab or CollectionService:GetTagged("Map")
	for i = #mapsTable, 1, -1 do
		-- Remove any maps which aren't in the maps folder or were chosen last round
		if mapsTable[i].Parent ~= ServerStorage.Maps or (self.prevMap == mapsTable[i].Name and #mapsTable > 1) then
			table.remove(mapsTable, i)
		end
	end
	assert(#mapsTable >= 1, "Needs to be at least one map in ServerStorage")
	return mapsTable[rand:NextInteger(1, #mapsTable)]
end

-- When a player votes for a map, change the value in replicated storage to reflect this and take their vote away from their previous vote (if this exists)
function MapHandler.mapVote(player, map)
	local gameStatus = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("GameStatus")
	if gameStatus.Value ~= "MapVoting" then return end
	local mapVotes = ReplicatedStorage:WaitForChild("MapVotes")
	local mapsToVote = mapVotes:WaitForChild("Maps")
	if not mapsToVote:FindFirstChild(map) then return end
	if MapHandler.votes[tostring(player.UserId)] and mapsToVote:FindFirstChild(MapHandler.votes[tostring(player.UserId)]) then
		mapsToVote[MapHandler.votes[tostring(player.UserId)]].Value -= 1
	else
		mapVotes:WaitForChild("TotalVotes").Value += 1
	end
	MapHandler.votes[tostring(player.UserId)] = map
	mapsToVote[map].Value += 1
	mapVotesChanged:FireAllClients()
end

-- When a player super votes, cancel all other votes and choose this map
function MapHandler.superVote(player, map)
	local gameStatus = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("GameStatus")
	if gameStatus.Value ~= "MapVoting" or not MapHandler.canSuperVote or not maps:FindFirstChild(map) then return end
	MapHandler.superVotes[tostring(player.UserId)] = map
	return true
end

mapVotesChanged.OnServerEvent:Connect(MapHandler.mapVote)
superVoteFunc.OnServerInvoke = MapHandler.superVote

return MapHandler