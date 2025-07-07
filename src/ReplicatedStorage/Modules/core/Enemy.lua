local ServerStorage = game:GetService("ServerStorage")
-- local TweenService = game:GetService("TweenService")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitboxHandler = require(script.Parent:WaitForChild("HitboxHandler"))

local RunService = game:GetService("RunService")

local ATTACK_STUN_TIME = 0.25
local DEFAULT_WALKSPEED = 18

local STATES = {
	Idle = "idle",
	Chasing = "chasing",
	Attacking = "attacking",
	Dead = "dead",
}

local EnemyConfig = {
	[1] = {
		melee = { name = "Ranger", health = 150, damage = 10, pierce = 0, range = 4, cooldown = 1, speed = 18 },
		ranged = { name = "Archer", health = 75, damage = 20, pierce = 0, range = 50, cooldown = 1, speed = 15 },
	},
	[2] = {
		melee = { name = "Knight", health = 200, damage = 25, pierce = 0, range = 5, cooldown = 1, speed = 18 },
		ranged = { name = "Crossbowman", health = 100, damage = 30, pierce = 0, range = 20, cooldown = 1, speed = 18 },
	},
	[3] = {
		melee = { name = "Brute", health = 300, damage = 35, pierce = 0, range = 5, cooldown = 1, speed = 18 },
		ranged = { name = "Sniper", health = 150, damage = 40, pierce = 0, range = 25, cooldown = 1, speed = 18 },
	},
	[4] = {
		melee = { name = "Champion", health = 400, damage = 45, pierce = 0, range = 5, cooldown = 1, speed = 18 },
		ranged = { name = "Sorcerer", health = 250, damage = 50, pierce = 0, range = 25, cooldown = 1, speed = 18 },
	},
}

local Enemy = {}
Enemy.__index = Enemy

-- CLASS SETUP --

function Enemy.new()
	local self = setmetatable({}, Enemy)

	-- PROPERTIES
	self.name = ""
	self.health = 100
	self.damage = 5
	self.pierce = 0
	self.range = 5
	self.attackCooldown = 0
	self.model = nil
	self.humanoid = nil
	self.target = nil
	self.ranged = false
	self.speed = 20
	self.alive = false
	self.active = false

	-- ASSETS
	self.animations = {}
	self.sounds = {}
	self.vfx = {}
	self.trail = nil

	-- STATES
	self.attacking = false
	self.state = "idle"
	self.damageDebounce = false
	self.lastAttackTime = 0

	-- INTERNALS
	self.hitbox = nil
	self.overlapParams = nil
	self._animConn = nil
	self._facingConn = nil

	return self
end

-- INITIALIZATION --

function Enemy:Init(stage, enemyType, rig)
	self.model = rig
	self.humanoid = rig:FindFirstChild("Humanoid")
	self.alive = true

	local config = EnemyConfig[stage] and EnemyConfig[stage][enemyType]
	if not config then
		warn(string.format("Invalid enemy config for stage %s, type %s", stage, enemyType))
		return
	end

	self.name = config.name
	self.health = config.health
	self.damage = config.damage
	self.pierce = config.pierce
	self.range = config.range or 5
	self.ranged = config.range > 15 and true or false
	self.speed = config.speed
	self.humanoid.WalkSpeed = config.speed
	self.attackCooldown = config.cooldown

	if self.humanoid then
		self.humanoid.Health = self.health
	end

	-- load anims
	local animFolder = rig:FindFirstChild("Animations")
	local animator = self.humanoid:FindFirstChildOfClass("Animator")

	if animFolder then
		for _, anim in pairs(animFolder:GetChildren()) do
			if anim:IsA("Animation") then
				self.animations[anim.Name] = animator:LoadAnimation(anim)
			end
		end
	end

	-- load sounds
	local soundFolder = rig:FindFirstChild("Sounds")

	if soundFolder then
		for _, sound in pairs(soundFolder:GetChildren()) do
			if sound:IsA("Sound") then
				self.sounds[sound.Name] = sound
			end
		end
	end

	-- load vfx
	local vfxFolder = rig:FindFirstChild("VFX")

	if vfxFolder then
		for _, vfx in pairs(vfxFolder:GetChildren()) do
			if vfx:IsA("Trail") then
				self.trail = vfx
			else
				self.vfx[vfx.Name] = vfx
			end
		end
	end

	-- load hitbox
	if self.range < 15 then -- Melee
		local template = ServerStorage:FindFirstChild("meleeHitbox")
		if template then
			local hitbox = template:Clone()
			hitbox.Size = Vector3.new(hitbox.Size.X, hitbox.Size.Y, self.range)
			hitbox.Parent = workspace
			self.hitbox = hitbox
		else
			warn("⚠️ meleeHitbox not found in ServerStorage!")
		end
	end

	self.overlapParams = OverlapParams.new()
	self.overlapParams.FilterType = Enum.RaycastFilterType.Include
	self.overlapParams.FilterDescendantsInstances = {} -- set when targeting
	self.overlapParams.MaxParts = 10
	self:SetState(STATES.Idle)

	print(string.format("✅ Built stage %d %s enemy (%s)", stage, enemyType, self.name))
