--[[
	The character's movement input, expressed relative to the way it is facing.

	Humanoid.MoveDirection is maintained by Roblox's own control scripts, so it is
	correct in both camera modes and needs no knowledge of which InputContext is
	live. That matters: the previous approach read a heldInputs table that only
	the Shiftlocked context populated, which is why dashes always went forward
	whenever the camera was locked but the context had drifted.

	Dotting it against the root part's axes gives a character-relative answer,
	which is the frame both physicsModule.Dash and the walk animations resolve
	against.
]]
local MoveDirection = {}

-- Below this the player is not really steering, just drift or numerical noise.
local MOVING_THRESHOLD = 0.1

-- Movement input resolved onto the character's own axes. Both components are 0
-- when standing still, including when opposing inputs cancel each other out.
local function components(character)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then
		return nil
	end

	local move = humanoid.MoveDirection
	if move.Magnitude < MOVING_THRESHOLD then
		return nil
	end

	return hrp.CFrame.LookVector:Dot(move), hrp.CFrame.RightVector:Dot(move)
end

--[[
	Signed forward component of the movement input, -1 to 1, or 0 when standing
	still.

	Distinct from Relative below, which answers "which single direction wins" --
	the right question for a dash, where exactly one of four animations has to be
	chosen. Sustaining a sprint is a different question: a diagonal like W+D is
	dominated by the strafe under Relative's tie-break, yet roughly 0.7 of its
	momentum is still going forward and it should keep the sprint alive.
]]
function MoveDirection.ForwardAmount(character)
	local forwardDot = components(character)
	return forwardDot or 0
end

--[[
	Returns "forward" | "back" | "left" | "right", or nil when standing still.

	Callers that must always have a direction should fall back themselves --
	getDashDirection uses `or "forward"`, so a standing dash goes the way the
	character faces.
]]
function MoveDirection.Relative(character)
	local forwardDot, rightDot = components(character)
	if not forwardDot then
		return nil
	end

	-- Ties go to the strafe, matching the old ordering where left/right were
	-- tested before back: a diagonal like W+A side-dashes.
	if math.abs(forwardDot) > math.abs(rightDot) then
		return forwardDot >= 0 and "forward" or "back"
	end
	return rightDot >= 0 and "right" or "left"
end

return MoveDirection
