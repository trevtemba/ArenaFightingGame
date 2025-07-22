local RagdollHandler = require(script.Parent:WaitForChild("RagdollHandler"))
local HitboxHandler = require(script.Parent:WaitForChild("HitboxHandler"))
local StunModule = require(script.Parent:WaitForChild("stunHandler"))
local attackDone = game:GetService("ReplicatedStorage").RemoteEvents.Client.attackDone
local clientEffects = game:GetService("ReplicatedStorage").RemoteEvents.Client.clientEffects

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyData = require(ReplicatedStorage.Modules.data.EnemyData)

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
	self.humanoid = owner.character:FindFirstChildOfClass("Humanoid")
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
	local stateHandler = self.owner.stateHandler
	local now = os.clock()
	local timeSinceLastAttack = now - self.lastAttackTime

	local blockedStates = {
		"casting",
		"stunned",
		"ragdolled",
	}

	return not stateHandler:HasAny(blockedStates)
		and self.owner.alive
		and timeSinceLastAttack >= self.owner.stats.attackCooldown
end

function CombatHandler:CanBlock()
	local stateHandler = self.owner.stateHandler

	local blockedStates = {
		"attacking",
		"casting",
		"stunned",
		"ragdolled",
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function CombatHandler:CanStun()
	local stateHandler = self.owner.stateHandler

	local blockedStates = {
		"hyperarmor",
		"ragdolled",
	}

	return not stateHandler:HasAny(blockedStates)
end

function CombatHandler:Attack()
	if not self.humanoid and not self:CanAttack() then
		return
	end
	if self.owner.stateHandler:HasState("blocking") then
		self:DisableBlock()
	end

	local now = os.clock()

	-- Reset combo if player waited too long
	if now - self.lastAttackTime > self.comboResetTime then
		self.combo = 1
	end

	local animName = "m" .. tostring(self.combo)
	local cooldown = self.combo < self.maxCombo and self.attackCooldown or (self.attackCooldown * 3)

	self.owner.stateHandler:SetState("attacking")
	self.lastAttackTime = now

	-- Play animation
	self.owner.animationHandler:StopAll()
	self.owner.animationHandler:Play(animName, 0, 3, 1, false, "Action3")

	self:M1Slow(5)

	-- Deal damage on hit marker
	self.owner.animationHandler:ConnectMarker(animName, "fire", function()
		local hitboxSize = ServerStorage:WaitForChild("meleeHitbox").Size

		local params = {
			attacker = self.owner,
			onHit = function(entity)
				self:ApplyDamage(entity, true, "attack")
				attackEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "attackHit")
			end,
			hitboxTemplate = "meleeHitbox",
			cframe = self.owner.character.PrimaryPart.CFrame * CFrame.new(0, 0, -3),
			size = Vector3.new(hitboxSize.X, hitboxSize.Y, self.owner.stats.range),
			duration = 0.15,
		}

		HitboxHandler:CreatePlrHitbox(params)
	end)

	task.delay(cooldown, function()
		self.owner.stateHandler:RemoveState("attacking")

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

function CombatHandler:EnableBlock()
	if not self.humanoid and not self:CanBlock() then
		return
	end

	self.owner.stateHandler:SetState("blocking")
	self.owner.physicsHandler:SetWalkspeed(5)
	self.owner.animationHandler:Play("block", nil, nil, nil, true, "Action2")
end

function CombatHandler:DisableBlock()
	if not self.humanoid then
		return
	end

	self.owner.stateHandler:RemoveState("blocking")
	self.owner.physicsHandler:SetWalkspeed(self.owner.stats.speed)
	self.owner.animationHandler:Stop("block")
end

function CombatHandler:BreakBlock()
	if not self.humanoid then
		return
	end
	self:DisableBlock()
	--block break logic todo, daze them for 1.53 second
end

function CombatHandler:ApplyDamage(entity, blockable, attackType)
	if not entity or not entity.combatHandler then
		return
	end

	local base = self.owner.stats.attackDmg or 10
	local pierce = self.owner.stats.pierce or 0
	local crit = self:determineCrit()
	if crit then
		print("hit crit")
	end
	local dmg = base * (crit and self.owner.stats.critMultiplier or 1)
	local dmgType = self.owner.damageTypes[attackType]

	entity:TakeDamage(dmg, pierce, 1, dmgType, crit, blockable, "slash")

	if self.combo == self.maxCombo then
		entity.physicsHandler:Knockback(self.owner.character, 200, 2)
	end
	self.owner.fxHandler:PlaySound("attack")
	self.owner.physicsHandler:MoveForward(3)
end

function CombatHandler:TakeDamage(damage, pierce, stunTime, damageType, crit, hitType)
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
	self.humanoid.Health = math.clamp(self.owner.currentHP, 0, self.humanoid.MaxHealth)

	clientEffects:FireAllClients("defaultHit", { target = self.owner.character, hitType = hitType })
	self.owner.physicsHandler:MoveBackward(6)
	self.owner.uiHandler:UpdateHealthBar()
	self.owner.uiHandler:ShowDamage(damage, damageType, crit)

	print(string.format("%s took %d damage", self.owner.name, totalDamage))

	if self.owner.currentHP <= 0 then
		self:Knock()
	end
end

function CombatHandler:BlockDamage()
	clientEffects:FireAllClients("defaultHit", { target = self.owner.character, hitType = "block" })
end

function CombatHandler:determineCrit()
	local critChance = self.owner.stats.critChance or 0
	local roll = math.random()

	return roll < critChance
end

function CombatHandler:Stun(stunTime)
	if not self.humanoid and not self:canStun() then
		return
	end

	self.owner.stateHandler:SetState("stunned")
	local stunResist = self.owner.stats["stunResist"] or 0
	local totalStunTime = nil

	if stunResist > 0 then
		totalStunTime = stunTime - (stunTime * (stunResist / 100))
	else
		totalStunTime = stunTime
	end

	StunModule.Stun(self.humanoid, totalStunTime)
	task.delay(stunTime, function()
		self.owner.stateHandler:RemoveState("stunned")
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
	end
end

function CombatHandler:M1Slow(speed)
	self.owner.physicsHandler:SetWalkspeed(speed)

	task.spawn(function()
		while os.clock() - self.lastAttackTime < m1SlowDelay do
			task.wait(0.05)
		end
		self.owner.physicsHandler:SetWalkspeed(self.owner.stats.speed)
		if self.entityType == "Player" then
			attackDone:FireClient(Players:GetPlayerByUserId(self.owner.userId))
		end
	end)
end

function CombatHandler:Knock()
	RagdollHandler:Ragdoll(self.owner.character)
	if self.entityType == "Player" then
		self.owner.stateHandler:SetState("ragdolled")
	else
		self.owner:SetState("knocked")
	end
end

return CombatHandler
