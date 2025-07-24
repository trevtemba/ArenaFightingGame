local RagdollHandler = require(script.Parent:WaitForChild("RagdollHandler"))
local HitboxHandler = require(script.Parent:WaitForChild("HitboxHandler"))
local StunModule = require(script.Parent:WaitForChild("stunHandler"))
local attackDone = game:GetService("ReplicatedStorage").RemoteEvents.Client.attackDone
local inAir = game:GetService("ReplicatedStorage").RemoteEvents.Client.inAir

local clientEffects = game:GetService("ReplicatedStorage").RemoteEvents.Client.clientEffects

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local STATE = require(script.Parent.State)
local EnemyData = require(ReplicatedStorage.Modules.data.EnemyData)

local meleeHitbox = ServerStorage:WaitForChild("meleeHitbox")

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
	self.comboResetTime = 0.9 -- Seconds to reset combo
	self.lastAttackTime = 0
	self.airResetTime = 1
	self.lastAirAttackTime = 0
	self.airFloatCoroutine = nil
	self.bufferedAttack = false
	self.bufferedAttackSpaceHeld = false
	self.bufferDuration = owner.stats.attackCooldown
	self.entityType = entityType
	return self
end

function CombatHandler:HandleAttackInput(spaceHeld)
	if self:CanAttack() then
		self:Attack(spaceHeld)
	else
		self.bufferedAttack = true
		self.bufferedAttackSpaceHeld = spaceHeld
		task.delay(self.bufferDuration, function()
			self.bufferedAttack = false
			self.bufferedAttackSpaceHeld = false
		end)
	end
end

