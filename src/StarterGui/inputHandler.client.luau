local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TouchInputService = game:GetService("TouchInputService")

local EnemyData = require(ReplicatedStorage.Modules.data.EnemyData)
local camModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("cameraModule"))
local animationModule =
	require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("animationModule"))
local physicsModule =
	require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("physicsModule"))

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BindableFunctions = ReplicatedStorage:WaitForChild("BindableFunctions")
local ClientEvents = RemoteEvents:WaitForChild("Client")
local ServerEvents = RemoteEvents:WaitForChild("Server")

-- Input Contexts
local CombatContext = PlayerGui:WaitForChild("Combat")
local CoreContext = PlayerGui:WaitForChild("Core")
local ShiftlockedContext = PlayerGui:WaitForChild("Shiftlocked")
local FreecamContext = PlayerGui:WaitForChild("Freecammed")

local switchContext = ClientEvents:WaitForChild("switchContext")
local isCharLoaded = BindableFunctions:WaitForChild("charLoaded")

local DASH_COOLDOWN = 1

local debounces = {
	attack = false,
	heavyAttack = false,
	block = false,
	dash = false,
	sprint = false,
	walk = false,
	shift = false,
}

local canDo = {
	dash = true,
}

local walking = nil
local sprinting = nil
local dashing = false

local activeKeyCount = 0
local sprintingFromDoubleTap = false
local doubleTapThreshold = 0.35
local lastForwardTapTime = 0

local directions = {
	left = { key = "WalkLeft", anim = "walkLeft" },
	right = { key = "WalkRight", anim = "walkRight" },
	back = { key = "WalkBack", anim = "walkBack" },
	forward = { key = "WalkForward", anim = "walkForward", sprintAnim = "sprint" },
}

-- Track current input holds
local heldInputs = {
	forward = false,
	left = false,
	right = false,
	back = false,
	shift = false,
}

local function processDebounce(name, duration)
	if debounces[name] == true then
		return true
	end

	debounces[name] = true

	task.delay(duration, function()
		debounces[name] = false
	end)

	return
end

local function processCooldown(name, cooldown)
	if canDo[name] == false then
		return true
	end

	canDo[name] = false

	task.delay(cooldown, function()
		canDo[name] = true
	end)

	return
end

-- Update this function
local function updateSprinting()
	local shouldSprint = heldInputs.forward and (heldInputs.shift or sprintingFromDoubleTap)

	if shouldSprint and not sprinting then
		sprinting = true
		animationModule.Stop(directions.forward.anim)
		animationModule.Play(directions.forward.sprintAnim, 0.1, true, "Action")
		camModule.EnableSprintPOV()

		local remote = ServerEvents:FindFirstChild("OnSprint")
		if remote then
			remote:FireServer("start")
		end
	elseif not shouldSprint and sprinting then
		sprinting = false
		animationModule.Stop(directions.forward.sprintAnim)
		camModule.DisableSprintPOV()

		local sprintRemote = ServerEvents:FindFirstChild("OnSprint")
		if sprintRemote then
			sprintRemote:FireServer("stop")
		end
		if heldInputs.forward then
			animationModule.Play(directions.forward.anim, 0.1, true, "Movement")
			local walkRemote = ServerEvents:FindFirstChild("OnWalk")
			if walkRemote then
				walkRemote:FireServer("forward")
			end
		end
	end
end

CoreContext:WaitForChild("Dash").Pressed:Connect(function()
	if processDebounce("dash", 0.2) then
		return
	end
	if processCooldown("dash", DASH_COOLDOWN) then
		return
	end
	if dashing == true then
		return
	end

	local walkingDir = walking or "forward"
	local animName
	dashing = true

	if walkingDir == "forward" then
		animName = "dashForward"
	elseif walkingDir == "left" then
		animName = "dashLeft"
	elseif walkingDir == "right" then
		animName = "dashRight"
	elseif walkingDir == "back" then
		animName = "dashBack"
	end

	local remote = ServerEvents:FindFirstChild("OnDash")
	if remote then
		remote:FireServer(walkingDir)
	end

	animationModule.Play(animName, 0.1, false, "Action2")
	animationModule.ConnectEvent(animName, "fire", function()
		physicsModule.Dash(walkingDir, 12)
		heldInputs.forward = false
		sprintingFromDoubleTap = false
		updateSprinting()
	end)
	task.delay(0.75, function()
		dashing = false
	end)
end)

CombatContext:WaitForChild("Attack").Pressed:Connect(function()
	if processDebounce("attack", 0.2) then
		return
	end

	local remote = ServerEvents:WaitForChild("OnAttack")
	if remote then
		remote:FireServer()
	end
end)

CombatContext:WaitForChild("Block").Pressed:Connect(function()
	if processDebounce("block", 0.2) then
		return
	end

	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer()
	end
end)

CombatContext:WaitForChild("Block").Released:Connect(function()
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer()
	end
end)

