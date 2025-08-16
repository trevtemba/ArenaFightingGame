local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local particleHelper = require(script.Parent.particleHelper)
local pulseVisibility = require(script.Parent["pulseVisibility."])
local Effects = ReplicatedStorage:WaitForChild("Effects")

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
