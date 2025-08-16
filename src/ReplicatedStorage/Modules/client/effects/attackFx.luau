local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ParticleEmitter = require(ReplicatedStorage.Modules.client.guiParticle.ParticleEmitter)
local animHelper = require(script.Parent.animHelper)
local highlightHelper = require(script.Parent.highlightHelper)
local particleHelper = require(script.Parent.particleHelper)
local soundHelper = require(script.Parent.soundHelper)
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local target: Model = argumentData.target
	local weapon: string = argumentData.weapon
	local combo: number = argumentData.combo

	if target and weapon then
		rootpart = target:FindFirstChild("HumanoidRootPart")
		if combo and rootpart then
			if combo == 5 then
				local highlightColor = Color3.fromRGB(255, 255, 255)
				local innerTransparency = 0.8
				local outerTransparency = 0.1
				local highlight = highlightHelper:highlightCharacter(
					target,
					highlightColor,
					innerTransparency,
					outerTransparency,
					false,
					"pulse",
					0.25
				)
				local chargeSound = soundHelper.PlaySound("bbCharge", target.PrimaryPart, 0.05)
				local bbFlashClone = Effects.CoreEffects.bbFlash:Clone()
				local bbOverHeadClone = Effects.CoreEffects.bbOverheadFlash:Clone()
				if weapon == "fist" then
					bbFlashClone.Parent = target:FindFirstChild("Right Leg")
				end
				bbOverHeadClone.Parent = target:FindFirstChild("Head")
				bbOverHeadClone.CFrame = bbOverHeadClone.CFrame * CFrame.new(0, 1, 0)
				particleHelper.EmitPart(bbFlashClone)
				particleHelper.EmitPart(bbOverHeadClone)
				task.delay(0.35, function()
					local swingSound = soundHelper.PlaySound((weapon .. "Swing"), target.PrimaryPart, 0.05)
					Debris:AddItem(swingSound, 1)
				end)
				Debris:AddItem(bbFlashClone, 1)
				Debris:AddItem(bbOverHeadClone, 1)
				Debris:AddItem(highlight, 1)
				Debris:AddItem(chargeSound, 1)
			else
				task.delay(0.15, function()
					local swingSound = soundHelper.PlaySound((weapon .. "Swing"), target.PrimaryPart, 0.05)
					Debris:AddItem(swingSound, 1)
				end)
			end
		end
	end
end
