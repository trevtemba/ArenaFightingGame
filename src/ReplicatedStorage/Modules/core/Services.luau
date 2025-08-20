local Services = {}

-- Core Roblox services
Services.ServerScriptService = game:GetService("ServerScriptService")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.ServerStorage = game:GetService("ServerStorage")
Services.Players = game:GetService("Players")
Services.RunService = game:GetService("RunService")
Services.TweenService = game:GetService("TweenService")
Services.DebrisService = game:GetService("Debris")
Services.CollectionService = game:GetService("CollectionService")
Services.ServerStorage = game:GetService("ServerStorage")
Services.Workspace = game:GetService("Workspace")

-- Server
Services.Entities = Services.ServerScriptService:WaitForChild("Entities")
Services.EntityHandlers = Services.Entities.Handlers
Services.EntityUtils = Services.Entities.Utils

Services.Server = Services.ServerScriptService:WaitForChild("Server")
Services.Data = Services.ServerScriptService:WaitForChild("Data")

-- Shared
Services.Modules = Services.ReplicatedStorage:WaitForChild("Modules")
Services.Core = Services.Modules:WaitForChild("core")
Services.ClientEvents = Services.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client")
Services.ServerEvents = Services.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Server")

return Services
