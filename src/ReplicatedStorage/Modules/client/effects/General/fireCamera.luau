local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local cameraModule = require(Services.Client:FindFirstChild("cameraModule"))

local function isStrong(attackAction)
	if
		attackAction == "knockback"
		or attackAction == "downslam"
		or attackAction == "knockup"
		or attackAction == "airknockback"
	then
		return true
	else
		return false
	end
end

return function(argumentData)
	local attackAction: boolean = argumentData.attackAction
	local victim: boolean = argumentData.victim

	if isStrong(attackAction) then
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
