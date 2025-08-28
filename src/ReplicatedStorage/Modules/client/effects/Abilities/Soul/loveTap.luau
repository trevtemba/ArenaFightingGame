local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = require(ReplicatedStorage.Modules.Shared.Services)
local animHelper = require(Services.ClientEffectsUtils.animHelper)
local Debris = Services.DebrisService
local ChatService = Services.ChatService
local particleHelper = require(Services.ClientEffectsUtils.particleHelper)
local toggleSoulVisibility = require(Services.ClientEffects.General.toggleSoulVisibility)
local ChatBubbleHelper = require(Services.ClientEffectsUtils.ChatBubbleHelper)
local soundHelper = require(Services.ClientEffectsUtils.soundHelper)

local ClientAssets = Services.ClientAssets

return function(argumentData)
	local target: Model = argumentData.target
	local soulType: string = argumentData.soulType
	if target then
		local rootPart = target:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local mockSoul = ClientAssets:FindFirstChild(soulType):Clone()
			local mockSoulHRP = mockSoul:FindFirstChild("HumanoidRootPart")
			if mockSoulHRP then
				mockSoul.Name = ""
				mockSoulHRP.Anchored = true
				mockSoul.Parent = Services.Workspace
				local offset = rootPart.CFrame.RightVector * 3
				local position = rootPart.Position + offset
				mockSoulHRP.CFrame = CFrame.new(position, rootPart.Position)

				toggleSoulVisibility({ target = mockSoul, visible = true, particleSkin = "default" })
				animHelper:PlayAnimation(mockSoul, "loveTap", 0.1, nil, nil, false, "Action4")
				ChatService:Chat(mockSoul:FindFirstChild("Head"), "Love Tap!", Enum.ChatColor.White)
				-- ChatBubbleHelper:ShowBubble(mockSoul:FindFirstChild("Head"), "Love tap!", 0.4, 0.1)
				task.delay(0.5, function()
					toggleSoulVisibility({ target = mockSoul, visible = false, particleSkin = "default" })
				end)
			end
			Debris:AddItem(mockSoul, 1)
		end
	end
end
