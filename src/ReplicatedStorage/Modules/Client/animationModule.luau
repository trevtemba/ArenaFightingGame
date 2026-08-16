local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Players = Services.Players

local animationModule = {}

local animations = {}
local animationConnections = {}
local animator = nil
local animFolder = nil
local loadedForCharacter = nil

local ANIM_FOLDER_TIMEOUT = 10

--[[
	The only animations this module ever plays. Everything else in the rig's
	Animations folder belongs to the server's AnimationHandler.

	Keeping an explicit list matters because both sides load onto the same
	Animator: it is the replicated one, so the client's FindFirstChildOfClass
	returns the instance the server already loaded the whole folder onto, and the
	rig's built-in Animate script adds roughly eighteen more. Loading the full
	folder a second time here pushed the total past the Animator's track cap, at
	which point Roblox silently refuses to play anything further. Ten tracks does
	not.
]]
local CLIENT_ANIMS = {
	"walkForward",
	"walkBack",
	"walkLeft",
	"walkRight",
	"sprint",
	"dashForward",
	"dashBack",
	"dashLeft",
	"dashRight",
	"landing",
}

local function getTrack(animName)
	local existing = animations[animName]
	if existing then
		return existing
	end

	if not animator or not animFolder then
		return nil
	end

	local anim = animFolder:FindFirstChild(animName)
	if not anim or not anim:IsA("Animation") then
		warn(`animationModule: no Animation named "{animName}" in the character's Animations folder`)
		return nil
	end

	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	animations[animName] = track

	--[[
		Warm the track before anyone plays it for real.

		LoadAnimation does not fetch the asset -- the first Play() does, and a
		track whose asset has not arrived yet does not play, it just does
		nothing. The server's AnimationHandler warms its tracks the same way at
		spawn, which is why attacks kept working while sprint and the dashes
		went dead once this module started creating tracks on demand.

		ContentProvider:PreloadAsync does not substitute for this: it resolves
		the asset for the content cache but never puts an AnimationTrack in a
		playable state.

		Play/Stop back to back is invisible -- the stop fade begins on the same
		frame, while the track's weight is still ~0, so nothing renders.
	]]
	track:Play()
	track:Stop()

	return track
end

-- Release this character's tracks and connections so a respawn does not stack a
-- second full set onto the Animator.
function animationModule.Cleanup()
	for animName in pairs(animationConnections) do
		animationModule.DisconnectAll(animName)
	end

	for _, track in pairs(animations) do
		track:Destroy()
	end

	table.clear(animations)
	table.clear(animationConnections)
	animator = nil
	animFolder = nil
	loadedForCharacter = nil
end

function animationModule.PreloadAll()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	if loadedForCharacter == character then
		return
	end
	if loadedForCharacter then
		animationModule.Cleanup()
	end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Name = "ClientAnimator"
		animator.Parent = humanoid
	end

	-- WaitForChild, not FindFirstChild: the folder is part of the server's rig and
	-- has no guaranteed replication order relative to the Humanoid. Missing it
	-- used to leave animFolder nil for the rest of the character's life, since
	-- nothing calls PreloadAll again.
	animFolder = character:WaitForChild("Animations", ANIM_FOLDER_TIMEOUT)
	if not animFolder then
		warn("animationModule: character has no Animations folder; client animations are disabled")
		return
	end

	-- Warm this module's own tracks now rather than on first use. Doing it here
	-- also gets them onto the Animator before the rig's Animate script fills it,
	-- so they are never the ones the track cap rejects.
	for _, animName in CLIENT_ANIMS do
		getTrack(animName)
	end

	loadedForCharacter = character
end

function animationModule.Play(animName, fadeTime, looped, priority)
	-- The nil check used to sit below the priority assignment, so calling Play
	-- with an unknown name and a priority threw instead of doing nothing.
	local animTrack = getTrack(animName)
	if not animTrack then
		return
	end

	if priority then
		animTrack.Priority = Enum.AnimationPriority[priority]
	end
	animTrack.Looped = looped or false
	animTrack:Play(fadeTime)
end

function animationModule.Stop(animName)
	local animTrack = animations[animName]
	if animTrack then
		animTrack:Stop()
	end
end

function animationModule.StopAll()
	if not animator then
		return
	end

	for _, track in animator:GetPlayingAnimationTracks() do
		track:Stop()
	end
end

function animationModule.StopAllExcept(anims)
	if not animator then
		return
	end

	-- Build a set of AnimationIds to keep
	local allowedIds = {}
	for key, val in pairs(anims) do
		if typeof(key) == "string" and val == true and animations[key] then
			local animTrack = animations[key]
			if animTrack.Animation then
				allowedIds[animTrack.Animation.AnimationId] = true
			end
		end
	end

	for _, track in animator:GetPlayingAnimationTracks() do
		local id = track.Animation and track.Animation.AnimationId
		if not allowedIds[id] then
			track:Stop()
		end
	end
end

function animationModule.ConnectEvent(animName, markerName, callback)
	-- getTrack, not a raw lookup: a caller may connect a marker before the
	-- animation has ever been played, which is when it gets loaded.
	local animTrack = getTrack(animName)
	if not animTrack then
		return
	end

	animationConnections[animName] = animationConnections[animName] or {}

	-- Disconnect old marker connection
	if animationConnections[animName][markerName] then
		animationConnections[animName][markerName]:Disconnect()
	end

	-- Connect new one
	local conn = animTrack:GetMarkerReachedSignal(markerName):Connect(callback)
	animationConnections[animName][markerName] = conn
end

function animationModule.ConnectStopped(animName, callback)
	local animTrack = getTrack(animName)
	if not animTrack then
		return
	end

	animationConnections[animName] = animationConnections[animName] or {}

	-- Disconnect old stopped connection
	if animationConnections[animName].stopped then
		animationConnections[animName].stopped:Disconnect()
	end

	-- Connect new stopped
	local conn = animTrack.Stopped:Connect(callback)
	animationConnections[animName].stopped = conn
end

function animationModule.DisconnectAll(animName)
	if animationConnections[animName] then
		for _, conn in pairs(animationConnections[animName]) do
			if conn.Connected then
				conn:Disconnect()
			end
		end
		animationConnections[animName] = nil
	end
end

return animationModule
