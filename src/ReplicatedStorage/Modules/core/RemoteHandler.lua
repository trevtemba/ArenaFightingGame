local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerHandler = require(ReplicatedStorage.Modules.core.PlayerHandler)

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")

remotes.Attack.OnServerEvent:Connect(PlayerHandler.OnAttack)
remotes.Cast.OnServerEvent:Connect(PlayerHandler.OnCast)
remotes.Dash.OnServerEvent:Connect(PlayerHandler.OnDash)
remotes.Pickup.OnServerEvent:Connect(PlayerHandler.OnPickup)