function CombatHandler:CanAttack()
	local now = os.clock()
	local timeSinceLastAttack = now - self.lastAttackTime
	if timeSinceLastAttack < self.owner.stats.attackCooldown then
		return false
	end

	local stateHandler = self.owner.stateHandler
	local blockedStates = {
		STATE.Attacking,
		STATE.Stunned,
		STATE.Ragdolled,
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function CombatHandler:CanBlock()
	local stateHandler = self.owner.stateHandler

	local blockedStates = {
		STATE.Attacking,
		STATE.Casting,
		STATE.Stunned,
		STATE.Ragdolled,
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function CombatHandler:CanStun()
	local stateHandler = self.owner.stateHandler

	local blockedStates = {
		STATE.Hyperarmor,
		STATE.Ragdolled,
	}

	return not stateHandler:HasAny(blockedStates)
end

function CombatHandler:Attack(spaceHeld)
	if not self.humanoid and not self:CanAttack() then
		return
	end
	if self.owner.stateHandler:HasState(STATE.Blocking) then
		self:DisableBlock()
	end

	local now = os.clock()
	local isAirCombo = false
	local airComboAction
	local cooldown
	local animName

	self.owner.stateHandler:SetState(STATE.Attacking)

	-- Reset combo if player waited too long
	if now - self.lastAttackTime > self.comboResetTime then
		self.combo = 1
	end
	self.lastAttackTime = now

	cooldown = self.combo < self.maxCombo and self.attackCooldown or (self.attackCooldown * 2)
	animName = "m" .. tostring(self.combo)

	if spaceHeld then
		if not self.owner.stateHandler:HasState(STATE.InAirCombo) then
			if self.combo < self.maxCombo then
				animName = "knockUp"
				isAirCombo = true
				airComboAction = "knockup"
			else
				print("combo ender, normal knockback")
			end
		else
			if self.combo < self.maxCombo then
				isAirCombo = true
				airComboAction = "continue"
			else
				isAirCombo = true
				airComboAction = "knockback"
			end
		end
	else
		if self.owner.stateHandler:HasState(STATE.InAirCombo) then
			if self.combo < self.maxCombo then
				isAirCombo = true
				airComboAction = "downm1"
			else
				isAirCombo = true
				airComboAction = "downslam"
			end
		end
	end

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
				if isAirCombo then
					self:handleAirCombo(entity, airComboAction)
				end
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
		self.owner.stateHandler:RemoveState(STATE.Attacking)

		if self.combo < self.maxCombo then
			self.combo += 1
		else
			self.combo = 1
		end

		-- if buffered attack, immediately attack
		if self.bufferedAttack and self:CanAttack() then
			self.bufferedAttack = false
			self:Attack(self.bufferedAttackSpaceHeld)
		end
	end)
end

function CombatHandler:EnableBlock()
	if not self.humanoid and not self:CanBlock() then
		return
	end

	self.owner.stateHandler:SetState(STATE.Blocking)
	self.owner.physicsHandler:SetWalkspeed(5)
	self.owner.animationHandler:Play("block", nil, nil, nil, true, "Action2")
end

function CombatHandler:DisableBlock()
	if not self.humanoid then
		return
	end

	self.owner.stateHandler:RemoveState(STATE.Blocking)
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
		self.owner:SetState(STATE.Stunned, stunTime)
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

	self.owner.stateHandler:SetState(STATE.Stunned)
	local stunResist = self.owner.stats["stunResist"] or 0
	local totalStunTime = nil

	if stunResist > 0 then
		totalStunTime = stunTime - (stunTime * (stunResist / 100))
	else
		totalStunTime = stunTime
	end

	StunModule.Stun(self.humanoid, totalStunTime)
	task.delay(stunTime, function()
		self.owner.stateHandler:RemoveState(STATE.Stunned)
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
	local m1SlowDelay = self.combo < self.maxCombo and 1 or 1.5

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

function CombatHandler:handleAirCombo(targetEntity, airComboAction)
	local attackerRoot = self.owner.character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetEntity.character:FindFirstChild("HumanoidRootPart")
	local attackerState = self.owner.stateHandler
	local targetState = targetEntity.stateHandler
	local now = os.clock()

	print(airComboAction)
	if airComboAction == "knockup" then
		self.lastAirAttackTime = os.clock()
		attackerState:SetState(STATE.InAirCombo)
		targetState:SetState(STATE.InAirCombo)

		inAir:FireClient(Players:GetPlayerByUserId(self.owner.userId), true)
		if CollectionService:HasTag(targetEntity.character, "Player") then
			inAir:FireClient(Players:GetPlayerByUserId(targetEntity.userId), true)
		end

		local bp1, bp2 = Instance.new("BodyPosition"), Instance.new("BodyPosition")
		for _, bp in { bp1, bp2 } do
			bp.P = 1200
			bp.MaxForce = Vector3.new(4e4, 4e4, 4e4)
			bp.D = 200
			bp.Name = "AirFloat"
		end
		bp1.Position = attackerRoot.Position + Vector3.new(0, 30, 0)
		bp2.Position = targetRoot.Position + Vector3.new(0, 30, 0)
		bp1.Parent = attackerRoot
		bp2.Parent = targetRoot

		-- Cancel old coroutine if still running
		if self.airFloatCoroutine then
			task.cancel(self.airFloatCoroutine)
		end

		-- Start new coroutine
		self.airFloatCoroutine = task.spawn(function()
			while os.clock() - self.lastAirAttackTime < self.airResetTime do
				task.wait(0.1)
			end

			-- Cleanup float
			bp1:Destroy()
			bp2:Destroy()
			attackerState:RemoveState(STATE.InAirCombo)
			targetState:RemoveState(STATE.InAirCombo)

			inAir:FireClient(Players:GetPlayerByUserId(self.owner.userId), false)
			if CollectionService:HasTag(targetEntity.character, "Player") then
				inAir:FireClient(Players:GetPlayerByUserId(targetEntity.userId), false)
			end

			self.airFloatCoroutine = nil
		end)
	elseif airComboAction == "continue" then
		print("continuing")
		self.lastAirAttackTime = os.clock()
	elseif airComboAction == "downslam" then
	elseif airComboAction == "knockback" then
	elseif airComboAction == "downm1" then
	else
		warn("Invalid air combo action:", airComboAction)
	end
end

function CombatHandler:Knock()
	RagdollHandler:Ragdoll(self.owner.character)
	if self.entityType == "Player" then
		self.owner.stateHandler:SetState(STATE.Ragdolled)
	else
		self.owner:SetState(STATE.Knocked)
	end
end

return CombatHandler
