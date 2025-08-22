return function(originPlrObj, direction, range, angle)
	local char = originPlrObj.character
	if not char then
		return
	end
	local head = char:FindFirstChild("Head")
	if not head then
		return
	end

	local origin = head.Position
	local bestTarget, bestDist = nil, math.huge

	for _, enemyObj in pairs(originPlrObj.currentEnemies) do
		local enemy = enemyObj.character
		local hrp = enemy:FindFirstChild("HumanoidRootPart")
		local hum = enemy:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local vec = hrp.Position - origin
			local dist = vec.Magnitude
			if dist <= range then
				local dot = direction:Dot(vec.Unit)
				local theta = math.deg(math.acos(dot))
				if theta <= angle and dist < bestDist then
					-- Line of sight check
					local ray = workspace:Raycast(origin, vec, RaycastParams.new())
					if not ray or ray.Instance:IsDescendantOf(enemy) then
						bestTarget, bestDist = enemyObj, dist
					end
				end
			end
		end
	end

	return bestTarget
end
