--[[
	AudioEnvironment: how the place around the listener (the camera) changes what is heard.

	Tunnels. The maps mark the inside of every tunnel with invisible box parts tagged "TunnelZone"
	(CollectionService); long or curved tunnels are chains of boxes that overlap at the joints. While
	the camera is inside one, every SoundGroup attached here gets:
	  * reverb (ReverbSoundEffect), its decay from the zone's ReverbDecay attribute;
	  * a short slap echo between the walls (EchoSoundEffect), its delay from the zone's width;
	  * a low-mid build-up (EqualizerSoundEffect: the reverberant field of a concrete tube keeps the
	    lows and loses the highs);
	  * a level rise.
	The effect starts a little before a portal and eases in over the first metres inside, scaled by
	how fast the camera moves, then eases out the same way.

	Zone attributes (optional): ReverbDecay (seconds, default 1.6), ReverbWet (dB, default -4).
	Testing without a tunnel: during Play, set the attribute ForceTunnel = true on SoundService.

	The maths (TunnelMath below) is copied in tools/audio_preview.py, which renders a tunnel pass.
	Keep the two in step.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local TAG = "TunnelZone"
local METERS_PER_STUD = 0.28

local TunnelMath = {
	APPROACH_M = 12, -- the effect begins this far before a portal
	APPROACH_SHARE = 0.4, -- and reaches this share of full at the portal
	EASE_M = 15, -- it is nearly complete this far inside (and gone this far outside)
	MIN_RATE = 1.2, -- 1/s, the slowest easing (a camera standing still)
	DEFAULT_DECAY = 1.6, -- s
	DEFAULT_WET = -4, -- dB
	LEVEL_RISE = 0.26, -- +2 dB
	LOW_GAIN = 5, -- dB below 400 Hz
	MID_GAIN = 1.5, -- dB from 400 Hz to 4 kHz
	HIGH_GAIN = -2, -- dB above 4 kHz
	ECHO_WET = -14, -- dB
	ECHO_FEEDBACK = 0.3,
}
TunnelMath.__index = TunnelMath

-- Target amount (0-1) for a listener this many metres outside the nearest zone (0 = inside).
function TunnelMath.target(outsideM: number): number
	if outsideM <= 0 then
		return 1
	end
	return math.clamp(1 - outsideM / TunnelMath.APPROACH_M, 0, 1) * TunnelMath.APPROACH_SHARE
end

-- One easing step: how far the amount moves toward the target this frame.
function TunnelMath.ease(amount: number, target: number, speed: number, dt: number): number
	local rate = math.max(TunnelMath.MIN_RATE, 3 * speed / TunnelMath.EASE_M)
	return amount + (target - amount) * math.clamp(rate * dt, 0, 1)
end

-- Reverb wet level (dB) for an amount, rising quickly at first.
function TunnelMath.wetLevel(amount: number, wet: number): number
	return -40 + (wet + 40) * math.sqrt(amount)
end

-- Slap echo delay (s) across a tunnel this many metres wide.
function TunnelMath.echoDelay(widthM: number): number
	return math.clamp(widthM / 343, 0.02, 0.08)
end

local AudioEnvironment = {}
AudioEnvironment.TunnelMath = TunnelMath

local zones: { [BasePart]: boolean } = {}
local groups = {} -- SoundGroup -> { reverb, echo, eq, baseVolume }
local amount = 0
local decay = TunnelMath.DEFAULT_DECAY
local wet = TunnelMath.DEFAULT_WET
local echoDelay = 0.035
local lastPosition: Vector3? = nil
local speed = 0
local started = false

local function addZone(instance: Instance)
	if instance:IsA("BasePart") then
		zones[instance] = true
	end
end

local function removeZone(instance: Instance)
	zones[instance :: BasePart] = nil
end

-- Distance in metres from a point to a box part (0 inside), using the part's own axes.
local function outsideDistance(part: BasePart, point: Vector3): number
	local p = part.CFrame:PointToObjectSpace(point)
	local h = part.Size / 2
	local dx = math.max(math.abs(p.X) - h.X, 0)
	local dy = math.max(math.abs(p.Y) - h.Y, 0)
	local dz = math.max(math.abs(p.Z) - h.Z, 0)
	return math.sqrt(dx * dx + dy * dy + dz * dz) * METERS_PER_STUD
end

local function apply(group: SoundGroup, entry)
	local on = amount > 0.002
	entry.reverb.Enabled = on
	entry.echo.Enabled = on
	entry.eq.Enabled = on
	if on then
		entry.reverb.DecayTime = decay
		entry.reverb.WetLevel = TunnelMath.wetLevel(amount, wet)
		entry.echo.Delay = echoDelay
		entry.echo.WetLevel = -40 + (TunnelMath.ECHO_WET + 40) * amount
		entry.eq.LowGain = TunnelMath.LOW_GAIN * amount
		entry.eq.MidGain = TunnelMath.MID_GAIN * amount
		entry.eq.HighGain = TunnelMath.HIGH_GAIN * amount
	end
	group.Volume = entry.baseVolume * (1 + TunnelMath.LEVEL_RISE * amount)
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local position = camera.CFrame.Position
	if lastPosition and dt > 0 then
		local moved = (position - lastPosition).Magnitude * METERS_PER_STUD
		if moved < 40 then -- ignore camera cuts and respawns
			speed += (moved / dt - speed) * math.clamp(5 * dt, 0, 1)
		end
	end
	lastPosition = position

	local nearest, nearestPart = math.huge, nil
	for part in zones do
		local d = outsideDistance(part, position)
		if d < nearest then
			nearest, nearestPart = d, part
		end
	end
	local target = TunnelMath.target(nearest)
	if SoundService:GetAttribute("ForceTunnel") == true then
		target = 1
	end
	if nearestPart then
		local d = nearestPart:GetAttribute("ReverbDecay")
		local w = nearestPart:GetAttribute("ReverbWet")
		decay = math.clamp(if type(d) == "number" then d else TunnelMath.DEFAULT_DECAY, 0.1, 20)
		wet = math.clamp(if type(w) == "number" then w else TunnelMath.DEFAULT_WET, -40, 10)
		local size = nearestPart.Size
		echoDelay = TunnelMath.echoDelay(math.min(size.X, size.Z) * METERS_PER_STUD)
	end
	local before = amount
	amount = TunnelMath.ease(amount, target, speed, dt)
	if amount < 0.001 and before < 0.001 then
		amount = 0
	end
	for group, entry in groups do
		apply(group, entry)
	end
end

local function start()
	if started then
		return
	end
	started = true
	for _, instance in CollectionService:GetTagged(TAG) do
		addZone(instance)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(addZone)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(removeZone)
	RunService.Heartbeat:Connect(update)
end

-- Adds tunnel effects to a SoundGroup (call once per group, before it plays).
function AudioEnvironment.attach(group: SoundGroup)
	start()
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.Name = "TunnelReverb"
	reverb.DryLevel = 0
	reverb.WetLevel = -40
	reverb.Density = 1
	reverb.Diffusion = 0.7
	reverb.DecayTime = TunnelMath.DEFAULT_DECAY
	reverb.Enabled = false
	reverb.Parent = group
	local echo = Instance.new("EchoSoundEffect")
	echo.Name = "TunnelEcho"
	echo.DryLevel = 0
	echo.WetLevel = -40
	echo.Feedback = TunnelMath.ECHO_FEEDBACK
	echo.Delay = 0.035
	echo.Enabled = false
	echo.Parent = group
	local eq = Instance.new("EqualizerSoundEffect")
	eq.Name = "TunnelEq"
	eq.LowGain = 0
	eq.MidGain = 0
	eq.HighGain = 0
	eq.Enabled = false
	eq.Parent = group
	groups[group] = { reverb = reverb, echo = echo, eq = eq, baseVolume = group.Volume }
	apply(group, groups[group])
end

function AudioEnvironment.detach(group: SoundGroup)
	groups[group] = nil
end

-- How much tunnel the listener hears now, 0-1 (for other modules and testing).
function AudioEnvironment.tunnelAmount(): number
	return amount
end

return AudioEnvironment
