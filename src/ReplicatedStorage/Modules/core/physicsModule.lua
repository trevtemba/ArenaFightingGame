local module = {}

local debrisService = game:GetService("Debris")
local tweenService = game:GetService('TweenService')
local tweenInfoMoveChar = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

function module.movePlayerForward(distance)

	local tween = tweenService:Create(HumanoidRootPart, tweenInfoMoveChar, { CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -distance) })
	tween:Play()

end

function module.movePlayerBackward(distance)
	
	local tween = tweenService:Create(HumanoidRootPart, tweenInfoMoveChar, { CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, distance) })
	tween:Play()
	
end

function module.knockbackPlayer(enemyChar)
	
	local att = Instance.new("Attachment", HumanoidRootPart)
	local lv = Instance.new("LinearVelocity", att)
	
	lv.MaxForce = 9999999
	lv.VectorVelocity = (HumanoidRootPart.Position - enemyChar:FindFirstChild("HumanoidRootPart").Position).Unit * Vector3.new(60, 0, 60) + Vector3.new(0, 40)
	lv.Attachment0 = att
	
	ragdollModule.Start()
	game.Debris:AddItem(att, 0.1)
	
	task.delay(1, function()
		ragdollModule.Stop()
	end)
	
end

return module
