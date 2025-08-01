local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local rootPos: Vector3 = argumentData.rootPos
	local tier: string = argumentData.tier
	local id: string = argumentData.id
	print("rererererre")
	if rootPos and tier and id then
		print(rootPos)
		print(tier)
		print(id)
	end
end
