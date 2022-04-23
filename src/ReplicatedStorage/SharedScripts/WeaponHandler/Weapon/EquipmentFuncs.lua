-- Functions for different types of equipment, these functions run when the player throws the equipment
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local playerHitByEquipment = getDataStream("PlayerHitByEquipment", "RemoteEvent")
local useEquipmentFunc = getDataStream("UseEquipmentFunc", "RemoteFunction")

local Trajectory = loadModule("Trajectory")
local Raycast = loadModule("Raycast")

local camera = workspace.CurrentCamera
local trajectory = Trajectory.new(Vector3.new(0, -game.Workspace.Gravity, 0))
local equipment = ReplicatedStorage.Assets.Equipment
local m62 = equipment:FindFirstChild("M62")

local EquipmentFuncs = {}

local GRENADE_TIMER = 4

-- When we throw the M62, just set it's velocity, wait a certain time and then explode and find the players near it (this function also support replication)
function EquipmentFuncs.M62throw(args)
	local settings = require(m62:FindFirstChild("Settings"))
	-- If we have a handler, that means this is the client that threw the grenade, and we don't want to invoke the server on replicated clients
	local isReplicated = args.handler == nil
	local newGrenade 
	local primaryPart = args.primaryPart
	
	if not isReplicated then
		newGrenade = Instance.new("Model")
		newGrenade.Name = "M62"
		for _, part in pairs(primaryPart.Parent:GetChildren()) do
			part.Parent = newGrenade
		end
	else
		newGrenade = m62:Clone()
		primaryPart = newGrenade.Receiver
	end
	primaryPart.Parent.Handle.CanCollide = true

	if args.welds then
		-- Disconnect the equipment from their hand
		for _, weld in pairs(args.welds) do
			if weld.Name == "equipment" then
				weld.Part1 = nil
			else
				weld.Part0 = nil
			end
		end
	end

	-- Get the velocity of the equipment
	local velocity = args.velocity or (camera.CFrame.LookVector * settings.velocity + settings.verticalVelocityAddition)
	if not isReplicated then
		-- Send to the server to invalidate or replicate to others
		task.spawn(function()
			local success = useEquipmentFunc:InvokeServer(primaryPart.Position, velocity, tick(), args.handler.currentEquipment.Name, args.handler.numEquipment)
			if not success then
				newGrenade:Destroy()
			end
		end)
	end

	-- Take the ping away from the time till explosion if it is a replicated grenade
	local timeTilExplode = GRENADE_TIMER
	if isReplicated and args.origin and args.timeThrown then
		newGrenade:SetPrimaryPartCFrame(CFrame.new(args.origin))
		local timePassed = tick() - args.timeThrown
		timeTilExplode -= timePassed
	end

	-- Had to use this custom trajectory calculation because Roblox physics are unreliable (grenade would go different ways on different clients)
	local ignoreList = {
		CollectionService:GetTagged("Accessory");
		CollectionService:GetTagged("Weapon");
		camera:FindFirstChild("ViewModel");
		newGrenade;
	}

	newGrenade.Parent = workspace
	task.delay(timeTilExplode, function()
		-- Create explosion and destroy the grenade
		local explosion = Instance.new("Explosion")
		explosion.Position = primaryPart.Position
		explosion.BlastRadius = 0
		explosion.Parent = game.Workspace
		newGrenade:Destroy()
		task.delay(1, function()
			explosion:Destroy()
		end)	

		if not isReplicated then
			local hitPlayers = {}
			for _, player in pairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
					local dist = (explosion.Position - player.Character.PrimaryPart.Position).Magnitude
					if dist > settings.blastRadius then continue end
					-- Raycast so you can't be hurt by grenades through walls
					local rayDirection = (player.Character.PrimaryPart.Position - explosion.Position).Unit
					local raycastResult = Raycast.new(ignoreList, "Blacklist", explosion.Position, rayDirection, dist * 1.5)
					if not raycastResult or raycastResult.Instance.Parent ~= player.Character then continue end
					table.insert(hitPlayers, {
						player = player;
						dist = dist;
					})
				end
			end
			if #hitPlayers > 0 then
				playerHitByEquipment:FireServer(hitPlayers, "M62")
			end
		end
	end)

	-- Had to use this custom trajectory calculation because Roblox physics are unreliable (grenade would go different ways on different clients)
	local path = trajectory:Cast(args.origin or primaryPart.Position, velocity, Enum.Material.Plastic, ignoreList)
	trajectory:Travel(primaryPart, path)
end

return EquipmentFuncs