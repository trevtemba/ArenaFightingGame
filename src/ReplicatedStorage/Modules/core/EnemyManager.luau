local Enemy = require(script.Parent:WaitForChild("Enemy"))

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerStorage = game:GetService("ServerStorage")
local EnemyData = require(ReplicatedStorage.Modules.data.EnemyData)
local DROP_TYPES = require(script.Parent.DropTypes)
local enemies = ServerStorage:WaitForChild("enemies")

local enemyMap = {}

local EnemyManager = {}

local SPAWN_OFFSET_Y = 3

-- Rolls a drop type from weighted rates
local function rollDrop(dropRates)
	local totalWeight = 0
	for _, weight in pairs(dropRates) do
		totalWeight += weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for dropType, weight in pairs(dropRates) do
		cumulative += weight
		if roll <= cumulative then
			return dropType
		end
	end

	return DROP_TYPES.None -- fallback
end

local function spawnEnemy(enemyTemplate, enemyType, spawnCFrame, level, plr, lootDrop)
	local enemy = enemyTemplate:Clone()
	enemy.Name = ""
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
	local dropRates = EnemyData[1].droprates
	local lootDrop = rollDrop(dropRates)

	-- first 3 are melee
	for i = 1, 1 do
		spawnEnemy(meleeTemplate, "melee", spawns[i], 1, plr, lootDrop)
	end

	-- last 2 are ranged
	for i = 4, 4 do
		spawnEnemy(rangedTemplate, "ranged", spawns[i], 1, plr, lootDrop)
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
