local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)

local highlightHelper = {}

function highlightHelper:highlightCharacter(
	target: Model,
	color: Color3,
	intensityFill: number,
	intensityOutline: number,
	alwaysOnTop: boolean,
	type: string,
	duration: number
)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.DepthMode = alwaysOnTop and "AlwaysOnTop" or "Occluded"
	highlight.Parent = target

	if type == "pulse" then
		tweenHelper:Tween(highlight, {
			time = duration,
			easingStyle = Enum.EasingStyle.Back,
			easingDirection = Enum.EasingDirection.Out,
		}, {
			FillTransparency = intensityFill,
			OutlineTransparency = intensityOutline,
		}, function()
			tweenHelper:Tween(highlight, {
				time = duration,
				easingStyle = Enum.EasingStyle.Quad,
				easingDirection = Enum.EasingDirection.In,
			}, {
				FillTransparency = 1,
				OutlineTransparency = 1,
			}, function()
				highlight:Destroy()
			end)
		end)
	end

	return highlight
end

return highlightHelper
