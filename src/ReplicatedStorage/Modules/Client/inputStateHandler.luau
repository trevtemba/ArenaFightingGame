local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
-- STATE is no longer needed here: the blocking lists moved to ActionRules, and
-- CanDo now looks the action up rather than comparing against each enum member.
local ActionRules = require(Services.Shared.ActionRules)
local Signal = require(Services.Signal)

local InputStateHandler = {}
InputStateHandler.__index = InputStateHandler

function InputStateHandler.new(humanoid)
	local self = setmetatable({}, InputStateHandler)

	-- Active states like "sprinting", "dashing", etc.
	self.states = {}
	-- Bumped on every mutation of a state. A pending SetFor expiry compares
	-- against this to tell whether it still owns the state it is about to remove.
	self._generations = {}

	--[[
		Fired as (state, isActive) when a state actually turns on or off. Mirrors
		the server's StateHandler.Changed.

		Only real transitions fire, so subscribers can treat every event as a
		change. This is what lets animation become a function of state instead of
		the scattered Play/Stop calls in inputHandler that kept drifting out of
		sync with the state they were meant to mirror.
	]]
	self.Changed = Signal.new()

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

	-- An action with no rule is unrestricted, same as the old if/elseif chain
	-- falling through to an empty blockedStates table.
	local blockedStates = ActionRules.For(ActionRules.client, state)

	return not self:HasAny(blockedStates) and self.humanoid
end

local function bump(self, state)
	local generation = (self._generations[state] or 0) + 1
	self._generations[state] = generation
	return generation
end

--[[
	The single mutation point, so every path that changes a state bumps the
	generation and fires Changed identically. Returns the new generation for
	callers that need to arm a supersession-checked timer.
]]
local function setActive(self, state, active)
	local generation = bump(self, state)
	local wasActive = self.states[state] == true

	self.states[state] = active or nil

	if wasActive ~= active then
		self.Changed:Fire(state, active)
	end

	return generation
end

-- Enables an input state
function InputStateHandler:SetState(state)
	setActive(self, state, true)
end

--[[
	Set a state and clear it after `duration`, unless something touches that
	state first. Mirrors the server's StateHandler:SetFor.

	A bare task.delay(d, function() RemoveState(X) end) cannot tell whether the X
	it is clearing is the one it set, so an older timer can clear a state a newer
	action established. Every mutation bumps the generation, so a superseded
	timer sees the mismatch and does nothing.
]]
function InputStateHandler:SetFor(state, duration)
	local generation = setActive(self, state, true)

	task.delay(duration, function()
		if self._generations[state] ~= generation then
			return
		end
		self:RemoveState(state)
	end)
end

-- Enables an input state
function InputStateHandler:GetState(state)
	return self.states[state]
end

-- Disables an input state
function InputStateHandler:RemoveState(state)
	setActive(self, state, false)
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
	-- Snapshot first: setActive fires Changed, and a subscriber that mutates
	-- state in response would otherwise be modifying the table mid-traversal.
	local active = self:GetAllStates()

	for _, state in active do
		-- Goes through setActive so a SetFor expiry still in flight cannot
		-- outlive the clear and then remove a state something set afterwards.
		setActive(self, state, false)
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

-- Drop every hold except forward/shift, so switching movement contexts does not
-- strand a direction that will never receive its Released event.
function InputStateHandler:ToggleHeldForFreecam()
	-- Iterates keys. This used to walk the values, which are all `true`, so it
	-- compared `true` against "forward" and then cleared self.heldInputs[true] --
	-- a key that is never set. It silently freed nothing.
	local stale = {}
	for input in pairs(self.heldInputs) do
		if input ~= "forward" and input ~= "shift" then
			table.insert(stale, input)
		end
	end

	for _, input in stale do
		self.heldInputs[input] = nil
	end
end

--[[
	Releases the Changed subscriptions. inputHandler builds a fresh handler on
	every spawn, so the previous one should be destroyed rather than left holding
	subscriptions -- see the note on the ShiftlockModule unsubscribe there.
]]
function InputStateHandler:Destroy()
	self.Changed:Destroy()
end

return InputStateHandler
