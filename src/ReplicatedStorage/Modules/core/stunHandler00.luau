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

	-- Cancel any previous stun
	if stunnedMap[humanoid] then
		task.cancel(stunnedMap[humanoid].task)
	end

	-- Save current values
	local originalSpeed = humanoid.WalkSpeed
	local originalJumpPower = humanoid.JumpPower
	local originalJumpHeight = humanoid.JumpHeight

	local newSpeed = walkSpeed or 0

	-- Apply stun immediately
	humanoid.WalkSpeed = newSpeed
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	char:SetAttribute("Stunned", true)

	-- Lock changes while stunned
	local changedConn = humanoid.Changed:Connect(function()
		humanoid.WalkSpeed = newSpeed
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end)

	local function cleanup()
		if humanoid:IsDescendantOf(game) then
			humanoid.WalkSpeed = originalSpeed
			humanoid.JumpPower = originalJumpPower
			humanoid.JumpHeight = originalJumpHeight
			char:SetAttribute("Stunned", false)
		end

		if changedConn then
			changedConn:Disconnect()
		end

		stunnedMap[humanoid] = nil
	end

	-- Schedule unstun
	local handle = task.delay(duration, cleanup)

	-- Store stun info
	stunnedMap[humanoid] = {
		task = handle,
		conn = changedConn,
	}
end

return StunHandler
