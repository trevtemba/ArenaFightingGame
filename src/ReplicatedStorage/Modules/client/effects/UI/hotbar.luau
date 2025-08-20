local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local Player = Services.Players.LocalPlayer

local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)
local castSprite1 = Services.UI:WaitForChild("castSprite1")
local outerglow = Services.UI:WaitForChild("outerglow")

local hotbar = {}

local function getHotbarUI(abilitySlot)
	local gui = Player:WaitForChild("PlayerGui")
	local hudGui = gui:WaitForChild("HUD")
	local abilityFrame = hudGui
		:WaitForChild("super")
		:WaitForChild("hotbar")
		:WaitForChild("abilityList")
		:WaitForChild("ability" .. tostring(abilitySlot))
	return abilityFrame
end
local function getSoulUI()
	local gui = Player:WaitForChild("PlayerGui")
	local hudGui = gui:WaitForChild("HUD")
	local soulFrame = hudGui:WaitForChild("super"):WaitForChild("soulAbility")
	return soulFrame
end

function hotbar.Cast(argumentData)
	local abilitySlot: number = argumentData.abilitySlot

	if abilitySlot then
		local abilityFrame = getHotbarUI(abilitySlot)
		local stroke = abilityFrame:WaitForChild("base"):WaitForChild("UIStroke")
		local glowFrame = outerglow:Clone()
		local sprite1 = castSprite1:Clone()

		glowFrame.Parent = abilityFrame
		glowFrame.Visible = true
		sprite1.Parent = abilityFrame
		sprite1.Visible = true

		local CELL_SIZE = 256
		local COLUMNS = 4
		local TOTAL_FRAMES = 16
		local FRAME_DURATION = 1 / 30 -- 15 FP

		task.defer(function()
			for i = 0, TOTAL_FRAMES - 1 do
				local col = i % COLUMNS
				local row = math.floor(i / COLUMNS)

				sprite1.ImageRectOffset = Vector2.new(col * CELL_SIZE, row * CELL_SIZE)
				task.wait(FRAME_DURATION)
			end

			sprite1:Destroy()
		end)

		tweenHelper:Tween(glowFrame, {
			time = 0.25,
			easingStyle = Enum.EasingStyle.Sine,
			easingDirection = Enum.EasingDirection.Out,
		}, {
			ImageTransparency = 0,
		}, function()
			-- Snap back to original size
			tweenHelper:Tween(glowFrame, {
				time = 0.25,
				easingStyle = Enum.EasingStyle.Sine,
				easingDirection = Enum.EasingDirection.Out,
			}, {
				ImageTransparency = 1,
			})
		end)
		tweenHelper:Tween(stroke, {
			time = 0.25,
			easingStyle = Enum.EasingStyle.Sine,
			easingDirection = Enum.EasingDirection.Out,
		}, {
			Transparency = 0,
		}, function()
			-- Snap back to original size
			tweenHelper:Tween(stroke, {
				time = 0.25,
				easingStyle = Enum.EasingStyle.Sine,
				easingDirection = Enum.EasingDirection.Out,
			}, {
				Transparency = 1,
			})
		end)
	end
end

function hotbar.Cooldown(argumentData)
	local cooldown: number = argumentData.cooldown
	local abilitySlot: number = argumentData.abilitySlot

	if cooldown and abilitySlot then
		local abilityFrame = getHotbarUI(abilitySlot)
		local cooldownFrame = abilityFrame:WaitForChild("base"):WaitForChild("cooldown")

		cooldownFrame.Visible = true

		tweenHelper:Tween(cooldownFrame, {
			time = cooldown,
			easingStyle = Enum.EasingStyle.Linear,
			easingDirection = Enum.EasingDirection.Out,
		}, {
			Size = UDim2.fromScale(1, 0),
		}, function()
			cooldownFrame.Visible = false
			cooldownFrame.Size = UDim2.fromScale(1, 1) -- Reset for next cooldown
		end)
	end
end

function hotbar.SoulCast()
	local soulFrame = getSoulUI()
	local stroke = soulFrame:WaitForChild("base"):WaitForChild("UIStroke")
	local glowFrame = outerglow:Clone()
	local sprite1 = castSprite1:Clone()

	glowFrame.Parent = soulFrame
	glowFrame.Visible = true
	glowFrame.Rotation = 45
	sprite1.Parent = soulFrame
	sprite1.Visible = true

	local CELL_SIZE = 256
	local COLUMNS = 4
	local TOTAL_FRAMES = 16
	local FRAME_DURATION = 1 / 30 -- 15 FP

	task.defer(function()
		for i = 0, TOTAL_FRAMES - 1 do
			local col = i % COLUMNS
			local row = math.floor(i / COLUMNS)

			sprite1.ImageRectOffset = Vector2.new(col * CELL_SIZE, row * CELL_SIZE)
			task.wait(FRAME_DURATION)
		end

		sprite1:Destroy()
	end)

	tweenHelper:Tween(glowFrame, {
		time = 0.25,
		easingStyle = Enum.EasingStyle.Sine,
		easingDirection = Enum.EasingDirection.Out,
	}, {
		ImageTransparency = 0,
	}, function()
		-- Snap back to original size
		tweenHelper:Tween(glowFrame, {
			time = 0.25,
			easingStyle = Enum.EasingStyle.Sine,
			easingDirection = Enum.EasingDirection.Out,
		}, {
			ImageTransparency = 1,
		})
	end)
	tweenHelper:Tween(stroke, {
		time = 0.25,
		easingStyle = Enum.EasingStyle.Sine,
		easingDirection = Enum.EasingDirection.Out,
	}, {
		Transparency = 0,
	}, function()
		-- Snap back to original size
		tweenHelper:Tween(stroke, {
			time = 0.25,
			easingStyle = Enum.EasingStyle.Sine,
			easingDirection = Enum.EasingDirection.Out,
		}, {
			Transparency = 1,
		})
	end)
end

function hotbar.SoulCooldown(argumentData)
	local soulFrame = getSoulUI()
	local cooldownFrame = soulFrame:WaitForChild("base"):WaitForChild("cooldown")
	local cooldown = argumentData.cooldown

	cooldownFrame.Visible = true

	tweenHelper:Tween(cooldownFrame, {
		time = cooldown,
		easingStyle = Enum.EasingStyle.Linear,
		easingDirection = Enum.EasingDirection.Out,
	}, {
		Size = UDim2.fromScale(0, 0),
	}, function()
		cooldownFrame.Visible = false
		cooldownFrame.Size = UDim2.fromScale(1, 1) -- Reset for next cooldown
	end)
end

return hotbar
