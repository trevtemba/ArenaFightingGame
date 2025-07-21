local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client")
local ClientRemotes = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client")

local clientEffects = ClientRemotes:WaitForChild("clientEffects")
local cachedEffects = {}

for _, module in ClientModules.effects:GetChildren() do
	if module:IsA("ModuleScript") then
		cachedEffects[module.Name] = require(module)
	end
end

clientEffects.OnClientEvent:Connect(function(effect, argumentData)
	local foundEffect = cachedEffects[effect]
	if foundEffect then
		foundEffect(argumentData)
	end
end)
