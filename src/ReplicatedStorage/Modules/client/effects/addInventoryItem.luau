local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game:GetService("Players").LocalPlayer

local function getUI()
	local gui = Player:WaitForChild("PlayerGui")
	local inv = gui:WaitForChild("HUD"):WaitForChild("super"):WaitForChild("inventory")
	return inv:WaitForChild("slots"), ReplicatedStorage:WaitForChild("UI"):WaitForChild("items")
end

return function(argumentData)
	local slotNum: number = argumentData.slotNum
	local itemId: string = argumentData.itemId

	if slotNum and itemId then
		local slots, items = getUI()

		--tween logic that shows item float across screen to the dedicated slot
		local slotFrame = slots:WaitForChild(string.format("slot%d", slotNum))
		local itemFrame = items:FindFirstChild(itemId):Clone()

		itemFrame.Parent = slotFrame
	end
end
