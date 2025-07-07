local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local DEBUG = false

local HitboxModule = {}

function HitboxModule:CreatePlrHitbox(params)
	assert(params.attacker, "Hitbox requires attacker")
	assert(params.onHit, "Hitbox requires onHit callback")

	local template = ServerStorage:FindFirstChild(params.hitboxTemplate)
	if not template then
		print(string.format("No %s template found in ServerStorage", params.hitboxTemplate))
		return
	end

	local hitbox = template:Clone()
	hitbox.Transparency = DEBUG and 0.5 or 1
	hitbox.Size = params.size or hitbox.Size
	hitbox.CFrame = params.cframe or CFrame.identity
	hitbox.Parent = Workspace
	hitbox.Name = "ActiveHitbox"

	-- Set up overlap parameters
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = params.ignoreList or { params.attacker.character }
	overlapParams.MaxParts = 50

	local hitOnce = {} -- Prevent multi-hit of same target

	-- Get parts overlapping the hitbox
	local parts = Workspace:GetPartsInPart(hitbox, overlapParams)
	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not hitOnce[model] then
			local entity = nil
			if CollectionService:HasTag(model, "Enemy") then
				entity = params.attacker:GetEnemyFromCharacter(model)
			else
				entity = params.attacker:GetPlayerFromCharacter(model)
			end
			if entity and entity ~= params.attacker then
				hitOnce[model] = true
				params.onHit(entity)
			end
		end
	end

	-- Cleanup
	Debris:AddItem(hitbox, params.duration or 0.2)
end

function HitboxModule:CreateNPCHitbox(params)
	assert(params.attacker, "Hitbox requires attacker")
	assert(params.onHit, "Hitbox requires onHit callback")

	local template = ServerStorage:FindFirstChild(params.hitboxTemplate)
	if not template then
		print(string.format("No %s template found in ServerStorage", params.hitboxTemplate))
		return
	end

	local hitbox = template:Clone()
	hitbox.Transparency = DEBUG and 0.5 or 1
	hitbox.Size = params.size or hitbox.Size
	hitbox.CFrame = params.cframe or CFrame.identity
	hitbox.Parent = Workspace:FindFirstChild("Hitboxes")
	hitbox.Name = "ActiveHitbox"

	-- Set up overlap parameters
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { params.target.character }
	overlapParams.MaxParts = 10

	local hitOnce = {} -- Prevent multi-hit of same target

	-- Get parts overlapping the hitbox
	local parts = Workspace:GetPartsInPart(hitbox, overlapParams)
	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not hitOnce[model] then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				hitOnce[model] = true
				params.onHit(params.target)
			end
		end
	end

	-- Cleanup
	Debris:AddItem(hitbox, params.duration or 0.2)
end

function HitboxModule:CreateNPCProjectile(params)
	assert(params.attacker, "Projectile requires attacker")
	assert(params.onHit, "Projectile requires onHit callback")
	assert(params.projectileTemplate, "Projectile requires a template")

	local targetChar = params.target.character
	local targetPart = targetChar:FindFirstChild("HumanoidRootPart")
	if not targetPart then
		return
	end

	local origin = params.origin
	local direction = (targetPart.Position - origin).Unit
	local projectile = params.projectileTemplate:Clone()

	projectile.CFrame = CFrame.new(origin, origin + direction)
	projectile.Transparency = 0
	projectile:WaitForChild("Trail").Enabled = true
	projectile.Parent = workspace

	local speed = params.speed or 100
	local maxRange = params.range or 100
	local hitRadius = params.hitRadius or 2
	local travelled = 0

	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		local step = speed * dt
		travelled += step

		projectile.CFrame = projectile.CFrame + (direction * step)

		if targetPart and (targetPart.Position - projectile.Position).Magnitude <= hitRadius then
			local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				connection:Disconnect()
				projectile:Destroy()
				params.onHit(params.target)
			end
		elseif travelled >= maxRange then
			connection:Disconnect()
			if params.onMiss then
				params.onMiss(projectile)
			else
				projectile:Destroy()
			end
		end
	end)
end

return HitboxModule
