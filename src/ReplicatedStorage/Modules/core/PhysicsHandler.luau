local PhysicsHandler = {}
PhysicsHandler.__index = PhysicsHandler

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local RagdollHandler = require(
	game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("core"):WaitForChild("RagdollHandler")
)

local tweenInfoMoveChar = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function PhysicsHandler.new(rig)
	local self = setmetatable({}, PhysicsHandler)

	self.character = rig
	self.hrp = rig:FindFirstChild("HumanoidRootPart")
	self.humanoid = rig:FindFirstChildOfClass("Humanoid")

	return self
end

function PhysicsHandler:TweenMove(distance)
	if not self.hrp then
		return
	end

	local goalCFrame = self.hrp.CFrame * CFrame.new(0, 0, -distance)
	local tween = TweenService:Create(self.hrp, tweenInfoMoveChar, { CFrame = goalCFrame })
	tween:Play()
end

function PhysicsHandler:TweenRetreat(distance)
	if not self.hrp then
		return
	end

	local goalCFrame = self.hrp.CFrame * CFrame.new(0, 0, distance)
	local tween = TweenService:Create(self.hrp, tweenInfoMoveChar, { CFrame = goalCFrame })
	tween:Play()
end

-- directional knockback (with ragdoll)
function PhysicsHandler:Knockback(fromCharacter, power)
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
	local upwardForce = Vector3.new(0, 20, 0)

	local lv = Instance.new("LinearVelocity")
	lv.Name = "KnockbackVelocity"
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = horizontalForce + upwardForce
	lv.Parent = att

	RagdollHandler:Ragdoll(self.character, 2)
	Debris:AddItem(att, 0.1)
end

function PhysicsHandler:TweenFaceTarget(targetCharacter, duration)
	if not self.hrp or not targetCharacter then
		return
	end

	local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not targetHRP then
		return
	end

	local targetPos = Vector3.new(
		targetHRP.Position.X,
		self.hrp.Position.Y, -- lock Y-axis to avoid tilting
		targetHRP.Position.Z
	)

	local currentPos = self.hrp.Position
	local lookAtCFrame = CFrame.new(currentPos, targetPos)

	local goal = { CFrame = lookAtCFrame }
	local tweenInfo = TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local tween = TweenService:Create(self.hrp, tweenInfo, goal)
	tween:Play()
end

function PhysicsHandler:SetWalkspeed(speed)
	if self.humanoid then
		self.humanoid.WalkSpeed = speed
	end
end

return PhysicsHandler
