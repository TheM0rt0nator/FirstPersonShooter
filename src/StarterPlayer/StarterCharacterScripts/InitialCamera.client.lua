local StarterGui = game:GetService("StarterGui")

-- When a player gets a new character, set their camera to the kit selection cam
local Camera = workspace.CurrentCamera

-- Disable built in leaderboard
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

--[[Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = CFrame.new(0, 0, 0)]]