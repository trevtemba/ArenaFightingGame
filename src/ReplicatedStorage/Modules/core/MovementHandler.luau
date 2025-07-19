-- MovementHandler.lua
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local sprintEvent = game:GetService("ReplicatedStorage").RemoteEvents.Client.sprint

local MovementHandler = {}
MovementHandler.__index = MovementHandler

-- Configs
local DASH_DISTANCE = 20
local DASH_DURATION = 0.2
local DASH_COOLDOWN = 1.5

function MovementHandler.new(playerObj)
	local self = setmetatable({}, MovementHandler)
	self.owner = playerObj
	self.character = playerObj.character
	self.humanoid = self.character:FindFirstChildOfClass("Humanoid")
	self.hrp = self.character:FindFirstChild("HumanoidRootPart")
	self.walkspeed = playerObj.stats.speed

	self.lastDash = 0
	self.isSprinting = false

	return self
end

-- === Sprint === --

function MovementHandler:StartSprint()
	if not self.humanoid then
		return
	end
	self.humanoid.WalkSpeed = self.walkspeed * 2
	self.isSprinting = true
	sprintEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "start")

	-- if self.owner.animationHandler then
	-- 	self.owner.animationHandler:Play("sprint", 0.2, 2, 1, true)
	-- 	task.delay(0.1, function()
	-- 		self.owner.animationHandler:Stop("walk")
	-- 	end)
	-- 	print("sprinting")
	-- end
end

function MovementHandler:StopSprint()
	if not self.humanoid then
		return
	end
	self.humanoid.WalkSpeed = self.walkspeed
	self.isSprinting = false
	sprintEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "stop")

	-- if self.owner.animationHandler then
	-- 	self.owner.animationHandler:Play("walk", 0.2, 2, 1, true)
	-- 	task.delay(0.1, function()
	-- 		self.owner.animationHandler:Stop("sprint")
	-- 	end)
	-- 	print("stopped sprinting")
	-- end
end

-- === Dash === --

function MovementHandler:Dash()
	if not self.hrp then
		return
	end
	if os.clock() - self.lastDash < DASH_COOLDOWN then
		return
	end

	self.lastDash = os.clock()

	local direction = self.hrp.CFrame.LookVector * DASH_DISTANCE
	local targetPosition = self.hrp.Position + direction

	local tween = TweenService:Create(self.hrp, TweenInfo.new(DASH_DURATION, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(targetPosition),
	})

	tween:Play()

	if self.owner.PlayAnimation then
		self.owner:PlayAnimation("Dash")
	end
end

-- === Jump === --

function MovementHandler:Jump()
	if not self.humanoid then
		return
	end
	if self.humanoid:GetState() == Enum.HumanoidStateType.Running then
		self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

return MovementHandler
