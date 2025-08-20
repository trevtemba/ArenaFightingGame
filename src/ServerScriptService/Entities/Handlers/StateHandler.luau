local StateHandler = {}
StateHandler.__index = StateHandler

function StateHandler.new()
	local self = setmetatable({}, StateHandler)

	self.states = {}

	return self
end

function StateHandler:SetState(state)
	self.states[state] = true
end

function StateHandler:RemoveState(state)
	if self.states[state] then
		self.states[state] = nil
	end
end

function StateHandler:HasState(state)
	return self.states[state] == true
end

function StateHandler:HasAny(states)
	for _, state in ipairs(states) do
		if self:HasState(state) then
			return true
		end
	end
	return false
end

function StateHandler:ClearStates()
	for k in pairs(self.states) do
		self.states[k] = nil
	end
end

function StateHandler:GetAllStates()
	local list = {}
	for state in pairs(self.states) do
		table.insert(list, state)
	end
	return list
end

return StateHandler
