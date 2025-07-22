-- MovementHandler.lua
local clientEffects = game:GetService("ReplicatedStorage").RemoteEvents.Client.clientEffects
local Players = game:GetService("Players")
local sprintEvent = game:GetService("ReplicatedStorage").RemoteEvents.Client.sprint

local MovementHandler = {}
MovementHandler.__index = MovementHandler

local STATE = require(script.Parent.State)

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
		STATE.Attacking,
		STATE.Casting,
		STATE.Blocking,
		STATE.Dashing,
		STATE.Stunned,
		STATE.Ragdolled,
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function MovementHandler:CanDash()
	local stateHandler = self.owner.stateHandler

	local blockedStates = {
		STATE.Attacking,
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function MovementHandler:StartSprint()
	if not self.humanoid and not self:CanSprint() then
		return
	end
	self.humanoid.WalkSpeed = self.walkspeed * 2
	self.owner.stateHandler:SetState(STATE.Sprinting)
	sprintEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "start")
end

function MovementHandler:StopSprint()
	if not self.humanoid then
		return
	end
	self.humanoid.WalkSpeed = self.walkspeed
	self.owner.stateHandler:RemoveState(STATE.Sprinting)
	sprintEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "stop")
end

-- === Dash === --

function MovementHandler:HandleDash(direction)
	if not self.humanoid and not self:CanDash() then
		return
	end
	self.owner.stateHandler:SetState(STATE.Dashing)
	clientEffects:FireAllClients("dash", { target = self.character, direction = direction })
	task.delay(0.5, function()
		self.owner.stateHandler:RemoveState(STATE.Dashing)
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
