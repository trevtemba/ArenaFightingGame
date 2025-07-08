local module = {}

local debrisService = game:GetService("Debris")
local RagdollHandler = require(
	game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("core"):WaitForChild("RagdollHandler")
)

local tweenService = game:GetService("TweenService")
local tweenInfoMoveChar = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)

-- function module.movePlayerForward(distance)
-- 	local tween = tweenService:Create(
-- 		HumanoidRootPart,
-- 		tweenInfoMoveChar,
-- 		{ CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, -distance) }
-- 	)
-- 	tween:Play()
-- end

-- function module.movePlayerBackward(distance)
-- 	local tween = tweenService:Create(
-- 		HumanoidRootPart,
-- 		tweenInfoMoveChar,
-- 		{ CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, distance) }
-- 	)
-- 	tween:Play()
-- end

-- function module.knockbackPlayer(enemyChar)
-- 	local att = Instance.new("Attachment", HumanoidRootPart)
-- 	local lv = Instance.new("LinearVelocity", att)

-- 	lv.MaxForce = 9999999
-- 	lv.VectorVelocity = (HumanoidRootPart.Position - enemyChar:FindFirstChild("HumanoidRootPart").Position).Unit
-- 			* Vector3.new(60, 0, 60)
-- 		+ Vector3.new(0, 40)
-- 	lv.Attachment0 = att

-- 	RagdollHandler.Start()
-- 	game.Debris:AddItem(att, 0.1)

-- 	task.delay(1, function()
-- 		RagdollHandler.Stop()
-- 	end)
-- end

function module.changeWalkspeed(humanoid, newSpeed)
	humanoid.WalkSpeed = newSpeed
end

return module
