-- ShootingController.client.lua  (LocalScript – place in StarterPlayerScripts)
-- Handles: picking up ball, aiming, reading timing meter, firing shot to server.
-- Communicates with BasketballGui via TimingModule (ModuleScript in ReplicatedStorage).

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

local TimingModule = require(ReplicatedStorage:WaitForChild("TimingModule"))

local remotes    = ReplicatedStorage:WaitForChild("BasketballRemotes")
local ShootEvent = remotes:WaitForChild("ShootBall")

local ball = workspace:WaitForChild("Basketball")

-- ── Hoop target ───────────────────────────────────────────────────────────────

local HOOP_POS = Vector3.new(
ball:GetAttribute("HoopX") or 0,
ball:GetAttribute("HoopY") or 10,
ball:GetAttribute("HoopZ") or 10.3
)

-- ── State ─────────────────────────────────────────────────────────────────────

local isAiming  = false
local hasBall   = false
local cooldown  = false
local COOLDOWN  = 2.5
local ballWeld  = nil

-- ── Ball pick-up ──────────────────────────────────────────────────────────────

local PICKUP_RANGE = 7

local function canPickUp()
return not hasBall and not cooldown
and ball and ball.Parent
and (rootPart.Position - ball.Position).Magnitude <= PICKUP_RANGE
end

local function attachBall()
local hand = character:FindFirstChild("RightHand")
       or character:FindFirstChild("Right Arm")
       or rootPart

ball.CFrame = hand.CFrame * CFrame.new(0, -0.5, -1)

local weld  = Instance.new("WeldConstraint")
weld.Part0  = hand
weld.Part1  = ball
weld.Parent = ball
ballWeld    = weld

ball.Anchored   = false
ball.CanCollide = false
hasBall         = true
end

local function detachBall()
if ballWeld then
ballWeld:Destroy()
ballWeld = nil
end
ball.CanCollide = true
hasBall         = false
end

-- ── Shot direction ────────────────────────────────────────────────────────────

local function computeShootDirection(power)
local toHoop   = HOOP_POS - ball.Position
local arcAngle = math.rad(50 - power * 20)   -- 30° – 50° arc
local horizDir = Vector3.new(toHoop.X, 0, toHoop.Z).Unit
local dir      = horizDir * math.cos(arcAngle) + Vector3.new(0, 1, 0) * math.sin(arcAngle)
return dir.Unit
end

-- ── Aim indicator helper ──────────────────────────────────────────────────────

local function setAimIndicator(text)
TimingModule.AimLabelEvent:Fire(text)
end

-- ── Shoot ─────────────────────────────────────────────────────────────────────

local function shoot()
if not hasBall or not isAiming or cooldown then return end

local timingLabel  = TimingModule.getTimingLabel()
local needlePos    = TimingModule.getNeedlePos()
local distCenter   = math.abs(needlePos - 0.5) * 2   -- 0 = centre, 1 = edge
local power        = 1 - distCenter * 0.7             -- 0.3 – 1.0

local isMiss = (timingLabel == "MISS")
if isMiss then power = power * 0.5 end

detachBall()
isAiming = false
TimingModule.ShowMeterEvent:Fire(false)
setAimIndicator("")

ShootEvent:FireServer(computeShootDirection(power), power, isMiss and "MISS" or timingLabel)

-- Show timing feedback locally for instant response
TimingModule.ShowFeedbackEvent:Fire(timingLabel)

cooldown = true
task.delay(COOLDOWN, function()
cooldown = false
end)
end

-- ── Input ─────────────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end

if input.KeyCode == Enum.KeyCode.E then
if canPickUp() then
attachBall()
setAimIndicator("Hold [F] to aim")
end
end

if input.KeyCode == Enum.KeyCode.F then
if hasBall and not isAiming then
isAiming = true
TimingModule.ShowMeterEvent:Fire(true)
setAimIndicator("Release [F] to SHOOT!")
end
end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
if input.KeyCode == Enum.KeyCode.F and isAiming then
shoot()
end
end)

-- ── Proximity indicator ───────────────────────────────────────────────────────

RunService.RenderStepped:Connect(function()
if not character or not ball then return end
if hasBall then return end
local dist = (rootPart.Position - ball.Position).Magnitude
setAimIndicator(dist <= PICKUP_RANGE and "Press [E] to pick up ball" or "")
end)

-- ── Respawn ───────────────────────────────────────────────────────────────────

player.CharacterAdded:Connect(function(newChar)
character = newChar
humanoid  = newChar:WaitForChild("Humanoid")
rootPart  = newChar:WaitForChild("HumanoidRootPart")
hasBall   = false
isAiming  = false
cooldown  = false
ballWeld  = nil
TimingModule.ShowMeterEvent:Fire(false)
end)

print("[ShootingController] Ready. [E] pick up ball, [F] hold to aim / release to shoot.")