CoreContext:WaitForChild("Shift").Pressed:Connect(function()
	if processDebounce("shift", 0.1) then
		return
	end
	heldInputs.shift = true
	updateSprinting()
	if sprinting then
		activeKeyCount += 1
	end
end)

CoreContext:WaitForChild("Shift").Released:Connect(function()
	heldInputs.shift = false
	updateSprinting()
	if activeKeyCount > 0 then
		activeKeyCount -= 1
	end
end)

local function switchToContext(contextName)
	local allContexts = {
		"Combat",
	}

	for _, name in ipairs(allContexts) do
		local context = PlayerGui:FindFirstChild(name)
		if context then
			context.Enabled = (name == contextName)
		end
	end
end

local function toggledShiftlockContext()
	ShiftlockedContext.Enabled = not ShiftlockedContext.Enabled
	FreecamContext.Enabled = not FreecamContext.Enabled
	if FreecamContext.Enabled == true then
		for _, v in pairs(heldInputs) do
			if v ~= "forward" then
				heldInputs[v] = false
			end
		end
	end
end

-- Directional Movement
local function setupMovementActionShiftLocked(direction, data)
	local inputAction = ShiftlockedContext:WaitForChild(data.key)

	if direction == "forward" then
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) then
				return
			end

			local currentTime = tick()
			if currentTime - lastForwardTapTime <= doubleTapThreshold then
				sprintingFromDoubleTap = true
			end
			lastForwardTapTime = currentTime

			heldInputs.forward = true
			updateSprinting()

			if not sprinting then
				walking = "forward"
				animationModule.Play(data.anim, 0.1, true, "Movement")

				local remote = ServerEvents:FindFirstChild("OnWalk")
				if remote then
					remote:FireServer("forward")
				end
			end
		end)

		inputAction.Released:Connect(function()
			heldInputs.forward = false
			sprintingFromDoubleTap = false
			updateSprinting()

			if walking == "forward" then
				walking = nil
			end

			animationModule.Stop(data.anim)
			animationModule.Stop(data.sprintAnim)
		end)
	else
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) then
				return
			end

			heldInputs[direction] = true
			walking = direction
			animationModule.Play(data.anim, 0.1, true, "Movement")

			local remote = ServerEvents:FindFirstChild("OnWalk")
			if remote then
				remote:FireServer(direction)
			end
		end)

		inputAction.Released:Connect(function()
			if walking == direction then
				walking = nil
			end

			heldInputs[direction] = false
			animationModule.Stop(data.anim)
		end)
	end
end

-- Freecam movement
local function setupMovementActionFreecammed(direction, data)
	local inputAction = FreecamContext:WaitForChild(data.key)

	if direction == "forward" then
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) then
				return
			end

			local currentTime = tick()
			if currentTime - lastForwardTapTime <= doubleTapThreshold then
				sprintingFromDoubleTap = true
			end
			lastForwardTapTime = currentTime

			heldInputs.forward = true
			updateSprinting()

			activeKeyCount += 1

			if not sprinting then
				walking = "forward"
				animationModule.Play(data.anim, 0.1, true, "Movement")

				local remote = ServerEvents:FindFirstChild("OnWalk")
				if remote then
					remote:FireServer("forward")
				end
			end
			--print(activeKeyCount)
		end)

		inputAction.Released:Connect(function()
			heldInputs.forward = false
			if activeKeyCount > 0 then
				activeKeyCount -= 1
			end

			if walking == "forward" then
				walking = nil
			end

			if activeKeyCount == 0 then
				updateSprinting()
				animationModule.Stop(data.anim)
			end
			sprintingFromDoubleTap = false

			--print(activeKeyCount)
		end)
	else
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) then
				return
			end

			activeKeyCount += 1

			--print(activeKeyCount)
		end)

		inputAction.Released:Connect(function()
			if activeKeyCount > 0 then
				activeKeyCount -= 1
			end

			if activeKeyCount == 0 then
				updateSprinting()
				animationModule.Stop("walkForward")
			end
			--print(activeKeyCount)
		end)
	end
end

-- Register all movement actions
for dir, info in pairs(directions) do
	setupMovementActionShiftLocked(dir, info)
end

-- Register all movement actions
for dir, info in pairs(directions) do
	setupMovementActionFreecammed(dir, info)
end

CoreContext:WaitForChild("LockCam").Pressed:Connect(function()
	toggledShiftlockContext()
end)

switchContext.OnClientEvent:Connect(function(contextName)
	switchToContext(contextName)
	print("Binds are now in " .. contextName .. " context!")
end)

if isCharLoaded:Invoke() then
	print("CHARACTER IS READY")
	PlayerGui:FindFirstChild("Core").Enabled = true
	PlayerGui:FindFirstChild("Freecammed").Enabled = true
else
	print("CHARACTER IS NOT READY YET — waiting for signal")
end
