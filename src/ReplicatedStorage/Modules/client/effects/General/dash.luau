local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local Debris = Services.DebrisService

local WeldHelper = require(Services.SharedUtils.WeldHelper)
local Effects = Services.Effects

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
			-- 	local dashEffect = Effects:WaitForChild("DashEffects"):WaitForChild(direction)
			-- 	if dashEffect then
			-- 		local followPartClone = dashEffect:FindFirstChild("followPart"):Clone()
			-- 		if followPartClone then
			-- 			-- Create an attachment in both parts
			-- 			local rootAttachment = Instance.new("Attachment")
			-- 			rootAttachment.Parent = rootPart

			-- 			local effectAttachment = Instance.new("Attachment")
			-- 			effectAttachment.Parent = followPartClone

			-- 			-- Align Position
			-- 			local alignP = followPartClone:FindFirstChildOfClass("AlignPosition")
			-- 			alignP.Attachment0 = effectAttachment
			-- 			alignP.Attachment1 = rootAttachment
			-- 			alignP.Parent = followPartClone

			-- 			-- Align Orientation
			-- 			local alignO = followPartClone:FindFirstChildOfClass("AlignOrientation")
			-- 			alignO.Attachment0 = effectAttachment
			-- 			alignO.Attachment1 = rootAttachment
			-- 			alignO.Parent = followPartClone

			-- 			followPartClone.CFrame = rootPart.CFrame
			-- 			followPartClone.Parent = workspace

			-- 			particleHelper.EnablePart(followPartClone)

			-- 			-- Disable after some time
			-- 			task.delay(0.6, function()
			-- 				particleHelper.DisablePart(followPartClone)
			-- 				Debris:AddItem(followPartClone, 0.5)
			-- 				Debris:AddItem(rootAttachment, 0.5)
			-- 			end)
			-- 		end
			-- 	end

			local trailLimb = Effects:FindFirstChild("TrailLimb")
			for _, v in target:GetChildren() do
				if v.Name == "Left Arm" or v.Name == "Right Arm" or v.Name == "Right Leg" or v.Name == "Left Leg" then
					local baseA = trailLimb:FindFirstChild("base"):Clone()
					local topA = trailLimb:FindFirstChild("top"):Clone()
					local trail = trailLimb:FindFirstChild("Trail"):Clone()
					trail.Attachment0 = baseA
					trail.Attachment1 = topA
					baseA.Parent = v
					topA.Parent = v
					trail.Enabled = true
					trail.Parent = v
					task.delay(0.6, function()
						trail.Enabled = false
						Debris:AddItem(trail, 1)
						Debris:AddItem(baseA, 1)
						Debris:AddItem(topA, 1)
					end)
				end
			end

			-- Debris:AddItem(clone, 1)
			Debris:AddItem(sound, 1)
		end
	end
end
