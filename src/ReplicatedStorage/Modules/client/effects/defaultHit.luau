local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local highlightHelper = require(script.Parent.highlightHelper)

local Sounds = ReplicatedStorage:FindFirstChild("Sounds")
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local target: Model = argumentData.target
	local hitType: string = argumentData.hitType
	if target and hitType then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local clone = nil
			local sound = nil

			if hitType == "blunt" then
				clone = Effects.CoreEffects.bluntHitEffect:Clone()
				sound = Sounds:FindFirstChild("impact"):Clone()
			elseif hitType == "slash" then
				clone = Effects.CoreEffects.slashHitEffect:Clone()
				sound = Sounds:FindFirstChild("impact"):Clone()
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
			local highlight =
				highlightHelper:highlightCharacter(target, Color3.fromRGB(255, 0, 0), 0.8, 1, false, "pulse", 0.25)
			-- Cleanup
			Debris:AddItem(clone, 1)
			Debris:AddItem(sound, 1)
			Debris:AddItem(highlight, 1)
		end
	end
end
