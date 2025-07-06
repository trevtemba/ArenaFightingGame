local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local core = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("core")
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")


local Game = require(core:WaitForChild("Game"))
local Player = require(core:WaitForChild("Player"))
local ChampionFactory = require(core:WaitForChild("ChampionFactory"))
local ChampionSelectedEvent = remotes:WaitForChild("ChampSelect")
local gameInstance = Game:GetInstance()

local MAX_PLAYERS = 1
local CHAMPION_PICK_TIME = 5
local availableChampions = { "Dante" }

local selectedChampions = {}

-- Tracks when players are ready
local joinedPlayers = {}

local function onPlayerAdded(plr)
	print(plr.Name .. " joined.")
	table.insert(joinedPlayers, plr)
end

-- Connect BEFORE checking current players
Players.PlayerAdded:Connect(onPlayerAdded)

-- Add any players already in the game (for Studio)
for _, plr in Players:GetPlayers() do
	onPlayerAdded(plr)
end

-- Wait until expected number of players have joined
print("Waiting for players...")
while #joinedPlayers < MAX_PLAYERS do
	print(#joinedPlayers .. "/" .. MAX_PLAYERS .. " players joined...")
	task.wait(1)
end

print("All players have joined. Initializing game...")

-- champ select logic

-- Listen for client picks
ChampionSelectedEvent.OnServerEvent:Connect(function(plr, championName)
	if table.find(availableChampions, championName) then
		selectedChampions[plr.UserId] = championName
		print(plr.Name .. " selected champion:", championName)
	end
end)

-- Give players time to pick
print("Select your champion!")
for i = CHAMPION_PICK_TIME, 1, -1 do
	print("Champion select ends in: " .. i)
	task.wait(1)
end

-- Finalize champion selection
for _, plr in ipairs(joinedPlayers) do
	if not selectedChampions[plr.UserId] then
		-- Assign random champion
		local randomPick = availableChampions[math.random(1, #availableChampions)]
		selectedChampions[plr.UserId] = randomPick
		print(plr.Name .. " did not pick. Assigned random champion: " .. randomPick)
	end
end

-- Wait for all characters to load
for _, plr in ipairs(joinedPlayers) do
	if not plr.Character then
		plr.CharacterAdded:Wait()
	end
end

-- Register players
for _, plr in ipairs(joinedPlayers) do

	local champion, rig = ChampionFactory.newChampion(selectedChampions[plr.UserId])

	rig:SetPrimaryPartCFrame(plr.Character.PrimaryPart.CFrame)
	plr.Character = rig
	rig.Parent = workspace:WaitForChild("Players")

	local playerObj = Player.new(plr, champion, rig)
	gameInstance:RegisterPlayer(playerObj)
end

print(gameInstance.players)

print(gameInstance.portal)
-- Start game logic

gameInstance:Run() 