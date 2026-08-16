local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local RaycastHelper = require(Services.SharedUtils.RaycastHelper)
local TableAttributes = require(Services.SharedUtils.TableAttributes)
local Players = Services.Players
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local hotbar = require(Services.ClientEffectsUI.hotbar)
local InputStateHandler = require(Services.Client.inputStateHandler)
-- cameraModule is no longer required here: the sprint POV is a consequence of
-- STATE.Sprinting and now lives in movementAnimator with the other consequences.
local animationModule = require(Services.Client:WaitForChild("animationModule"))
local physicsModule = require(Services.Client:WaitForChild("physicsModule"))
local ShiftlockModule = require(Services.Client.smoothShiftlock.SmoothShiftLock)
local movementAnimator = require(Services.Client:WaitForChild("movementAnimator"))
local moveDirection = require(Services.Client:WaitForChild("moveDirection"))
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
local JUMP_COOLDOWN = 1
-- Backstop for a jump lock whose releasing remote never arrives. Long enough to
-- never fire during a normal attack.
local JUMP_LOCK_TIMEOUT = 5

-- Keys must match the strings passed to processDebounce. `heavyAttack` and
-- `sprint` were declared but never used, while attackHeavy/cast1/showSoul/
-- soulAbility were created on first call -- so this table read as authoritative
-- while not actually being the list. Movement debounces are per-direction
-- ("walk_forward" and friends) so one direction cannot swallow another.
local debounces = {
	attack = false,
	attackHeavy = false,
	block = false,
	cast1 = false,
	dash = false,
	jump = false,
	shift = false,
	showSoul = false,
	soulAbility = false,
	walk_forward = false,
	walk_back = false,
	walk_left = false,
	walk_right = false,
}

--[[
	Whether the player is currently asking to sprint.

	Edge-triggered, not a reading of whether Shift is down. Holding Shift is not
	a standing request: landing revokes the request outright, and the sprint must
	be asked for again even though the key never came up. That is what makes a
	jump cost you the sprint rather than pause it -- momentum carries through the
	air, and touching down ends it.

	Set by:     a fresh Shift press, or a double-tap of forward.
	Cleared by: landing, dashing, releasing Shift, or releasing all movement keys.
]]
local sprintRequested = false
-- Declared up here rather than beside applyMovementContext because
-- isMovingForSprint reads it, and that is defined earlier in the file.
-- nil until the first applyMovementContext call establishes the baseline.
local movementContextShiftlocked = nil
local sprintHeartbeat = nil
-- Forward momentum needed to sustain a shift lock sprint. A diagonal gives ~0.7,
-- a pure strafe ~0, so anything between comfortably separates them.
local SPRINT_FORWARD_THRESHOLD = 0.3
local doubleTapThreshold = 0.35
local lastForwardTapTime = 0

local directions = {
	left = { key = "WalkLeft", anim = "walkLeft" },
	right = { key = "WalkRight", anim = "walkRight" },
	back = { key = "WalkBack", anim = "walkBack" },
	forward = { key = "WalkForward", anim = "walkForward", sprintAnim = "sprint" },
}

--[[
	Every binding in this file is connected at file scope, but inputStateHandler
	is only built once the character is ready, far below. An input arriving in
	that window would index nil, so each handler drops it.

	The contexts are supposed to be disabled until then, but their saved Enabled
	state in Studio is not something this script controls, and Combat is switched
	on by a server remote that can land at any time.
]]
local function notReady()
	return inputStateHandler == nil
end

--[[
	Jump is disabled during attacks and re-enabled by the matching *Done remote.
	That made the remote a single point of failure: one dropped attackDone and
	JumpPower stays 0 for the rest of the life, with nothing to notice.

	The generation counter is the same trick StateHandler:SetFor uses -- the
	safety restore only fires if nothing has touched the lock since, so a normal
	remote-driven restore cancels it rather than racing it.
]]
local jumpLockGeneration = 0

local function setCanJump(bool)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	jumpLockGeneration += 1

	if bool then
		humanoid.JumpPower = DEFAULT_JUMP_POWER
		return
	end

	humanoid.JumpPower = 0

	local generation = jumpLockGeneration
	task.delay(JUMP_LOCK_TIMEOUT, function()
		if jumpLockGeneration ~= generation then
			return
		end
		warn("Jump stayed locked for", JUMP_LOCK_TIMEOUT, "s - a *Done remote never arrived; restoring")
		setCanJump(true)
	end)
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
	camera modes, so this needs no knowledge of which context is live. The math
	lives in moveDirection because movementAnimator resolves walk animations
	against exactly the same frame.

	Freecam behaviour is unchanged by construction: AutoRotate keeps the
	character facing MoveDirection there, so LookVector and MoveDirection agree
	and this still answers "forward".
]]
local function getDashDirection()
	-- Standing still: dash the way the character faces.
	return moveDirection.Relative(player.Character) or "forward"
