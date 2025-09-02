return function(t)
	local isArray = #t > 0
	local parts = {}

	if isArray then
		for _, v in ipairs(t) do
			table.insert(parts, tostring(v))
		end
	else
		for k, v in pairs(t) do
			table.insert(parts, string.format("%s = %s", tostring(k), tostring(v)))
		end
	end

	return "{ " .. table.concat(parts, ", ") .. " }"
end
