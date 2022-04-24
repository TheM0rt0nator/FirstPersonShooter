local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local playerKilledRemote = getDataStream("PlayerKilled", "RemoteEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local KillFeedTile = loadModule("KillFeedTile")

local KillFeed = Roact.Component:extend("KillFeed")

local player = Players.LocalPlayer

local TILE_EXPIRE_TIME = 10
local DISPLAY_TIME = 3.5

function KillFeed:init()
	self.maid = Maid.new()
	self.tileInfo = {}
	self.tiles = {}
	self.visible, self.setVisible = Roact.createBinding(false)
	self.maid:GiveTask(playerKilledRemote.OnClientEvent:Connect(function(killer, victim, weapon)
		if killer == victim then return end
		-- Could use the weapon argument to add a weapon icon instead of the 'killed' text
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
		local newTile = Roact.createElement(KillFeedTile, {
			killerName = killer;
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
	end))
end

-- Start a timer to hide the kill feed after, which can be topped up if another kill happens
function KillFeed:startTimer()
	task.spawn(function()
		while self.timer > 0 do
			self.timer -= 0.01
			if self.timer <= 0.5 then
				-- Could add a fading out effect here 
			end
			task.wait()
		end
		self.setVisible(false)
		self.timerStarted = false
	end)
end

function KillFeed:render()
	return Roact.createElement("ScreenGui", {
		Name = "KillFeed";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		ResetOnSpawn = false;
		DisplayOrder = 1;
		Enabled = Roact.joinBindings({self.props.visible, self.visible}):map(function(values)
			return values[1] and values[2]
		end);
	}, {
		MainFrame = Roact.createElement("Frame", {
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0.539, 0);
			Name = "MainFrame";
			Size = UDim2.new(0.225, 0, 0.2, 0);
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

-- WHen the component is unmounted, cleanup it's connections
function KillFeed:willUnmount()
	self.maid:DoCleaning()
end

return KillFeed