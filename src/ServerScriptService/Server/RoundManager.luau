local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local CollectionService = Services.CollectionService
local Players = Services.Players

local EnemyManager = require(Services.Server.EnemyManager)

local ClientEvents = Services.ClientEvents
local Dummy = require(Services.Entities.Dummy)

local arenas = Services.ServerStorage:WaitForChild("arenas")

local arenaSpawnPositions = {
	-- Arena 1
	CFrame.new(-925, 0.5, -925),
	-- Arena 2
	CFrame.new(-925, 0.5, -285),
	-- Arena 3
	CFrame.new(-925, 0.5, -300),
	-- Arena 4
	CFrame.new(-925, 0.5, 925),
	-- Arena 5
	CFrame.new(-510, 0.5, -925),
	-- Arena 6
	CFrame.new(-510, 0.5, -285),
	-- Arena 7
	CFrame.new(-510, 0.5, -300),
	-- Arena 8
	CFrame.new(-510, 0.5, 925),
}

local RoundManager = {}

function RoundManager.RunPve(stage, plrObjs)
	local pveArena = arenas:WaitForChild("pve")
	local arena = pveArena:WaitForChild("arenaModel")

	for i, plrObj in ipairs(plrObjs) do
		-- spawn an arena
		local plrArena = arena:Clone()
		plrArena:PivotTo(arenaSpawnPositions[i] * CFrame.Angles(0, math.rad(90), 0))
		plrArena.Parent = game.Workspace

		-- store all spawn cframes
		local plrSpawn = plrArena:WaitForChild("pSpawn1")
		local enemySpawns = {}

		for _, child in ipairs(plrArena:GetChildren()) do
			if child:IsA("BasePart") and child.Name:match("^eSpawn") then
				table.insert(enemySpawns, child.CFrame)
			end
		end

		-- spawn player
		local plrFinalCFrame = plrSpawn.CFrame * CFrame.new(0, 3, 0)
		plrObj.character:PivotTo(plrFinalCFrame)
		ClientEvents:WaitForChild("switchContext")
			:FireClient(Players:GetPlayerFromCharacter(plrObj.character), "Combat")
		-- spawn the enemies in each of the arenas

		if stage == 1 then
			EnemyManager.SpawnS1Enemies(enemySpawns, plrObj)
			print("level 1 npcs spawned")
		elseif stage == 2 then
			print("level 2 npcs spawned")
		elseif stage == 3 then
			print("level 3 npcs spawned")
		elseif stage == 4 then
			print("level 4 npcs spawned")
		end
	end
end

function RoundManager.RunTraining(plrObjs)
	local activeDummies = {}
	local Dummies = game:GetService("Workspace"):FindFirstChild("Dummies")

	for _, dummyRig in pairs(Dummies:GetChildren()) do
		local dummyObj = Dummy.new(dummyRig, dummyRig:GetAttribute("type"))
		CollectionService:AddTag(dummyRig, "Dummy")
		if not dummyObj then
			warn("something wrong with the dummy obj construction")
		end
		activeDummies[dummyRig] = dummyObj
		dummyObj:Initialize()
		dummyObj:SetPlayerTable(plrObjs)
		dummyObj:Activate()
		table.insert(activeDummies, dummyObj)
	end

	for _, plrObj in ipairs(plrObjs) do
		plrObj:SetEnemyTable(activeDummies)
		ClientEvents:WaitForChild("switchContext")
			:FireClient(Players:GetPlayerFromCharacter(plrObj.character), "Combat")
	end
end

function RoundManager.RunPvp(stage, plrObjs)
	if stage == 1 then
		print("stage 1 player damage")
	elseif stage == 2 then
		print("stage 2 player damage")
	elseif stage == 3 then
		print("stage 3 player damage")
	elseif stage == 4 then
		print("stage 4 player damage")
	end
end

function RoundManager.RunAugment(stage, plrObjs) end

function RoundManager.RunCarousel(stage, plrObjs) end

return RoundManager
