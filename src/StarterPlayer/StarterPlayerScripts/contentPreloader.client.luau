-- StarterPlayerScripts/PreloadAssets.lua

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Example: preload loot orb variants
local Assets = ReplicatedStorage:WaitForChild("Assets")
local UI = ReplicatedStorage:WaitForChild("UI")

local assetsToPreload = {}

-- Optional: show loading UI here
for _, item in pairs(UI:WaitForChild("items"):GetDescendants()) do
	if item:IsA("ImageLabel") or item:IsA("ImageButton") then
		table.insert(assetsToPreload, item)
	end
end
-- Preload assets (this blocks only this script)
ContentProvider:PreloadAsync(assetsToPreload)

-- Optional: hide loading UI here
print("Assets preloaded.")
