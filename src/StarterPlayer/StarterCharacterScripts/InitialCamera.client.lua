local StarterGui = game:GetService("StarterGui")

-- When a player gets a new character, set their camera to the kit selection cam
local camera = workspace.CurrentCamera

local isFistJoin = true

if isFistJoin then
	isFistJoin = false
	-- Disable built in leaderboard
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new((workspace.HomeScreen.PrimaryPart.CFrame + Vector3.new(0, 5, 0)).Position, workspace.HomeScreen.PrimaryPart.CFrame.Position) * CFrame.Angles(0, 0, math.pi / 2)
end