local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local superVoteEvent = getDataStream("SuperVoteEvent", "RemoteEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local MapVotingTile = loadModule("MapVotingTile")
local String = loadModule("String")

local MapVoting = Roact.Component:extend("MapVoting")

function MapVoting:init()
	self.maid = Maid.new()
	self.visible, self.setVisible = Roact.createBinding(false)
	self.timeLeft, self.setTimeLeft = Roact.createBinding("00:00")
	
	task.spawn(function()
		local gameValues = ReplicatedStorage:WaitForChild("GameValues")
		local mapVotes = ReplicatedStorage:WaitForChild("MapVotes")
		self.gameStatus = gameValues:WaitForChild("GameStatus")
		-- Set the maps in the state when the component loads if it is map voting time
		if self.gameStatus.Value == "MapVoting" then
			self.setTimeLeft(String.convertToMS(mapVotes.Timer.Value))
			self:startTimer(mapVotes)
			self.setVisible(true)
			self:setState({
				maps = mapVotes:WaitForChild("Maps"):GetChildren();
			})
		end
		-- When status changes to map voting, make this UI visible, or invisible if not
		self.maid:GiveTask(self.gameStatus.Changed:Connect(function()
			if self.gameStatus.Value == "MapVoting" then
				self.setTimeLeft(String.convertToMS(mapVotes.Timer.Value))
				self:startTimer(mapVotes)
				self:setState({
					maps = mapVotes:WaitForChild("Maps"):GetChildren();
				})
				self.setVisible(true)
			else
				self.setVisible(false)
			end
		end))
		-- If someone supervotes, show their name where the timer was, then reset the timer
		self.maid:GiveTask(superVoteEvent.OnClientEvent:Connect(function(playerName, map)
			self.running = false
			self.setTimeLeft(playerName .. " super voted for " .. map .. "!")
			if self.gameStatus.Value == "MapVoting" then
				self.gameStatus.Changed:Wait()
			end
			self.setTimeLeft("00:00")
		end))
	end)
end

-- Starts the timer for the map voting to be over
function MapVoting:startTimer(mapVotes)
	task.spawn(function()
		self.running = true
		while self.gameStatus.Value == "MapVoting" and self.running do
			self.setTimeLeft(String.convertToMS(mapVotes.Timer.Value))
			task.wait(1)
		end
		self.running = false
	end)
end

function MapVoting:render()
	local tiles = {}
	if self.state.maps then
		for _, map in pairs(self.state.maps) do
			table.insert(tiles, Roact.createElement(MapVotingTile, {
				map = map.Name;
			}))
		end
	end

	return Roact.createElement("Frame", {
		Active = true;
		AnchorPoint = Vector2.new(0.5, 1);
		BackgroundTransparency = 1;
		Position = UDim2.new(0.5, 0, 0.94, 0);
		Name = "MapVoting";
		ZIndex = 2;
		Visible = self.visible;
		Size = UDim2.new(0.398, 0, 0.28, 0);
		BackgroundColor3 = Color3.new(1, 1, 1);
	}, {
		Holder = Roact.createElement("Frame", {
			Active = true;
			BackgroundTransparency = 1;
			Name = "Holder";
			ZIndex = 2;
			Size = UDim2.new(1, 0, 1, 0);
		}, {
			Tiles = Roact.createFragment(tiles);

			UIListLayout = Roact.createElement("UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Center;
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Center;
				Padding = UDim.new(0.06, 0);
				SortOrder = Enum.SortOrder.LayoutOrder;
			});
		});

		TimeLeft = Roact.createElement("TextLabel", {
			FontSize = Enum.FontSize.Size14;
			TextColor3 = Color3.new(1, 1, 1);
			Text = self.timeLeft;
			Name = "TimeLeft";
			AnchorPoint = Vector2.new(0.5, 0);
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Position = UDim2.new(0.5, 0, 1, 0);
			Size = UDim2.new(0.4, 0, 0.2, 0);
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});

		Title = Roact.createElement("TextLabel", {
			FontSize = Enum.FontSize.Size14;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "Vote for the next map!";
			AnchorPoint = Vector2.new(0, 1);
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Name = "Title";
			Size = UDim2.new(1, 0, 0.2, 0);
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});
	})
end

function MapVoting:willUnmount()
	self.maid:DoCleaning()
end

return MapVoting