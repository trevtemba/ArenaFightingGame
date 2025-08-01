local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local LootData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("data"):WaitForChild("LootData"))
local clientEffects =
	ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client"):WaitForChild("clientEffects")

local lootOrbsFolder = ServerStorage.assets.lootOrbs
local LootManager = {}
local lootOrbMap = {} -- [orbId] = { player = Player, tier = "Common" }
local orbCounter = 0

local function generateOrbId()
	orbCounter += 1
	return "orb_" .. os.time() .. "_" .. orbCounter
end

function LootManager.CreateLootOrb(rootPos: Vector3, playerObj, tier: string)
	assert(LootData.Tiers[tier], "Invalid loot tier: " .. tostring(tier))

	local function getPlayerFromTouch(part)
		local character = part:FindFirstAncestorWhichIsA("Model")
		if character then
			return Players:GetPlayerFromCharacter(character)
		end
		return nil
	end

	local orbClone = lootOrbsFolder:FindFirstChild(tier):Clone()
	orbClone.Position = rootPos
	orbClone.Parent = game.Workspace:WaitForChild("Assets"):WaitForChild("orbs")

	local id = generateOrbId()
	lootOrbMap[id] = {
		userId = playerObj.userId,
		tier = tier,
		instance = orbClone,
	}
	orbClone:SetAttribute("orbId", id)

	task.defer(function()
		clientEffects:FireAllClients("spawnOrb", { tier = tier, orbId = id })

		task.delay(2, function()
			orbClone.Touched:Connect(function(hit)
				local player = getPlayerFromTouch(hit)
				if player and player.UserId == playerObj.userId then
					local success, loot = LootManager.TryPickup(player.UserId, id)
					if success and loot then
						print("Player: " .. player.Name .. " collected: " .. loot.Name)
						loot.Apply(playerObj)
						orbClone:Destroy()
					end
				end
			end)
		end)
	end)

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

function LootManager.TryPickup(userId: number, orbId: string)
	print(userId)
	print(orbId)
	local orb = lootOrbMap[orbId]

	if not orb or orb.userId ~= userId then
		print("Invalid or unauthorized orb")
		return false, nil
	end

	-- Immediately remove to prevent race conditions
	lootOrbMap[orbId] = nil

	-- Roll and apply loot
	local loot = rollItemFromTier(orb.tier)

	return true, loot
end

return LootManager
