local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local Roact = loadModule("Roact")

local hitPlayerEvent = getDataStream("HitPlayerEvent", "BindableEvent")

local HitMarkers = Roact.Component:extend("HitMarkers")

function HitMarkers:init()
	hitPlayerEvent.Event:Connect(function(part)
		print("Show hitmarkers!")
	end)
end

function HitMarkers:render()
	return Roact.createElement("ScreenGui")
end

return HitMarkers
