local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Souls = ServerStorage.Souls
local CollisionManager = require(script.Parent.CollisionManager)

local mockRootPart = ReplicatedStorage:WaitForChild("Misc"):FindFirstChild("MockRootPart")

local SoulHandler = {}
SoulHandler.__index = SoulHandler

function SoulHandler.new(playerObj)
	local self = setmetatable({}, SoulHandler)

	self.owner = playerObj
	self.cooldown = nil
	self.character = nil
	self.ability = nil
	self.animationHandler = nil
	self.instanceObjects = {}

	self:Init()
	return self
end

function SoulHandler:Init()
	local data = require(Souls:FindFirstChild(self.owner.soulType):FindFirstChild("Data"))
	self.cooldown = data.cooldown
	self.character = data.rig
	self.ability = data.ability

	self.character.Parent = game.Workspace.Assets
	self.instanceObjects = self:AttachToPlayer()

	self.animationHandler = AnimationHandler.new(self.character)
	self.owner.character:SetAttribute("soulAbilityCd", self.cooldown)
	CollisionManager:SetCollisionGroupEntities(self.character)
end

function SoulHandler:AttachToPlayer()
	local playerCharacter = self.owner.character

	local att0 = Instance.new("Attachment")
	att0.Name = "SoulAttach" .. "_Base"
	att0.Parent = self.character.PrimaryPart

	local att1 = Instance.new("Attachment")
	att1.Name = "SoulAttach" .. "_Target"
	att1.Parent = playerCharacter.PrimaryPart

	local alignP = Instance.new("AlignPosition")
	alignP.Name = "SoulAttach"
	alignP.Mode = Enum.PositionAlignmentMode.TwoAttachment
	alignP.MaxForce = 5e5
	alignP.Responsiveness = 200

	local alignO = Instance.new("AlignOrientation")
	alignO.Name = "SoulAttach"
	alignO.Mode = Enum.OrientationAlignmentMode.TwoAttachment
	alignO.Responsiveness = 200

	alignP.Attachment0 = att0
	alignP.Attachment1 = att1
	alignP.Parent = self.character:FindFirstChild("physicsAssets")

	alignO.Attachment0 = att0
	alignO.Attachment1 = att1
	alignO.Parent = self.character:FindFirstChild("physicsAssets")

	return alignP, alignO, att0, att1
end

function SoulHandler:Cast()
	self.ability:Cast(self)
end
function SoulHandler:Show()
	print("showing soul")
end

return SoulHandler
