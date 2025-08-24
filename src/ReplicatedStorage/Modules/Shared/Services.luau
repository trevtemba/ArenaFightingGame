local Services = {}

-- Core Roblox services
Services.ServerScriptService = game:GetService("ServerScriptService")
Services.ReplicatedStorage = game:GetService("ReplicatedStorage")
Services.ServerStorage = game:GetService("ServerStorage")
Services.Players = game:GetService("Players")
Services.RunService = game:GetService("RunService")
Services.TweenService = game:GetService("TweenService")
Services.UserInputService = game:GetService("UserInputService")
Services.DebrisService = game:GetService("Debris")
Services.CollectionService = game:GetService("CollectionService")
Services.ServerStorage = game:GetService("ServerStorage")
Services.Workspace = game:GetService("Workspace")
Services.Lighting = game:GetService("Lighting")
Services.ChatService = game:GetService("Chat")

Services.Modules = Services.ReplicatedStorage:WaitForChild("Modules")
Services.UI = Services.ReplicatedStorage:WaitForChild("UI")
Services.Effects = Services.ReplicatedStorage:WaitForChild("Effects")
Services.Animations = Services.ReplicatedStorage:WaitForChild("Animations")
Services.Sounds = Services.ReplicatedStorage:WaitForChild("Sounds")
Services.Assets = Services.ReplicatedStorage:WaitForChild("Assets")
Services.BindableFunctions = Services.ReplicatedStorage:WaitForChild("BindableFunctions")

-- Server
if Services.RunService:IsServer() then
	Services.Entities = Services.ServerScriptService:WaitForChild("Entities")
	Services.EntityHandlers = Services.Entities.Handlers
	Services.EntityUtils = Services.Entities.Utils

	Services.Server = Services.ServerScriptService:WaitForChild("Server")
	Services.Data = Services.ServerScriptService:WaitForChild("Data")
end

-- Shared
Services.Shared = Services.Modules:WaitForChild("Shared")
Services.SharedUtils = Services.Shared:WaitForChild("Utils")
Services.Enums = Services.Shared.Enums

Services.ClientEvents = Services.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Client")
Services.ServerEvents = Services.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Server")

-- Client
Services.Client = Services.Modules:WaitForChild("Client")
Services.ClientUtils = Services.Client:WaitForChild("Utils")
Services.ClientEffects = Services.Client:WaitForChild("effects")
Services.ClientAssets = Services.Client:WaitForChild("Assets")
Services.ClientEffectsUtils = Services.ClientEffects:WaitForChild("Utils")
Services.ClientEffectsUI = Services.ClientEffects:WaitForChild("UI")

return Services
