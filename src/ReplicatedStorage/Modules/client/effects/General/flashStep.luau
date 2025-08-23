local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Debris = Services.DebrisService

local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local pulseVisibility = require(Services.ClientEffectsUtils.pulseVisibility)
local Effects = Services.Effects

return function(argumentData)
	local target: Model = argumentData.target
	local duration: number = argumentData.duration

	if target then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			pulseVisibility(target, duration)
			local flashStepClone = Effects.FlashStep:Clone()
			local lines = flashStepClone.particle
			local att = flashStepClone.flashStep
			lines.Parent = rootPart
			att.Parent = rootPart

			particleHelper.EnablePart(rootPart)

			task.delay(duration, function()
				particleHelper.DisablePart(rootPart)
				Debris:AddItem(flashStepClone, 1)
			end)
		end
	end
end
