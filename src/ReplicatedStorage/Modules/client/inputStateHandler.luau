local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local STATE = require(Services.Enums.State)

local InputStateHandler = {}
InputStateHandler.__index = InputStateHandler

function InputStateHandler.new(humanoid)
	local self = setmetatable({}, InputStateHandler)

	-- Active states like "sprinting", "dashing", etc.
	self.states = {}
	self.humanoid = humanoid
	-- Track current input holds
	self.heldInputs = {}
	self.walking = nil
	self.soulVisible = false
	return self
end

function InputStateHandler:CanDo(state)
	local stunned = self.humanoid.Parent:GetAttribute("Stunned")
	if stunned then
		print("cant do, your stunned")
		return false
	end

	local blockedStates = {}
	if state == STATE.Sprinting then
		blockedStates = {
			STATE.Sprinting,
			STATE.InAirCombo,
			STATE.Attacking,
			STATE.AttackingHeavy,
			STATE.Casting,
			STATE.Blocking,
			STATE.Dashing,
			STATE.Stunned,
			STATE.Ragdolled,
		}
	elseif state == STATE.Walking then
		blockedStates = {
			STATE.Stunned,
			STATE.Ragdolled,
		}
	elseif state == STATE.Dashing then
		blockedStates = {
			STATE.Dashing,
			STATE.InAirCombo,
			STATE.Attacking,
			STATE.Casting,
			STATE.Stunned,
			STATE.Ragdolled,
		}
	elseif state == STATE.Blocking then
		blockedStates = {
			STATE.Attacking,
			STATE.Blocking,
			STATE.Casting,
			STATE.Stunned,
			STATE.Ragdolled,
		}
	elseif state == STATE.Attacking then
		blockedStates = {
			STATE.Casting,
			STATE.AttackingHeavy,
		}
	elseif state == STATE.AttackingHeavy then
		blockedStates = {
			STATE.Casting,
			STATE.Attacking,
		}
	elseif state == STATE.Casting then
		blockedStates = {
			STATE.Casting,
			STATE.Stunned,
		}
	elseif state == STATE.SoulCasting then
		blockedStates = {
			STATE.Casting,
			STATE.SoulCasting,
		}
	elseif state == STATE.Jumping then
		blockedStates = {
			STATE.Jumping,
			STATE.Casting,
			STATE.Stunned,
			STATE.Ragdolled,
		}
	end

	return not self:HasAny(blockedStates) and self.humanoid
end

-- Enables an input state
function InputStateHandler:SetState(state)
	self.states[state] = true
end

-- Enables an input state
function InputStateHandler:GetState(state)
	return self.states[state]
end

-- Disables an input state
function InputStateHandler:RemoveState(state)
	self.states[state] = nil
end

-- Checks if an input state is currently active
function InputStateHandler:HasState(state)
	return self.states[state] == true
end

function InputStateHandler:HasAny(states)
	for _, state in ipairs(states) do
		if self:HasState(state) then
			return true
		end
	end
	return false
end

-- Clears all current input states (useful on death or reset)
function InputStateHandler:ClearStates()
	for k in pairs(self.states) do
		self.states[k] = nil
	end
end

function InputStateHandler:ClearHelds()
	for k in pairs(self.heldInputs) do
		self.heldInputs[k] = nil
	end
end

-- Optionally expose all active states (for debugging or syncing)
function InputStateHandler:GetAllStates()
	local list = {}
	for state in pairs(self.states) do
		table.insert(list, state)
	end
	return list
end

function InputStateHandler:HeldOn(input)
	self.heldInputs[input] = true
end

function InputStateHandler:HeldOff(input)
	self.heldInputs[input] = nil
end

function InputStateHandler:IsHeld(input)
	return self.heldInputs[input]
end

function InputStateHandler:GetAllHeldInputs()
	return self.heldInputs
end

function InputStateHandler:ToggleHeldForFreecam()
	for _, v in pairs(self.heldInputs) do
		if v ~= "forward" and v ~= "shift" then
			self.heldInputs[v] = nil
		end
	end
end

return InputStateHandler
