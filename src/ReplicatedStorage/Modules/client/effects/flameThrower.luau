local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local weldHelper = require(script.Parent.weldHelper)
local Assets = ReplicatedStorage:WaitForChild("Assets")

return function(argumentData)
	local target: Model = argumentData.target
	local duration: number = argumentData.duration

	if target then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local flameThrowerClone = Assets:WaitForChild("flameThrower"):Clone()
			flameThrowerClone.CFrame = rootPart.CFrame * CFrame.new(1.25, 0.75, -3.5)
			local weld = weldHelper.WeldParts(rootPart, flameThrowerClone)
			flameThrowerClone.Parent = game.Workspace:WaitForChild("Assets")
			flameThrowerClone.flame.Enabled = true

			task.delay(duration, function()
				flameThrowerClone.flame.Enabled = false
				Debris:AddItem(flameThrowerClone, 5)
				Debris:AddItem(weld, duration + 5)
			end)
		end
	end
end
