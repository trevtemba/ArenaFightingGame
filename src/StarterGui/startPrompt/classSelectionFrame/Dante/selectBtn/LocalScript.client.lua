local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local champSelect = require(Services.ClientEffectsUI.champSelect)

local remote = Services.ServerEvents:WaitForChild("ChampSelect")
local hoverScript = script.Parent.Parent.Parent:FindFirstChild("hoverScript")
local selectBtn = script.Parent

local CHAMP_NAME = "Dante"

selectBtn.MouseButton1Click:Connect(function()
	hoverScript.Enabled = false
	--Fires morpth event
	remote:FireServer(CHAMP_NAME)
	champSelect.Select({ selectedChamp = CHAMP_NAME })
end)
