local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local RoundManager = require(Services.Server.RoundManager)

local roundTypes = {
	"PvE",
	"PvP",
	"Augment",
	"Carousel",
	"Training",
}

local roundDuration = {
	60,
	60,
	30,
	60,
	1000,
}
local Round = {}

Round.__index = Round

function Round.new(typeIndex, stage)
	local self = setmetatable({}, Round)

	self.type = typeIndex
	self.name = roundTypes[typeIndex]
	self.stage = stage
	self.duration = roundDuration[typeIndex]
	self.elapsed = 0
	self.active = false
	self.onComplete = nil -- optional callback

	return self
end

function Round:Start(plrObjs)
	self.active = true
	self.elapsed = 0

	if self.type == 1 then
		RoundManager.RunPve(self.stage, plrObjs)
	elseif self.type == 2 then
		RoundManager.RunPvp(self.stage, plrObjs)
	elseif self.type == 3 then
		RoundManager.RunAugment(self.stage, plrObjs)
	elseif self.type == 4 then
		RoundManager.RunCarousel(self.stage, plrObjs)
	elseif self.type == 5 then
		RoundManager.RunTraining(plrObjs)
	end

	print("Started " .. self.name .. " round for " .. self.duration .. " seconds.")
end

function Round:Update(dt)
	if not self.active then
		return false
	end

	self.elapsed += dt
	--print(self.name .. " Round - Time Left: " .. math.max(0, self.duration - self.elapsed))

	if self.elapsed >= self.duration then
		self.active = false
		print(self.name .. " round complete.")
		if self.onComplete then
			self.onComplete()
		end
		return true
	end

	return false
end

function Round:IsFinished()
	return not self.active
end

return Round
