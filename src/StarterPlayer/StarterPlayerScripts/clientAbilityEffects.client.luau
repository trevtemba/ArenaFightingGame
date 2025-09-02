local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local ClientModules = Services.Client

local clientAbilityEffects = Services.ClientEvents:WaitForChild("clientAbilityEffects")
local cachedChampAbilityEffects = {}
local cachedSoulAbilityEffects = {}

for _, module in ClientModules.effects.Abilities.Dante:GetChildren() do
	if module:IsA("ModuleScript") then
		cachedChampAbilityEffects[module.Name] = require(module)
	end
end
for _, module in ClientModules.effects.Abilities.Soul:GetChildren() do
	if module:IsA("ModuleScript") then
		cachedSoulAbilityEffects[module.Name] = require(module)
	end
end

clientAbilityEffects.OnClientEvent:Connect(function(effect, abilityType, argumentData)
	local foundEffect
	if abilityType == "champ" then
		foundEffect = cachedChampAbilityEffects[effect]
	elseif abilityType == "soul" then
		foundEffect = cachedSoulAbilityEffects[effect]
	end
	if foundEffect then
		foundEffect(argumentData)
	end
end)