end

function Enemy:PreloadAnimations()
	for _, anim in pairs(self.animations) do
		anim:Play(0)
		anim:Stop()
	end
end

-- AI/STATE --

function Enemy:Update()
	if not self.alive or not self.active then
		return
	end
	if not self.target or not self.target.character then
		return
	end

	local hrp = self.model:FindFirstChild("HumanoidRootPart")
	local targetHRP = self.target.character:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then
		return
	end

	if self.target.state["knocked"] == true then
		self:SetState("idle")
		self.model.Humanoid:MoveTo(hrp.Position)
		return
	end

	local distance = (hrp.Position - targetHRP.Position).Magnitude

	if distance > self.range then
		self:SetState("chasing")
		self:StopFacing()
		self.model.Humanoid:MoveTo(targetHRP.Position)
	else
		local now = os.clock()
		if not self.lastAttackTime then
			self.lastAttackTime = 0
		end

		if now - self.lastAttackTime >= self.attackCooldown then
			self:StartFacing()
			self.lastAttackTime = now
			self:SetState("attacking")
			self.model.Humanoid:MoveTo(hrp.Position) -- stop movement
		end
	end
end

function Enemy:SetTarget(targetPlayer)
	self.target = targetPlayer
	self.active = true
	if targetPlayer and targetPlayer.character then
		--print(targetPlayer.character)

		self.overlapParams.FilterDescendantsInstances = { targetPlayer.character }
	end
end

function Enemy:StartAI()
	task.spawn(function()
		while self.alive and self.active do
			self:Update()
			task.wait(0.2)
		end
	end)
end

function Enemy:EvaluateNextState()
	if not self.target or not self.target.character or self.target.state["knocked"] == true then
		return
	end

	local hrp = self.model:FindFirstChild("HumanoidRootPart")
	local targetHRP = self.target.character:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then
		return
	end

	if self.target.state["knocked"] == true then
		self:SetState("idle")
		self.model.Humanoid:MoveTo(hrp.Position)
		return
	end

	local distance = (hrp.Position - targetHRP.Position).Magnitude

	if distance > self.range then
		self:SetState(STATES.Chasing)
	else
		self.state = STATES.Idle
		self:StartFacing()
		self:SetState(STATES.Attacking) -- re-attack if still in range
	end
end

function Enemy:SetState(newState)
	if self.state == newState and newState ~= "idle" then
		return
	end
	self.state = newState

	if newState == "idle" then
		self:PlayAnimation("idle", true)
	elseif newState == "chasing" then
		self:PlayAnimation("run", true)
	elseif newState == "attacking" then
		-- Stop all current animations
		for _, anim in pairs(self.animations) do
			anim:Stop()
		end
		self:PlayAnimation("attack", false)
	elseif newState == "dead" then
		self:PlayAnimation("death", false)
	end
end

-- MOVEMENT/ANIMATION --

function Enemy:StartFacing()
	if self._facingConn then
		self._facingConn:Disconnect()
	end

	self._facingConn = RunService.Heartbeat:Connect(function()
		if not self.target or not self.target.character or not self.model or not self.alive then
			return
		end

		local npcCF = self.model:GetPivot()
		local npcPos = npcCF.Position
		local targetPos = self.target.character:GetPivot().Position
		targetPos = Vector3.new(targetPos.X, npcPos.Y, targetPos.Z)

		local goalCF = CFrame.lookAt(npcPos, targetPos)
		local lerpCF = npcCF:Lerp(goalCF, 0.05)

		self.model:PivotTo(lerpCF)
	end)
