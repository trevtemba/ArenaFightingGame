local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local RunService = Services.RunService

local animationModule = require(Services.Client.animationModule)
local moveDirection = require(Services.Client.moveDirection)
local camModule = require(Services.Client.cameraModule)
local STATE = require(Services.Enums.State)

--[[
	Owns every looping locomotion animation, derived rather than driven.

	This used to be spelled out imperatively at each input call site: both
	movement contexts played their own walk animation, updateSprinting started
	and stopped the sprint, and applyMovementContext had to sweep up whatever was
	left stranded. Three copies of the truth, which drifted -- sprint stopped
	itself on a redundant update, and the left/right/back walks played
	walkForward whenever the live context disagreed with the camera.

	Here the desired animation is a pure function of (state, movement direction)
	and is diffed against what is actually playing, so there is nothing to keep
	in sync.

	Deliberately scoped to *looping* animations. One-shots -- the dashes and
	landing -- stay imperative at their trigger, because they self-terminate:
	deriving a non-looped dash would have the resolver restart it the moment it
	ended, since STATE.Dashing outlives the animation.

	Locomotion also yields entirely while airborne, so the rig's built-in Animate
	script can show its jump and fall animations without a walk blending against
	them at the same Movement priority.
]]
local MovementAnimator = {}

-- Locomotion is suppressed entirely in these; the character is not steering.
local SUPPRESSED_BY = {
	STATE.Stunned,
	STATE.Ragdolled,
}

local WALK_ANIM = {
	forward = "walkForward",
	back = "walkBack",
	left = "walkLeft",
	right = "walkRight",
}

-- Sprint sits above the walks so it wins while both would apply.
local PRIORITY = {
	sprint = "Action",
	walkForward = "Movement",
	walkBack = "Movement",
	walkLeft = "Movement",
	walkRight = "Movement",
}

local FADE_TIME = 0.1

local stateHandler = nil
local character = nil
local playing = nil
local connections = {}

--[[
	Airborne, so the rig's own Animate script owns the animation.

	Reads the humanoid rather than STATE.Jumping for the same reason the sprint
	condition reads MoveDirection rather than held keys: being off the ground is
	a physical fact, not a game state. STATE.Jumping is only set when the player
	presses jump, so walking off a ledge would leave a walk animation playing all
	the way down.
]]
local function isAirborne()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.FloorMaterial == Enum.Material.Air
end

local function resolve()
	if not stateHandler or not character then
		return nil
	end

	if stateHandler:HasAny(SUPPRESSED_BY) or isAirborne() then
		return nil
	end

	if stateHandler:HasState(STATE.Sprinting) then
		return "sprint"
	end

	local direction = moveDirection.Relative(character)
	return direction and WALK_ANIM[direction] or nil
end

--[[
	Idempotent: recomputes the desired animation and does nothing unless it
	differs from what is playing. Safe to call every frame, and safe to call
	twice for the same change from both drivers below.
]]
local function apply()
	local desired = resolve()
	if desired == playing then
		return
	end

	if playing then
		animationModule.Stop(playing)
	end
	if desired then
		animationModule.Play(desired, FADE_TIME, true, PRIORITY[desired])
	end

	playing = desired
end

--[[
	Sprint's non-animation consequences, which drifted for the same reason the
	animation did -- they were spelled out inside updateSprinting alongside the
	decision itself, so they fired on redundant updates and not on state changes
	that came from elsewhere.
]]
local function onSprintChanged(isActive)
	if isActive then
		camModule.EnableSprintPOV()
	else
		camModule.DisableSprintPOV()
	end

	local remote = Services.ServerEvents:FindFirstChild("OnSprint")
	if remote then
		remote:FireServer(isActive and "start" or "stop")
	end
end

function MovementAnimator.Start(newStateHandler, newCharacter)
	MovementAnimator.Stop()

	stateHandler = newStateHandler
	character = newCharacter

	-- Two drivers, both landing on the same idempotent apply().
	--
	-- Changed covers state transitions with no frame of latency. Heartbeat
	-- covers direction, which is not a state change at all -- turning from W to
	-- A never touches the state table, so a signal alone would miss it.
	local onChanged = stateHandler.Changed:Connect(function(state, isActive)
		if state == STATE.Sprinting then
			onSprintChanged(isActive)
		end
		apply()
	end)
	table.insert(connections, onChanged)

	table.insert(connections, RunService.Heartbeat:Connect(apply))
end

function MovementAnimator.Stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)

	if playing then
		animationModule.Stop(playing)
	end

	stateHandler = nil
	character = nil
	playing = nil
end

return MovementAnimator
