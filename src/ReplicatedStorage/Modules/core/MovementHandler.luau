-- MovementHandler.lua
local clientEffects = game:GetService("ReplicatedStorage").RemoteEvents.Client.clientEffects
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

function MovementHandler:CanSprint()
	local stateHandler = self.owner.stateHandler

	local blockedStates = {
		"attacking",
		"casting",
		"blocking",
		"dashing",
		"stunned",
		"ragdolled",
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function MovementHandler:CanDash()
	local stateHandler = self.owner.stateHandler

	local blockedStates = {
		"attacking",
		"casting",
		"stunned",
		"ragdolled",
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function MovementHandler:StartSprint()
	if not self.humanoid and not self:CanSprint() then
		return
	end
	self.humanoid.WalkSpeed = self.walkspeed * 2
	self.owner.stateHandler:SetState("sprinting")
	sprintEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "start")
end

function MovementHandler:StopSprint()
	if not self.humanoid then
		return
	end
	self.humanoid.WalkSpeed = self.walkspeed
	self.owner.stateHandler:RemoveState("sprinting")
	sprintEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "stop")
end

-- === Dash === --

function MovementHandler:HandleDash(direction)
	if not self.humanoid and not self:CanDash() then
		return
	end
	self.owner.stateHandler:SetState("dashing")
	clientEffects:FireAllClients("dash", { target = self.character, direction = direction })
	task.delay(0.5, function()
		self.owner.stateHandler:RemoveState("dashing")
	end)
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
