local STATE = require(script.Parent.Enums.State)

--[[
	One place where "which states block which actions" is written down.

	These lists used to live inline in three files -- inputStateHandler:CanDo,
	MovementHandler:CanSprint/CanDash, and CombatHandler's five Can* methods --
	so adding a state or changing a rule meant remembering to edit all of them,
	and forgetting was silent.

	This does NOT merge client and server authority. Each side still keeps its
	own state and evaluates these rules against it independently; the server
	never reads client state, so nothing here weakens validation. Only the rule
	*data* is shared, not the state.

	`server` and `client` are deliberately separate columns rather than one
	merged list, because the two genuinely differ and the differences are
	intentional:

	  - The client self-blocks re-entry on Dashing, Jumping and SoulCasting so a
	    repeated keypress cannot restart an action already in flight. The server
	    has no reason to care. Sprinting is the exception -- see its entry.
	  - The client omits Stunned from several lists because CanDo checks the
	    character's Stunned attribute up front, which already covers every
	    action.
	  - Walking and Jumping are client-only; the server has no rule for them.
	    CanStun is server-only -- it gates whether a stun *lands*, not whether an
	    action starts.

	Merging the two columns would change behaviour in both directions, so they
	stay side by side. The point is that the divergences are now visible and
	reviewable in one place instead of scattered across three files.
]]
local ActionRules = {}

-- Evaluated by inputStateHandler:CanDo against client-predicted state.
ActionRules.client = {
	[STATE.Attacking] = {
		-- Blocking is deliberately absent, matching the server. Attacking out of
		-- a block is intended: the player should not have to release F first.
		-- inputHandler drops its own Blocking state to match, and attackDone
		-- resumes the block if F is still down.
		STATE.Casting,
		STATE.AttackingHeavy,
	},
	[STATE.AttackingHeavy] = {
		STATE.Casting,
		STATE.Attacking,
		STATE.AttackingHeavy,
	},
	[STATE.Casting] = {
		STATE.Casting,
		STATE.Stunned,
	},
	[STATE.SoulCasting] = {
		STATE.Casting,
		STATE.SoulCasting,
	},
	[STATE.Blocking] = {
		STATE.Attacking,
		STATE.Blocking,
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Sprinting] = {
		-- Deliberately NOT self-blocking. It used to list Sprinting, so any
		-- updateSprinting() call during a sprint evaluated shouldSprint = false
		-- and removed the state -- which stopped the sprint animation while the
		-- player was still sprinting. Re-entry is now a silent no-op instead.
		-- Jumping is deliberately absent: sprint speed carries through the air.
		-- The sprint *animation* still yields mid-air, but that is handled by
		-- movementAnimator's airborne check, not by dropping the state.
		-- Landing ends the sprint by revoking the request in inputHandler, not
		-- by blocking the state here.
		STATE.InAirCombo,
		STATE.Attacking,
		STATE.AttackingHeavy,
		STATE.Casting,
		STATE.Blocking,
		STATE.Dashing,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Dashing] = {
		STATE.Dashing,
		STATE.InAirCombo,
		STATE.Attacking,
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Walking] = {
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Jumping] = {
		STATE.Jumping,
		STATE.Attacking,
		STATE.AttackingHeavy,
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	},
}

-- Evaluated by the server handlers against authoritative state.
ActionRules.server = {
	[STATE.Attacking] = {
		STATE.Attacking,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.AttackingHeavy] = {
		STATE.Attacking,
		STATE.AttackingHeavy,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Casting] = {
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Blocking] = {
		STATE.Attacking,
		STATE.AttackingHeavy,
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Sprinting] = {
		STATE.Attacking,
		STATE.Casting,
		STATE.Blocking,
		STATE.Dashing,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	[STATE.Dashing] = {
		STATE.Attacking,
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	},
	-- Whether an incoming stun lands, not whether an action may start.
	[STATE.Stunned] = {
		STATE.Hyperarmor,
		STATE.Ragdolled,
	},
}

-- Shared so a missing rule does not allocate a throwaway table on every check.
-- Never mutate this.
local NO_RULE = table.freeze({})

--[[
	Blocking states for `action`, or an empty list when that side has no rule --
	which means unrestricted, matching the old fall-through behaviour when an
	action matched none of the if/elseif branches.
]]
function ActionRules.For(realm, action)
	return realm[action] or NO_RULE
end

return ActionRules
