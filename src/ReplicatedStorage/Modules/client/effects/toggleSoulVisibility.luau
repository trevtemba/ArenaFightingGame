local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local CollectionService = Services.CollectionService
local Debris = Services.DebrisService

local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)
local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)

local SoulEffects = Services.Effects:WaitForChild("SoulEffects")

return function(argumentData)
	local target: Model = argumentData.target
	local visible: string = argumentData.visible
	local particleSkin: string = argumentData.particleSkin

	if target and particleSkin then
		local targetTransparency = visible and 0.25 or 1
		local soundName = visible and "soulPoofIn" or "soulPoofOut"
		local sound = soundHelper.PlaySound(soundName, target.PrimaryPart, 0.025)
		local particleAtt = SoulEffects:FindFirstChild(particleSkin):Clone()
		particleAtt.Parent = target.PrimaryPart

		particleHelper.EmitPart(particleAtt)
		for _, child in pairs(target:GetDescendants()) do
			if child:IsA("BasePart") and not CollectionService:HasTag(child, "ignore") then
				tweenHelper:Tween(child, {
					time = 0.25,
					easingStyle = Enum.EasingStyle.Quad,
					easingDirection = Enum.EasingDirection.Out,
				}, {
					Transparency = targetTransparency,
				})
			end
		end
		Debris:AddItem(particleAtt, 1)
		Debris:AddItem(sound, 1)
	end
end
