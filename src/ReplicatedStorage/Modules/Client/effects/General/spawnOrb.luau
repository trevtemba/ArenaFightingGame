local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local RunService = Services.RunService

local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local tweenHelper = require(Services.ClientEffectsUtils.tweenHelper)
local orbsFolder = Services.Workspace:WaitForChild("Assets"):WaitForChild("orbs")

local function GetOrb(orbId)
	local orb = nil

	for _, part in orbsFolder:GetChildren() do
		if part:GetAttribute("orbId") == orbId then
			orb = part
			break
		end
	end

	if orb then
		return orb
	else
		warn("Orb not found on client for ID:", orbId)
		return nil
	end
end

local function startFloatTween(orb)
	-- Store the base position
	local basePosition = orb.Position

	-- Tween info for floating
	local floatTweenData = {
		time = 1.5,
		easingStyle = Enum.EasingStyle.Sine,
		easingDirection = Enum.EasingDirection.InOut,
		repeatCount = -1, -- loop forever
		reverses = true,
	}

	-- Float goal (go 2 studs up from base)
	local floatGoal = {
		Position = basePosition + Vector3.new(0, 1, 0),
	}

	tweenHelper:Tween(orb, floatTweenData, floatGoal)
end

local function waitForLanding(part, threshold)
	threshold = threshold or 0.1
	return task.spawn(function()
		while part and part:IsDescendantOf(workspace) do
			if part.AssemblyLinearVelocity.Magnitude < threshold then
				break
			end
			RunService.Heartbeat:Wait()
		end

		part.Anchored = true
		startFloatTween(part)
	end)
end

return function(argumentData)
	local tier: string = argumentData.tier
	local id: string = argumentData.orbId

	local orbPart = GetOrb(id)
	if orbPart and tier and id then
		particleHelper.EnablePart(orbPart)

		-- Unanchor and prepare for motion
		orbPart.Anchored = false

		-- BodyVelocity for launch arc
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = Vector3.new(math.random(-5, 5), math.random(15, 25), math.random(-5, 5))
		bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bodyVelocity.P = 1250
		bodyVelocity.Parent = orbPart

		task.delay(1, function()
			if bodyVelocity then
				bodyVelocity:Destroy()
				waitForLanding(orbPart)
			end
		end)
	end
end
