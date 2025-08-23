local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Player = Services.Players.LocalPlayer

local cameraModule = require(Services.Client.cameraModule)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)
local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)
local blur = Services.Lighting:WaitForChild("Blur")

local champSelect = {}

local function getUI()
	local gui = Player:WaitForChild("PlayerGui")
	local startGui = gui:WaitForChild("startPrompt")
	local classSelectionFrame = startGui:WaitForChild("classSelectionFrame")
	return classSelectionFrame, startGui
end

function champSelect.Select(argumentData)
	local selectedChamp: number = argumentData.selectedChamp

	if selectedChamp then
		local classSelectionFrame, startGui = getUI()
		local selectedFrame = classSelectionFrame:WaitForChild(selectedChamp)
		local message = startGui:FindFirstChild("message")
		soundHelper.PlaySound("uiSelect", selectedFrame, nil)

		tweenHelper:Tween(
			selectedFrame,
			{ time = 1, easingStyle = Enum.EasingStyle.Back, easingDirection = Enum.EasingDirection.In },
			{
				Position = UDim2.fromScale(0.5, 2),
			}
		)
		tweenHelper:Tween(
			message,
			{ time = 1, easingStyle = Enum.EasingStyle.Quad, easingDirection = Enum.EasingDirection.In },
			{
				Position = UDim2.fromScale(0.5, -3),
			}
		)
		tweenHelper:Tween(
			message,
			{ time = 0.7, easingStyle = Enum.EasingStyle.Quad, easingDirection = Enum.EasingDirection.InOut },
			{
				TextTransparency = 1,
			}
		)
		--Disables GUI and blur
		task.delay(0.25, function()
			tweenHelper:Tween(
				blur,
				{ time = 1, easingStyle = Enum.EasingStyle.Quad, easingDirection = Enum.EasingDirection.InOut },
				{
					Size = 0,
				}
			)
		end)
		task.delay(1, function()
			cameraModule.normCam()
			startGui.Enabled = false
		end)
	end
end

return champSelect
