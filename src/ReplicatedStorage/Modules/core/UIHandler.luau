local TweenService = game:GetService("TweenService")

local UIFolder = game:GetService("ServerStorage"):FindFirstChild("ui")
local healthBarGui = UIFolder:FindFirstChild("HealthBar")
local damageCounterGui = UIFolder:FindFirstChild("DamageIndicator")

local UIHandler = {}
UIHandler.__index = UIHandler

function UIHandler.new(entity)
	local self = setmetatable({}, UIHandler)

	self.owner = entity

	-- Health bar
	self.healthBar = nil
	self.healthFill = nil
	self.damageFill = nil
	self.dividers = nil
	self.healthBarTween = nil
	self.healthShowTime = 1.75

	self.damageCounter = nil
	self.damageShowTime = 0.25

	self:init()
	return self
end

function UIHandler:init()
	local HumanoidRootPart = self.owner.character:FindFirstChild("HumanoidRootPart")

	local healthBar = healthBarGui:Clone()
	self.healthBar = healthBar
	self.healthFill = healthBar:FindFirstChild("base"):FindFirstChild("healthBase"):FindFirstChild("health")
	self.damageFill = healthBar:FindFirstChild("base"):FindFirstChild("healthBase"):FindFirstChild("damage")
	self.dividers = healthBar:WaitForChild("base"):WaitForChild("healthBase"):WaitForChild("dividers")
	self:CreateDividers()
	healthBar.Parent = HumanoidRootPart

	local damageCounter = damageCounterGui:Clone()
	self.damageCounter = damageCounter
	damageCounter.Parent = HumanoidRootPart
end

function UIHandler:UpdateHealthBar()
	local hpRatio = self.owner.currentHP / self.owner.maxHP

	self.healthFill.Size = UDim2.new(hpRatio, 0, 1, 0)

	self.healthBar.Enabled = true

	if self.healthBarTween then
		self.healthBarTween:Cancel()
	end

	self.healthBarTween = TweenService:Create(
		self.healthBar:FindFirstChildOfClass("CanvasGroup"),
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	)
	self.healthBarTween:Play()

	local tween =
		TweenService:Create(self.damageFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(hpRatio, 0, 1, 0),
		})
	tween:Play()

	task.delay(self.healthShowTime, function()
		if self.healthBarTween then
			self.healthBarTween:Cancel()
		end

		self.healthBarTween = TweenService:Create(
			self.healthBar:FindFirstChildOfClass("CanvasGroup"),
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ GroupTransparency = 1 }
		)
		self.healthBarTween:Play()
	end)
end

function UIHandler:ShowDamage(damage, damageType, crit)
	local damageCounter = self.damageCounter:Clone()
	damageCounter.Parent = self.owner.character:FindFirstChild("HumanoidRootPart")
	local counterUI = damageCounter:FindFirstChild(damageType)

	local randomOffset = Vector3.new(
		math.random(-1, 1), -- x offset
		math.random(0, 1), -- y offset
		math.random(0, 2) -- z offset
	)

	local damageScale = damage > 100 and 0.95 or 0.75

	if crit then
		counterUI:FindFirstChild("crit").Visible = true
		damageScale = damageScale + 0.1
		self.owner.fxHandler:PlaySound("critHit")
	else
		counterUI:FindFirstChild("crit").Visible = false
		self.owner.fxHandler:PlaySound("normHit")
	end

	counterUI:FindFirstChild("damage").Text = damage

	--Entrance animation
	local damageCounterScaleTweenIn = TweenService:Create(
		counterUI:FindFirstChildOfClass("UIScale"),
		TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Scale = damageScale }
	)
	damageCounterScaleTweenIn:Play()

	local damageCounterPositionTween = TweenService:Create(
		damageCounter,
		TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ StudsOffset = randomOffset }
	)
	damageCounterPositionTween:Play()

	-- Exit animation
	task.delay(self.damageShowTime, function()
		local damageCounterScaleTweenOut = TweenService:Create(
			counterUI:FindFirstChildOfClass("UIScale"),
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = 0 }
		)
		damageCounterScaleTweenOut:Play()
		damageCounterScaleTweenOut.Completed:Connect(function()
			damageCounter:Destroy()
		end)
	end)
end

function UIHandler:CreateDividers()
	local maxHp = self.owner.maxHP
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

return UIHandler
