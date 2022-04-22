local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local setEquippedKit = getDataStream("SetEquippedKit", "RemoteEvent")
local fireWeaponEvent = getDataStream("FireWeapon", "RemoteEvent")
local aimWeaponEvent = getDataStream("AimWeapon", "RemoteEvent")
local playerHitEvent = getDataStream("PlayerHit", "RemoteEvent")
local equipWeaponFunc = getDataStream("EquipWeapon", "RemoteFunction")
local reloadWeaponFunc = getDataStream("ReloadWeapon", "RemoteFunction")
local playerKilledEvent = getDataStream("LocalPlayerKilled", "BindableEvent")

local WeaponKits = loadModule("WeaponKits")
local BulletRender = loadModule("BulletRender")
local Weapon = loadModule("Weapon")
local Keybinds = loadModule("Keybinds")
local UserInput = loadModule("UserInput")

local setInterfaceState = RunService:IsClient() and getDataStream("SetInterfaceState", "BindableEvent")

local gravity = Vector3.new(0, workspace.Gravity, 0)

local WeaponHandler = {
	MAX_WEAPONS = 2;
	players = {};
}

-- SERVER FUNCTIONS --
function WeaponHandler:initiate()
	if RunService:IsClient() then return end
	task.spawn(function()
		-- Run playerAdded for any players already in-game
		for _, player in pairs(Players:GetPlayers()) do
			WeaponHandler.playerAdded(player)
		end
		Players.PlayerAdded:Connect(WeaponHandler.playerAdded)
		Players.PlayerRemoving:Connect(WeaponHandler.playerRemoving)
	end)
end

-- When player asks server to set their equipped kit, make sure the kit exists and then equip the weapons in the kit
function WeaponHandler.setEquippedKit(player, kit)
	-- Could add checks here if there are unlockable kits which the player doesn't have
	if WeaponKits[kit] and #WeaponKits[kit].Weapons <= WeaponHandler.MAX_WEAPONS then
		-- Wait for their character to exist
		if not player.Character then
			player.CharacterAdded:Wait()
		end

		-- Clone gun and save it in the players table
		local primaryWeapon = ReplicatedStorage.Assets.Weapons[WeaponKits[kit].Weapons.Primary]:Clone()
		local secondaryWeapon = ReplicatedStorage.Assets.Weapons[WeaponKits[kit].Weapons.Secondary]:Clone()
		local primaryWeaponSettings = require(primaryWeapon.Settings)
		local secondaryWeaponSettings = require(secondaryWeapon.Settings)

		-- Don't want bullets to hit these 
		CollectionService:AddTag(primaryWeapon, "Weapon")
		CollectionService:AddTag(secondaryWeapon, "Weapon")

		-- Could add code here to edit settings for the gun (larger or more magazines etc)
		
		WeaponHandler.players[tostring(player.UserId)] = {
			currentKit = kit;
			equipped = "primary";
			weapons = {
				primary = {
					model = primaryWeapon;
					settings = primaryWeaponSettings;
					magData = {
						ammo = primaryWeaponSettings.magCapacity;
						spare = primaryWeaponSettings.spareBullets;
					};
				};
				secondary = {
					model = secondaryWeapon;
					settings = secondaryWeaponSettings;
					magData = {
						ammo = secondaryWeaponSettings.magCapacity;
						spare = secondaryWeaponSettings.spareBullets;
					};
				};
			};
		}
		
		if player.Character then
			-- Attach the primary gun to the player
			primaryWeapon.Parent = player.Character
			primaryWeapon.Receiver:WaitForChild("BackWeld").Part0 = nil
			primaryWeapon.Receiver:WaitForChild("WeaponHold").Part0 = player.Character["RightHand"]
			-- Load the server animations for the weapons
			WeaponHandler.players[tostring(player.UserId)].weapons.primary.loadedAnimations = {
				idle = player.Character.Humanoid:LoadAnimation(primaryWeapon.ServerAnimations.Idle);
				aim = player.Character.Humanoid:LoadAnimation(primaryWeapon.ServerAnimations.Aim);
				aimFire = player.Character.Humanoid:LoadAnimation(primaryWeapon.ServerAnimations.AimFire);
				idleFire = player.Character.Humanoid:LoadAnimation(primaryWeapon.ServerAnimations.HipFire);
			};

			-- Attach the secondary gun to the player
			secondaryWeapon.Parent = player.Character
			secondaryWeapon.Receiver:WaitForChild("WeaponHold").Part0 = nil
			secondaryWeapon.Receiver:WaitForChild("BackWeld").Part0 = player.Character:WaitForChild("UpperTorso")
			-- Load the server animations for the weapons
			WeaponHandler.players[tostring(player.UserId)].weapons.secondary.loadedAnimations = {
				idle = player.Character.Humanoid:LoadAnimation(secondaryWeapon.ServerAnimations.Idle);
				aim = player.Character.Humanoid:LoadAnimation(secondaryWeapon.ServerAnimations.Aim);
				aimFire = player.Character.Humanoid:LoadAnimation(secondaryWeapon.ServerAnimations.AimFire);
				idleFire = player.Character.Humanoid:LoadAnimation(secondaryWeapon.ServerAnimations.HipFire);
			};

			return true
		end
	end
