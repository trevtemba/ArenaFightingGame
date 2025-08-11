local Player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tweenHelper = require(ReplicatedStorage.Modules.client.effects.tweenHelper)
local castSprite1 = ReplicatedStorage:WaitForChild("UI"):WaitForChild("castSprite1")
local outerglow = ReplicatedStorage:WaitForChild("UI"):WaitForChild("outerglow")

local hotbar = {}

local function getUI(abilitySlot)
	local gui = Player:WaitForChild("PlayerGui")
	local hudGui = gui:WaitForChild("HUD")
	local abilityFrame = hudGui
		:WaitForChild("super")
		:WaitForChild("hotbar")
		:WaitForChild("abilityList")
		:WaitForChild("ability" .. tostring(abilitySlot))
	return abilityFrame
end

function hotbar.Cast(argumentData)
	local abilitySlot: number = argumentData.abilitySlot

	if abilitySlot then
		local abilityFrame = getUI(abilitySlot)
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
		local abilityFrame = getUI(abilitySlot)
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

return hotbar
