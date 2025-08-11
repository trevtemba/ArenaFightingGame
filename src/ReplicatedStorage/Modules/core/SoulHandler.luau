local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))

local ServerStorage = game:GetService("ServerStorage")
local Souls = ServerStorage.Souls
local CollisionManager = require(script.Parent.CollisionManager)

local SoulHandler = {}
SoulHandler.__index = SoulHandler

function SoulHandler.new(playerObj)
	local self = setmetatable({}, SoulHandler)

	self.owner = playerObj
	self.cooldown = nil
	self.character = nil
	self.ability = nil
	self.animationHandler = nil

	self:Init()
	return self
end

function SoulHandler:Init()
	local data = require(Souls:FindFirstChild(self.owner.soulType):FindFirstChild("Data"))
	self.cooldown = data.cooldown
	self.character = data.rig
	self.ability = data.ability

	self.animationHandler = AnimationHandler.new(self.character)

	CollisionManager:SetCollisionGroupEntities(self.character)
end

function SoulHandler:Cast()
	self.data.ability:Cast()
end

return SoulHandler
