local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local UICorner = loadModule("UICorner")

local KitButtonTemplate = Roact.Component:extend("KitButtonTemplate")

-- Template for a kit selection button
function KitButtonTemplate:render()
	return Roact.createElement("TextButton", {
		FontSize = Enum.FontSize.Size14;
		TextColor3 = Color3.new(0, 0, 0);
		Text = self.props.text;
		AnchorPoint = Vector2.new(0, 0.5);
		Font = Enum.Font.Oswald;
		Name = "KitButtonTemplate";
		Size = UDim2.new(0.2, 0, 0.08, 0);
		SizeConstraint = Enum.SizeConstraint.RelativeXX;
		TextScaled = true;
		LayoutOrder = self.props.layoutOrder;
		BackgroundColor3 = Color3.new(1, 1, 1);
		AutoButtonColor = not self.props.isSelected;
		[Roact.Event.MouseButton1Click] = function()
			if typeof(self.props.onClick) == "function" then
				self.props.onClick()
			end
		end
	}, {
		UICorner = UICorner(0.1, 0);

		UIStroke = Roact.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
			Transparency = 0.7;
			Color = Color3.new(0.067, 1, 0);
			Thickness = 5;
			Enabled = self.props.isSelected;
		});
	});
end

return KitButtonTemplate