local WeldHelper = require(script.Parent:WaitForChild("WeldHelper"))
local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))
local FXHandler = require(script.Parent:WaitForChild("FXHandler"))
local CombatHandler = require(script.Parent:WaitForChild("CombatHandler"))

local Game = require(script.Parent:WaitForChild("Game"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	self.ranged = champion.ranged
	self.alive = true

	--Modules
	self.animationHandler = nil
	self.fxHandler = nil
	self.combatHandler = nil

	-- Runtime-modifiable stats
	self.stats = {
		durability = champion.durability,
		attackDmg = champion.attackDmg,
		magicDmg = champion.magicDmg,
		attackSpeed = champion.attackSpeed,
		attackCooldown = champion.attackCooldown,
		pierce = champion.pierce,
		range = champion.range,
		critChance = 0,
		stunResist = 0,
	}

	-- Combat state
	self.maxHP = champion.hp
	self.currentHP = champion.hp
	self.maxEnergy = champion.energy
	self.currentEnergy = champion.energy
	self.cooldowns = champion.cooldowns
	self.state = {
		blocking = false,
		dashing = false,
		attacking = false,
		stunned = false,
		silenced = false,
		channeling = false,
		knocked = false,
	}
	self.statusEffects = {
		["stunned"] = { duration = 2, expiresAt = os.clock() + 2 },
		["burning"] = { duration = 5, dps = 10 },
	}

	self:Initialize()

	return self
end

function Player:Damage(roundNum, enemyHP)
	self.health = self.health - (roundNum + enemyHP / 10)
end

function Player:Impact()
	self.state.stunned = true
	local track1 = "impactleft"
	local track2 = "impactright"

	-- Randomly choose one of the impact animations
	local chosenTrack = math.random(1, 2) == 1 and track1 or track2

	if chosenTrack then
		self.animationHandler:Play(chosenTrack, 0.1, 2)
		self.fxHandler:PlaySound("impact")
		self.fxHandler:PlayParticle("impact")
		self.animationHandler:ConnectStopped(chosenTrack, function()
			self.state.stunned = false
		end)
	end
end

--TODO
function Player:Attack(target)
	if self.combatHandler then
		self.combatHandler:Attack(target)
	end
end

function Player:TakeDamage(amount, pierce, stunTime)
	if self.combatHandler then
		self.combatHandler:TakeDamage(amount, pierce, stunTime)
	end
	self:Impact()
end

-- TODO

function Player:Initialize()
	-- load asset handlers
	self.animationHandler = AnimationHandler.new(self.character)
	self.fxHandler = FXHandler.new(self.character)
	self.combatHandler = CombatHandler.new(self)

	-- setup ragdoll
	local humanoid = self.character:FindFirstChildOfClass("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.BreakJointsOnDeath = false
end

function Player:GetStat(stat)
	-- First check dynamic player-modified stats
	if self.stats and self.stats[stat] ~= nil then
		return self.stats[stat]
	end

	-- Fall back to champion base stat
	return self.champion and self.champion:GetStat(stat)
end

function Player:BindCharacterEvents()
	local gameInstance = Game:GetInstance()

	-- Update reverse lookup map
	gameInstance:UnregisterCharacter(self.character)
	gameInstance:RegisterPlayer(self)

	-- Rebind animation/FX handlers to new animator or character parts
	if self.animationHandler then
		self.animationHandler:SetCharacter(self.character)
	end
	if self.fxHandler then
		self.fxHandler:SetCharacter(self.character)
	end

	-- Reconnect humanoid death listener
	local humanoid = self.character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			self:OnDeath()
		end)
	end
end

function Player:GetTargetFromCharacter(model)
	local gameInstance = Game:GetInstance()

	for _, player in pairs(gameInstance:Get("alivePlayers")) do
		if player.character == model then
			return player
		end
	end
	return nil
end

return Player
