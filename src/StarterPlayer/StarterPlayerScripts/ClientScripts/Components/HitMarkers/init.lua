local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")

local hitPlayerEvent = getDataStream("HitPlayerEvent", "BindableEvent")

local HitMarkers = Roact.Component:extend("HitMarkers")

-- Connect to the event so we can show the hit markers when you hit someone
function HitMarkers:init()
	self.maid = Maid.new()
	self.color, self.setColor = Roact.createBinding(Color3.fromRGB(255, 255, 255))
	self.visible, self.setVisible = Roact.createBinding(false)

	self.maid:GiveTask(hitPlayerEvent.Event:Connect(function(part)
		local headshot = part.Name == "Head"
		if headshot then
			self.setColor(Color3.fromRGB(255, 0, 0))
		else
			self.setColor(Color3.new(1, 1, 1))
		end
		local viewmodel = workspace.Camera:FindFirstChild("ViewModel")
		if viewmodel then
			-- Hit marker sound; can change the sound depending on if it is a headshot or not - not great sound design here but have limited time
			task.delay(.1, function()
				local sound = viewmodel.Receiver.HitSound:Clone()
				sound.Parent = viewmodel.Receiver
				if headshot then
					sound:FindFirstChild("EqualizerSoundEffect").LowGain = 2
				end
				sound:Play()
				task.delay(1, function()
					sound:Destroy()
				end)
			end)
		end
		self.setVisible(true)
		if not self.timerStarted then
			self.timerStarted = true
			self.timer = .3
			self:startTimer()
		else
			self.timer = .3
		end
	end))
end

-- Start a timer to hide the hit markers, which can be topped up if we hit again
function HitMarkers:startTimer()
	while self.timer > 0 do
		self.timer -= 0.01
		task.wait()
	end
	self.setVisible(false)
	self.timerStarted = false
end

function HitMarkers:render()
	return Roact.createElement("ScreenGui", {
		Enabled = self.visible;
	}, {
		HitMarker = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			Image = "rbxassetid://9418396522";
			BackgroundTransparency = 1;
			Position = UDim2.new(0.5, 0, 0.5, 0);
			Size = UDim2.new(0, 31, 0, 31);
			BackgroundColor3 = Color3.new(1, 1, 1);
			ImageColor3 = self.color;
			Visible = self.visible;
		})
	})
end

-- When the component is unmounted, cleanup connections
function HitMarkers:willUnmount()
	if self.maid then
		self.maid:DoCleaning()
	end
end

return HitMarkers
