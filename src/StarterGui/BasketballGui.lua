-- BasketballGui.lua  (LocalScript – place in StarterGui)
-- Creates the timing-meter UI, score display, and shot-feedback text.
-- Communicates with ShootingController via TimingModule (ModuleScript in ReplicatedStorage).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TimingModule = require(ReplicatedStorage:WaitForChild("TimingModule"))

-- Wait for RemoteEvents (created by GameManager on the server)
local remotes       = ReplicatedStorage:WaitForChild("BasketballRemotes")
local ScoreEvent    = remotes:WaitForChild("ScoreUpdate")
local FeedbackEvent = remotes:WaitForChild("ShotFeedback")

-- ── Constants ─────────────────────────────────────────────────────────────────

local METER_WIDTH  = 360
local METER_HEIGHT = 36
local NEEDLE_W     = 8
local NEEDLE_SPEED = 0.9   -- fraction of bar per second

local ZONES = TimingModule.ZONES

-- ── Build ScreenGui ───────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "BasketballGui"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = playerGui

-- ── Score Display ─────────────────────────────────────────────────────────────

local scoreFrame = Instance.new("Frame")
scoreFrame.Name                  = "ScoreFrame"
scoreFrame.Size                  = UDim2.new(0, 200, 0, 80)
scoreFrame.Position               = UDim2.new(0.5, -100, 0, 16)
scoreFrame.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
scoreFrame.BackgroundTransparency = 0.35
scoreFrame.BorderSizePixel        = 0
scoreFrame.Parent                 = screenGui

local scoreCorner = Instance.new("UICorner")
scoreCorner.CornerRadius = UDim.new(0, 14)
scoreCorner.Parent       = scoreFrame

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size                  = UDim2.new(1, 0, 0.4, 0)
scoreLabel.Position               = UDim2.new(0, 0, 0, 4)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Font                   = Enum.Font.GothamBold
scoreLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
scoreLabel.TextScaled             = true
scoreLabel.Text                   = "SCORE"
scoreLabel.Parent                 = scoreFrame

local scoreValue = Instance.new("TextLabel")
scoreValue.Name                  = "Value"
scoreValue.Size                  = UDim2.new(1, 0, 0.6, 0)
scoreValue.Position               = UDim2.new(0, 0, 0.4, 0)
scoreValue.BackgroundTransparency = 1
scoreValue.Font                   = Enum.Font.GothamBold
scoreValue.TextColor3             = Color3.fromRGB(255, 220, 0)
scoreValue.TextScaled             = true
scoreValue.Text                   = "0"
scoreValue.Parent                 = scoreFrame

-- ── Timing Meter ─────────────────────────────────────────────────────────────

local meterContainer = Instance.new("Frame")
meterContainer.Name                  = "MeterContainer"
meterContainer.Size                  = UDim2.new(0, METER_WIDTH + 20, 0, METER_HEIGHT + 60)
meterContainer.Position               = UDim2.new(0.5, -(METER_WIDTH + 20) / 2, 1, -(METER_HEIGHT + 90))
meterContainer.BackgroundTransparency = 1
meterContainer.Visible               = false
meterContainer.Parent                = screenGui

local meterTitle = Instance.new("TextLabel")
meterTitle.Size                  = UDim2.new(1, 0, 0, 28)
meterTitle.Position               = UDim2.new(0, 0, 0, 0)
meterTitle.BackgroundTransparency = 1
meterTitle.Font                   = Enum.Font.GothamBold
meterTitle.TextColor3             = Color3.fromRGB(255, 255, 255)
meterTitle.TextScaled             = true
meterTitle.Text                   = "🏀  SHOOT TIMING  –  Release [F] to shoot!"
meterTitle.Parent                 = meterContainer

local barBg = Instance.new("Frame")
barBg.Name            = "BarBg"
barBg.Size            = UDim2.new(0, METER_WIDTH, 0, METER_HEIGHT)
barBg.Position        = UDim2.new(0, 10, 0, 32)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
barBg.BorderSizePixel  = 0
barBg.Parent           = meterContainer

Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 8)

-- Colour zones
for i, zone in ipairs(ZONES) do
local zf = Instance.new("Frame")
zf.Size             = UDim2.new(zone.max - zone.min, 0, 1, 0)
zf.Position         = UDim2.new(zone.min, 0, 0, 0)
zf.BackgroundColor3  = zone.color
zf.BorderSizePixel   = 0
zf.ZIndex            = 2
zf.Parent            = barBg

-- Dot in the perfect zone
if zone.label == "PERFECT!" then
local dot = Instance.new("TextLabel")
dot.Size                  = UDim2.new(1, -2, 1, 0)
dot.Position              = UDim2.new(0, 1, 0, 0)
dot.BackgroundTransparency = 1
dot.Font                  = Enum.Font.GothamBold
dot.TextColor3            = Color3.fromRGB(255, 255, 255)
dot.TextTransparency      = 0.2
dot.TextScaled            = true
dot.Text                  = "●"
dot.ZIndex                = 3
dot.Parent                = zf
end
end

-- Divider lines between zones
for i = 1, #ZONES - 1 do
local div = Instance.new("Frame")
div.Size            = UDim2.new(0, 2, 1, 0)
div.Position        = UDim2.new(ZONES[i].max, -1, 0, 0)
div.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
div.BorderSizePixel  = 0
div.ZIndex           = 4
div.Parent           = barBg
end

