-- All functions related to basic Data Stores

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

if RunService:IsClient() then return {} end

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Table = loadModule("Table")
local Time = loadModule("Time")

local DataStore = {}
DataStore.Data = {}
DataStore.DataCache = {}

local AUTOSAVE_INTERVAL = 60
local DATA_WAIT_INTERVAL = 30

-- Returns the stored session data, and creates a table if it doesn't exist yet
function DataStore.getStoredData(dataStore)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")

	if not DataStore.Data[dataStore] then
		DataStore.Data[dataStore] = {}
		DataStore.DataCache[dataStore] = {}
	end
	return DataStore.Data[dataStore]
end

-- Sets the session data for a given data store with given index, merging it in if it is a table
function DataStore.setSessionData(dataStore, index, newData)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local data = DataStore.getStoredData(dataStore)
	data[index] = (data[index] and data[index]) or {}
	if typeof(newData) == "table" and typeof(data[index] == "table") then
		data[index] = Table.merge(data[index], newData)
	else
		data[index] = newData
	end

	DataStore.DataCache[dataStore][index] = newData
end

-- Removes the session data for a given data store with given index
function DataStore.removeSessionData(dataStore, index, saveData)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local data = DataStore.getStoredData(dataStore)
	if data and data[index] then
		if saveData then
			DataStore.updateDataAsync(dataStore, index, function(currentData, keyInfo)
				local userIDs = keyInfo:GetUserIds()
				local metadata = keyInfo:GetMetadata()
				return data[index], userIDs, metadata
			end)
		end
		data[index] = nil
		DataStore.DataCache[dataStore][index] = nil
	end
end

-- Gets the data in the given data store with the given index, saves it in the Data table and returns it
-- initialData argument is the data you want to set for this index if it doesn't exist yet
function DataStore.getData(dataStore, index, initialData, initialUserIds, initialMetaData)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local data = DataStore.getStoredData(dataStore)
	if data[index] then return data[index] end
	local storedData, keyInfo = DataStore.getDataAsync(dataStore, index)
	if not storedData and initialData then
		DataStore.setDataAsync(dataStore, index, initialData, initialUserIds, initialMetaData)
		return initialData, keyInfo
	end
	data[index] = storedData
	return storedData, keyInfo
end

-- Waits for the data and repeatedly tries the getData function until it gets the data
function DataStore.waitForData(dataStore, index)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local data = DataStore.getStoredData(dataStore)
	if data[index] then return data[index] end
	while not data[index] do
		DataStore.getData(dataStore, index)
		if not data[index] then
			task.wait(DATA_WAIT_INTERVAL)
		end
	end

	return data[index]
end

-- Returns the data saved in the given datastore, along with the keyInfo of the index
function DataStore.getDataAsync(dataStore, index)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local success, savedData, keyInfo = pcall(function()
		local storedData, keyInfo = dataStore:GetAsync(index)
		return storedData, keyInfo
	end)
	if success then 
		return savedData, keyInfo
	else
		warn("Failed to get data from DataStore: " , dataStore , " with index: " , index , " due to error: " , savedData)
	end
end

-- Completely overwrites the data in the given data store with the given index, saves it in the Data table and returns it
function DataStore.setDataAsync(dataStore, index, newData, userIds, metaData)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local setOptions
	if metaData then
		setOptions= Instance.new("DataStoreSetOptions")
		setOptions:SetMetadata(metaData)
	end

	local success, errorMessage = pcall(function()
		dataStore:SetAsync(index, newData, userIds, setOptions)
	end)
	if not success then
		warn("Failed to save data to DataStore: " , dataStore , " with index: " , index , " due to error: " , errorMessage)
	else
		DataStore.DataCache[dataStore][index] = nil
	end
end

-- Increments the number value in a data store
function DataStore.incrementDataAsync(dataStore, index, newValue, userIds, metaData)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")
	assert(typeof(newValue) == "number", "newValue argument must be a number")

	local incrementOptions
	if metaData then
		incrementOptions= Instance.new("DataStoreIncrementOptions")
		incrementOptions:SetMetadata(metaData)
	end

	local success, errorMessage = pcall(function()
		dataStore:IncrementAsync(index, newValue, userIds, incrementOptions)
	end)
	if not success then
		warn("Failed to increment data to DataStore: " , dataStore , " with index: " , index , " due to error: " , errorMessage)
	else
		DataStore.DataCache[dataStore][index] = nil
	end
