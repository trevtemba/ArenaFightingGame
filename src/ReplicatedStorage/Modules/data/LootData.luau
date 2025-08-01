local DROP_TYPES = require(game:GetService("ReplicatedStorage").Modules.core.DropTypes)

local LootData = {}

LootData.Tiers = {
	[DROP_TYPES.Common] = {
		Weight = 60,
		Loot = {
			{
				Name = "Gold 2-5",
				Apply = function(playerObj)
					local amount = math.random(2, 5)
					playerObj:AddGold(amount)
				end,
			},
		},
	},
	[DROP_TYPES.Uncommon] = {
		Weight = 60,
		Loot = {
			{
				Name = "Component",
				Apply = function(playerObj)
					playerObj:AddRandomComponent()
				end,
			},
			{
				Name = "Heal 15hp",
				Apply = function(playerObj)
					playerObj:AddHealth(15)
				end,
			},
		},
	},
	[DROP_TYPES.Rare] = {
		Weight = 30,
		Loot = {
			{
				Name = "ComponentAnvil",
				Apply = function(playerObj)
					playerObj:SpawnAnvil("component")
				end,
			},
		},
	},
	[DROP_TYPES.Legendary] = {
		Weight = 10,
		Loot = {
			{
				Name = "ItemAnvil",
				Apply = function(playerObj)
					playerObj:SpawnAnvil("item")
				end,
			},
		},
	},
}

return LootData
