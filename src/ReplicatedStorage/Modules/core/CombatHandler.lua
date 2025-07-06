local RagdollHandler = require(script.Parent:WaitForChild("RagdollHandler"))
local StunModule = require(script.Parent:WaitForChild("stunHandler"))

local CombatHandler = {}
CombatHandler.__index = CombatHandler

function CombatHandler.new(owner)
	local self = setmetatable({}, CombatHandler)
	self.owner = owner -- Reference to the player or npc that owns this handler
	self.ownerHumanoid = owner.character:FindFirstChildOfClass("Humanoid")
	self.combo = 1
	self.maxCombo = 3
	self.comboResetTime = 1.5 -- Seconds to reset combo
	self.lastAttackTime = 0
	
	return self
end

function CombatHandler:CanAttack()
	return self.owner.alive
		and not self.owner.state.attacking
		and not self.owner.state.stunned
end

function CombatHandler:Attack(target)
	if not self:CanAttack() then return end

	local now = os.clock()

	-- Reset combo if player waited too long
	if now - self.lastAttackTime > self.comboResetTime then
		self.combo = 1
	end

	local animName = "m" .. tostring(self.combo)
	self.lastAttackTime = now
	self.owner.state.attacking = true

	-- Play animation
	self.owner.animationHandler:Play(animName, 0.1, 2)

	-- Deal damage on hit marker
	self.owner.animationHandler:ConnectMarker(animName, "Hitbox", function()
		self:ApplyDamage(target)
	end)

	-- Reset attacking state when animation ends
	self.owner.animationHandler:ConnectStopped(animName, function()
		self.owner.state.attacking = false

		-- Increment combo or loop back
		if self.combo < self.maxCombo then
			self.combo += 1
		else
			self.combo = 1
		end
	end)
end

function CombatHandler:ApplyDamage(target)
	if not target or not target.combatHandler then return end

	local base = self.owner.stats.attackDmg or 10
	local pierce = self.owner.stats.pierce or 0
	local durability = target:GetStat("durability") or 0
	local dmg = math.max(0, base - math.max(0, durability - pierce))

	target:TakeDamage(dmg, pierce)
	self.owner.fxHandler:PlaySound("slash")
end

function CombatHandler:TakeDamage(damage, pierce, stunTime)

	self:Stun(stunTime)
	local durability = self.owner.stats["durability"]
	local multiplier =	nil
	local totalDamage = nil

	if durability > pierce then
		multiplier = (durability - pierce) / 100
		totalDamage = damage - (damage * multiplier)
	elseif durability < pierce then
		multiplier = (pierce - durability) / 100
		totalDamage = damage + (damage * multiplier)
	else
		totalDamage = damage
	end
	
	if self.owner.state.blocking then
		totalDamage = totalDamage * 0.1
	end

	self.owner.currentHP = math.max(self.owner.currentHP - totalDamage, 0)
	self.ownerHumanoid.Health = math.clamp(self.owner.currentHP, 0, self.ownerHumanoid.MaxHealth)
	
	print(string.format("%s took %d damage", self.owner.name, totalDamage))
	self.owner.fxHandler:PlaySound("impact")
	self.owner.fxHandler:PlayParticle("impact")

	if self.owner.currentHP <= 0 then
		self:Knock()
	end
end

function CombatHandler:Stun(stunTime)
	local stunResist = self.owner.stats["stunResist"]
	local totalStunTime = nil
	
	if stunResist > 0 then
		totalStunTime = stunTime - (stunTime * (stunResist / 100))
	else
		totalStunTime = stunTime
	end

	StunModule.Stun(self.ownerHumanoid, totalStunTime)

end

function CombatHandler:Knock()
	RagdollHandler:Ragdoll(self.owner.character)
	self.owner.state["knocked"] = true
end

function CombatHandler:Die()
	self.owner.alive = false
	self.owner.animationHandler:Play("death")
	self.owner.fxHandler:PlaySound("death")
	self.owner.state.dead = true
end

return CombatHandler
