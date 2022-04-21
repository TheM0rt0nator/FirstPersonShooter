--[[
	- Displays players ammo count, health and current weapon in bottom right/left of the screen
	- Also display crosshairs for the gun
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local UICorner = loadModule("UICorner")
local Flipper = loadModule("Flipper")

local ammoChanged = getDataStream("AmmoChanged", "BindableEvent")
local weaponChanged = getDataStream("WeaponChanged", "BindableEvent")

local player = Players.LocalPlayer

local HUD = Roact.Component:extend("HUD")

function HUD:init()
	self.maid = Maid.new()

	-- Use flipper to make the health tween if it is increasing
	self.healthMotor = Flipper.SingleMotor.new(1)
	self.health, self.setHealth = Roact.createBinding(self.healthMotor:getValue())
	self.motorVelocity = .2
	self.healthMotor:onStep(function(val)
		print(val)
		self.setHealth(val)
	end)

	self.weapon, self.setWeapon = Roact.createBinding("")
	self.ammo, self.setAmmo = Roact.createBinding("0")
	self.spare, self.setSpare = Roact.createBinding("0")

	-- Spawn this so it doesn't hold everything up
	task.spawn(function()
		if not player.Character then
			player.CharacterAdded:Wait()
		end
		self.char = player.character
		self.humanoid = self.char:WaitForChild("Humanoid")
		local currentHealth = self.humanoid.Health
		self.healthMotor:setGoal(Flipper.Instant.new(self.humanoid.Health / self.humanoid.MaxHealth))

		-- Connect a listener to the players health to update the UI
		self.healthConnection = self.humanoid.HealthChanged:Connect(function(health)
			if health > currentHealth then
				self.healthMotor:setGoal(Flipper.Linear.new(self.humanoid.Health / self.humanoid.MaxHealth, {
					velocity = self.motorVelocity;
				}))
			else
				self.healthMotor:setGoal(Flipper.Instant.new(self.humanoid.Health / self.humanoid.MaxHealth))
			end
			currentHealth = health
		end)

		-- Reset these values when the player gets a new character
		self.maid:GiveTask(player.CharacterAdded:Connect(function(newChar)
			self.char = newChar
			self.humanoid = newChar:WaitForChild("Humanoid")

			if self.healthConnection then
				self.healthConnection:Disconnect()
				self.healthConnection = self.humanoid.HealthChanged:Connect(function(health)
					if health > currentHealth then
						self.healthMotor:setGoal(Flipper.Linear.new(self.humanoid.Health / self.humanoid.MaxHealth, {
							velocity = self.motorVelocity;
						}))
					else
						self.healthMotor:setGoal(Flipper.Instant.new(self.humanoid.Health / self.humanoid.MaxHealth))
					end
					currentHealth = health
				end)
			end

			self.healthMotor:setGoal(Flipper.Instant.new(self.humanoid.Health / self.humanoid.MaxHealth))
		end))

		-- Listen to the ammo changed event to change the ammo UI
		self.maid:GiveTask(ammoChanged.Event:Connect(function(newAmmo, newSpare)
			self.setAmmo(tostring(newAmmo))
			self.setSpare(tostring(newSpare))
		end))

		-- Listen to the weapon changed event to change the weapon text
		self.maid:GiveTask(weaponChanged.Event:Connect(function(newWeapon)
			self.setWeapon(newWeapon)
		end))
	end)
end

function HUD:render()
	return Roact.createElement("ScreenGui", {
		Name = "HUD";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
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