end

-- Checks to see if the player has the weapon they are trying to use equipped
function WeaponHandler.weaponCheck(player, weapon)
	local playersVals = WeaponHandler.players[tostring(player.UserId)]
	if not playersVals or not playersVals.currentKit then return end
	local hasWeapon
	for _, weaponInfo in pairs(playersVals.weapons) do
		if weaponInfo.model.Name == weapon then
			hasWeapon = true
			break
		end
	end
	if not hasWeapon or not player.Character then return end
	return playersVals, true
end

-- When a player equips a weapon, do checks to make sure they can (they are spawned in the game etc) and play the server animation
function WeaponHandler.equipWeapon(player, weapon, bool)
	local playersVals, hasWeapon = WeaponHandler.weaponCheck(player, weapon)
	if not hasWeapon or not player.Character then return end
	if bool then
		-- Set the players equipped gun to either primary or secondary
		for weaponNum, weaponInfo in pairs(playersVals.weapons) do
			if weaponInfo.model.Name == weapon then
				playersVals.equipped = weaponNum
				break
			end
		end
	end
	
	-- Check if the current equipped weapon exists or not
	if not playersVals.weapons[playersVals.equipped] then return end
	local weaponModel = playersVals.weapons[playersVals.equipped].model

	-- Equip
	if bool then
		-- Unholster the gun and weld it to the players hand
		weaponModel.Receiver.BackWeld.Part0 = nil
		weaponModel.Receiver.WeaponHold.Part0 = player.Character["RightHand"]
		playersVals.weapons[playersVals.equipped].loadedAnimations.idle:Play()
	-- Unequip
	else
		-- Holster the gun
		weaponModel.Receiver.WeaponHold.Part0 = nil
		weaponModel.Receiver.BackWeld.Part0 = player.Character["UpperTorso"]
		for _, anim in pairs(playersVals.weapons[playersVals.equipped].loadedAnimations) do
			anim:Stop()
		end
	end	

	return true 
end

-- Players asks the server to reload, and server checks if they can and then updates the ammo on the server
function WeaponHandler.reloadWeapon(player, weapon, clientAmmo, clientSpare)
	local playersVals, hasWeapon = WeaponHandler.weaponCheck(player, weapon)
	if not hasWeapon then return end
	local weaponData = playersVals.weapons[playersVals.equipped]
	local weaponAmmoData = weaponData.magData
	if weaponAmmoData.ammo ~= clientAmmo or weaponAmmoData.spare ~= clientSpare then return end
	local neededBullets = weaponData.settings.magCapacity - weaponAmmoData.ammo
	local givenBullets = neededBullets
	if neededBullets > weaponAmmoData.spare then
		givenBullets = weaponAmmoData.spare
	end
	weaponAmmoData.spare -= givenBullets
	weaponAmmoData.spare = math.clamp(weaponAmmoData.spare, 0, weaponData.settings.spareBullets)
	weaponAmmoData.ammo += givenBullets
	return true
