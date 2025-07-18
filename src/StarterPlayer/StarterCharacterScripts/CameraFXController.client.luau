local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ClientEvents = RemoteEvents:WaitForChild("Client")

local CameraEffectEvent = ClientEvents:WaitForChild("attack")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera

local fovTweenOut, fovTweenIn
local fovResetting = false
local originalFOV = 70

CameraEffectEvent.OnClientEvent:Connect(function(effectType, windupDuration, followDuration, fovChange)
	if effectType == "FOVZoom" then
		if fovTweenOut then
			fovTweenOut:Cancel()
		end
		if fovTweenIn then
			fovTweenIn:Cancel()
		end

		-- Set original FOV only once if not currently tweening back
		if not fovResetting then
			originalFOV = 70
		end

		local targetFOV = originalFOV + fovChange

		fovTweenOut = TweenService:Create(
			camera,
			TweenInfo.new(windupDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				FieldOfView = targetFOV,
			}
		)

		fovTweenIn =
			TweenService:Create(camera, TweenInfo.new(followDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				FieldOfView = originalFOV,
			})

		fovResetting = true

		fovTweenOut:Play()
		fovTweenOut.Completed:Wait()
		fovTweenIn:Play()
		fovTweenIn.Completed:Wait()

		fovResetting = false
	end
end)
