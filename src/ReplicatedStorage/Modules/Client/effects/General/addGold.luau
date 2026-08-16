local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Player = Services.Players.LocalPlayer
local RunService = Services.RunService
local Debris = Services.DebrisService

local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)
local ParticleEmitter = require(Services.Client.guiParticle.ParticleEmitter)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)
local goldParticles = Services.UI:WaitForChild("goldParticles")

local function getUI()
	local gui = Player:WaitForChild("PlayerGui")
	local hudGui = gui:WaitForChild("HUD")
	local goldFrame = hudGui:WaitForChild("super"):WaitForChild("goldFrame")
	local coinTemplate = hudGui:WaitForChild("coinTemplate")
	return goldFrame, coinTemplate, hudGui
end

return function(argumentData)
	local amount: number = argumentData.amount

	if amount then
		local goldFrame, coinTemplate, hudGui = getUI()

		local goldValue = goldFrame:WaitForChild("base"):WaitForChild("gold")
		local goldIcon = goldFrame:WaitForChild("iconBase"):WaitForChild("icon")
		local orbSound = soundHelper.PlaySound("orbPickup", hudGui)
		local goldParticleEmitter = ParticleEmitter.new(goldIcon.Parent, goldParticles)

		for _ = 1, amount do
			local coinFrame = coinTemplate:Clone()
			local viewport = coinFrame:WaitForChild("viewport")
			coinFrame.Parent = hudGui
			coinFrame.Position = UDim2.fromScale(0.5, 0.5)
			coinFrame.Visible = true

			local coin3D = viewport:FindFirstChildWhichIsA("Model")
			if not coin3D then
				warn("No coin model found in viewport")
				continue
			end

			if not coin3D.PrimaryPart then
				coin3D.PrimaryPart = coin3D:FindFirstChildWhichIsA("BasePart")
			end

			-- Spin the coin during tween only
			local baseCFrame = coin3D.PrimaryPart.CFrame
			local yRotation = 0
			local spinDuration = 1
			local elapsed = 0

			local conn
			conn = RunService.RenderStepped:Connect(function(dt)
				if not coinFrame.Parent then
					conn:Disconnect()
					return
				end

				elapsed += dt
				if elapsed >= spinDuration then
					conn:Disconnect()
					return
				end

				yRotation += math.rad(180) * dt
				coin3D:SetPrimaryPartCFrame(baseCFrame * CFrame.Angles(0, yRotation, 0))
			end)

			-- Step 1: Fade in
			tweenHelper:Tween(
				viewport,
				{ time = 0.5, easingStyle = Enum.EasingStyle.Quad, easingDirection = Enum.EasingDirection.Out },
				{ ImageTransparency = 0 }
			)
			tweenHelper:Tween(coinFrame, {
				time = 0.5,
				easingStyle = Enum.EasingStyle.Cubic,
				easingDirection = Enum.EasingDirection.Out,
			}, { Size = UDim2.fromOffset(64, 64) }, function()
				tweenHelper:Tween(coinFrame, {
					time = 0.5,
					easingStyle = Enum.EasingStyle.Cubic,
					easingDirection = Enum.EasingDirection.In,
				}, { Size = UDim2.fromOffset(32, 32) })
			end)

			-- Step 2: Move to gold icon
			local goalPosition = goldIcon.AbsolutePosition
			local finalPos = UDim2.fromOffset(goalPosition.X, goalPosition.Y)

			tweenHelper:Tween(coinFrame, {
				time = spinDuration,
				easingStyle = Enum.EasingStyle.Cubic,
				easingDirection = Enum.EasingDirection.In,
			}, {
				Position = finalPos,
			}, function()
				coinFrame:Destroy()
				local coinSound = soundHelper.PlaySound("coinCollect", hudGui, 0.075)
				local current = tonumber(goldValue.Text) or 0

				goldValue.Text = tostring(current + 1)
				tweenHelper:Tween(goldIcon, {
					time = 0.35,
					easingStyle = Enum.EasingStyle.Elastic,
					easingDirection = Enum.EasingDirection.Out,
				}, {
					Size = UDim2.fromScale(1.25, 1.25),
				}, function()
					-- Snap back to original size
					tweenHelper:Tween(goldIcon, {
						time = 0.1,
						easingStyle = Enum.EasingStyle.Sine,
						easingDirection = Enum.EasingDirection.Out,
					}, {
						Size = UDim2.fromScale(1, 1),
					})
				end)
				goldParticleEmitter:Emit(10)

				goldParticleEmitter.onSpawn = function(particle)
					particle.velocity = Vector2.new(math.random(-20, 20), math.random(-10, 10))
					particle.transparency = 0
					particle.maxAge = 1
				end

				goldParticleEmitter.onUpdate = function(particle, deltaTime)
					particle.transparency = particle.transparency + 0.05
					particle.position = particle.position - (particle.velocity / 3 * deltaTime)
				end
				Debris:AddItem(coinSound, 1)
			end)

			task.wait(0.05)
		end

		task.delay(1.5, function()
			goldParticleEmitter:Destroy()
		end)
		Debris:AddItem(orbSound, 1)
	end
end
