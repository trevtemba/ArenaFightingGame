local Enemy = require(script.Parent:WaitForChild("Enemy"))

local CollectionService = game:GetService("CollectionService")

local ServerStorage = game:GetService("ServerStorage")
local enemies = ServerStorage:WaitForChild("enemies")

local enemyMap = {}

local EnemyManager = {}

local SPAWN_OFFSET_Y = 3

local function spawnEnemy(enemyTemplate, enemyType, spawnCFrame, level, plr)
	local enemy = enemyTemplate:Clone()
	local enemyObj = Enemy.new()
	local plrPos = plr.character:GetPivot().Position

	enemy.Parent = workspace

	-- Build enemy
	enemyObj:Init(level, enemyType, enemy)
	enemyObj:PreloadAnimations()

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
	for i = 1, 1 do
		spawnEnemy(meleeTemplate, "melee", spawns[i], 1, plr)
	end

	-- -- last 2 are ranged
	-- for i = 4, 5 do
	-- 	spawnEnemy(rangedTemplate, "ranged", spawns[i], 1, plr)
	-- end
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
