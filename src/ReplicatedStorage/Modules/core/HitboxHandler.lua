-- HitboxModule.lua
local HitboxModule = {}
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

-- 🔧 CONFIG
local HITBOX_TEMPLATE_NAME = "meleeHitbox"
local DEBUG = false 

function HitboxModule:Create(params)
	assert(params.attacker, "Hitbox requires attacker")
	assert(params.onHit, "Hitbox requires onHit callback")

	local template = ServerStorage:FindFirstChild(HITBOX_TEMPLATE_NAME)
	if not template then
		warn("No meleeHitbox template found in ServerStorage")
		return
	end

	local hitbox = template:Clone()
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Transparency = DEBUG and 0.5 or 1
	hitbox.Size = params.size or hitbox.Size
	hitbox.CFrame = params.cframe or CFrame.identity
	hitbox.Parent = Workspace
	hitbox.Name = "ActiveHitbox"

	-- Set up overlap parameters
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = params.ignoreList or {params.attacker.character}
	overlapParams.MaxParts = 50

	local hitOnce = {} -- Prevent multi-hit of same target

	-- Get parts overlapping the hitbox
	local parts = Workspace:GetPartsInPart(hitbox, overlapParams)
	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not hitOnce[model] then
			local target = params.attacker:GetTargetFromCharacter(model)
			if target and target ~= params.attacker then
				hitOnce[model] = true
				params.onHit(target)
			end
		end
	end

	-- Cleanup
	Debris:AddItem(hitbox, params.duration or 0.2)
end

return HitboxModule

