local WeldHelper = {}

function WeldHelper.WeldParts(partA: BasePart, partB: BasePart)
	if not partA or not partB then
		warn("WeldHelper: Invalid parts provided.")
		return nil
	end

	local weld = Instance.new("WeldConstraint")
	weld.Name = "AutoWeld"
	weld.Part0 = partA
	weld.Part1 = partB
	weld.Parent = partA
	return weld
end

return WeldHelper

