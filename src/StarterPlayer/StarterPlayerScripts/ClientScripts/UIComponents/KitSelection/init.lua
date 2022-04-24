local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local spawnPlayerFunc = getDataStream("SpawnPlayerFunc", "RemoteFunction")
local setInterfaceState = getDataStream("SetInterfaceState", "BindableEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")
local UICorner = loadModule("UICorner")
local KitInfoFrame = loadModule("KitInfoFrame")
local KitButtonTemplate = loadModule("KitButtonTemplate")
local WeaponKits = loadModule("WeaponKits")
local WeaponHandler = loadModule("WeaponHandler")
local MapVoting = loadModule("MapVoting")

local camera = workspace.CurrentCamera

local KitSelection = Roact.Component:extend("KitSelection")

-- Set up the timer binding
function KitSelection:init()
	self.maid = Maid.new()
	self.debounce = false
	task.spawn(function()
		self.gameStatus = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("GameStatus")
		local text = if self.gameStatus.Value == "GameRunning" then "DEPLOY" else "INTERMISSION"
		self.buttonVisible, self.setButtonVisible = Roact.createBinding(false)
		if self.gameStatus.Value == "MapVoting" then
			self.setButtonVisible(false)
		end
		self.buttonText, self.setButtonText = Roact.createBinding(text)
		self.maid:GiveTask(self.gameStatus.Changed:Connect(function()
			local status = self.gameStatus.Value
			self.setButtonText(if status == "GameRunning" then "DEPLOY" elseif status == "ChoosingMap" then "LOADING MAP" else "INTERMISSION")
			if self.gameStatus.Value == "MapVoting" then
				self.setButtonVisible(false)
			else
				self.setButtonVisible(true)
			end
		end))
		self:setState({
			currentKit = "Assault";
		})
	end)
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
		ResetOnSpawn = false;
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
					weaponName = WeaponKits[currentKit].Equipment[1].Name;
				});
	
				UICorner = UICorner(0.1, 0);
			});
	
			KitButtonHolder = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 1);
				Name = "KitButtonHolder";
				BackgroundTransparency = 0.699999988079071;
				Position = UDim2.new(0.5, 0, 0.095, 0);
				Size = UDim2.new(0.45, 0, 0.074, 0);
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
	
			DeployButton = Roact.createElement("TextButton", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(0, 0, 0);
				Text = self.buttonText;
				AnchorPoint = Vector2.new(0.5, 1);
				Font = Enum.Font.Oswald;
				Name = "SpawnButton";
				Position = UDim2.new(0.5, 0, 0.98, 0);
				Size = UDim2.new(0.15, 0, 0.1, 0);
				TextScaled = true;
				Visible = self.buttonVisible;
				BackgroundColor3 = Color3.new(1, 1, 1);
				[Roact.Event.MouseButton1Click] = function()
					if not self.debounce and self.buttonText:getValue() == "DEPLOY" then
						self.debounce = true
						self.setButtonText("DEPLOYING")
						local success = spawnPlayerFunc:InvokeServer(self.state.currentKit)
						if success then
							WeaponHandler:setupWeapons(self.state.currentKit)
							camera.CameraType = Enum.CameraType.Custom
							camera.CameraSubject = Players.LocalPlayer.Character:WaitForChild("Humanoid")
							self.setButtonText("DEPLOY")
						end
						task.wait(3)
						self.debounce = false
					end
				end;
			}, {
				UICorner = UICorner(0.2, 0);
			});

			MapVoting = Roact.createElement(MapVoting);
			
			Title = Roact.createElement("TextLabel", {
				FontSize = Enum.FontSize.Size14;
				TextColor3 = Color3.new(1, 1, 1);
				Text = "Call To Arms";
				Name = "Title";
				AnchorPoint = Vector2.new(0, 1);
				Font = Enum.Font.Oswald;
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 0, 1, 0);
				Size = UDim2.new(0.2, 0, 0.118, 0);
				TextScaled = true;
				BackgroundColor3 = Color3.new(1, 1, 1);
			});
		});
	})
end

return KitSelection