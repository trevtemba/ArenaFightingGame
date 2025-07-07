local RagdollHandler = require(script.Parent:WaitForChild("RagdollHandler"))
local HitboxHandler = require(script.Parent:WaitForChild("HitboxHandler"))
local StunModule = require(script.Parent:WaitForChild("stunHandler"))

local ServerStorage = game:GetService("ServerStorage")
local meleeHitbox = ServerStorage:WaitForChild("meleeHitbox")

local CombatHandler = {}
CombatHandler.__index = CombatHandler

function CombatHandler.new(owner, entityType)
	local self = setmetatable({}, CombatHandler)
	self.owner = owner -- Reference to the player or npc that owns this handler
	self.ownerHumanoid = owner.character:FindFirstChildOfClass("Humanoid")
	self.combo = 1
	self.maxCombo = 3
	self.comboResetTime = 1.5 -- Seconds to reset combo
	self.lastAttackTime = 0
	self.entityType = entityType
	return self
end

function CombatHandler:CanAttack()
	return self.owner.alive and not self.owner.state.attacking and not self.owner.state.stunned
end

function CombatHandler:Attack()
	if not self:CanAttack() then
		return
	end

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
	self.owner.animationHandler:ConnectMarker(animName, "fire", function()
		local hitboxSize = ServerStorage:WaitForChild("meleeHitbox").Size

		local params = {
			attacker = self.owner,
			onHit = function(entity)
				self:ApplyDamage(entity)
			end,
			hitboxTemplate = "meleeHitbox",
			cframe = self.owner.character.PrimaryPart.CFrame * CFrame.new(0, 0, -2),
			size = Vector3.new(hitboxSize.X, hitboxSize.Y, self.owner.stats.range),
			duration = 0.15,
		}

		HitboxHandler:CreatePlrHitbox(params)
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

function CombatHandler:ApplyDamage(entity)
	if not entity or not entity.combatHandler then
		return
	end

	local base = self.owner.stats.attackDmg or 10
	local pierce = self.owner.stats.pierce or 0
	local dmg = base -- TODO: add crit functionality
	entity:TakeDamage(dmg, pierce, 0.75)
	self.owner.fxHandler:PlaySound("attack")
end

function CombatHandler:TakeDamage(damage, pierce, stunTime)
	if self.entityType == "Player" then
		self:Stun(stunTime)
	elseif self.entityType == "Enemy" then
		self.owner:SetState("stunned", stunTime)
	end
	local durability = self.owner.stats["durability"]
	local multiplier = nil
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

	if self.owner.state.blocking and self.owner.state.blocking == true then
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
	local stunResist = self.owner.stats["stunResist"] or 0
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
	if self.entityType == "Player" then
		self.owner.state["knocked"] = true
	else
		self.owner:SetState("knocked")
	end
end

function CombatHandler:Die()
	self.owner.alive = false
	self.owner.animationHandler:Play("death")
	self.owner.fxHandler:PlaySound("death")
	self.owner.state.dead = true
end

return CombatHandler
