-- Functions for different types of equipment, these functions run when the player throws the equipment
-- This could also be done with OOP where you make a new module per equipment and they inherit the throw function from the main class
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local playerHitByEquipment = getDataStream("PlayerHitByEquipment", "RemoteEvent")
local useEquipmentFunc = getDataStream("UseEquipmentFunc", "RemoteFunction")
local flashbangEvent = getDataStream("FlashbangEvent", "BindableEvent")

local Trajectory = loadModule("Trajectory")
local Raycast = loadModule("Raycast")

local camera = workspace.CurrentCamera
local trajectory = Trajectory.new(Vector3.new(0, -game.Workspace.Gravity, 0))
local equipment = ReplicatedStorage.Assets.Equipment
local fragGrenade = equipment:FindFirstChild("Frag Grenade")
local smokeGrenade = equipment:FindFirstChild("Smoke Grenade")
local flashbang = equipment:FindFirstChild("Flashbang")

local EquipmentFuncs = {}

local GRENADE_TIMER = 4
local SMOKE_TIMER = 8

-- General throwing function to be used by and equipment
function EquipmentFuncs.throw(args)
	local gameStatus = ReplicatedStorage.GameValues.GameStatus
	if gameStatus.Value ~= "GameRunning" then return end
	local settings = args.settings
	-- If we have a handler, that means this is the client that threw the grenade, and we don't want to invoke the server on replicated clients
	local isReplicated = args.handler == nil
	local newGrenade 
	local primaryPart = args.primaryPart
	
	if not isReplicated then
		newGrenade = Instance.new("Model")
		newGrenade.Name = "Grenade"
		for _, part in pairs(primaryPart.Parent:GetChildren()) do
			part.Parent = newGrenade
		end
	else
		newGrenade = args.model:Clone()
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
			local success = useEquipmentFunc:InvokeServer(primaryPart.Position, velocity, os.time(), args.handler.currentEquipment.Name, args.handler.numEquipment)
			if not success then
				newGrenade:Destroy()
			end
		end)
	end

	-- Had to use this custom trajectory calculation because Roblox physics are unreliable (grenade would go different ways on different clients)
	local ignoreList = {
		CollectionService:GetTagged("Accessory");
		CollectionService:GetTagged("Weapon");
		CollectionService:GetTagged("Foliage");
		newGrenade;
		workspace.Bullets;
	}

	if camera:FindFirstChild("ViewModel") then
		table.insert(ignoreList, camera:FindFirstChild("ViewModel"))
	end

	newGrenade.Parent = workspace

	task.spawn(function()
		if newGrenade:FindFirstChild("Main") and newGrenade.Main:FindFirstChild("Trail") then
			newGrenade.Main:FindFirstChild("Trail").Enabled = true
		end
		local ballPart = newGrenade:FindFirstChild("Handle")
		-- Had to use this custom trajectory calculation because Roblox physics are unreliable (grenade would go different ways on different clients)
		local path = trajectory:Cast(args.origin or ballPart.Position, velocity, Enum.Material.Plastic, ignoreList)
		trajectory:Travel(ballPart, path)
	end)
	return newGrenade
end

