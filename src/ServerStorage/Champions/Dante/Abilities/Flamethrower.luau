local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HitboxHandler = require(ReplicatedStorage.Modules.core.HitboxHandler)
local STATE = require(ReplicatedStorage.Modules.core.State)
local castDone = ReplicatedStorage.RemoteEvents.Client.castDone
local Flamethrower = {}

Flamethrower.Config = {
	name = "Seismic Slam",
	type = "Damage",
	blockable = true,
	knocksBack = true,
	duration = 2.5,
	cooldown = 5,
	damage = 40,
	hitboxType = "cone",
	hitboxParams = {
		range = 10,
		angle = 60,
	},
}

function Flamethrower:Cast(combatHandler, animName)
	local attacker = combatHandler.owner

	combatHandler.owner.animationHandler:Play(animName, 0, 3, 1, false, "Action3")
	-- When starting the attack (before connecting or right at anim start)
	combatHandler._castSessionId = (combatHandler._castSessionId or 0) + 1
	local sessionId = combatHandler._castSessionId

	-- Deal damage on hit marker
	combatHandler.owner.animationHandler:ConnectMarker(animName, "fire", function()
		if combatHandler._castSessionId ~= sessionId then
			return
		end
		HitboxHandler:CreateConeHitbox({
			attacker = attacker,
			cframe = attacker.character.PrimaryPart.CFrame,
			range = self.Config.hitboxParams.range,
			angle = self.Config.hitboxParams.angle,
			onHit = function(entity)
				combatHandler:ApplyDamage(
					entity,
					self.Config.blockable,
					"ability",
					self.Config.knocksBack,
					nil,
					self.Config.damage
				)
			end,
		})
	end)

	task.delay(self.Config.duration, function()
		combatHandler.owner.stateHandler:RemoveState(STATE.Casting)
		castDone:FireClient(Players:GetPlayerByUserId(combatHandler.owner.userId))
	end)
end

return Flamethrower
