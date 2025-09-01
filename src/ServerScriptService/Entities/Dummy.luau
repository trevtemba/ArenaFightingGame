local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)

local TableToString = require(Services.SharedUtils:WaitForChild("TableToString"))

local CollisionManager = require(Services.EntityUtils.CollisionManager)
local AnimationHandler = require(Services.EntityHandlers.AnimationHandler)
local UIHandler = require(Services.EntityHandlers.UIHandler)
local CombatHandler = require(Services.EntityHandlers.CombatHandler)
local MovementHandler = require(Services.EntityHandlers.MovementHandler)
local PhysicsHandler = require(Services.EntityHandlers.PhysicsHandler)
local SoulHandler = require(Services.EntityHandlers.SoulHandler)
local StateHandler = require(Services.EntityHandlers.StateHandler)

local DummyData = require(Services.Data.DummyData)
local STATE = require(Services.Enums.State)

local Dummy = {}
Dummy.__index = Dummy

function Dummy.new(rig, type)
	local self = setmetatable({}, Dummy)

	-- Game properties
	self.name = type .. "Dummy"
	self.health = 100
	self.type = type
	self.soulType = DummyData[type].soulType
	self.tier = 1
	self.xp = 0
	self.character = rig
	self.alive = true

	--Modules
	self.animationHandler = nil
	self.uiHandler = nil
	self.combatHandler = nil
	self.movementHandler = nil
	self.physicsHandler = nil
	self.stateHandler = nil
	self.soulHandler = nil

	-- Runtime-modifiable baseStats
	self.baseStats = {
		durability = DummyData[type].durability,
		attackDmg = DummyData[type].attackDmg,
		magicDmg = DummyData[type].magicDmg,
		attackSpeed = DummyData[type].attackSpeed,
		attackCooldown = DummyData[type].attackCooldown,
		pierce = DummyData[type].pierce,
		critChance = DummyData[type].critChance,
		critMultiplier = DummyData[type].critMultiplier,
		speed = DummyData[type].speed,
		range = DummyData[type].range,
		abilityCooldowns = DummyData[type].cooldowns,
		stunResist = 0,
	}

	self.abilities = DummyData[type].abilities

	-- (Base + Modifier)
	self.stats = {}

	self.damageTypes = {
		attack = DummyData[type].attackDmgType,
		ability = DummyData[type].attackDmgType,
	}

	-- Combat state
	self.maxHP = DummyData[type].hp
	self.currentHP = DummyData[type].hp
	self.maxEnergy = DummyData[type].energy
	self.currentEnergy = DummyData[type].energy

	self.currentPlayers = {}
	self.statusEffects = {
		["stunned"] = { duration = 2, expiresAt = os.clock() + 2 },
		["burning"] = { duration = 5, dps = 10 },
	}

	return self
end

function Dummy:Initialize()
	self:RecalculateStats()

	-- load asset handlers
	self.animationHandler = AnimationHandler.new(self.character)
	self.uiHandler = UIHandler.new(self)
	self.combatHandler = CombatHandler.new(self, "Dummy")
	self.movementHandler = MovementHandler.new(self)
	self.physicsHandler = PhysicsHandler.new(self.character, "Dummy", nil)
	self.stateHandler = StateHandler.new()
	self.soulHandler = SoulHandler.new(self)

	-- setup ragdoll and walkspeed
	local humanoid = self.character:FindFirstChildOfClass("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.BreakJointsOnDeath = false

	CollisionManager:SetCollisionGroupEntities(self.character)

	self:SyncWalkspeed()
end

function Dummy:RecalculateStats()
	for stat, val in pairs(self.baseStats) do
		self.stats[stat] = val
	end
	for slot, cooldown in ipairs(self.stats.abilityCooldowns) do
		self.character:SetAttribute("abilityCd" .. tostring(slot), cooldown)
	end
end

-- Apply incremental stat change (e.g. temporary buff)
function Dummy:ApplyStat(stat, val)
	self.stats[stat] = (self.stats[stat] or 0) + val
end

function Dummy:Attack(spaceHeld)
	if self.combatHandler then
		self.combatHandler:HandleAttackInput(spaceHeld)
	end
end

function Dummy:Activate()
	if self.type == "attacking" then
		task.defer(function()
			while self.character:FindFirstChildOfClass("Humanoid") do
				self:Attack(false)
				task.wait(0.05)
			end
		end)
	elseif self.type == "blocking" then
		task.defer(function()
			while self.character:FindFirstChildOfClass("Humanoid") do
				if not self.stateHandler:HasState(STATE.Blocking) then
					self.combatHandler:EnableBlock()
				end
				task.wait(0.1)
			end
		end)
	elseif self.type == "uptilt" then
		task.defer(function()
			while self.character:FindFirstChildOfClass("Humanoid") do
				if self.combatHandler.combo < self.combatHandler.maxCombo then
					self:Attack(true)
					if self.stateHandler:HasState(STATE.InAirCombo) then
						task.wait(0.1)
					else
						task.wait(1.1)
					end
				elseif self.combatHandler.combo >= self.combatHandler.maxCombo then
					self:Attack(false)
					task.wait(1.1)
				end
			end
		end)
	end
end

function Dummy:Cast(abilitySlot)
	if self.combatHandler then
		self.combatHandler:HandleCastInput(abilitySlot)
	end
end

function Dummy:SoulCast()
	if self.combatHandler then
		self.soulHandler:Cast()
	end
end

function Dummy:Block(activate)
	if self.combatHandler then
		if activate then
			self.combatHandler:EnableBlock()
		else
			self.combatHandler:DisableBlock()
		end
	end
end

function Dummy:TakeDamage(attackData) --todo, enemyposition so we can make blocking only work if u are facing attacker
	if self.combatHandler then
		if self.stateHandler:HasState("blocking") then
			if attackData.blockable then
				if attackData.blockable360 then
					self.combatHandler:BlockDamage()
				else
					if self.combatHandler:CanBlock180(attackData.attackerPosition) then
						self.combatHandler:BlockDamage()
					else
						self.combatHandler:TakeDamage(attackData)
					end
				end
			else
				self.combatHandler:BreakBlock(attackData.attackAction, attackData.attackerLookVector)
			end
		else
			self.combatHandler:TakeDamage(attackData)
		end
	end
end

function Dummy:SetPlayerTable(plrObjs)
	for _, plrObj in pairs(plrObjs) do
		self.currentPlayers[plrObj.character] = plrObj
	end
end

function Dummy:GetPlayerFromCharacter(character)
	local player = self.currentPlayers[character]

	if player then
		return self.currentPlayers[character]
	else
		print("Could not get enemy from Enemy rig")
		return
	end
end

function Dummy:GetStat(stat)
	-- First check dynamic player-modified baseStats
	if self.stats and self.stats[stat] ~= nil then
		return self.stats[stat]
	end

	-- Fall back to champion base stat
	return self.champion and self.champion:GetStat(stat)
end

function Dummy:SyncWalkspeed()
	if self.stats.speed then
		local humanoid = self.character:FindFirstChildOfClass("Humanoid")
		humanoid.WalkSpeed = self.stats.speed
	end
end

function Dummy:CharDie() end

function Dummy:ReturnDev(devCode)
	if devCode == "state" then
		print("SERVER STATES: " .. TableToString(self.stateHandler:GetAllStates()))
	end
end
return Dummy
