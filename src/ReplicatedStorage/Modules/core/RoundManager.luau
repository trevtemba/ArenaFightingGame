local Players = game:GetService("Players")

local EnemyManager = require(script.Parent:WaitForChild("EnemyManager"))
local RemoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents")
local ClientEvents = RemoteEvents:WaitForChild("Client")

local ServerStorage = game:GetService("ServerStorage")

local arenas = ServerStorage:WaitForChild("arenas")

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

function RoundManager.RunPve(stage, plrs)
	local pveArena = arenas:WaitForChild("pve")
	local arena = pveArena:WaitForChild("arenaModel")

	for i, plr in ipairs(plrs) do
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
		plr.character:PivotTo(plrFinalCFrame)
		ClientEvents:WaitForChild("switchContext"):FireClient(Players:GetPlayerFromCharacter(plr.character), "Combat")
		-- spawn the enemies in each of the arenas

		if stage == 1 then
			EnemyManager.SpawnS1Enemies(enemySpawns, plr)
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

function RoundManager.RunPvp(stage, plrs)
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

function RoundManager.RunAugment(stage, plrs) end

function RoundManager.RunCarousel(stage, plrs) end

return RoundManager
