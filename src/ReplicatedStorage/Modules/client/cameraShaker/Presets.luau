-- Camera Shake Presets
-- Stephen Leitnick
-- February 26, 2018

--[[
	
	CameraShakePresets.Bump
	CameraShakePresets.Explosion
	CameraShakePresets.Earthquake
	CameraShakePresets.BadTrip
	CameraShakePresets.HandheldCamera
	CameraShakePresets.Vibration
	CameraShakePresets.RoughDriving
	
--]]

local CameraShakeInstance = require(script.Parent.Instance)

local CameraShakePresets = {

	-- A high-magnitude, short, yet smooth shake.
	-- Should happen once.
	Bump = function()
		local c = CameraShakeInstance.new(2.5, 4, 0.1, 0.75)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Mid_Bump = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5 * 1.5, 4 * 1.5, 0.1 * 1.5, 0.75)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Mid_Bump2 = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5 * 1.5, 4 * 1.5, 0.1 * 1.5, 0.75 * 2)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	-- A high-magnitude, short, yet smooth shake.
	-- Should happen once.
	Light_Bump = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5 / 1.5, 3, 0.15, 0.8)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	["Short_StrongBump"] = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(6.5 * 1.5, 3.5 * 1.5, 0.1 * 1.5, 0.55)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(3, 1, 1)
		return c
	end,

	HeavyLongBump = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5, 3, 0.1, 2)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	BigSmoothBump = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(15, 2.5, 0, 1)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	MidLongBump = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5, 3, 0.1, 1)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Heavy_Bump = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5 * 5, 4, 0.1 * 2, 0.75 * 2)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Heavy_Bump2 = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5 * 3, 3, 0.1 * 2, 0.75 * 2)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Aplified_Heavy_Bump2 = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2.5 * 5, 3, 0.2, 0.75 * 2)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Aplified_Wind_Stronge = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(6.5 * 5, 7.5, 0.25, 0.75)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Intense_Bump = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new((2.5 * 5) * 2, 4, (0.1 * 2) * 2, (0.75 * 2) * 2)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	-- A high-magnitude, short, yet smooth shake.
	-- Should happen once.
	High_Shake = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(2, 10, 0.30, 0.75)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(4, 1, 1)
		return c
	end,

	-- An intense and rough shake.
	-- Should happen once.
	Explosion = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(5, 10, 0.2, 1.5)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(4, 1, 1)
		return c
	end,

	-- An intense, rough but controled shake.
	-- Should happen once.
	ShortExplosion = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(5 / 1.5, 10 / 2.5, 0.1, 0.75)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(4, 1, 1)
		return c
	end,

	-- A continuous, rough shake
	-- Sustained.
	Earthquake = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(0.6, 3.5, 2, 10)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(1, 1, 4)
		return c
	end,

	-- A bizarre shake with a very high magnitude and low roughness.
	-- Sustained.
	BadTrip = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(10, 0.15, 5, 10)
		c.PositionInfluence = Vector3.new(0, 0, 0.15)
		c.RotationInfluence = Vector3.new(2, 1, 4)
		return c
	end,

	-- A subtle, slow shake.
	-- Sustained.
	HandheldCamera = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(1, 0.25, 5, 10)
		c.PositionInfluence = Vector3.new(0, 0, 0)
		c.RotationInfluence = Vector3.new(1, 0.5, 0.5)
		return c
	end,

	-- A very rough, yet low magnitude shake.
	-- Sustained.
	Vibration = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(0.4, 20, 2, 2)
		c.PositionInfluence = Vector3.new(0, 0.15, 0)
		c.RotationInfluence = Vector3.new(1.25, 0, 4)
		return c
	end,

	-- Sustained.
	Half_Vibration = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(0.4, 20, 2 / 2, 2 / 2)
		c.PositionInfluence = Vector3.new(0, 0.15, 0)
		c.RotationInfluence = Vector3.new(1.25, 0, 4)
		return c
	end,

	-- Sustained.
	Half_Vibration2 = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(0.4 * 2, 20 * 2, 2 / 2, 2 / 2)
		c.PositionInfluence = Vector3.new(0, 0.15, 0)
		c.RotationInfluence = Vector3.new(1.25, 0, 4)
		return c
	end,

	Vibration2 = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(0.4, 20, 0.1, 3)
		c.PositionInfluence = Vector3.new(0, 0.15, 0)
		c.RotationInfluence = Vector3.new(1.25, 0, 4)
		return c
	end,

	-- A slightly rough, medium magnitude shake.
	-- Sustained.
	RoughDriving = function()
		-- magnitude, roughness, fadeinTime, fadeOutTime
		local c = CameraShakeInstance.new(1, 2, 1, 1)
		c.PositionInfluence = Vector3.new(0, 0, 0)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end,

	Hit = function()
		local c = CameraShakeInstance.new(2, 10, 0.1, 0.5)
		c.PositionInfluence = Vector3.new(0.15, 0, 0.15)
		c.RotationInfluence = Vector3.new(0.5, 0, 0.5)
		return c
	end,

	Impact = function()
		local c = CameraShakeInstance.new(3, 2, 0.1, 0.5)
		c.PositionInfluence = Vector3.new(0.15, 0, 0.15)
		c.RotationInfluence = Vector3.new(0.5, 0, 0.5)
		return c
	end,
}

return setmetatable({}, {
	__index = function(t, i)
		local f = CameraShakePresets[i]
		if type(f) == "function" then
			return f()
		end
		error('No preset found with index "' .. i .. '"')
	end,
})
