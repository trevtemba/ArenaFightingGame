local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local Debris = Services.DebrisService

local animHelper = require(Services.ClientEffectsUtils.animHelper)
local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)
local Effects = Services.Effects

return function(argumentData)
	local target: Model = argumentData.target
	local position: Vector3 = argumentData.position

	if target and position then
		animHelper:StopAll(target)
		animHelper:PlayAnimation(target, "grounded", 0, nil, nil, true, "Action4")
		task.delay(1, function()
			animHelper:StopAll(target)
			animHelper:PlayAnimation(target, "getUp", 0.2, nil, nil, false, "Action2")
		end)
		local groundClone = Effects:FindFirstChild("Ground"):Clone()
		groundClone.Position = position
		groundClone.Parent = game.Workspace:FindFirstChild("Assets")
		particleHelper.EmitPart(groundClone)
		local slamSound = soundHelper.PlaySound("groundSlam", target.PrimaryPart, 0.05)
		Debris:AddItem(groundClone, 4)
		Debris:AddItem(slamSound, 4)
	end
end
