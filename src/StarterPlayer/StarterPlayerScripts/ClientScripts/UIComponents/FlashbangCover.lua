local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local flashbangEvent = getDataStream("FlashbangEvent", "BindableEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local Flipper = loadModule("Flipper")
local Raycast = loadModule("Raycast")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local FlashbangCover = Roact.Component:extend("FlashbangCover")

local STUN_TIME = 3

function FlashbangCover:init()
	self.maid = Maid.new()
	self.stuns = 0
	self.visible, self.setVisible = Roact.createBinding(false)

	-- Create a motor for the intensity so we can tween it up / down
	self.intensityMotor = Flipper.SingleMotor.new(0)
	self.intensity, self.setIntensity = Roact.createBinding(self.intensityMotor:getValue())
	self.motorVelocity = .2
	self.intensityMotor:onStep(function(val)
		self.setIntensity(val)
		ReplicatedStorage.Assets.Sounds.EarsRingingSound.Volume = 1 - val
		if val == 1 then
			ReplicatedStorage.Assets.Sounds.EarsRingingSound:Stop()
		end
	end)

	self.maid:GiveTask(flashbangEvent.Event:Connect(function(pos, grenade, soundPart)
		if not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then return end
		-- Check close enough
		local dist = (player.Character.HumanoidRootPart.Position - pos).Magnitude
		if dist > 100 then return end
		-- Check is not behind wall or something
		local ignoreList = {
			CollectionService:GetTagged("Accessory");
			CollectionService:GetTagged("Weapon");
			camera:FindFirstChild("ViewModel");
			grenade;
			soundPart;
		}
		local rayDirection = (player.Character.HumanoidRootPart.Position - pos).Unit
		local raycastResult = Raycast.new(ignoreList, "Blacklist", pos, rayDirection, dist * 1.5)
		if not raycastResult or raycastResult.Instance.Parent ~= player.Character then return end
		-- Check the angle between their look vector and the grenade vector
		local lookVector = camera.CFrame.LookVector.Unit
		local grenadeVector = (pos - player.Character.HumanoidRootPart.Position).Unit
		local angle = math.acos(lookVector:Dot(grenadeVector))
		-- If the player is looking further than 100 degrees away then do nothing
		if math.deg(angle) > 100 then return end
		self.stuns += 1
		local intensity = (math.deg(angle) / 100) - 0.3
		intensity = math.clamp(intensity, 0, 0.6)
		self.intensityMotor:setGoal(Flipper.Instant.new(intensity))
		self.setVisible(true)
		-- Play ears ringing sound
		if not ReplicatedStorage.Assets.Sounds.EarsRingingSound.IsPlaying then
			ReplicatedStorage.Assets.Sounds.EarsRingingSound:Play()
		end
		local numStuns = self.stuns
		task.wait(STUN_TIME)
		-- Cancel tweening back incase we've beens stunned again
		if self.stuns ~= numStuns then return end
		self.intensityMotor:setGoal(Flipper.Linear.new(1, {
			velocity = self.motorVelocity;
		}))
	end))
end

-- Render just a plain white screen
function FlashbangCover:render()
	return Roact.createElement("ScreenGui", {
		Name = "FlashbangCover";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		ResetOnSpawn = false;
		Enabled = Roact.joinBindings({self.props.visible, self.visible}):map(function(values)
			return values[1] and values[2]
		end);
	}, {
		Cover = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			BorderSizePixel = 0;
			Position = UDim2.new(0.5, 0, 0, 0);
			Size = UDim2.new(1, 0, 2, 0);
			BackgroundTransparency = self.intensity;
			BackgroundColor3 = Color3.new(1, 1, 1);
		})
	})
end

function FlashbangCover:willUnmount()
	self.maid:DoCleaning()
end	

return FlashbangCover