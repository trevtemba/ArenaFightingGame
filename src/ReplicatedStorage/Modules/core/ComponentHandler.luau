local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.Modules.data.ItemData)

local ComponentHandler = {}
ComponentHandler.__index = ComponentHandler

function ComponentHandler.new(owner)
	local self = setmetatable({}, ComponentHandler)
	self.owner = owner
	self.lootPool = {}
	self.components = {}
	return self
end

function ComponentHandler:AddComponent(componentId)
	if not Items[componentId] then
		warn("Attempted to add unknown component ID:", componentId)
		return
	end
	table.insert(self.components, Items[componentId])
end

function ComponentHandler:SetStageComponents(componentIdList)
	self.lootPool = {}
	for _, id in ipairs(componentIdList) do
		self.lootPool[id] = (self.lootPool[id] or 0) + 1
	end
end

function ComponentHandler:RollComponent()
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

	return Items[chosenId], chosenId
end

function ComponentHandler:MergeComponents(componentId1, componentId2)
	if not componentId1 or not componentId2 then
		return nil
	end

	local function getRecipeKey(id1, id2)
		local sorted = { id1, id2 }
		table.sort(sorted)
		return sorted[1] .. "+" .. sorted[2]
	end

	local key = getRecipeKey(componentId1, componentId2)
	local fusedItem = Items[key]
	return fusedItem
end

return ComponentHandler
