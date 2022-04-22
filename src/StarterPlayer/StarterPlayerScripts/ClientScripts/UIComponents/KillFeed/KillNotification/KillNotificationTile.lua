local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")

local KillNotificationTile = Roact.Component:extend("KillNotificationTile")

function KillNotificationTile:render()
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1;
		Name = "KillNotification";
		Size = UDim2.new(1, 0, 0.2, 0);
		BackgroundColor3 = Color3.new(1, 1, 1);
	}, {
		Kills = Roact.createElement("TextLabel", {
			TextColor3 = Color3.new(1, 1, 0);
			Text = "+1 Kill";
			Name = "Kills";
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			Size = UDim2.new(0.4, 0, 1, 0);
			FontSize = Enum.FontSize.Size14;
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});
	
		Victim = Roact.createElement("TextLabel", {
			TextColor3 = Color3.new(1, 0.318, 0);
			Text = self.props.victimName;
			Name = "Victim";
			Size = UDim2.new(0.6, 0, 1, 0);
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Right;
			Position = UDim2.new(0.4, 0, 0, 0);
			FontSize = Enum.FontSize.Size14;
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});
	})
	
end

return KillNotificationTile