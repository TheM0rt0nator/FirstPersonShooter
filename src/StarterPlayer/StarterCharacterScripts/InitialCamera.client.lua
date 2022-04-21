local StarterGui = game:GetService("StarterGui")

-- When a player gets a new character, set their camera to the kit selection cam
local camera = workspace.CurrentCamera

-- Disable built in leaderboard
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(0, 0, 0)