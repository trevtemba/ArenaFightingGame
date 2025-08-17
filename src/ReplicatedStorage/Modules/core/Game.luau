local Round = require(script.Parent:WaitForChild("Round"))
local DummyFolder = game.Workspace:FindFirstChild("Dummy")

local portalMsg = {
	"Extra augment round",
	"All mythic augments",
	"Artifact start",
	"Bonus loot PvE",
}

local roundSequence = { 1, 1, 3, 2, 2, 4, 2, 1, 3, 2, 2, 4, 2, 1, 3, 2, 2, 4, 2, 1, 2, 2, 4, 2, 1, 2, 2, 4 }

local Game = {}

Game.__index = Game

local instance = nil

function Game.new(players)
	if instance then
		return instance
	end

	local self = setmetatable({}, Game)
	self.players = {} -- List of Player objects
	self.alivePlayers = {}
	self.characterToPlayer = {}
	self.roundQueue = roundSequence -- e.g., {1, 2, 2, 3, 4} where 1 = PvE, 2 = PvP, etc.
	self.currentRoundIndex = 0
	self.currentRound = nil
	self.stage = 1
	self.componentIdList = { "gs001", "ms001", "sh001", "gh001", "sg001" }
	self.portal = portalMsg[math.random(1, #portalMsg)]

	instance = self
	return self
end

function Game:incrementPlayerComponentPools()
	for _, playerObj in pairs(self.alivePlayers) do
		playerObj.itemHandler:SetStageComponents(self.componentIdList)
	end
end

function Game:AddPlayer(playerObj)
	self.players[playerObj.userId] = playerObj
	table.insert(self.alivePlayers, playerObj)
	self:SortPlayersByHealth()
end

function Game:GetPlayer(plr)
	return self.players[plr.UserId]
end

function Game:SortPlayersByHealth()
	table.sort(self.players, function(a, b)
		return a.health > b.health
	end)
end

function Game:NextRound()
	self.currentRoundIndex += 1
	local roundType = self.roundQueue[self.currentRoundIndex]
	if roundType then
		local currRound = Round.new(roundType, self.stage)
		self.currentRound = currRound
		currRound:Start(self.alivePlayers)
	else
		print("No more rounds.")
	end
end

function Game:Run(TRAINING_MODE)
	if TRAINING_MODE then
		local roundType = 5
		if roundType then
			-- Intermission
			for i = 5, 1, -1 do
				print("Intermission: " .. i)
				task.wait(1)
			end
			local currRound = Round.new(roundType, self.stage)
			self.currentRound = currRound
			currRound:Start(self.alivePlayers)
		else
			print("No more rounds.")
		end
	else
		print(string.format("Start of stage %d", self.stage))
		self:incrementPlayerComponentPools()
		while self.currentRoundIndex < #self.roundQueue do
			-- Intermission
			for i = 5, 1, -1 do
				print("Intermission: " .. i)
				task.wait(1)
			end

			-- Start round
			self:NextRound()

			if self.currentRoundIndex == 3 then
				self.stage += 1
				self:incrementPlayerComponentPools()
				print(string.format("Start of stage %d", self.stage))
				-- elseif self.currentRoundIndex == 9 then
				-- 	self.stage += 1
				-- 	print(string.format("Start of stage %d", self.stage))
				-- elseif self.currentRoundIndex == 15 then
				-- 	self.stage += 1
				-- 	print(string.format("Start of stage %d", self.stage))
				-- elseif self.currentRoundIndex == 21 then
				-- 	self.stage += 1
				-- 	print(string.format("Start of stage %d", self.stage))
			end

			local round = self.currentRound

			-- Drive the timer manually
			while not round:IsFinished() do
				round:Update(1)
				wait(1)
			end
		end

		print("All rounds complete!")
	end
end

function Game:GetInstance()
	return instance or Game.new()
end

function Game:Get(property)
	return self[property]
end

function Game:RegisterPlayer(playerObj)
	self.players[playerObj.userId] = playerObj
	self.characterToPlayer[playerObj.character] = playerObj
	table.insert(self.alivePlayers, playerObj)
	playerObj.character:SetAttribute("Player", true)
	self:SortPlayersByHealth()
end

function Game:UnregisterCharacter(model)
	self.characterToPlayer[model] = nil
end

function Game:GetPlayerFromCharacter(model)
	return self.characterToPlayer[model]
end

return Game
