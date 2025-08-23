local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)

local RagdollHandler = require(Services.EntityUtils.RagdollHandler)
local HitboxHandler = require(Services.EntityUtils.HitboxHandler)
local StunModule = require(Services.EntityUtils.stunHandler)

local attackDone = Services.ReplicatedStorage.RemoteEvents.Client.attackDone
local castDone = Services.ReplicatedStorage.RemoteEvents.Client.castDone
local inAir = Services.ReplicatedStorage.RemoteEvents.Client.inAir

local clientEffects = Services.ClientEvents.clientEffects

local CollectionService = Services.CollectionService
local ServerStorage = Services.ServerStorage
local Players = Services.Players

local STATE = require(Services.Enums.State)

local attackEvent =
	game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("attack")

local FLINCH_DISTANCE = 3

local CombatHandler = {}
CombatHandler.__index = CombatHandler

function CombatHandler.new(owner, entityType)
	local self = setmetatable({}, CombatHandler)
	self.owner = owner -- Reference to the player or npc that owns this handler
	self.humanoid = owner.character:FindFirstChildOfClass("Humanoid")
	self.attackCooldown = owner.stats.attackCooldown
	self.combo = 1
	self.maxCombo = 5
	self.blockAnimSeq = 1
	self.comboResetTime = 1 -- Seconds to reset combo
	self.lastAttackTime = 0
	self.lastCastTime = {}
	self.airResetTime = 1.5
	self.lastAirAttackTime = 0
	self.bufferedAttack = false
	self.bufferedAttackSpaceHeld = false
	self.bufferDuration = owner.stats.attackCooldown
	self.attackerFloat = nil
	self.targetFloat = nil
	self._attackSessionId = nil
	self._castSessionId = nil
	self._blockBreakSessionId = nil
	self._airFloatCoroutine = nil
	self._m1SlowId = nil
	self._stunSessionId = nil
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

function CombatHandler:HandleCastInput(abilitySlot)
	self:Cast(abilitySlot)
end

function CombatHandler:CanAttack()
	local now = os.clock()
	if self.lastAttackTime then
		local timeSinceLastAttack = now - self.lastAttackTime
		if timeSinceLastAttack < self.owner.stats.attackCooldown then
			return false
		end
	end

	local stateHandler = self.owner.stateHandler
	local blockedStates = {
		STATE.Attacking,
		STATE.Stunned,
		STATE.Ragdolled,
	}

	return not stateHandler:HasAny(blockedStates) and self.owner.alive
end

