local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))
local FXHandler = require(script.Parent:WaitForChild("FXHandler"))
local UIHandler = require(script.Parent:WaitForChild("UIHandler"))
local CombatHandler = require(script.Parent:WaitForChild("CombatHandler"))
local MovementHandler = require(script.Parent:WaitForChild("MovementHandler"))
local PhysicsHandler = require(script.Parent:WaitForChild("PhysicsHandler"))

local Game = require(script.Parent:WaitForChild("Game"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollisionManager = require(script.Parent.CollisionManager)
local Soul = require(script.Parent.Soul)
local StateHandler = require(script.Parent.StateHandler)

local Player = {}
Player.__index = Player

function Player.new(plr, champion, rig)
	local self = setmetatable({}, Player)

	-- Game properties
	self.userId = plr.UserId
	self.name = plr.Name
	self.health = 100
	self.xp = 0
	self.champion = champion
	self.character = rig
	self.soul = Soul.new("Engage")
	self.ranged = champion.ranged
	self.alive = true

	--Modules
	self.animationHandler = nil
	self.fxHandler = nil
	self.uiHandler = nil
	self.combatHandler = nil
	self.movementHandler = nil
	self.physicsHandler = nil
	self.stateHandler = nil

	-- Runtime-modifiable stats
	self.stats = {
		durability = champion.durability,
		attackDmg = champion.attackDmg,
		magicDmg = champion.magicDmg,
		attackSpeed = champion.attackSpeed,
		attackCooldown = champion.attackCooldown,
		pierce = champion.pierce,
		critChance = champion.critChance,
		critMultiplier = champion.critMultiplier,
		speed = champion.speed,
		range = champion.range,
		stunResist = 0,
	}

	self.damageTypes = {
		attack = champion.attackDmgType,
	}

	-- Combat state
	self.maxHP = champion.hp
	self.currentHP = champion.hp
	self.maxEnergy = champion.energy
	self.currentEnergy = champion.energy

	self.cooldowns = champion.cooldowns

	self.currentEnemies = {}
	self.statusEffects = {
		["stunned"] = { duration = 2, expiresAt = os.clock() + 2 },
		["burning"] = { duration = 5, dps = 10 },
	}

	self:Initialize()

	return self
end

function Player:Initialize()
	-- load asset handlers
	self.animationHandler = AnimationHandler.new(self.character)
	self.fxHandler = FXHandler.new(self.character)
	self.uiHandler = UIHandler.new(self)
	self.combatHandler = CombatHandler.new(self, "Player")
	self.movementHandler = MovementHandler.new(self)
	self.physicsHandler = PhysicsHandler.new(self.character, "player", self.userId)
	self.stateHandler = StateHandler.new()

	-- setup ragdoll and walkspeed
	local humanoid = self.character:FindFirstChildOfClass("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.BreakJointsOnDeath = false

	CollisionManager:SetCollisionGroupEntities(self.character)

	self:SyncWalkspeed()
end

function Player:Damage(roundNum, enemyHP)
	self.health = self.health - (roundNum + enemyHP / 10)
end

function Player:Attack(target, spaceHeld)
	if self.combatHandler then
		self.combatHandler:HandleAttackInput(target, spaceHeld)
	end
end

function Player:Block(activate)
	if self.combatHandler then
		if activate then
			self.combatHandler:EnableBlock()
		else
			self.combatHandler:DisableBlock()
		end
	end
end

function Player:Dash(direction)
	if self.movementHandler then
		self.movementHandler:HandleDash(direction)
	end
end

function Player:SprintHandler(sprintState)
	if self.movementHandler then
		if sprintState == "start" then
			self.movementHandler:StartSprint()
		elseif sprintState == "stop" then
			self.movementHandler:StopSprint()
		end
	end
end

function Player:TakeDamage(amount, pierce, stunTime, dmgType, crit, blockable, hitType) --todo, enemyposition so we can make blocking only work if u are facing attacker
	if self.combatHandler then
		if self.stateHandler:HasState("blocking") then
			if blockable then
				self.combatHandler:BlockDamage()
			else
				self.combatHandler:BreakBlock()
			end
		else
			self.combatHandler:TakeDamage(amount, pierce, stunTime, dmgType, crit, hitType)
		end
	end
end

function Player:SetEnemyTable(enemies)
	self.currentEnemies = enemies
	print(self.currentEnemies)
end

function Player:GetPlayerFromCharacter(character)
	local gameInstance = Game:GetInstance()

	for _, player in pairs(gameInstance:Get("alivePlayers")) do
		if player.character == character then
			return player
		end
	end
	return nil
end

function Player:GetEnemyFromCharacter(character)
	local enemy = self.currentEnemies[character]

	if enemy then
		return self.currentEnemies[character]
	else
		print("Could not get enemy from Enemy rig")
	end
end

function Player:GetStat(stat)
	-- First check dynamic player-modified stats
	if self.stats and self.stats[stat] ~= nil then
		return self.stats[stat]
	end

	-- Fall back to champion base stat
	return self.champion and self.champion:GetStat(stat)
end

function Player:SyncWalkspeed()
	if self.stats.speed then
		local humanoid = self.character:FindFirstChildOfClass("Humanoid")
		humanoid.WalkSpeed = self.stats.speed
	end
end

function Player:CharDie() end

return Player
