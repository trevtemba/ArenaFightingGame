local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Players = Services.Players
local HitboxHandler = require(Services.EntityUtils.HitboxHandler)
local FindTarget = require(Services.EntityUtils.FindTarget)

local STATE = require(Services.Enums.State)

local soulCastDone = Services.ClientEvents.soulCastDone
local clientEffects = Services.ClientEvents.clientEffects

local Ability = {}

Ability.Config = {
	name = "Love tap",
	type = "Damage",
	blockable = true,
	knocksBack = false,
	damage = 5,
	targetType = "lockOn",
	hitboxType = "cone",
	hitboxParams = {
		range = 50,
		angle = 60,
	},
}

function Ability:Cast(soulHandler, argumentData)
	local target = argumentData.target
	if target then
	end
	print(target)
	task.delay(soulHandler.cooldown, function()
		soulCastDone:FireClient(Players:GetPlayerByUserId(soulHandler.owner.userId))
	end)
end

return Ability
