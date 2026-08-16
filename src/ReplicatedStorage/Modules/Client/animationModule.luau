local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local Players = Services.Players
local ContentProvider = game:GetService("ContentProvider")

local animationModule = {}

local animations = {}
local animationConnections = {}
local animator = nil
local animFolder = nil
local loadedForCharacter = nil

--[[
	Tracks are loaded on first use rather than all at once.

	An Animator caps how many AnimationTracks it will hold, and the server's
	AnimationHandler already loads every animation in the rig's Animations
	folder onto this same Animator (it is the replicated one, so the client's
	FindFirstChildOfClass returns it). Eagerly loading the whole folder here
	loaded all of them a second time, and the rig's built-in Animate script adds
	roughly eighteen more on top. That pushed the total past the cap, at which
	point Roblox silently refuses to play anything further -- which surfaced as
	attack and hit animations intermittently not appearing.

	The client only ever plays a handful of these (movement, dashes, landing),
	so loading on demand keeps the Animator well under the limit. The assets are
	still downloaded up front by PreloadAll, so first use does not stall.
]]
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
		return nil
	end

	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	animations[animName] = track
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

	animFolder = character:FindFirstChild("Animations")
	if not animFolder then
		return
	end

	-- Download the assets without creating tracks. The previous implementation
	-- called Play() then Stop() on every track to force the download, which put
	-- the entire folder on the Animator at once.
	local assets = {}
	for _, anim in animFolder:GetChildren() do
		if anim:IsA("Animation") then
			table.insert(assets, anim)
		end
	end

	local ok, err = pcall(function()
		ContentProvider:PreloadAsync(assets)
	end)
	if not ok then
		warn("Animation preload failed:", err)
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
