local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local Players = Services.Players

local HitboxHandler = require(Services.EntityUtils.HitboxHandler)
local STATE = require(Services.Core.State)

local castDone = Services.ClientEvents.castDone
local clientEffects = Services.ClientEvents.clientEffects

local Flamethrower = {}

Flamethrower.Config = {
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
	stunTime = 1,
}

function Flamethrower:Cast(combatHandler, animName)
	local attacker = combatHandler.owner

	combatHandler.owner.animationHandler:Play(animName, 0.25, 3, 1, false, "Action3")
	-- When starting the attack (before connecting or right at anim start)
	combatHandler._castSessionId = (combatHandler._castSessionId or 0) + 1
	local sessionId = combatHandler._castSessionId

	-- Deal damage on hit marker
	combatHandler.owner.animationHandler:ConnectMarker(animName, "fire", function()
		if combatHandler._castSessionId ~= sessionId then
			return
		end

		clientEffects:FireAllClients(
			"flameThrower",
			{ target = combatHandler.owner.character, duration = self.Config.duration }
		)
		for tick = 1, 4 do
			HitboxHandler:CreateConeHitbox({
				attacker = attacker,
				cframe = attacker.character.PrimaryPart.CFrame,
				range = self.Config.hitboxParams.range,
				angle = self.Config.hitboxParams.angle,
				onHit = function(entity)
					combatHandler:ApplyDamage({
						entity = entity,
						blockable = self.Config.blockable,
						type = "ability",
						knocksBack = self.Config.knocksBack,
						isAirCombo = nil,
						abilityDamage = self.Config.damage,
						attackAction = "default",
						stunTime = self.Config.stunTime,
					})
				end,
			})
			task.wait(0.5)
		end
	end)

	task.delay(self.Config.duration, function()
		combatHandler.owner.stateHandler:RemoveState(STATE.Casting)
		castDone:FireClient(Players:GetPlayerByUserId(combatHandler.owner.userId))
	end)
end

return Flamethrower
