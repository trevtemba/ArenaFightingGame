local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Sounds = ReplicatedStorage:FindFirstChild("Sounds")
local DamageCounter = ReplicatedStorage:FindFirstChild("UI"):FindFirstChild("DamageCounter")
local MockRootPart = ReplicatedStorage:FindFirstChild("MockRootPart")

return function(argumentData)
	local target = argumentData.target
	local damage = argumentData.damage
	local damageType = argumentData.damageType
	local crit = argumentData.crit
	local damageShowTime = argumentData.damageShowTime

	if target then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local damageCounter = DamageCounter:Clone()
			local mockRootPart = MockRootPart:Clone()
			mockRootPart.CFrame = rootPart.CFrame
			mockRootPart.Parent = workspace
			damageCounter.Parent = mockRootPart
			local counterUI = damageCounter:FindFirstChild(damageType)

			local randomOffset = Vector3.new(
				math.random(-1, 1), -- x offset
				math.random(0, 1), -- y offset
				math.random(0, 2) -- z offset
			)

			local damageScale = damage > 100 and 0.95 or 0.75
			local sound = nil
			if crit then
				counterUI:FindFirstChild("crit").Visible = true
				damageScale = damageScale + 0.1
				sound = Sounds:FindFirstChild("critHit"):Clone()
			else
				counterUI:FindFirstChild("crit").Visible = false
				sound = Sounds:FindFirstChild("normHit"):Clone()
			end

			sound.Parent = target
			sound:Play()

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
			task.delay(damageShowTime, function()
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
			Debris:AddItem(sound, 1)
			Debris:AddItem(mockRootPart, 1)
			Debris:AddItem(damageCounter, 1)
		end
	end
end
