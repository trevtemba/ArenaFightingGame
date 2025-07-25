local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CollisionManager = require(script.Parent.CollisionManager)
local HitboxHandler = require(script.Parent:WaitForChild("HitboxHandler"))
local CombatHandler = require(script.Parent:WaitForChild("CombatHandler"))
local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))
local FXHandler = require(script.Parent:WaitForChild("FXHandler"))
local UIHandler = require(script.Parent:WaitForChild("UIHandler"))
local PhysicsHandler = require(script.Parent:WaitForChild("PhysicsHandler"))
local EnemyData = require(script.Parent.Parent:WaitForChild("data"):WaitForChild("EnemyData"))

local clientEffects = ReplicatedStorage.RemoteEvents.Client.clientEffects
local StateHandler = require(script.Parent.StateHandler)

local STATE = require(script.Parent:WaitForChild("State"))
local ATTACK_STUN_TIME = 0.5

local Enemy = {}
Enemy.__index = Enemy

-- CLASS SETUP --

function Enemy.new()
	local self = setmetatable({}, Enemy)

	-- PROPERTIES
	self.name = ""
	self.character = nil
	self.humanoid = nil
	self.teir = 0
	self.target = nil
	self.alive = false
	self.active = false
	self.stats = {
		durability = 0,
		damage = 0,
		pierce = 0,
		range = 0,
		attackCooldown = 1,
		critChance = 0,
		speed = 18,
	}

	self.damageTypes = {
		attack = nil,
	}

	-- COMBAT STATE
	self.maxHP = 100
	self.currentHP = 100

	-- HANDLERS
	self.combatHandler = nil
	self.fxHandler = nil
	self.uiHandler = nil
	self.animationHandler = nil
	self.physicsHandler = nil
	self.stateHandler = nil

	-- ASSETS
	self.trail = nil

	-- STATE
	self.attacking = false
	self.damageDebounce = false
	self.lastAttackTime = 0

	-- INTERNALS
	self.hitbox = nil
	self._stunEndTime = nil
	self._facingConn = nil

	return self
end

-- INITIALIZATION --

function Enemy:Init(stage, enemyType, rig)
	self.character = rig
	self.humanoid = rig:FindFirstChild("Humanoid")
	self.alive = true

	local trail = rig:FindFirstChild("VFX"):FindFirstChild("Trail")

	if trail then
		self.trail = trail
	end

	local config = EnemyData[stage] and EnemyData[stage][enemyType]
	if not config then
		warn(string.format("Invalid enemy config for stage %s, type %s", stage, enemyType))
		return
	end

	self.name = config.name
	self.currentHP = config.health
	self.maxHP = config.health
	self.teir = stage

	self.humanoid.WalkSpeed = config.speed
	self.humanoid.DisplayName = ""

	self.stats["durability"] = config.durability
	self.stats["damage"] = config.damage
	self.stats["pierce"] = config.pierce
	self.stats["range"] = config.range or 5
	self.stats["attackCooldown"] = config.cooldown
	self.stats["critChance"] = config.crit
	self.stats["critMultiplier"] = config.critMultiplier
	self.stats["speed"] = config.speed
	self.stats["ranged"] = config.range > 15 and true or false
	self.damageTypes.attack = config.attackDmgType

	if self.humanoid then
		self.humanoid.Health = self.maxHP
	end

	-- load hitbox
	if self.stats["ranged"] == false then -- Melee
		local template = ServerStorage:FindFirstChild("meleeHitbox")
		if template then
			local hitbox = template:Clone()
			hitbox.Size = Vector3.new(hitbox.Size.X, hitbox.Size.Y, self.stats["range"])
			hitbox.Parent = workspace
			self.hitbox = hitbox
		else
			warn("⚠️ meleeHitbox not found in ServerStorage!")
		end
	end

	self.combatHandler = CombatHandler.new(self, "Enemy")
	self.fxHandler = FXHandler.new(self.character)
	self.uiHandler = UIHandler.new(self)
	self.animationHandler = AnimationHandler.new(self.character)
	self.physicsHandler = PhysicsHandler.new(self.character, "enemy", nil)
	self.stateHandler = StateHandler.new()

	self:SetState(STATE.Idle)
	CollisionManager:SetCollisionGroupEntities(self.character)
	print(string.format("✅ Built stage %d %s enemy (%s)", stage, enemyType, self.name))
	print(self)
end

-- STATE --

