-- Imported this from a previous project I made

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local camTypeChanged = getDataStream("CamTypeChanged", "BindableEvent")

local Cam = {
	currentType = "Default";
}

local camera = workspace.CurrentCamera

-- Compile all of the camera modes into this module
for _, module in pairs(script:GetChildren()) do
	Cam[module.Name] = require(module)
end

-- Sets a unique custom camera type if it exists
function Cam:setCameraType(camType, ...)
	if self.currentType ~= camType and camType == "Default" then
		self:returnToPlayer()
		return
	end
	if self[camType] then 
		self.currentType = camType
		self[camType](self, ...)
		camTypeChanged:Fire(camType)
	elseif Enum.CameraType[camType] then
		self.currentType = camType
		camera.CameraType = Enum.CameraType[camType]
		camTypeChanged:Fire(camType)
	end
end

-- Returns the camera to the player, with an optional argument to tween, and a tween duration
function Cam:returnToPlayer(tween, tweenDuration)
	if self.prevCamCFrame then
		camera.CFrame = self.prevCamCFrame
		self.prevCamCFrame = nil
	end
	camera.CameraType = Enum.CameraType.Custom
	self.currentType = "Default"
	camTypeChanged:Fire("Default")
end

return Cam