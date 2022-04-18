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

local rand = Random.new()

local Weapon = {}
Weapon.__index = Weapon

-- Create a new weapon object
function Weapon.new(name)
	local self = {
		name = name;
		canFire = true;
		loadedAnimations = {};
		springs = {
			walkCycle = Spring.new();
			sway = Spring.new();
			recoil = Spring.new(4, 100, nil, 6);
		};
		lerpValues = {
			aim = Instance.new("NumberValue");
			walkspeed = Instance.new("NumberValue");
		};
	}

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
	if not self.canFire and bool then return end

	-- Set the firing value to the bool and then return if we are not firing anymore
	self.firing = bool
	if not bool or self.isSprinting then return end

	local function fire()
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

		-- Shove the recoil spring to make the camera shake when we shoot, using the values from this guns settings to change the amount of recoil
		local verticalRecoil = rand:NextNumber(0.15, 0.2) * self.recoilFactor * (self.settings.weaponStats.verticalRecoilFactor or 1)
		local horizontalRecoil = rand:NextNumber(-0.05, 0.05) * self.recoilFactor * (self.settings.weaponStats.horizontalRecoilFactor or 1)
		self.springs.recoil:shove(Vector3.new(verticalRecoil, horizontalRecoil, 0))
		task.spawn(function()
			task.wait(.15)
			self.springs.recoil:shove(Vector3.new(-verticalRecoil, -horizontalRecoil, 0))
		end)
		
		task.wait(60 / self.settings.weaponStats.rpm)
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
			self:sprint(false)
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

-- Enable / disable sprinting by chaning walkspeed and cancelling shooting and aiming
function Weapon:sprint(bool)
	if not self.char or not self.char:FindFirstChild("Humanoid") then return end
	self.isSprinting = bool
	self.char.Humanoid.WalkSpeed = if bool then (self.settings.sprintSpeed or 25) else 16
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
				self:sprint(true)
			end;
			endedFunc = function()
				self:sprint(false)
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
				print("Reload gun")
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

		-- Add the aim offset to the final offset
		local idleOffset = self.viewmodel.Offsets.Idle.Value
		local aimOffset = idleOffset:lerp(self.viewmodel.Offsets.Aim.Value, self.lerpValues.aim.Value)
		local finalOffset = aimOffset

		-- Allows us to reduce the players walkspeed by changing the walkspeed lerp value while we are aiming
		if not self.isSprinting then
			local aimWalkspeed = self.settings.aimWalkspeed or 6
			self.char.Humanoid.WalkSpeed = 16 - ((16 - aimWalkspeed) * self.lerpValues.walkspeed.Value)
		end
		
		-- Get the amount the mouse has moved and apply this to the sway spring, so we can sway the viewmodel based on camera movement
		local mouseDelta = UserInputService:GetMouseDelta()
		if self.aiming then mouseDelta *= 0.7 end
		self.springs.sway:shove(Vector3.new(mouseDelta.X / 300, mouseDelta.Y / 300, 0))
		
		local frequency = 1
		local amplitude = 0.05
		local movementSway = Vector3.new(
			Maths.getSine(amplitude, frequency * 10), 
			Maths.getSine(amplitude, frequency * 3), 
			Maths.getSine(amplitude, frequency * 3)
		)
	
		-- Apply the movement sway to the walking spring, so that the viewmodel bobs when the player is walking
		self.springs.walkCycle:shove((movementSway / 25) * dt * 60 * velocity.Magnitude)
		
		-- Update the springs
		local sway = self.springs.sway:update(dt)
		local walkCycle = self.springs.walkCycle:update(dt)
		local recoil = self.springs.recoil:update(dt)

		-- Make the camera shake when we shoot
		self.camera.CFrame = self.camera.CFrame * CFrame.Angles(recoil.X, recoil.Y, recoil.Z)

		-- Less recoil when we're aiming
		self.recoilFactor = if self.aiming then self.settings.weaponStats.aimRecoilFactor else 1

		-- Apply all of these movements to the viewmodels CFrame
		self.viewmodel.RootPart.CFrame = self.camera.CFrame:ToWorldSpace(finalOffset) * CFrame.Angles(0, math.pi, 0)
		self.viewmodel.RootPart.CFrame = self.viewmodel.RootPart.CFrame:ToWorldSpace(CFrame.new(walkCycle.X / 2, walkCycle.Y / 2,0))
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(-sway.Y, -sway.X, 0)
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(recoil.X * self.recoilFactor, recoil.Y * self.recoilFactor, 0)
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(0, walkCycle.Y, walkCycle.X)
	end
end

return Weapon