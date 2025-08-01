-- Modules/PlayerHandler.lua
local Game = require(script.Parent.Game)
local PlayerHandler = {}

function PlayerHandler.OnAttack(plr: Player, spaceHeld)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:Attack(spaceHeld)
	end
end

function PlayerHandler.OnBlock(plr: Player, activate)
	local playerObj = Game:GetInstance():GetPlayer(plr, activate)
	if playerObj then
		playerObj:Block(activate)
	end
end

function PlayerHandler.OnSprint(plr: Player, sprintState)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:SprintHandler(sprintState)
	end
end

function PlayerHandler.OnCast(plr: Player, abilitySlot)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:CastAbility(abilitySlot)
	end
end

function PlayerHandler.OnDash(plr: Player, direction)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:Dash(direction)
	end
end

return PlayerHandler
