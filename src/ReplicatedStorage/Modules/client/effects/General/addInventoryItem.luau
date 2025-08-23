local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Player = Services.Players.LocalPlayer

local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)
local UI = Services.UI

local function getUI()
	local gui = Player:WaitForChild("PlayerGui")
	local hud = gui:WaitForChild("HUD")
	local inv = hud:WaitForChild("super"):WaitForChild("inventory")
	return inv:WaitForChild("slots"), UI:WaitForChild("items"), hud
end

return function(argumentData)
	local slotNum: number = argumentData.slotNum
	local itemId: string = argumentData.itemId

	if slotNum and itemId then
		local slots, items, InventoryGui = getUI()
		local slotFrame = slots:WaitForChild(string.format("slot%d", slotNum))
		local itemTemplate = items:FindFirstChild(itemId)
		if not itemTemplate then
			return
		end

		local itemFrame = itemTemplate:Clone()
		local iconBtn = itemFrame:WaitForChild("icon")
		itemFrame.Parent = InventoryGui -- float independently before docking

		-- Start position: center of screen
		-- itemFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		itemFrame.Position = UDim2.fromScale(0.5, 0.5)
		itemFrame.Visible = true
		itemFrame.BackgroundTransparency = 1
		iconBtn.ImageTransparency = 1

		-- Step 1: Fade in
		tweenHelper:Tween(
			iconBtn,
			{ time = 0.75, easingStyle = Enum.EasingStyle.Quad, easingDirection = Enum.EasingDirection.In },
			{ ImageTransparency = 0 }
		)
		-- tweenHelper:Tween(itemFrame, { time = 1 }, { BackgroundTransparency = 0 })

		-- Step 2: Move to slot
		local goalPosition = slotFrame.AbsolutePosition
		-- local rootGui = InventoryGui
		-- local viewportSize = rootGui.AbsoluteSize

		-- You can optionally convert to Scale using viewport if you're tweening in different resolution
		local finalPos = UDim2.fromOffset(goalPosition.X, goalPosition.Y)
		print(finalPos)
		tweenHelper:Tween(itemFrame, {
			time = 0.75,
			easingStyle = Enum.EasingStyle.Quart,
			easingDirection = Enum.EasingDirection.In,
		}, {
			Position = finalPos,
		}, function()
			itemFrame.Parent = slotFrame
			itemFrame.Position = UDim2.fromScale(0, 0)
			itemFrame.BackgroundTransparency = 0
			local flashFrame = UI:WaitForChild("flashFrame"):Clone()
			flashFrame.Parent = itemFrame

			tweenHelper:Tween(flashFrame, { time = 0.1 }, { BackgroundTransparency = 0.1 }, function()
				tweenHelper:Tween(
					flashFrame,
					{ time = 0.75, easingStyle = Enum.EasingStyle.Cubic, easingDirection = Enum.EasingDirection.InOut },
					{ BackgroundTransparency = 1 },
					function()
						flashFrame:Destroy()
					end
				)
			end)
		end)
	end
end
