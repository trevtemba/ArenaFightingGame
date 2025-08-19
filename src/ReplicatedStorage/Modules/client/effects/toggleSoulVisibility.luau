local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local particleHelper = require(script.Parent.particleHelper)
local soundHelper = require(script.Parent.soundHelper)
local tweenHelper = require(script.Parent.tweenHelper)
local Effects = ReplicatedStorage:WaitForChild("Effects")
local SoulEffects = Effects:WaitForChild("SoulEffects")

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