-- Needle
local needle = Instance.new("Frame")
needle.Name            = "Needle"
needle.Size            = UDim2.new(0, NEEDLE_W, 1, 8)
needle.Position        = UDim2.new(0, -NEEDLE_W / 2, 0, -4)
needle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
needle.BorderSizePixel  = 0
needle.ZIndex           = 5
needle.Parent           = barBg

Instance.new("UICorner", needle).CornerRadius = UDim.new(0, 4)

local pressHint = Instance.new("TextLabel")
pressHint.Size                  = UDim2.new(1, 0, 0, 20)
pressHint.Position               = UDim2.new(0, 0, 1, -2)
pressHint.BackgroundTransparency = 1
pressHint.Font                   = Enum.Font.Gotham
pressHint.TextColor3             = Color3.fromRGB(200, 200, 200)
pressHint.TextScaled             = true
pressHint.Text                   = "Hold [F] to aim  •  Release [F] to shoot"
pressHint.Parent                 = meterContainer

-- ── Feedback Text ─────────────────────────────────────────────────────────────

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name                   = "FeedbackText"
feedbackLabel.Size                   = UDim2.new(0, 500, 0, 80)
feedbackLabel.Position                = UDim2.new(0.5, -250, 0.38, 0)
feedbackLabel.BackgroundTransparency  = 1
feedbackLabel.Font                    = Enum.Font.GothamBold
feedbackLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
feedbackLabel.TextStrokeColor3        = Color3.fromRGB(0, 0, 0)
feedbackLabel.TextStrokeTransparency  = 0.4
feedbackLabel.TextScaled              = true
feedbackLabel.Text                    = ""
feedbackLabel.ZIndex                  = 10
feedbackLabel.Parent                  = screenGui

local feedStroke = Instance.new("UIStroke")
feedStroke.Color     = Color3.fromRGB(0, 0, 0)
feedStroke.Thickness = 3
feedStroke.Parent    = feedbackLabel

-- ── Aim Indicator ─────────────────────────────────────────────────────────────

local aimLabel = Instance.new("TextLabel")
aimLabel.Name                   = "AimIndicator"
aimLabel.Size                   = UDim2.new(0, 300, 0, 40)
aimLabel.Position                = UDim2.new(0.5, -150, 0.5, -60)
aimLabel.BackgroundTransparency  = 1
aimLabel.Font                    = Enum.Font.GothamBold
aimLabel.TextColor3              = Color3.fromRGB(255, 220, 0)
aimLabel.TextScaled              = true
aimLabel.Text                    = ""
aimLabel.ZIndex                  = 10
aimLabel.Parent                  = screenGui

-- ── Needle animation ──────────────────────────────────────────────────────────

local needlePos = 0
local needleDir = 1
local feedbackTween = nil

RunService.RenderStepped:Connect(function(dt)
if not TimingModule.isMeterActive() then return end

needlePos = needlePos + needleDir * NEEDLE_SPEED * dt
if needlePos >= 1 then
needlePos = 1
needleDir = -1
elseif needlePos <= 0 then
needlePos = 0
needleDir = 1
end

TimingModule.setNeedlePos(needlePos)

needle.Position        = UDim2.new(needlePos, -NEEDLE_W / 2, 0, -4)
needle.BackgroundColor3 = TimingModule.getZone(needlePos).color
end)

-- ── ShowMeter BindableEvent ───────────────────────────────────────────────────

TimingModule.ShowMeterEvent.Event:Connect(function(show)
meterContainer.Visible = show
TimingModule.setMeterActive(show)
if show then
needlePos = 0
needleDir = 1
TimingModule.setNeedlePos(0)
end
end)

-- ── AimLabel BindableEvent ────────────────────────────────────────────────────

TimingModule.AimLabelEvent.Event:Connect(function(text)
aimLabel.Text = text
end)

-- ── ShowFeedback BindableEvent ────────────────────────────────────────────────

local function showFeedback(text)
if feedbackTween then feedbackTween:Cancel() end

feedbackLabel.Text             = text
feedbackLabel.TextTransparency  = 0
feedbackLabel.TextColor3        = TimingModule.FEEDBACK_COLORS[text]
or Color3.fromRGB(255, 255, 255)
feedbackLabel.Position          = UDim2.new(0.5, -250, 0.38, 0)

TweenService:Create(feedbackLabel,
TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
{ Position = UDim2.new(0.5, -250, 0.35, 0) }):Play()

task.delay(0.8, function()
feedbackTween = TweenService:Create(feedbackLabel,
TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
{ TextTransparency = 1 })
feedbackTween:Play()
end)
end

TimingModule.ShowFeedbackEvent.Event:Connect(function(text)
showFeedback(text)
end)

-- ── Remote event handlers ─────────────────────────────────────────────────────

ScoreEvent.OnClientEvent:Connect(function(newScore)
scoreValue.Text = tostring(newScore)
local pulseTween = TweenService:Create(scoreValue,
TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
{ TextColor3 = Color3.fromRGB(255, 255, 80) })
pulseTween:Play()
pulseTween.Completed:Connect(function()
TweenService:Create(scoreValue,
TweenInfo.new(0.4),
{ TextColor3 = Color3.fromRGB(255, 220, 0) }):Play()
end)
end)

FeedbackEvent.OnClientEvent:Connect(function(text)
showFeedback(text)
end)

print("[BasketballGui] UI ready.")
