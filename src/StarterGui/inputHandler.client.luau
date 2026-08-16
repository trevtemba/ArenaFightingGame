local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local RaycastHelper = require(Services.SharedUtils.RaycastHelper)
local TableAttributes = require(Services.SharedUtils.TableAttributes)
local Players = Services.Players
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local hotbar = require(Services.ClientEffectsUI.hotbar)
local InputStateHandler = require(Services.Client.inputStateHandler)
local camModule = require(Services.Client:WaitForChild("cameraModule"))
local animationModule = require(Services.Client:WaitForChild("animationModule"))
local physicsModule = require(Services.Client:WaitForChild("physicsModule"))
local ShiftlockModule = require(Services.Client.smoothShiftlock.SmoothShiftLock)
local STATE = require(Services.Enums.State)
local TableToString = require(Services.SharedUtils.TableToString)

local ClientEvents = Services.ClientEvents
local ServerEvents = Services.ServerEvents

-- Input Handler
local inputStateHandler = nil
-- Input Contexts
local CombatContext = PlayerGui:WaitForChild("Combat")
local CoreContext = PlayerGui:WaitForChild("Core")
local ShiftlockedContext = PlayerGui:WaitForChild("Shiftlocked")
local FreecamContext = PlayerGui:WaitForChild("Freecammed")

local switchContext = ClientEvents:WaitForChild("switchContext")
local attackDone = ClientEvents:WaitForChild("attackDone")
local attackHeavyDone = ClientEvents:WaitForChild("attackHeavyDone")
local castDone = ClientEvents:WaitForChild("castDone")
local soulCastDone = ClientEvents:WaitForChild("soulCastDone")
local inAir = ClientEvents:WaitForChild("inAir")

local camera = Services.Workspace.CurrentCamera
local mouse = player:GetMouse()
local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)

local DASH_COOLDOWN = 1
local DEFAULT_JUMP_POWER = 80

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

	inputStateHandler:SetFor(state, cooldown)

	return
end

--[[
	Dash direction comes from the humanoid's actual movement input rather than
	the heldInputs table.

	heldInputs only ever learns about left/right/back from the Shiftlocked
	context's handlers; the Freecammed ones never call HeldOn(direction). Since
	SmoothShiftLock owns the Alt keybind through ContextActionService and sinks
	it, the camera can be shiftlocked while the enabled InputContext is still
	Freecammed -- and then nothing records a direction and this fell through to
	"forward" no matter what was held. That was the whole "shiftlock only ever
	dashes forward" bug.

	MoveDirection is set by the default control scripts and is correct in both
	camera modes, so this needs no knowledge of which context is live. Dotting it
	against the root part's axes yields a character-relative direction, which is
	the frame physicsModule.Dash resolves against.

	Freecam behaviour is unchanged by construction: AutoRotate keeps the
	character facing MoveDirection there, so LookVector and MoveDirection agree
	and this still answers "forward".
]]
local function getDashDirection()
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return "forward"
	end

	local move = humanoid.MoveDirection
	-- Standing still: dash the way the character faces.
	if move.Magnitude < 0.1 then
		return "forward"
	end

	local forwardDot = hrp.CFrame.LookVector:Dot(move)
	local rightDot = hrp.CFrame.RightVector:Dot(move)

	-- Ties go to the strafe, matching the old ordering where left/right were
	-- tested before back: a diagonal like W+A side-dashes.
	if math.abs(forwardDot) > math.abs(rightDot) then
		return forwardDot >= 0 and "forward" or "back"
	end
	return rightDot >= 0 and "right" or "left"
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
			-- local walkRemote = ServerEvents:FindFirstChild("OnWalk")
			-- if walkRemote then
			-- 	walkRemote:FireServer("forward")
			-- end
		end
	end
end

CoreContext:WaitForChild("Jump").Pressed:Connect(function()
	inputStateHandler:HeldOn("space")
	if processDebounce("dash", 0.2) or not inputStateHandler:CanDo(STATE.Jumping) then
		return
	end
	inputStateHandler:SetState(STATE.Jumping)
	--setCanJump(false)
end)

