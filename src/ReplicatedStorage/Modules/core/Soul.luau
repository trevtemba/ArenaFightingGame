local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))

local ServerStorage = game:GetService("ServerStorage")
local CollisionManager = require(script.Parent.CollisionManager)

local Soul = {}
Soul.__index = Soul

function Soul.new(soulType)
	local self = setmetatable({}, Soul)

	self.name = nil
	self.type = soulType
	self.character = nil
	self.animationHandler = nil

	return self
end

function Soul:Init()
	CollisionManager:SetCollisionGroupEntities(self.character)
end

function Soul:Cast()
	if self.type == "Engage" then
		--logic
	end
end

return Soul
