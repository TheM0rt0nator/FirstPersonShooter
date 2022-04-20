local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local WeaponKits = loadModule("WeaponKits")
local BulletRender = loadModule("BulletRender")

local setEquippedKit = getDataStream("SetEquippedKit", "RemoteEvent")
local fireWeaponEvent = getDataStream("FireWeapon", "RemoteEvent")
local aimWeaponEvent = getDataStream("AimWeapon", "RemoteEvent")
local playerHitEvent = getDataStream("PlayerHit", "RemoteEvent")
local equipWeaponFunc = getDataStream("EquipWeapon", "RemoteFunction")
local reloadWeaponFunc = getDataStream("ReloadWeapon", "RemoteFunction")

local gravity = Vector3.new(0, workspace.Gravity, 0)

local WeaponHandler = {
	MAX_WEAPONS = 2;
	players = {};
}

-- When player asks server to set their equipped kit, make sure the kit exists and then equip the weapons in the kit
function WeaponHandler.setEquippedKit(player, kit)
	if WeaponKits[kit] and #WeaponKits[kit].Weapons <= WeaponHandler.MAX_WEAPONS then
		-- Wait for their character to exist
		if not player.Character then
			player.CharacterAdded:Wait()
		end

		-- Clone gun and save it in the players table
		local weapon = ReplicatedStorage.Assets.Weapons[WeaponKits[kit].Weapons.Primary]:Clone()
		local weaponSettings = require(weapon.Settings)

		-- Could add code here to edit settings for the gun (larger or more magazines etc)
		
		WeaponHandler.players[tostring(player.UserId)] = {
			currentKit = kit;
			equipped = "primary";
			weapons = {
				primary = {
					model = weapon;
					settings = weaponSettings;
					magData = {
						ammo = weaponSettings.weaponStats.magCapacity;
						spare = weaponSettings.weaponStats.spareBullets;
					};
				};
			};
		}
		
		if player.Character then
			-- Attach the secondary gun to the player
			weapon.Parent = player.Character
			weapon.Receiver:WaitForChild("BackWeld").Part0 = player.Character:WaitForChild("UpperTorso")
			-- Load the server animations for the weapons
			WeaponHandler.players[tostring(player.UserId)].weapons.primary.loadedAnimations = {
				idle = player.Character.Humanoid:LoadAnimation(weapon.ServerAnimations.Idle);
				aim = player.Character.Humanoid:LoadAnimation(weapon.ServerAnimations.Aim);
				aimFire = player.Character.Humanoid:LoadAnimation(weapon.ServerAnimations.AimFire);
				idleFire = player.Character.Humanoid:LoadAnimation(weapon.ServerAnimations.HipFire);
			};
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
		playersVals.equipped = if playersVals.weapons.primary.model.Name == weapon then "primary" else "secondary"
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
		playersVals.weapons[playersVals.equipped].loadedAnimations.idle:Stop()
		playersVals.weapons[playersVals.equipped].loadedAnimations.aim:Stop()
		playersVals.weapons[playersVals.equipped].loadedAnimations.aimFire:Stop()	
		playersVals.weapons[playersVals.equipped].loadedAnimations.idleFire:Stop()
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
	local neededBullets = weaponData.settings.weaponStats.magCapacity - weaponAmmoData.ammo
	local givenBullets = neededBullets
	if neededBullets > weaponAmmoData.spare then
		givenBullets = weaponAmmoData.spare
	end
	weaponAmmoData.spare -= givenBullets
	weaponAmmoData.spare = math.clamp(weaponAmmoData.spare, 0, weaponData.settings.weaponStats.spareBullets)
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
	fireWeaponEvent:FireAllClients(player, origin, velocity)
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
	local weaponsStats = playersVals.weapons[playersVals.equipped].settings.weaponStats
	local damage = (hitPart.Name == "Head" and weaponsStats.headshot) or weaponsStats.damage
		hitPart.Parent.Humanoid:TakeDamage(damage)
	end
end

-- Function which is called when another player shoots their gun and we want to replicate their bullets
function WeaponHandler.replicateBullet(fromPlayer, origin, velocity)
	if Players.LocalPlayer == fromPlayer then return end
	local bullet = ReplicatedStorage.Assets.Other.Bullet:Clone()
	bullet.Size = Vector3.new(0.05, 0.05, velocity.Magnitude / 200)
	bullet.CFrame = CFrame.new(origin + velocity.Unit * bullet.Size.Z, origin + velocity.Unit * bullet.Size.Z * 2)
	bullet.Parent = workspace.Bullets

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

-- Run playerAdded for any players already in-game
for _, player in pairs(Players:GetPlayers()) do
	WeaponHandler.playerAdded(player)
end
Players.PlayerAdded:Connect(WeaponHandler.playerAdded)
Players.PlayerRemoving:Connect(WeaponHandler.playerRemoving)

return WeaponHandler