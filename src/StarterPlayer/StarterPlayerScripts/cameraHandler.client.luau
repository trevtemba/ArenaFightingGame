local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local CameraShaker = require(Services.Client:WaitForChild("cameraShaker"):WaitForChild("CameraShaker"))

local ClientEvents = Services.ClientEvents

local attackEvent = ClientEvents:WaitForChild("attack")
local sprintEvent = ClientEvents:WaitForChild("sprint")

local TweenService = Services.TweenService
local camera = Services.Workspace.CurrentCamera

local player = Services.Players.LocalPlayer

local originalFOV = 70
local fovChange = 5
local resetDelay = 1
local returnTweenTime = 0.4
local zoomTweenTime = 0.25

local lastAttackTime = 0
local resetScheduled = false
local fovTween

local function resetFOV()
	if camera.FieldOfView ~= originalFOV then
		if fovTween then
			fovTween:Cancel()
		end
		fovTween = TweenService:Create(
			camera,
			TweenInfo.new(returnTweenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ FieldOfView = originalFOV }
		)
		fovTween:Play()
	end
	resetScheduled = false
end

function initCamShake()
	local function ShakeCamera(shakeCf)
		camera.CFrame = camera.CFrame * shakeCf
	end

	local renderPriority = Enum.RenderPriority.Camera.Value + 1
	local camShakeInstance = CameraShaker.new(renderPriority, ShakeCamera)

	return camShakeInstance
end

local camShake = initCamShake()

attackEvent.OnClientEvent:Connect(function(effectType)
	if effectType == "attackHit" then
		-- camShake:Start()
		-- camShake:Shake(CameraShaker.Presets.Hit)

		-- Cancel any active FOV tween
		if fovTween then
			fovTween:Cancel()
		end

		-- Quick FOV zoom in
		local recoilFOV = originalFOV - 2
		local recoilDuration = 0.15

		fovTween = TweenService:Create(
			camera,
			TweenInfo.new(recoilDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ FieldOfView = recoilFOV }
		)
		fovTween:Play()

		-- Tween back to normal
		task.delay(recoilDuration, function()
			fovTween = TweenService:Create(
				camera,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ FieldOfView = originalFOV }
			)
			fovTween:Play()
		end)
	end
end)

-- sprintEvent.OnClientEvent:Connect(function(sprintState)
-- 	if sprintState == "start" then
-- 		fovTween = TweenService:Create(
-- 			camera,
-- 			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
-- 			{ FieldOfView = originalFOV + fovChange }
-- 		)
-- 		fovTween:Play()

-- 		-- camShake:Start()
-- 		-- camShake:ShakeSustain(CameraShaker.Presets.Impact)
-- 	elseif sprintState == "stop" then
-- 		resetFOV()
-- 		camShake:StopSustained(0.1)
-- 	end
-- end)
