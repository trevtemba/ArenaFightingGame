local RagdollHandler = require(script.Parent:WaitForChild("RagdollHandler"))
local HitboxHandler = require(script.Parent:WaitForChild("HitboxHandler"))
local StunModule = require(script.Parent:WaitForChild("stunHandler"))
local attackDone = game:GetService("ReplicatedStorage").RemoteEvents.Client.attackDone

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local meleeHitbox = ServerStorage:WaitForChild("meleeHitbox")
local m1SlowDelay = 0.75

local flinchEvent =
	game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("flinch")

local attackEvent =
	game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("attack")

local CombatHandler = {}
CombatHandler.__index = CombatHandler

function CombatHandler.new(owner, entityType)
	local self = setmetatable({}, CombatHandler)
	self.owner = owner -- Reference to the player or npc that owns this handler
	self.ownerHumanoid = owner.character:FindFirstChildOfClass("Humanoid")
	self.attackCooldown = owner.stats.attackCooldown
	self.combo = 1
	self.maxCombo = 5
	self.comboResetTime = 1.5 -- Seconds to reset combo
	self.lastAttackTime = 0
	self.bufferedAttack = false
	self.bufferDuration = owner.stats.attackCooldown
	self.entityType = entityType
	return self
end

function CombatHandler:HandleAttackInput()
	if self:CanAttack() then
		self:Attack()
	else
		self.bufferedAttack = true

		task.delay(self.bufferDuration, function()
			self.bufferedAttack = false
		end)
	end
end

function CombatHandler:CanAttack()
	local now = os.clock()
	local timeSinceLastAttack = now - self.lastAttackTime

	return self.owner.alive
		and not self.owner.state.attacking
		and not self.owner.state.stunned
		and timeSinceLastAttack >= self.owner.stats.attackCooldown
end

function CombatHandler:CanBlock()
	return self.owner.alive == true and self.owner.state.attacking == false and self.owner.state.stunned == false
end

function CombatHandler:Attack()
	if not self:CanAttack() then
		return
	end
	if self.owner.state.blocking == true then
		self.owner.state.blocking = false
	end

	local now = os.clock()

	-- Reset combo if player waited too long
	if now - self.lastAttackTime > self.comboResetTime then
		self.combo = 1
	end

	local animName = "m" .. tostring(self.combo)
	local cooldown = self.combo < self.maxCombo and self.attackCooldown or (self.attackCooldown * 3)

	self.owner.state.attacking = true
	self.lastAttackTime = now

	-- Play animation
	self.owner.animationHandler:StopAll()
	self.owner.animationHandler:Play(animName, 0, 3, 1, false, "Action3")

	self:M1Slow(2)

	-- Deal damage on hit marker
	self.owner.animationHandler:ConnectMarker(animName, "fire", function()
		local hitboxSize = ServerStorage:WaitForChild("meleeHitbox").Size

		local params = {
			attacker = self.owner,
			onHit = function(entity)
				self:ApplyDamage(entity, true)
				attackEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "attackHit")
				self.owner.physicsHandler:TweenMove(1)
			end,
			hitboxTemplate = "meleeHitbox",
			cframe = self.owner.character.PrimaryPart.CFrame * CFrame.new(0, 0, -2),
			size = Vector3.new(hitboxSize.X, hitboxSize.Y, self.owner.stats.range),
			duration = 0.15,
		}

		HitboxHandler:CreatePlrHitbox(params)
	end)

	task.delay(cooldown, function()
		self.owner.state.attacking = false

		if self.combo < self.maxCombo then
			self.combo += 1
		else
			self.combo = 1
		end

		-- if buffered attack, immediately attack
		if self.bufferedAttack and self:CanAttack() then
			self.bufferedAttack = false
			self:Attack()
		end
	end)
end

function CombatHandler:HandleBlock()
	if not self:CanBlock() then
		return
	end

	if self.owner.state.blocking == false then
		self.owner.state.blocking = true
		self.owner.physicsHandler:SetWalkspeed(5)
		self.owner.animationHandler:Play("block")
	else
		self.owner.state.blocking = false
		self.owner.physicsHandler:SetWalkspeed(self.owner.stats.speed)
		self.owner.animationHandler:Stop("block")
	end
end

function CombatHandler:ApplyDamage(entity, blockable)
	if not entity or not entity.combatHandler then
		return
	end

	local base = self.owner.stats.attackDmg or 10
	local pierce = self.owner.stats.pierce or 0
	local dmg = base -- TODO: add crit functionality

	entity:TakeDamage(dmg, pierce, 1, blockable, self.owner.character)
	if self.combo == self.maxCombo then
		entity.physicsHandler:Knockback(self.owner.character, 40)
	end
	self.owner.fxHandler:PlaySound("attack")
end

function CombatHandler:TakeDamage(damage, pierce, stunTime)
	if self.entityType == "Player" then
		self:Stun(stunTime)
		self:Flinch()
	elseif self.entityType == "Enemy" then
		self.owner:SetState("stunned", stunTime)
		self.owner:Flinch()
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

	self.owner.currentHP = math.max(self.owner.currentHP - totalDamage, 0)
	self.ownerHumanoid.Health = math.clamp(self.owner.currentHP, 0, self.ownerHumanoid.MaxHealth)

	print(string.format("%s took %d damage", self.owner.name, totalDamage))

	if self.owner.currentHP <= 0 then
		self:Knock()
	end
end

function CombatHandler:BlockDamage()
	self.owner.fxHandler:PlaySound("impact")
	self.owner.fxHandler:PlayParticle("block")
end

function CombatHandler:Stun(stunTime)
	self.owner.state.stunned = true
	local stunResist = self.owner.stats["stunResist"] or 0
	local totalStunTime = nil

	if stunResist > 0 then
		totalStunTime = stunTime - (stunTime * (stunResist / 100))
	else
		totalStunTime = stunTime
	end

	StunModule.Stun(self.ownerHumanoid, totalStunTime)
	task.delay(stunTime, function()
		self.owner.state.stunned = false
	end)
end

function CombatHandler:Flinch()
	local track1 = "impactleft"
	local track2 = "impactright"

	-- Randomly choose one of the impact animations
	local chosenTrack = math.random(1, 2) == 1 and track1 or track2

	if chosenTrack then
		self.owner.animationHandler:Play(chosenTrack, 0.1, 2)
		flinchEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "impact")
		self.owner.fxHandler:PlaySound("impact")
		self.owner.fxHandler:PlayParticle("impact")
		print("ahhhhhh")
	end
end

function CombatHandler:M1Slow(speed)
	self.owner.physicsHandler:SetWalkspeed(speed)

	task.spawn(function()
		while os.clock() - self.lastAttackTime < m1SlowDelay do
			task.wait(0.05)
		end
		self.owner.physicsHandler:SetWalkspeed(self.owner.stats.speed)
		attackDone:FireClient(Players:GetPlayerByUserId(self.owner.userId))
	end)
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
