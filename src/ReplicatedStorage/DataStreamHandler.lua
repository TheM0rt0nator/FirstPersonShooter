-- Handles creation and referencing of RemoteEvents, RemoteFunctions, BindableEvents and BindableFunctions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local DataStreams = {}
DataStreams.__index = DataStreams

local PossibleStreams = {
	RemoteEvent = true;
	RemoteFunction = true;
	BindableEvent = true;
	BindableFunction = true;
}

local RemotesFolder
local BindablesFolder

if RunService:IsServer() then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = ReplicatedStorage

	BindablesFolder = Instance.new("Folder")
	BindablesFolder.Name = "Bindables"
	BindablesFolder.Parent = ServerStorage
elseif RunService:IsClient() then
	RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	BindablesFolder = Instance.new("Folder")
	BindablesFolder.Name = "Bindables"
	BindablesFolder.Parent = ReplicatedStorage
end

-- Creates a new data stream handler object
function DataStreams.new()
	return setmetatable({}, DataStreams)
end

-- Returns a data steam with the given name and type, after creating it or getting it (if it already exists)
function DataStreams:getDataStream(streamName, streamType)
	assert(typeof(streamName) == "string" and PossibleStreams[streamType], "Invalid arguments while trying to get data stream")

	local function getStream(folder)
		if folder:WaitForChild(streamName, 1) then
			return folder:FindFirstChild(streamName)
		else
			local newStream = Instance.new(streamType, folder)
			newStream.Name = streamName

			return newStream
		end
	end

	if string.find(streamType, "Bindable") then
		return getStream(BindablesFolder)
	end

	if RunService:IsServer() then
		return getStream(RemotesFolder)
	elseif RunService:IsClient() then
		if RemotesFolder:WaitForChild(streamName, 5) then
			return RemotesFolder:FindFirstChild(streamName)
		end

		warn(streamName .. " of type " .. streamType .. " was not found")
	end
end

-- When the module is called like a function, either creates the remote or returns the already created remote
function DataStreams:__call(streamName, streamType)
	return self:getDataStream(streamName, streamType)
end

return DataStreams