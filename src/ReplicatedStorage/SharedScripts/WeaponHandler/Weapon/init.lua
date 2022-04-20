local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Maths = loadModule("Maths")
local Spring = loadModule("Spring")
local UserInput = loadModule("UserInput")
local Keybinds = loadModule("Keybinds")
local HitDetector = loadModule("HitDetector")

local hitPlayerEvent = getDataStream("HitPlayerEvent", "BindableEvent")

local rand = Random.new()
local gravity = Vector3.new(0, workspace.Gravity, 0)

local Weapon = {}
Weapon.__index = Weapon

-- Create a new weapon object
function Weapon.new(name)
	local self = {
		name = name;
		canFire = true;
		loadedAnimations = {};
		hitDetector = HitDetector.new();
		springs = {
			movementTilt = Spring.new();
			walkCycle = Spring.new();
			sway = Spring.new();
			recoil = Spring.new(4, 100, nil, 6);
		};
		lerpValues = {
			aim = Instance.new("NumberValue");
			walkspeed = Instance.new("NumberValue");
			sprint = Instance.new("NumberValue");
			-- This is so that the sprint offset doesn't apply when we are stationary or going backwards
			idleOverride = Instance.new("NumberValue");
		};
	}

	-- Connect a listener to the hit event so we can do damage etc
	self.hitConnection = self.hitDetector.hitEvent.Event:Connect(function(part)
		if part.Parent and part.Parent:FindFirstChild("Humanoid") and part.Parent.Humanoid.Health > 0 then
			part.Parent.Humanoid:TakeDamage(5)
			-- Fire a bindable to tell the UI to show hitmarkers
			hitPlayerEvent:Fire(part)
		end
	end)
	setmetatable(self, Weapon)

	return self
end

-- Equip the weapon
function Weapon:equip()
	if self.disabled then return end

	-- Get a clone of the weapon, or cancel the function if the weapon doesn't exist
	local weapon = ReplicatedStorage.Assets.Weapons:FindFirstChild(self.name)
	if not weapon then return end
	weapon = weapon:Clone()

	-- Get a viewmodel and put the weapons contents inside it
	self.viewmodel = ReplicatedStorage.Assets.Other.ViewModel:Clone()
	for _, instance in pairs(weapon:GetChildren()) do
		instance.Parent = self.viewmodel
		if instance:IsA("BasePart") then
			instance.CanCollide = false
			instance.CastShadow = false
		end
	end	

	self.camera = workspace.CurrentCamera
	self.char = Players.LocalPlayer.Character
	
	-- Bound the gun to the viewmodels root part
	self.viewmodel.RootPart.weapon.Part1 = self.viewmodel.WeaponRootPart
	self.viewmodel.Left.leftHand.Part0 = self.viewmodel.WeaponRootPart
	self.viewmodel.Right.rightHand.Part0 = self.viewmodel.WeaponRootPart
	self.viewmodel.Parent = workspace.Camera
	
    -- Save the settings table
	self.settings = require(self.viewmodel.Settings)
	self.weaponStats = self.settings.weaponStats

	-- Setup the magazine and ammunition
	self.ammo = self.weaponStats.magCapacity
	self.spareBullets = self.weaponStats.spareBullets

    -- Load animations from settings
	self:loadAnimations()
	self.loadedAnimations.idle:Play(0) --no lerp time from default pos to prevent stupid looking arms for no longer than 0 frames	

	-- Connect inputs
	self:connectInput()
	
	-- Gun successfully equipped
	self.equipped = true
end

-- Unequip the weapon
function Weapon:unequip()
	-- Disconnect inputs
	self:disconnectInput()
	-- Destroy the viewmodel, which also destroys the gun, and set equipped to false
	self.viewmodel:Destroy()
    self.viewmodel = nil
	self.equipped = false
end

