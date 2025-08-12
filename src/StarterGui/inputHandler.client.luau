local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local hotbar = require(ReplicatedStorage.Modules.client.effects.UI.hotbar)
local InputStateHandler = require(ReplicatedStorage.Modules.client.inputStateHandler)
local camModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("cameraModule"))
local animationModule =
	require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("animationModule"))
local physicsModule =
	require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("physicsModule"))
local STATE = require(ReplicatedStorage.Modules.core.State)
local tableToString = require(ReplicatedStorage.Modules.tableToString)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BindableFunctions = ReplicatedStorage:WaitForChild("BindableFunctions")
local ClientEvents = RemoteEvents:WaitForChild("Client")
local ServerEvents = RemoteEvents:WaitForChild("Server")

-- Input Handler
local inputStateHandler = nil
-- Input Contexts
local CombatContext = PlayerGui:WaitForChild("Combat")
local CoreContext = PlayerGui:WaitForChild("Core")
local ShiftlockedContext = PlayerGui:WaitForChild("Shiftlocked")
local FreecamContext = PlayerGui:WaitForChild("Freecammed")

local switchContext = ClientEvents:WaitForChild("switchContext")
local attackDone = ClientEvents:WaitForChild("attackDone")
local castDone = ClientEvents:WaitForChild("castDone")
local soulCastDone = ClientEvents:WaitForChild("soulCastDone")
local inAir = ClientEvents:WaitForChild("inAir")
local isCharLoaded = BindableFunctions:WaitForChild("charLoaded")

local DASH_COOLDOWN = 1
local JUMP_COOLDOWN = 1
local DEFAULT_JUMP_POWER = 60

local debounces = {
	attack = false,
	heavyAttack = false,
	block = false,
	dash = false,
	sprint = false,
	walk = false,
	shift = false,
}

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

local function setCanJump(bool)
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if bool then
		humanoid.JumpPower = DEFAULT_JUMP_POWER
	else
		humanoid.JumpPower = 0
	end
end
local function processDebounce(name, duration)
	if debounces[name] == true then
		return true
	end

	debounces[name] = true

	task.delay(duration, function()
		debounces[name] = false
	end)

	return false
end

local function processCooldown(state, cooldown)
	if not inputStateHandler:CanDo(state) then
		return true
	end

	inputStateHandler:SetState(state)

	task.delay(cooldown, function()
		inputStateHandler:RemoveState(state)
	end)

	return
end

local function getDashDirection()
	local activeKeys = inputStateHandler:GetAllHeldInputs()
	local direction = "forward"

	if activeKeys["left"] and not activeKeys["right"] then
		direction = "left"
	elseif activeKeys["right"] and not activeKeys["left"] then
		direction = "right"
	elseif activeKeys["back"] and not activeKeys["left"] and not activeKeys["right"] then
		direction = "back"
	elseif activeKeys["back"] and activeKeys["left"] and activeKeys["right"] then
		print()
		direction = "back"
	end
	return direction
end

-- Update this function
local function updateSprinting()
	local shouldSprint = inputStateHandler:IsHeld("forward")
		and inputStateHandler:CanDo(STATE.Sprinting)
		and (inputStateHandler:IsHeld("shift") or sprintingFromDoubleTap)

	if shouldSprint then
		inputStateHandler:SetState(STATE.Sprinting)
		inputStateHandler.walking = "forward"
		animationModule.Stop(directions.forward.anim)
		animationModule.Play(directions.forward.sprintAnim, 0.1, true, "Action")
		camModule.EnableSprintPOV()

		local remote = ServerEvents:FindFirstChild("OnSprint")
		if remote then
			remote:FireServer("start")
		end
	elseif not shouldSprint then
		inputStateHandler:RemoveState(STATE.Sprinting)
		animationModule.Stop(directions.forward.sprintAnim)
		camModule.DisableSprintPOV()

		local sprintRemote = ServerEvents:FindFirstChild("OnSprint")
		if sprintRemote then
			sprintRemote:FireServer("stop")
		end
		if inputStateHandler:IsHeld("forward") then
			animationModule.Play(directions.forward.anim, 0.1, true, "Movement")
			local walkRemote = ServerEvents:FindFirstChild("OnWalk")
			if walkRemote then
				walkRemote:FireServer("forward")
			end
		end
	end
end

CoreContext:WaitForChild("Jump").Pressed:Connect(function()
	if processDebounce("dash", 0.2) or not inputStateHandler:CanDo(STATE.Jumping) then
		return
	end

	--setCanJump(false)
	inputStateHandler:HeldOn("space")
	print("holding space")
end)

