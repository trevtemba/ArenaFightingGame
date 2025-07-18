local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CamModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("cameraModule"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ClientEvents = RemoteEvents:WaitForChild("Client")
local ServerEvents = RemoteEvents:WaitForChild("Server")

-- Input Contexts
local CombatContext = PlayerGui:WaitForChild("Combat")

local switchContext = ClientEvents:WaitForChild("switchContext")
local flinchEvent = ClientEvents:WaitForChild("flinch")

local debounces = {
	attack = false,
	heavyAttack = false,
	block = false,
	dodge = false,
	sprint = false,
}

local runTick = 0
local sprinting = false
local doubleTapThreshold = 0.35

CombatContext:WaitForChild("Sprint").Pressed:Connect(function()
	local now = os.clock()

	if now - runTick <= doubleTapThreshold then
		if not debounces["sprint"] then
			debounces["sprint"] = true

			local remote = ServerEvents:WaitForChild("OnSprint")
			if remote then
				remote:FireServer("start")
				sprinting = true
			end

			task.delay(0.1, function()
				debounces["sprint"] = false
			end)
		end
	end

	runTick = now
end)

CombatContext:WaitForChild("Sprint").Released:Connect(function()
	if sprinting == false then
		return
	end

	local remote = ServerEvents:FindFirstChild("OnSprint")
	if remote then
		remote:FireServer("stop")
		sprinting = false
	end
end)

CombatContext:WaitForChild("Attack").Pressed:Connect(function()
	if debounces["attack"] == true then
		return
	end

	debounces["attack"] = true

	local remote = ServerEvents:WaitForChild("OnAttack")
	if remote then
		remote:FireServer()
		print("attack fired")
	end

	task.delay(0.2, function()
		debounces["attack"] = false
	end)
end)

CombatContext:WaitForChild("Block").Pressed:Connect(function()
	if debounces["block"] == true then
		return
	end

	debounces["block"] = true
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer()
	end

	task.delay(0.3, function()
		debounces["block"] = false
	end)
end)

CombatContext:WaitForChild("Block").Released:Connect(function()
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer()
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

switchContext.OnClientEvent:Connect(function(contextName)
	switchToContext(contextName)
	print("Binds are now in " .. contextName .. " context!")
end)