function CombatHandler:CanCast(abilitySlot)
	local now = os.clock()
	if self.lastCastTime[abilitySlot] then
		local timeSinceLastCast = now - self.lastCastTime[abilitySlot]
		if timeSinceLastCast < self.owner.stats.abilityCooldowns[abilitySlot] then
			return false
		end
	end

	local stateHandler = self.owner.stateHandler
	local blockedStates = {
		STATE.Casting,
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

function CombatHandler:Cast(abilitySlot)
	if not self.humanoid or not self:CanCast(abilitySlot) then
		if self.entityType == "Player" then
			castDone:FireClient(Players:GetPlayerByUserId(self.owner.userId))
		end
		return
	end
	if self.owner.stateHandler:HasState(STATE.Blocking) then
		self:DisableBlock()
	end

	local now = os.clock()
	local animName = "ability" .. tostring(abilitySlot)
	self.owner.stateHandler:SetState(STATE.Casting)

	self.lastCastTime[abilitySlot] = now

	local ability = self.owner.abilities[abilitySlot]

	clientEffects:FireAllClients("initiate", { target = self.owner.character, initiateType = "cast" })
	ability:Cast(self, animName)
end

function CombatHandler:Attack(spaceHeld)
	if not self.humanoid or not self:CanAttack() then
		if self.entityType == "Player" then
			attackDone:FireClient(Players:GetPlayerByUserId(self.owner.userId))
		end
		return
	end
	if self.owner.stateHandler:HasState(STATE.Blocking) then
		self:DisableBlock()
	end

	local now = os.clock()
	local blockable
	local isAirCombo = false
	local knocksBack = false
	local cooldown
	local animName

	self.owner.stateHandler:SetState(STATE.Attacking)

	-- Reset combo if player waited too long
	if now - self.lastAttackTime > self.comboResetTime then
		self.combo = 1
	end
	blockable = self.combo < self.maxCombo
	self.lastAttackTime = now

	cooldown = self.combo < self.maxCombo and self.attackCooldown or (self.attackCooldown * 2)
	knocksBack = self.combo == self.maxCombo
	animName = "m" .. tostring(self.combo)

	-- DETERMINE ATTACK ACTION
	local attackAction = self.combo == self.maxCombo and "knockback" or "default"
	local stunTime = attackAction == "default" and 1 or 3.25

	if spaceHeld then
		if not self.owner.stateHandler:HasState(STATE.InAirCombo) then
			if self.combo < self.maxCombo then
				animName = "knockUp"
				isAirCombo = true
				attackAction = "knockup"
				stunTime = 1.25
			else
				print("combo ender, normal knockback")
			end
		else
			if self.combo < self.maxCombo then
				isAirCombo = true
				attackAction = "aircontinue"
			else
				animName = "airKnockBack"
				isAirCombo = true
				attackAction = "knockback"
				stunTime = 1.5
			end
		end
	else
		if self.owner.stateHandler:HasState(STATE.InAirCombo) then
			if self.combo < self.maxCombo then
				isAirCombo = true
				attackAction = "downm1"
			else
				animName = "downSlam"
				isAirCombo = true
				attackAction = "downslam"
				stunTime = 2.5
			end
		end
	end

	-- Play animation
	self.owner.animationHandler:StopAll()
	self.owner.animationHandler:Play(animName, 0.25, 3, 1, false, "Action3")
	clientEffects:FireAllClients("attackFx", { target = self.owner.character, weapon = "fist", combo = self.combo })
	if self.combo == self.maxCombo then
		self:M1Slow(5)
	else
		self:M1Slow(self.owner.stats.speed)
	end
	-- When starting the attack (before connecting or right at anim start)
	self._attackSessionId = (self._attackSessionId or 0) + 1
	local sessionId = self._attackSessionId

	-- Deal damage on hit marker
	self.owner.animationHandler:ConnectMarker(animName, "fire", function()
		local hitboxSize = ServerStorage:WaitForChild("meleeHitbox").Size
		if self._attackSessionId ~= sessionId then
			return
		end
		local params = {
			attacker = self.owner,
			onHit = function(entity)
				self:ApplyDamage({
					entity = entity,
					blockable = blockable,
					type = "attack",
					knocksBack = knocksBack,
					isAirCombo = isAirCombo,
					abilityDamage = nil,
					attackAction = attackAction,
					stunTime = stunTime,
				})
				if isAirCombo then
					self:handleAirCombo(entity, attackAction)
				end
				if self.entityType == "Player" then
					attackEvent:FireClient(Players:GetPlayerByUserId(self.owner.userId), "attackHit")
				end
			end,
			hitboxTemplate = "meleeHitbox",
			cframe = self.owner.character.PrimaryPart.CFrame * CFrame.new(0, 0, -3),
			size = Vector3.new(hitboxSize.X, hitboxSize.Y, self.owner.stats.range),
			duration = 0.2,
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
	if not self.humanoid or not self:CanBlock() then
		return
	end

	clientEffects:FireAllClients("initiate", { target = self.owner.character, initiateType = "block" })
	self.owner.stateHandler:SetState(STATE.Blocking)
	self.owner.physicsHandler:SetWalkspeed(5)
	clientEffects:FireAllClients(
		"handleEffect",
		{ target = self.owner.character, effectType = "block", activate = true }
	)
end

function CombatHandler:DisableBlock()
	if not self.humanoid then
		return
	end

	self.owner.stateHandler:RemoveState(STATE.Blocking)
	self.owner.physicsHandler:SetWalkspeed(self.owner.stats.speed)
	clientEffects:FireAllClients(
		"handleEffect",
		{ target = self.owner.character, effectType = "block", activate = false }
	)
end

function CombatHandler:BreakBlock(attackAction, attackerLookVector)
	if not self.humanoid then
		return
	end
	self:DisableBlock()
	self:Stun(2, 0)
	print(attackAction)
	self.owner.physicsHandler:SetWalkspeed(0)
	self.owner.animationHandler:StopAll()
	clientEffects:FireAllClients("handleEffect", {
		target = self.owner.character,
		effectType = "blockBreak",
		activate = true,
		ignoreAnim = attackAction == "downslam",
	})
	clientEffects:FireAllClients("defaultHit", {
		target = self.owner.character,
		hitType = "blockBreak",
		attackAction = attackAction,
		knockBack = false,
		attackerLookVector = attackerLookVector,
	})

	self._blockBreakSessionId = (self._blockBreakSessionId or 0) + 1
	local sessionId = self._blockBreakSessionId

	task.delay(2, function()
		if self._blockBreakSessionId ~= sessionId then
			return
		end
		self:RestoreBreakBlock()
	end)
end

function CombatHandler:RestoreBreakBlock()
	if not self.humanoid then
		return
	end
	self._blockBreakSessionId = nil
	clientEffects:FireAllClients(
		"handleEffect",
		{ target = self.owner.character, effectType = "blockBreak", activate = false }
	)
	self.owner.physicsHandler:SetWalkspeed(self.owner.stats.speed)
	self.owner.animationHandler:Stop("blockBreak")
end

function CombatHandler:ApplyDamage(attackData)
	local entity = attackData.entity
	local blockable = attackData.blockable
	local type = attackData.type
	local knocksBack = attackData.knocksBack
	local isAirCombo = attackData.isAirCombo
	local abilityDamage = attackData.abilityDamage
	local attackAction = attackData.attackAction
	local stunTime = attackData.stunTime

	if not entity or not entity.combatHandler then
		return
	end

	local base
	if type == "attack" then
		base = self.owner.stats.attackDmg or 10
	elseif type == "ability" then
		base = abilityDamage
	end

	local pierce = self.owner.stats.pierce or 0
	local crit = self:determineCrit()
	if crit then
		print("hit crit")
	end
	local dmg = base * (crit and self.owner.stats.critMultiplier or 1)
	local dmgType = self.owner.damageTypes[type]
	local lookVector = self.owner.character:FindFirstChild("HumanoidRootPart").CFrame.LookVector

	local newAttackData = {
		damage = dmg,
		pierce = pierce,
		stunTime = stunTime,
		damageType = dmgType,
		type = type,
		crit = crit,
		blockable = blockable,
		knocksBack = knocksBack,
		isAirCombo = isAirCombo,
		hitType = "blunt",
		attackerLookVector = lookVector,
		attackerPhysicsHandler = self.owner.physicsHandler,
		attackAction = attackAction,
	}

	entity:TakeDamage(newAttackData)
end

function CombatHandler:TakeDamage(attackData)
	print(attackData.attackAction)
	if self.entityType == "Player" or self.entityType == "Dummy" then
		if self._blockBreakSessionId then
			self:RestoreBreakBlock()
		end
		self.owner.animationHandler:StopAll()
		self:Stun(attackData.stunTime, 3)
	elseif self.entityType == "Enemy" then
		self.owner.animationHandler:StopAll()
		self.owner:SetState(STATE.Stunned, attackData.stunTime)
	end

	self.owner.stateHandler:RemoveState(STATE.Attacking)
	local targetChar = self.owner.character
	local attackerChar = attackData.attackerPhysicsHandler.character
	local durability = self.owner.stats["durability"]
	local multiplier = nil
	local totalDamage = nil

	if durability > attackData.pierce then
		multiplier = (durability - attackData.pierce) / 100
		totalDamage = attackData.damage - (attackData.damage * multiplier)
	elseif durability < attackData.pierce then
		multiplier = (attackData.pierce - durability) / 100
		totalDamage = attackData.damage + (attackData.damage * multiplier)
	else
		totalDamage = attackData.damage
	end

	self.owner.currentHP = math.max(self.owner.currentHP - totalDamage, 0)
	self.humanoid.Health = math.clamp(self.owner.currentHP, 0, self.humanoid.MaxHealth)

	clientEffects:FireAllClients("defaultHit", {
		target = targetChar,
		hitType = attackData.hitType,
		attackAction = attackData.attackAction,
		knockBack = attackData.knocksBack,
		attackerLookVector = attackData.attackerLookVector,
	})
	if CollectionService:HasTag(attackerChar, "Player") then
		clientEffects:FireClient(
			Players:GetPlayerFromCharacter(attackerChar),
			"fireCamera",
			{ attackAction = attackData.attackAction, victim = false }
		)
	end
	if CollectionService:HasTag(targetChar, "Player") then
		clientEffects:FireClient(
			Players:GetPlayerFromCharacter(targetChar),
			"fireCamera",
			{ attackAction = attackData.attackAction, victim = true }
		)
	end
	if not attackData.isAirCombo then
		if attackData.knocksBack then
			self.owner.physicsHandler:MoveBackward(attackData.attackerLookVector, FLINCH_DISTANCE * 20, 3.5)
		else
			if attackData.type == "attack" then
				attackData.attackerPhysicsHandler:SetWalkspeed(0)
				attackData.attackerPhysicsHandler:MoveForward(attackData.attackerLookVector, FLINCH_DISTANCE)
				task.delay(0.75, function()
					attackData.attackerPhysicsHandler:SetWalkspeed(12)
				end)
			end
			self.owner.physicsHandler:MoveBackward(attackData.attackerLookVector, FLINCH_DISTANCE)
		end
	end
	self.owner.uiHandler:UpdateHealthBar()
	self.owner.uiHandler:ShowDamage(attackData.damage, attackData.damageType, attackData.crit)

	print(string.format("%s took %d damage", self.owner.name, totalDamage))

	if self.owner.currentHP <= 0 then
		if self.entityType == "Enemy" then
			self.owner:Die()
		end
		self:Knock()
	end
end

function CombatHandler:BlockDamage()
	if self.blockAnimSeq == 1 then
		self.blockAnimSeq = 2
	else
		self.blockAnimSeq = 1
	end

	clientEffects:FireAllClients(
		"defaultHit",
		{ target = self.owner.character, hitType = "block", blockAnimSequence = self.blockAnimSeq }
	)
end

function CombatHandler:determineCrit()
	local critChance = self.owner.stats.critChance or 0
	local roll = math.random()

	return roll < critChance
end

function CombatHandler:Stun(stunTime, walkspeed)
	if not self.humanoid or not self:CanStun() then
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

	local sessionId = (self._stunSessionId and self._stunSessionId or 0) + 1
	self._stunSessionId = sessionId
	self.humanoid:SetAttribute("CurrentStunId", sessionId)

	StunModule.Stun(self.humanoid, totalStunTime, walkspeed, sessionId, function()
		self.owner.stateHandler:RemoveState(STATE.Stunned)
	end)
end

function CombatHandler:M1Slow(speed)
	self.owner.physicsHandler:SetWalkspeed(speed)
	local m1SlowDelay = self.combo < self.maxCombo and 1 or 1.5

	-- Increment a unique ID to track this specific slowdown
	self._m1SlowId = (self._m1SlowId or 0) + 1
	local currentId = self._m1SlowId

	task.defer(function()
		while os.clock() - self.lastAttackTime < m1SlowDelay do
			task.wait(0.05)
			-- If a new M1Slow was triggered, abort this one
			if self._m1SlowId ~= currentId then
				return
			end
		end

		-- Only resume walkspeed and fire if still valid
		if self._m1SlowId == currentId then
			self.owner.physicsHandler:SetWalkspeed(self.owner.stats.speed)
			if self.entityType == "Player" then
				attackDone:FireClient(Players:GetPlayerByUserId(self.owner.userId))
			end
		end
	end)
end

function CombatHandler:handleAirCombo(targetEntity, attackAction)
	local attackerRoot = self.owner.character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetEntity.character:FindFirstChild("HumanoidRootPart")
	local attackerState = self.owner.stateHandler
	local targetState = targetEntity.stateHandler

	local function disableInAir()
		self.owner.physicsHandler:ClearAirFloat(self.attackerFloat, self.targetFloat)
		self.attackerFloat = nil
		self.targetFloat = nil

		attackerState:RemoveState(STATE.InAirCombo)
		targetState:RemoveState(STATE.InAirCombo)

		if self.entityType == "Player" then
			inAir:FireClient(Players:GetPlayerByUserId(self.owner.userId), false)
		end
		if CollectionService:HasTag(targetEntity.character, "Player") then
			inAir:FireClient(Players:GetPlayerByUserId(targetEntity.userId), false)
		end

		self._airFloatCoroutine = nil
	end

	if attackAction == "knockup" then
		self.lastAirAttackTime = os.clock()
		attackerState:SetState(STATE.InAirCombo)
		targetState:SetState(STATE.InAirCombo)
		clientEffects:FireAllClients("flashStep", { target = self.owner.character, duration = 0.6 })
		if self.entityType == "Player" then
			inAir:FireClient(Players:GetPlayerByUserId(self.owner.userId), true)
		end
		if CollectionService:HasTag(targetEntity.character, "Player") then
			inAir:FireClient(Players:GetPlayerByUserId(targetEntity.userId), true)
		end

		-- Create floating constraints
		local aAlign, aAlignPart, aAtt0, aAtt1 =
			self.owner.physicsHandler:createAirFloat(self.owner.character, "airFloat", 100)
		local tAlign, tAlignPart, tAtt0, tAtt1 =
			targetEntity.physicsHandler:createAirFloat(targetEntity.character, "airFloat", 20)

		-- Store for reuse
		self.attackerFloat = { align = aAlign, alignPart = aAlignPart, att0 = aAtt0, att1 = aAtt1 }
		self.targetFloat = { align = tAlign, alignPart = tAlignPart, att0 = tAtt0, att = tAtt1 }

		task.delay(0.5, function()
			self.attackerFloat.alignPart.CFrame = attackerRoot.CFrame * CFrame.new(0, 20, 0)
		end)
		self.targetFloat.alignPart.CFrame = targetRoot.CFrame * CFrame.new(0, 20, 0)

		-- Cleanup timer
		if self._airFloatCoroutine then
			task.cancel(self._airFloatCoroutine)
		end
		self._airFloatCoroutine = task.defer(function()
			while os.clock() - self.lastAirAttackTime < self.airResetTime do
				task.wait(0.1)
			end

			disableInAir()
		end)
	elseif attackAction == "aircontinue" then
		-- Offset: attacker moves slightly forward, target moves back
		if self.attackerFloat and self.targetFloat then
			self.attackerFloat.align.Responsiveness = 20
			self.targetFloat.align.Responsiveness = 20
			print("continuing")
			self.lastAirAttackTime = os.clock()
			local aAlignPart = self.attackerFloat.alignPart
			local tAlignPart = self.targetFloat.alignPart
			local attackerLookVector = attackerRoot.CFrame.LookVector
			local distance = 4

			aAlignPart.CFrame = CFrame.new(aAlignPart.Position + attackerLookVector * distance)
			tAlignPart.CFrame = CFrame.new(tAlignPart.Position + attackerLookVector * distance)
		end
	elseif attackAction == "downslam" then
		if self._airFloatCoroutine then
			task.cancel(self._airFloatCoroutine)
		end

		if self.attackerFloat and self.targetFloat then
			self.lastAirAttackTime = os.clock()

			local tAlign = self.targetFloat.align
			local tAlignPart = self.targetFloat.alignPart
			local attackerLookVector = attackerRoot.CFrame.LookVector
			tAlign.Responsiveness = 100

			-- back position
			local backwardOffset = attackerLookVector * 10 -- stud offse
			local newXZPos = tAlignPart.Position + backwardOffset

			-- Raycast downward to find ground height
			local rayOrigin = newXZPos
			-- Downward and backward relative to the attacker’s look vector
			local rayDirection = (attackerLookVector * -0.5 + Vector3.new(0, -1, 0)).Unit * 200

			local groundPos = self.owner.physicsHandler:ReturnRaycastVector(
				rayOrigin,
				rayDirection,
				{ targetEntity.character, self.owner.character }
			)

			-- Step 3: Use result
			if groundPos then
				tAlignPart.Position = Vector3.new(newXZPos.X, groundPos.Y + 3, newXZPos.Z)

				local connection
				connection = game:GetService("RunService").Heartbeat:Connect(function()
					local root = targetEntity.character:FindFirstChild("HumanoidRootPart")
					if root and root.Position.Y <= tAlignPart.Position.Y + 1 then -- adjust tolerance
						connection:Disconnect()

						clientEffects:FireAllClients("slamVFX", {
							target = targetEntity.character,
							position = Vector3.new(newXZPos.X, groundPos.Y, newXZPos.Z),
						})
					end
				end)
			else
				tAlignPart.Position = newXZPos -- fallback if no ground detected
			end

			task.delay(0.5, function()
				disableInAir()
			end)
		end
	elseif attackAction == "airknockback" or attackAction == "knockback" then
		self.lastAirAttackTime = os.clock()
		local tAlignPart = self.targetFloat.alignPart
		local attackerLookVector = attackerRoot.CFrame.LookVector
		local distance = 20

		tAlignPart.CFrame = CFrame.new(tAlignPart.Position + attackerLookVector * distance)

		task.delay(0.5, function()
			disableInAir()
		end)
	elseif attackAction == "downm1" then
		print("downm1")
		disableInAir()
	else
		warn("Invalid air combo action:", attackAction)
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
