-- Modules/Champion.lua
local Champion = {}
Champion.__index = Champion

function Champion.new(data)
	local self = setmetatable({}, Champion)

	self.name = data.name
	self.hp = data.hp
	self.energy = data.energy
	self.durability = data.durability
	self.attackDmg = data.attackDmg
	self.magicDmg = data.magicDmg
	self.attackSpeed = data.attackSpeed
	self.attackCooldown = data.attackCooldown
	self.attackHeavyCooldown = data.attackHeavyCooldown
	self.pierce = data.pierce
	self.critChance = data.critChance
	self.critMultiplier = data.critMultiplier
	self.speed = data.speed
	self.range = data.range

	self.ranged = data.ranged
	self.attackDmgType = data.attackDmgType
	self.abilities = data.abilities or {}
	self.cooldowns = data.cooldowns
	self.passive = data.passive

	return self
end

function Champion:UseAbility(slot, target)
	local ability = self.abilities[slot]
	if ability and ability.Cast then
		ability:Cast(self, target)
	end
end

function Champion:GetStat(stat)
	return self[stat]
end

return Champion
