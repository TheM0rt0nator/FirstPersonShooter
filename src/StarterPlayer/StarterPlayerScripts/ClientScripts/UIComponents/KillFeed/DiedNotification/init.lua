local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local playerKilledRemote = getDataStream("PlayerKilled", "RemoteEvent")
local camTypeChanged = getDataStream("CamTypeChanged", "BindableEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local CameraTypes = loadModule("CameraTypes")

local player = Players.LocalPlayer

local DiedNotification = Roact.Component:extend("DiedNotification")

-- When we die, want the camera to follow the player who killed us
function DiedNotification:init()
	self.maid = Maid.new()
	self.visible, self.setVisible = Roact.createBinding(false)
	self.killer, self.setKiller = Roact.createBinding("")
	self.weapon, self.setWeapon = Roact.createBinding("")
	self.maid:GiveTask(playerKilledRemote.OnClientEvent:Connect(function(killer, victim, weapon)
		if player.Name == victim 
			and workspace:FindFirstChild(killer)
		then
			-- Set to death cam, then wait for it to change off death cam to hide the death notification
			if killer ~= victim then 
				self.setKiller(killer)
			end
			if weapon then
				self.setWeapon(weapon or "")
			end
			self.setVisible(true)
			CameraTypes:setCameraType("DeathCam", workspace:FindFirstChild(killer).HumanoidRootPart)
			task.wait(2)
			if CameraTypes.currentType ~= "DeathCam" then 
				self.setVisible(false)
				return 
			end
			camTypeChanged.Event:Wait()
			self.setVisible(false)
			self.setWeapon("")
			self.setKiller("")
		end
	end))
end

function DiedNotification:render()
	return Roact.createElement("ScreenGui", {
		Name = "DiedNotification";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		ResetOnSpawn = false;
		DisplayOrder = 1;
		Enabled = Roact.joinBindings({self.props.visible, self.visible}):map(function(values)
			return values[1] and values[2]
		end);
	}, {
		MainFrame = Roact.createElement("Frame", {
			BackgroundTransparency = 1;
			Position = UDim2.new(0.392, 0, 0.1, 0);
			Name = "MainFrame";
			Size = UDim2.new(0.216, 0, 0.213, 0);
			BackgroundColor3 = Color3.new(1, 1, 1);
		}, {
			KillerLabel = Roact.createElement("TextLabel", {
				TextColor3 = Color3.new(0.624, 0, 0);
				Text = self.killer:map(function(killer)
					return "You were killed by " .. killer
				end);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Name = "KillerLabel";
				Size = UDim2.new(1, 0, 0.4, 0);
				FontSize = Enum.FontSize.Size14;
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
		
			WeaponLabel = Roact.createElement("TextLabel", {
				TextColor3 = Color3.new(0.624, 0, 0);
				Text = self.weapon:map(function(weapon)
					return "Weapon: " .. weapon
				end);
				Name = "WeaponLabel";
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0.154, 0, 0.4, 0);
				Size = UDim2.new(0.693, 0, 0.194, 0);
				FontSize = Enum.FontSize.Size14;
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
		})
		
	})
end

function DiedNotification:willUnmount()
	self.maid:DoCleaning()
end

return DiedNotification