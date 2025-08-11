--Fetch tween service
local tweenServ = game:GetService("TweenService")
--set tween info
local tweenInfoBtns1 = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vpFrame = script.Parent
	:WaitForChild("Dante")
	:WaitForChild("bruteFrame")
	:WaitForChild("topFrame")
	:WaitForChild("parFrame")
	:WaitForChild("ViewportFrame")
local vpRig = vpFrame:WaitForChild("WorldModel"):WaitForChild("viewportRig")
local vpRigHum = vpRig:WaitForChild("Humanoid")
local animator = vpRigHum:FindFirstChildOfClass("Animator")

local uiModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("client"):WaitForChild("guiModule"))

for i, v in pairs(animator:GetPlayingAnimationTracks()) do
	print("releasing anims")
	v:Stop()
end

local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://13578279914"
local idle = vpRigHum:LoadAnimation(anim)

--Fetch all children in classSelectionFrame
for i, v in pairs(script.Parent:GetChildren()) do
	--If a frame
	if v:IsA("Frame") then
		--When mouse enters the frame, enlarge and darken it
		v.MouseEnter:Connect(function()
			uiModule.hoverSound()
			tweenServ:Create(v, tweenInfoBtns1, { BackgroundTransparency = 0.7 }):Play()
			tweenServ:Create(v, tweenInfoBtns1, { Position = UDim2.new(0.5, 0, 0.49, 0) }):Play()
			idle:Play(0.15)
		end)
		--when mouse leaves, revert changes
		v.MouseLeave:Connect(function()
			tweenServ:Create(v, tweenInfoBtns1, { BackgroundTransparency = 1 }):Play()
			tweenServ:Create(v, tweenInfoBtns1, { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
			idle:Stop(0.15)
		end)
	end
end
