local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local AnimHelper = {}

AnimHelper.AnimationsFolder = Services.ReplicatedStorage:FindFirstChild("Animations")

function AnimHelper:PlayAnimation(rig, name, fadeTime, weight, speed, looped, priority)
	if not self.AnimationsFolder then
		warn("AnimHelper: AnimationsFolder not set. Set AnimHelper.AnimationsFolder before calling PlayAnimation.")
		return
	end

	if not rig or not rig:FindFirstChild("Humanoid") then
		warn("AnimHelper: Invalid rig provided")
		return
	end

	local humanoid = rig:FindFirstChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid

	-- Find animation by name
	local animInstance = self.AnimationsFolder:FindFirstChild(name)
	if not animInstance or not animInstance:IsA("Animation") then
		warn("AnimHelper: Animation not found -", name)
		return
	end

	-- Prevent double-play
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation == animInstance then
			return track -- Already playing
		end
	end

	-- Load and configure animation
	local track = animator:LoadAnimation(animInstance)
	track.Looped = looped or false
	track.Priority = priority or Enum.AnimationPriority.Core
	track:Play(fadeTime or 0.1, weight or 1, speed or 1)

	return track
end

function AnimHelper:StopAll(rig)
	if not rig or not rig:FindFirstChild("Humanoid") then
		warn("AnimHelper: Invalid rig provided")
		return
	end

	local humanoid = rig:FindFirstChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end
end

function AnimHelper:StopAnimation(rig, name, fadeTime)
	if not rig or not rig:FindFirstChild("Humanoid") then
		warn("AnimHelper: Invalid rig provided")
		return
	end

	if not self.AnimationsFolder then
		warn("AnimHelper: AnimationsFolder not set. Set AnimHelper.AnimationsFolder before calling StopAnimation.")
		return
	end

	local humanoid = rig:FindFirstChild("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	local animInstance = self.AnimationsFolder:FindFirstChild(name)
	if not animInstance or not animInstance:IsA("Animation") then
		warn("AnimHelper: Animation not found -", name)
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation == animInstance then
			track:Stop(fadeTime or 0.1)
			return track
		end
	end
end

function AnimHelper:ConnectStopped(track, callback)
	if not track or typeof(callback) ~= "function" then
		warn("AnimHelper: Invalid track or callback for ConnectStopped")
		return
	end
	return track.Stopped:Connect(callback)
end

-- Connect function to animation marker reached
function AnimHelper:ConnectMarker(track, markerName, callback)
	if not track or typeof(markerName) ~= "string" or typeof(callback) ~= "function" then
		warn("AnimHelper: Invalid parameters for ConnectMarker")
		return
	end
	return track:GetMarkerReachedSignal(markerName):Connect(callback)
end

return AnimHelper
