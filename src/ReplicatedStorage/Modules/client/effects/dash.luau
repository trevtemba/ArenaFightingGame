local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = ReplicatedStorage:WaitForChild("Effects")

local weldHelper = require(script.Parent:FindFirstChild("weldHelper"))
local offsets = {
	left = CFrame.new(2, 0, 0),
	right = CFrame.new(-2, 0, 0),
	forward = CFrame.new(0, 0, 2),
	back = CFrame.new(0, 0, -2),
}
return function(argumentData)
	local target: Model = argumentData.target
	local direction: string = argumentData.direction
	local sound = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("dash"):Clone()
	sound.Parent = target

	if target and direction then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		sound:Play()

		if rootPart then
			local clone = Effects:WaitForChild("DashEffects"):WaitForChild(direction):Clone()
			if clone then
				clone.CFrame = rootPart.CFrame * offsets[direction]
				weldHelper.WeldParts(rootPart, clone)
				clone.Parent = rootPart
				for _, v in clone:GetDescendants() do
					if v:IsA("ParticleEmitter") then
						v.Enabled = true
						task.delay(0.4, function()
							v.Enabled = false
						end)
					end
				end
			end

			local trailLimb = Effects:FindFirstChild("TrailLimb")
			for _, v in target:GetChildren() do
				if v.Name == "Left Arm" or v.Name == "Right Arm" or v.Name == "Right Leg" or v.Name == "Left Leg" then
					local trailLimbClone = trailLimb:Clone()
					trailLimbClone.CFrame = v.CFrame
					weldHelper.WeldParts(v, trailLimbClone)
					trailLimbClone.Trail.Enabled = true
					trailLimbClone.Parent = v
					task.delay(0.6, function()
						trailLimbClone.Trail.Enabled = false
						Debris:AddItem(trailLimbClone, 1)
					end)
				end
			end

			Debris:AddItem(clone, 1)
			Debris:AddItem(sound, 1)
		end
	end
end
