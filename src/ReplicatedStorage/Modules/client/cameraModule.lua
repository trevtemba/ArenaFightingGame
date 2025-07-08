local module = {}

local TweenService = game:GetService("TweenService")

local cameraInst = workspace:WaitForChild("Camera")
local cameraPart = workspace:WaitForChild("MenuFolder"):WaitForChild("MenuCamera"):WaitForChild("menuCameraPart").CFrame

function module.menuCam()
	repeat
		task.wait()
		cameraInst.CameraType = Enum.CameraType.Scriptable
	until cameraInst.CameraType == Enum.CameraType.Scriptable
	--Send the camera to cameraPart we created for custom menu camera.
	cameraInst.CFrame = cameraPart
end

function module.normCam()
	local camera = game.Workspace.Camera
	camera.CameraType = Enum.CameraType.Custom
end

-- FX

function module.CameraShakeHeavy(character, duration)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local surfTest = Instance.new("SurfaceAppearance")
	surfTest.Parent = humanoid

	task.spawn(function()
		local startTime = tick()

		repeat
			local endTime = tick()

			local XOffset = math.random(-50, 50) / 1000
			local YOffset = math.random(-50, 50) / 1000
			local ZOffset = math.random(-50, 50) / 1000

			humanoid.CameraOffset = Vector3.new(XOffset, YOffset, ZOffset)

			task.wait()

		until endTime - startTime >= duration

		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end)
end

function module.CameraShakeLight(character, duration)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local surfTest = Instance.new("SurfaceAppearance")
	surfTest.Parent = humanoid

	task.spawn(function()
		local startTime = tick()

		repeat
			local endTime = tick()

			local XOffset = math.random(-50, 50) / 2000
			local YOffset = math.random(-50, 50) / 2000
			local ZOffset = math.random(-50, 50) / 2000

			humanoid.CameraOffset = Vector3.new(XOffset, YOffset, ZOffset)

			task.wait()

		until endTime - startTime >= duration

		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end)
end

return module
