local WeldHelper = require(script.Parent:WaitForChild("WeldHelper"))

local FXHandler = {}
FXHandler.__index = FXHandler

function FXHandler.new(rig)
	local self = setmetatable({}, FXHandler)

	self.rig = rig
	self.fx = {
		sounds = {},
		particles = {},
		projectiles = {},
	}

	for _, sound in pairs(rig:FindFirstChild("Sounds"):GetChildren()) do
		if sound:IsA("Sound") then
			self.fx.sounds[sound.Name] = sound
		end
	end

	for _, particle in pairs(rig:FindFirstChild("VFX"):FindFirstChild("Particles"):GetChildren()) do
		if particle:IsA("Part") then
			self.fx.particles[particle.Name] = particle
			if particle.Name == "impact" then
				local hrp = self.rig:WaitForChild("HumanoidRootPart")
				particle.CFrame = hrp.CFrame
				particle.Parent = self.rig
				WeldHelper.WeldParts(particle, hrp)
			end
		end
	end

	for _, vfx in pairs(rig:FindFirstChild("VFX"):GetChildren()) do
		if vfx:IsA("Part") then
			self.fx.projectiles[vfx.Name] = vfx
		end
	end

	return self
end

function FXHandler:PlaySound(name)
	local sound = self.fx.sounds[name]
	if sound then
		sound:Play()
	end
end

function FXHandler:PlayParticle(particleName)
	local particleInstance = self.fx.particles[particleName]

	for _, v in pairs(particleInstance:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			if v:GetAttribute("instant") == true then
				v:Emit(v:GetAttribute("emitCount"))
			else
				v.Enabled = true

				task.delay(0.75, function()
					v.Enabled = false
				end)
			end
		end
	end
end

function FXHandler:SetCharacter(newChar)
	self.rig = newChar
end

-- 🔴 Cleanup all attached FX (optional, for hard resets)
function FXHandler:Cleanup()
	for _, child in ipairs(self.rig:GetChildren()) do
		if child:IsA("Sound") or child:IsA("ParticleEmitter") then
			child:Destroy()
		end
	end
end

function FXHandler:GetProjectile(name)
	return self.fx.projectiles[name]
end

return FXHandler
