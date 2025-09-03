local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Debris = Services.DebrisService

return function(argumentData)
	local target: Model = argumentData.target
	local direction: string = argumentData.direction

	if target and direction then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local clone = nil

			Debris:AddItem(clone, 1)
		end
	end
end