end

local MOVEMENT_INPUTS = { "forward", "left", "right", "back" }

local function isAnyMovementHeld()
	for _, input in MOVEMENT_INPUTS do
		if inputStateHandler:IsHeld(input) then
			return true
		end
	end
	return false
end

--[[
	Whether the character is actually moving in a way that should sustain a sprint.

	Reads real movement rather than held keys, which is what makes opposing
	inputs behave: holding W and S leaves both keys down but cancels
	MoveDirection to zero, and sprinting on the spot is nonsense. Held-key
	bookkeeping cannot see that -- only the resulting motion can.

	Shift lock and freecam then disagree about what counts. Locked, the character
	strafes because it keeps facing the camera, so sprinting sideways or
	backwards is meaningless and sprint needs real forward momentum. In freecam
	AutoRotate turns the character to face whatever is held, so every direction
	is forward as far as the character is concerned.
]]
local function isMovingForSprint()
	local character = player.Character

	if not movementContextShiftlocked then
		return moveDirection.Relative(character) ~= nil
	end

	-- A component test, not the discrete direction: W+D resolves to "right"
	-- under Relative's tie-break, but ~0.7 of its momentum is still forward and
	-- a diagonal should absolutely keep sprinting. The threshold sits well below
	-- that 0.7 and well above the ~0 of a pure strafe or a W+S cancel.
	return moveDirection.ForwardAmount(character) > SPRINT_FORWARD_THRESHOLD
end

--[[
	Decides whether the sprint state should be on, and nothing else.

	The animation, the camera POV and the OnSprint remote used to be spelled out
	here too. They now hang off inputStateHandler.Changed in movementAnimator, so
	they follow the state wherever it is set from rather than only when this
	function happens to run. That also makes this safe to call redundantly: a
	repeat SetState is a no-op and fires no signal.
]]
local function updateSprinting()
	local shouldSprint = sprintRequested and isMovingForSprint() and inputStateHandler:CanDo(STATE.Sprinting)

	-- Letting go of every movement key ends the request. Not tied to the sprint
	-- state: that can lapse while the player is still plainly asking -- W+S
	-- cancelling out, or a shift lock strafe -- and should resume when it does.
	if not isAnyMovementHeld() then
		sprintRequested = false
	end

	-- Guarded because this now runs every frame: an unguarded RemoveState would
	-- bump the state's generation 60 times a second for no reason.
	if shouldSprint then
		if not inputStateHandler:HasState(STATE.Sprinting) then
			inputStateHandler:SetState(STATE.Sprinting)
		end
		inputStateHandler.walking = "forward"
	elseif inputStateHandler:HasState(STATE.Sprinting) then
		inputStateHandler:RemoveState(STATE.Sprinting)
	end
end

CoreContext:WaitForChild("Jump").Pressed:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:HeldOn("space")
	-- Its own debounce key. This used to reuse "dash", so a jump blocked a dash
	-- for 0.2s and vice versa -- two unrelated actions sharing one timer.
	if processDebounce("jump", JUMP_COOLDOWN) or not inputStateHandler:CanDo(STATE.Jumping) then
		return
	end

	--[[
		STATE.Jumping is only cleared by the Landed transition, so setting it
		when the character cannot leave the ground strands it -- and because
		Jumping blocks itself in ActionRules, that would end jumping for good.
		JumpPower is zeroed by setCanJump during attacks and air combos.
	]]
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.JumpPower <= 0 then
		return
	end

	inputStateHandler:SetState(STATE.Jumping)
	--setCanJump(false)
end)

CoreContext:WaitForChild("Jump").Released:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:HeldOff("space")
end)

CoreContext:WaitForChild("Dash").Pressed:Connect(function()
	if notReady() then
		return
	end
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
	-- No HeldOff("forward") here any more: it reported a key as up while it was
	-- physically down, and clearing sprintRequested already ends the sprint.
	sprintRequested = false
	updateSprinting()
end)

--[[
	Attacking, heavy attacking and casting all break a block on the server --
	CombatHandler:Attack, :AttackHeavy and :Cast each call DisableBlock.

	DisableBlock only broadcasts the VFX event; it never tells inputStateHandler.
	So the client has to drop its own Blocking state or the two disagree, and a
	stale client-side block would then make CanDo(Blocking) refuse the tryBlock
	that attackDone uses to resume it -- leaving the player unblocked with F
	still held.
]]
local function breakBlock()
	if inputStateHandler:HasState(STATE.Blocking) then
		inputStateHandler:RemoveState(STATE.Blocking)
	end
