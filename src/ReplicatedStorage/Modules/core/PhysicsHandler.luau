local PhysicsHandler = {}
PhysicsHandler.__index = PhysicsHandler

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RagdollHandler = require(
	game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("core"):WaitForChild("RagdollHandler")
)

function PhysicsHandler.new(rig, entityType, userId)
	local self = setmetatable({}, PhysicsHandler)

	self.character = rig
	self.hrp = rig:FindFirstChild("HumanoidRootPart")
	self.humanoid = rig:FindFirstChildOfClass("Humanoid")
	self.entityType = entityType
	self.userId = entityType == "player" and userId or nil

	return self
end

local lowFrictionProps = PhysicalProperties.new(
	0.001, -- Density (keep default or tweak)
	0.2, -- Friction (very low)
	0, -- Elasticity
	1, -- FrictionWeight
	1 -- ElasticityWeight
)

local function setLowFriction(rig)
	for _, part in pairs(rig:GetChildren()) do
		if part:IsA("BasePart") then
			part.CustomPhysicalProperties = lowFrictionProps
		end
	end
end

-- Utility to stop velocity after a short duration
local function applyImpulse(hrp, direction)
	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(4e4, 0, 4e4)
	velocity.Velocity = hrp.CFrame.LookVector * direction
	velocity.Parent = hrp
	Debris:AddItem(velocity, 0.3)
end

function PhysicsHandler:shiftNetworkOwner(duration)
	print("Shifting network ownership")
	if not self.hrp or not self.humanoid then
		return
	end

	self.humanoid.PlatformStand = true -- Freeze control

	task.delay(duration, function()
		local player = Players:GetPlayerByUserId(self.userId)
		if self.hrp and player then
			self.humanoid.PlatformStand = false
		end
	end)
end

function PhysicsHandler:MoveForward(distance)
	if not self.hrp then
		return
	end

	applyImpulse(self.hrp, distance)
end

function PhysicsHandler:MoveBackward(distance)
	if not self.hrp then
		return
	end

	applyImpulse(self.hrp, -distance)
end

function PhysicsHandler:Knockback(fromCharacter, power, duration)
	if not self.hrp or not fromCharacter then
		return
	end

	local enemyHRP = fromCharacter:FindFirstChild("HumanoidRootPart")
	if not enemyHRP then
		return
	end

	local att = Instance.new("Attachment")
	att.Name = "KnockbackAttachment"
	att.Parent = self.hrp

	local direction = (self.hrp.Position - enemyHRP.Position).Unit
	local horizontalForce = direction * power
	local upwardForce = Vector3.new(0, 0, 0)

	local lv = Instance.new("LinearVelocity")
	lv.Name = "KnockbackVelocity"
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = horizontalForce + upwardForce

	setLowFriction(self.character)
	lv.Parent = att
	RagdollHandler:Ragdoll(self.character, duration)

	Debris:AddItem(att, 0.01)
end

function PhysicsHandler:SetWalkspeed(speed)
	if self.humanoid then
		self.humanoid.WalkSpeed = speed
	end
end

return PhysicsHandler