end

function Enemy:StopFacing()
	if self._facingConn then
		self._facingConn:Disconnect()
		self._facingConn = nil
	end
end

function Enemy:PlayAnimation(animName, shouldLoop)
	if self.attacking then
		while self.attacking do
			task.wait(0.1)
		end
	end

	local animTrack = self.animations[animName]
	if not animTrack then
		warn("Animation '" .. animName .. "' not found for enemy " .. self.name)
		return
	end

	animTrack.Looped = shouldLoop or false

	-- disconnect previous attack marker connection
	if self._animConn then
		self._animConn:Disconnect()
		self._animConn = nil
	end

	if animName == "idle" then
		self:StopAnimation("run")
	end

	animTrack:Play(0.1)

	if animName == "run" then
		animTrack:AdjustSpeed(self.speed / DEFAULT_WALKSPEED)
	end

	if animName == "attack" then
		self.attacking = true
		self:PlaySound("attack", false)

		if not self.ranged then
			self.trail.Enabled = true
			task.delay(0.3, function()
				self:StopFacing()
				self:MeleeAttack()
			end)
		else
			task.delay(0.3, function()
				self:PlayParticle("Fire")
				self:StopFacing()
				self:RangedAttack()
			end)
		end
		animTrack.Stopped:Once(function()
			if self.trail then
				self.trail.Enabled = false
			end
			self.attacking = false
			self:EvaluateNextState()
		end)
	end
end

function Enemy:StopAnimation(animName)
	local anim = self.animations[animName]
	if anim then
		anim:Stop()
	end
end

-- ATTACKS --

function Enemy:MeleeAttack()
	local hitboxSize = ServerStorage:WaitForChild("meleeHitbox").Size

	local params = {
		attacker = self,
		target = self.target,
		onHit = function(target)
			target:TakeDamage(self.damage, self.pierce, ATTACK_STUN_TIME)
			self.damageDebounce = true
			print(
				self.name
					.. " hit "
					.. target.name
					.. " for "
					.. self.damage
					.. " damage! ("
					.. self.pierce
					.. " pierce)"
			)
			task.delay(0.4, function()
				self.damageDebounce = false
			end)
		end,
		hitboxTemplate = "meleeHitbox",
		cframe = self.model.PrimaryPart.CFrame * CFrame.new(0, 0, -2),
		size = Vector3.new(hitboxSize.X, hitboxSize.Y, self.range),
		duration = 0.15,
	}
	HitboxHandler:CreateNPCHitbox(params)
end

function Enemy:RangedAttack()
	local params = {
		attacker = self,
		target = self.target,
		projectileTemplate = self.vfx["Projectile"],
		origin = self.model.PrimaryPart.Position,
		targetPosition = self.target.character:WaitForChild("HumanoidRootPart").Position,
		range = self.range + 10,
		speed = 100,
		hitRadius = 2,
		onHit = function(target)
			target:TakeDamage(self.damage, self.pierce, ATTACK_STUN_TIME)
			self.damageDebounce = true
			print(
				self.name
					.. " hit "
					.. target.name
					.. " for "
					.. self.damage
					.. " damage! ("
					.. self.pierce
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
	HitboxHandler:CreateNPCProjectile(params)
end

function Enemy:FadeOutProjectile(projectile)
	local tween = game:GetService("TweenService"):Create(projectile, TweenInfo.new(0.3), { Transparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		projectile:Destroy()
	end)
end

function Enemy:PlaySound(soundName, shouldLoop)
	local soundTrack = self.sounds[soundName]
	soundTrack.Looped = shouldLoop

	soundTrack:Play()
end

function Enemy:PlayParticle(particleName)
	local particleInstance = self.vfx[particleName]

	for _, v in pairs(particleInstance:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			if v:GetAttribute("instant") == true then
				v:Emit(v:GetAttribute("emitCount"))
			else
				v.Enabled = true

				task.delay(0.75, function()
					v.Enabled = false
				end)
			end
		end
	end
end

function Enemy:GetStat(stat)
	return self[stat]
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
