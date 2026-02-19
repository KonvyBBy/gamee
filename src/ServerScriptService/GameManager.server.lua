-- GameManager.server.lua
-- Handles scoring, ball resets, and RemoteEvents for the shooting system.

local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris          = game:GetService("Debris")
local RunService      = game:GetService("RunService")

-- ── RemoteEvents ──────────────────────────────────────────────────────────────

local remotes = Instance.new("Folder")
remotes.Name   = "BasketballRemotes"
remotes.Parent = ReplicatedStorage

local ShootEvent   = Instance.new("RemoteEvent")
ShootEvent.Name    = "ShootBall"
ShootEvent.Parent  = remotes

local ScoreEvent   = Instance.new("RemoteEvent")
ScoreEvent.Name    = "ScoreUpdate"
ScoreEvent.Parent  = remotes

local FeedbackEvent = Instance.new("RemoteEvent")
FeedbackEvent.Name  = "ShotFeedback"
FeedbackEvent.Parent = remotes

-- ── Score state ───────────────────────────────────────────────────────────────

local scores = {}   -- { [userId] = score }

local function getScore(player)
	return scores[player.UserId] or 0
end

local function addScore(player, points)
	scores[player.UserId] = getScore(player) + points
	-- Broadcast updated score to the shooter
	ScoreEvent:FireClient(player, scores[player.UserId])
end

-- ── Ball helpers ──────────────────────────────────────────────────────────────

local RESET_DELAY = 4  -- seconds before ball resets to spawn

local function getBall()
	return workspace:FindFirstChild("Basketball")
end

local function resetBall()
	local ball = getBall()
	if ball then
		ball.CFrame    = CFrame.new(0, 2, -8)
		ball.Velocity  = Vector3.new(0, 0, 0)
		ball.RotVelocity = Vector3.new(0, 0, 0)
	end
end

-- ── Basket detection ──────────────────────────────────────────────────────────
-- Watches the BasketSensor for balls passing through from above.

local sensor = workspace:WaitForChild("BasketballCourt"):WaitForChild("BasketSensor")

-- Track whether ball has entered from above
local ballAbove = false

RunService.Heartbeat:Connect(function()
	local ball = getBall()
	if not ball then return end

	local ballPos   = ball.Position
	local sensPos   = sensor.Position
	local rimHeight = sensPos.Y + 0.2   -- top of sensor

	-- Within the horizontal radius of the basket?
	local dx = ballPos.X - sensPos.X
	local dz = ballPos.Z - sensPos.Z
	local horizDist = math.sqrt(dx*dx + dz*dz)

	if horizDist < 0.9 then
		if ballPos.Y > rimHeight then
			ballAbove = true
		elseif ballAbove and ballPos.Y < rimHeight then
			-- Ball crossed through basket from above → SCORE!
			ballAbove = false

			-- Find which player owns the ball (attribute set by ShootBall handler)
			local shooterId = ball:GetAttribute("ShooterId")
			if shooterId then
				local player = Players:GetPlayerByUserId(shooterId)
				if player then
					addScore(player, 2)
					FeedbackEvent:FireClient(player, "IN!", true)
					print("[GameManager] Score! Player:", player.Name, "| Total:", getScore(player))
				end
			end

			-- Reset ball after delay
			task.delay(RESET_DELAY, resetBall)
		end
	else
		ballAbove = false
	end
end)

-- ── ShootBall handler ─────────────────────────────────────────────────────────
-- Client fires this with: (direction: Vector3, power: number 0‒1, timing: string)

ShootEvent.OnServerEvent:Connect(function(player, direction, power, timingLabel)
	local ball = getBall()
	if not ball then return end

	-- Tag ball with shooter
	ball:SetAttribute("ShooterId", player.UserId)

	-- Clamp power
	power = math.clamp(power or 0.5, 0, 1)

	-- Base launch speed scales with power
	local SPEED_MIN = 28
	local SPEED_MAX = 48
	local speed = SPEED_MIN + (SPEED_MAX - SPEED_MIN) * power

	-- Apply directional launch from ball position
	ball.Velocity = direction.Unit * speed

	-- Slight random spin for realism
	ball.RotVelocity = Vector3.new(
		math.random(-5, 5),
		math.random(-5, 5),
		math.random(-5, 5)
	)

	-- If shot is marked as a miss by the client timing system, nudge ball off-target
	if timingLabel == "MISS" then
		local sideNudge = (math.random() - 0.5) * 12
		local depthNudge = math.random(-4, 0)
		ball.Velocity = ball.Velocity + Vector3.new(sideNudge, 0, depthNudge)
	end

	print(string.format("[GameManager] %s shot the ball | timing=%s | power=%.2f",
		player.Name, timingLabel or "?", power))
end)

-- ── Player cleanup ────────────────────────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
	scores[player.UserId] = nil
end)

print("[GameManager] Ready.")
