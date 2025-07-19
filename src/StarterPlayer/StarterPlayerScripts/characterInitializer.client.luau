-- CharacterInitializer (LocalScript, e.g. in StarterPlayerScripts)

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local AnimationHandler = require(game:GetService("ReplicatedStorage").Modules.client.animationModule)
local ShiftlockModule = require(game:GetService("ReplicatedStorage").Modules.client.smoothShiftlock.SmoothShiftLock)

local player = Players.LocalPlayer

local BindableFunctions = game:GetService("ReplicatedStorage"):WaitForChild("BindableFunctions")
local isCharLoaded = BindableFunctions:WaitForChild("charLoaded")

local charLoaded = false

isCharLoaded.OnInvoke = function()
	return charLoaded
end

-- Function to process the character if it has the "player" tag
local function processCharacter(character)
	if CollectionService:HasTag(character, "player") then
		print("Processing tagged player character:", character.Name)
		local humanoid = character:WaitForChild("Humanoid")
		local animator = humanoid:WaitForChild("Animator")

		-- Your initialization logic here
		AnimationHandler.PreloadAll()
		charLoaded = true
		ShiftlockModule.new()
	else
		warn("Character does not have 'player' tag, skipping.")
	end
end

-- Wait for the character and run the check
local function onCharacterAdded(character)
	if character:IsDescendantOf(game) then
		processCharacter(character)
	else
		character.AncestryChanged:Wait()
		processCharacter(character)
	end
end

-- Initial setup
if player.Character then
	onCharacterAdded(player.Character)
end

-- Listen for future character spawns
player.CharacterAdded:Connect(onCharacterAdded)
