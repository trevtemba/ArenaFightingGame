local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local CollectionService = Services.CollectionService
local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)

return function(target, duration)
	local highlight = target.Highlight
	if highlight then
		highlight.Enabled = false
	end
	for _, child in pairs(target:GetDescendants()) do
		if child:IsA("BasePart") and not CollectionService:HasTag(child, "ignore") then
			tweenHelper:Tween(child, {
				time = 0.2,
				easingStyle = Enum.EasingStyle.Quad,
				easingDirection = Enum.EasingDirection.Out,
			}, {
				Transparency = 1,
			}, function()
				task.delay(duration, function()
					tweenHelper:Tween(child, {
						time = 0.2,
						easingStyle = Enum.EasingStyle.Quad,
						easingDirection = Enum.EasingDirection.Out,
					}, {
						Transparency = 0,
					}, function()
						highlight.Enabled = true
					end)
				end)
			end)
		end
	end
end
