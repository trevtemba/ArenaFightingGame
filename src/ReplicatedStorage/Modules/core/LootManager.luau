local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LootData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("data"):WaitForChild("LootData"))
local clientEffects =
	ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("clientEffects")

local LootManager = {}
local lootOrbMap = {} -- [orbId] = { player = Player, tier = "Common" }
local orbCounter = 0

local function generateOrbId()
	orbCounter += 1
	return "orb_" .. os.time() .. "_" .. orbCounter
end

function LootManager.CreateLootOrb(rootPos: Vector3, userId: number, tier: string)
	assert(LootData.Tiers[tier], "Invalid loot tier: " .. tostring(tier))
	local player = Players:GetPlayerByUserId(userId)
	if not player or not player:IsDescendantOf(game.Players) then
		return nil
	end

	local id = generateOrbId()
	lootOrbMap[id] = {
		player = player,
		tier = tier,
	}

	-- Render on client
	clientEffects:FireAllClients("spawnOrb", { rootPos = rootPos, tier = tier, id = id })

	return id
end

-- Weighted roll within a loot tier
local function rollItemFromTier(tier: string)
	local tierData = LootData.Tiers[tier]
	if not tierData then
		return nil
	end

	local lootList = tierData.Loot
	if #lootList == 0 then
		return nil
	end

	return lootList[math.random(1, #lootList)]
end

function LootManager.CanPickup(player: Player, orbId: string)
	local orb = lootOrbMap[orbId]
	return orb and orb.player == player
end

function LootManager.TryPickup(player: Player, orbId: string)
	local orb = lootOrbMap[orbId]

	if not orb or orb.player ~= player then
		return false, "Invalid or unauthorized orb"
	end

	-- Immediately remove to prevent race conditions
	lootOrbMap[orbId] = nil

	-- Roll and apply loot
	local loot = rollItemFromTier(orb.tier)
	if loot then
		loot.Apply(player)
	end

	return true, loot
end

return LootManager
