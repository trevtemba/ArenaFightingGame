local PhysicsService = game:GetService("PhysicsService")

local CollisionManager = {}

local ENTITIES = "Entities"

function CollisionManager:Init()
	PhysicsService:RegisterCollisionGroup(ENTITIES)
	PhysicsService:CollisionGroupSetCollidable(ENTITIES, ENTITIES, false)
end

function CollisionManager:SetCollisionGroup(model, collisionGroupName)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = collisionGroupName
		end
	end
end

function CollisionManager:SetCollisionGroupEntities(model)
	self:SetCollisionGroup(model, ENTITIES)
end

return CollisionManager
