-- StarterPlayerScripts/PreloadAssets.lua

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Example: preload loot orb variants
local Assets = ReplicatedStorage:WaitForChild("Assets")
local UI = ReplicatedStorage:WaitForChild("UI")
local Effects = ReplicatedStorage:WaitForChild("Effects")

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

table.insert(assetsToPreload, Assets:WaitForChild("flameThrower"))
-- Preload assets (this blocks only this script)
ContentProvider:PreloadAsync(assetsToPreload)

-- Optional: hide loading UI here
print("Assets preloaded.")
