local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local LineDivider = loadModule("LineDivider")

local KitInfoFrame = Roact.Component:extend("KitInfoFrame")

-- Template for a kit info frame
function KitInfoFrame:render()
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1;
		Position = self.props.position or UDim2.new(0, 0, 0, 0);
		Name = self.props.name;
		Size = self.props.size;
		BackgroundColor3 = Color3.new(1, 1, 1);
	}, {
		Line = Roact.createElement(LineDivider, {
			position = UDim2.new(0.265, 0, 0.398, 0);
			size = UDim2.new(0.469, 0, 0.02, 0);
		});

		Title = Roact.createElement("TextLabel", {
			TextColor3 = Color3.new(0, 0, 0);
			Text = self.props.text;
			Name = "Title";
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Position = UDim2.new(0.178, 0, 0, 0);
			Size = UDim2.new(0.642, 0, 0.4, 0);
			FontSize = Enum.FontSize.Size14;
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});

		WeaponName = Roact.createElement("TextLabel", {
			FontSize = Enum.FontSize.Size14;
			TextColor3 = Color3.new(0, 0, 0);
			Text = self.props.weaponName;
			Name = "WeaponName";
			AnchorPoint = Vector2.new(0, 1);
			Font = Enum.Font.Oswald;
			BackgroundTransparency = 1;
			Position = UDim2.new(0.178, 0, 0.9, 0);
			Size = UDim2.new(0.642, 0, 0.4, 0);
			TextScaled = true;
			BackgroundColor3 = Color3.new(1, 1, 1);
		});
	});
end

return KitInfoFrame