end

-- Updates the data using the given function
function DataStore.updateDataAsync(dataStore, index, updateFunction)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")
	assert(typeof(updateFunction) == "function", "updateFunction argument must be a function")

	local success, errorMessage = pcall(function()
		return dataStore:UpdateAsync(index, updateFunction)
	end)
	if not success then
		warn("Failed to increment data to DataStore: " , dataStore , " with index: " , index , " due to error: " , errorMessage)
	else
		DataStore.DataCache[dataStore][index] = nil
	end
end

-- Restores a previous version of data, closest to the given date in form {year = 2020, month = 3, day = 09, etc...} (accepts minDate and maxData, where only maxDate is compulsory)
function DataStore.restorePreviousVersion(dataStore, index, minDate, maxDate)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")
	assert(typeof(maxDate) == "table", "maxDate argument must be a table")

	local minDateTime
	if minDate and typeof(minDate) == "table" then
		minDateTime = DateTime.fromUniversalTime(minDate.year or 0, minDate.month or 0, minDate.day or 0, minDate.hour or 0, minDate.min or 0).UnixTimestampMillis
	end
	local maxDateTime = DateTime.fromUniversalTime(maxDate.year, maxDate.month, maxDate.day, maxDate.hour or 0, maxDate.min or 0)
	local listSuccess, pages = pcall(function()
		return dataStore:ListVersionsAsync(index, Enum.SortDirection.Descending, minDateTime, maxDateTime.UnixTimestampMillis)
	end)
	if listSuccess then
		local items = pages:GetCurrentPage()
		if table.getn(items) > 0 then
			-- Read the closest version
			local closestEntry = items[1]
			local success, value, info = pcall(function()
				return dataStore:GetVersionAsync(index, closestEntry.Version)
			end)
			-- Restore current value by overwriting with the closest version
			if success then
				local userIds = info:GetUserIds()
				local setOptions = Instance.new("DataStoreSetOptions")
				setOptions:SetMetadata(info:GetMetadata())
				DataStore.setDataAsync(dataStore, index, value, userIds, setOptions)
			end
		else
			-- No entries found
			warn("No entries found before given max date")
		end
	end
end

-- Attempts to list all the keys in a dataStore, and returns the pages table
function DataStore.listKeys(dataStore)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")

	local listSuccess, pages = pcall(function()
		return dataStore:ListKeysAsync()
	end)
	if listSuccess then
		return pages
	end
end

-- Returns the length of the JSON encoded data, used to check data limits
function DataStore.getDataSize(dataStore, index)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local data = DataStore.getStoredData(dataStore)
	local success, encodedData = pcall(function()
		local data = data[index] or DataStore.getData(dataStore, index)
		if data then
			return HttpService:JSONEncode(data)
		else
			error("Data doesn't exist")
		end
	end)
	if success then
		return string.len(encodedData)
	end
end

-- Removes the index from a given dataStore object
function DataStore.removeDataAsync(dataStore, index)
	assert(typeof(dataStore) == "Instance" and dataStore.ClassName and dataStore.ClassName == "DataStore", "DataStore argument must be a DataStore instance")
	assert(typeof(index) == "string", "index argument must be a string")

	local success, removedValue = pcall(function()
		return dataStore:RemoveAsync(index)
	end)
	if success then
		warn("Removed index: " .. index .. " from dataStore: " , dataStore , " successfully")
	else
		warn("Failed to remove index: " .. index .. " from dataStore: " , dataStore)
	end
end

-- Saves all data in all datastores
function DataStore.saveAllData()
	for dataStore, data in pairs(DataStore.DataCache) do
		for index, value in pairs(data) do
			if typeof(value) == "number" then
				DataStore.incrementDataAsync(dataStore, index, value)
			else
				DataStore.updateDataAsync(dataStore, index, function(currentData, keyInfo)
					local userIDs = keyInfo:GetUserIds()
					local metadata = keyInfo:GetMetadata()
					return value, userIDs, metadata
				end)
			end
		end
	end
end

-- Auto save all the datastores at a set interval
task.spawn(function()
	while true do
		Time:WaitRealTime(AUTOSAVE_INTERVAL)
		DataStore.saveAllData()
	end
end)

game:BindToClose(function()
	--[[ If the current session is studio, do nothing
	if RunService:IsStudio() then
		return
	end]]

	DataStore.saveAllData()
end)

return DataStore