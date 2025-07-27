local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local highlightHelper = require(script.Parent.highlightHelper)

local Sounds = ReplicatedStorage:FindFirstChild("Sounds")
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local target: Model = argumentData.target
	local hitType: string = argumentData.hitType
	local knocksBack: boolean = argumentData.knocksBack
	if target and hitType then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local clone = nil
			local sound = nil
			local highlightColor = Color3.fromRGB(255, 0, 0)
			local innerTransparency = 0.85
			local outerTransparency = 1
			-- todo: add knockback effect
			if hitType == "blunt" then
				clone = Effects.CoreEffects.bluntHitEffect:Clone()
				sound = Sounds:FindFirstChild("impact"):Clone()
			elseif hitType == "slash" then
				clone = Effects.CoreEffects.slashHitEffect:Clone()
				sound = Sounds:FindFirstChild("impact"):Clone()
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
			for _, v in clone:GetDescendants() do
				if v:IsA("ParticleEmitter") then
					if v:GetAttribute("EmitDelay") and v:GetAttribute("EmitDelay") > 0 then
						task.delay(v:GetAttribute("EmitDelay"), function()
							v:Emit(v:GetAttribute("EmitCount"))
						end)
					else
						v:Emit(v:GetAttribute("EmitCount"))
					end
				end
			end
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
			Debris:AddItem(clone, 1)
			Debris:AddItem(sound, 1)
			Debris:AddItem(highlight, 1)
		end
	end
end
