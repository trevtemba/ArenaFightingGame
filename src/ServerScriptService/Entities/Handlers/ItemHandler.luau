local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local Items = require(Services.Data:WaitForChild("ItemData"))

local ItemHandler = {}
ItemHandler.__index = ItemHandler

function ItemHandler.new(owner)
	local self = setmetatable({}, ItemHandler)
	self.owner = owner
	self.lootPool = {}
	return self
end

function ItemHandler:SetStageComponents(componentIdList)
	self.lootPool = {}
	for _, id in ipairs(componentIdList) do
		self.lootPool[id] = (self.lootPool[id] or 0) + 1
	end
end

function ItemHandler:SpawnAnvil(type)
	if type == "component" then
		print("component anvil logic")
	elseif type == "item" then
		print("item anvil logic")
	end
end

function ItemHandler:RollComponent()
	local availableIds = {}
	for id, count in pairs(self.lootPool) do
		if count > 0 then
			table.insert(availableIds, id)
		end
	end
	if #availableIds == 0 then
		return nil
	end

	local chosenIndex = math.random(#availableIds)
	local chosenId = availableIds[chosenIndex]

	self.lootPool[chosenId] = self.lootPool[chosenId] - 1
	if self.lootPool[chosenId] <= 0 then
		self.lootPool[chosenId] = nil
	end

	return chosenId
end

function ItemHandler:MergeComponents(componentId1, componentId2)
	if not componentId1 or not componentId2 then
		return nil
	end

	local function getRecipeKey(id1, id2)
		local sorted = { id1, id2 }
		table.sort(sorted)
		return sorted[1] .. "+" .. sorted[2]
	end

	local key = getRecipeKey(componentId1, componentId2)
	local fusedItemId = Items[key]
	return fusedItemId
end

return ItemHandler
