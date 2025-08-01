local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local target: Model = argumentData.target
	local killEffect: string = argumentData.killEffect
	if target and killEffect then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			--todo
		end
	end
end
