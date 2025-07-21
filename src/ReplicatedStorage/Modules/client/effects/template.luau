local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local target: Model = argumentData.target
	local direction: string = argumentData.direction
	print("rererererre")
	if target and direction then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local clone = nil

			Debris:AddItem(clone, 1)
		end
	end
end
