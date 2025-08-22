local TweenService = game:GetService("TweenService")

local TweenModule = {}

-- Create and play a tween
function TweenModule:Tween(instance, tweenInfoData, goalProps, onComplete)
	local info = TweenInfo.new(
		tweenInfoData.time or 0.5,
		tweenInfoData.easingStyle or Enum.EasingStyle.Quad,
		tweenInfoData.easingDirection or Enum.EasingDirection.Out,
		tweenInfoData.repeatCount or 0,
		tweenInfoData.reverses or false,
		tweenInfoData.delayTime or 0
	)

	local tween = TweenService:Create(instance, info, goalProps)
	tween:Play()

	if onComplete then
		tween.Completed:Once(onComplete)
	end

	return tween
end

return TweenModule