end

-- When a player fires a weapon, make sure they have enough ammo and replicate to other players
function WeaponHandler.fireWeapon(player, weapon, origin, velocity)
	local playersVals, hasWeapon = WeaponHandler.weaponCheck(player, weapon)
	if not hasWeapon then return end
	-- If server says they have no ammo, they have no ammo and don't do anything
	if playersVals.weapons[playersVals.equipped].magData.ammo <= 0 then return end
	-- Take one away from the server ammo
	playersVals.weapons[playersVals.equipped].magData.ammo -= 1

	fireWeaponEvent:FireAllClients(player, origin, velocity, weapon)
	if playersVals.aiming then 
		playersVals.weapons[playersVals.equipped].loadedAnimations.aimFire:Play()	
	else
		playersVals.weapons[playersVals.equipped].loadedAnimations.idleFire:Play()
	end
end

-- When a player aims their weapon, make sure they have that weapon equipped and then play the aim animation on the server
function WeaponHandler.aimWeapon(player, weapon, bool)
	local playersVals, hasWeapon = WeaponHandler.weaponCheck(player, weapon)
	if not hasWeapon or not player.Character then return end

	playersVals.aiming = bool
	-- Either play or stop the aiming animation
	if bool then
		playersVals.weapons[playersVals.equipped].loadedAnimations.aim:Play()
	else
		playersVals.weapons[playersVals.equipped].loadedAnimations.aim:Stop()
	end	
end

-- When a player is hit, need to check to make sure the hit is valid and then deal damage
function WeaponHandler.playerHit(player, weapon, bulletNum, hitPart)
	if hitPart.Parent and hitPart.Parent:FindFirstChild("Humanoid") and hitPart.Parent.Humanoid.Health > 0 then--and Players:FindFirstChild(hitPart.Parent.Name) then
		local playersVals = WeaponHandler.players[tostring(player.UserId)]
		local weaponsStats = playersVals.weapons[playersVals.equipped].settings
		local damage = (hitPart.Name == "Head" and weaponsStats.headshot) or weaponsStats.damage
		hitPart.Parent.Humanoid:TakeDamage(damage)
		if hitPart.Parent.Humanoid.Health <= 0 then
			playerKilledEvent:Fire(player, Players:FindFirstChild(hitPart.Parent.Name), weapon)
		end
	end
end


-- CLIENT FUNCTIONS --

-- Creates the weapon objects and sets up the input to equip them
function WeaponHandler:setupWeapons(kit)
	if RunService:IsServer() then return end
	if not self.weaponObjects then
		self.weaponObjects = {}
	end
	self.isUsingEquipment = false

	-- Collect our equipment models (support for multiple equipment per kit, but not implemented switching between equipments)
	self.storedEquipment = {}
	for _, equipmentInfo in pairs(WeaponKits[kit].Equipment) do
		self.storedEquipment[equipmentInfo.Name] = ReplicatedStorage.Assets.Equipment:FindFirstChild(equipmentInfo.Name)
	end
	self.currentEquipment = WeaponKits[kit].Equipment[1]
	self.numEquipment = self.currentEquipment.Amount

	for weaponNum, weapon in pairs(WeaponKits[kit].Weapons) do
		local weaponObj = Weapon.new(weapon, self)
		self.weaponObjects[weaponNum] = weaponObj

		-- Connects all the inputs from keybinds module to equip this weapon
		for bindNum, keybind in ipairs(Keybinds["Equip" .. weaponNum]) do
			local inputType = (keybind.EnumType == Enum.UserInputType and keybind) or Enum.UserInputType.Keyboard
			local keyCode = keybind.EnumType == Enum.KeyCode and keybind
			UserInput.connectInput(inputType, keyCode, "EquipWeapon" .. weaponNum .. bindNum, {
				endedFunc = function()
					if not weaponObj.equipped and not self.isUsingEquipment then
						local otherWeapon = weaponNum == "Primary" and "Secondary" or "Primary"
						self.weaponObjects[otherWeapon]:unequip()
						weaponObj:equip(true)
						self.equipped = weaponNum
					end
				end;
			}, true)
		end

		if weaponNum == "Primary" then
			weaponObj:equip(true)
		end
		self.equipped = "Primary"
	end

	-- Connect using equipment inputs
	for bindNum, keybind in pairs(Keybinds.UseEquipment) do
		local inputType = (string.find(keybind.Name, "Button") and Enum.UserInputType.Gamepad1) or Enum.UserInputType.Keyboard
		UserInput.connectInput(inputType, keybind, "UseEquipment" .. bindNum, {
			beganFunc = function()
				if not self.isUsingEquipment then
					self.isUsingEquipment = true
					self.equipmentHeld = true
					self.weaponObjects[self.equipped]:useEquipment(self)
					self.isUsingEquipment = false
				end
			end;
			endedFunc = function()
				self.equipmentHeld = false
			end;
		}, true)
	end
	setInterfaceState:Fire("inGame")
