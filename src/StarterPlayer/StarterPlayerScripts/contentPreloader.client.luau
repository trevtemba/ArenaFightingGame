local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.core.Services)

local Assets = Services.Assets
local UI = Services.UI
local Effects = Services.Effects
local Animations = Services.Animations

local assetsToPreload = {}

for _, item in pairs(UI:GetDescendants()) do
	if item:IsA("ImageLabel") or item:IsA("ImageButton") then
		table.insert(assetsToPreload, item)
	end
end

for _, item in pairs(Effects:GetDescendants()) do
	if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
		table.insert(assetsToPreload, item)
	end
end

for _, item in pairs(Animations:GetDescendants()) do
	if item:IsA("Animation") then
		table.insert(assetsToPreload, item)
	end
end

table.insert(assetsToPreload, Assets:WaitForChild("flameThrower"))
-- Preload assets (this blocks only this script)
ContentProvider:PreloadAsync(assetsToPreload)

-- Optional: hide loading UI here
print("Assets preloaded.")