end

CombatContext:WaitForChild("Attack").Pressed:Connect(function()
	if notReady() then
		return
	end
	if processDebounce("attack", 0.05) or not inputStateHandler:CanDo(STATE.Attacking) then
		return
	end
	inputStateHandler:SetState(STATE.Attacking)
	breakBlock()
	updateSprinting()

	setCanJump(false)

	local remote = ServerEvents:WaitForChild("OnAttack")
	if remote then
		remote:FireServer(inputStateHandler:IsHeld("space"))
	end
end)

CombatContext:WaitForChild("AttackHeavy").Pressed:Connect(function()
	if notReady() then
		return
	end
	if processDebounce("attackHeavy", 0.2) or not inputStateHandler:CanDo(STATE.AttackingHeavy) then
		return
	end
	inputStateHandler:SetState(STATE.AttackingHeavy)
	breakBlock()
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

--[[
	The single way a block starts, whether from the keypress or from resuming one
	that was interrupted by an attack.

	It used to only fire the remote. The resume paths below call it whenever F is
	still down, so the server would start blocking while the client never set
	STATE.Blocking -- CanDo(Attacking) then failed to see the block, and the
	eventual Block.Released cleared a state that was never set. Setting the state
	here keeps the two ends agreeing however the block began.
]]
local function tryBlock()
	if not inputStateHandler:CanDo(STATE.Blocking) then
		return
	end

	inputStateHandler:SetState(STATE.Blocking)

	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer(true)
	end
end
CombatContext.Block.Pressed:Connect(function()
	if notReady() then
		return
	end
	-- Above the debounce on purpose: "f is down" is true whether or not the
	-- block itself is allowed, and the resume paths key off it.
	inputStateHandler:HeldOn("f")
	if processDebounce("block", 0.2) then
		return
	end
	tryBlock()
end)

CombatContext:WaitForChild("Block").Released:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:RemoveState(STATE.Blocking)
	inputStateHandler:HeldOff("f")
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer(false)
	end
end)

CombatContext:WaitForChild("Ability1").Pressed:Connect(function()
	if notReady() then
		return
	end
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
		breakBlock()
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
	if notReady() then
		return
	end
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
	if notReady() then
		return
	end
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
	if notReady() then
		return
	end
	if processDebounce("shift", 0.1) then
		return
	end
	inputStateHandler:HeldOn("shift")
	sprintRequested = true
	updateSprinting()
end)

CoreContext:WaitForChild("Shift").Released:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:HeldOff("shift")
	sprintRequested = false
	updateSprinting()
end)

