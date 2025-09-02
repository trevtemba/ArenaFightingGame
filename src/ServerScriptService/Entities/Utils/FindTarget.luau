return function(originPlrObj, origin, direction, range, angle)
	if not origin or not direction then
		return
	end
	direction = direction.Unit

	local bestTarget, bestDist = nil, math.huge

	for _, enemyObj in pairs(originPlrObj.currentEnemies) do
		local enemy = enemyObj.character
		local hrp = enemy and enemy:FindFirstChild("HumanoidRootPart")
		local hum = enemy and enemy:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local vec = hrp.Position - origin
			local dist = vec.Magnitude
			if dist <= range then
				local dot = direction:Dot(vec.Unit)
				local theta = math.deg(math.acos(dot))
				print("Target:", enemyObj, "Dist:", dist, "Theta:", theta)

				if theta <= angle and dist < bestDist then
					-- Line of sight check
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = { originPlrObj.character }

					local ray = workspace:Raycast(origin, vec, params)
					if ray then
						print("Ray hit:", ray.Instance:GetFullName())
					else
						print("Ray hit nothing")
					end

					if not ray or ray.Instance:IsDescendantOf(enemy) then
						bestTarget, bestDist = enemyObj, dist
					end
				end
			end
		end
	end

	return bestTarget
end
