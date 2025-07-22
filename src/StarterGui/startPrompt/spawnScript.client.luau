--Grabs variables
local plr = game:GetService("Players").LocalPlayer
local character = plr.Character or plr.CharacterAdded:wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local blur = game.Lighting:WaitForChild("Blur")

local camModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("cameraModule"))

--add blur
blur.Enabled = true
--enables menu camera
camModule.menuCam()
