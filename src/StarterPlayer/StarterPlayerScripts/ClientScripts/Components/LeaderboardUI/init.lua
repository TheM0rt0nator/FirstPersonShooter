--[[
	- Create multiple components in this folder which make up the leaderboard, and connect the tab button to it to display it if they are in-game
	- Create components called the current gamemode so the leaderboard can be different per gamemode
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local UserInput = loadModule("UserInput")

local Leaderboard = Roact.Component:extend("HitMarkers")

-- When the component is initiated, connect the input for opening it
function Leaderboard:init()
	self.maid = Maid.new()
	self.enabled, self.setEnabled = Roact.createBinding(false)
	UserInput.connectInput(Enum.UserInputType.Keyboard, Enum.KeyCode.Tab, "Leaderboard", {
		beganFunc = function()
			-- Only let leaderboard open if we are in correct UI state
			if self.props.visible:getValue() then
				self.setEnabled(not self.enabled:getValue())
			end
		end;
	}, true)
end

-- Render the component
function Leaderboard:render()
	return Roact.createElement("ScreenGui", {
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
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
				Position = UDim2.new(0.5, 0, 0.248, 0);
				Size = UDim2.new(0.95, 0, 0.721, 0);
				BackgroundColor3 = Color3.new(1, 1, 1);
				BorderSizePixel = 0;
				CanvasSize = UDim2.new(0, 0, 0, 0);
			}, {
				TileTemplate = Roact.createElement("Frame", {
					BackgroundTransparency = 1;
					Name = "TileTemplate";
					Size = UDim2.new(1, 0, 0.1, 0);
					BackgroundColor3 = Color3.new(1, 1, 1);
				}, {
					Deaths = Roact.createElement("TextLabel", {
						TextColor3 = Color3.new(0, 0, 0);
						Text = "1";
						Name = "Deaths";
						Size = UDim2.new(0.2, 0, 0.1, 0);
						Font = Enum.Font.Oswald;
						BackgroundTransparency = 1;
						Position = UDim2.new(0.76, 0, 0, 0);
						BorderSizePixel = 0;
						FontSize = Enum.FontSize.Size14;
						TextScaled = true;
						BackgroundColor3 = Color3.new(1, 1, 1);
					});
	
					Kills = Roact.createElement("TextLabel", {
						TextColor3 = Color3.new(0, 0, 0);
						Text = "23";
						Name = "Kills";
						Size = UDim2.new(0.2, 0, 0.1, 0);
						Font = Enum.Font.Oswald;
						BackgroundTransparency = 1;
						Position = UDim2.new(0.56, 0, 0, 0);
						BorderSizePixel = 0;
						FontSize = Enum.FontSize.Size14;
						TextScaled = true;
						BackgroundColor3 = Color3.new(1, 1, 1);
					});
	
					PlayerName = Roact.createElement("TextLabel", {
						TextColor3 = Color3.new(0, 0, 0);
						Text = "TheM0rt0antor";
						Name = "PlayerName";
						Font = Enum.Font.Oswald;
						BackgroundTransparency = 1;
						Size = UDim2.new(0.6, 0, 0.11, 0);
						BorderSizePixel = 0;
						FontSize = Enum.FontSize.Size14;
						TextScaled = true;
						BackgroundColor3 = Color3.new(1, 1, 1);
					});
				});
	
				UITableLayout = Roact.createElement("UITableLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder;
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
				});
			});
	
			Titles = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0);
				Name = "Titles";
				BackgroundTransparency = 1;
				Position = UDim2.new(0.5, 0, 0.139, 0);
				Size = UDim2.new(0.95, 0, 0.091, 0);
				BorderSizePixel = 0;
				BackgroundColor3 = Color3.new(1, 1, 1);
			}, {
				NameTitle = Roact.createElement("TextLabel", {
					TextColor3 = Color3.new(0, 0, 0);
					Text = "Player";
					Font = Enum.Font.Oswald;
					BackgroundTransparency = 1;
					Name = "NameTitle";
					Size = UDim2.new(0.6, 0, 1, 0);
					FontSize = Enum.FontSize.Size14;
					TextScaled = true;
					BackgroundColor3 = Color3.new(1, 1, 1);
				});
	
				KillsTitle = Roact.createElement("TextLabel", {
					LayoutOrder = 2;
					TextColor3 = Color3.new(0, 0, 0);
					Text = "Kills";
					Name = "KillsTitle";
					Font = Enum.Font.Oswald;
					BackgroundTransparency = 1;
					FontSize = Enum.FontSize.Size14;
					Size = UDim2.new(0.2, 0, 1, 0);
					ZIndex = 2;
					TextScaled = true;
					BackgroundColor3 = Color3.new(1, 1, 1);
				});
	
				DeathsTitle = Roact.createElement("TextLabel", {
					LayoutOrder = 4;
					TextColor3 = Color3.new(0, 0, 0);
					Text = "Deaths";
					Font = Enum.Font.Oswald;
					BackgroundTransparency = 1;
					Name = "DeathsTitle";
					Size = UDim2.new(0.2, 0, 1, 0);
					FontSize = Enum.FontSize.Size14;
					TextScaled = true;
					BackgroundColor3 = Color3.new(1, 1, 1);
				});
	
				UIListLayout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal;
					SortOrder = Enum.SortOrder.LayoutOrder;
				});
			});
	
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0);
			});
	
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0.05, 0);
			});
	
			Title = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(0, 0, 0);
				Text = "Free For All";
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
			});
		});
	})
end

-- WHen the component is unmounted, cleanup it's connections
function Leaderboard:willUnmount()
	self.maid:DoCleaning()
	UserInput.disconnectInput(Enum.UserInputType.Keyboard, "Leaderboard")
end

return Leaderboard