-- When we throw the M62, just set it's velocity, wait a certain time and then explode and find the players near it (this function also support replication)
function EquipmentFuncs.FragGrenadethrow(args)
	local gameStatus = ReplicatedStorage.GameValues.GameStatus
	if gameStatus.Value ~= "GameRunning" then return end
	local isReplicated = args.handler == nil
	local settings = require(fragGrenade:FindFirstChild("Settings"))
	
	args.settings = settings
	args.model = fragGrenade
	local newGrenade = EquipmentFuncs.throw(args)
	local primaryPart = newGrenade:FindFirstChild("Receiver")

	local ignoreList = {
		CollectionService:GetTagged("Accessory");
		CollectionService:GetTagged("Weapon");
		CollectionService:GetTagged("Foliage");
		newGrenade;
		workspace.Bullets;
	}

	if camera:FindFirstChild("ViewModel") then
		table.insert(ignoreList, camera:FindFirstChild("ViewModel"))
	end

	task.delay(GRENADE_TIMER, function()
		if not newGrenade.Parent then return end
		-- Create explosion and destroy the grenade
		local explosion = Instance.new("Explosion")
		explosion.Position = primaryPart.Position
		explosion.BlastRadius = 0
		explosion.Parent = game.Workspace
		local newSoundPart = Instance.new("Part")
		newSoundPart.Anchored = true
		newSoundPart.Position = primaryPart.Position
		newSoundPart.CanCollide = false
		newSoundPart.Size = Vector3.new(0.1, 0.1, 0.1)
		newSoundPart.Transparency = 1
		newSoundPart.Parent = workspace	
		primaryPart:FindFirstChild("ExplodeSound").Parent = newSoundPart
		newSoundPart:FindFirstChild("ExplodeSound"):Play()
		newGrenade:Destroy()
		task.delay(1, function()
			explosion:Destroy()
		end)
		task.delay(4, function()
			newSoundPart:Destroy()
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
				playerHitByEquipment:FireServer(hitPlayers, "Frag Grenade", explosion.Position, args.handler.numEquipment)
			end
		end
	end)
end

-- Same as M62 but doesn't explode just releases smoke
function EquipmentFuncs.SmokeGrenadethrow(args)
	local gameStatus = ReplicatedStorage.GameValues.GameStatus
	if gameStatus.Value ~= "GameRunning" then return end
	local settings = require(smokeGrenade:FindFirstChild("Settings"))
	
	args.settings = settings
	args.model = smokeGrenade
	local newGrenade = EquipmentFuncs.throw(args)
	local primaryPart = newGrenade:FindFirstChild("Receiver")

	task.delay(2, function()
		primaryPart:FindFirstChild("SmokeParticles").Enabled = true
		if primaryPart:FindFirstChild("ExplodeSound") then
			primaryPart:FindFirstChild("ExplodeSound"):Play()
		end
		local newSmokePart = Instance.new("Part")
		newSmokePart.Anchored = true
		newSmokePart.Position = primaryPart.Position
		newSmokePart.CanCollide = false
		newSmokePart.Transparency = 1
		newSmokePart.Size = Vector3.new(0.1, 0.1, 0.1)
		newSmokePart.Parent = workspace
		primaryPart:FindFirstChild("SmokeParticles").Parent = newSmokePart
		primaryPart.Anchored = true
		task.wait(SMOKE_TIMER)
		-- Put particles inside a separate part so that the particles don't just instantly disappear
		primaryPart:FindFirstChild("ExplodeSound").Parent = newSmokePart
		newSmokePart:FindFirstChild("SmokeParticles").Enabled = false
		newGrenade:Destroy()
		task.delay(5, function()
			newSmokePart:Destroy()
		end)
	end)
end

-- Same as others but when it explodes, we fire a flashbang event to make players screens go white depending on their distance / look vector from the flashbang
function EquipmentFuncs.Flashbangthrow(args)
	local gameStatus = ReplicatedStorage.GameValues.GameStatus
	if gameStatus.Value ~= "GameRunning" then return end
	local settings = require(flashbang:FindFirstChild("Settings"))
	
	args.settings = settings
	args.model = flashbang
	local newGrenade = EquipmentFuncs.throw(args)
	local primaryPart = newGrenade:FindFirstChild("Receiver")

	task.delay(GRENADE_TIMER, function()
		if primaryPart:FindFirstChild("ExplodeSound") then
			local newSoundPart = Instance.new("Part")
			newSoundPart.Anchored = true
			newSoundPart.Position = primaryPart.Position
			newSoundPart.CanCollide = false
			newSoundPart.Size = Vector3.new(0.1, 0.1, 0.1)
			newSoundPart.Transparency = 1
			newSoundPart.Parent = workspace	
			primaryPart:FindFirstChild("ExplodeSound").Parent = newSoundPart
			newSoundPart.ExplodeSound:Play()
			newSoundPart.ExplodeSound.TimePosition = 0.4
			-- Emit particles for flashbang
			for _, particle in pairs(newGrenade.Main:GetChildren()) do
				if particle:IsA("ParticleEmitter") then
					particle.Parent = newSoundPart
					particle:Emit(particle.Rate)
				end
			end
			newGrenade:Destroy()
			flashbangEvent:Fire(primaryPart.Position, newGrenade, newSoundPart)
			task.delay(5, function()
				newSoundPart:Destroy()
			end)
		end
	end)
end

return EquipmentFuncs