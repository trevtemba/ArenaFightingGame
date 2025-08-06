local Player = game:GetService("Players").LocalPlayer
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local castSprite = ReplicatedStorage:WaitForChild("UI"):WaitForChild("castSprite")

local hotbar = {}

local function getUI(abilitySlot)
	local gui = Player:WaitForChild("PlayerGui")
	local hudGui = gui:WaitForChild("HUD")
	local abilityFrame = hudGui
		:WaitForChild("super")
		:WaitForChild("hotbar")
		:WaitForChild("abilityList")
		:WaitForChild("ability" .. tostring(abilitySlot))
	return abilityFrame
end

function hotbar.Cast(argumentData)
	local abilitySlot: number = argumentData.abilitySlot

	if abilitySlot then
		local abilityFrame = getUI(abilitySlot)
		local sprite = castSprite:Clone()
		sprite.Parent = abilityFrame
		sprite.Visible = true

		local CELL_SIZE = 256
		local COLUMNS = 4
		local TOTAL_FRAMES = 16
		local FRAME_DURATION = 1 / 15 -- 15 FPS (adjust as needed)

		task.spawn(function()
			for i = 0, TOTAL_FRAMES - 1 do
				local col = i % COLUMNS
				local row = math.floor(i / COLUMNS)

				sprite.ImageRectOffset = Vector2.new(col * CELL_SIZE, row * CELL_SIZE)
				task.wait(FRAME_DURATION)
			end

			sprite:Destroy()
		end)
	end
end

return hotbar