CoreContext:WaitForChild("Jump").Released:Connect(function()
	inputStateHandler:HeldOff("space")
	print("letting go of space")
end)

CoreContext:WaitForChild("Dash").Pressed:Connect(function()
	if processDebounce("dash", 0.2) then
		return
	end
	if processCooldown(STATE.Dashing, DASH_COOLDOWN) then
		return
	end

	local walkingDir = getDashDirection()
	local animName
	inputStateHandler:RemoveState(STATE.Sprinting)

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
	physicsModule.Dash(walkingDir, 12)
	inputStateHandler:HeldOff("forward")
	sprintingFromDoubleTap = false
	updateSprinting()
end)

CombatContext:WaitForChild("Attack").Pressed:Connect(function()
	if processDebounce("attack", 0.2) or not inputStateHandler:CanDo(STATE.Attacking) then
		return
	end
	inputStateHandler:SetState(STATE.Attacking)
	updateSprinting()

	setCanJump(false)

	local remote = ServerEvents:WaitForChild("OnAttack")
	if remote then
		remote:FireServer(inputStateHandler:IsHeld("space"))
	end
end)

CombatContext:WaitForChild("Block").Pressed:Connect(function()
	print("pressed f")
	if processDebounce("block", 0.2) or not inputStateHandler:CanDo(STATE.Blocking) then
		print("canDoBlock: ", inputStateHandler:CanDo(STATE.Blocking))
		return
	end
	inputStateHandler:SetState(STATE.Blocking)

	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		print("pressing block")
		remote:FireServer(true)
	end
end)

CombatContext:WaitForChild("Block").Released:Connect(function()
	inputStateHandler:RemoveState(STATE.Blocking)
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer(false)
	end
end)

CombatContext:WaitForChild("Ability1").Pressed:Connect(function()
	if
		processDebounce("cast1", player.Character:GetAttribute("abilityCd1"))
		or not inputStateHandler:CanDo(STATE.Casting)
	then
		return
	end
	inputStateHandler:SetState(STATE.Casting)
	hotbar.Cast({ abilitySlot = 1 })
	hotbar.Cooldown({ cooldown = player.Character:GetAttribute("abilityCd1"), abilitySlot = 1 })
	local remote = ServerEvents:FindFirstChild("OnCast")
	if remote then
		print("casting 1")
		remote:FireServer(1)
	end
end)

CombatContext:WaitForChild("SoulAbility").Pressed:Connect(function()
	if
		processDebounce("soulAbility", player.Character:GetAttribute("soulAbilityCd"))
		or not inputStateHandler:CanDo(STATE.SoulCasting)
	then
		return
	end
	inputStateHandler:SetState(STATE.SoulCasting)
	hotbar.SoulCast()
	hotbar.SoulCooldown({ cooldown = player.Character:GetAttribute("soulAbilityCd") })
	local remote = ServerEvents:FindFirstChild("OnSoulCast")
	if remote then
		print("casting soul")
		remote:FireServer()
	end
end)

CoreContext:WaitForChild("ShowSoul").Pressed:Connect(function()
	if processDebounce("showSoul", 1) then
		return
	end

	local remote = ServerEvents:FindFirstChild("OnSoulShow")
	if remote then
		remote:FireServer()
	end
end)

CoreContext:WaitForChild("Shift").Pressed:Connect(function()
	if processDebounce("shift", 0.1) then
		return
	end
	inputStateHandler:HeldOn("shift")
	updateSprinting()
	if inputStateHandler:HasState(STATE.Sprinting) then
		activeKeyCount += 1
	end
end)

CoreContext:WaitForChild("Shift").Released:Connect(function()
	inputStateHandler:HeldOff("shift")
	updateSprinting()
	if activeKeyCount > 0 then
		activeKeyCount -= 1
	end
end)

