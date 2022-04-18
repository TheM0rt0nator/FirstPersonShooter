-- Useful functions to do with time

local Time = {}

-- Returns the Unix Timestamp in seconds
function Time:GetCurrentUnixTime()
	local now = DateTime.now()
	return now.UnixTimestamp
end

-- Returns the Unix Timestamp in milliseconds
function Time:GetCurrentUnixTimeMillis()
	local now = DateTime.now()
	return now.UnixTimestampMillis
end

-- Waits for a real amount of time by checking the actual time now to ensure the exact amount of time has passed
function Time:WaitRealTime(time)
	local startTime = Time:GetCurrentUnixTimeMillis()
	local endTime = startTime + time * 1000
	local waitInterval = (time <= 1 and 0.01) or 1
	while Time:GetCurrentUnixTimeMillis() < endTime do
		task.wait(waitInterval)
	end
end

return Time