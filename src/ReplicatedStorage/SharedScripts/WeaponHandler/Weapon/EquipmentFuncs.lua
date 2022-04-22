-- Functions for different types of equipment, these functions run when the player throws the equipment
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local useEquipmentFunc = getDataStream("UseEquipment", "RemoteFunction")

local camera = workspace.CurrentCamera

local EquipmentFuncs = {}

-- When we throw the M62, just set it's velocity, wait a certain time and then explode and find the players near it
function EquipmentFuncs.M62throw(primaryPart, welds, handler)
	local newGrenade = Instance.new("Model", workspace)
	newGrenade.Name = "M62"
	for _, part in pairs(primaryPart.Parent:GetChildren()) do
		part.Parent = newGrenade
	end
	primaryPart.Parent.Handle.CanCollide = true
	-- Disconnect the equipment from their hand
	for _, weld in pairs(welds) do
		if weld.Name == "equipment" then
			weld.Part1 = nil
		else
			weld.Part0 = nil
		end
	end

	-- Get the origin and velocity of the equipment and send to the server to invalidate or replicate to others
	local origin = primaryPart.Position
	local velocity = camera.CFrame.LookVector * 100 + Vector3.new(0, 30, 0)

	task.spawn(function()
		local success = useEquipmentFunc:InvokeServer(origin, velocity, handler.currentEquipment, handler.numEquipment)
		if not success then
			newGrenade:Destroy()
		end
	end)
	primaryPart.AssemblyLinearVelocity = velocity
end

return EquipmentFuncs