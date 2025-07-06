local ReplicatedStorage = game:WaitForChild("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Player = game:GetService("Players").LocalPlayer
local playerGui = Player:WaitForChild("PlayerGui")
local tweenServ = game:GetService("TweenService")

local tweenInfoBtns1 = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local tweenInfoBtns2 = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ChampSelect")

local blur = game.Lighting:WaitForChild("Blur")

local selectBtn = script.Parent
local startPrompt = playerGui:WaitForChild("startPrompt")

local camModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("frontend"):WaitForChild("cameraModule"))
local uiModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("frontend"):WaitForChild("guiModule"))

local CHAMP_NAME = "Dante"

selectBtn.MouseButton1Click:Connect(function()
	local parentFrame = selectBtn.Parent.Parent
	local parentScript = parentFrame:FindFirstChild("hoverScript")
	--Fires morpth event
	uiModule.selectSound()
	remote:FireServer(CHAMP_NAME)
	--Tween
	parentFrame:TweenPosition(UDim2.new(0.5, 0, 2, 0), "In", "Back", 1, false)
	parentFrame.Parent:FindFirstChild("message"):TweenPosition(UDim2.new(0.5, 0, -3, 0), "In", "Quad", 1, false)
	tweenServ:Create(parentFrame.Parent:FindFirstChild("message"):FindFirstChild("drop"), tweenInfoBtns2, {TextTransparency = 1}):Play()
	
	--Disables GUI and blur
	task.delay(0.25, function()

		tweenServ:Create(blur, tweenInfoBtns1, {Size = 0.1}):Play()

	end)
	task.delay(1, function()

		--startPrompt.Enabled = false

	end)
	--uiModule.playSplash()
	--Camera adjustment
	camModule.normCam()
	

	
end)

