local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Debris = Services.DebrisService

local animHelper = require(Services.ClientEffectsUtils.animHelper)
local highlightHelper = require(Services.ClientEffectsUtils.highlightHelper)
local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)

local Sounds = Services.Sounds
local Effects = Services.Effects

return function(argumentData)
	local target: Model = argumentData.target
	local hitType: string = argumentData.hitType
	local attackAction: string = argumentData.attackAction
	local knockBack: boolean = argumentData.knockBack
	local attackerLookVector: Vector3 = argumentData.attackerLookVector
	local combo: number = argumentData.combo
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
				if attackAction then
					if attackAction == "downslam" then
						local dustParticleAtt = Effects:FindFirstChild("DustTrail"):FindFirstChild("Attachment"):Clone()
						local knockBackSound = soundHelper.PlaySound("knockback1", rootPart, nil)
						windClone.Parent = rootPart
						animHelper:StopAll(target)
						animHelper:PlayAnimation(target, "falling", 0.1, nil, nil, true, "Action3")
						local shockWaveClone = Effects:FindFirstChild("CleanShockwave"):Clone()
						local lookAtCFrame =
							CFrame.lookAt(rootPart.Position, rootPart.Position + attackerLookVector.Unit)
						shockWaveClone.CFrame = lookAtCFrame * CFrame.Angles(math.rad(-135), 0, 0)
						shockWaveClone.Parent = game.Workspace
						particleHelper.EmitPart(shockWaveClone)
						particleHelper.EmitPart(windClone)
						dustParticleAtt.Parent = rootPart
						particleHelper.EnablePart(dustParticleAtt)

						task.delay(1, function()
							particleHelper.DisablePart(dustParticleAtt)
							Debris:AddItem(dustParticleAtt, 1)
						end)

						Debris:AddItem(shockWaveClone, 1)
						Debris:AddItem(knockBackSound, 1)
						Debris:AddItem(windClone, 1)
					elseif attackAction == "knockup" then
						local risingLinesClone =
							Effects:FindFirstChild("RiseLines"):FindFirstChild("ParticleEmitter"):Clone()
						local knockBackSound = soundHelper.PlaySound("knockback1", rootPart, nil)
						windClone.Parent = rootPart
						animHelper:StopAll(target)
						animHelper:PlayAnimation(target, "knockedUp", 0.2, nil, nil, true, "Action")
						local shockWaveClone = Effects:FindFirstChild("CleanShockwave"):Clone()
						local lookAtCFrame =
							CFrame.lookAt(rootPart.Position, rootPart.Position + attackerLookVector.Unit)
						shockWaveClone.CFrame = lookAtCFrame * CFrame.Angles(math.rad(-45), 0, 0)
						shockWaveClone.Parent = game.Workspace
						particleHelper.EmitPart(shockWaveClone)
						particleHelper.EmitPart(windClone)
						risingLinesClone.Parent = rootPart

						particleHelper.EnablePart(risingLinesClone)

						task.delay(1, function()
							animHelper:StopAnimation(target, "knockedUp", 0.1)
							particleHelper.DisablePart(risingLinesClone)
							Debris:AddItem(risingLinesClone, 1)
						end)

						Debris:AddItem(shockWaveClone, 1)
						Debris:AddItem(knockBackSound, 1)
						Debris:AddItem(windClone, 1)
					elseif attackAction == "continue" then
						local track1 = "impactleft"
						local track2 = "impactright"

						-- Randomly choose one of the impact animations
						local chosenTrack = math.random(1, 2) == 1 and track1 or track2
						animHelper:StopAll(target)
						animHelper:PlayAnimation(target, chosenTrack, 0.1, nil, nil, false, "Action3")
					elseif
						knockBack
						and (
							attackAction == "knockback"
							or attackAction == "cast"
							or attackAction == "attackHeavyGround"
						)
					then
						local dustParticleAtt = Effects:FindFirstChild("DustTrail"):FindFirstChild("Attachment"):Clone()
						local knockBackSound = soundHelper.PlaySound("knockback1", rootPart, nil)
						windClone.Parent = rootPart
						local knockBackAnim =
							animHelper:PlayAnimation(target, "knockBack", 0.1, nil, nil, false, "Action4")

						local shockWaveClone = Effects:FindFirstChild("CleanShockwave"):Clone()
						local lookAtCFrame =
							CFrame.lookAt(rootPart.Position, rootPart.Position + attackerLookVector.Unit)
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
							animHelper:PlayAnimation(target, "getUp", 0.1, nil, nil, false, "Action2")
						end)
						Debris:AddItem(shockWaveClone, 1)
						Debris:AddItem(knockBackSound, 1)
						Debris:AddItem(windClone, 1)
					elseif attackAction == "default" or attackAction == "aircontinue" then
						if hitType ~= "blockBreak" then
							local track1 = "impactleft"
							local track2 = "impactright"

							-- Randomly choose one of the impact animations
							local chosenTrack = math.random(1, 2) == 1 and track1 or track2
							-- animHelper:StopAll(target)
							animHelper:PlayAnimation(target, chosenTrack, 0.1, nil, nil, false, "Action3")
						end
					end
				end
			else
				local track1 = "blockImpactRight"
				local track2 = "blockImpactLeft"

				-- Randomly choose one of the impact animations
				local chosenTrack = argumentData.blockAnimSequence == 1 and track1 or track2
				animHelper:PlayAnimation(target, chosenTrack, 0.1, nil, nil, false, "Action3")
			end
			if hitType == "blunt" then
				if combo then
					if combo <= 2 then
						clone = Effects.CoreEffects.bluntHitEffect:Clone()
					elseif combo <= 5 then
						clone = Effects.CoreEffects.bluntHitEffect2:Clone()
					end
				else
					clone = Effects.CoreEffects.bluntHitEffect:Clone()
				end
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

			-- Cleanup
			Debris:AddItem(highlight, 1)
			Debris:AddItem(clone, 1)
			Debris:AddItem(sound, 1)
		end
	end
end
