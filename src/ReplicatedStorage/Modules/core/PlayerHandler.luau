-- Modules/PlayerHandler.lua
local Game = require(script.Parent.Game)
local PlayerHandler = {}

function PlayerHandler.OnAttack(plr: Player, spaceHeld)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:Attack(spaceHeld)
	end
end

function PlayerHandler.OnCast(plr: Player, abilitySlot)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:Cast(abilitySlot)
	end
end

function PlayerHandler.OnSoulCast(plr: Player)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:SoulCast()
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

function PlayerHandler.OnDash(plr: Player, direction)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:Dash(direction)
	end
end
function PlayerHandler.OnDev(plr: Player, devCode)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:ReturnDev(devCode)
	end
end

return PlayerHandler
