local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

return function(self, subjectPart)
	camera.CameraType = Enum.CameraType.Scriptable
	local totalTime = 0
	local goalOffset = 30
	local startHeight = camera.CFrame.Position.Y
	local goalHeight = startHeight + 20
	local renderConnection
	renderConnection = RunService.RenderStepped:Connect(function(dt)
		if self.currentType ~= "DeathCam" or not subjectPart or not subjectPart:IsDescendantOf(workspace) then
			renderConnection:Disconnect()
			renderConnection = nil
			return
		end

		local currentOffset = (subjectPart.Position - camera.CFrame.Position).Magnitude
		local newCamPos = camera.CFrame 
		if currentOffset > goalOffset then
			-- If we are not at our goal offset, zoom the camera towards the subject
			newCamPos += (subjectPart.Position - camera.CFrame.Position).Unit / 5
		end
		if newCamPos.Position.Y < goalHeight then
			newCamPos += Vector3.new(0, 0.1, 0)
		end
		
		camera.CFrame = CFrame.new(newCamPos.Position, subjectPart.Position)
		totalTime += dt
	end)
end