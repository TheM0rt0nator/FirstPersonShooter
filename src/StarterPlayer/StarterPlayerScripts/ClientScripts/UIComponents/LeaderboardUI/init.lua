local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local updateLeaderboardUI = getDataStream("UpdateLeaderboardUI", "RemoteEvent")
local playerKilledRemote = getDataStream("PlayerKilled", "RemoteEvent")
local gameOverEvent = getDataStream("GameOverEvent", "RemoteEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local UserInput = loadModule("UserInput")
local UICorner = loadModule("UICorner")
local LeaderboardTile = loadModule("LeaderboardTile")

local camera = workspace.CurrentCamera

local Leaderboard = Roact.Component:extend("Leaderboard")

-- When the component is initiated, connect the input for opening it
function Leaderboard:init()
	self.maid = Maid.new()
	self.enabled, self.setEnabled = Roact.createBinding(false)
	self.canvasSize, self.setCanvasSize = Roact.createBinding(UDim2.new(0, 0, 0, 0))
	self.winnerText, self.setWinnerText = Roact.createBinding("")
	self.roundType = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("RoundType")
	self.gameStatus = ReplicatedStorage.GameValues:WaitForChild("GameStatus")
	UserInput.connectInput(Enum.UserInputType.Keyboard, Enum.KeyCode.Tab, "Leaderboard", {
		beganFunc = function()
			if self.gameStatus.Value ~= "GameRunning" then return end
			-- Only let leaderboard open if we are in correct UI state
			if self.props.visible:getValue() then
				self.setEnabled(not self.enabled:getValue())
			end
		end;
	}, true)

	-- Listen to the update leaderboard and player killed remotes and update the UI
	self.maid:GiveTask(updateLeaderboardUI.OnClientEvent:Connect(function()
		if self.mounted then
			self:setState({})
		end
	end))
	self.maid:GiveTask(playerKilledRemote.OnClientEvent:Connect(function()
		if self.mounted then
			self:setState({})
		end
	end))
	self.maid:GiveTask(gameOverEvent.OnClientEvent:Connect(function(winner)
		self.setWinnerText(winner .. " wins!")
		self.setEnabled(true)
		task.wait(5)
		self.setWinnerText("")
		self.setEnabled(false)
	end))
end

-- Render the component
function Leaderboard:render()
	local tiles = {}
	local tileProps = {}
	local titleSeparateStats 
	-- Create the props for all the tiles
	for _, playerStats in pairs(ReplicatedStorage:WaitForChild("Leaderboard"):GetChildren()) do
		local playerName = playerStats.Name
		local separateStats = playerStats:GetChildren()
		if not titleSeparateStats then
			titleSeparateStats = separateStats
		end
		local props = {
			playerName = playerName;
			layoutOrder = 1;
		}
		-- Collect the stats and get their layout order and name to be displayed in the UI
		for _, stat in pairs(separateStats) do
			props[stat.Name] = {
				name = stat.Name;
				layoutOrder = stat:WaitForChild("LayoutOrderVal").Value;
				value = stat.Value;
			}
		end
		table.insert(tileProps, props)
	end
	if not titleSeparateStats then return end

	local roundType = self.roundType.Value

	-- Sorts the leaderboard from highest to lowest score type
	table.sort(tileProps, function(a, b)
		if a[roundType] and b[roundType] then
			return tonumber(a[roundType].value) > tonumber(b[roundType].value)
		end
	end)

	local titleProps = {
		playerName = "Player";
		layoutOrder = 0;
	}
	for i, stat in pairs(titleSeparateStats) do
		titleProps["stat" .. i] = {
			name = stat.Name;
			layoutOrder = stat:WaitForChild("LayoutOrderVal").Value;
			value = stat.Name;
		}
	end
	table.insert(tileProps, 1, titleProps)

	-- Create all the tiles in the correct order
	for layoutOrder, props in pairs(tileProps) do
		props.layoutOrder = layoutOrder
		table.insert(tiles, Roact.createElement(LeaderboardTile, props))
	end

	return Roact.createElement("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		ResetOnSpawn = false;
		-- Show if we are in the correct UI state and if the component is enabled
		Enabled = Roact.joinBindings({self.props.visible, self.enabled}):map(function(values)
			return values[1] and values[2]
		end);
	}, {
		Leaderboard = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = 0.4000000059604645;
			Position = UDim2.new(0.5, 0, 0.5, 0);
			Name = "Leaderboard";
			Size = UDim2.new(0.2, 0, 0.4, 0);
			BackgroundColor3 = Color3.new(0.678, 0.678, 0.678);
		}, {
			MainFrame = Roact.createElement("ScrollingFrame", {
				ScrollBarImageColor3 = Color3.new(0, 0, 0);
				Active = true;
				AnchorPoint = Vector2.new(0.5, 0);
				Name = "MainFrame";
				BackgroundTransparency = 1;
				Position = UDim2.new(0.5, 0, 0.13, 0);
				Size = UDim2.new(0, camera.ViewportSize.X * 0.2 * 0.95, 0.85, 0);
				BackgroundColor3 = Color3.new(1, 1, 1);
				BorderSizePixel = 0;
				CanvasSize = self.canvasSize;
			}, {
				Roact.createFragment(tiles);

				UIListLayout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					[Roact.Change.AbsoluteContentSize] = function(ui)
						self.setCanvasSize(UDim2.new(0, ui.AbsoluteContentSize.X, 0, ui.AbsoluteContentSize.Y + 10))
					end
				});
			});
	
			UICorner = UICorner(0.05, 0);
	
			Title = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(0, 0, 0);
				Text = ReplicatedStorage:WaitForChild("GameValues").CurrentMode.Value;
				Name = "Title";
				AnchorPoint = Vector2.new(0.5, 0);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0.5, 0, 0, 0);
				Size = UDim2.new(1, 0, 0.124, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
	
			LineDivider = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0);
				Name = "LineDivider";
				Position = UDim2.new(0.5, 0, 0.123, 0);
				Size = UDim2.new(0.706, 0, 0.001, 0);
				BorderSizePixel = 0;
				BackgroundColor3 = Color3.new(0, 0, 0);
			}, {
				UICorner = UICorner(1, 0);
			});

			Winner = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(1, 1, 1);
				Text = self.winnerText;
				Name = "Winner";
				TextStrokeTransparency = 0.6000000238418579;
				AnchorPoint = Vector2.new(0.5, 0);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0.5, 0, -0.124, 0);
				Size = UDim2.new(1, 0, 0.124, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			})
			
		});
	})
end

-- WHen the component is unmounted, cleanup it's connections
function Leaderboard:willUnmount()
	self.maid:DoCleaning()
	UserInput.disconnectInput(Enum.UserInputType.Keyboard, "Leaderboard")
end

-- Let the component know it has been mounted
function Leaderboard:didMount()
	self.mounted = true
end

return Leaderboard