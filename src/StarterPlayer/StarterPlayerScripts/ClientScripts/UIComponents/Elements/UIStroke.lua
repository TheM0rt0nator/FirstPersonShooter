local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")

local UIStroke = Roact.Component:extend("UIStroke")

-- UI Stroke component to consolidate code
function UIStroke:render()
	return Roact.createElement("UIStroke", {
		Color = self.props.color or Color3.new();
		ApplyStrokeMode = self.props.applyStrokeMode or Enum.ApplyStrokeMode.Contextual;
		LineJoinMode = self.props.lineJoinMode or Enum.LineJoinMode.Round;
		Thickness = self.props.thickness or 1;
		Transparency = self.props.transparency or 0;
		Enabled = self.props.enabled;
	})
end

return function(props)
	return Roact.createElement(UIStroke, props)
end
