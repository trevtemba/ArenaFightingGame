local PhysicsHandler = {}
PhysicsHandler.__index = PhysicsHandler

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RagdollHandler = require(
	game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("core"):WaitForChild("RagdollHandler")
)

local mockRootPart = ReplicatedStorage:WaitForChild("Misc"):FindFirstChild("MockRootPart")

function PhysicsHandler.new(rig, entityType, userId)
	local self = setmetatable({}, PhysicsHandler)

	self.character = rig
	self.hrp = rig:FindFirstChild("HumanoidRootPart")
	self.humanoid = rig:FindFirstChildOfClass("Humanoid")
	self.entityType = entityType
	self.userId = entityType == "player" and userId or nil
	self.alignPart = nil
	self.alignPostion = nil

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
function PhysicsHandler:applyImpulse(direction)
	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(4e4, 0, 4e4)
	velocity.Velocity = self.hrp.CFrame.LookVector * direction
	velocity.Parent = self.hrp
	Debris:AddItem(velocity, 0.3)
end

-- Setup helper
function PhysicsHandler:createAirFloat(character, name)
	local alignPart = mockRootPart:Clone()
	alignPart.Parent = game.Workspace:FindFirstChild("PhysicsAssets")
	alignPart.CFrame = character.PrimaryPart.CFrame

	local att0 = Instance.new("Attachment")
	att0.Name = name .. "_Base"
	att0.Parent = character.PrimaryPart

	local att1 = Instance.new("Attachment")
	att1.Name = name .. "_Target"
	att1.Parent = alignPart

	local align = Instance.new("AlignPosition")
	align.Name = name
	align.Mode = Enum.PositionAlignmentMode.TwoAttachment
	align.MaxForce = 5e5
	align.Responsiveness = 20

	align.Attachment0 = att0
	align.Attachment1 = att1
	align.Parent = character.PrimaryPart

	return align, alignPart, att0, att1
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

	self:applyImpulse(distance)
end

function PhysicsHandler:MoveBackward(distance)
	if not self.hrp then
		return
	end

	self:applyImpulse(-distance)
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
