local ComponentHandler = {}
ComponentHandler.__index = ComponentHandler

function ComponentHandler.new(owner)
	local self = setmetatable({}, ComponentHandler)
	self.owner = owner -- Reference to the player or npc that owns this handler
	self.foundComponents = {}
	self.components = {}
	return self
end

function ComponentHandler:AddComponent()
	-- todo
end

function ComponentHandler:RollComponent() end

function ComponentHandler:MergeComponents(component1, component2) end

function ComponentHandler:ApplyComponent(component) end

function ComponentHandler:IncrementComponentPool() end
return ComponentHandler
