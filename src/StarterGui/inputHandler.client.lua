local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ClientEvents = RemoteEvents:WaitForChild("Client")
local ServerEvents = RemoteEvents:WaitForChild("Server")

-- Input Contexts
local CombatContext = PlayerGui:WaitForChild("Combat")

local switchContext = ClientEvents:WaitForChild("switchContext")

local debounces = {
	attack = false,
	heavyAttack = false,
	dodge = false,
}

CombatContext:WaitForChild("Attack").Pressed:Connect(function()
	if debounces["attack"] then
		return
	end

	debounces["attack"] = true

	local remote = ServerEvents:FindFirstChild("OnAttack")
	if remote then
		remote:FireServer()
	end

	task.delay(0.3, function()
		debounces["attack"] = false
	end)
end)

CombatContext:WaitForChild("Block").Pressed:Connect(function()
	print("f clicked while in combat")
	local remote = ServerEvents:FindFirstChild("OnBlock")
	if remote then
		remote:FireServer()
		print("Block event fired")
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
