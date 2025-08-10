local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitboxHandler = require(ReplicatedStorage.Modules.core.HitboxHandler)
local STATE = require(ReplicatedStorage.Modules.core.State)
local castDone = ReplicatedStorage.RemoteEvents.Client.castDone
local clientEffects = game:GetService("ReplicatedStorage").RemoteEvents.Client.clientEffects

local Ability = {}

Ability.Config = {
	name = "Seismic Slam",
	type = "Damage",
	blockable = true,
	knocksBack = false,
	duration = 2,
	damage = 25,
	hitboxType = "cone",
	hitboxParams = {
		range = 50,
		angle = 60,
	},
}

function Ability:Cast()
	print("CASTING SOUL ABILITY")
end

return Ability
