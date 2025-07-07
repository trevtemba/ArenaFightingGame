local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerHandler = require(ReplicatedStorage.Modules.core.PlayerHandler)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ServerEvents = RemoteEvents:WaitForChild("Server")

ServerEvents.Attack.OnServerEvent:Connect(PlayerHandler.OnAttack)
ServerEvents.Cast.OnServerEvent:Connect(PlayerHandler.OnCast)
ServerEvents.Dash.OnServerEvent:Connect(PlayerHandler.OnDash)
ServerEvents.Pickup.OnServerEvent:Connect(PlayerHandler.OnPickup)
