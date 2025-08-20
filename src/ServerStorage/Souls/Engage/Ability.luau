local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local Players = Services.Players
local HitboxHandler = require(Services.EntityUtils.HitboxHandler)

local STATE = require(Services.Core.State)

local soulCastDone = Services.ClientEvents.castDone
local clientEffects = Services.ClientEvents.clientEffects

local Ability = {}

Ability.Config = {
	name = "Love tap",
	type = "Damage",
	blockable = true,
	knocksBack = false,
	damage = 5,
	hitboxType = "cone",
	hitboxParams = {
		range = 50,
		angle = 60,
	},
}

function Ability:Cast(soulHandler)
	print("CASTING SOUL ABILITY")
	task.delay(soulHandler.cooldown, function()
		soulCastDone:FireClient(Players:GetPlayerByUserId(soulHandler.owner.userId))
	end)
end

return Ability
