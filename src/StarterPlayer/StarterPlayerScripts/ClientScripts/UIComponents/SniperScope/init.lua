local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local sniperAimEvent = getDataStream("SniperAimEvent", "BindableEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")

local camera = workspace.CurrentCamera

local SniperScope = Roact.Component:extend("SniperScope")

function SniperScope:init()
	self.maid = Maid.new()
	self.visible, self.setVisible = Roact.createBinding(false)
	-- Listen to the sniper aim event to see when we're aiming with a sniper, and change the field of view and visiblity of the scope
	self.maid:GiveTask(sniperAimEvent.Event:Connect(function(bool, fov)
		self.setVisible(bool)
		camera.FieldOfView = fov
	end))
end

function SniperScope:render()
	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false;
		Name = "SniperScope";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		Enabled = Roact.joinBindings({self.props.visible, self.visible}):map(function(values)
			return values[1] and values[2]
		end);
	}, {
		ScopeImage = Roact.createElement("ImageLabel", {
			Name = "ScopeImage";
			AnchorPoint = Vector2.new(0.5, 0.5);
			Image = "rbxassetid://9457435092";
			BackgroundTransparency = 1;
			Position = UDim2.new(0.5, 0, 0.5, 0);
			SizeConstraint = Enum.SizeConstraint.RelativeXX;
			Size = UDim2.new(0.4, 0, 0.4, 0);
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new(1, 1, 1);
		}, {
			RightCover = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 0.5);
				Name = "RightCover";
				Position = UDim2.new(1, 0, 0.5, 0);
				Size = UDim2.new(1, 0, 1, 0);
				BorderSizePixel = 0;
				BackgroundColor3 = Color3.new(0, 0, 0);
			});
	
			LeftCover = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 0.5);
				Name = "LeftCover";
				Position = UDim2.new(-1, 0, 0.5, 0);
				Size = UDim2.new(1, 0, 1, 0);
				BorderSizePixel = 0;
				BackgroundColor3 = Color3.new(0, 0, 0);
			});
	
			BottomCover = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0);
				Name = "BottomCover";
				Position = UDim2.new(0.5, 0, 1, 0);
				Size = UDim2.new(3, 0, 1, 0);
				BorderSizePixel = 0;
				BackgroundColor3 = Color3.new(0, 0, 0);
			});
	
			TopCover = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 1);
				Name = "TopCover";
				Position = UDim2.new(0.5, 0, 0, 0);
				Size = UDim2.new(3, 0, 1, 0);
				BorderSizePixel = 0;
				BackgroundColor3 = Color3.new(0, 0, 0);
			});
		});
	})	
end

return SniperScope