end

-- Function which is called when another player shoots their gun and we want to replicate their bullets
function WeaponHandler.replicateBullet(fromPlayer, origin, velocity, weapon)
	if Players.LocalPlayer == fromPlayer then return end
	local bullet = ReplicatedStorage.Assets.Other.Bullet:Clone()
	bullet.Size = Vector3.new(0.05, 0.05, velocity.Magnitude / 200)
	bullet.CFrame = CFrame.new(origin + velocity.Unit * bullet.Size.Z, origin + velocity.Unit * bullet.Size.Z * 2)
	bullet.Parent = workspace.Bullets

	-- If we can, play the firing sound on this client too
	if fromPlayer.Character 
		and fromPlayer.Character:FindFirstChild(weapon) 
		and fromPlayer.Character:FindFirstChild(weapon):FindFirstChild("Receiver") 
		and fromPlayer.Character[weapon].Receiver:FindFirstChild("FireSound") 
	then
		-- Play the firing sound every time we fire on the server too
		local sound = fromPlayer.Character[weapon].Receiver.FireSound:Clone()
		sound.Parent = fromPlayer.Character[weapon].Receiver
		sound:Play()
		
		task.delay(2, function()
			sound:Destroy()
		end)
	end

	-- Fire a raycast bullet to calculate actual hits
	WeaponHandler.BulletRender:fire(origin, velocity, gravity, 2000, "Blacklist", {workspace.Camera, Players.LocalPlayer.Character}, bullet, true)
end

-- When the player joins, create a table for them so we can store the weapons they currently have equipped
function WeaponHandler.playerAdded(player)
	WeaponHandler.players[tostring(player.UserId)] = {}
end

-- When the player leaves, delete their weapon table
function WeaponHandler.playerRemoving(player)
	if WeaponHandler.players[tostring(player.UserId)] then
		WeaponHandler.players[tostring(player.UserId)] = nil
	end
end

-- Connect all the remotes
if RunService:IsServer() then
	setEquippedKit.OnServerEvent:Connect(WeaponHandler.setEquippedKit)
	fireWeaponEvent.OnServerEvent:Connect(WeaponHandler.fireWeapon)
	aimWeaponEvent.OnServerEvent:Connect(WeaponHandler.aimWeapon)
	playerHitEvent.OnServerEvent:Connect(WeaponHandler.playerHit)
	equipWeaponFunc.OnServerInvoke = WeaponHandler.equipWeapon
	reloadWeaponFunc.OnServerInvoke = WeaponHandler.reloadWeapon
elseif RunService:IsClient() then
	-- Create a new bullet renderer for other players bullets
	WeaponHandler.BulletRender = BulletRender.new()
	fireWeaponEvent.OnClientEvent:Connect(WeaponHandler.replicateBullet)
end

return WeaponHandler