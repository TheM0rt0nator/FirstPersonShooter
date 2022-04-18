local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Maths = loadModule("Maths")
local Spring = loadModule("Spring")

local Weapon = {}
Weapon.__index = Weapon

-- Function which returns a value along the sine wave, based on time (randomized effect)
local function getBobbing(addition, speed, modifier)
	return math.sin(tick() * addition * speed) * modifier
end

-- Create a new weapon object
function Weapon.new(name)
	local self = {
		name = name;
		loadedAnimations = {};
		springs = {
			walkCycle = Spring.new();
			sway = Spring.new();
		};
		lerpValues = {
			aim = Instance.new("NumberValue");
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
	self.loadedAnimations.idle = self.viewmodel.AnimationController:LoadAnimation(self.settings.animations.viewmodel.idle)
	self.loadedAnimations.aim = self.viewmodel.AnimationController:LoadAnimation(self.settings.animations.viewmodel.aim)
	self.loadedAnimations.idle:Play(0) --no lerp time from default pos to prevent stupid looking arms for no longer than 0 frames	
	
	-- Gun successfully equipped
	self.equipped = true
end

-- Unequip the weapon
function Weapon:unequip()
	-- Destroy the viewmodel, which also destroys the gun, and set equipped to false
	self.viewmodel:Destroy()
    self.viewmodel = nil
	self.equipped = false
end

-- Changes the aim lerp value to tell the viewport where to go
function Weapon:aim(bool)
	if self.disabled then return end
	if not self.equipped then return end
	self.aiming = bool
	UserInputService.MouseIconEnabled = not bool
	
	if bool then
		local tweeningInformation = TweenInfo.new(.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local properties = {Value = 1}
		self.loadedAnimations.aim:Play()
		TweenService:Create(self.lerpValues.aim, tweeningInformation, properties):Play()	
	else
		local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local properties = {Value = 0}
		self.loadedAnimations.aim:Stop()
		TweenService:Create(self.lerpValues.aim, tweeningInformation, properties):Play()			
	end
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
		
		-- Get the amount the mouse has moved and apply this to the sway spring, so we can sway the viewmodel based on camera movement
		local mouseDelta = UserInputService:GetMouseDelta()
		if self.aiming then mouseDelta *= 0.7 end
		self.springs.sway:shove(Vector3.new(mouseDelta.X / 300, mouseDelta.Y / 300, 0))
		
		local speed = 1
		local modifier = 0.05
		local movementSway = Vector3.new(getBobbing(10, speed, modifier), getBobbing(5, speed, modifier), getBobbing(5, speed, modifier))
	
		-- Apply the movement sway to the walking spring, so that the viewmodel bobs when the player is walking
		self.springs.walkCycle:shove((movementSway / 25) * dt * 60 * velocity.Magnitude)
		
		-- Update the springs
		local sway = self.springs.sway:update(dt)
		local walkCycle = self.springs.walkCycle:update(dt)
		
		-- Apply all of these movements to the viewmodels CFrame
		self.viewmodel.RootPart.CFrame = self.camera.CFrame:ToWorldSpace(finalOffset) * CFrame.Angles(0, math.pi, 0)
		self.viewmodel.RootPart.CFrame = self.viewmodel.RootPart.CFrame:ToWorldSpace(CFrame.new(walkCycle.X / 2, walkCycle.Y / 2,0))
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(-sway.Y, -sway.X, 0)
		self.viewmodel.RootPart.CFrame *= CFrame.Angles(0, walkCycle.Y, walkCycle.X)
	end
end

return Weapon

--CFrame.new(.04, -.785, 0) * CFrame.Angles(math.rad(0), math.rad(180), math.rad(1.1))