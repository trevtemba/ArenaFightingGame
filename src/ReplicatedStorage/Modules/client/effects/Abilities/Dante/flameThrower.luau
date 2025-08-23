local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Debris = Services.DebrisService

local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)
local WeldHelper = require(Services.SharedUtils.WeldHelper)
local Assets = Services.Assets

return function(argumentData)
	local target: Model = argumentData.target
	local duration: number = argumentData.duration

	if target then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local flameThrowerClone = Assets:WaitForChild("flameThrower"):Clone()
			flameThrowerClone.CFrame = rootPart.CFrame * CFrame.new(1.25, 0.75, -3.5)
			local weld = WeldHelper.WeldParts(rootPart, flameThrowerClone)
			flameThrowerClone.Parent = game.Workspace:WaitForChild("Assets")

			soundHelper.PlaySound("flamethrower", flameThrowerClone, nil)
			particleHelper.EnablePart(flameThrowerClone)

			task.delay(duration, function()
				particleHelper.DisablePart(flameThrowerClone)
				Debris:AddItem(flameThrowerClone, 1)
				Debris:AddItem(weld, duration + 1)
			end)
		end
	end
end
