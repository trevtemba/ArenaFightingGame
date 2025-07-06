-- ReplicatedStorage/Champions/Dante/Passive.lua
local Passive = {}

function Passive:Apply(level)
	-- Scale durability or other bonuses with level
	return {
		bonusDurability = level * 2,
	}
end

return Passive

