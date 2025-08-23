local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Debris = Services.DebrisService
local Effects = Services.Effects

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
