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

function module.CameraSway(character, direction)
	local camera = workspace.CurrentCamera
	if not camera or not character then
		return
	end

	-- Optional: Only sway if player has control of the camera
	if camera.CameraType ~= Enum.CameraType.Custom then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local swayDirection = direction or "right" -- "left" or "right"
	local swayAmount = Vector3.new(0.15, 0.05, 0)
	local rollAngle = math.rad(2.5) -- 2.5 degrees of roll
	if swayDirection == "left" then
		swayAmount = Vector3.new(-0.15, 0.05, 0)
		rollAngle = -rollAngle
	end

	local swayDuration = 0.08
	local originalOffset = humanoid.CameraOffset
	local originalCFrame = camera.CFrame

	-- Apply position sway via Humanoid.CameraOffset
	local swayTween =
		TweenService:Create(humanoid, TweenInfo.new(swayDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CameraOffset = originalOffset + swayAmount,
		})
	swayTween:Play()

	-- Simultaneously apply camera roll by briefly setting Scriptable camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = originalCFrame * CFrame.Angles(0, 0, rollAngle)

	-- Wait then revert
	task.delay(swayDuration, function()
		-- Smooth return of CameraOffset
		local returnTween =
			TweenService:Create(humanoid, TweenInfo.new(swayDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CameraOffset = originalOffset,
			})
		returnTween:Play()

		-- Restore camera rotation
		camera.CFrame = originalCFrame
		camera.CameraType = Enum.CameraType.Custom
	end)
end

return module
