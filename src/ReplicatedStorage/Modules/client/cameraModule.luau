local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)
local Players = Services.Players
local TweenService = Services.TweenService
local RunService = Services.RunService

local CameraShaker = require(Services.Client:FindFirstChild("cameraShaker"):FindFirstChild("CameraShaker"))
local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)
local player = Players.LocalPlayer

local cameraInst = Services.Workspace:WaitForChild("Camera")
local cameraPart =
	Services.Workspace:WaitForChild("MenuFolder"):WaitForChild("MenuCamera"):WaitForChild("menuCameraPart").CFrame

local originalFOV = 70

local sprintFOVChange = 10
local sprintFOVTweenTime = 0.75

local fovTween
local bobConnection
local bobAmplitude = 0.075 -- How far the camera bobs (height)
local bobFrequency = 15 -- How fast the camera bobs
local bobTime = 0

local module = {}

function module.menuCam()
	repeat
		task.wait()
		cameraInst.CameraType = Enum.CameraType.Scriptable
	until cameraInst.CameraType == Enum.CameraType.Scriptable
	--Send the camera to cameraPart we created for custom menu camera.
	cameraInst.CFrame = cameraPart
end

function module.normCam()
	local camera = game.Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
end

-- FX

function module.CameraShakeHeavy(character, duration)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local surfTest = Instance.new("SurfaceAppearance")
	surfTest.Parent = humanoid

	task.spawn(function()
		local startTime = os.clock()

		repeat
			local endTime = os.clock()

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
		local startTime = os.clock()

		repeat
			local endTime = os.clock()

			local XOffset = math.random(-50, 50) / 2000
			local YOffset = math.random(-50, 50) / 2000
			local ZOffset = math.random(-50, 50) / 2000

			humanoid.CameraOffset = Vector3.new(XOffset, YOffset, ZOffset)

			task.wait()

		until endTime - startTime >= duration

		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end)
end

function module.Flash(data)
	local camera = workspace.CurrentCamera or data.camera
	local tim = data.tim or 1
	local request = data.request

	if request and script.Parent.camEffects:FindFirstChild(request) then
		local effect = script.Parent.camEffects[request]:Clone()
		effect.Parent = camera
		effect.Enabled = true

		game.Debris:AddItem(effect, tim)
	else
		warn(request, "does not exist in effects folder!")
	end
end

function module.Blur(data)
	local camera = workspace.CurrentCamera or data.camera
	local tim1, tim2 = data.tim1 or 0.5, data.tim2
	local EasingStyleDirc = data.EasingStyleDirc or Enum.EasingDirection.Out
	local EasingStyle = data.EasingStyle or Enum.EasingStyle.Sine
	local EasingStyle2 = data.EasingStyle2 or EasingStyle
	local size = data.size or 7
	local wait_till_normalFov = data.wait_till_normalFov or tim1

	coroutine.wrap(function()
		local blur = script.Parent.camEffects["Blur"]:Clone()
		blur.Parent = camera
		blur.Size = 0

		-- tween
		tweenHelper:Tween(blur, { tim1, EasingStyle, EasingStyleDirc }, { Size = size }):Play()

		task.wait(wait_till_normalFov)

		tweenHelper:Tween(blur, { tim2 or tim1, EasingStyle2, EasingStyleDirc }, { Size = 0 })

		game.Debris:AddItem(blur, tim2 or tim1)
	end)()
end

function module.Shake(data)
	local camera = workspace.CurrentCamera or data.camera
	local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
		camera.CFrame = camera.CFrame * shakeCFrame
	end)

	local shake = data.shake or "Bump"
	camShake:Start()
	camShake:Shake(CameraShaker.Presets[shake])
end

function module.EnableSprintPOV()
	fovTween = TweenService:Create(
		game.Workspace.CurrentCamera,
		TweenInfo.new(sprintFOVTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = originalFOV + sprintFOVChange }
	)
	fovTween:Play()

	-- Start camera bobbing
	if not bobConnection then
		bobTime = 0
		local camera = workspace.CurrentCamera

		bobConnection = RunService.RenderStepped:Connect(function(dt)
			bobTime += dt
			local offsetY = math.sin(bobTime * bobFrequency) * bobAmplitude

			-- Apply a small vertical offset relative to the camera's current rotation
			camera.CFrame = camera.CFrame * CFrame.new(0, offsetY, 0)
		end)
	end
end

function module.DisableSprintPOV()
	local camera = game.Workspace.CurrentCamera
	if camera.FieldOfView ~= originalFOV then
		if fovTween then
			fovTween:Cancel()
		end
		fovTween = TweenService:Create(
			camera,
			TweenInfo.new(sprintFOVTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FieldOfView = originalFOV }
		)
		fovTween:Play()

		-- Stop bobbing
		if bobConnection then
			bobConnection:Disconnect()
			bobConnection = nil
		end
	end
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
