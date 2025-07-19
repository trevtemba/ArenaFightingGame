-- MovementHandler.lua
local HeapProfilerService = game:GetService("HeapProfilerService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local sprintEvent = game:GetService("ReplicatedStorage").RemoteEvents.Client.sprint

local MovementHandler = {}
MovementHandler.__index = MovementHandler

-- Configs
local DASH_DISTANCE = 20
local DASH_DURATION = 0.7
local DASH_COOLDOWN = 1
local DASH_SPEED = DASH_DISTANCE / DASH_DURATION

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

function MovementHandler:HandleDash(direction)
	-- if not self.hrp or not self.humanoid or self.isDashing then
	-- 	return
	-- end

	-- local now = tick()
	-- if now - self.lastDash < DASH_COOLDOWN then
	-- 	return
	-- end

	-- self.lastDash = now
	-- self.isDashing = true
	-- self.humanoid.WalkSpeed = 0

	-- local dashSpeed = 75
	-- local startTime = tick()
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
