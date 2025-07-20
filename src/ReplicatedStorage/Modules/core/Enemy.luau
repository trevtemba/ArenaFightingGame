local ServerStorage = game:GetService("ServerStorage")
-- local TweenService = game:GetService("TweenService")
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitboxHandler = require(script.Parent:WaitForChild("HitboxHandler"))
local CombatHandler = require(script.Parent:WaitForChild("CombatHandler"))
local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))
local FXHandler = require(script.Parent:WaitForChild("FXHandler"))
local PhysicsHandler = require(script.Parent:WaitForChild("PhysicsHandler"))
local EnemyData = require(script.Parent.Parent:WaitForChild("data"):WaitForChild("EnemyData"))
local HealthBarGui = game:GetService("ServerStorage").ui.HealthBar

local RunService = game:GetService("RunService")

local ATTACK_STUN_TIME = 0.25

local STATES = {
	Idle = "idle",
	Chasing = "chasing",
	Attacking = "attacking",
	Stunned = "stunned",
	Knocked = "knocked",
	Dead = "dead",
}

local Enemy = {}
Enemy.__index = Enemy

-- CLASS SETUP --

function Enemy.new()
	local self = setmetatable({}, Enemy)

	-- PROPERTIES
	self.name = ""
	self.character = nil
	self.humanoid = nil
	self.target = nil
	self.alive = false
	self.active = false
	self.stats = {
		durability = 0,
		damage = 0,
		pierce = 0,
		range = 0,
		attackCooldown = 1,
		speed = 18,
	}

	-- COMBAT STATE
	self.maxHP = 100
	self.currentHP = 100

	-- HANDLERS
	self.combatHandler = nil
	self.fxHandler = nil
	self.animationHandler = nil
	self.physicsHandler = nil

	-- ASSETS
	self.trail = nil
	self.healthBarGui = nil
	self.healthFill = nil
	self.damageFill = nil
	self.dividers = nil

	-- STATES
	self.attacking = false
	self.state = STATES.Idle
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

	HealthBarGui:Clone()
	HealthBarGui.Parent = self.character:WaitForChild("HumanoidRootPart")

	self.healthBarGui = self.character:WaitForChild("HumanoidRootPart"):WaitForChild("HealthBar")
	self.healthFill = self.healthBarGui:WaitForChild("base"):WaitForChild("healthBase"):WaitForChild("health")
	self.damageFill = self.healthBarGui:WaitForChild("base"):WaitForChild("healthBase"):WaitForChild("damage")
	self.dividers = self.healthBarGui:WaitForChild("base"):WaitForChild("healthBase"):WaitForChild("dividers")
	self.healthBarGui.Enabled = false

	self:CreateDividers()

	self.humanoid.WalkSpeed = config.speed
	self.humanoid.DisplayName = ""

	self.stats["durability"] = config.durability
	self.stats["damage"] = config.damage
	self.stats["pierce"] = config.pierce
	self.stats["range"] = config.range or 5
	self.stats["attackCooldown"] = config.cooldown
	self.stats["speed"] = config.speed
	self.stats["ranged"] = config.range > 15 and true or false

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
	self.animationHandler = AnimationHandler.new(self.character)
	self.physicsHandler = PhysicsHandler.new(self.character)

	self:SetState(STATES.Idle)

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
	if self.state == STATES.Knocked then
		return
	end

	while self.state == STATES.Stunned do
		task.wait(0.2)
	end

	local hrp = self.character:FindFirstChild("HumanoidRootPart")
	local targetHRP = self.target.character:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then
		return
	end

	if self.target.state["knocked"] == true then
		self:SetState(STATES.Idle)
		self.character.Humanoid:MoveTo(hrp.Position)
		return
	end

	local distance = (hrp.Position - targetHRP.Position).Magnitude

	if distance > self.stats["range"] then
		self:SetState(STATES.Chasing)
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
			self:SetState(STATES.Attacking)
			self.character.Humanoid:MoveTo(hrp.Position) -- stop movement
		end
	end
end

function Enemy:EvaluateNextState()
	if not self.target or not self.target.character then
		return
	end
	if self.state == STATES.Knocked then
		return
	end

	while self.state == STATES.Stunned do
		task.wait(0.2)
	end

	local hrp = self.character:FindFirstChild("HumanoidRootPart")
	local targetHRP = self.target.character:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHRP then
		return
	end

	if self.target.state["knocked"] == true then
		self:SetState(STATES.Idle)
		self.character.Humanoid:MoveTo(hrp.Position)
		return
	end

	local distance = (hrp.Position - targetHRP.Position).Magnitude

	if distance > self.stats["range"] then
		self:SetState(STATES.Chasing)
	else
		self.state = STATES.Idle
		self:StartFacing()
		self:SetState(STATES.Attacking) -- re-attack if still in range
	end
