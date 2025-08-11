return {
	["gs001"] = { name = "Greatsword", stats = { attackDmg = 15 } },
	["ms001"] = { name = "Mage Staff", stats = { magicDmg = 15 } },
	["sh001"] = { name = "Shield", stats = { durability = 10 } },
	["gh001"] = { name = "Giant's Heart", stats = { health = 150 } },
	["sg001"] = { name = "Steel Gauntlet", stats = { critChance = 20 } },

	-- === OFFENSIVE FUSIONS ===
	["gs001+gs001"] = {
		name = "Titanblade",
		stats = { attackDmg = 34 },
		passive = "Every 3rd attack deals double damage.",
	},

	["ms001+ms001"] = {
		name = "Supernova",
		stats = { magicDmg = 34 },
		passive = "Spells burn enemies for 5 magic damage over 3s.",
	},

	["sg001+sg001"] = {
		name = "Phantom Gauntlet",
		stats = { critChance = 50 },
		passive = "Critical hits reduce enemy defense by 20% for 3s.",
	},

	["gs001+sg001"] = {
		name = "Executioner's Edge",
		stats = { attackDmg = 18, critChance = 25 },
		passive = "Crits apply bleed, dealing 10 damage over 4s.",
	},

	["ms001+sg001"] = {
		name = "Arcane Fist",
		stats = { magicDmg = 17, critChance = 25 },
		passive = "Spells can crit, dealing 150% damage.",
	},

	-- === DEFENSIVE FUSIONS ===
	["sh001+sh001"] = {
		name = "Fortress",
		stats = { durability = 23 },
		passive = "Gain a 10% damage reduction shield every 10s.",
	},

	["gh001+gh001"] = {
		name = "Colossus Heart",
		stats = { health = 340 },
		passive = "Heal 2% max HP every second out of combat.",
	},

	["sh001+gh001"] = {
		name = "Stoneheart",
		stats = { durability = 12, health = 165 },
		passive = "Taking damage grants 5% bonus defense for 4s (stacks).",
	},

	["sh001+sg001"] = {
		name = "Crushing Fist",
		stats = { durability = 12, critChance = 25 },
		passive = "Critical hits stun enemies for 0.5s (1.5s cooldown).",
	},

	-- === HYBRID / UTILITY FUSIONS ===
	["gs001+ms001"] = {
		name = "Spellblade",
		stats = { attackDmg = 17, magicDmg = 17 },
		passive = "Basic attacks trigger a magic explosion every 3s.",
	},

	["gs001+sh001"] = {
		name = "Ironbreaker",
		stats = { attackDmg = 18, durability = 12 },
		passive = "On hit, reduce enemy damage by 10% for 2s.",
	},
}
