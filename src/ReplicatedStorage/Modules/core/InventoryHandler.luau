local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemHandler = require(script.Parent.ItemHandler)
local Items = require(ReplicatedStorage.Modules.data.ItemData)
local clientEffects = ReplicatedStorage.RemoteEvents.Client.clientEffects

local InventoryHandler = {}
InventoryHandler.__index = InventoryHandler

local MAX_SLOTS = 16

function InventoryHandler.new(owner)
	local self = setmetatable({}, InventoryHandler)
	self.owner = owner
	self.inventory = table.create(MAX_SLOTS, nil)
	self.gold = 0
	self.activeItems = {}
	return self
end

function InventoryHandler:AddItem(itemId)
	if not Items[itemId] then
		warn("Invalid itemId: " .. tostring(itemId))
		return false
	end

	local slotNum = 0
	for slot = 1, MAX_SLOTS do
		if self.inventory[slot] == nil then
			self.inventory[slot] = itemId
			slotNum = slot
			clientEffects:FireAllClients("addInventoryItem", { slotNum = slotNum, itemId = itemId })
			return true
		end
	end

	return false -- Inventory full
end

function InventoryHandler:AddGold(amount)
	self.gold += amount

	clientEffects:FireAllClients("addGold", { amount = amount })

	return true
end

function InventoryHandler:RemoveItem(slot)
	if self.inventory[slot] then
		self.inventory[slot] = nil
		return true
	end
	return false
end

function InventoryHandler:MoveItem(fromSlot, toSlot)
	if fromSlot == toSlot then
		return false
	end

	local fromItem = self.inventory[fromSlot]
	if not fromItem then
		return false
	end

	-- Swap or move
	self.inventory[fromSlot], self.inventory[toSlot] = self.inventory[toSlot], self.inventory[fromSlot]

	return true
end

function InventoryHandler:MergeItems(slot1, slot2)
	local id1 = self.inventory[slot1]
	local id2 = self.inventory[slot2]

	if not id1 or not id2 then
		return false
	end

	if slot1 == slot2 then
		return false
	end

	local fusedItemId = ItemHandler:MergeComponents(id1, id2)
	if not fusedItemId then
		print(fusedItemId .. " is not valid")
		return false
	end

	-- Replace slot1 with fused item, clear slot2
	self.inventory[slot1] = fusedItemId
	self.inventory[slot2] = nil

	return true
end

function InventoryHandler:GetInventory()
	local copy = {}
	for i = 1, MAX_SLOTS do
		copy[i] = self.inventory[i]
	end
	return copy
end

function InventoryHandler:updateClient() end

return InventoryHandler
