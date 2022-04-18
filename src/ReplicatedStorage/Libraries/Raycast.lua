-- Useful functions for Raycasting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Table = loadModule("Table")

local Raycast = {}

-- Returns a raycast result with the given arguments
function Raycast.new(filterInstances, filterType, origin, direction, length)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = filterInstances
	raycastParams.FilterType = Enum.RaycastFilterType[filterType]

	return workspace:Raycast(origin, direction * length, raycastParams)
end

-- Returns a table of all of the parts hit by a ray or nil if no parts are hit
function Raycast.getAllHitParts(filterInstances, filterType, origin, direction, length)
	local hitParts = {}

	local function getHitParts(thisOrigin, thisLength)
		local hit = Raycast.new(filterInstances, filterType, thisOrigin, direction, thisLength)
		if hit and hit.Instance and not Table.contains(hitParts, hit.Instance) then
			table.insert(hitParts, hit.Instance)
			local hitPos = hit.Position
			local dist = (hitPos - thisOrigin).Magnitude
			thisLength -= dist
			getHitParts(hitPos, thisLength)
		end
	end
	getHitParts(origin, length)

	return (#hitParts > 0 and hitParts) or nil
end

-- Returns the first model hit by the ray or nil
function Raycast.getFirstHitModel(filterInstances, filterType, origin, direction, length)
	local function getHitModel(thisOrigin, thisLength)
		local hit = Raycast.new(filterInstances, filterType, thisOrigin, direction, thisLength)
		if hit and hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model") then
			return hit.Instance:FindFirstAncestorOfClass("Model")
		elseif hit and hit.Instance then
			local hitPos = hit.Position
			local dist = (hitPos - thisOrigin).Magnitude
			thisLength -= dist
			getHitModel(hitPos, thisLength)
		end
	end
	return getHitModel(origin, length)
end

-- Returns a table of all of the models hit by a ray or nil if no parts are hit
function Raycast.getAllHitModels(filterInstances, filterType, origin, direction, length)
	local hitModels = {}
	local hitParts = Raycast.getAllHitParts(filterInstances, filterType, origin, direction, length)
	for _, part in pairs(hitParts) do
		local hitModel = part:FindFirstAncestorOfClass("Model")
		if hitModel and not Table.contains(hitModels, hitModel) then
			table.insert(hitModels, hitModel)
		end
	end
	return (#hitModels > 0 and hitModels) or nil
end

-- Returns a table of all of the players hit by a ray or nil if no parts are hit
function Raycast.getAllHitPlayers(filterInstances, filterType, origin, direction, length)
	local hitPlayers = {}
	local hitParts = Raycast.getAllHitParts(filterInstances, filterType, origin, direction, length)
	if not hitParts then return end
	for _, part in pairs(hitParts) do
		local hitModel = part:FindFirstAncestorOfClass("Model")
		if hitModel and hitModel:FindFirstChild("Humanoid") and hitModel:FindFirstChild("Humanoid"):IsA("Humanoid") then
			local player = Players:GetPlayerFromCharacter(hitModel)
			if not Table.contains(hitPlayers, player) then
				table.insert(hitPlayers, hitModel)
			end
		end
	end
	return (#hitPlayers > 0 and hitPlayers) or nil
end

-- Casts a ray and shows it's path using a part, returning this part
function Raycast.showRayAsPart(origin, direction, length, parent)
	local newRaycastPart = Instance.new("Part", parent)
	newRaycastPart.Anchored = true
	newRaycastPart.CanCollide = false
	newRaycastPart.Size = Vector3.new(0.1, 0.1, length)
	newRaycastPart.Color = Color3.fromRGB(255, 0, 0)
	local endPos = origin + direction * length
	newRaycastPart.CFrame = CFrame.new(origin, endPos) * CFrame.new(0, 0, -length / 2)
	return newRaycastPart
end

return Raycast