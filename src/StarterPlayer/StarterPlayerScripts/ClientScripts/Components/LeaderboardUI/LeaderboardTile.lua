local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Camera = workspace.CurrentCamera

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")

local LeaderboardTile = Roact.Component:extend("LeaderboardTile")

-- This could be extended to more gamemodes 
function LeaderboardTile:render()
	local xSize = Camera.ViewportSize.X * 0.2 * 0.95
	local children = {
		PlayerName = Roact.createElement("TextLabel", {
			TextColor3 = Color3.new(0, 0, 0);
			Text = self.props.playerName;
			Name = "PlayerName";
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Size = UDim2.new(0, 0.6 * xSize, 1, 0);
			BorderSizePixel = 0;
			FontSize = Enum.FontSize.Size14;
			TextScaled = true;
			LayoutOrder = 1;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});
	}
	local numStats = 0
	-- Collect all the stats and put them in the UI
	for propName, stat in pairs(self.props) do
		if propName ~= "playerName" and propName ~= "layoutOrder" then
			numStats += 1
			children[propName] = Roact.createElement("TextLabel", {
				TextColor3 = Color3.new(0, 0, 0);
				Text = stat.value;
				Name = stat.name;
				Size = UDim2.new(0, 0.2 * xSize, 1, 0);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0, (0.6 * xSize) + ((stat.layoutOrder - 1) * 0.2 * xSize), 0, 0);
				BorderSizePixel = 0;
				FontSize = Enum.FontSize.Size14;
				TextScaled = true;
				LayoutOrder = 1 + stat.layoutOrder;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
		end
	end

	local statXAddition = numStats > 2 and (0.2 * xSize * (numStats - 2)) or 0

	return Roact.createElement("Frame", {
		BackgroundTransparency = 1;
		Name = "Tile";
		LayoutOrder = self.props.layoutOrder;
		Size = UDim2.new(0, xSize + statXAddition, 0, Camera.ViewportSize.Y * 0.0324);
		BackgroundColor3 = Color3.new(1, 1, 1);
	}, children);
end

return LeaderboardTile