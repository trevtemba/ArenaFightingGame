local ReplicatedStorage = game:GetService("ReplicatedStorage")
local soundHelper = {}

function soundHelper.PlaySound(soundName, parent, pitchShiftRange)
	local soundFolder = ReplicatedStorage:FindFirstChild("Sounds")
	if not soundFolder then
		warn("Sounds folder missing from ReplicatedStorage")
		return
	end

	local sound = soundFolder:FindFirstChild(soundName)
	if not sound then
		warn("Invalid sound name:", soundName)
		return
	end

	local soundClone = sound:Clone()
	soundClone.Parent = parent

	if pitchShiftRange then
		local shift = soundClone:FindFirstChildOfClass("PitchShiftSoundEffect")
		if shift then
			local variation = (math.random() * 2 - 1) * pitchShiftRange
			shift.Octave += variation
		end
	end

	soundClone:Play()

	return soundClone
end

return soundHelper
