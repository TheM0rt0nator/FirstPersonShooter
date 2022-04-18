local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")

local UICorner = Roact.Component:extend("UICorner")

-- UI Cornder component to consolidate code
function UICorner:render()
	return Roact.createElement("UICorner", {
		CornerRadius = UDim.new(self.props.scale, self.props.offset)
	})
end

return function(scale, offset)
	return Roact.createElement(UICorner,{
		scale = scale;
		offset = offset;
	})
end
