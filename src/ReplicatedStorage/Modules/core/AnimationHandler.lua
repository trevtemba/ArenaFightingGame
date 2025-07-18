-- AnimationHandler.lua
local AnimationHandler = {}
AnimationHandler.__index = AnimationHandler

local DEFAULT_WALKSPEED = 18

function AnimationHandler.new(rig)
	local self = setmetatable({}, AnimationHandler)
	self.animator = rig:FindFirstChild("Humanoid"):FindFirstChildOfClass("Animator")
	self.animations = {} -- [name] = { track = AnimationTrack, signals = {} }

	for _, anim in pairs(rig:FindFirstChild("Animations"):GetChildren()) do
		if anim:IsA("Animation") then
			local animTrack = self.animator:LoadAnimation(anim)
			local name = anim.Name

			self.animations[name] = {
				track = animTrack,
				stoppedConn = nil, -- single .Stopped connection
				markerConns = {}, -- [markerName] = connection
			}
			animTrack:Play()
			animTrack:Stop()
		end
	end

	return self
end

function AnimationHandler:Play(name, fadeTime, weight, speed, looped)
	local animData = self.animations[name]
	if animData then
		animData.track:Play(fadeTime or 0.1, weight or 1)
		animData.track:AdjustSpeed(speed or 1)
		animData.track.Looped = looped or false
	end
end

function AnimationHandler:PlayRun(speed, fadeTime, weight)
	local animData = self.animations["run"]
	if animData then
		animData.track:Play(fadeTime or 0.1, weight or 1)
		animData.track:AdjustSpeed(speed / DEFAULT_WALKSPEED)
	end
end

function AnimationHandler:ConnectStopped(name, callback)
	local animData = self.animations[name]
	if animData then
		-- Disconnect old Stopped connection if it exists
		if animData.stoppedConn then
			animData.stoppedConn:Disconnect()
		end

		-- Connect and store
		animData.stoppedConn = animData.track.Stopped:Connect(callback)
	end
end

function AnimationHandler:ConnectMarker(name, markerName, callback)
	local animData = self.animations[name]
	if animData then
		-- Ensure markerConns table exists
		animData.markerConns = animData.markerConns or {}

		-- Disconnect existing marker connection
		if animData.markerConns[markerName] then
			animData.markerConns[markerName]:Disconnect()
		end

		-- Connect and store
		local conn = animData.track:GetMarkerReachedSignal(markerName):Connect(callback)
		animData.markerConns[markerName] = conn
	end
end

function AnimationHandler:Stop(name)
	local animData = self.animations[name]
	if animData then
		animData.track:Stop()
	end
end

function AnimationHandler:StopAll()
	for _, animData in pairs(self.animations) do
		animData.track:Stop()
	end
end

function AnimationHandler:SetCharacter(newChar)
	local humanoid = newChar:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self.animator = humanoid:FindFirstChildOfClass("Animator")
	else
		self.animator = nil
	end
end

function AnimationHandler:Cleanup()
	for _, animData in pairs(self.animations) do
		-- Disconnect Stopped
		if animData.stoppedConn then
			animData.stoppedConn:Disconnect()
			animData.stoppedConn = nil
		end

		-- Disconnect marker connections
		if animData.markerConns then
			for _, conn in pairs(animData.markerConns) do
				conn:Disconnect()
			end
			animData.markerConns = {}
		end
	end
end

return AnimationHandler
