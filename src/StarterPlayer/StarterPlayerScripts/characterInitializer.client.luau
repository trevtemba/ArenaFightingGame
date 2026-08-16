local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Players = Services.Players
local player = Players.LocalPlayer
local CollectionService = Services.CollectionService

local cameraModule = require(Services.Client.cameraModule)
local viewportHandler = require(Services.Client.viewportHandler)
local AnimationHandler = require(Services.Client.animationModule)
local ShiftlockModule = require(Services.Client.smoothShiftlock.SmoothShiftLock)

local isCharLoaded = Services.BindableFunctions:WaitForChild("charLoaded")

local charLoaded = false

isCharLoaded.OnInvoke = function()
	return charLoaded
end

--[[
	Readiness is published as an attribute as well as through the charLoaded
	BindableFunction. The BindableFunction can only be polled, and everything
	below PreloadAll happens after a yield, so a consumer that polls at the
	wrong moment gets `false` and has no way to find out when that changes.
	inputHandler lost that race on every spawn. The attribute gives consumers
	something they can actually wait on.
]]
local function setCharacterReady(ready)
	charLoaded = ready
	player:SetAttribute("CharacterReady", ready)
end

-- Function to process the character if it has the "player" tag
local function processCharacter(character)
	if CollectionService:HasTag(character, "Player") then
		print("Processing tagged player character:", character.Name)
		local humanoid = character:WaitForChild("Humanoid")
		-- Barrier, not a value: PreloadAll below needs the Animator to exist.
		humanoid:WaitForChild("Animator")
		humanoid.JumpPower = 80
		humanoid.CameraOffset = Vector3.new(0, 1.5, 0)
		-- Your initialization logic here
		AnimationHandler.PreloadAll()
		setCharacterReady(true)
		ShiftlockModule.new()
		cameraModule.normCam()
		viewportHandler.InitCoin()
	else
		warn("Character does not have 'player' tag, skipping.")
	end
end

-- Wait for the character and run the check
local function onCharacterAdded(character)
	-- The old character's handlers no longer apply; clear readiness so anything
	-- waiting blocks until this one is actually initialized.
	setCharacterReady(false)

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
