local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local animHelper = require(script.Parent.animHelper)
local particleHelper = require(script.Parent.particleHelper)
local soundHelper = require(script.Parent.soundHelper)
local Effects = ReplicatedStorage:WaitForChild("Effects")

return function(argumentData)
	local target: Model = argumentData.target
	local weapon: string = argumentData.weapon
	local combo: number = argumentData.combo

	if target and weapon then
		if combo then
			if combo == 5 then
				task.delay(0.25, function()
					local swingSound = soundHelper.PlaySound((weapon .. "Swing"), target.PrimaryPart, 0.05)
					Debris:AddItem(swingSound, 1)
				end)
			else
				task.delay(0.1, function()
					local swingSound = soundHelper.PlaySound((weapon .. "Swing"), target.PrimaryPart, 0.05)
					Debris:AddItem(swingSound, 1)
				end)
			end
		end
	end
end