-- Activate / deactivate firing the weapon
function Weapon:fire(bool)
	-- Check to make sure we can fire the weapon
	if self.reloading or not self.equipped then return end
	if self.firing and bool then return end 

	if bool and self.ammo <= 0 then
		self:reload()
		return
	end

	if not self.canFire and bool then return end

	-- Set the firing value to the bool and then return if we are not firing anymore
	self.firing = bool
	if not bool then return end
	if self.isSprinting then
		self:sprint(false, true)
	end

	local function fire()
		if self.ammo <= 0 then 
			self.firing = false 
			return 
		end
		-- Play the firing sound every time we fire
		local sound = self.viewmodel.Receiver.FireSound:Clone()
		sound.Parent = self.viewmodel.Receiver
		sound:Play()
		
		task.delay(2, function()
			sound:Destroy()
		end)
		
		-- Muzzle flash
		for _, v in pairs(self.viewmodel.Receiver.MuzzleFlashAttachment:GetChildren()) do
			if v:IsA("ParticleEmitter") then
				v:Emit(v.Rate)
			end
		end	

		-- Take one round out of the ammo every time we fire
		self.ammo -= 1
		print(self.ammo)

		-- Render a real bullet for visuals
		local origin = self.viewmodel.Barrel.Position
		local bulletDirection = (self.viewmodel.Muzzle.Position - origin).Unit

		local bullet = ReplicatedStorage.Assets.Other.Bullet:Clone()
		bullet.Size = Vector3.new(0.05, 0.05, self.weaponStats.velocity / 200)
		bullet.CFrame = CFrame.new(origin + bulletDirection * bullet.Size.Z, origin + bulletDirection * bullet.Size.Z * 2)
		bullet.Parent = workspace.Bullets
		-- Fire a raycast bullet to calculate actual hits
		self.hitDetector:fire(origin, bulletDirection * self.weaponStats.velocity, gravity, self.weaponStats.range, "Blacklist", {self.viewmodel, self.char}, bullet)

		-- Shove the recoil spring to make the camera shake when we shoot, using the values from this guns settings to change the amount of recoil
		local verticalRecoil = rand:NextNumber(0.15, 0.2) * self.recoilFactor * (self.weaponStats.verticalRecoilFactor or 1)
		local horizontalRecoil = rand:NextNumber(-0.05, 0.05) * self.recoilFactor * (self.weaponStats.horizontalRecoilFactor or 1)
		self.springs.recoil:shove(Vector3.new(verticalRecoil, horizontalRecoil, 0))
		task.spawn(function()
			task.wait(.15)
			self.springs.recoil:shove(Vector3.new(-verticalRecoil, -horizontalRecoil, 0))
		end)
		
		task.wait(60 / self.weaponStats.rpm)
	end
	
	-- Keep firing the gun until the firing value is set to false, and ensure the function only runs once per fire
	repeat
		self.canFire = false
		fire()
		self.canFire = true
	until not self.firing
end

