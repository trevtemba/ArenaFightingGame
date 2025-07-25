local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local highlightHelper = require(script.Parent.highlightHelper)
local Effects = ReplicatedStorage:WaitForChild("Effects")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")

return function(argumentData)
	local target = argumentData.target
	local initiateType = argumentData.initiateType

	if target and initiateType then
		local highlightColor = Color3.fromRGB(255, 0, 0)
		local innerTransparency = 0.85
		local outerTransparency = 1
		local sound
		if initiateType == "block" then
			sound = Sounds:FindFirstChild("startBlock"):Clone()
			highlightColor = Color3.fromRGB(255, 204, 19)
			outerTransparency = 0.1
		end

		sound.Parent = target
		sound:Play()

		local highlight = highlightHelper:highlightCharacter(
			target,
			highlightColor,
			innerTransparency,
			outerTransparency,
			false,
			"pulse",
			0.25
		)
		Debris:AddItem(sound, 1)
		Debris:AddItem(highlight, 1)
	end
end
