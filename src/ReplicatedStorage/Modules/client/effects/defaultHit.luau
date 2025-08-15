local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local animHelper = require(script.Parent.animHelper)
local highlightHelper = require(script.Parent.highlightHelper)
local particleHelper = require(script.Parent.particleHelper)
local soundHelper = require(script.Parent.soundHelper)

local Sounds = ReplicatedStorage:FindFirstChild("Sounds")
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local target: Model = argumentData.target
	local hitType: string = argumentData.hitType
	local knockBack: boolean = argumentData.knockBack
	local attackerLookVector: Vector3 = argumentData.attackerLookVector
	if target and hitType then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local clone = nil
			local sound = nil
			local highlightColor = Color3.fromRGB(255, 0, 0)
			local innerTransparency = 0.85
			local outerTransparency = 1
			local windClone = Effects:FindFirstChild("Wind"):FindFirstChild("wind"):Clone()

			if hitType ~= "block" then
				if knockBack then
					local dustParticleAtt = Effects:FindFirstChild("DustTrail"):FindFirstChild("Attachment"):Clone()
					local knockBackSound = soundHelper.PlaySound("knockback1", rootPart, nil)
					windClone.Parent = rootPart
					animHelper:StopAll(target)
					local knockBackAnim = animHelper:PlayAnimation(target, "knockBack", 0.2, nil, nil, false, "Action4")

					local shockWaveClone = Effects:FindFirstChild("CleanShockwave"):Clone()
					local lookAtCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + attackerLookVector.Unit)
					shockWaveClone.CFrame = lookAtCFrame * CFrame.Angles(math.rad(-90), 0, 0)
					shockWaveClone.Parent = game.Workspace
					particleHelper.EmitPart(shockWaveClone)
					particleHelper.EmitPart(windClone)
					dustParticleAtt.Parent = rootPart
					particleHelper.EnablePart(dustParticleAtt)

					task.delay(1, function()
						particleHelper.DisablePart(dustParticleAtt)
						Debris:AddItem(dustParticleAtt, 1)
					end)
					animHelper:ConnectStopped(knockBackAnim, function()
						animHelper:PlayAnimation(target, "getUp", 0.2, nil, nil, false, "Action4")
					end)
					Debris:AddItem(shockWaveClone, 1)
					Debris:AddItem(knockBackSound, 1)
					Debris:AddItem(windClone, 1)
				else
					local track1 = "impactleft"
					local track2 = "impactright"

					-- Randomly choose one of the impact animations
					local chosenTrack = math.random(1, 2) == 1 and track1 or track2
					animHelper:StopAll(target)
					animHelper:PlayAnimation(target, chosenTrack, 0.2, nil, nil, false, "Action4")
				end
			end
			if hitType == "blunt" then
				clone = Effects.CoreEffects.bluntHitEffect:Clone()
				sound = Sounds:FindFirstChild("impact"):Clone()
				outerTransparency = 0.1
			elseif hitType == "slash" then
				clone = Effects.CoreEffects.slashHitEffect:Clone()
				sound = Sounds:FindFirstChild("impact"):Clone()
				outerTransparency = 0.1
			elseif hitType == "block" then
				clone = Effects.CoreEffects.blockHitEffect:Clone()
				local num = math.random(1, 3)
				sound = Sounds:FindFirstChild("block" .. num):Clone()
				highlightColor = Color3.fromRGB(255, 204, 19)
				outerTransparency = 0.1
			elseif hitType == "blockBreak" then
				clone = Effects.CoreEffects.blockBreakHitEffect:Clone()
				sound = Sounds:FindFirstChild("blockBreak"):Clone()
				outerTransparency = 0.1
			else
				warn("hitType not valid")
				return
			end
			clone.Parent = rootPart
			sound.Parent = target
			sound:Play()
			particleHelper.EmitPart(clone)
			local highlight = highlightHelper:highlightCharacter(
				target,
				highlightColor,
				innerTransparency,
				outerTransparency,
				false,
				"pulse",
				0.25
			)
			-- if knockBack then
			-- 	local knockBackSound = Sounds.knockback1:Clone()
			-- 	local knockBackClone = Effects.KnockbackEffect:Clone()
			-- 	local lookAtCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + attackerLookVector.Unit)
			-- 	knockBackClone.CFrame = lookAtCFrame * CFrame.Angles(math.rad(-90), 0, 0)
			-- 	knockBackClone.Parent = game.Workspace
			-- 	particleHelper.EmitPart(knockBackClone)
			-- 	knockBackSound.Parent = rootPart
			-- 	knockBackSound:Play()

			-- 	Debris:AddItem(knockBackClone, 1)
			-- 	Debris:AddItem(knockBackSound, 1)
			-- end
			-- Cleanup

			Debris:AddItem(clone, 1)
			Debris:AddItem(sound, 1)
			Debris:AddItem(highlight, 1)
		end
	end
end
