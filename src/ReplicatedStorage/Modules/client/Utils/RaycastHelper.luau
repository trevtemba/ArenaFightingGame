-- ClientHelpers/RaycastHelper.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Players = Services.Players
local UserInputService = Services.UserInputService
local Workspace = Services.Workspace

local RaycastHelper = {}
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- whitelist or collection service tag check can go here
local function isCharacter(hitPart)
	local character = hitPart:FindFirstAncestorOfClass("Model")
	if not character then
		return false
	end
	if character == localPlayer.Character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	return true, character
end

function RaycastHelper:GetMouseTarget(maxDistance)
	maxDistance = maxDistance or 1000

	-- get mouse position in screen space
	local mousePos = UserInputService:GetMouseLocation()

	-- convert to ray in world space
	local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	-- do the raycast
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { localPlayer.Character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * maxDistance, raycastParams)
	if result then
		local valid, enemy = isCharacter(result.Instance)
		if valid then
			return enemy, result
		end
	end

	return nil, nil
end

return RaycastHelper
