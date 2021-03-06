local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local setInterfaceState = getDataStream("SetInterfaceState", "BindableEvent")

local Roact = loadModule("Roact")
local Maid = loadModule("Maid")

local MainInterface = Roact.Component:extend("MainInterface")

local Components = {
	DiedNotification = loadModule("DiedNotification");
	FlashbangCover = loadModule("FlashbangCover");
	HitMarkers = loadModule("HitMarkers");
	HUD = loadModule("HUD");
	KillFeed = loadModule("KillFeed");
	KillNotification = loadModule("KillNotification");
	KitSelection = loadModule("KitSelection");
	LeaderboardUI = loadModule("LeaderboardUI");
	SniperScope = loadModule("SniperScope");
}

local InterfaceStates = {
	kitSelection = {
		"KitSelection";
	};
	inGame = {
		"DiedNotification";
		"FlashbangCover";
		"HitMarkers";
		"HUD";
		"KillFeed";
		"KillNotification";
		"LeaderboardUI";
		"SniperScope";
	};
}

function MainInterface:init()
	self.maid = Maid.new()
	self.currentState = nil
	self.visibilityBindings = {}
	self.setVisibleBindings = {}
	-- Create a binding for each component, to tell it whether to be visible or not
	for componentName, _ in pairs(Components) do
		self.visibilityBindings[componentName], self.setVisibleBindings[componentName] = Roact.createBinding(false)
	end

	-- When the setInterfaceState Bindable is fired, set the state of the interface and set the relevant components visibility binding to true/false
	self.maid:GiveTask(setInterfaceState.Event:Connect(function(state)
		if state and InterfaceStates[state] and self.currentState ~= state then
			self:setState(state)
		end
	end))

	self:setState("kitSelection")
end

function MainInterface:setState(state)
	self.currentState = state
	local stateComponents = InterfaceStates[state]
	-- Set the components in this state to visible = true and the rest to false
	for componentName, _ in pairs(Components) do
		if not table.find(stateComponents, componentName) and self.visibilityBindings[componentName] and self.setVisibleBindings[componentName] then
			self.setVisibleBindings[componentName](false)
		else
			self.setVisibleBindings[componentName](true)
		end
	end
end

function MainInterface:render()
	local children = {}

	for componentName, component in pairs(Components) do
		children[componentName] = Roact.createElement(component, {
			visible = self.visibilityBindings[componentName]
		})
	end

	-- Create a screen Gui for the main interface, and put everything else inside this screen gui
	return Roact.createElement("ScreenGui", {
		Name = "MainInterface";
		ResetOnSpawn = false;
	}, children)
end

return MainInterface