-- animationModule.lua
local animationModule = {}

local Players = game:GetService("Players")
local animations = {}
local animationConnections = {}
local animator = nil

function animationModule.PreloadAll()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Name = "ClientAnimator"
		animator.Parent = humanoid
	end

	local animFolder = character:FindFirstChild("Animations")
	if not animFolder then
		return
	end

	for _, anim in pairs(animFolder:GetChildren()) do
		if anim:IsA("Animation") then
			local animTrack = animator:LoadAnimation(anim)
			animTrack.Priority = Enum.AnimationPriority.Action
			animations[anim.Name] = animTrack
			animTrack:Play()
			animTrack:Stop()
		end
	end
end

function animationModule.Play(animName, fadeTime, looped, priority)
	local animTrack = animations[animName]

	if priority then
		animTrack.Priority = Enum.AnimationPriority[priority]
	end
	if animTrack then
		animTrack.Looped = looped or false
		animTrack:Play(fadeTime)
	end
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
	local animTrack = animations[animName]
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
	local animTrack = animations[animName]
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
