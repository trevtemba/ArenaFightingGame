local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoulHandler = require(ServerScriptService.Entities.Handlers.SoulHandler)
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Players = Services.Players
local CollectionService = Services.CollectionService
local HitboxHandler = require(Services.EntityUtils.HitboxHandler)
local FindTarget = require(Services.EntityUtils.FindTarget)

local STATE = require(Services.Enums.State)

local soulCastDone = Services.ClientEvents.soulCastDone
local clientAbilityEffects = Services.ClientEvents.clientAbilityEffects
local clientEffects = Services.ClientEvents.clientEffects

local Ability = {}

Ability.Config = {
	name = "Love tap",
	type = "Damage",
	blockable = true,
	blockable360 = true,
	knocksBack = false,
	damage = 5,
	targetType = "lockOn",
	duration = 1,
	stunTime = 1,
}

function Ability:Cast(soulHandler, isVisible, argumentData)
	clientEffects:FireAllClients("initiate", { target = soulHandler.owner.character, initiateType = "cast" })
	local target = argumentData.target
	if target then
		local soulChar = soulHandler.character
		local combatHandler = soulHandler.owner.combatHandler

		local targetEntity
		if CollectionService:HasTag(target, "Enemy") or CollectionService:HasTag(target, "Dummy") then
			targetEntity = soulHandler.owner:GetEnemyFromCharacter(target)
		else
			targetEntity = soulHandler.owner:GetPlayerFromCharacter(target)
		end

		if isVisible then
			soulHandler:ToggleVisibility(false)
		end
		clientAbilityEffects:FireAllClients("loveTap", "soul", { target = target, soulType = soulHandler.type })

		if targetEntity then
			task.delay(0.25, function()
				combatHandler:ApplyDamage({
					entity = targetEntity,
					blockable = self.Config.blockable,
					blockable360 = self.Config.blockable360,
					type = "ability",
					knocksBack = self.Config.knocksBack,
					isAirCombo = nil,
					abilityDamage = self.Config.damage,
					attackAction = "default",
					stunTime = self.Config.stunTime,
				})
			end)
		else
			warn("soulability: target doesn't contain entity tag")
		end

		task.delay(self.Config.duration, function()
			if isVisible then
				soulHandler:ToggleVisibility(isVisible)
			end
		end)
	end
	print(target)
	task.delay(soulHandler.cooldown, function()
		soulCastDone:FireClient(Players:GetPlayerByUserId(soulHandler.owner.userId))
	end)
end

return Ability
