local SeismicSlam = {}

SeismicSlam.Config = {
	name = "SeismicSlam",
	type = "Damage",
	blockable = true,
	knocksBack = false,
	duration = 2,
	damage = 25,
	targetType = "free",
	hitboxType = "cone",
	hitboxParams = {
		range = 50,
		angle = 60,
	},
	stunTime = 1,
}

function SeismicSlam:Cast(combatHandler, animName) end

return SeismicSlam
