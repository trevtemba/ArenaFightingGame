-- local TweenService = game:GetService("TweenService")

local UIFolder = game:GetService("ServerStorage"):FindFirstChild("ui")
local healthBarGui = UIFolder:FindFirstChild("HealthBar")
local clientEffects = game:GetService("ReplicatedStorage").RemoteEvents.Client.clientEffects

local UIHandler = {}
UIHandler.__index = UIHandler

function UIHandler.new(entity)
	local self = setmetatable({}, UIHandler)

	self.owner = entity

	-- Health bar
	self.dividers = nil
	self.healthBarTween = nil
	self.healthShowTime = 1.75
	self.damageShowTime = 0.25
	-- self.healthBar = nil
	-- self.healthFill = nil
	-- self.damageFill = nil

	self:init()
	return self
end

function UIHandler:init()
	local HumanoidRootPart = self.owner.character:FindFirstChild("HumanoidRootPart")

	local healthBar = healthBarGui:Clone()
	self.dividers = healthBar:WaitForChild("base"):WaitForChild("healthBase"):WaitForChild("dividers")
	self:CreateDividers()
	healthBar.Parent = HumanoidRootPart
	-- self.healthBar = healthBar
	-- self.healthFill = healthBar:FindFirstChild("base"):FindFirstChild("healthBase"):FindFirstChild("health")
	-- self.damageFill = healthBar:FindFirstChild("base"):FindFirstChild("healthBase"):FindFirstChild("damage")
end

function UIHandler:UpdateHealthBar()
	clientEffects:FireAllClients("updateHealthBar", {
		target = self.owner.character,
		currentHP = self.owner.currentHP,
		maxHP = self.owner.maxHP,
		healthShowTime = self.healthShowTime,
	})
end

function UIHandler:ShowDamage(damage, damageType, crit)
	clientEffects:FireAllClients("showDamage", {
		target = self.owner.character,
		damage = damage,
		damageType = damageType,
		crit = crit,
		damageShowTime = self.damageShowTime,
	})
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

-- function UIHandler:UpdateHealthBar()
-- 	local hpRatio = self.owner.currentHP / self.owner.maxHP

-- 	self.healthFill.Size = UDim2.new(hpRatio, 0, 1, 0)

-- 	self.healthBar.Enabled = true

-- 	if self.healthBarTween then
-- 		self.healthBarTween:Cancel()
-- 	end

-- 	self.healthBarTween = TweenService:Create(
-- 		self.healthBar:FindFirstChildOfClass("CanvasGroup"),
-- 		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
-- 		{ GroupTransparency = 0 }
-- 	)
-- 	self.healthBarTween:Play()

-- 	local tween =
-- 		TweenService:Create(self.damageFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
-- 			Size = UDim2.new(hpRatio, 0, 1, 0),
-- 		})
-- 	tween:Play()

-- 	task.delay(self.healthShowTime, function()
-- 		if self.healthBarTween then
-- 			self.healthBarTween:Cancel()
-- 		end

-- 		self.healthBarTween = TweenService:Create(
-- 			self.healthBar:FindFirstChildOfClass("CanvasGroup"),
-- 			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
-- 			{ GroupTransparency = 1 }
-- 		)
-- 		self.healthBarTween:Play()
-- 	end)
-- end

return UIHandler
