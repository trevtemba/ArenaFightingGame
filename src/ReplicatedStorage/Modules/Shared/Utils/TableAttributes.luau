local HttpService = game:GetService("HttpService")

local TableAttributes = {}

function TableAttributes.Set(instance: Instance, name: string, tbl: any)
	if typeof(instance) ~= "Instance" then
		error("First argument must be an Instance")
	end
	if typeof(tbl) ~= "table" then
		error("Value must be a table")
	end

	-- endcode property to JSON and set as string attribute
	local encoded = HttpService:JSONEncode(tbl)
	instance:SetAttribute(name, encoded)
end

function TableAttributes.Get(instance: Instance, name: string)
	if typeof(instance) ~= "Instance" then
		error("First argument must be an Instance")
	end

	local raw = instance:GetAttribute(name)
	if not raw then
		return nil
	end

	-- decode the JSON back to table
	local success, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)

	if success then
		return decoded
	else
		warn(("Failed to decode table attribute %s: %s"):format(name, tostring(decoded)))
		return nil
	end
end

return TableAttributes
