local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local TweenService = Services.TweenService
local player = Services.Players.LocalPlayer

return function(argumentData)
	local target = argumentData.target
	local currentHP = argumentData.currentHP
	local maxHP = argumentData.maxHP
	local healthShowTime = argumentData.healthShowTime

	if target and target ~= player.Character then
		local healthBar = target:FindFirstChild("HumanoidRootPart"):FindFirstChild("HealthBar")
		local healthFill = healthBar
			:FindFirstChildOfClass("CanvasGroup")
			:FindFirstChild("healthsuper")
			:FindFirstChild("healthBase")
			:FindFirstChild("health")
		local damageFill = healthBar
			:FindFirstChildOfClass("CanvasGroup")
			:FindFirstChild("healthsuper")
			:FindFirstChild("healthBase")
			:FindFirstChild("damage")
		local hpRatio = currentHP / maxHP

		healthFill.Size = UDim2.fromScale(hpRatio, 1)

		healthBar.Enabled = true
		local healthBarTween
		if healthBarTween then
			healthBarTween:Cancel()
		end

		healthBarTween = TweenService:Create(
			healthBar:FindFirstChildOfClass("CanvasGroup"),
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ GroupTransparency = 0 }
		)
		healthBarTween:Play()

		local tween =
			TweenService:Create(damageFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(hpRatio, 1),
			})
		tween:Play()

		task.delay(healthShowTime, function()
			if healthBarTween then
				healthBarTween:Cancel()
			end

			healthBarTween = TweenService:Create(
				healthBar:FindFirstChildOfClass("CanvasGroup"),
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ GroupTransparency = 1 }
			)
			healthBarTween:Play()
		end)
	end
end
