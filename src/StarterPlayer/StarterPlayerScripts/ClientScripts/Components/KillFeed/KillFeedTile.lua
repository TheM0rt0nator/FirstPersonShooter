local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")

local KillFeedTile = Roact.Component:extend("KillFeedTile")

function KillFeedTile:render()
	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 1);
		Name = "KillTile";
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 1, 0);
		Size = UDim2.new(1, 0, 0.122, 0);
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(1, 1, 1);
	}, {
		KilledText = Roact.createElement("TextLabel", {
			FontSize = Enum.FontSize.Size14;
			TextColor3 = Color3.new(0.741, 0.741, 0.741);
			Text = "killed";
			TextStrokeTransparency = 0.5;
			Name = "KilledText";
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Position = UDim2.new(0.4, 0, 0, 0);
			Size = UDim2.new(0.2, 0, 1, 0);
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});

		Killer = Roact.createElement("TextLabel", {
			TextColor3 = Color3.new(0, 0.882, 0.043);
			Text = self.props.killerName;
			Name = "Killer";
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Right;
			Size = UDim2.new(0.4, 0, 1, 0);
			FontSize = Enum.FontSize.Size14;
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});

		Victim = Roact.createElement("TextLabel", {
			TextColor3 = Color3.new(0.686, 0.02, 0);
			Text = self.props.victimName;
			Name = "Victim";
			Size = UDim2.new(0.4, 0, 1, 0);
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			Position = UDim2.new(0.6, 0, 0, 0);
			FontSize = Enum.FontSize.Size14;
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});
	});
end

return KillFeedTile