local ParticleHelper = {}

function ParticleHelper.EmitPart(part)
	for _, v in part:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			if v:GetAttribute("EmitDelay") and v:GetAttribute("EmitDelay") > 0 then
				task.delay(v:GetAttribute("EmitDelay"), function()
					v:Emit(v:GetAttribute("EmitCount"))
				end)
			else
				v:Emit(v:GetAttribute("EmitCount"))
			end
		end
	end
end

return ParticleHelper
