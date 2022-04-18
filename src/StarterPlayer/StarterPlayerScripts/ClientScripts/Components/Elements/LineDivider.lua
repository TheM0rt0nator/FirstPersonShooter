local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local UICorner = loadModule("UICorner")

local LineDivider = Roact.Component:extend("LineDivider")

-- Line divider to be re-used anywhere
function LineDivider:render()
	return Roact.createElement("Frame", {
		Name = "Line";
		BackgroundTransparency = 0.20000000298023224;
		Position = self.props.position;
		Size = self.props.size;
		BorderSizePixel = 0;
		BackgroundColor3 = Color3.new(0.224, 0.224, 0.224);
	}, {
		UICorner = UICorner(1, 0);
	});
end

return LineDivider