end

function Enemy:SetState(newState, stunDuration)
	if self.state == newState and (newState ~= STATES.Idle and newState ~= STATES.Stunned) then
		return
	end
	self.state = newState
	self:StateHandler(newState, stunDuration)
end

function Enemy:StateHandler(stateName, stunDuration)
	if self.attacking == true and stateName ~= STATES.Stunned then
		while self.attacking == true do
			task.wait(0.1)
		end
	end

	if stateName == STATES.Idle then
		self:Idle()
	end
	if stateName == STATES.Chasing then
		self:Chase()
	end
	if stateName == STATES.Attacking then
		self:Attack()
	end
	if stateName == STATES.Stunned then
		self:Stun(stunDuration or 0.75)
	end
	if stateName == STATES.Dead then
		self:Die()
	end
end

function Enemy:Idle()
	print("idling")
	self.animationHandler:StopAll()
	self.animationHandler:Play("idle")
end

function Enemy:Chase()
	print("chasing")
	self.animationHandler:Stop("idle")
	self.animationHandler:PlayRun(self.stats.speed)
end

function Enemy:Attack()
	if self.state == STATES.Stunned then
		return
	end

	print("attacking")
	self.attacking = true
	self.animationHandler:StopAll()
	self.animationHandler:Play("attack", 0.1)
	self.combatHandler:M1Slow(5, 0.75)
	self.fxHandler:PlaySound("attack")

	if self.stats.ranged == false then
		self.trail.Enabled = true
		self.animationHandler:ConnectMarker("attack", "fire", function()
			print("attack fired")
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

	if self.state == STATES.Dead or self.state == STATES.Knocked then
		return
	end

	local now = os.clock()
	self._stunEndTime = now + duration

	self.character.Humanoid:MoveTo(self.character.HumanoidRootPart.Position)
	self:Flinch()

	task.delay(duration, function()
		-- Only reset if no newer stun has occurred
		if os.clock() >= self._stunEndTime and self.state == STATES.Stunned then
			self.state = ""
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
			target:TakeDamage(self.stats["damage"], self.stats["pierce"], ATTACK_STUN_TIME, true)
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
			target:TakeDamage(self.stats["damage"], self.stats["pierce"], ATTACK_STUN_TIME, true)
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
		onMiss = function(projectile)
			self:FadeOutProjectile(projectile)
		end,
	}
	self.fxHandler:PlayParticle("Fire")
	HitboxHandler:CreateNPCProjectile(params)
end

function Enemy:TakeDamage(amount, pierce, stunTime)
	if self.combatHandler then
		self.combatHandler:TakeDamage(amount, pierce, stunTime)
	end
end

function Enemy:UpdateHealthBar()
	local hpRatio = self.currentHP / self.maxHP
	self.healthFill.Size = UDim2.new(hpRatio, 0, 1, 0)

	local showTime = 1.5
	self.healthBarGui.Enabled = true

	if self.healthBarTween then
		self.healthBarTween:Cancel()
	end

	self.healthBarTween = game:GetService("TweenService"):Create(
		self.healthBarGui:FindFirstChildOfClass("CanvasGroup"),
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	)
	self.healthBarTween:Play()

	local tween = game:GetService("TweenService")
		:Create(self.damageFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(hpRatio, 0, 1, 0),
		})
	tween:Play()

	task.delay(showTime, function()
		if self.healthBarTween then
			self.healthBarTween:Cancel()
		end

		self.healthBarTween = game:GetService("TweenService"):Create(
			self.healthBarGui:FindFirstChildOfClass("CanvasGroup"),
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ GroupTransparency = 1 }
		)
		self.healthBarTween:Play()
	end)
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
	self.physicsHandler:TweenRetreat(2)

	self.fxHandler:PlaySound("impact")
	self.fxHandler:PlayParticle("impact")
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

function Enemy:CreateDividers()
	local maxHp = self.maxHP
	local dividerCount = math.floor(maxHp / 100) - 1
	self.dividers:ClearAllChildren()

	for i = 1, dividerCount do
		local divider = Instance.new("Frame")
		divider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		divider.BackgroundTransparency = 0.7
		divider.Size = UDim2.new(0.02, 0, 1, 0)
		divider.Position = UDim2.new(i / (dividerCount + 1), 0, 0, 0)
		divider.BorderSizePixel = 0
		divider.ZIndex = 5
		divider.Parent = self.dividers
	end
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
