local ChatBubbleHelper = {}

function ChatBubbleHelper:ShowBubble(part: BasePart, text: string, duration: number, fadeTime: number)
	duration = duration or 1.5
	fadeTime = fadeTime or 0.25

	-- create billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = part
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Text = text
	textLabel.Parent = billboard

	-- remove after duration with fade
	task.delay(duration, function()
		local steps = 10
		for i = 1, steps do
			textLabel.TextTransparency = i / steps
			textLabel.TextStrokeTransparency = 0.5 + (i / steps / 2)
			task.wait(fadeTime / steps)
		end
		billboard:Destroy()
	end)
end

return ChatBubbleHelper
