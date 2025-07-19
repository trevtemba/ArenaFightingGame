-- animationModule.lua
local animationModule = {}

local Players = game:GetService("Players")
local animations = {}

function animationModule.PreloadAll()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
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

function animationModule.Play(animName, fadeTime, looped)
	print("playing anim")
	local animTrack = animations[animName]
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

return animationModule
