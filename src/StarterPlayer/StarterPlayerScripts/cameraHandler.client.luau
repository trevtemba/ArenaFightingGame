local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraShaker = require(ReplicatedStorage.Modules.client.cameraShaker.CameraShaker)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ClientEvents = RemoteEvents:WaitForChild("Client")

local attackEvent = ClientEvents:WaitForChild("attack")
local flinchEvent = ClientEvents:WaitForChild("flinch")
local sprintEvent = ClientEvents:WaitForChild("sprint")

local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera

local player = game:GetService("Players").LocalPlayer

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
		camShake:Start()
		camShake:Shake(CameraShaker.Presets.Hit)

		-- Cancel any active FOV tween
		if fovTween then
			fovTween:Cancel()
		end

		-- Quick FOV zoom in
		local recoilFOV = originalFOV - 4
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

flinchEvent.OnClientEvent:Connect(function(effectType)
	if effectType == "impact" then
		camShake:Start()
		camShake:Shake(CameraShaker.Presets.Impact)
	end
end)

sprintEvent.OnClientEvent:Connect(function(sprintState)
	if sprintState == "start" then
		fovTween = TweenService:Create(
			camera,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FieldOfView = originalFOV + fovChange }
		)
		fovTween:Play()

		-- camShake:Start()
		-- camShake:ShakeSustain(CameraShaker.Presets.Impact)
	elseif sprintState == "stop" then
		resetFOV()
		camShake:StopSustained(0.1)
	end
end)
