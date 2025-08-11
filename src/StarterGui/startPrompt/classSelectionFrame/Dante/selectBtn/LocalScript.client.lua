local ReplicatedStorage = game:GetService("ReplicatedStorage")
local champSelect = require(ReplicatedStorage.Modules.client.effects.UI.champSelect)

local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Server"):WaitForChild("ChampSelect")
local hoverScript = script.Parent.Parent.Parent:FindFirstChild("hoverScript")
local selectBtn = script.Parent

local CHAMP_NAME = "Dante"

selectBtn.MouseButton1Click:Connect(function()
	hoverScript.Enabled = false
	--Fires morpth event
	remote:FireServer(CHAMP_NAME)
	champSelect.Select({ selectedChamp = CHAMP_NAME })
end)
