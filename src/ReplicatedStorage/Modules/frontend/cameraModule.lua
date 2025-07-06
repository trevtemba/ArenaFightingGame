local module = {}

local tween = game:GetService("TweenService")
--Grabs variables
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:wait()
local cameraInst = workspace:WaitForChild("Camera")
--Waits for camera part to load
local cameraPart = workspace:WaitForChild("MenuFolder"):WaitForChild("MenuCamera"):WaitForChild("menuCameraPart").CFrame
--Waits for camera to be scriptable, once scriptable..
function module.menuCam()
	
	repeat wait()
		cameraInst.CameraType = Enum.CameraType.Scriptable
	until cameraInst.CameraType == Enum.CameraType.Scriptable
	--Send the camera to cameraPart we created for custom menu camera.
	cameraInst.CFrame = cameraPart
	
end

function module.normCam()
	
	local camera = game.Workspace.Camera
	camera.CameraType = Enum.CameraType.Custom
	
end

return module
