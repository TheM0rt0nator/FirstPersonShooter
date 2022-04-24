local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local superVoteEvent = getDataStream("SuperVoteEvent", "RemoteEvent")
local mapVotesChanged = getDataStream("MapVotesChanged", "RemoteEvent")
local superVoteFunc = getDataStream("SuperVoteFunc", "RemoteFunction")
local localMapVotesChanged = getDataStream("LocalMapVotesChanged", "BindableEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local UICorner = loadModule("UICorner")
local UIStroke = loadModule("UIStroke")

local camera = workspace.CurrentCamera

local MapVotingTile = Roact.Component:extend("MapVotingTile")

function MapVotingTile:init()
	self.maid = Maid.new()
	self.votes, self.setVotes = Roact.createBinding("0")
	self.selected, self.setSelected = Roact.createBinding(false)
	self.supervoteVisible, self.setSuperVoteVisible = Roact.createBinding(true)
	self.debounce = false
	self.superVoteDebounce = false

	task.spawn(function()
		local gameValues = ReplicatedStorage:WaitForChild("GameValues")
		self.mapVotes = ReplicatedStorage:WaitForChild("MapVotes")
		self.gameStatus = gameValues:WaitForChild("GameStatus")
		-- When the tile loads, set it's votes to the value in replicated storage for this map
		if self.gameStatus.Value == "MapVoting" then
			self.setVotes(tostring(self.mapVotes.Maps:FindFirstChild(self.props.map).Value))
			self:superVoteCheck()
		end
		-- Change the value when the repstorage value changes
		self.maid:GiveTask(mapVotesChanged.OnClientEvent:Connect(function()
			self.setVotes(tostring(self.mapVotes.Maps:FindFirstChild(self.props.map).Value))
		end))
		-- Set the votes back to 0 when the map voting stage is over, or set it to the votes when it is map voting
		self.maid:GiveTask(self.gameStatus.Changed:Connect(function()
			if self.gameStatus.Value ~= "MapVoting" then
				self.setVotes("0")
				self.setSelected(false)
			else
				self.setSuperVoteVisible(true)
				self:superVoteCheck()
				self.setVotes(tostring(self.mapVotes.Maps:FindFirstChild(self.props.map).Value))
			end
		end))
		-- Selection box around selected vote
		self.maid:GiveTask(localMapVotesChanged.Event:Connect(function(vote)
			if self.props.vote ~= vote then
				self.setSelected(false)
			end
		end))
		-- If someone supervotes, need to disable the voting buttons
		self.maid:GiveTask(superVoteEvent.OnClientEvent:Connect(function(playerName, map)
			-- Disable the buttons
			self.debounce = true
			self.running = false
			self.setSuperVoteVisible(false)
			self.superVoteDebounce = true
			if self.props.map == map then
				self.setVotes("SUPERVOTED!")
			end
			if self.gameStatus.Value == "MapVoting" then
				self.gameStatus.Changed:Wait()
			end
			self.setVotes("0")
			-- Enable the buttons
			self.debounce = false
			self.superVoteDebounce = false
		end))
	end)
end

-- Loops to check when to hide the supervote buttons (when 5 seconds until voting ends)
function MapVotingTile:superVoteCheck()
	task.spawn(function()
		self.running = true
		while self.gameStatus.Value == "MapVoting" and self.running do
			if self.mapVotes.Timer.Value <= 5 then
				self.setSuperVoteVisible(false)
				break
			end
			task.wait(1)
		end
		self.running = false
	end)
end

function MapVotingTile:render()
	if self.gameStatus.Value == "MapVoting" and self.mapVotes.Timer.Value > 5 and not self.mapVotes:FindFirstChild("SuperVote") then
		self.setSuperVoteVisible(true)
	end

	return Roact.createElement("ImageButton", {
		ScaleType = Enum.ScaleType.Fit;
		Name = "Template";
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png";
		BackgroundTransparency = 1;
		Size = UDim2.new(0.25, 0, 0.25, 0);
		SizeConstraint = Enum.SizeConstraint.RelativeXX;
		ZIndex = 3;
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(1, 1, 1);
		[Roact.Event.MouseButton1Click] = function()
			if not self.debounce then
				self.debounce = true
				-- When we click on a vote, fire the server with the map we want to vote for
				mapVotesChanged:FireServer(self.props.map)
				localMapVotesChanged:Fire(self.props.map)
				self.setSelected(true)
				task.wait(1)
				self.debounce = false
			end
		end
	}, {
		Votes = Roact.createElement("TextLabel", {
			FontSize = Enum.FontSize.Size14;
			TextColor3 = Color3.new(1, 1, 1);
			Text = self.votes;
			TextStrokeTransparency = 0.5;
			Name = "Votes";
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 1, 0);
			Size = UDim2.new(1, 0, 0.25, 0);
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});

		MapName = Roact.createElement("TextLabel", {
			FontSize = Enum.FontSize.Size14;
			TextColor3 = Color3.new(1, 1, 1);
			Text = self.props.map;
			TextStrokeTransparency = 0.5;
			AnchorPoint = Vector2.new(0, 1);
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Name = "MapName";
			Size = UDim2.new(1, 0, 0.25, 0);
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});

		UIStroke = UIStroke({
			applyStrokeMode = Enum.ApplyStrokeMode.Border;
			color = Color3.fromRGB(0, 154, 12);
			thickness = camera.ViewportSize.X * 0.0026;
			enabled = self.selected;
		});

		UICorner = UICorner(0.1, 0);

		SuperVote = Roact.createElement("TextButton", {
			FontSize = Enum.FontSize.Size14;
			TextColor3 = Color3.new(0, 0, 0);
			Text = "SUPER VOTE";
			AnchorPoint = Vector2.new(0, 1);
			Font = Enum.Font.Oswald;
			Name = "SuperVote";
			Position = UDim2.new(0, 0, 1, 0);
			Size = UDim2.new(1, 0, 0.2, 0);
			Visible = self.supervoteVisible;
			TextScaled = true;
			BackgroundColor3 = Color3.new(0, 0.678, 0.02);
			[Roact.Event.MouseButton1Click] = function()
				if not self.superVoteDebounce then
					self.superVoteDebounce = true
					local success = superVoteFunc:InvokeServer(self.props.map)
					if success then
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, 1259784642)
					end
					task.wait(1)
					self.superVoteDebounce = false
				end
			end
		}, {
			UICorner = UICorner(0.4, 0);
		})
		
	});
end

function MapVotingTile:willUnmount()
	self.maid:DoCleaning()
end

return MapVotingTile