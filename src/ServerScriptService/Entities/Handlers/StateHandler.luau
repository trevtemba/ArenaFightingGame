local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Signal = require(Services.Signal)

local StateHandler = {}
StateHandler.__index = StateHandler

function StateHandler.new()
	local self = setmetatable({}, StateHandler)

	self.states = {}
	-- Bumped on every mutation of a state. A pending SetFor expiry compares
	-- against this to tell whether it still owns the state it is about to remove.
	self._generations = {}

	--[[
		Fired as (state, isActive) when a state actually turns on or off.

		Only real transitions fire. Setting a state that is already active is
		silent, so subscribers can treat every event as a change rather than
		de-duplicating themselves -- which is the whole point: consequences of a
		state change can live with the thing that cares (animation, UI, VFX)
		instead of being spelled out imperatively at each of the ~77 call sites
		that mutate state.
	]]
	self.Changed = Signal.new()

	return self
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

function StateHandler:SetState(state)
	setActive(self, state, true)
end

function StateHandler:RemoveState(state)
	setActive(self, state, false)
end

--[[
	Set a state and clear it after `duration`, unless something touches that
	state first.

	This is what makes overlapping timers safe. A bare
	task.delay(d, function() RemoveState(X) end) has no way to know whether the X
	it is clearing is the one it set: get stunned mid-attack and the attack's
	timer still fires on schedule, clearing a state that a newer action
	established. Because every mutation bumps the generation, a superseded timer
	sees the mismatch and does nothing.
]]
function StateHandler:SetFor(state, duration)
	local generation = setActive(self, state, true)

	task.delay(duration, function()
		if self._generations[state] ~= generation then
			return
		end
		self:RemoveState(state)
	end)
end

--[[
	Arm an expiry for a state that was set earlier, with the same supersession
	guarantee as SetFor. Use when the set and the expiry are far apart in the
	flow -- an attack sets its state up front but only knows the cooldown once
	the swing resolves.
]]
function StateHandler:RemoveStateAfter(state, duration)
	local generation = self._generations[state]

	task.delay(duration, function()
		if self._generations[state] ~= generation then
			return
		end
		self:RemoveState(state)
	end)
end

function StateHandler:HasState(state)
	return self.states[state] == true
end

function StateHandler:HasAny(states)
	for _, state in ipairs(states) do
		if self:HasState(state) then
			return true
		end
	end
	return false
end

function StateHandler:ClearStates()
	-- Snapshot first: setActive fires Changed, and a subscriber that mutates
	-- state in response would otherwise be modifying the table mid-traversal.
	local active = self:GetAllStates()

	for _, state in active do
		-- Goes through setActive so a SetFor expiry still in flight cannot
		-- outlive the clear and then remove a state something set afterwards.
		setActive(self, state, false)
	end
end

function StateHandler:GetAllStates()
	local list = {}
	for state in pairs(self.states) do
		table.insert(list, state)
	end
	return list
end

--[[
	Releases the Changed subscriptions. Nothing calls this yet -- entities are
	dropped rather than explicitly torn down -- but a handler that owns a Signal
	should offer it, and this is where entity cleanup belongs when it arrives.
]]
function StateHandler:Destroy()
	self.Changed:Destroy()
end

return StateHandler
