-- MovementHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Players = Services.Players
local clientEffects = Services.ClientEvents.clientEffects
local sprintEvent = Services.ClientEvents.sprint

local MovementHandler = {}
MovementHandler.__index = MovementHandler

local STATE = require(Services.Enums:WaitForChild("State"))
local ActionRules = require(Services.Shared:WaitForChild("ActionRules"))

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
	local blockedStates = ActionRules.For(ActionRules.server, STATE.Sprinting)

	return not self.owner.stateHandler:HasAny(blockedStates) and self.owner.alive
end

function MovementHandler:CanDash()
	local blockedStates = ActionRules.For(ActionRules.server, STATE.Dashing)

	return not self.owner.stateHandler:HasAny(blockedStates) and self.owner.alive
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
	self.owner.stateHandler:SetFor(STATE.Dashing, 0.5)
	clientEffects:FireAllClients("dash", { target = self.character, direction = direction })
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
