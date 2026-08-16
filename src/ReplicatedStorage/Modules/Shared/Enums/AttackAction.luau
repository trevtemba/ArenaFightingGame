--!strict
--[[
	The kind of hit an attack delivers.

	This value is decided on the server (CombatHandler / abilities), travels to
	the victim through AttackData, and is then read back by the client to pick a
	hit animation (effects/General/defaultHit) and a camera reaction
	(effects/General/fireCamera).

	Because producers and consumers sit on opposite sides of a remote, a typo in
	either one fails silently -- the branch simply never runs. Every value below
	is produced somewhere; consumers should compare against these members rather
	than against string literals.
]]

local AttackAction = {
	-- Ground melee
	Default = "default", -- ordinary combo hit, no knockback
	Knockback = "knockback", -- combo ender

	-- Air combo
	Knockup = "knockup", -- launcher, starts the air combo
	AirContinue = "aircontinue", -- mid-air combo continuation
	DownM1 = "downm1", -- light hit that ends the air combo
	DownSlam = "downslam", -- air combo ender, slams the victim down

	-- Heavy attacks
	AttackHeavyGround = "attackHeavyGround",
	AttackHeavyAir = "attackHeavyAir", -- the dive slam
}

export type AttackAction =
	"default"
	| "knockback"
	| "knockup"
	| "aircontinue"
	| "downm1"
	| "downslam"
	| "attackHeavyGround"
	| "attackHeavyAir"

return AttackAction
