local module = {}

--// SERVICES \\--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
--// VARIABLES \\--
local Player = Players.LocalPlayer -- Get local player
local Character = Player.Character or Player.CharacterAdded:Wait() -- Get player character

function module.CameraShakeHeavy(duration)

	local humanoid = Character:FindFirstChild("Humanoid")
	local surfTest = Instance.new("SurfaceAppearance")
	surfTest.Parent = humanoid

	task.spawn(function()

		local startTime = tick()

		repeat

			local endTime = tick()

			local XOffset = math.random(-50, 50) / 1000
			local YOffset = math.random(-50, 50) / 1000
			local ZOffset = math.random(-50, 50) / 1000

			Character:FindFirstChild("Humanoid").CameraOffset = Vector3.new(XOffset, YOffset, ZOffset)

			task.wait()

		until endTime - startTime >= duration	

		Character:FindFirstChild("Humanoid").CameraOffset = Vector3.new(0, 0, 0)

	end)

end

function module.CameraShakeLight(duration)

	local humanoid = Character:FindFirstChild("Humanoid")
	local surfTest = Instance.new("SurfaceAppearance")
	surfTest.Parent = humanoid

	task.spawn(function()

		local startTime = tick()

		repeat

			local endTime = tick()

			local XOffset = math.random(-50, 50) / 2000
			local YOffset = math.random(-50, 50) / 2000
			local ZOffset = math.random(-50, 50) / 2000

			Character:FindFirstChild("Humanoid").CameraOffset = Vector3.new(XOffset, YOffset, ZOffset)

			task.wait()

		until endTime - startTime >= duration	

		Character:FindFirstChild("Humanoid").CameraOffset = Vector3.new(0, 0, 0)

	end)

end

return module