-- Changes the aim lerp value to tell the viewport where to go
function Weapon:aim(bool)
	if self.disabled or not self.equipped then return end
	if not self.equipped then return end
	self.aiming = bool
	UserInputService.MouseIconEnabled = not bool
	
	if bool then
		if self.isSprinting then
			self:sprint(false, true)
		end
		local tweeningInformation = TweenInfo.new(.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local properties = {Value = 1}
		self.loadedAnimations.aim:Play()
		TweenService:Create(self.lerpValues.aim, tweeningInformation, properties):Play()
		TweenService:Create(self.lerpValues.walkspeed, tweeningInformation, properties):Play()
	else
		local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local properties = {Value = 0}
		self.loadedAnimations.aim:Stop()
		TweenService:Create(self.lerpValues.aim, tweeningInformation, properties):Play()		
		TweenService:Create(self.lerpValues.walkspeed, tweeningInformation, properties):Play()	
	end
end

-- Runs the reloading animation and resets the guns ammo
function Weapon:reload()
	if self.reloading then return end
	if self.ammo == self.weaponStats.magCapacity or self.spareBullets <= 0 then return end
	self.reloading = true
	-- Run animation
	self.viewmodel.Receiver.ReloadSound:Play()
	task.wait(3)
	local neededBullets = self.weaponStats.magCapacity - self.ammo
	local givenBullets = neededBullets
	if neededBullets > self.spareBullets then
		givenBullets = self.spareBullets
	end
	self.spareBullets -= givenBullets
	self.spareBullets = math.clamp(self.spareBullets, 0, self.weaponStats.spareBullets)
	self.ammo += givenBullets
	self.canFire = true
	print(self.ammo, self.spareBullets)
	self.reloading = false
end

-- Enable / disable sprinting by chaning walkspeed and cancelling shooting and aiming
function Weapon:sprint(bool, changeIsSprinting)
	if not self.char or not self.char:FindFirstChild("Humanoid") then return end
	if changeIsSprinting then
		self.isSprinting = bool
	end
	self.char.Humanoid.WalkSpeed = if bool then (self.settings.sprintSpeed or 25) else 16
	local tweenTo = bool and 1 or 0
	local tweeningInformation = TweenInfo.new(.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local properties = {Value = tweenTo}
	TweenService:Create(self.lerpValues.sprint, tweeningInformation, properties):Play()
	self.sprintStance = bool
	if not bool then return end
	self:aim(false)
	self:fire(false)
end

-- Connects the relevant inputs using the Keybinds module
function Weapon:connectInput()
	-- Connect firing the weapon inputs
	for bindNum, keybind in ipairs(Keybinds.Fire) do
		local inputType = (keybind.EnumType == Enum.UserInputType and keybind) or Enum.UserInputType.Keyboard
		local keyCode = keybind.EnumType == Enum.KeyCode and keybind
		UserInput.connectInput(inputType, keyCode, "FireWeapon" .. bindNum, {
			beganFunc = function()
				self:fire(true)
			end;
			endedFunc = function()
				self:fire(false)
			end;
		}, true)
	end

	-- Connect aiming inputs
	for bindNum, keybind in pairs(Keybinds.Aim) do
		local inputType = (keybind.EnumType == Enum.UserInputType and keybind) or Enum.UserInputType.Keyboard
		local keyCode = keybind.EnumType == Enum.KeyCode and keybind
		UserInput.connectInput(inputType, keyCode, "AimWeapon" .. bindNum, {
			beganFunc = function()
				self:aim(true)
			end;
			endedFunc = function()
				self:aim(false)
			end;
		}, true)
	end

	-- Connect using equipment inputs
	for bindNum, keybind in pairs(Keybinds.UseEquipment) do
		local inputType = (string.find(keybind.Name, "Button") and Enum.UserInputType.Gamepad1) or Enum.UserInputType.Keyboard
		UserInput.connectInput(inputType, keybind, "UseEquipment" .. bindNum, {
			beganFunc = function()
				print("Hold equipment")
			end;
			endedFunc = function()
				print("Use equipment")
			end;
		}, true)
	end

	-- Connect the sprint inputs
	for bindNum, keybind in pairs(Keybinds.Sprint) do
		local inputType = (string.find(keybind.Name, "Button") and Enum.UserInputType.Gamepad1) or Enum.UserInputType.Keyboard
		UserInput.connectInput(inputType, keybind, "Sprint" .. bindNum, {
			beganFunc = function()
				self:sprint(true, true)
			end;
			endedFunc = function()
				self:sprint(false, true)
			end;
		}, true)
	end

	-- Connect the crouch inputs
	for bindNum, keybind in pairs(Keybinds.Crouch) do
		local inputType = (string.find(keybind.Name, "Button") and Enum.UserInputType.Gamepad1) or Enum.UserInputType.Keyboard
		UserInput.connectInput(inputType, keybind, "Crouch" .. bindNum, {
			beganFunc = function()
				print("Start crouching")
			end;
			endedFunc = function()
				print("Finish crouching")
			end;
		}, true)
	end

	-- Connect the reload inputs 
	for bindNum, keybind in pairs(Keybinds.Reload) do
		local inputType = (string.find(keybind.Name, "Button") and Enum.UserInputType.Gamepad1) or Enum.UserInputType.Keyboard
		UserInput.connectInput(inputType, keybind, "ReloadWeapon" .. bindNum, {
			beganFunc = function()
				self:reload()
			end;
		}, true)
	end
end

-- Disconnects the connect inputs when the weapon is equipped
function Weapon:disconnectInput()
	for _, keybind in pairs(Keybinds.Aim) do
		local inputType = (keybind.EnumType == "UserInputType" and keybind) or Enum.UserInputType.Keyboard
		UserInput.disconnectInput(inputType, "AimWeapon")
	end
end

-- Loads the animations and stores them in the object
function Weapon:loadAnimations()
	self.loadedAnimations.idle = self.viewmodel.AnimationController:LoadAnimation(self.settings.animations.viewmodel.idle)
	self.loadedAnimations.aim = self.viewmodel.AnimationController:LoadAnimation(self.settings.animations.viewmodel.aim)
end

-- Update the weapons position based on the camera
function Weapon:update(dt)
	if self.viewmodel then
		-- Get the players velocity
		local velocity = self.char.HumanoidRootPart.AssemblyLinearVelocity

		-- Get the players movement direction relative to the camera so we can tilt the viewmodel
		local forwardBackDir = self.char.Humanoid.MoveDirection:Dot(self.camera.CFrame.LookVector)
		local leftRightDir = self.char.Humanoid.MoveDirection:Dot(self.camera.CFrame.RightVector)

		-- Only tilt the viewport if we are not aiming
		if not self.aiming then
			self.springs.movementTilt:shove(Vector3.new(math.rad(-forwardBackDir * 2), 0, math.rad(-leftRightDir * 2)))
		end

		-- Cancel out the sprint stance if we are not moving or are moving backwards
		if self.isSprinting and (math.abs(velocity.Magnitude) < 1 or (math.abs(forwardBackDir) > 0.1 and forwardBackDir < 0.1)) and self.sprintStance then
			self:sprint(false)
		elseif self.isSprinting and (math.abs(velocity.Magnitude) > 1 and math.abs(forwardBackDir) > 0.1 and forwardBackDir > 0.1) and not self.sprintStance then
			self:sprint(true)
		end

		-- Add the aim offset to the final offset
		local idleOffset = self.viewmodel.Offsets.Idle.Value --* CFrame.Angles(xTilt * ((movementDirection.X > 0 and 1) or -1), 0, zTilt * ((movementDirection.Z > 0 and 1) or -1))
		local aimOffset = idleOffset:lerp(self.viewmodel.Offsets.Aim.Value, self.lerpValues.aim.Value)
		-- Only want the sprint offset to apply if we are actually sprinting
		local sprintOffset = aimOffset:lerp(self.viewmodel.Offsets.Sprint.Value, self.lerpValues.sprint.Value)
		local finalOffset = sprintOffset

		-- Allows us to reduce the players walkspeed by changing the walkspeed lerp value while we are aiming
		local backwardsReduction = if not self.aiming and forwardBackDir < 0 then 4 else 0
		if not self.isSprinting then
			local aimWalkspeed = self.settings.aimWalkspeed or 6
			-- Reduce walkspeed if we are walking backwards
			self.char.Humanoid.WalkSpeed = 16 - ((16 - aimWalkspeed) * self.lerpValues.walkspeed.Value) - backwardsReduction
		else
			self.char.Humanoid.WalkSpeed = (self.settings.sprintSpeed or 25) - backwardsReduction * 2
		end
		
		-- Get the amount the mouse has moved and apply this to the sway spring, so we can sway the viewmodel based on camera movement
		local mouseDelta = UserInputService:GetMouseDelta()
		if self.aiming then mouseDelta *= 0.7 end
		self.springs.sway:shove(Vector3.new(math.clamp(mouseDelta.X, -50, 50) / 300, math.clamp(mouseDelta.Y, -50, 50) / 300, 0))
		
		local frequency = 1
		local amplitude = 0.1
		local sprintAddition = self.isSprinting and 1.4 or 1
		local movementSway = Vector3.new(
			Maths.getSine(amplitude, frequency * 7 * sprintAddition), 
			Maths.getSine(amplitude, frequency * 14 * sprintAddition), 
			0
		)

		-- Custom camera movement (don't want it to move as much as the viewmodel) which is relative to players velocity
		local camSway = Vector3.new(
			Maths.getSine(amplitude * 0.01 * sprintAddition, frequency * 14 * sprintAddition), 
			0, 
			0
		) * velocity.Magnitude * 0.05
	
		-- Apply the movement sway to the walking spring, so that the viewmodel bobs when the player is walking
		self.springs.walkCycle:shove((movementSway / 25) * dt * 60 * velocity.Magnitude)
		
		-- Update the springs
		local movementTilt = self.springs.movementTilt:update(dt)
		local sway = self.springs.sway:update(dt)
		local walkCycle = self.springs.walkCycle:update(dt)
		local recoil = self.springs.recoil:update(dt)

		-- Make the camera shake when we shoot
		self.camera.CFrame *= CFrame.Angles(recoil.X, recoil.Y, recoil.Z)
		self.camera.CFrame *= CFrame.Angles(camSway.X, camSway.Y, camSway.Z)

		-- Less recoil when we're aiming
		self.recoilFactor = if self.aiming then self.weaponStats.aimRecoilFactor else 1

		-- Apply all of these movements to the viewmodels CFrame
		self.viewmodel.RootPart.CFrame = self.camera.CFrame:ToWorldSpace(finalOffset) * CFrame.Angles(0, math.pi, 0)
		self.viewmodel.RootPart.CFrame = self.viewmodel.RootPart.CFrame:ToWorldSpace(CFrame.new(walkCycle.X / 4, walkCycle.Y / 2, 0))
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(movementTilt.X, 0, movementTilt.Z)
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(-sway.Y, -sway.X, 0)
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(recoil.X * self.recoilFactor, recoil.Y * self.recoilFactor, 0)
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(walkCycle.Y / 3, walkCycle.X / 3, 0)
	end
end

return Weapon