CoreContext:WaitForChild("stateShow").Pressed:Connect(function()
	print("CLIENT STATES: " .. tableToString(inputStateHandler:GetAllStates()))
	local remote = ServerEvents:FindFirstChild("OnDev")
	if remote then
		remote:FireServer("state")
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
		inputStateHandler:ToggleHeldForFreecam() -- only forward/shift remain held
	end
end

-- Directional Movement
local function setupMovementActionShiftLocked(direction, data)
	local inputAction = ShiftlockedContext:WaitForChild(data.key)

	if direction == "forward" then
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			local currentTime = tick()
			if currentTime - lastForwardTapTime <= doubleTapThreshold then
				sprintingFromDoubleTap = true
			end
			lastForwardTapTime = currentTime

			inputStateHandler:HeldOn("forward")
			updateSprinting()

			if not inputStateHandler:HasState(STATE.Sprinting) then
				inputStateHandler.walking = "forward"
				animationModule.Play(data.anim, 0.1, true, "Movement")

				local remote = ServerEvents:FindFirstChild("OnWalk")
				if remote then
					remote:FireServer("forward")
				end
			end
		end)

		inputAction.Released:Connect(function()
			inputStateHandler:HeldOff("forward")
			sprintingFromDoubleTap = false
			updateSprinting()

			if inputStateHandler.walking == "forward" then
				inputStateHandler.walking = nil
			end

			animationModule.Stop(data.anim)
			animationModule.Stop(data.sprintAnim)
		end)
	else
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			inputStateHandler:HeldOn(direction)
			inputStateHandler.walking = direction
			animationModule.Play(data.anim, 0.1, true, "Movement")

			local remote = ServerEvents:FindFirstChild("OnWalk")
			if remote then
				remote:FireServer(direction)
			end
		end)

		inputAction.Released:Connect(function()
			if inputStateHandler.walking == direction then
				inputStateHandler.walking = nil
			end

			inputStateHandler:HeldOff(direction)
			animationModule.Stop(data.anim)
		end)
	end
end

-- Freecam movement
local function setupMovementActionFreecammed(direction, data)
	local inputAction = FreecamContext:WaitForChild(data.key)

	if direction == "forward" then
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			local currentTime = tick()
			if currentTime - lastForwardTapTime <= doubleTapThreshold then
				sprintingFromDoubleTap = true
			end
			lastForwardTapTime = currentTime

			inputStateHandler:HeldOn("forward")
			updateSprinting()

			activeKeyCount += 1

			if not inputStateHandler:HasState(STATE.Sprinting) then
				inputStateHandler.walking = "forward"
				animationModule.Play(data.anim, 0.1, true, "Movement")

				local remote = ServerEvents:FindFirstChild("OnWalk")
				if remote then
					remote:FireServer("forward")
				end
			end
			--print(activeKeyCount)
		end)

		inputAction.Released:Connect(function()
			if activeKeyCount > 0 then
				activeKeyCount -= 1
			end
			inputStateHandler:HeldOff("forward")

			if inputStateHandler.walking == "forward" then
				inputStateHandler.walking = nil
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
			if processDebounce("walk", 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
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

attackDone.OnClientEvent:Connect(function()
	inputStateHandler:RemoveState(STATE.Attacking)
	setCanJump(true)
	print("client can do movement")
end)

castDone.OnClientEvent:Connect(function()
	inputStateHandler:RemoveState(STATE.Casting)
	setCanJump(true)
end)

soulCastDone.OnClientEvent:Connect(function()
	inputStateHandler:RemoveState(STATE.SoulCasting)
	setCanJump(true)
end)

inAir.OnClientEvent:Connect(function(isActive)
	if isActive then
		inputStateHandler:SetState(STATE.InAirCombo)
		setCanJump(false)
	else
		inputStateHandler:RemoveState(STATE.InAirCombo)
		setCanJump(true)
	end
	print(inputStateHandler:HasState(STATE.InAirCombo))
end)

if isCharLoaded:Invoke() then
	print("CHARACTER IS READY")
	local humanoid = player.Character.Humanoid
	local char = player.Character

	inputStateHandler = InputStateHandler.new(humanoid)
	PlayerGui:FindFirstChild("Core").Enabled = true
	PlayerGui:FindFirstChild("Freecammed").Enabled = true
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			inputStateHandler:RemoveState(STATE.Jumping)
			inputStateHandler:RemoveState(STATE.InAirCombo)
			animationModule.Play("landing", 0.1, false, "Action")
			-- Trigger landing animation or reset jump state
		end
	end)
	char:GetAttributeChangedSignal("Stunned"):Connect(function()
		local stunned = char:GetAttribute("Stunned")
		if stunned then
			-- animationModule.StopAllExcept({ impactleft = true, impactright = true, blockBreak = true })
			inputStateHandler:ClearStates()
			inputStateHandler:SetState(STATE.Stunned)
			setCanJump(false)
		else
			inputStateHandler:RemoveState(STATE.Stunned)
			setCanJump(true)
		end
	end)
else
	print("CHARACTER IS NOT READY YET — waiting for signal")
end
