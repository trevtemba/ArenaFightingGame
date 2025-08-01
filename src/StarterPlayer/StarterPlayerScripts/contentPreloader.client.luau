-- StarterPlayerScripts/PreloadAssets.lua

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Example: preload loot orb variants
local Assets = ReplicatedStorage:WaitForChild("Assets")

local assetsToPreload = {}

-- Optional: show loading UI here

-- Preload assets (this blocks only this script)
ContentProvider:PreloadAsync(assetsToPreload)

-- Optional: hide loading UI here
print("Assets preloaded.")
