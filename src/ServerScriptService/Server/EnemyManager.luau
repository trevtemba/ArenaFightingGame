local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local CollectionService = Services.CollectionService

local Enemy = require(Services.Entities.Enemy)
local EnemyData = require(Services.Data.EnemyData)
local DROP_TYPES = require(Services.Core.DropTypes)
local enemies = Services.ServerStorage:WaitForChild("enemies")

local enemyMap = {}

local EnemyManager = {}

local SPAWN_OFFSET_Y = 3

local function rollDropType(dropRates)
	local totalWeight = 0
	for _, entry in ipairs(dropRates) do
		totalWeight += entry.Weight
	end

	local roll = math.random() * totalWeight
	print(roll)
	local cumulative = 0

	for _, entry in ipairs(dropRates) do
		cumulative += entry.Weight
		if roll <= cumulative then
			return entry.Type
		end
	end

	return DROP_TYPES.None
end

local function spawnEnemy(enemyTemplate, enemyType, spawnCFrame, level, plr, lootDrop, enemyNum)
	local enemy = enemyTemplate:Clone()
	enemy.Name = ""
	enemy:SetAttribute("id", "enemy_" .. tostring(enemyNum))
	local enemyObj = Enemy.new(lootDrop)
	local plrPos = plr.character:GetPivot().Position

	enemy.Parent = workspace

	-- Build enemy
	enemyObj:Init(level, enemyType, enemy)

	--Tag it and put in reverse lookup table
	CollectionService:AddTag(enemy, "Enemy")
	enemyMap[enemy] = enemyObj

	-- Apply offset and rotation
	local spawnPosition = spawnCFrame.Position + Vector3.new(0, SPAWN_OFFSET_Y, 0)
	local lookAtCFrame = CFrame.lookAt(spawnPosition, plrPos)
	enemy:PivotTo(lookAtCFrame)

	enemyObj:SetTarget(plr)
	enemyObj:StartAI()
end

function EnemyManager.SpawnS1Enemies(spawns, plr)
	local meleeTemplate = enemies:WaitForChild("s1melee")
	local rangedTemplate = enemies:WaitForChild("s1ranged")
	-- first 3 are melee
	for enemyNum = 1, 1 do
		local dropRates = EnemyData[1].dropRates
		local lootDrop = rollDropType(dropRates)
		spawnEnemy(meleeTemplate, "melee", spawns[enemyNum], 1, plr, lootDrop, enemyNum)
		print("Enemy spawned with loot drop of: " .. lootDrop)
	end

	-- last 2 are ranged
	for enemyNum = 4, 4 do
		local dropRates = EnemyData[1].dropRates
		local lootDrop = rollDropType(dropRates)
		spawnEnemy(rangedTemplate, "ranged", spawns[enemyNum], 1, plr, lootDrop)
	end

	plr:SetEnemyTable(enemyMap)
end

function EnemyManager:GetEnemyFromCharacter(character)
	if CollectionService:HasTag(character, "Enemy") then
		return enemyMap[character]
	end
	return nil
end

function EnemyManager.CleanEnemies()
	-- TODO: Implement later
end

return EnemyManager
