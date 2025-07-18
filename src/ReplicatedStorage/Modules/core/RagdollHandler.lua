-- RagdollModule.lua
local RagdollModule = {}

local rigMotorCache = {}

local function convertToBallSocket(motor)
	local part0, part1 = motor.Part0, motor.Part1
	if not part0 or not part1 then
		return
	end

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

function RagdollModule:Ragdoll(rig, duration)
	if not rig or not rig:IsA("Model") then
		return
	end

	rigMotorCache[rig] = {}

	for _, desc in ipairs(rig:GetDescendants()) do
		if desc:IsA("Motor6D") then
			-- Store properties to restore later
			table.insert(rigMotorCache[rig], {
				Name = desc.Name,
				Part0 = desc.Part0,
				Part1 = desc.Part1,
				C0 = desc.C0,
				C1 = desc.C1,
			})

			convertToBallSocket(desc)
		end
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	if duration then
		task.delay(duration, function()
			self:Unragdoll(rig)
		end)
	end
end

function RagdollModule:Unragdoll(rig)
	if not rig or not rig:IsA("Model") then
		return
	end

	-- Destroy ragdoll constraints
	for _, part in ipairs(rig:GetDescendants()) do
		if part:IsA("BallSocketConstraint") and part.Name == "RagdollSocket" then
			part:Destroy()
		elseif part:IsA("Attachment") and (part.Name == "RagdollAttachment0" or part.Name == "RagdollAttachment1") then
			part:Destroy()
			print("")
		end
	end

	-- Restore Motor6Ds
	local cached = rigMotorCache[rig]
	if cached then
		for _, data in ipairs(cached) do
			local motor = Instance.new("Motor6D")
			motor.Name = data.Name
			motor.Part0 = data.Part0
			motor.Part1 = data.Part1
			motor.C0 = data.C0
			motor.C1 = data.C1
			motor.Parent = data.Part0
		end
	end

	-- Reset Humanoid state
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	-- Cleanup cache
	rigMotorCache[rig] = nil
end

return RagdollModule
