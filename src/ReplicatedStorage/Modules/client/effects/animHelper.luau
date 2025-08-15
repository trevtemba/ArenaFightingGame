local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimHelper = {}

AnimHelper.AnimationsFolder = ReplicatedStorage:FindFirstChild("Animations")

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
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

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

return AnimHelper
