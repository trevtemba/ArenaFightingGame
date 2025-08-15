local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cameraModule = require(ReplicatedStorage.Modules.client.cameraModule)
local tweenHelper = require(script.Parent.tweenHelper)
local FlashLighting = game:GetService("Lighting"):FindFirstChild("Flash")

return function(argumentData)
	local knockBack: boolean = argumentData.knockBack
	local victim: boolean = argumentData.victim

	if knockBack then
		if victim then
			cameraModule.Shake({ shake = "Mid_Bump2" })
			cameraModule.Flash({ request = "white", tim = 0.08 })
			cameraModule.Blur({ wait_till_normalFov = 0.1, size = 15, tim1 = 0.1, tim2 = 0.15 })
		else
			cameraModule.Shake({ shake = "Mid_Bump" })
			cameraModule.Flash({ request = "white", tim = 0.08 })
			cameraModule.Blur({ wait_till_normalFov = 0.1, size = 15, tim1 = 0.1, tim2 = 0.15 })
		end
	else
		cameraModule.Shake({ shake = "Light_Bump" })
		cameraModule.Blur({ wait_till_normalFov = 0.1, size = 15, tim1 = 0.1, tim2 = 0.15 })
	end
end