function Enemy:Update()
	if not self.alive or not self.active then
		return
	end
	if not self.target or not self.target.character then
		return
	end
	if self.stateHandler:HasState(STATE.Knocked) then
		return
	end

	while self.stateHandler:HasState(STATE.Stunned) do
		task.wait(0.2)
	end

	local hrp = self.character:FindFirstChild("HumanoidRootPart")
	local targetHRP = self.target.character:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then
		return
	end

	if self.target.stateHandler:HasState("knocked") then
		self:SetState(STATE.Idle)
		self.character.Humanoid:MoveTo(hrp.Position)
		return
	end

	local distance = (hrp.Position - targetHRP.Position).Magnitude

	if distance > self.stats["range"] then
		self:SetState(STATE.Chasing)
		self:StopFacing()
		self.character.Humanoid:MoveTo(targetHRP.Position)
	else
		local now = os.clock()
		if not self.lastAttackTime then
			self.lastAttackTime = 0
		end

		if now - self.lastAttackTime >= self.stats["attackCooldown"] then
			self:StartFacing()
			self.lastAttackTime = now
			self:SetState(STATE.Attacking)
			self.character.Humanoid:MoveTo(hrp.Position) -- stop movement
		end
	end
end

function Enemy:EvaluateNextState()
	if not self.target or not self.target.character then
		return
	end
	if self.stateHandler:HasState(STATE.Knocked) then
		return
	end

	while self.stateHandler:HasState(STATE.Stunned) do
		task.wait(0.2)
	end

	local hrp = self.character:FindFirstChild("HumanoidRootPart")
	local targetHRP = self.target.character:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then
		return
	end

	if self.target.stateHandler:HasState("knocked") then
		self:SetState(STATE.Idle)
		self.character.Humanoid:MoveTo(hrp.Position)
		return
	end

	local distance = (hrp.Position - targetHRP.Position).Magnitude

	if distance > self.stats["range"] then
		self:SetState(STATE.Chasing)
	else
		self.stateHandler:ClearStates()
		self.stateHandler:SetState(STATE.Idle)
		self:StartFacing()
		self:SetState(STATE.Attacking) -- re-attack if still in range
	end
end

function Enemy:SetState(newState, stunDuration)
	if self.stateHandler:HasState(newState) and (newState ~= STATE.Idle and newState ~= STATE.Stunned) then
		return
	end
	self.stateHandler:ClearStates()
	self.stateHandler:SetState(newState)
	self:StateHandler(newState, stunDuration)
end

function Enemy:StateHandler(stateName, stunDuration)
	if self.attacking == true and stateName ~= STATE.Stunned then
		while self.attacking == true do
			task.wait(0.1)
		end
	end

	if stateName == STATE.Idle then
		self:Idle()
	end
	if stateName == STATE.Chasing then
		self:Chase()
	end
	if stateName == STATE.Attacking then
		self:Attack()
	end
	if stateName == STATE.Stunned then
		self:Stun(stunDuration or 0.75)
	end
	if stateName == STATE.Dead then
		self:Die()
	end
end

function Enemy:Idle()
	self.animationHandler:StopAll()
	self.animationHandler:Play("idle")
end

function Enemy:Chase()
	self.animationHandler:Stop("idle")
	self.animationHandler:PlayRun(self.stats.speed)
end

function Enemy:Attack()
	if self.stateHandler:HasState(STATE.Stunned) then
		return
	end

	self.attacking = true
	self.animationHandler:StopAll()
	self.animationHandler:Play("attack", 0.1)
	self.combatHandler:M1Slow(5, 0.75)
	self.fxHandler:PlaySound("attack")

	if self.stats.ranged == false then
		self.trail.Enabled = true
		self.animationHandler:ConnectMarker("attack", "fire", function()
			self:StopFacing()
			self:MeleeAttack()
		end)
	else
		self.animationHandler:ConnectMarker("attack", "fire", function()
			self:StopFacing()
			self:RangedAttack()
		end)
	end

	self.animationHandler:ConnectStopped("attack", function()
		if self.trail then
			self.trail.Enabled = false
		end
		self.attacking = false
		self:EvaluateNextState()
	end)
end

function Enemy:Stun(duration)
	print("stunned")
	duration = duration or 1.5

	if self.stateHandler:HasState(STATE.Dead) or self.stateHandler:HasState(STATE.Knocked) then
		return
	end

	local now = os.clock()
	self._stunEndTime = now + duration

	self.character.Humanoid:MoveTo(self.character.HumanoidRootPart.Position)
	self:Flinch()

	task.delay(duration, function()
		-- Only reset if no newer stun has occurred
		if os.clock() >= self._stunEndTime and self.stateHandler:HasState(STATE.Stunned) then
			self.stateHandler:ClearStates()
			self:EvaluateNextState()
		end
	end)
end

function Enemy:Die()
	--todo
end

-- AI LOGIC

function Enemy:SetTarget(targetPlayer)
	self.target = targetPlayer
	self.active = true
end

function Enemy:StartAI()
	task.spawn(function()
		while self.alive and self.active do
			self:Update()
			task.wait(0.2)
		end
	end)
