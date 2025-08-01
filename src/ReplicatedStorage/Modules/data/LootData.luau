local DROP_TYPES = require(game:GetService("ReplicatedStorage").Modules.core.DropTypes)

local LootData = {}

LootData.Tiers = {
	[DROP_TYPES.Common] = {
		Weight = 60,
		Loot = {
			{
				Name = "Gold 2-5",
				Apply = function(player)
					-- playerData:AddGold(50)
				end,
			},
		},
	},
	[DROP_TYPES.Uncommon] = {
		Weight = 60,
		Loot = {
			{
				Name = "Component",
				Apply = function(player)
					-- playerData:AddComponent(50)
				end,
			},
			{
				Name = "Heal 15hp",
				Apply = function(player)
					-- player.Character.Humanoid.Health += 25
				end,
			},
		},
	},
	[DROP_TYPES.Rare] = {
		Weight = 30,
		Loot = {
			{
				Name = "ComponentAnvil",
				Apply = function(player)
					-- Inventory:AddItem(player, "Epic Sword")
				end,
			},
		},
	},
	[DROP_TYPES.Legendary] = {
		Weight = 10,
		Loot = {
			{
				Name = "Artifact",
				Apply = function(player)
					-- SummonPet(player)
				end,
			},
		},
	},
}

return LootData
