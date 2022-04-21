--[[
	- Just a notification which appears when you get a kill, probably in the top middle of the screen and shows who you killed
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local KillNotificationTile = loadModule("KillNotificationTile")

local playerKilledRemote = getDataStream("PlayerKilled", "RemoteEvent")

local KillNotification = Roact.Component:extend("KillFeed")

local TILE_EXPIRE_TIME = 2
local DISPLAY_TIME = 2

function KillNotification:init()
	self.maid = Maid.new()
	self.tileInfo = {}
	self.tiles = {}
	self.visible, self.setVisible = Roact.createBinding(false)
	-- Connect to the player killed remote and check if we are the killer
	self.maid:GiveTask(playerKilledRemote.OnClientEvent:Connect(function(killer, victim, weapon)
		if Player.Name == killer then
			-- Play a sound to notify them they got a kill
			ReplicatedStorage.Assets.Sounds.KillSound:Play()
			-- Could add a cool animation here but limited time
			-- Remove any kills which have expired
			local timeNow = DateTime.now().UnixTimestamp
			for i = #self.tileInfo, 1, -1 do
				local tileInfo = self.tileInfo[i]
				if timeNow - tileInfo.timeCreated >= TILE_EXPIRE_TIME then
					table.remove(self.tileInfo, i)
					table.remove(self.tiles, i)
				end
			end
			-- Create the new tile and save the time it was created, so it can be deleted after desired time
			local newTile = Roact.createElement(KillNotificationTile, {
				victimName = victim;
			})
			table.insert(self.tileInfo, {
				timeCreated = timeNow;
			})
			table.insert(self.tiles, newTile)
			self.setVisible(true)
			self:setState({})
			-- Start or top up the timer for the UI to close
			if not self.timerStarted then
				self.timerStarted = true
				self.timer = DISPLAY_TIME
				self:startTimer()
			else
				self.timer = DISPLAY_TIME
			end
		end
	end))
end

-- Start a timer to hide the kill feed after, which can be topped up if another kill happens
function KillNotification:startTimer()
	while self.timer > 0 do
		self.timer -= 0.01
		if self.timer <= 0.5 then
			-- Could add a fading out effect here 
		end
		task.wait()
	end
	self.setVisible(false)
	self.timerStarted = false
end

function KillNotification:render()
	return Roact.createElement("ScreenGui", {
		Name = "KillNotifications";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		Enabled = Roact.joinBindings({self.props.visible, self.visible}):map(function(values)
			return values[1] and values[2]
		end);
	}, {
		MainFrame =  Roact.createElement("Frame", {
			BackgroundTransparency = 1;
			Position = UDim2.new(0.537, 0, 0.379, 0);
			Name = "MainFrame";
			Size = UDim2.new(0.068, 0, 0.13, 0);
			BackgroundColor3 = Color3.new(1, 1, 1);
		}, {
			Tiles = Roact.createFragment(self.tiles);
	
			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Bottom;
				SortOrder = Enum.SortOrder.LayoutOrder;
			});
		});
	})
end

return KillNotification