-- StunHandler.lua
local StunHandler = {}

local stunnedMap = {}

function StunHandler.Stun(humanoid: Humanoid, duration: number, walkSpeed: number?)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local char = humanoid.Parent
	if not char then
		return
	end

	-- Cancel previous task (if running)
	if stunnedMap[humanoid] then
		stunnedMap[humanoid].active = false -- signal the old coroutine to stop
		if stunnedMap[humanoid].conn then
			stunnedMap[humanoid].conn:Disconnect()
		end
	end

	-- Save original stats
	local originalSpeed = humanoid.WalkSpeed
	local originalJumpPower = humanoid.JumpPower
	local originalJumpHeight = humanoid.JumpHeight
	local newSpeed = walkSpeed or 0

	-- Apply stun immediately
	humanoid.WalkSpeed = newSpeed
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	char:SetAttribute("Stunned", true)

	local changedConn = humanoid.Changed:Connect(function()
		humanoid.WalkSpeed = newSpeed
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end)

	local stunInfo = {
		conn = changedConn,
		active = true,
	}

	stunnedMap[humanoid] = stunInfo

	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < duration do
			if not stunInfo.active then
				return
			end -- cancelled
			task.wait(0.1)
		end

		if stunInfo.active and humanoid:IsDescendantOf(game) then
			humanoid.WalkSpeed = originalSpeed
			humanoid.JumpPower = originalJumpPower
			humanoid.JumpHeight = originalJumpHeight
			char:SetAttribute("Stunned", false)
		end

		if stunInfo.conn then
			stunInfo.conn:Disconnect()
		end

		stunnedMap[humanoid] = nil
	end)
end

return StunHandler