CoreContext:WaitForChild("stateShow").Pressed:Connect(function()
	if notReady() then
		return
	end
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
	-- No animation sweep needed: movementAnimator re-resolves from the character's
	-- actual movement, so a direction cannot be left playing across the switch.
end

-- Directional Movement
local function setupMovementActionShiftLocked(direction, data)
	local inputAction = ShiftlockedContext:WaitForChild(data.key)

	if direction == "forward" then
		inputAction.Pressed:Connect(function()
			if notReady() then
				return
			end
			-- Recorded before the debounce. The key is physically down either
			-- way, and Released clears it unconditionally -- gating only the
			-- press meant a swallowed press left a hold that was never set but
			-- still got cleared.
			inputStateHandler:HeldOn("forward")

			if processDebounce("walk_" .. direction, 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			local currentTime = tick()
			if currentTime - lastForwardTapTime <= doubleTapThreshold then
				sprintRequested = true
			end
			lastForwardTapTime = currentTime

			if not inputStateHandler:HasState(STATE.Walking) then
				inputStateHandler:SetState(STATE.Walking)
			end

			updateSprinting()

			if not inputStateHandler:HasState(STATE.Sprinting) then
				inputStateHandler.walking = "forward"
			end
		end)

		inputAction.Released:Connect(function()
			if notReady() then
				return
			end
			inputStateHandler:HeldOff("forward")
			updateSprinting()

			if inputStateHandler.walking == "forward" then
				inputStateHandler.walking = nil
				inputStateHandler:RemoveState(STATE.Walking)
			end
		end)
	else
		inputAction.Pressed:Connect(function()
			if notReady() then
				return
			end
			inputStateHandler:HeldOn(direction)

			if processDebounce("walk_" .. direction, 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			if not inputStateHandler:HasState(STATE.Walking) then
				inputStateHandler:SetState(STATE.Walking)
			end

			inputStateHandler.walking = direction
			updateSprinting()
		end)

		inputAction.Released:Connect(function()
			if notReady() then
				return
			end
			if inputStateHandler.walking == direction then
				inputStateHandler:RemoveState(STATE.Walking)
				inputStateHandler.walking = nil
			end

			inputStateHandler:HeldOff(direction)
			updateSprinting()
		end)
	end
end

-- Freecam movement
local function setupMovementActionFreecammed(direction, data)
	local inputAction = FreecamContext:WaitForChild(data.key)

	if direction == "forward" then
		inputAction.Pressed:Connect(function()
			if notReady() then
				return
			end
			inputStateHandler:HeldOn("forward")

			if processDebounce("walk_" .. direction, 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			local currentTime = tick()
			if currentTime - lastForwardTapTime <= doubleTapThreshold then
				sprintRequested = true
			end
			lastForwardTapTime = currentTime

			updateSprinting()

			if not inputStateHandler:HasState(STATE.Sprinting) then
				inputStateHandler.walking = "forward"
				if not inputStateHandler:HasState(STATE.Walking) then
					inputStateHandler:SetState(STATE.Walking)
				end
			end
		end)

		inputAction.Released:Connect(function()
			if notReady() then
				return
			end
			inputStateHandler:HeldOff("forward")

			if inputStateHandler.walking == "forward" then
				inputStateHandler.walking = nil
			end

			updateSprinting()

			if not isAnyMovementHeld() then
				inputStateHandler:RemoveState(STATE.Walking)
			end
		end)
	else
		inputAction.Pressed:Connect(function()
			if notReady() then
				return
			end
			-- Freecam used to skip this, so heldInputs could not answer "is any
			-- movement key down" -- which is exactly what the sprint condition
			-- needs in this mode.
			inputStateHandler:HeldOn(direction)

			if processDebounce("walk_" .. direction, 0.05) or not inputStateHandler:CanDo(STATE.Walking) then
				return
			end

			if not inputStateHandler:HasState(STATE.Walking) then
				inputStateHandler:SetState(STATE.Walking)
			end

			updateSprinting()
		end)

		inputAction.Released:Connect(function()
			if notReady() then
				return
			end
			inputStateHandler:HeldOff(direction)
			updateSprinting()

			if not isAnyMovementHeld() then
				inputStateHandler:RemoveState(STATE.Walking)
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
script.Destroying:Connect(function()
	unsubscribeShiftlock()
	-- Same reasoning: the animator holds a Heartbeat connection and a Changed
	-- subscription on this run's handler, both of which outlive the script.
	movementAnimator.Stop()
	if sprintHeartbeat then
		sprintHeartbeat:Disconnect()
		sprintHeartbeat = nil
	end
	if inputStateHandler then
		inputStateHandler:Destroy()
	end
end)

switchContext.OnClientEvent:Connect(function(contextName)
	switchToContext(contextName)
	print("Binds are now in " .. contextName .. " context!")
end)

attackDone.OnClientEvent:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:RemoveState(STATE.Attacking)
	if inputStateHandler:IsHeld("f") then
		tryBlock()
	end
	setCanJump(true)
	print("client can do movement")
end)

attackHeavyDone.OnClientEvent:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:RemoveState(STATE.AttackingHeavy)
	if inputStateHandler:IsHeld("f") then
		tryBlock()
	end
	setCanJump(true)
	print("client can do movement")
end)

castDone.OnClientEvent:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:RemoveState(STATE.Casting)
	if inputStateHandler:IsHeld("f") then
		tryBlock()
	end
	setCanJump(true)
end)

soulCastDone.OnClientEvent:Connect(function()
	if notReady() then
		return
	end
	inputStateHandler:RemoveState(STATE.SoulCasting)
	setCanJump(true)
	print("done soulcasting")
end)

inAir.OnClientEvent:Connect(function(isActive)
	if notReady() then
		return
	end
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
	-- Subscribes to inputStateHandler.Changed, so it has to come after the handler
	-- exists and be torn down with it -- see the Destroying hook below.
	movementAnimator.Start(inputStateHandler, char)

	--[[
		Sprint is re-decided every frame, not only on key events.

		Movement is a continuous quantity: pressing S while W is held cancels
		MoveDirection to zero without any single event meaning "stopped", and at
		the instant a key event fires MoveDirection still holds the previous
		frame's value. Sampling on events alone would read stale input and miss
		the standing-still case entirely. updateSprinting is a no-op when nothing
		changed.
	]]
	sprintHeartbeat = Services.RunService.Heartbeat:Connect(updateSprinting)
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
			-- InAirCombo is not cleared here. CombatHandler owns it and ends it
			-- over the inAir remote; clearing it locally too gave one state two
			-- writers with nothing reconciling them.
			-- Touching down ends the sprint outright rather than suppressing it
			-- for a window: the request is revoked, so it stays off until the
			-- player asks again, even if Shift never came up.
			sprintRequested = false
			animationModule.Play("landing", 0.1, false, "Action")
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
