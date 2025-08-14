local AnimationHandler = require(script.Parent:WaitForChild("AnimationHandler"))
local RunService = game:GetService("RunService")
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
	self.animationHandler = AnimationHandler.new(self.character)

	self.instanceObjects = self:AttachToPlayer()
	self.owner.character:SetAttribute("soulAbilityCd", self.cooldown)
	CollisionManager:SetCollisionGroupEntities(self.character)
	task.delay(1, function()
		self.animationHandler:Play("idle", nil, nil, nil, true, "Idle")
	end)
end

function SoulHandler:AttachToPlayer()
	local playerCharacter = self.owner.character

	local att0 = Instance.new("Attachment")
	att0.Name = "SoulAttach" .. ""
	att0.Parent = self.character.PrimaryPart

	local alignP = Instance.new("AlignPosition")
	alignP.Name = "SoulAttach"
	alignP.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignP.MaxForce = 5e5
	alignP.Responsiveness = 20

	local alignO = Instance.new("AlignOrientation")
	alignO.Name = "SoulAttach"
	alignO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignO.Responsiveness = 20

	alignP.Attachment0 = att0
	alignP.Parent = self.character:FindFirstChild("physicsAssets")

	alignO.Attachment0 = att0
	alignO.Parent = self.character:FindFirstChild("physicsAssets")

	task.defer(function()
		RunService.Stepped:Connect(function()
			alignP.Position = playerCharacter.PrimaryPart.Position
				+ (playerCharacter.PrimaryPart.CFrame.lookVector * -3)
				+ (playerCharacter.PrimaryPart.CFrame.rightVector * 3)
			alignO.CFrame = playerCharacter.PrimaryPart.CFrame
		end)
	end)

	return alignP, alignO, att0
end

function SoulHandler:Cast()
	self.ability:Cast(self)
end
function SoulHandler:Show()
	print("showing soul")
end

return SoulHandler
