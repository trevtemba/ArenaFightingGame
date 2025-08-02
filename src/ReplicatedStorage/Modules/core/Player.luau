local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))
local FXHandler = require(script.Parent:WaitForChild("FXHandler"))
local UIHandler = require(script.Parent:WaitForChild("UIHandler"))
local CombatHandler = require(script.Parent:WaitForChild("CombatHandler"))
local MovementHandler = require(script.Parent:WaitForChild("MovementHandler"))
local PhysicsHandler = require(script.Parent:WaitForChild("PhysicsHandler"))

local Game = require(script.Parent:WaitForChild("Game"))

local CollisionManager = require(script.Parent.CollisionManager)
local InventoryHandler = require(script.Parent.InventoryHandler)
local ItemHandler = require(script.Parent.ItemHandler)
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
	self.gold = 0
	self.tier = 1
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
	self.itemHandler = nil
	self.stateHandler = nil
	self.inventoryHandler = nil

	-- Runtime-modifiable baseStats
	self.baseStats = {
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

	-- (Base + Modifier)
	self.stats = {}

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
	self:RecalculateStats()

	-- load asset handlers
	self.animationHandler = AnimationHandler.new(self.character)
	self.fxHandler = FXHandler.new(self.character)
	self.uiHandler = UIHandler.new(self)
	self.combatHandler = CombatHandler.new(self, "Player")
	self.movementHandler = MovementHandler.new(self)
	self.physicsHandler = PhysicsHandler.new(self.character, "player", self.userId)
	self.itemHandler = ItemHandler.new(self)
	self.stateHandler = StateHandler.new()
	self.inventoryHandler = InventoryHandler.new(self)

	-- setup ragdoll and walkspeed
	local humanoid = self.character:FindFirstChildOfClass("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.BreakJointsOnDeath = false

	CollisionManager:SetCollisionGroupEntities(self.character)

	self:SyncWalkspeed()
end

function Player:RecalculateStats()
	for stat, val in pairs(self.baseStats) do
		self.stats[stat] = val
	end
	if self.inventoryHandler then
		for _, item in pairs(self.inventoryHandler.activeItems) do
			if item and item.stats then
				for stat, val in pairs(item.stats) do
					self.stats[stat] = (self.stats[stat] or 0) + val
				end
			end
		end
	end
end

-- Apply incremental stat change (e.g. temporary buff)
function Player:ApplyStat(stat, val)
	self.stats[stat] = (self.stats[stat] or 0) + val
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

function Player:TakeDamage(attackData) --todo, enemyposition so we can make blocking only work if u are facing attacker
	if self.combatHandler then
		if self.stateHandler:HasState("blocking") then
			if attackData.blockable then
				self.combatHandler:BlockDamage()
			else
				self.combatHandler:BreakBlock()
			end
		else
			self.combatHandler:TakeDamage(attackData)
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
	-- First check dynamic player-modified baseStats
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

-- ADDERS

function Player:AddHealth(amount)
	self.health += amount
end

function Player:AddGold(amount)
	self.gold += amount
end

function Player:AddRandomComponent()
	if self.itemHandler then
		local randomComponent = self.itemHandler:RollComponent()
		self:AddItemToInventory(randomComponent)
	end
end

function Player:AddItemToInventory(itemId)
	if self.inventoryHandler then
		self.inventoryHandler:AddItem(itemId)
		print(self.inventoryHandler.inventory)
	end
end

function Player:AddRandomArtifact()
	if self.itemHandler then
		print("artifact todo")
	end
end

function Player:SpawnAnvil(type)
	if self.itemHandler then
		self.itemHandler:SpawnAnvil(type)
	end
end

function Player:CharDie() end

return Player
