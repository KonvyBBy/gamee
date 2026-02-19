-- CourtBuilder.server.lua
-- Programmatically builds the basketball court, hoop, and ball in the workspace.

local RunService = game:GetService("RunService")

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function part(parent, name, size, position, color, material, anchored, transparency)
	local p = Instance.new("Part")
	p.Name          = name
	p.Size          = size
	p.CFrame        = CFrame.new(position)
	p.BrickColor    = BrickColor.new(color)
	p.Material      = material or Enum.Material.SmoothPlastic
	p.Anchored      = anchored ~= false
	p.CanCollide    = true
	p.Transparency  = transparency or 0
	p.Parent        = parent
	return p
end

local function cylinder(parent, name, size, cframe, color, material)
	local p = part(parent, name, size, Vector3.new(0,0,0), color, material)
	p.Shape  = Enum.PartType.Cylinder
	p.CFrame = cframe
	return p
end

-- ── Court ────────────────────────────────────────────────────────────────────

local court = Instance.new("Model")
court.Name = "BasketballCourt"
court.Parent = workspace

-- Floor
local floor = part(court, "Floor",
	Vector3.new(56, 1, 30),
	Vector3.new(0, -0.5, 0),
	"Bright orange", Enum.Material.Wood)

-- Court lines (white decal-style strips)
local function line(name, size, pos)
	local l = part(court, name, size, pos, "White", Enum.Material.SmoothPlastic)
	l.CFrame = CFrame.new(pos) * CFrame.new(0, 0.51, 0)
	l.Size   = Vector3.new(size.X, 0.05, size.Z)
	return l
end

line("CenterLine",  Vector3.new(0.3, 0.05, 30), Vector3.new(0,  0.5, 0))
line("CenterCircle", Vector3.new(6, 0.05, 6),    Vector3.new(0, 0.5, 0))  -- approximate

-- Boundary walls (invisible, keep ball in)
local function wall(name, size, pos)
	local w = part(court, name, size, pos, "Medium stone grey")
	w.Transparency = 0.9
	w.CanCollide   = true
	return w
end
wall("WallLeft",   Vector3.new(1, 10, 30), Vector3.new(-28.5, 5, 0))
wall("WallRight",  Vector3.new(1, 10, 30), Vector3.new( 28.5, 5, 0))
wall("WallFront",  Vector3.new(56, 10, 1), Vector3.new(0, 5, -15.5))
wall("WallBack",   Vector3.new(56, 10, 1), Vector3.new(0, 5,  15.5))

-- Ceiling (invisible)
local ceiling = part(court, "Ceiling", Vector3.new(56, 1, 30), Vector3.new(0, 15, 0), "White")
ceiling.Transparency = 1
ceiling.CanCollide   = false

-- ── Hoop ─────────────────────────────────────────────────────────────────────
-- Positioned at one end of the court (positive Z side, facing player spawn)

local HOOP_X    =  0
local HOOP_Y    = 10       -- rim height
local HOOP_Z    = 12       -- near back wall
local BOARD_Z   = HOOP_Z + 0.5

-- Backboard
local backboard = part(court, "Backboard",
	Vector3.new(6, 4, 0.4),
	Vector3.new(HOOP_X, HOOP_Y + 1.5, BOARD_Z),
	"White", Enum.Material.Glass)
backboard.Transparency = 0.3

-- Backboard inner square (orange guide)
local innerSq = part(court, "BackboardSquare",
	Vector3.new(2.4, 1.8, 0.2),
	Vector3.new(HOOP_X, HOOP_Y + 1.2, BOARD_Z - 0.2),
	"Bright orange")

-- Pole
cylinder(court, "HoopPole",
	Vector3.new(0.4, 12, 0.4),
	CFrame.new(HOOP_X, 6, BOARD_Z + 0.6) * CFrame.Angles(0, 0, math.pi/2),
	"Dark stone grey", Enum.Material.Metal)

-- Rim (two halves so ball can pass through)
local rimRadius = 0.75
local rimPart = Instance.new("Part")
rimPart.Name        = "Rim"
rimPart.Shape       = Enum.PartType.Cylinder
rimPart.Size        = Vector3.new(0.15, rimRadius * 2 * math.pi, 0.15)
rimPart.CFrame      = CFrame.new(HOOP_X, HOOP_Y, BOARD_Z - 1.2)
rimPart.BrickColor  = BrickColor.new("Bright orange")
rimPart.Material    = Enum.Material.Metal
rimPart.Anchored    = true
rimPart.CanCollide  = true
rimPart.Parent      = court

-- Invisible basket sensor (cylinder, no collide) – used to detect made shots
local sensor = Instance.new("Part")
sensor.Name        = "BasketSensor"
sensor.Size        = Vector3.new(rimRadius * 1.8, 0.4, rimRadius * 1.8)
sensor.Shape       = Enum.PartType.Cylinder
sensor.CFrame      = CFrame.new(HOOP_X, HOOP_Y - 0.2, BOARD_Z - 1.2)
                     * CFrame.Angles(0, 0, math.pi/2)
sensor.Transparency = 1
sensor.CanCollide   = false
sensor.Anchored     = true
sensor.Parent       = court

-- Net (decorative cylinders hanging down)
local NET_SEGS = 8
for i = 1, NET_SEGS do
	local angle = (i / NET_SEGS) * math.pi * 2
	local nx = HOOP_X + math.cos(angle) * rimRadius * 0.7
	local nz = (BOARD_Z - 1.2) + math.sin(angle) * rimRadius * 0.7
	local seg = part(court, "Net"..i,
		Vector3.new(0.05, 1.2, 0.05),
		Vector3.new(nx, HOOP_Y - 0.8, nz),
		"White", Enum.Material.Fabric)
	seg.CanCollide = false
end

-- ── Ball ─────────────────────────────────────────────────────────────────────

local ball = Instance.new("Part")
ball.Name       = "Basketball"
ball.Shape      = Enum.PartType.Ball
ball.Size       = Vector3.new(1.5, 1.5, 1.5)
ball.CFrame     = CFrame.new(0, 2, -8)   -- player spawn area
ball.BrickColor = BrickColor.new("Bright orange")
ball.Material   = Enum.Material.SmoothPlastic
ball.Elasticity = 0.5
ball.Friction   = 0.5
ball.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.5, 0.6, 0.1, 0.5)
ball.Parent     = workspace

-- Add a subtle texture line (seam)
local seam = Instance.new("SpecialMesh")
seam.MeshType = Enum.MeshType.Sphere
seam.Parent   = ball

-- Store hoop position as an attribute so other scripts can read it
ball:SetAttribute("HoopX",  HOOP_X)
ball:SetAttribute("HoopY",  HOOP_Y)
ball:SetAttribute("HoopZ",  BOARD_Z - 1.2)

-- ── Spawn ─────────────────────────────────────────────────────────────────────

-- Move default spawn away from hoop
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	spawn.CFrame = CFrame.new(0, 1, -8)
end

print("[CourtBuilder] Court, hoop, and ball ready.")
