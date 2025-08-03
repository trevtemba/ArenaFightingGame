local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local coinTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("coinTemplate")
local coinModel = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Coin")

local viewportHandler = {}

function viewportHandler.InitCoin()
	local playerGui = player:WaitForChild("PlayerGui")

	-- Clone and parent to live UI
	local coinCloneUI = coinTemplate:Clone()
	coinCloneUI.Visible = true
	coinCloneUI.Parent = playerGui:WaitForChild("HUD") -- Or wherever your HUD lives

	-- Now it's live on screen. Set up the viewport
	local viewport = coinCloneUI:WaitForChild("viewport")

	-- Create and assign camera
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(Vector3.new(0, 0, 3), Vector3.new(0, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Clone 3D coin model into the viewport -1.609, 4.867, -7.626
	local coin3D = coinModel:Clone()
	coin3D.Parent = viewport

	-- Make sure it's centered
	if not coin3D.PrimaryPart then
		coin3D.PrimaryPart = coin3D:FindFirstChildWhichIsA("BasePart")
	end
	coin3D:SetPrimaryPartCFrame(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)))
end

return viewportHandler
