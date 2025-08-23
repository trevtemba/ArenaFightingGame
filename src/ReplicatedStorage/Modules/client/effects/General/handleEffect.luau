local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Debris = Services.DebrisService

local animHelper = require(Services.ClientEffectsUtils.animHelper)
local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local Effects = Services.Effects

return function(argumentData)
	local target: Model = argumentData.target
	local effectType: string = argumentData.effectType
	local activate: boolean = argumentData.activate
	local ignoreAnim: boolean = argumentData.ignoreAnim

	if target and effectType then
		if effectType == "blockBreak" then
			local head = target:FindFirstChild("Head")
			if head then
				if activate then
					local dizzyEffectClone = Effects.DizzyEffect:FindFirstChild("confused"):Clone()
					dizzyEffectClone.Parent = head
					particleHelper.EnablePart(dizzyEffectClone)
					if not ignoreAnim then
						animHelper:StopAll(target)
						animHelper:PlayAnimation(target, "blockBreak", 0.1, nil, nil, true, "Action4")
					end
				else
					local dizzyEffect = head:FindFirstChild("confused")
					if dizzyEffect then
						particleHelper.DisablePart(dizzyEffect)
						animHelper:StopAnimation(target, "blockBreak", 0)
						Debris:AddItem(dizzyEffect, 1)
					end
				end
				local clone = nil

				Debris:AddItem(clone, 1)
			end
		elseif effectType == "block" then
			if activate then
				animHelper:PlayAnimation(target, "block", 0.1, nil, nil, true, "Action4")
			else
				animHelper:StopAnimation(target, "block", 0.1)
			end
		end
	end
end
