--!strict
--[[
	Shared shapes for data that crosses a module or remote boundary.

	AttackData is the important one: it is assembled in CombatHandler:ApplyDamage,
	handed to the victim's TakeDamage, and parts of it are then forwarded to the
	client effect modules. Before this existed the table was built and read in
	four different places with no agreement on which fields were required, so a
	missing field showed up as a nil index deep inside a client effect rather
	than at the call site that forgot it.
]]

local AttackActionEnum = require(script.Parent.Enums.AttackAction)

export type AttackAction = AttackActionEnum.AttackAction

-- Which damage formula and which of the attacker's stats apply.
export type DamageKind = "attack" | "ability"

-- Picks the impact VFX/sound set in effects/General/defaultHit.
export type HitType = "blunt" | "slash" | "block" | "blockBreak"

--[[
	Built by CombatHandler:ApplyDamage, consumed by <entity>:TakeDamage.

	`blockable` is whether a block can stop this at all; `blockable360` waives
	the facing requirement, otherwise the defender must be facing the attacker
	(see CombatHandler:CanBlock180).
]]
export type AttackData = {
	damage: number,
	pierce: number,
	stunTime: number,
	damageType: string,
	type: DamageKind,
	crit: boolean,
	blockable: boolean,
	blockable360: boolean,
	knocksBack: boolean,
	isAirCombo: boolean?,
	hitType: HitType,
	attackerLookVector: Vector3,
	attackerPosition: Vector3,
	attackerPhysicsHandler: any,
	attackAction: AttackAction,
	combo: number?,
}

--[[
	The arguments CombatHandler:ApplyDamage takes. Distinct from AttackData:
	this is what the *caller* supplies, before the attacker's stats, crit roll
	and position are folded in to produce the AttackData above.
]]
export type ApplyDamageParams = {
	entity: any,
	blockable: boolean,
	blockable360: boolean,
	type: DamageKind,
	knocksBack: boolean,
	isAirCombo: boolean?,
	abilityDamage: number?,
	attackAction: AttackAction,
	stunTime: number,
	combo: number?,
}

return {}
