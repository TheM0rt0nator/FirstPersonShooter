--[[
	- Displays players ammo count, health and current weapon in bottom right/left of the screen
	- Also display crosshairs for the gun
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local ammoChanged = getDataStream("AmmoChanged", "BindableEvent")
local weaponChanged = getDataStream("WeaponChanged", "BindableEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local UICorner = loadModule("UICorner")
local Flipper = loadModule("Flipper")
local ImageDirectory = loadModule("ImageDirectory")

local player = Players.LocalPlayer

local HUD = Roact.Component:extend("HUD")

function HUD:init()
	self.maid = Maid.new()

	-- Use flipper to make the health tween if it is increasing
	self.healthMotor = Flipper.SingleMotor.new(1)
	self.health, self.setHealth = Roact.createBinding(self.healthMotor:getValue())
	self.motorVelocity = .2
	self.healthMotor:onStep(function(val)
		self.setHealth(val)
	end)

	self.healthVisible, self.setHealthVisible = Roact.createBinding(true)
	self.weapon, self.setWeapon = Roact.createBinding("")
	self.ammo, self.setAmmo = Roact.createBinding("0")
	self.spare, self.setSpare = Roact.createBinding("0")
	self.equipment, self.setEquipment = Roact.createBinding("")
	self.equipmentNum, self.setEquipmentNum = Roact.createBinding(0)

	-- Spawn this so it doesn't hold everything up
	task.spawn(function()
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		self.char = player.character
		self.humanoid = self.char:WaitForChild("Humanoid")
		self.currentHealth = self.humanoid.Health
		self.healthMotor:setGoal(Flipper.Instant.new(self.humanoid.Health / self.humanoid.MaxHealth))

		-- Connect a listener to the players health to update the UI
		self.healthConnection = self.humanoid.HealthChanged:Connect(function(health)
			self:healthChanged(health)
		end)

		-- Reset these values when the player gets a new character
		self.maid:GiveTask(player.CharacterAdded:Connect(function(newChar)
			self.char = newChar
			self.humanoid = newChar:WaitForChild("Humanoid")
			self.currentHealth = self.humanoid.Health

			if self.healthConnection then
				self.healthConnection:Disconnect()
				self.healthConnection = self.humanoid.HealthChanged:Connect(function(health)
					self:healthChanged(health)
				end)
			end

			self.setHealthVisible(true)
			self.healthMotor:setGoal(Flipper.Instant.new(self.humanoid.Health / self.humanoid.MaxHealth))
		end))

		-- Listen to the ammo changed event to change the ammo UI
		self.maid:GiveTask(ammoChanged.Event:Connect(function(newAmmo, newSpare, equipmentName, equipmentNum)
			self.setAmmo(tostring(newAmmo))
			self.setSpare(tostring(newSpare))
			if not equipmentName or not equipmentNum then return end
			self.setEquipment(equipmentName)
			self.setEquipmentNum(equipmentNum)
		end))

		-- Listen to the weapon changed event to change the weapon text
		self.maid:GiveTask(weaponChanged.Event:Connect(function(newWeapon)
			self.setWeapon(newWeapon)
		end))
	end)
end

-- Only tween the health if we are regenerating health, otherwise make it instant
function HUD:healthChanged(health)
	if health <= 0 then
		self.setHealthVisible(false)
	else
		self.setHealthVisible(true)
	end
	if health > self.currentHealth then
		self.healthMotor:setGoal(Flipper.Linear.new(self.humanoid.Health / self.humanoid.MaxHealth, {
			velocity = self.motorVelocity;
		}))
	else
		self.healthMotor:setGoal(Flipper.Instant.new(self.humanoid.Health / self.humanoid.MaxHealth))
	end
	self.currentHealth = health
end

function HUD:render()
	local equipmentIcons = {}

	-- Only show equipment we have, use bindings to hide them when we use an equipment
	-- Up to 5 (this could be max number of equipment someday?)
	for i = 1, 5 do
		equipmentIcons[i] = Roact.createElement("ImageLabel", {
			Image = self.equipment:map(function(val)
				if ImageDirectory[val .. "Icon"] then
					return ImageDirectory[val .. "Icon"]
				end
				return ""
			end);
			Visible = self.equipmentNum:map(function(val)
				if i > val then
					return false
				end
				return true
			end);
			BackgroundTransparency = 1;
			Name = "Template";
			Size = UDim2.new(0.5, 0, 1, 0);
			ScaleType = Enum.ScaleType.Fit;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});
	end

	return Roact.createElement("ScreenGui", {
		Name = "HUD";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		ResetOnSpawn = false;
		DisplayOrder = 1;
		Enabled = Roact.joinBindings({self.props.visible, self.visible}):map(function(values)
			return values[1] and values[2]
		end);
	}, {
		AmmoCounter = Roact.createElement("Frame", {
			BackgroundTransparency = 1;
			Position = UDim2.new(0.89, 0, 0.857, 0);
			Name = "AmmoCounter";
			Size = UDim2.new(0.091, 0, 0.066, 0);
			BackgroundColor3 = Color3.new(1, 1, 1);
		}, {
			GunName = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(1, 1, 1);
				Text = self.weapon;
				Name = "GunName";
				TextStrokeTransparency = 0.5;
				AnchorPoint = Vector2.new(0, 0.5);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0.506, 0, 1.31, 0);
				Size = UDim2.new(0.421, 0, 0.622, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
	
			Spare = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				Name = "Spare";
				TextColor3 = Color3.new(1, 1, 1);
				Text = self.spare;
				Size = UDim2.new(0.43, 0, 1.2, 0);
				TextStrokeTransparency = 0.5;
				AnchorPoint = Vector2.new(0, 0.5);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Left;
				Position = UDim2.new(0.5, 0, 0.5, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
	
			Ammo = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				Name = "Ammo";
				TextColor3 = Color3.new(1, 1, 1);
				Text = self.ammo;
				Size = UDim2.new(0.35, 0, 1, 0);
				TextStrokeTransparency = 0.5;
				AnchorPoint = Vector2.new(0, 0.5);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				TextXAlignment = Enum.TextXAlignment.Right;
				Position = UDim2.new(0, 0, 0.5, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
	
			Slash = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(1, 1, 1);
				Text = "/";
				Name = "Slash";
				TextStrokeTransparency = 0.5;
				AnchorPoint = Vector2.new(0, 0.5);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0.35, 0, 0.5, 0);
				Size = UDim2.new(0.15, 0, 1.2, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});

			Equipment = Roact.createElement("Frame", {
				BackgroundTransparency = 1;
				Position = UDim2.new(-0.007, 0, 0.987, 0);
				Name = "Equipment";
				Size = UDim2.new(0.506, 0, 0.634, 0);
				BackgroundColor3 = Color3.new(1, 1, 1);
			}, {
				Icons = Roact.createFragment(equipmentIcons);
			
				UIListLayout = Roact.createElement("UIListLayout", {
					Padding = UDim.new(-0.3, 0);
					SortOrder = Enum.SortOrder.LayoutOrder;
					FillDirection = Enum.FillDirection.Horizontal;
				});
			})
		});
	
		Health = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0);
			Name = "Health";
			Position = UDim2.new(0.5, 0, 0.014, 0);
			Size = UDim2.new(0.179, 0, 0.026, 0);
			BackgroundColor3 = Color3.new(0.4, 0, 0);
		}, {
			Fill = Roact.createElement("Frame", {
				Name = "Fill";
				Position = UDim2.new(0, 0, 0, 0);
				Size = self.health:map(function(value)
					return UDim2.new(0, 0, 1, 0):Lerp(UDim2.new(1, 0, 1, 0), value)
				end);
				Visible = self.healthVisible;
				BackgroundColor3 = Color3.new(0, 0.882, 0.043);
			}, {
				UICorner = UICorner(0.4, 0);
			});
	
			UICorner = UICorner(0.4, 0);
		});
	
		Crosshair = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			Name = "Crosshair";
			Position = UDim2.new(0.5, 0, 0.5, 0);
			SizeConstraint = Enum.SizeConstraint.RelativeXX;
			Size = UDim2.new(0.002, 0, 0.002, 0);
			BackgroundColor3 = Color3.new(1, 0, 0);
		}, {
			UICorner = UICorner(1, 0);
		});
	})
end

-- Cleanup the maids connections
function HUD:willUnmount()
	self.maid:DoCleaning()
	if self.healthConnection then
		self.healthConnection:Disconnect()
		self.healthConnection = nil
	end
end

return HUD