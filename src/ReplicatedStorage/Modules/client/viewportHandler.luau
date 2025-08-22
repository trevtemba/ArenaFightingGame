local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local Players = Services.Players
local player = Players.LocalPlayer
local coinTemplate = Services.UI:WaitForChild("coinTemplate")
local coinModel = Services.Assets:WaitForChild("Coin")

local viewportHandler = {}

function viewportHandler.InitCoin()
	local playerGui = player:WaitForChild("PlayerGui")

	-- Clone and parent to live UI
	local coinCloneUI = coinTemplate:Clone()
	coinCloneUI.Visible = true
	coinCloneUI.Parent = playerGui:WaitForChild("HUD")

	local viewport = coinCloneUI:WaitForChild("viewport")

	-- Create and assign camera
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(0, 0, 5)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local coin3D = coinModel:Clone()
	coin3D.Parent = viewport

	if not coin3D.PrimaryPart then
		coin3D.PrimaryPart = coin3D:FindFirstChildWhichIsA("BasePart")
	end
	coin3D:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0))
end

return viewportHandler
