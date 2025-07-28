local LootDefinitions = {}

LootDefinitions.Tiers = {
	["Common"] = {
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
	["Uncommon"] = {
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
	["Rare"] = {
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
	["Legendary"] = {
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

return LootDefinitions
