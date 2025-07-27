return {
	hp = 1000,
	energy = 100,
	durability = 10,
	attackDmg = 20,
	magicDmg = 20,
	attackSpeed = 1,
	attackCooldown = 0.5,
	critChance = 0.25,
	critMultiplier = 1.75,
	pierce = 0,
	speed = 12,
	range = 5,

	ranged = false,
	attackDmgType = "physical",

	abilities = {
		"Seismic Slam",
		"Matrix Uplink",
		"Flamethrower",
		"Overdrive",
	},
	cooldowns = {
		[1] = 3,
		[2] = 3,
		[3] = 3,
		[4] = 25,
	},
}
