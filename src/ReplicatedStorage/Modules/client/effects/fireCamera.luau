local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cameraModule = require(ReplicatedStorage.Modules.client.cameraModule)
local tweenHelper = require(script.Parent.tweenHelper)
local FlashLighting = game:GetService("Lighting"):FindFirstChild("Flash")

return function(argumentData)
	local flashType: string = argumentData.flashType
	local victim: boolean = argumentData.victim
	if flashType then
		if flashType == "knockBack" then
			if victim then
				cameraModule.Shake({ shake = "Mid_Bump2" })
				cameraModule.Flash({ request = "white", tim = 0.08 })
				cameraModule.Blur({ wait_till_normalFov = 0.1, size = 15, tim1 = 0.1, tim2 = 0.15 })
			else
				cameraModule.Shake({ shake = "Mid_Bump" })
				cameraModule.Flash({ request = "white", tim = 0.08 })
				cameraModule.Blur({ wait_till_normalFov = 0.1, size = 15, tim1 = 0.1, tim2 = 0.15 })
			end
			-- tweenHelper:Tween(FlashLighting, {
			-- 	time = 0.01,
			-- 	easingDirection = Enum.EasingDirection.Out,
			-- 	easingStyle = Enum.EasingStyle.Sine,
			-- }, { Brightness = 1 }, function()
			-- 	tweenHelper:Tween(FlashLighting, {
			-- 		time = 0.3,
			-- 		easingDirection = Enum.EasingDirection.Out,
			-- 		easingStyle = Enum.EasingStyle.Quart,
			-- 	}, { Brightness = 0 })
			-- end)
		end
	end
end
