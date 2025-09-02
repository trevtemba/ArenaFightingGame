local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local animHelper = require(ReplicatedStorage.Modules.Client.effects.Utils.animHelper)
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Debris = Services.DebrisService

local highlightHelper = require(Services.ClientEffectsUtils.highlightHelper)
local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)
local Effects = Services.Effects

local champHighlightMap = {
	["Dante"] = {
		["Base"] = Color3.fromRGB(255, 208, 0),
		["Outer"] = Color3.fromRGB(255, 255, 255),
	},
	["N/A"] = {
		["Base"] = Color3.fromRGB(255, 255, 255),
		["Outer"] = Color3.fromRGB(255, 255, 255),
	},
}
return function(argumentData)
	local target: Model = argumentData.target
	local weapon: string = argumentData.weapon
	local fxType: string = argumentData.fxType
	local combo: number = argumentData.combo
	local champName: string = argumentData.champName

	if target and fxType and weapon and champName then
		local rootpart = target:FindFirstChild("HumanoidRootPart")
		if fxType == "attackHeavyGround" then
			if rootpart then
				local highlightColor = champHighlightMap[champName].Base
				local outerHighlightColor = champHighlightMap[champName].Outer
				local innerTransparency = 0.85
				local outerTransparency = 0.1
				local highlight = highlightHelper:highlightCharacter(
					target,
					highlightColor,
					innerTransparency,
					outerTransparency,
					false,
					"pulse",
					0.25,
					outerHighlightColor
				)
				local chargeSound = soundHelper.PlaySound("bbCharge", target.PrimaryPart, 0.05)
				local bbFlashClone = Effects.CoreEffects.bbFlash:Clone()
				local bbOverHeadClone = Effects.CoreEffects.bbOverheadFlash:Clone()
				if weapon == "gun" then
					bbFlashClone.Parent = target:FindFirstChild("Left Arm")
					local gunChargeSound = soundHelper.PlaySound("gunCharge", target.PrimaryPart, 0.05)
					Debris:AddItem(gunChargeSound, 1)
					task.delay(0.5, function()
						local gunBlastSound = soundHelper.PlaySound("gunBlast", target.PrimaryPart, 0.05)
						local gunVFX = Effects:FindFirstChild("MuzzleFlash"):Clone()
						gunVFX.CFrame = rootpart.CFrame * CFrame.new(-0.25, 1.25, -4)
						gunVFX.Parent = Services.Workspace:FindFirstChild("Assets")
						particleHelper.EmitPart(gunVFX)
						Debris:AddItem(gunBlastSound, 1)
						Debris:AddItem(gunVFX, 1)
					end)
				end
				bbOverHeadClone.Parent = rootpart
				bbOverHeadClone.CFrame = bbOverHeadClone.CFrame * CFrame.new(0, 3, 0)
				bbFlashClone:FindFirstChildOfClass("ParticleEmitter").Color =
					ColorSequence.new(champHighlightMap[champName].Base)
				particleHelper.EmitPart(bbFlashClone)
				-- particleHelper.EmitPart(bbOverHeadClone)

				Debris:AddItem(bbFlashClone, 1)
				Debris:AddItem(bbOverHeadClone, 1)
				Debris:AddItem(highlight, 1)
				Debris:AddItem(chargeSound, 1)
			end
		elseif fxType == "attackHeavyAir" then
			if rootpart then
				local initAnimTrack = animHelper:PlayAnimation(target, "attackHeavyAirInit", 0, 3, 1, false, "Action3")
				animHelper:ConnectStopped(initAnimTrack, function()
					animHelper:PlayAnimation(target, "attackHeavyAirDive", 0.2, 3, 1, false, "Action3")
				end)
				local highlightColor = champHighlightMap[champName].Base
				local outerHighlightColor = champHighlightMap[champName].Outer
				local innerTransparency = 0.85
				local outerTransparency = 0.1
				local highlight = highlightHelper:highlightCharacter(
					target,
					highlightColor,
					innerTransparency,
					outerTransparency,
					false,
					"pulse",
					0.25,
					outerHighlightColor
				)
				local chargeSound = soundHelper.PlaySound("bbCharge", target.PrimaryPart, 0.05)
				local bbFlashClone = Effects.CoreEffects.bbFlash:Clone()
				local bbOverHeadClone = Effects.CoreEffects.bbOverheadFlash:Clone()
				if weapon == "gun" then
					bbFlashClone.Parent = target:FindFirstChild("Left Arm")
					local gunChargeSound = soundHelper.PlaySound("gunCharge", target.PrimaryPart, 0.05)
					Debris:AddItem(gunChargeSound, 1)
					task.delay(0.5, function()
						local gunBlastSound = soundHelper.PlaySound("gunBlast", target.PrimaryPart, 0.05)
						local gunVFX = Effects:FindFirstChild("MuzzleFlash"):Clone()
						gunVFX.CFrame = rootpart.CFrame * CFrame.new(-0.25, 1.25, -4)
						gunVFX.Parent = Services.Workspace:FindFirstChild("Assets")
						particleHelper.EmitPart(gunVFX)
						Debris:AddItem(gunBlastSound, 1)
						Debris:AddItem(gunVFX, 1)
					end)
				elseif weapon == "fist" then
					bbFlashClone.Parent = target:FindFirstChild("Right Leg")
				end
				bbOverHeadClone.Parent = rootpart
				bbOverHeadClone.CFrame = bbOverHeadClone.CFrame * CFrame.new(0, 3, 0)
				bbFlashClone:FindFirstChildOfClass("ParticleEmitter").Color =
					ColorSequence.new(champHighlightMap[champName].Base)
				particleHelper.EmitPart(bbFlashClone)
				-- particleHelper.EmitPart(bbOverHeadClone)

				Debris:AddItem(bbFlashClone, 1)
				Debris:AddItem(bbOverHeadClone, 1)
				Debris:AddItem(highlight, 1)
				Debris:AddItem(chargeSound, 1)
			end
		elseif fxType == "attackLight" then
			if combo and rootpart then
				if combo == 5 then
					local highlightColor = champHighlightMap[champName].Base
					local outerHighlightColor = champHighlightMap[champName].Outer
					local innerTransparency = 0.85
					local outerTransparency = 0.1
					local highlight = highlightHelper:highlightCharacter(
						target,
						highlightColor,
						innerTransparency,
						outerTransparency,
						false,
						"pulse",
						0.25,
						outerHighlightColor
					)
					local chargeSound = soundHelper.PlaySound("bbCharge", target.PrimaryPart, 0.05)
					local bbFlashClone = Effects.CoreEffects.bbFlash:Clone()
					local bbOverHeadClone = Effects.CoreEffects.bbOverheadFlash:Clone()
					if weapon == "fist" then
						bbFlashClone.Parent = target:FindFirstChild("Left Arm")
					end
					bbOverHeadClone.Parent = rootpart
					bbOverHeadClone.CFrame = bbOverHeadClone.CFrame * CFrame.new(0, 3, 0)
					bbFlashClone:FindFirstChildOfClass("ParticleEmitter").Color =
						ColorSequence.new(champHighlightMap[champName].Base)
					particleHelper.EmitPart(bbFlashClone)
					-- particleHelper.EmitPart(bbOverHeadClone)
					task.delay(0.25, function()
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
end
