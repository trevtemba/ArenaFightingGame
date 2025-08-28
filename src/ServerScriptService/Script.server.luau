local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local CollectionService = Services.CollectionService

local CollisionManager = require(Services.EntityUtils.CollisionManager)
local Game = require(Services.Server.Game)
local Player = require(Services.Entities.Player)
local ChampionFactory = require(Services.EntityUtils.ChampionFactory)

local ServerEvents = Services.ServerEvents
local ClientEvents = Services.ClientEvents
local champChosenByServer = ClientEvents:WaitForChild("champChosenByServer")
local ChampionSelectedEvent = ServerEvents:WaitForChild("ChampSelect")

CollisionManager:Init()
local gameInstance = Game:GetInstance()

local MAX_PLAYERS = 1
local CHAMPION_PICK_TIME = 5
local TRAINING_MODE = true
local availableChampions = { "Dante" }

local selectedChampions = {}
math.randomseed(tick())

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
		champChosenByServer:FireClient(plr, randomPick)
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
	local soulType = "Engage" --this will be a pcall that fetches the respective players soul type from database
	CollectionService:AddTag(rig, "Player")
	rig:SetPrimaryPartCFrame(plr.Character.PrimaryPart.CFrame)
	plr.Character = rig

	rig.Parent = workspace:WaitForChild("Players")

	local playerObj = Player.new(plr, champion, rig, soulType)
	gameInstance:RegisterPlayer(playerObj)
end

print(gameInstance.players)

print(gameInstance.portal)

gameInstance:Run(TRAINING_MODE)
