local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)

local TableAttributes = require(Services.SharedUtils.TableAttributes)
local AnimationHandler = require(Services.EntityHandlers:WaitForChild("AnimationHandler"))
local CollisionManager = require(Services.EntityUtils.CollisionManager)
local CollectionService = Services.CollectionService
local RunService = Services.RunService
local Souls = Services.ServerStorage.Souls
local clientEffects = Services.ClientEvents.clientEffects

local SoulHandler = {}
SoulHandler.__index = SoulHandler

function SoulHandler.new(playerObj)
	local self = setmetatable({}, SoulHandler)

	self.owner = playerObj
	self.type = nil
	self.cooldown = nil
	self.character = nil
	self.visible = false
	self.ability = nil
	self.animationHandler = nil
	self.instanceObjects = {}

	self:Init()
	return self
end

function SoulHandler:Init()
	local data = require(Souls:FindFirstChild(self.owner.soulType):FindFirstChild("Data"))
	self.type = data.type
	self.cooldown = data.cooldown
	self.character = data.rig:Clone()
	self.ability = data.ability
	self.targetType = data.ability.Config.targetType

	self.character.Parent = game.Workspace.Assets.Souls
	self.animationHandler = AnimationHandler.new(self.character)

	self.instanceObjects = self:AttachToPlayer()

	-- For client effects, I don't want to use same rig for physics related movements
	local clientAssetClone = data.rig:Clone()
	clientAssetClone.Name = data.type

	if not Services.ClientAssets:FindFirstChild(clientAssetClone.Name) then
		clientAssetClone.Parent = Services.ClientAssets
	end

	local soulAbilityInfo = {
		cooldown = self.cooldown,
		targetType = self.targetType,
	}
	TableAttributes.Set(self.owner.character, "soulAbilityInfo", soulAbilityInfo)
	CollisionManager:SetCollisionGroupEntities(self.character)
	CollectionService:AddTag(self.character, "Soul")

	task.defer(function()
		self.animationHandler:Play("idle", nil, nil, nil, true, "Idle")
	end)
end

function SoulHandler:AttachToPlayer()
	local playerCharacter = self.owner.character

	local att0 = Instance.new("Attachment")
	att0.Name = "SoulAttachA" .. ""
	att0.Parent = self.character.PrimaryPart

	local alignP = Instance.new("AlignPosition")
	alignP.Name = "SoulAttachP"
	alignP.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignP.MaxForce = 5e5
	alignP.Responsiveness = 50

	local alignO = Instance.new("AlignOrientation")
	alignO.Name = "SoulAttach0"
	alignO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignO.Responsiveness = 50

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

	return { alignP = alignP, alignO = alignO, att = att0 }
end

function SoulHandler:Cast(argumentData)
	self.ability:Cast(self, self.visible, argumentData)
end
function SoulHandler:ToggleVisibility(visible)
	if visible then
		clientEffects:FireAllClients(
			"toggleSoulVisibility",
			{ target = self.character, visible = true, particleSkin = "default" }
		)
		self.visible = true
	else
		clientEffects:FireAllClients(
			"toggleSoulVisibility",
			{ target = self.character, visible = false, particleSkin = "default" }
		)
		self.visible = false
	end
end

return SoulHandler
