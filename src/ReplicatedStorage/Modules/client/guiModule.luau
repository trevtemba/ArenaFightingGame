local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local tweenService = Services.TweenService
local Player = Services.Players.LocalPlayer
local playerGui = Player:WaitForChild("PlayerGui")
local splash = playerGui:WaitForChild("splash")
--tweeninfo
local tweenInfoBtns1 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
--Screens
local startPrompt = playerGui:WaitForChild("startPrompt")
local splashScreen = splash:WaitForChild("splashScreen")
--Frames
--FX
local uiSFX = ReplicatedStorage:WaitForChild("UISFX")

function module:hoverSound()
	uiSFX:WaitForChild("hover"):Play()
end

function module:selectSound()
	uiSFX:WaitForChild("select"):Play()
end

function module.playSplash()
	tweenService:Create(splashScreen, tweenInfoBtns1, { BackgroundTransparency = 0 }):Play()

	--[[
	task.delay(1, function()
		print("removing")
		tweenService:Create(splashScreen, tweenInfoBtns1, {BackgroundTransparency = 1}):Play()
		
	end)
	]]
end

return module
