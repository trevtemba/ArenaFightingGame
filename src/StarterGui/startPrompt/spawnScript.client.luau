local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)

local toggleCamera = Services.ClientEvents:WaitForChild("toggleCamera")
local champChosenByServer = Services.ClientEvents:WaitForChild("champChosenByServer")
local blur = Services.Lighting:WaitForChild("Blur")

local champSelect = require(Services.ClientEffectsUI.champSelect)
local camModule = require(Services.Client:WaitForChild("cameraModule"))

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
