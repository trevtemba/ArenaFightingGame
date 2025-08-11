local ReplicatedStorage = game:GetService("ReplicatedStorage")
local toggleCamera = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("toggleCamera")
local champChosenByServer =
	ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("champChosenByServer")
local blur = game.Lighting:WaitForChild("Blur")

local champSelect = require(ReplicatedStorage.Modules.client.effects.UI.champSelect)
local camModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("cameraModule"))

--add blur
blur.Enabled = true
--enables menu camera
camModule.menuCam()

toggleCamera.OnClientEvent:Connect(function(cameraType)
	if cameraType == "normal" then
		camModule.normCam()
	end
end)

champChosenByServer.OnClientEvent:Connect(function(selectedChamp)
	champSelect.Select({ selectedChamp = selectedChamp })
end)
