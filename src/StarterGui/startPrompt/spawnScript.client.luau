--Grabs variables
local plr = game:GetService("Players").LocalPlayer
local character = plr.Character or plr.CharacterAdded:wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleCamera = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("toggleCamera")
local blur = game.Lighting:WaitForChild("Blur")

local camModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("cameraModule"))

--add blur
blur.Enabled = true
--enables menu camera
camModule.menuCam()

toggleCamera.OnClientEvent:Connect(function(cameraType)
	if cameraType == "normal" then
		-- camModule.normCam()
	end
end)
