local RunService = game:GetService("RunService")

local DASH_DURATION = 0.4
local DASH_SPEED = 80
local SLOWDOWN_DURATION = 0.3 -- how long they stay slowed after dashing

local player = game.Players.LocalPlayer

local isDashing = false

local physicModule = {}

function EaseOutCubic(t)
	return 1 - math.pow(1 - t, 3)
end

function physicModule.Dash(direction, defaultSpeed)
	if isDashing then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		return
	end

	isDashing = true
	humanoid.WalkSpeed = 0

	local startTime = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= DASH_DURATION then
			conn:Disconnect()

			-- Set walkspeed to half of default temporarily
			humanoid.WalkSpeed = defaultSpeed * 0.5

			-- Restore full speed after slowdown duration
			task.delay(SLOWDOWN_DURATION, function()
				humanoid.WalkSpeed = defaultSpeed
				isDashing = false
			end)

			return
		end

		local t = elapsed / DASH_DURATION
		local ease = 1 - (t * 0.6) -- linear decay from 1 to 0.4

		local cf = hrp.CFrame
		local vec
		if direction == "forward" then
			vec = cf.LookVector
		elseif direction == "back" then
			vec = -cf.LookVector
		elseif direction == "right" then
			vec = cf.RightVector
		elseif direction == "left" then
			vec = -cf.RightVector
		else
			vec = Vector3.zero
		end

		hrp.AssemblyLinearVelocity = vec.Unit * DASH_SPEED * ease
	end)
end

return physicModule