end

function Enemy:StartFacing()
	if self._facingConn then
		self._facingConn:Disconnect()
	end

	self._facingConn = RunService.Heartbeat:Connect(function()
		if not self.target or not self.target.character or not self.character or not self.alive then
			return
		end

		local npcCF = self.character:GetPivot()
		local npcPos = npcCF.Position
		local targetPos = self.target.character:GetPivot().Position
		targetPos = Vector3.new(targetPos.X, npcPos.Y, targetPos.Z)

		local goalCF = CFrame.lookAt(npcPos, targetPos)
		local lerpCF = npcCF:Lerp(goalCF, 0.05)

		self.character:PivotTo(lerpCF)
	end)
end

function Enemy:StopFacing()
	if self._facingConn then
		self._facingConn:Disconnect()
		self._facingConn = nil
	end
end

-- ATTACKS --

function Enemy:MeleeAttack()
	local hitboxSize = ServerStorage:WaitForChild("meleeHitbox").Size

	local params = {
		attacker = self,
		target = self.target,
		onHit = function(target)
			local attackData = {
				damage = self.stats.damage,
				pierce = self.stats.pierce,
				stunTime = ATTACK_STUN_TIME,
				damageType = self.damageTypes.attack,
				crit = false,
				blockable = true,
				hitType = "slash",
				attackerLookVector = self.character:FindFirstChild("HumanoidRootPart").CFrame.LookVector,
			}
			target:TakeDamage(attackData)

			self.damageDebounce = true
			print(
				self.name
					.. " hit "
					.. target.name
					.. " for "
					.. self.stats["damage"]
					.. " damage! ("
					.. self.stats["pierce"]
					.. " pierce)"
			)
			task.delay(0.4, function()
				self.damageDebounce = false
			end)
		end,
		hitboxTemplate = "meleeHitbox",
		cframe = self.character.PrimaryPart.CFrame * CFrame.new(0, 0, -2),
		size = Vector3.new(hitboxSize.X, hitboxSize.Y, self.stats["range"]),
		duration = 0.15,
	}
	HitboxHandler:CreateNPCHitbox(params)
end

function Enemy:RangedAttack()
	local params = {
		attacker = self,
		target = self.target,
		projectileTemplate = self.fxHandler:GetProjectile("Projectile"),
		origin = self.character.PrimaryPart.Position,
		targetPosition = self.target.character:WaitForChild("HumanoidRootPart").Position,
		range = self.stats["range"] + 10,
		speed = 80,
		hitRadius = 2,
		onHit = function(target)
			local attackData = {
				damage = self.stats.damage,
				pierce = self.stats.pierce,
				stunTime = ATTACK_STUN_TIME,
				damageType = self.damageTypes.attack,
				crit = false,
				blockable = true,
				knocksBack = false,
				hitType = "blunt",
				attackerLookVector = self.character:FindFirstChild("HumanoidRootPart").CFrame.LookVector,
			}
			target:TakeDamage(attackData)
			self.damageDebounce = true
			print(
				self.name
					.. " attacked "
					.. target.name
					.. " for "
					.. self.stats["damage"]
					.. " damage! ("
					.. self.stats["pierce"]
					.. " pierce)"
			)
			task.delay(0.4, function()
				self.damageDebounce = false
			end)
		end,
		onMiss = function(projectile)
			self:FadeOutProjectile(projectile)
		end,
	}
	self.fxHandler:PlayParticle("Fire")
	HitboxHandler:CreateNPCProjectile(params)
end

function Enemy:TakeDamage(attackData)
	if self.combatHandler then
		self.combatHandler:TakeDamage(attackData)
	end
end

function Enemy:Flinch()
	self.animationHandler:StopAll()
	local track1 = "impactleft"
	local track2 = "impactright"

	-- Randomly choose one of the impact animations
	local chosenTrack = math.random(1, 2) == 1 and track1 or track2

	if chosenTrack then
		self.animationHandler:Play(chosenTrack, 0.1, 2)
	end
end

function Enemy:FadeOutProjectile(projectile)
	local tween = game:GetService("TweenService"):Create(projectile, TweenInfo.new(0.3), { Transparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		projectile:Destroy()
	end)
end

function Enemy:GetStat(stat)
	if self.stats[stat] == nil then
		return
	end

	return self.stats[stat]
end

function Enemy:Destroy()
	self.alive = false
	self.active = false

	if self._animConn then
		self._animConn:Disconnect()
		self._animConn = nil
	end

	if self._facingConn then
		self._facingConn:Disconnect()
		self._facingConn = nil
	end

	if self.hitbox then
		self.hitbox:Destroy()
		self.hitbox = nil
	end
end

return Enemy
