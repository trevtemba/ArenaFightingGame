-- Modules/PlayerHandler.lua
local Game = require(script.Parent.Game)
local PlayerHandler = {}

function PlayerHandler.OnAttack(plr)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:Attack()
	end
end

function PlayerHandler.OnCast(plr, abilitySlot)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:CastAbility(abilitySlot)
	end
end

function PlayerHandler.OnDash(plr)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:Dash()
	end
end

function PlayerHandler.OnPickup(plr, orbId)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:PickupLoot(orbId)
	end
end

return PlayerHandler