CoreContext:WaitForChild("Jump").Released:Connect(function()
	inputStateHandler:HeldOff("space")
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
	if processDebounce("attack", 0.05) or not inputStateHandler:CanDo(STATE.Attacking) then
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

CombatContext:WaitForChild("AttackHeavy").Pressed:Connect(function()
	if processDebounce("attackHeavy", 0.2) or not inputStateHandler:CanDo(STATE.AttackingHeavy) then
		return
	end
	inputStateHandler:SetState(STATE.AttackingHeavy)
	updateSprinting()
	setCanJump(false)

	if inputStateHandler:GetState(STATE.Jumping) and inputStateHandler:GetState(STATE.Dashing) then
		physicsModule.StopDash()
	end
	local remote = ServerEvents:WaitForChild("OnAttackHeavy")
	if remote then
		remote:FireServer(inputStateHandler:GetState(STATE.Jumping))
	end
end)

local function tryBlock()
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		print("pressing block")
		remote:FireServer(true)
	end
end
CombatContext.Block.Pressed:Connect(function()
	print("pressed f")
	inputStateHandler:HeldOn("f")
	if processDebounce("block", 0.2) or not inputStateHandler:CanDo(STATE.Blocking) then
		print("canDoBlock: ", inputStateHandler:CanDo(STATE.Blocking))
		return
	end
	inputStateHandler:SetState(STATE.Blocking)
	tryBlock()
end)

CombatContext:WaitForChild("Block").Released:Connect(function()
	inputStateHandler:RemoveState(STATE.Blocking)
	inputStateHandler:HeldOff("f")
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer(false)
	end
end)

CombatContext:WaitForChild("Ability1").Pressed:Connect(function()
	local slot = 1 -- placeholder for when i add all hotbar actions
	local abilityInfo = TableAttributes.Get(player.Character, string.format("ability%dInfo", slot))
	if processDebounce("cast1", 0.1) or not inputStateHandler:CanDo(STATE.Casting) then
		return
	end
	local targetType = abilityInfo.targetType
	if targetType == "lockOn" then
		local character, hit = RaycastHelper:GetMouseTarget(500) -- max distance (gonna sanity check on server)
		if character then
			local remote = ServerEvents:FindFirstChild("OnCast")
			if remote then
				print("casting 1", character.Name)
				remote:FireServer({
					target = character,
					hitPosition = hit.Position,
				})
			end
		end
	else
		inputStateHandler:SetState(STATE.Casting)
		hotbar.Cast({ abilitySlot = 1 })
		hotbar.Cooldown({ cooldown = abilityInfo.cooldown, abilitySlot = 1 })
		local remote = ServerEvents:FindFirstChild("OnCast")
		if remote then
			print("casting 1")
			remote:FireServer(1)
		end
	end
end)

CombatContext:WaitForChild("SoulAbility").Pressed:Connect(function()
	local soulAbilityInfo = TableAttributes.Get(player.Character, "soulAbilityInfo")
	if processDebounce("soulAbility", 0.1) or not inputStateHandler:CanDo(STATE.SoulCasting) then
		return
	end
	local targetType = soulAbilityInfo.targetType
	if targetType == "lockOn" then
		local character, hit = RaycastHelper:GetMouseTarget(500) -- max distance (gonna sanity check on server)
		if character then
			inputStateHandler:SetState(STATE.SoulCasting)
			hotbar.SoulCast()
			hotbar.SoulCooldown({ cooldown = soulAbilityInfo.cooldown })
			local remote = ServerEvents:FindFirstChild("OnSoulCast")
			if remote then
				print("casting soul on", character.Name)
				remote:FireServer({
					target = character,
					hitPosition = hit.Position,
				})
			end
		end
	else
		inputStateHandler:SetState(STATE.SoulCasting)
		hotbar.SoulCast()
		hotbar.SoulCooldown({ cooldown = soulAbilityInfo.cooldown })
		local remote = ServerEvents:FindFirstChild("OnSoulCast")
		if remote then
			print("casting soul")
			remote:FireServer({ origin = unitRay.Origin, direction = unitRay.Direction.Unit })
		end
	end
end)

CoreContext:WaitForChild("ShowSoul").Pressed:Connect(function()
	if processDebounce("showSoul", 1) then
		return
	end

	inputStateHandler.soulVisible = not inputStateHandler.soulVisible
	local visible = inputStateHandler.soulVisible

	local remote = ServerEvents:FindFirstChild("OnSoulVisibleToggle")
	if remote then
		remote:FireServer(visible)
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
	print("CLIENT STATES: " .. TableToString(inputStateHandler:GetAllStates()))
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

--[[
	Which movement context is live is derived from the shift lock state, never
	toggled independently.

	The two used to be separate state machines that both keyed off Alt:
	SmoothShiftLock binds Alt through ContextActionService and sinks it, while
	this script blind-toggled the two contexts with `not` and never established a
	baseline for Shiftlocked at startup. Nothing tied them together, so the camera
	could be locked while the Freecammed context was still the live one. That is
	why shift lock only ever dashed forward and why the left/right/back walk
	animations never played -- the Freecammed handlers deliberately play
	walkForward for every direction, which is right for that mode because
	AutoRotate turns the character to face movement.

	Setting both from one boolean makes the states unrepresentable rather than
	merely unlikely.
]]
local movementContextShiftlocked = nil

local function applyMovementContext(shiftlocked)
	if movementContextShiftlocked == shiftlocked then
		return
	end
	movementContextShiftlocked = shiftlocked

	ShiftlockedContext.Enabled = shiftlocked
	FreecamContext.Enabled = not shiftlocked

	-- Anything still held belongs to the context being disabled, so its Released
	-- handler will never fire. Drop those holds and the animations they started,
	-- or a direction stays stuck on forever.
	if inputStateHandler then
		inputStateHandler:ToggleHeldForFreecam() -- only forward/shift remain held
	end
	for _, data in pairs(directions) do
		animationModule.Stop(data.anim)
	end

	-- Only the Freecammed handlers keep this counter, so a key held across the
	-- switch is counted once and never decremented -- which strands it above zero
	-- and permanently defeats the `activeKeyCount == 0` guards that stop the walk
	-- animation. Nothing from the incoming context is counted yet, so zero is the
	-- honest value; the next press/release cycle re-syncs it.
	activeKeyCount = 0
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

			if not inputStateHandler:HasState(STATE.Walking) then
				inputStateHandler:SetState(STATE.Walking)
			end

			inputStateHandler:HeldOn("forward")
			updateSprinting()

			if not inputStateHandler:HasState(STATE.Sprinting) then
				inputStateHandler.walking = "forward"
				animationModule.Play(data.anim, 0.1, true, "Movement")

				-- local remote = ServerEvents:FindFirstChild("OnWalk")
				-- if remote then
				-- 	remote:FireServer("forward")
				-- end
			end
		end)

		inputAction.Released:Connect(function()
			inputStateHandler:HeldOff("forward")
			sprintingFromDoubleTap = false
			updateSprinting()

			if inputStateHandler.walking == "forward" then
				inputStateHandler.walking = nil
				inputStateHandler:RemoveState(STATE.Walking)
			end

			animationModule.Stop(data.anim)
			animationModule.Stop(data.sprintAnim)
		end)
	else
		inputAction.Pressed:Connect(function()
			if processDebounce("walk", 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			if not inputStateHandler:HasState(STATE.Walking) then
				inputStateHandler:SetState(STATE.Walking)
			end

			inputStateHandler:HeldOn(direction)
			inputStateHandler.walking = direction
			animationModule.Play(data.anim, 0.1, true, "Movement")

			-- local remote = ServerEvents:FindFirstChild("OnWalk")
			-- if remote then
			-- 	remote:FireServer(direction)
			-- end
		end)

		inputAction.Released:Connect(function()
			if inputStateHandler.walking == direction then
				inputStateHandler:RemoveState(STATE.Walking)
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
				if not inputStateHandler:HasState(STATE.Walking) then
					inputStateHandler:SetState(STATE.Walking)
					animationModule.Play(data.anim, 0.1, true, "Movement")
				end

				-- local remote = ServerEvents:FindFirstChild("OnWalk")
				-- if remote then
				-- 	remote:FireServer("forward")
				-- end
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
				inputStateHandler:RemoveState(STATE.Walking)
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

			if not inputStateHandler:HasState(STATE.Walking) then
				inputStateHandler:SetState(STATE.Walking)
				animationModule.Play("walkForward", 0.1, true, "Movement")
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
				inputStateHandler:RemoveState(STATE.Walking)
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

--[[
	The context follows the camera, and nothing here toggles either one.

	SmoothShiftLock's own ContextActionService binding is what actually toggles
	shift lock today -- LockCam never did, it only flipped the contexts, which is
	precisely how the two drifted apart. Having LockCam call ToggleShiftLock
	instead would be a coin flip: it sinks Alt at Medium priority, so if LockCam
	also carries Alt both would fire and the camera would toggle twice per press.

	So the camera keeps its existing owner and the contexts subscribe to it.

	Unsubscribed on destroy: this script lives in a ResetOnSpawn ScreenGui, so it
	re-runs on every respawn. The listener list is module state and outlives the
	script, so without this each spawn would stack another subscription whose
	closure still points at the previous run's contexts and inputStateHandler.
]]
local unsubscribeShiftlock = ShiftlockModule.OnStateChanged(applyMovementContext)
script.Destroying:Connect(unsubscribeShiftlock)

switchContext.OnClientEvent:Connect(function(contextName)
	switchToContext(contextName)
	print("Binds are now in " .. contextName .. " context!")
end)

attackDone.OnClientEvent:Connect(function()
	inputStateHandler:RemoveState(STATE.Attacking)
	if inputStateHandler:IsHeld("f") then
		tryBlock()
	end
	setCanJump(true)
	print("client can do movement")
end)

attackHeavyDone.OnClientEvent:Connect(function()
	inputStateHandler:RemoveState(STATE.AttackingHeavy)
	if inputStateHandler:IsHeld("f") then
		tryBlock()
	end
	setCanJump(true)
	print("client can do movement")
end)

castDone.OnClientEvent:Connect(function()
	inputStateHandler:RemoveState(STATE.Casting)
	if inputStateHandler:IsHeld("f") then
		tryBlock()
	end
	setCanJump(true)
end)

soulCastDone.OnClientEvent:Connect(function()
	inputStateHandler:RemoveState(STATE.SoulCasting)
	setCanJump(true)
	print("done soulcasting")
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

--[[
	characterInitializer only flips CharacterReady after it has preloaded
	animations, which happens after a yield. This script therefore always
	observed `false` on its single isCharLoaded:Invoke() poll, and the old else
	branch merely logged "waiting for signal" without waiting for anything --
	so inputStateHandler stayed nil and every binding above was dead on arrival.

	Wait on the attribute instead. Checking before arming the signal is safe:
	nothing yields between the two, so the value cannot change in between.
]]
local function waitForCharacterReady()
	while player:GetAttribute("CharacterReady") ~= true do
		player:GetAttributeChangedSignal("CharacterReady"):Wait()
	end
end

waitForCharacterReady()

do
	print("CHARACTER IS READY")
	local char = player.Character
	local humanoid = char:WaitForChild("Humanoid")

	inputStateHandler = InputStateHandler.new(humanoid)
	PlayerGui:FindFirstChild("Core").Enabled = true

	--[[
		Establish a known baseline for both contexts, rather than only enabling
		Freecammed and leaving Shiftlocked on whatever it was saved as in Studio.

		SmoothShiftLock always constructs with Enabled = false, and characterInitializer
		builds it just after flipping CharacterReady, so "not shiftlocked" is the
		correct starting state whether or not the instance exists yet. Any later
		toggle arrives through OnStateChanged.
	]]
	local shiftlock = ShiftlockModule.Active
	applyMovementContext(shiftlock ~= nil and shiftlock:IsEnabled() or false)
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
			if inputStateHandler:IsHeld("f") then
				tryBlock()
			end
			setCanJump(true)
		end
	end)
end
