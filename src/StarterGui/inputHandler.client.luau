local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CamModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("cameraModule"))
local animationModule =
	require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("animationModule"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ClientEvents = RemoteEvents:WaitForChild("Client")
local ServerEvents = RemoteEvents:WaitForChild("Server")

-- Input Contexts
local CombatContext = PlayerGui:WaitForChild("Combat")
local CoreContext = PlayerGui:WaitForChild("Core")
local ShiftlockedContext = PlayerGui:WaitForChild("Shiftlocked")

local switchContext = ClientEvents:WaitForChild("switchContext")
local flinchEvent = ClientEvents:WaitForChild("flinch")
local charLoaded = ClientEvents:WaitForChild("charLoaded")

local debounces = {
	attack = false,
	heavyAttack = false,
	block = false,
	dodge = false,
	sprint = false,
	walk = false,
}

local walkTick = 0
local walking = nil
local sprinting = false
local doubleTapThreshold = 0.35

local function processDebounce(name, duration)
	debounces[name] = true

	task.delay(duration, function()
		debounces[name] = false
	end)
end

CoreContext:WaitForChild("WalkForward").Pressed:Connect(function()
	local now = os.clock()

	if now - walkTick <= doubleTapThreshold then
		if not debounces["sprint"] then
			processDebounce("sprint", 0.1)

			local remote = ServerEvents:WaitForChild("OnSprint")
			if remote then
				remote:FireServer("start")
				sprinting = true
			end
		end
	end

	walkTick = now
end)

CoreContext:WaitForChild("WalkForward").Released:Connect(function()
	if sprinting == false then
		return
	end

	local remote = ServerEvents:FindFirstChild("OnSprint")
	if remote then
		remote:FireServer("stop")
		sprinting = false
	end
end)

ShiftlockedContext:WaitForChild("WalkLeft").Pressed:Connect(function()
	if debounces["walk"] == true then
		return
	end

	processDebounce("walk", 0.05)
	walking = "left"
	animationModule.Play("walkLeft", 0.1, true)

	local remote = ServerEvents:FindFirstChild("OnWalk")
	if remote then
		remote:FireServer("left")
	end
end)
ShiftlockedContext:WaitForChild("WalkLeft").Released:Connect(function()
	if walking == "left" then
		walking = nil
	end

	animationModule.Stop("walkLeft")
end)

CombatContext:WaitForChild("Attack").Pressed:Connect(function()
	if debounces["attack"] == true then
		return
	end

	processDebounce("attack", 0.2)

	local remote = ServerEvents:WaitForChild("OnAttack")
	if remote then
		remote:FireServer()
		print("attack fired")
	end
end)

CombatContext:WaitForChild("Block").Pressed:Connect(function()
	if debounces["block"] == true then
		return
	end

	processDebounce("block", 0.2)

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

local function enableCore()
	CoreContext.Enabled = true
end
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
end

CoreContext:WaitForChild("LockCam").Pressed:Connect(function()
	toggledShiftlockContext()
end)

switchContext.OnClientEvent:Connect(function(contextName)
	switchToContext(contextName)
	print("Binds are now in " .. contextName .. " context!")
end)

charLoaded.OnClientEvent:Connect(function()
	print("hererrrr")
	animationModule.PreloadAll()
	enableCore()
end)
