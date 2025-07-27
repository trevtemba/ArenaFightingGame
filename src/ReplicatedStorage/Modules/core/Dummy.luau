local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HitboxHandler = require(script.Parent.HitboxHandler)
local AnimationHandler = require(ReplicatedStorage.Modules.core.AnimationHandler)
local CollisionManager = require(ReplicatedStorage.Modules.core.CollisionManager)
local CombatHandler = require(ReplicatedStorage.Modules.core.CombatHandler)
local FXHandler = require(ReplicatedStorage.Modules.core.FXHandler)
local PhysicsHandler = require(ReplicatedStorage.Modules.core.PhysicsHandler)
local STATE = require(ReplicatedStorage.Modules.core.State)
local StateHandler = require(ReplicatedStorage.Modules.core.StateHandler)
local UIHandler = require(ReplicatedStorage.Modules.core.UIHandler)
local DummyData = require(ReplicatedStorage.Modules.data.DummyData)

local ATTACK_STUN_TIME = 0.75

local Dummy = {}
Dummy.__index = Dummy

-- CLASS SETUP --

function Dummy.new()
	local self = setmetatable({}, Dummy)

	-- PROPERTIES
	self.name = ""
	self.character = nil
	self.humanoid = nil
	self.teir = 0
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

	return self
end

function Dummy:Init(dummyType, rig)
	self.character = rig
	self.humanoid = rig:FindFirstChild("Humanoid")
	self.alive = true

	local config = DummyData[dummyType]
	if not config then
		warn(string.format("Invalid enemy config for type %s", dummyType))
		return
	end

	self.name = config.name
	self.currentHP = config.health
	self.maxHP = config.health
	self.teir = 0

	self.humanoid.WalkSpeed = config.speed
	self.humanoid.DisplayName = config.name

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
	self.physicsHandler = PhysicsHandler.new(self.character, "Enemy", nil)
	self.stateHandler = StateHandler.new()

	self:SetState(STATE.Idle)
	CollisionManager:SetCollisionGroupEntities(self.character)
	print(string.format("✅ Built %s enemy (%s)", dummyType, self.name))
	print(self)
end

function Dummy:MeleeAttack()
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

function Dummy:Flinch()
	self.animationHandler:StopAll()
	local track1 = "impactleft"
	local track2 = "impactright"

	-- Randomly choose one of the impact animations
	local chosenTrack = math.random(1, 2) == 1 and track1 or track2

	if chosenTrack then
		self.animationHandler:Play(chosenTrack, 0.1, 2)
	end
end

function Dummy:TakeDamage(attackData)
	if self.combatHandler then
		self.combatHandler:TakeDamage(attackData)
	end
end

return Dummy
