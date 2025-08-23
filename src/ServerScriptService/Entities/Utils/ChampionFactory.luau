local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)

local Champion = require(Services.EntityUtils:WaitForChild("Champion"))
local ChampionsFolder = Services.ServerStorage:WaitForChild("Champions")

local ChampionFactory = {}

function ChampionFactory.newChampion(name)
	local folder = ChampionsFolder:FindFirstChild(name)
	if not folder then
		error("Champion folder '" .. name .. "' not found.")
	end

	-- Load data (stats and config)
	local dataModule = folder:FindFirstChild("Data")
	assert(dataModule, "Missing Data.lua in champion folder: " .. name)
	local data = require(dataModule)

	-- Load passive
	local passiveModule = folder:FindFirstChild("Passive")
	local passive = passiveModule and require(passiveModule)

	-- Load abilities
	local abilities = {}
	local abilitiesFolder = folder:FindFirstChild("Abilities")
	assert(abilitiesFolder, "Missing Abilities folder for champion: " .. name)

	for slot, abilityName in pairs(data.abilities) do
		local abilityModule = abilitiesFolder:FindFirstChild(abilityName)
		assert(abilityModule, `Missing ability module "{abilityName}" in {name}'s Abilities folder`)
		abilities[slot] = require(abilityModule)
	end

	local champion = Champion.new({
		name = name,
		hp = data.hp,
		energy = data.energy,
		durability = data.durability,
		attackDmg = data.attackDmg,
		magicDmg = data.magicDmg,
		attackSpeed = data.attackSpeed,
		attackCooldown = data.attackCooldown,
		pierce = data.pierce,
		critChance = data.critChance,
		critMultiplier = data.critMultiplier,
		speed = data.speed,
		range = data.range,

		ranged = data.ranged,
		attackDmgType = data.attackDmgType,
		abilities = abilities,
		cooldowns = data.cooldowns,
		passive = passive,
	})
	local rig = folder:FindFirstChild(name):Clone()

	return champion, rig
end

return ChampionFactory
