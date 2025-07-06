-- RagdollModule.lua
local RagdollModule = {}

-- Internal helper to convert Motor6D to BallSocket
local function convertToBallSocket(motor)
	local part0, part1 = motor.Part0, motor.Part1
	if not part0 or not part1 then return end

	local attachment0 = Instance.new("Attachment")
	attachment0.CFrame = motor.C0
	attachment0.Name = "RagdollAttachment0"
	attachment0.Parent = part0

	local attachment1 = Instance.new("Attachment")
	attachment1.CFrame = motor.C1
	attachment1.Name = "RagdollAttachment1"
	attachment1.Parent = part1

	local socket = Instance.new("BallSocketConstraint")
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1
	socket.Name = "RagdollSocket"
	socket.Parent = part0

	motor:Destroy()
end

-- Ragdoll the given rig
function RagdollModule:Ragdoll(rig)
	for _, desc in ipairs(rig:GetDescendants()) do
		if desc:IsA("Motor6D") then
			convertToBallSocket(desc)
		end
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
end

-- Restore a ragdolled rig
function RagdollModule:Unragdoll(rig)
	for _, part in ipairs(rig:GetDescendants()) do
		if part:IsA("BallSocketConstraint") and part.Name == "RagdollSocket" then
			part:Destroy()
		elseif part:IsA("Attachment") and (part.Name == "RagdollAttachment0" or part.Name == "RagdollAttachment1") then
			part:Destroy()
		end
	end

	-- Optional: Reset Humanoid state
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

return RagdollModule
