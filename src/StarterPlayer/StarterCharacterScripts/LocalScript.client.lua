repeat
	task.wait()
until game:IsLoaded()

game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)