-- Useful string manipulation functions

local String = {}

-- Removes all white space in a string
function String.removeSpaces(str)
	assert(typeof(str) == "string", "Argument needs to be a string")

	local newString, numSpaces = string.gsub(str, "(%s)%s*", "")

	return newString
end

-- Removes all punctation in a string, uncluding special characters like @
function String.removePunc(str)
	assert(typeof(str) == "string", "Argument needs to be a string")

	local newString, numRemovals = string.gsub(str, "%p", "")

	return newString
end

-- Returns a table of start and end indexes of a pattern within a string
function String.getStringMatches(str, pattern)
	assert(typeof(str) == "string" and typeof(pattern) == "string", "Arguments need to be a strings")

	local found = 0
	local positions = {}
	while(found)do
		found += 1
		found = str:find(pattern, found)
		table.insert(positions, found)
	end

	return positions
end

-- Makes the first letter of a string lowercase
function String.lowerFirstLetter(str)
	assert(typeof(str) == "string", "Argument needs to be a string")

	return string.lower(str:sub(1, 1)) .. str:sub(2)
end

-- Makes the first letter of a string uppercase
function String.upperFirstLetter(str)
	assert(typeof(str) == "string", "Argument needs to be a string")

	return string.upper(str:sub(1, 1)) .. str:sub(2)
end

-- Returns the time in minute format (minutes:seconds)
function String.convertToMS(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = math.floor(seconds % 60)
	if minutes < 10 and seconds >= 10 then
		return "0"..minutes..":"..seconds
	elseif minutes >= 10 and seconds < 10 then
		return minutes..":0"..seconds
	elseif minutes < 10 and seconds < 10 then
		return "0"..minutes..":0"..seconds
	else
		return minutes..":"..seconds
	end
end

-- Returns the time in short hour format (hours:minutes)
function String.convertToHM(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local hoursText = hours
	local minutesText = minutes
	if hours < 10 then
		hoursText = "0" .. hours
	end
	if minutes < 10 then
		minutesText = "0" .. minutes
	end
	return hoursText .. ":" .. minutesText
end

-- Returns the time in hour format (hours:minutes:seconds)
function String.convertToHMS(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	seconds = math.floor(seconds % 60)
	local hoursText = hours
	local minutesText = minutes
	local secondsText = seconds
	if hours < 10 then
		hoursText = "0" .. hours
	end
	if minutes < 10 then
		minutesText = "0" .. minutes
	end
	if seconds < 10 then
		secondsText = "0" .. seconds
	end
	return hoursText .. ":" .. minutesText .. ":" .. secondsText
end

-- Converts a number to have commas in the correct places
function String.commaFormat(amount)
	local formatted = amount
	local k
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then
			break
		end
	end
	return formatted
  end

return String