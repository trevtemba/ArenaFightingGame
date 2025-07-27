local UIFolder = game:GetService("ServerStorage"):FindFirstChild("ui")
local billboardGui_template = UIFolder:FindFirstChild("HealthBar")
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
	self.billBoardGui = nil
	-- self.healthFill = nil
	-- self.damageFill = nil

	self:init()
	return self
end

function UIHandler:init()
	local HumanoidRootPart = self.owner.character:FindFirstChild("HumanoidRootPart")

	local billboard = billboardGui_template:Clone()
	self.dividers =
		billboard:WaitForChild("super"):WaitForChild("healthsuper"):WaitForChild("healthBase"):WaitForChild("dividers")
	self.billBoardGui = billboard
	self:Calibrate()
	billboard.Parent = HumanoidRootPart
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

function UIHandler:Calibrate()
	local teir = self.billBoardGui.super.teirsuper.teirbase.teirbase2:FindFirstChildOfClass("TextLabel")

	teir.Text = self.owner.teir
	self:CreateDividers()
end

function UIHandler:CreateDividers()
	local maxHp = self.owner.maxHP
	local dividerCount = math.floor(maxHp / 100) - 1
	self.dividers:ClearAllChildren()

	for i = 1, dividerCount do
		local divider = Instance.new("Frame")
		divider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		divider.BackgroundTransparency = 0
		divider.Size = UDim2.new(0.01, 0, 1, 0)
		divider.Position = UDim2.new(i / (dividerCount + 1), 0, 0, 0)
		divider.BorderSizePixel = 0
		divider.ZIndex = 5
		divider.Parent = self.dividers
	end
end

return UIHandler
