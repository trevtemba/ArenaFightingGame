-- Modules/PlayerHandler.lua
local Game = require(script.Parent.Game)
local PlayerHandler = {}

function PlayerHandler.OnAttack(plr)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		local states = playerObj.stateHandler:GetAllStates()
		print(states)
		playerObj:Attack()
	end
end

function PlayerHandler.OnBlock(plr, activate)
	local playerObj = Game:GetInstance():GetPlayer(plr, activate)
	if playerObj then
		local states = playerObj.stateHandler:GetAllStates()
		print(states)
		playerObj:Block(activate)
	end
end

function PlayerHandler.OnSprint(plr, sprintState)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		local states = playerObj.stateHandler:GetAllStates()
		print(states)
		playerObj:SprintHandler(sprintState)
	end
end

function PlayerHandler.OnCast(plr, abilitySlot)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		local states = playerObj.stateHandler:GetAllStates()
		print(states)
		playerObj:CastAbility(abilitySlot)
	end
end

function PlayerHandler.OnDash(plr, direction)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		local states = playerObj.stateHandler:GetAllStates()
		print(states)
		playerObj:Dash(direction)
	end
end

function PlayerHandler.OnPickup(plr, orbId)
	local playerObj = Game:GetInstance():GetPlayer(plr)
	if playerObj then
		playerObj:PickupLoot(orbId)
	end
end

return PlayerHandler
