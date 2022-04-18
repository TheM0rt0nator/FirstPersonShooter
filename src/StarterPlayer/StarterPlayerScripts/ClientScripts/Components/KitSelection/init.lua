local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local UICorner = loadModule("UICorner")
local KitInfoFrame = loadModule("KitInfoFrame")
local KitButtonTemplate = loadModule("KitButtonTemplate")
local WeaponKits = loadModule("WeaponKits")

local KitSelection = Roact.Component:extend("KitSelection")

-- Set up the timer binding
function KitSelection:init()
	self:setState({
		currentKit = "Assault";
	})
end

-- Render the UI
function KitSelection:render()
	local visible = self.props.visible
	local currentKit = self.state.currentKit

	-- Group the buttons by getting the kits from the WeaponKits module
	local kitButtons = {}
	for kitName, kitInfo in pairs(WeaponKits) do
		kitButtons[kitName] = Roact.createElement(KitButtonTemplate, {
			text = kitName;
			isSelected = kitName == currentKit;
			onClick = function()
				-- Only re-render the UI if we are clicking on a new kit
				if self.state.currentKit == kitName then return end
				self:setState({
					currentKit = kitName;
				})
			end;
			layoutOrder = kitInfo.layoutOrder;
		});
	end

	-- Create the UI
	return Roact.createElement("ScreenGui", {
		Name = "KitSelection";
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
		Enabled = visible;
	}, {
		Holder = Roact.createElement("Frame", {
			BackgroundTransparency = 1;
			Name = "Holder";
			Size = UDim2.new(1, 0, 1, 0);
			BackgroundColor3 = Color3.new(1, 1, 1);
		}, {
			KitInfoHolder = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 0.5);
				BackgroundTransparency = 0.699999988079071;
				Position = UDim2.new(-0.018, 0, 0.5, 0);
				Name = "KitInfoHolder";
				Size = UDim2.new(0.181, 0, 0.394, 0);
				BackgroundColor3 = Color3.new(0.631, 0.631, 0.631);
			}, {
				PrimaryInfo = Roact.createElement(KitInfoFrame, {
					name = "PrimaryInfo";
					text = "Primary";
					size = UDim2.new(1, 0, 0.33, 0);
					weaponName = WeaponKits[currentKit].Weapons.Primary;
				});

				SecondaryInfo = Roact.createElement(KitInfoFrame, {
					name = "SecondaryInfo";
					text = "Secondary";
					size = UDim2.new(1, 0, 0.33, 0);
					position = UDim2.new(0, 0, 0.33, 0);
					weaponName = WeaponKits[currentKit].Weapons.Secondary;
				});

				EquipmentInfo = Roact.createElement(KitInfoFrame, {
					name = "EquipmentInfo";
					text = "Equipment";
					size = UDim2.new(1, 0, 0.33, 0);
					position = UDim2.new(0, 0, 0.66, 0);
					weaponName = WeaponKits[currentKit].Equipment[1];
				});
	
				UICorner = UICorner(0.1, 0);
			});
	
			KitButtonHolder = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 1);
				Name = "KitButtonHolder";
				BackgroundTransparency = 0.699999988079071;
				Position = UDim2.new(0.5, 0, 1.016, 0);
				Size = UDim2.new(0.7, 0, 0.178, 0);
				BorderSizePixel = 0;
				BackgroundColor3 = Color3.new(0.631, 0.631, 0.631);
			}, {
				KitButtons = Roact.createFragment(kitButtons);
	
				UIListLayout = Roact.createElement("UIListLayout", {
					VerticalAlignment = Enum.VerticalAlignment.Center;
					FillDirection = Enum.FillDirection.Horizontal;
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
					Padding = UDim.new(0.03, 0);
					SortOrder = Enum.SortOrder.LayoutOrder;
				});
	
				UICorner = UICorner(0.1, 0);
			});
	
			SpawnButton = Roact.createElement("TextButton", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(0, 0, 0);
				Text = "Spawn";
				AnchorPoint = Vector2.new(0.5, 0);
				Font = Enum.Font.Oswald;
				Name = "SpawnButton";
				Position = UDim2.new(0.5, 0, 0.77, 0);
				Size = UDim2.new(0.1, 0, 0.06, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
				[Roact.Event.MouseButton1Click] = function()
					print("Spawning player")
				end;
			}, {
				UICorner = UICorner(0.2, 0);
			});

			
			Title = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(0, 0, 0);
				Text = "Call To Arms";
				Name = "Title";
				AnchorPoint = Vector2.new(0.5, 0);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0.5, 0, 0, 0);
				Size = UDim2.new(0.3, 0, 0.118, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
		});
	})
end

return KitSelection