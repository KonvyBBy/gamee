-- TimingModule.lua  (ModuleScript – place in ReplicatedStorage)
-- Shared state for the timing meter, readable by both the GUI and ShootingController.

local TimingModule = {}

-- ── Zone definitions (public so GUI can use them to build the bar) ─────────────

TimingModule.ZONES = {
	{ min = 0.00, max = 0.10, label = "MISS",           color = Color3.fromRGB(220,  50,  50) },
	{ min = 0.10, max = 0.30, label = "EARLY!",         color = Color3.fromRGB(220,  50,  50) },
	{ min = 0.30, max = 0.45, label = "SLIGHTLY EARLY", color = Color3.fromRGB(255, 200,   0) },
	{ min = 0.45, max = 0.55, label = "PERFECT!",       color = Color3.fromRGB( 50, 210,  80) },
	{ min = 0.55, max = 0.70, label = "SLIGHTLY LATE",  color = Color3.fromRGB(255, 200,   0) },
	{ min = 0.70, max = 0.90, label = "LATE!",          color = Color3.fromRGB(220,  50,  50) },
	{ min = 0.90, max = 1.00, label = "MISS",           color = Color3.fromRGB(220,  50,  50) },
}

TimingModule.FEEDBACK_COLORS = {
	["PERFECT!"]        = Color3.fromRGB( 50, 220,  80),
	["IN!"]             = Color3.fromRGB( 50, 220,  80),
	["SLIGHTLY EARLY"]  = Color3.fromRGB(255, 200,   0),
	["SLIGHTLY LATE"]   = Color3.fromRGB(255, 200,   0),
	["EARLY!"]          = Color3.fromRGB(255, 100,  50),
	["LATE!"]           = Color3.fromRGB(255, 100,  50),
	["MISS"]            = Color3.fromRGB(220,  50,  50),
}

-- ── Runtime state (written by BasketballGui, read by ShootingController) ───────

local state = {
	meterActive = false,
	needlePos   = 0,    -- 0.0 → 1.0
}

-- Returns the zone table for a given needle position
function TimingModule.getZone(pos)
	for _, zone in ipairs(TimingModule.ZONES) do
		if pos >= zone.min and pos < zone.max then
			return zone
		end
	end
	return TimingModule.ZONES[#TimingModule.ZONES]
end

-- Returns current timing label string
function TimingModule.getTimingLabel()
	return TimingModule.getZone(state.needlePos).label
end

-- Returns current needle position (0–1)
function TimingModule.getNeedlePos()
	return state.needlePos
end

-- Called every frame by BasketballGui to update the needle position
function TimingModule.setNeedlePos(pos)
	state.needlePos = pos
end

-- Called by ShootingController to show/hide the meter
function TimingModule.setMeterActive(active)
	state.meterActive = active
end

function TimingModule.isMeterActive()
	return state.meterActive
end

-- ── BindableEvents for cross-script signalling ────────────────────────────────
-- Created once here; both scripts reference them via the module.

-- ShowMeter: ShootingController fires this to show/hide the meter in BasketballGui
local showMeterEvent = Instance.new("BindableEvent")
showMeterEvent.Name = "ShowMeterEvent"
TimingModule.ShowMeterEvent = showMeterEvent

-- ShowFeedback: ShootingController fires this to trigger feedback in BasketballGui
local showFeedbackEvent = Instance.new("BindableEvent")
showFeedbackEvent.Name = "ShowFeedbackEvent"
TimingModule.ShowFeedbackEvent = showFeedbackEvent

-- AimLabelChange: ShootingController fires this to update the aim hint text
local aimLabelEvent = Instance.new("BindableEvent")
aimLabelEvent.Name = "AimLabelEvent"
TimingModule.AimLabelEvent = aimLabelEvent

return TimingModule
