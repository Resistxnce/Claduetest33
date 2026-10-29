-- A pretend Roblox *client* for previewing menus outside Studio. It runs the
-- game's client modules (StarterPlayer.StarterPlayerScripts.Client) with a
-- fake LocalPlayer, PlayerGui, input, camera, tweens and remotes, so the
-- ScreenGuis they build can be exported by gui.luau and drawn by
-- gui_render.mjs. Used by gui.luau; screens files get it as `Client`.
--
-- Folders work like world.luau: the game's src (EARNESP_SRC) first, then each
-- MODELS_SRC folder (split by ":") laid over it, so an agent's folder can
-- replace client/Ui.luau, client/HackMenu.luau and so on.
--
-- Time is fake. Nothing runs on its own: RenderStepped, Heartbeat, Stepped,
-- task.wait and task.delay only move when Client.step(seconds) is called
-- (gui.luau steps a few frames after each Build). Tweens jump straight to
-- their goal, so pictures show where an animation ends.
--
-- Handy calls for screens files (see gui.luau for the file format):
--   Client.require("PlayMenu")            a client module (or "ReplicatedStorage.Shared.Config")
--   Client.run("Main")                    runs a LocalScript such as Main.client.luau
--   Client.setAttributes({ InRound = true, Wave = 1 })   on the LocalPlayer (fires the signals)
--   Client.setStat("Credits", 296100)     leaderstats value (fires .Changed)
--   Client.spawnCharacter({ Health = 95 })
--   Client.step(0.5)                      run half a second of frames, waits and delays
--   Client.click(button) / Client.hover(gui) / Client.pressKey(Enum.KeyCode.H)
--   Client.type(textBox, "esp")           types into a TextBox
--   Client.fireClient("KillFeed", "Noob", 50)   a RemoteEvent from the "server"
--   Client.onInvoke("BuyHack", function(id) return true, "Bought" end)
--   Client.find(root, "Hud.HackMenu.Tabs") / Client.findText(root, "STORE")
--   Client.serverTime()                   what workspace:GetServerTimeNow() returns
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

-- world.luau brings the part and model polyfills (Position, GetPivot, ...)
local World = require("./world")

local Instance = roblox.Instance
local Vector2 = roblox.Vector2
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local UDim2 = roblox.UDim2
local Enum = roblox.Enum

local Client = {}
Client.World = World
Client.roblox = roblox

local MODEL_SRCS = string.split(process.env.MODELS_SRC or "src", ":")
local GAME_SRC = process.env.EARNESP_SRC
	or error("Set EARNESP_SRC to the game's src folder (the one with shared/, server/ and client/)")

-- RemoteFunctions in the game's default.project.json; every other remote is a RemoteEvent
local REMOTE_FUNCTIONS = { BuyHack = true, BanWave = true, BuyUpgrade = true, RedeemCode = true, Armory = true }

-- A pretend clock that starts at a fixed date, so pictures don't change run to run
local EPOCH = 1793000000

-- The current preview: replaced by Client.reset() before every screen
local session

-- Errors from game code -------------------------------------------------------------

-- Lune's errors from Roblox properties aren't strings, and debug.traceback
-- fails on them ("error in error handling"), so make a string first
local function traceback(err)
	if type(err) ~= "string" then
		return tostring(err)
	end
	return debug.traceback(err, 2)
end

-- Game errors are printed once each, the way Studio's output shows them
local function report(message)
	message = tostring(message)
	if not session then
		print("[client error] " .. message)
		return
	end
	local key = string.sub(message, 1, 300)
	if session.errorSeen[key] then
		return
	end
	session.errorSeen[key] = true
	table.insert(session.errors, message)
	print("     [client error] " .. string.gsub(message, "\n", "\n       "))
end
Client.report = report

-- Threads and fake time --------------------------------------------------------------

-- Runs a function in a new thread that task.wait can pause
local function spawnFunction(fn, ...)
	local thread
	thread = coroutine.create(function(...)
		local ok, err = xpcall(fn, traceback, ...)
		if not ok then
			if type(err) == "string" and string.find(err, "error in error handling", 1, true) then
				-- The traceback itself failed (usually a stack overflow); say where it started
				local source, line = debug.info(fn, "sl")
				err ..= ` (in a function from {source}:{line})`
			end
			report(err)
		end
	end)
	session.managed[thread] = true
	local ok, err = coroutine.resume(thread, ...)
	if not ok then
		report(err)
	end
	return thread
end

local function resumeThread(thread, ...)
	if coroutine.status(thread) ~= "suspended" then
		return
	end
	local ok, err = coroutine.resume(thread, ...)
	if not ok then
		report(err)
	end
end

-- Wakes `thread` (or calls `fn`) once the fake clock reaches `at`
local function schedule(at, thread, fn, args)
	session.seq += 1
	local entry = { At = at, Seq = session.seq, Thread = thread, Fn = fn, Args = args }
	table.insert(session.queue, entry)
	return entry
end

local function inTaskThread()
	local thread = coroutine.running()
	return session.managed[thread] == true, thread
end

local function wait(seconds, reason)
	seconds = math.max(tonumber(seconds) or 0, 0)
	local managed, thread = inTaskThread()
	if not managed then
		-- The main thread can't pause (a module's top level, or Build itself)
		return seconds
	end
	local started = session.now
	session.waitingOn[thread] = reason
	schedule(session.now + seconds, thread)
	coroutine.yield()
	session.waitingOn[thread] = nil
	return session.now - started
end

local taskLib = {}
function taskLib.spawn(target, ...)
	if type(target) == "thread" then
		session.managed[target] = true
		resumeThread(target, ...)
		return target
	end
	return spawnFunction(target, ...)
end
function taskLib.defer(target, ...)
	local args = table.pack(...)
	if type(target) == "thread" then
		session.managed[target] = true
		schedule(session.now, target, nil, args)
		return target
	end
	local entry = schedule(session.now, nil, target, args)
	return entry
end
function taskLib.delay(seconds, target, ...)
	local args = table.pack(...)
	if type(target) == "thread" then
		session.managed[target] = true
		schedule(session.now + (seconds or 0), target, nil, args)
		return target
	end
	return schedule(session.now + (seconds or 0), nil, target, args)
end
function taskLib.wait(seconds)
	return wait(seconds, `task.wait({seconds or 0})`)
end
function taskLib.cancel(target)
	for index = #session.queue, 1, -1 do
		local entry = session.queue[index]
		if entry == target or entry.Thread == target then
			table.remove(session.queue, index)
		end
	end
	if type(target) == "thread" then
		pcall(coroutine.close, target)
	end
end
taskLib.desynchronize = function() end
taskLib.synchronize = function() end

-- Runs everything that is due by the fake clock's current time
local function runDue()
	for _ = 1, 10000 do
		local best, bestIndex
		for index, entry in session.queue do
			if
				entry.At <= session.now + 1e-9
				and (not best or entry.At < best.At or (entry.At == best.At and entry.Seq < best.Seq))
			then
				best, bestIndex = entry, index
			end
		end
		if not best then
			return
		end
		table.remove(session.queue, bestIndex)
		local args = best.Args or { n = 0 }
		if best.Thread then
			resumeThread(best.Thread, table.unpack(args, 1, args.n))
		elseif best.Fn then
			spawnFunction(best.Fn, table.unpack(args, 1, args.n))
		end
	end
	report("runDue: more than 10000 tasks in one frame (a loop with task.wait(0)?)")
end

-- Signals ---------------------------------------------------------------------------

local Signal = {}
Signal.__index = Signal

local function newSignal(name)
	return setmetatable({ Name = name, Handlers = {}, Waiting = {} }, Signal)
end
Client.newSignal = newSignal

function Signal:Connect(fn)
	local connection
	connection = {
		Connected = true,
		Fn = fn,
		Disconnect = function()
			connection.Connected = false
			local index = table.find(self.Handlers, connection)
			if index then
				table.remove(self.Handlers, index)
			end
		end,
	}
	table.insert(self.Handlers, connection)
	return connection
end
Signal.ConnectParallel = Signal.Connect

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Wait()
	local managed, thread = inTaskThread()
	if not managed then
		report(`{self.Name or "signal"}:Wait() called outside a task thread; it returns at once in the preview`)
		return nil
	end
	table.insert(self.Waiting, thread)
	session.waitingOn[thread] = `{self.Name or "signal"}:Wait()`
	local result = table.pack(coroutine.yield())
	session.waitingOn[thread] = nil
	return table.unpack(result, 1, result.n)
end

-- Handlers run in their own threads, like Roblox's deferred-free signals
function Signal:Fire(...)
	for _, connection in table.clone(self.Handlers) do
		if connection.Connected then
			spawnFunction(connection.Fn, ...)
		end
	end
	local waiting = self.Waiting
	self.Waiting = {}
	for _, thread in waiting do
		resumeThread(thread, ...)
	end
end

-- Events and missing methods on Lune's instances -------------------------------------

-- Lune instances have no events, so each one gets fake signals on first use.
-- They only fire when the preview fires them (clicks, Client.set, ...).
-- These tables hold their instances strongly on purpose: Lune hands out the
-- same Lua object for an instance only while one is still alive, so a weak
-- key would let a button lose its connections to the garbage collector.
-- Client.reset starts them over.
local instanceSignals = {}

local function signalOf(instance, name)
	local list = instanceSignals[instance]
	if not list then
		list = {}
		instanceSignals[instance] = list
	end
	local made = list[name]
	if not made then
		made = newSignal(name)
		list[name] = made
	end
	return made
end
Client.signalOf = signalOf

local EVENTS = {
	Instance = {
		"Changed",
		"ChildAdded",
		"ChildRemoved",
		"DescendantAdded",
		"DescendantRemoving",
		"AncestryChanged",
		"AttributeChanged",
		"Destroying",
	},
	GuiObject = {
		"MouseEnter",
		"MouseLeave",
		"MouseMoved",
		"MouseWheelForward",
		"MouseWheelBackward",
		"InputBegan",
		"InputChanged",
		"InputEnded",
		"TouchTap",
		"TouchLongPress",
		"TouchPan",
		"TouchPinch",
		"TouchRotate",
		"TouchSwipe",
		"SelectionGained",
		"SelectionLost",
	},
	GuiButton = {
		"Activated",
		"MouseButton1Click",
		"MouseButton1Down",
		"MouseButton1Up",
		"MouseButton2Click",
		"MouseButton2Down",
		"MouseButton2Up",
	},
	TextBox = { "FocusLost", "Focused", "ReturnPressedFromOnScreenKeyboard" },
	Humanoid = {
		"Died",
		"HealthChanged",
		"Running",
		"Jumping",
		"StateChanged",
		"MoveToFinished",
		"FreeFalling",
		"Seated",
		"Climbing",
	},
	BasePart = { "Touched", "TouchEnded" },
	Sound = { "Ended", "Played", "Loaded", "Paused", "Resumed", "Stopped" },
	BindableEvent = { "Event" },
	ProximityPrompt = {
		"Triggered",
		"TriggerEnded",
		"PromptShown",
		"PromptHidden",
		"PromptButtonHoldBegan",
		"PromptButtonHoldEnded",
	},
	ClickDetector = { "MouseClick", "MouseHoverEnter", "MouseHoverLeave", "RightMouseClick" },
	Animator = { "AnimationPlayed" },
	Tool = { "Activated", "Deactivated", "Equipped", "Unequipped" },
}
for className, names in EVENTS do
	for _, name in names do
		roblox.implementProperty(className, name, function(self)
			return signalOf(self, name)
		end)
	end
end

roblox.implementMethod("Instance", "GetPropertyChangedSignal", function(self, property)
	return signalOf(self, "Property:" .. tostring(property))
end)
roblox.implementMethod("Instance", "GetAttributeChangedSignal", function(self, attribute)
	return signalOf(self, "Attribute:" .. tostring(attribute))
end)

-- WaitForChild pauses the thread until the child shows up (checked every frame)
roblox.implementMethod("Instance", "WaitForChild", function(self, name, timeout)
	local child = self:FindFirstChild(name)
	if child then
		return child
	end
	local managed = inTaskThread()
	if not managed then
		error(
			`Infinite yield: {self:GetFullName()} has no child named "{name}" yet (and the preview can't wait outside a task thread)`,
			2
		)
	end
	local started = session.now
	local warned = false
	while true do
		wait(1 / 60, `{self:GetFullName()}:WaitForChild("{name}")`)
		child = self:FindFirstChild(name)
		if child then
			return child
		end
		if timeout and session.now - started >= timeout then
			return nil
		end
		if not warned and session.now - started >= 5 then
			warned = true
			print(`     [warn] Infinite yield possible on {self:GetFullName()}:WaitForChild("{name}")`)
		end
	end
end)

roblox.implementMethod("Instance", "FindFirstAncestor", function(self, name)
	local node = self.Parent
	while node do
		if node.Name == name then
			return node
		end
		node = node.Parent
	end
	return nil
end)
roblox.implementMethod("Instance", "GetActor", function()
	return nil
end)

local function noop() end
for _, method in { "Play", "Stop", "Pause", "Resume" } do
	roblox.implementMethod("Sound", method, noop)
end
roblox.implementMethod("SoundService", "PlayLocalSound", noop)
roblox.implementMethod("BindableEvent", "Fire", function(self, ...)
	signalOf(self, "Event"):Fire(...)
end)
local bindableCallbacks = {}
roblox.implementProperty("BindableFunction", "OnInvoke", function(self)
	return bindableCallbacks[self]
end, function(self, fn)
	bindableCallbacks[self] = fn
end)
roblox.implementMethod("BindableFunction", "Invoke", function(self, ...)
	local fn = bindableCallbacks[self]
	if fn then
		return fn(...)
	end
	return nil
end)

-- Humanoid and animation stand-ins
local function fakeTrack()
	local track = {
		IsPlaying = false,
		Length = 1,
		Speed = 1,
		TimePosition = 0,
		Looped = false,
		Priority = Enum.AnimationPriority.Action,
	}
	track.Stopped = newSignal("Stopped")
	track.Ended = newSignal("Ended")
	track.DidLoop = newSignal("DidLoop")
	track.KeyframeReached = newSignal("KeyframeReached")
	function track.Play()
		track.IsPlaying = true
	end
	function track.Stop()
		track.IsPlaying = false
	end
	track.AdjustSpeed = noop
	track.AdjustWeight = noop
	track.GetMarkerReachedSignal = function()
		return newSignal("Marker")
	end
	track.Destroy = noop
	return track
end
roblox.implementMethod("Humanoid", "LoadAnimation", fakeTrack)
roblox.implementMethod("Animator", "LoadAnimation", fakeTrack)
roblox.implementMethod("Animator", "GetPlayingAnimationTracks", function()
	return {}
end)
roblox.implementMethod("Humanoid", "GetPlayingAnimationTracks", function()
	return {}
end)
roblox.implementMethod("Humanoid", "TakeDamage", function(self, amount)
	self.Health = math.max(0, self.Health - amount)
end)
for _, method in
	{
		"MoveTo",
		"Move",
		"EquipTool",
		"UnequipTools",
		"ApplyDescription",
		"BuildRigFromAttachments",
		"SetStateEnabled",
		"ChangeState",
	}
do
	roblox.implementMethod("Humanoid", method, noop)
end
roblox.implementMethod("Humanoid", "GetState", function()
	return Enum.HumanoidStateType.Running
end)
roblox.implementMethod("Humanoid", "GetStateEnabled", function()
	return true
end)

for _, className in { "BasePart", "Part", "MeshPart", "WedgePart" } do
	roblox.implementMethod(className, "GetTouchingParts", function()
		return {}
	end)
	roblox.implementMethod(className, "ApplyImpulse", noop)
	roblox.implementMethod(className, "ApplyAngularImpulse", noop)
	roblox.implementMethod(className, "SetNetworkOwner", noop)
	roblox.implementMethod(className, "GetNetworkOwner", function()
		return nil
	end)
end

-- Old GuiObject tween helpers: jump to the end, like TweenService here
roblox.implementMethod("GuiObject", "TweenPosition", function(self, position)
	self.Position = position
	return true
end)
roblox.implementMethod("GuiObject", "TweenSize", function(self, size)
	self.Size = size
	return true
end)
roblox.implementMethod("GuiObject", "TweenSizeAndPosition", function(self, size, position)
	self.Size = size
	self.Position = position
	return true
end)
local focusedBox = nil
roblox.implementMethod("TextBox", "CaptureFocus", function(self)
	focusedBox = self
	signalOf(self, "Focused"):Fire()
end)
roblox.implementMethod("TextBox", "ReleaseFocus", function(self, submitted)
	if focusedBox == self then
		focusedBox = nil
	end
	signalOf(self, "FocusLost"):Fire(submitted == true)
end)
roblox.implementMethod("TextBox", "IsFocused", function(self)
	return focusedBox == self
end)
roblox.implementMethod("BasePlayerGui", "GetGuiObjectsAtPosition", function()
	return {}
end)
roblox.implementMethod("LayerCollector", "GetLayoutNodeTree", function()
	return nil
end)

-- The workspace and camera
roblox.implementMethod("Workspace", "GetServerTimeNow", function()
	return EPOCH + session.now
end)
for _, method in
	{
		"Raycast",
		"Blockcast",
		"Spherecast",
		"Shapecast",
		"FindPartOnRay",
		"FindPartOnRayWithIgnoreList",
		"FindPartOnRayWithWhitelist",
	}
do
	roblox.implementMethod("Workspace", method, function()
		return nil
	end)
end
for _, method in
	{
		"GetPartBoundsInBox",
		"GetPartBoundsInRadius",
		"GetPartsInPart",
		"FindPartsInRegion3",
		"FindPartsInRegion3WithIgnoreList",
	}
do
	roblox.implementMethod("Workspace", method, function()
		return {}
	end)
end
roblox.implementMethod("Workspace", "GetRealPhysicsFPS", function()
	return 60
end)
roblox.implementMethod("Workspace", "BulkMoveTo", function(_, parts, cframes)
	for index, part in parts do
		part.CFrame = cframes[index]
	end
end)
roblox.implementMethod("Workspace", "ArePartsTouchingOthers", function()
	return false
end)

-- Camera projection, so ESP-style code gets real-ish numbers
local function project(camera, position, withInset)
	local viewport = camera.ViewportSize
	local relative = camera.CFrame:PointToObjectSpace(position)
	local depth = -relative.Z
	local tanHalf = math.tan(math.rad(camera.FieldOfView) / 2)
	local aspect = viewport.X / viewport.Y
	local safeDepth = if math.abs(depth) < 1e-4 then 1e-4 else depth
	local x = (relative.X / (safeDepth * tanHalf * aspect) + 1) / 2 * viewport.X
	local y = (1 - relative.Y / (safeDepth * tanHalf)) / 2 * viewport.Y
	if withInset then
		y -= session.inset
	end
	local onScreen = depth > 0 and x >= 0 and x <= viewport.X and y >= 0 and y <= viewport.Y
	return Vector3.new(x, y, depth), onScreen
end
roblox.implementMethod("Camera", "WorldToViewportPoint", function(self, position)
	return project(self, position, false)
end)
roblox.implementMethod("Camera", "WorldToScreenPoint", function(self, position)
	return project(self, position, true)
end)
local function pointToRay(camera, x, y, depth)
	local viewport = camera.ViewportSize
	local tanHalf = math.tan(math.rad(camera.FieldOfView) / 2)
	local aspect = viewport.X / viewport.Y
	local dx = (x / viewport.X * 2 - 1) * tanHalf * aspect
	local dy = (1 - y / viewport.Y * 2) * tanHalf
	local direction = camera.CFrame:VectorToWorldSpace(Vector3.new(dx, dy, -1).Unit)
	return roblox.Ray.new(camera.CFrame.Position, direction * (depth or 1))
end
roblox.implementMethod("Camera", "ViewportPointToRay", function(self, x, y, depth)
	return pointToRay(self, x, y, depth)
end)
roblox.implementMethod("Camera", "ScreenPointToRay", function(self, x, y, depth)
	return pointToRay(self, x, y + session.inset, depth)
end)
roblox.implementMethod("Camera", "GetPartsObscuringTarget", function()
	return {}
end)

roblox.implementMethod("Lighting", "GetMinutesAfterMidnight", function(self)
	return self.ClockTime * 60
end)
roblox.implementMethod("Lighting", "SetMinutesAfterMidnight", function(self, minutes)
	self.ClockTime = minutes / 60
end)
roblox.implementMethod("Lighting", "GetSunDirection", function()
	return Vector3.new(0.4, 0.8, 0.4).Unit
end)

-- Properties Lune can't read until they're set get Roblox's defaults when made
local SEEDS = {
	GuiBase2d = { AbsoluteSize = Vector2.zero, AbsolutePosition = Vector2.zero, AbsoluteRotation = 0 },
	TextLabel = { TextBounds = Vector2.zero, TextFits = true },
	TextButton = { TextBounds = Vector2.zero, TextFits = true },
	ImageLabel = { Image = "" },
	ImageButton = { Image = "" },
	ScrollingFrame = { AbsoluteCanvasSize = Vector2.zero, AbsoluteWindowSize = Vector2.zero },
	UIGridStyleLayout = { AbsoluteContentSize = Vector2.zero },
	UIGridLayout = { AbsoluteCellSize = Vector2.zero, AbsoluteCellCount = Vector2.zero },
	TextBox = { TextBounds = Vector2.zero, TextFits = true, ContentText = "", LocalizedText = "" },
	UICorner = { CornerRadius = roblox.UDim.new(0, 8) },
	ScreenGui = { IgnoreGuiInset = false },
	Humanoid = {
		Health = 100,
		MaxHealth = 100,
		WalkSpeed = 16,
		JumpPower = 50,
		JumpHeight = 7.2,
		HipHeight = 2,
		MoveDirection = Vector3.zero,
		FloorMaterial = Enum.Material.Plastic,
		Jump = false,
		PlatformStand = false,
		Sit = false,
		CameraOffset = Vector3.zero,
		WalkToPoint = Vector3.zero,
	},
	BasePart = {
		Position = Vector3.zero,
		Orientation = Vector3.zero,
		AssemblyLinearVelocity = Vector3.zero,
		AssemblyAngularVelocity = Vector3.zero,
		Mass = 1,
		AssemblyMass = 1,
		LocalTransparencyModifier = 0,
	},
	Attachment = { Position = Vector3.zero, WorldPosition = Vector3.zero, WorldCFrame = CFrame.new() },
	Model = { WorldPivot = CFrame.new() },
	Camera = { NearPlaneZ = -0.1 },
	Lighting = { ClockTime = 14 },
	Sound = { IsPlaying = false, TimeLength = 1, IsLoaded = true, SoundId = "" },
}
SEEDS.TextLabel.ContentText = ""
SEEDS.TextLabel.LocalizedText = ""
SEEDS.TextButton.ContentText = ""
SEEDS.TextButton.LocalizedText = ""
local function seed(instance)
	for className, values in SEEDS do
		if instance:IsA(className) then
			for key, value in values do
				local ok = pcall(function()
					return instance[key]
				end)
				if not ok then
					pcall(function()
						instance[key] = value
					end)
				end
			end
		end
	end
	return instance
end
Client.seed = seed

-- Lune keeps a part's Position apart from its CFrame, and can't read it until
-- it's set; each frame copies one into the other (whichever code changed)
local placed = {}
local function syncParts(root)
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") then
			local ok, position = pcall(function()
				return item.Position
			end)
			local written = placed[item]
			if ok and written and position ~= written then
				item.CFrame = item.CFrame.Rotation + position
			end
			local current = item.CFrame.Position
			item.Position = current
			placed[item] = current
		end
	end
end

local function newInstance(className, parent)
	local instance = seed(Instance.new(className))
	if instance:IsA("BasePart") then
		placed[instance] = Vector3.zero
	end
	if parent ~= nil then
		instance.Parent = parent
	end
	return instance
end

-- Source folders ----------------------------------------------------------------------

-- A node stands for a folder, ModuleScript or LocalScript made from one or more
-- directories laid over each other (later ones win). Everything is read at
-- start-up: Lune's file calls can't run inside the metamethods used later.
local nodeMeta = {}
local makeNode

local function sourceName(entry)
	if entry:match("%.server%.luau$") or entry:match("%.server%.lua$") then
		return nil
	end
	local base = entry:match("^(.+)%.client%.luau$") or entry:match("^(.+)%.client%.lua$")
	if base then
		return base, "LocalScript"
	end
	base = entry:match("^(.+)%.luau$") or entry:match("^(.+)%.lua$")
	if base then
		return base, "ModuleScript"
	end
	return nil
end

local function scanChildren(node)
	local list = {}
	for _, dir in node.Dirs do
		if fs.isDir(dir) then
			for _, entry in fs.readDir(dir) do
				local full = dir .. "/" .. entry
				if fs.isDir(full) then
					local existing = list[entry]
					local dirs = if existing then existing.Dirs else {}
					table.insert(dirs, full)
					list[entry] = { Dirs = dirs, File = existing and existing.File, Kind = existing and existing.Kind }
				else
					local name, kind = sourceName(entry)
					if name and name ~= "init" then
						local existing = list[name]
						list[name] = { Dirs = if existing then existing.Dirs else {}, File = full, Kind = kind }
					end
				end
			end
		end
	end
	local made = {}
	for name, info in list do
		made[name] = makeNode(name, node, info.Dirs, info.File, info.Kind)
	end
	return made
end

function makeNode(name, parent, dirs, file, kind)
	local node = { Name = name, ParentNode = parent, Dirs = dirs, File = file, Kind = kind }
	if not file then
		for _, dir in dirs do
			for _, init in { "init.luau", "init.lua", "init.client.luau" } do
				if fs.isFile(dir .. "/" .. init) then
					node.File = dir .. "/" .. init
					node.Kind = if init == "init.client.luau" then "LocalScript" else "ModuleScript"
				end
			end
		end
	end
	if node.File then
		node.Source = fs.readFile(node.File)
	end
	node.Children = if #dirs > 0 then scanChildren(node) else {}
	return setmetatable(node, nodeMeta)
end

local function className(node)
	return rawget(node, "ClassOverride") or rawget(node, "Kind") or "Folder"
end

local NODE_METHODS = {
	WaitForChild = function(self, name)
		local child = rawget(self, "Children")[name]
		if not child then
			error(`Infinite yield: {self:GetFullName()} has no child named "{name}"`, 2)
		end
		return child
	end,
	FindFirstChild = function(self, name)
		return rawget(self, "Children")[name]
	end,
	GetChildren = function(self)
		local list = {}
		for _, child in rawget(self, "Children") do
			table.insert(list, child)
		end
		table.sort(list, function(a, b)
			return a.Name < b.Name
		end)
		return list
	end,
	GetDescendants = function(self)
		local list = {}
		local function walk(node)
			for _, child in rawget(node, "Children") do
				table.insert(list, child)
				walk(child)
			end
		end
		walk(self)
		return list
	end,
	IsA = function(self, name)
		local own = className(self)
		return name == own
			or name == "Instance"
			or (name == "LuaSourceContainer" and own ~= "Folder")
			or (name == "BaseScript" and own == "LocalScript")
	end,
	GetFullName = function(self)
		local names = {}
		local node = self
		while node do
			table.insert(names, 1, rawget(node, "Name"))
			node = rawget(node, "ParentNode")
		end
		return table.concat(names, ".")
	end,
	IsDescendantOf = function(self, other)
		local node = rawget(self, "ParentNode")
		while node do
			if node == other then
				return true
			end
			node = rawget(node, "ParentNode")
		end
		return false
	end,
	GetAttribute = function()
		return nil
	end,
	GetAttributes = function()
		return {}
	end,
	FindFirstChildOfClass = function(self, name)
		for _, child in rawget(self, "Children") do
			if className(child) == name then
				return child
			end
		end
		return nil
	end,
	GetPropertyChangedSignal = function(self, name)
		return newSignal(name)
	end,
	GetAttributeChangedSignal = function(self, name)
		return newSignal(name)
	end,
}
NODE_METHODS.FindFirstChildWhichIsA = NODE_METHODS.FindFirstChildOfClass

nodeMeta.__index = function(self, key)
	if key == "Parent" then
		return rawget(self, "ParentNode")
	elseif key == "ClassName" then
		return className(self)
	elseif NODE_METHODS[key] then
		return NODE_METHODS[key]
	elseif key == "ChildAdded" or key == "ChildRemoved" or key == "DescendantAdded" or key == "Changed" then
		return newSignal(key)
	end
	local child = rawget(self, "Children")[key]
	if child then
		return child
	end
	error(`{key} is not a valid member of {className(self)} "{self:GetFullName()}"`, 2)
end
nodeMeta.__tostring = function(self)
	return rawget(self, "Name")
end

local function overlay(folder)
	local dirs = { GAME_SRC .. "/" .. folder }
	for _, root in MODEL_SRCS do
		if root ~= "" then
			table.insert(dirs, root .. "/" .. folder)
		end
	end
	return dirs
end

local function folderNode(name, parent, children)
	local node = setmetatable({ Name = name, ParentNode = parent, Dirs = {}, Children = {} }, nodeMeta)
	for childName, child in children or {} do
		node.Children[childName] = child
		rawset(child, "ParentNode", node)
	end
	return node
end

-- Built once; module results are cached per session
local sharedNode = makeNode("Shared", nil, overlay("shared"))
local clientNode = makeNode("Client", nil, overlay("client"))
local remotesNode = folderNode("Remotes", nil)
local replicatedStorageNode = folderNode("ReplicatedStorage", nil, { Shared = sharedNode, Remotes = remotesNode })
local playerScriptsNode = folderNode("StarterPlayerScripts", nil, { Client = clientNode })
local starterPlayerNode = folderNode("StarterPlayer", nil, {
	StarterPlayerScripts = playerScriptsNode,
	StarterCharacterScripts = folderNode("StarterCharacterScripts", nil),
})
rawset(replicatedStorageNode, "ClassOverride", "ReplicatedStorage")
rawset(starterPlayerNode, "ClassOverride", "StarterPlayer")

-- Remotes: any name works; RemoteFunctions answer with Client.onInvoke handlers
local function makeRemote(name)
	local kind = if REMOTE_FUNCTIONS[name] then "RemoteFunction" else "RemoteEvent"
	local remote = { Name = name, ClassName = kind, Parent = remotesNode }
	remote.OnClientEvent = newSignal(name .. ".OnClientEvent")
	remote.OnServerEvent = newSignal(name .. ".OnServerEvent")
	function remote.FireServer(_, ...)
		table.insert(session.sent, { Remote = name, Args = table.pack(...) })
	end
	function remote.InvokeServer(_, ...)
		table.insert(session.sent, { Remote = name, Args = table.pack(...) })
		local handler = session.invokeHandlers[name]
		if handler then
			return handler(...)
		end
		return nil
	end
	function remote.IsA(_, other)
		return other == kind or other == "Instance"
	end
	function remote.GetFullName()
		return "ReplicatedStorage.Remotes." .. name
	end
	remote.GetAttribute = function()
		return nil
	end
	remote.Destroy = noop
	return remote
end

local function remoteNamed(name)
	local made = session.remotes[name]
	if not made then
		made = makeRemote(name)
		session.remotes[name] = made
	end
	return made
end

setmetatable(rawget(remotesNode, "Children"), {
	__index = function(_, name)
		if type(name) == "string" and session then
			return remoteNamed(name)
		end
		return nil
	end,
})

-- Fake services ----------------------------------------------------------------------

local function stubService(name)
	return setmetatable({ Name = name, ClassName = name }, {
		__index = function(self, key)
			if
				type(key) == "string"
				and key:match("^[A-Z]")
				and (
					key:find("Added")
					or key:find("Removing")
					or key:find("Changed")
					or key:find("Finished")
					or key:find("Ended")
					or key:find("Began")
					or key:find("Event")
				)
			then
				local made = newSignal(name .. "." .. key)
				rawset(self, key, made)
				return made
			end
			return function()
				return nil
			end
		end,
	})
end

local function makeRunService()
	local service = {
		Name = "RunService",
		ClassName = "RunService",
		RenderStepped = newSignal("RenderStepped"),
		Heartbeat = newSignal("Heartbeat"),
		Stepped = newSignal("Stepped"),
		PreRender = newSignal("PreRender"),
		PreAnimation = newSignal("PreAnimation"),
		PreSimulation = newSignal("PreSimulation"),
		PostSimulation = newSignal("PostSimulation"),
		Bound = {},
	}
	function service.IsClient()
		return true
	end
	function service.IsServer()
		return false
	end
	function service.IsStudio()
		return true
	end
	function service.IsRunning()
		return true
	end
	function service.IsRunMode()
		return false
	end
	function service.IsEdit()
		return false
	end
	function service.BindToRenderStep(_, name, priority, fn)
		service.Bound[name] = { Priority = priority, Fn = fn }
	end
	function service.UnbindFromRenderStep(_, name)
		service.Bound[name] = nil
	end
	return service
end

local function makeInputService(touch)
	local service = {
		Name = "UserInputService",
		ClassName = "UserInputService",
		TouchEnabled = touch,
		KeyboardEnabled = not touch,
		MouseEnabled = not touch,
		GamepadEnabled = false,
		AccelerometerEnabled = false,
		GyroscopeEnabled = false,
		VREnabled = false,
		MouseIconEnabled = true,
		MouseIcon = "",
		MouseBehavior = Enum.MouseBehavior.Default,
		MouseDeltaSensitivity = 1,
		ModalEnabled = false,
		OnScreenKeyboardVisible = false,
	}
	for _, name in
		{
			"InputBegan",
			"InputEnded",
			"InputChanged",
			"JumpRequest",
			"TouchStarted",
			"TouchEnded",
			"TouchMoved",
			"TouchTap",
			"TouchLongPress",
			"TouchPan",
			"TouchPinch",
			"TouchSwipe",
			"TouchRotate",
			"LastInputTypeChanged",
			"WindowFocused",
			"WindowFocusReleased",
			"GamepadConnected",
			"GamepadDisconnected",
			"TextBoxFocused",
			"TextBoxFocusReleased",
			"PointerAction",
		}
	do
		service[name] = newSignal("UserInputService." .. name)
	end
	function service.GetMouseLocation()
		local size = session.camera.ViewportSize
		return Vector2.new(size.X / 2, size.Y / 2)
	end
	function service.GetMouseDelta()
		return Vector2.zero
	end
	function service.IsKeyDown()
		return false
	end
	function service.IsMouseButtonPressed()
		return false
	end
	function service.IsGamepadButtonDown()
		return false
	end
	function service.GetKeysPressed()
		return {}
	end
	function service.GetMouseButtonsPressed()
		return {}
	end
	function service.GetFocusedTextBox()
		return focusedBox
	end
	function service.GetLastInputType()
		return if touch then Enum.UserInputType.Touch else Enum.UserInputType.MouseMovement
	end
	function service.GetConnectedGamepads()
		return {}
	end
	function service.GetNavigationGamepads()
		return {}
	end
	function service.GetGamepadConnected()
		return false
	end
	function service.GetStringForKeyCode(_, keyCode)
		return keyCode.Name
	end
	function service.GetImageForKeyCode()
		return ""
	end
	function service.GetDeviceRotation()
		return CFrame.new()
	end
	return service
end

local function makeTweenService()
	local service = { Name = "TweenService", ClassName = "TweenService" }
	function service.Create(_, instance, info, goals)
		local tween = { Instance = instance, TweenInfo = info, PlaybackState = Enum.PlaybackState.Begin }
		tween.Completed = newSignal("Tween.Completed")
		function tween.Play()
			-- Straight to the end, so the picture shows where it lands
			for key, value in goals do
				local ok, err = pcall(function()
					instance[key] = value
				end)
				if not ok then
					report(`TweenService: can't set {key}: {err}`)
				end
			end
			tween.PlaybackState = Enum.PlaybackState.Completed
			local time = (info and info.Time or 1) + (info and info.DelayTime or 0)
			local repeats = info and info.RepeatCount or 0
			if repeats >= 0 then
				taskLib.delay(time * (repeats + 1) * (if info and info.Reverses then 2 else 1), function()
					tween.Completed:Fire(Enum.PlaybackState.Completed)
				end)
			end
		end
		function tween.Pause()
			tween.PlaybackState = Enum.PlaybackState.Paused
		end
		function tween.Cancel()
			tween.PlaybackState = Enum.PlaybackState.Cancelled
		end
		tween.Destroy = noop
		return tween
	end
	function service.GetValue(_, alpha)
		return alpha
	end
	function service.SmoothDamp(_, current, target)
		return target, current * 0
	end
	return service
end

local TweenInfo = {
	new = function(time, style, direction, repeatCount, reverses, delayTime)
		return {
			Time = time or 1,
			EasingStyle = style or Enum.EasingStyle.Quad,
			EasingDirection = direction or Enum.EasingDirection.Out,
			RepeatCount = repeatCount or 0,
			Reverses = reverses or false,
			DelayTime = delayTime or 0,
		}
	end,
}

local function makeStarterGui()
	local enabled = {}
	local service =
		{ Name = "StarterGui", ClassName = "StarterGui", ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor }
	-- CoreGuiType.All switches every type at once
	function service.SetCoreGuiEnabled(_, coreType, on)
		if coreType == Enum.CoreGuiType.All then
			table.clear(enabled)
		end
		enabled[coreType] = on == true
	end
	function service.GetCoreGuiEnabled(_, coreType)
		if enabled[coreType] ~= nil then
			return enabled[coreType]
		end
		return enabled[Enum.CoreGuiType.All] ~= false
	end
	service.SetCore = noop
	function service.GetCore()
		return nil
	end
	service.RegisterGetCore = noop
	service.RegisterSetCore = noop
	return service
end

local function makeGuiService()
	local service = {
		Name = "GuiService",
		ClassName = "GuiService",
		SelectedObject = nil,
		AutoSelectGuiEnabled = true,
		GuiNavigationEnabled = false,
		MenuIsOpen = false,
		TouchControlsEnabled = true,
		TopbarInset = roblox.Rect.new(0, 0, 0, 0),
		MenuOpened = newSignal("MenuOpened"),
		MenuClosed = newSignal("MenuClosed"),
	}
	function service.GetGuiInset()
		return Vector2.new(0, session.inset), Vector2.zero
	end
	function service.IsTenFootInterface()
		return false
	end
	service.AddSelectionParent = noop
	service.RemoveSelectionGroup = noop
	service.Select = noop
	service.CloseInspectMenu = noop
	return service
end

local function makeContextActionService()
	local service = { Name = "ContextActionService", ClassName = "ContextActionService", Bound = {} }
	function service.BindAction(_, name, fn, createButton, ...)
		service.Bound[name] = { Fn = fn, Inputs = { ... } }
	end
	function service.BindActionAtPriority(_, name, fn, createButton, priority, ...)
		service.Bound[name] = { Fn = fn, Inputs = { ... } }
	end
	function service.UnbindAction(_, name)
		service.Bound[name] = nil
	end
	service.UnbindAllActions = function()
		table.clear(service.Bound)
	end
	for _, name in { "SetTitle", "SetImage", "SetPosition", "SetDescription" } do
		service[name] = noop
	end
	function service.GetButton()
		return nil
	end
	function service.GetAllBoundActionInfo()
		return {}
	end
	service.LocalToolEquipped = newSignal("LocalToolEquipped")
	service.LocalToolUnequipped = newSignal("LocalToolUnequipped")
	return service
end

local function makeMarketplaceService()
	local service = { Name = "MarketplaceService", ClassName = "MarketplaceService" }
	for _, name in
		{
			"PromptGamePassPurchase",
			"PromptProductPurchase",
			"PromptPurchase",
			"PromptPremiumPurchase",
			"PromptSubscriptionPurchase",
			"PromptBundlePurchase",
		}
	do
		service[name] = function(_, ...)
			table.insert(session.sent, { Remote = "MarketplaceService." .. name, Args = table.pack(...) })
		end
	end
	for _, name in
		{
			"PromptGamePassPurchaseFinished",
			"PromptProductPurchaseFinished",
			"PromptPurchaseFinished",
			"PromptPremiumPurchaseFinished",
			"PromptBundlePurchaseFinished",
		}
	do
		service[name] = newSignal(name)
	end
	function service.UserOwnsGamePassAsync()
		return false
	end
	function service.PlayerOwnsAsset()
		return false
	end
	function service.GetProductInfo(_, id)
		return {
			Name = "Product " .. tostring(id),
			Description = "",
			PriceInRobux = 99,
			IconImageAssetId = 0,
			IsForSale = true,
		}
	end
	return service
end

local function makeTextService()
	local service = { Name = "TextService", ClassName = "TextService" }
	-- A rough width: about 0.56 of the text size per character
	function service.GetTextSize(_, text, size, _, frameSize)
		local width = utf8.len(text) or #text
		local w = width * size * 0.56
		local lines = 1
		if frameSize and frameSize.X > 0 and w > frameSize.X then
			lines = math.ceil(w / frameSize.X)
			w = frameSize.X
		end
		return Vector2.new(w, lines * size)
	end
	function service.GetTextBoundsAsync(_, params)
		return service.GetTextSize(nil, params.Text or "", params.Size or 14, nil, Vector2.new(params.Width or 0, 0))
	end
	function service.FilterStringAsync(_, text)
		return {
			GetNonChatStringForBroadcastAsync = function()
				return text
			end,
			GetNonChatStringForUserAsync = function()
				return text
			end,
			GetChatForUserAsync = function()
				return text
			end,
		}
	end
	return service
end

local function makeHttpService()
	local service = { Name = "HttpService", ClassName = "HttpService", HttpEnabled = false }
	function service.JSONEncode(_, value)
		return serde.encode("json", value)
	end
	function service.JSONDecode(_, text)
		return serde.decode("json", text)
	end
	local count = 0
	function service.GenerateGUID(_, braces)
		count += 1
		local id = string.format("00000000-0000-4000-8000-%012d", count)
		return if braces == false then id else "{" .. id .. "}"
	end
	return service
end

local function makeCollectionService()
	local service = { Name = "CollectionService", ClassName = "CollectionService" }
	function service.AddTag(_, instance, tag)
		instance:AddTag(tag)
	end
	function service.RemoveTag(_, instance, tag)
		instance:RemoveTag(tag)
	end
	function service.HasTag(_, instance, tag)
		return instance:HasTag(tag)
	end
	function service.GetTags(_, instance)
		return instance:GetTags()
	end
	function service.GetTagged(_, tag)
		local list = {}
		for _, root in { session.workspace, session.lighting, session.playerGui } do
			for _, item in root:GetDescendants() do
				if item:HasTag(tag) then
					table.insert(list, item)
				end
			end
		end
		return list
	end
	function service.GetInstanceAddedSignal(_, tag)
		return newSignal("Tagged:" .. tag)
	end
	function service.GetInstanceRemovedSignal(_, tag)
		return newSignal("Untagged:" .. tag)
	end
	return service
end

local function makeDebris()
	local service = { Name = "Debris", ClassName = "Debris" }
	function service.AddItem(_, item, lifetime)
		taskLib.delay(lifetime or 10, function()
			pcall(function()
				item:Destroy()
			end)
		end)
	end
	return service
end

-- The local player ------------------------------------------------------------------------

local PLAYER_EVENTS = {
	"CharacterAdded",
	"CharacterRemoving",
	"CharacterAppearanceLoaded",
	"AttributeChanged",
	"Changed",
	"Chatted",
	"Idled",
	"OnTeleport",
	"ChildAdded",
	"ChildRemoved",
}

local function makeMouse()
	local mouse = {
		ClassName = "Mouse",
		Hit = CFrame.new(0, 0, -100),
		Origin = CFrame.new(),
		Target = nil,
		TargetFilter = nil,
		Icon = "",
		UnitRay = roblox.Ray.new(Vector3.zero, Vector3.new(0, 0, -1)),
	}
	for _, name in
		{ "Button1Down", "Button1Up", "Button2Down", "Button2Up", "Move", "Idle", "WheelForward", "WheelBackward" }
	do
		mouse[name] = newSignal("Mouse." .. name)
	end
	return setmetatable(mouse, {
		__index = function(_, key)
			local size = session.camera.ViewportSize
			if key == "X" then
				return size.X / 2
			elseif key == "Y" then
				return size.Y / 2 - session.inset
			elseif key == "ViewSizeX" then
				return size.X
			elseif key == "ViewSizeY" then
				return size.Y
			end
			return nil
		end,
	})
end

local function makePlayer(playersService, options)
	-- Children (PlayerGui, leaderstats, ...) live in a real folder so ScreenGuis can be parented
	local holder = Instance.new("Folder")
	holder.Name = options.Name
	local playerGui = Instance.new("PlayerGui")
	playerGui.Name = "PlayerGui"
	playerGui.Parent = holder
	for _, name in { "Backpack", "PlayerScripts" } do
		local item = Instance.new("Folder")
		item.Name = name
		item.Parent = holder
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { "Credits", "Bans" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Value = 0
		value.Parent = leaderstats
	end
	leaderstats.Parent = holder

	local attributes = {}
	local props = {
		Name = options.Name,
		DisplayName = options.DisplayName or options.Name,
		UserId = options.UserId or 1,
		AccountAge = 400,
		Character = nil,
		CameraMode = Enum.CameraMode.Classic,
		CameraMinZoomDistance = 0.5,
		CameraMaxZoomDistance = 400,
		DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice,
		DevTouchMovementMode = Enum.DevTouchMovementMode.UserChoice,
		DevEnableMouseLock = true,
		AutoJumpEnabled = true,
		HealthDisplayDistance = 100,
		NameDisplayDistance = 100,
		Neutral = true,
		Team = nil,
		TeamColor = roblox.BrickColor.new("White"),
		MembershipType = Enum.MembershipType.None,
		LocaleId = "en-us",
		RespawnLocation = nil,
		ReplicationFocus = nil,
		GameplayPaused = false,
		Archivable = true,
	}
	local events = {}
	for _, name in PLAYER_EVENTS do
		events[name] = newSignal("Player." .. name)
	end
	local attributeSignals = {}
	local mouse = makeMouse()
	local player

	local methods = {}
	function methods.GetAttribute(_, name)
		return attributes[name]
	end
	function methods.GetAttributes()
		return table.clone(attributes)
	end
	function methods.SetAttribute(_, name, value)
		if attributes[name] == value then
			return
		end
		attributes[name] = value
		events.AttributeChanged:Fire(name)
		if attributeSignals[name] then
			attributeSignals[name]:Fire()
		end
	end
	function methods.GetAttributeChangedSignal(_, name)
		attributeSignals[name] = attributeSignals[name] or newSignal("Attribute:" .. name)
		return attributeSignals[name]
	end
	function methods.GetPropertyChangedSignal(_, name)
		return signalOf(holder, "Property:" .. name)
	end
	function methods.WaitForChild(_, name, timeout)
		return holder:WaitForChild(name, timeout)
	end
	for _, name in
		{
			"FindFirstChild",
			"FindFirstChildOfClass",
			"FindFirstChildWhichIsA",
			"GetChildren",
			"GetDescendants",
			"ClearAllChildren",
		}
	do
		methods[name] = function(_, ...)
			return holder[name](holder, ...)
		end
	end
	function methods.IsA(_, name)
		return name == "Player" or name == "Instance"
	end
	function methods.GetMouse()
		return mouse
	end
	function methods.GetNetworkPing()
		return 0.002
	end
	function methods.GetFullName()
		return "Players." .. props.Name
	end
	function methods.IsDescendantOf(_, other)
		return other == playersService
	end
	function methods.IsInGroup()
		return false
	end
	function methods.GetRankInGroup()
		return 0
	end
	function methods.GetRoleInGroup()
		return "Guest"
	end
	function methods.HasAppearanceLoaded()
		return true
	end
	function methods.GetJoinData()
		return {}
	end
	function methods.GetFriendsOnline()
		return {}
	end
	function methods.IsFriendsWith()
		return false
	end
	function methods.DistanceFromCharacter()
		return 0
	end
	function methods.Kick(_, message)
		report("LocalPlayer:Kick(" .. tostring(message) .. ")")
	end
	for _, name in
		{
			"LoadCharacter",
			"Move",
			"ClearCharacterAppearance",
			"RequestStreamAroundAsync",
			"SetSuperSafeChat",
			"Destroy",
		}
	do
		methods[name] = noop
	end

	player = setmetatable({}, {
		__index = function(_, key)
			if key == "ClassName" then
				return "Player"
			elseif key == "Parent" then
				return playersService
			elseif props[key] ~= nil then
				return props[key]
			elseif methods[key] then
				return methods[key]
			elseif events[key] then
				return events[key]
			end
			local child = holder:FindFirstChild(key)
			if child then
				return child
			end
			if key == "Character" or key == "Team" or key == "RespawnLocation" or key == "ReplicationFocus" then
				return nil
			end
			error(`{key} is not a valid member of Player "Players.{props.Name}"`, 2)
		end,
		__newindex = function(_, key, value)
			if methods[key] or events[key] then
				error(`can't set {key} on Player`, 2)
			end
			props[key] = value
			events.Changed:Fire(key)
			signalOf(holder, "Property:" .. key):Fire()
		end,
		__tostring = function()
			return props.Name
		end,
	})
	return player, holder, playerGui, leaderstats, attributes
end

local function makePlayersService(options)
	local service =
		{ Name = "Players", ClassName = "Players", MaxPlayers = 12, RespawnTime = 5, CharacterAutoLoads = true }
	service.PlayerAdded = newSignal("PlayerAdded")
	service.PlayerRemoving = newSignal("PlayerRemoving")
	local player, holder, playerGui, leaderstats, attributes = makePlayer(service, options)
	service.LocalPlayer = player
	function service.GetPlayers()
		return { player }
	end
	function service.GetPlayerByUserId(_, id)
		return if id == player.UserId then player else nil
	end
	function service.GetPlayerFromCharacter(_, model)
		return if model ~= nil and model == player.Character then player else nil
	end
	function service.GetNameFromUserIdAsync()
		return player.Name
	end
	function service.GetUserIdFromNameAsync()
		return player.UserId
	end
	function service.GetUserThumbnailAsync()
		return "rbxasset://textures/ui/GuiImagePlaceholder.png", true
	end
	function service.GetHumanoidDescriptionFromUserId()
		return Instance.new("HumanoidDescription")
	end
	function service.CreateHumanoidModelFromDescription(_, description)
		return World.makeRig(description)
	end
	function service.FindFirstChild(_, name)
		return if name == player.Name then player else nil
	end
	return service, player, holder, playerGui, leaderstats, attributes
end

-- Sessions ----------------------------------------------------------------------------

local SERVICE_MAKERS = {
	RunService = function()
		return session.runService
	end,
	UserInputService = function()
		return session.inputService
	end,
	TweenService = makeTweenService,
	StarterGui = makeStarterGui,
	GuiService = makeGuiService,
	ContextActionService = makeContextActionService,
	MarketplaceService = makeMarketplaceService,
	TextService = makeTextService,
	HttpService = makeHttpService,
	CollectionService = makeCollectionService,
	Debris = makeDebris,
}
-- Services that are real Lune instances (so things can be parented to them)
local REAL_SERVICES =
	{ Lighting = true, SoundService = true, ReplicatedFirst = true, Teams = true, MaterialService = true, Chat = true }

local function getService(name)
	local services = session.services
	if services[name] then
		return services[name]
	end
	local made
	if name == "Workspace" then
		made = session.workspace
	elseif name == "Players" then
		made = session.players
	elseif name == "ReplicatedStorage" then
		made = replicatedStorageNode
	elseif name == "StarterPlayer" then
		made = starterPlayerNode
	elseif SERVICE_MAKERS[name] then
		made = SERVICE_MAKERS[name]()
	elseif REAL_SERVICES[name] then
		local ok, service = pcall(function()
			return session.datamodel:GetService(name)
		end)
		made = if ok then service else stubService(name)
	else
		made = stubService(name)
	end
	services[name] = made
	return made
end
Client.getService = function(name)
	return getService(name)
end

local function makeGame()
	return setmetatable(
		{
			Name = "Game",
			ClassName = "DataModel",
			PlaceId = 0,
			GameId = 0,
			JobId = "preview",
			CreatorId = 0,
			PlaceVersion = 1,
		},
		{
			__index = function(self, key)
				if key == "GetService" or key == "FindService" then
					return function(_, name)
						return getService(name)
					end
				elseif key == "Workspace" or key == "workspace" then
					return session.workspace
				elseif key == "IsLoaded" then
					return function()
						return true
					end
				elseif key == "Loaded" or key == "Close" then
					return newSignal(key)
				elseif key == "BindToClose" then
					return noop
				elseif key == "GetPropertyChangedSignal" then
					return function(_, name)
						return newSignal(name)
					end
				elseif key == "IsA" then
					return function(_, name)
						return name == "DataModel" or name == "Instance"
					end
				elseif key == "FindFirstChild" or key == "WaitForChild" then
					return function(_, name)
						return getService(name)
					end
				elseif
					type(key) == "string"
					and (
						key:match("Service$")
						or key == "Lighting"
						or key == "Players"
						or key == "ReplicatedStorage"
						or key == "StarterGui"
						or key == "StarterPlayer"
					)
				then
					return getService(key)
				end
				error(`{key} is not a valid member of DataModel "Game"`, 2)
			end,
		}
	)
end

local DEFAULTS = { Viewport = { 1280, 720 }, Inset = 58, Touch = false, PlayerName = "Player1" }

-- Starts a fresh client: new player, PlayerGui, camera, clock and module cache.
-- options: Viewport = { w, h }, Inset = 58 (the topbar height), Touch = true for
-- a phone, PlayerName, DisplayName.
function Client.reset(options)
	options = options or {}
	local viewport = options.Viewport or DEFAULTS.Viewport
	session = {
		now = 0,
		seq = 0,
		queue = {},
		managed = setmetatable({}, { __mode = "k" }),
		waitingOn = setmetatable({}, { __mode = "k" }),
		errors = {},
		errorSeen = {},
		moduleCache = {},
		services = {},
		remotes = {},
		invokeHandlers = {},
		sent = {},
		inset = options.Inset or DEFAULTS.Inset,
		shared = {},
		G = {},
	}
	focusedBox = nil
	table.clear(instanceSignals)
	table.clear(bindableCallbacks)
	table.clear(placed)
	session.datamodel = Instance.new("DataModel")
	session.workspace = session.datamodel:GetService("Workspace")
	session.lighting = session.datamodel:GetService("Lighting")
	local camera = Instance.new("Camera")
	camera.Name = "Camera"
	camera.FieldOfView = 70
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 20), Vector3.new(0, 5, 0))
	camera.ViewportSize = Vector2.new(viewport[1], viewport[2])
	camera.Parent = session.workspace
	session.workspace.CurrentCamera = camera
	session.camera = camera
	local arenas = Instance.new("Folder")
	arenas.Name = "Arenas"
	arenas.Parent = session.workspace

	session.runService = makeRunService()
	session.inputService = makeInputService(options.Touch == true)
	local players, player, holder, playerGui, leaderstats, attributes = makePlayersService({
		Name = options.PlayerName or DEFAULTS.PlayerName,
		DisplayName = options.DisplayName,
		UserId = options.UserId,
	})
	session.players = players
	session.player = player
	session.playerHolder = holder
	session.playerGui = playerGui
	session.leaderstats = leaderstats
	session.attributes = attributes
	session.game = makeGame()

	-- What the server gives a brand-new player
	attributes.Bans = 0
	attributes.Kills = 0

	Client.player = player
	Client.playerGui = playerGui
	Client.camera = camera
	Client.workspace = session.workspace
	Client.game = session.game
	Client.lighting = session.lighting
	Client.UserInputService = session.inputService
	Client.RunService = session.runService
	return Client
end

-- Loading modules -------------------------------------------------------------------------

local requireNode
local makeEnvironment

local function osTable()
	local fake = table.clone(os)
	fake.clock = function()
		return session.now
	end
	fake.time = function(date)
		if date then
			return os.time(date)
		end
		return math.floor(EPOCH + session.now)
	end
	return fake
end

local function randomClass()
	return {
		new = function(seedValue)
			local state = math.floor(tonumber(seedValue) or 7) % 2147483647
			if state <= 0 then
				state = 7
			end
			local rng = {}
			local function nextFloat()
				state = (state * 16807) % 2147483647
				return state / 2147483647
			end
			function rng.NextNumber(_, a, b)
				a = a or 0
				b = b or 1
				return a + nextFloat() * (b - a)
			end
			function rng.NextInteger(_, a, b)
				return math.floor(a + nextFloat() * (b - a + 1))
			end
			function rng.NextUnitVector()
				return Vector3.new(nextFloat() - 0.5, nextFloat() - 0.5, nextFloat() - 0.5).Unit
			end
			function rng.Shuffle(_, list)
				for index = #list, 2, -1 do
					local other = math.floor(nextFloat() * index) + 1
					list[index], list[other] = list[other], list[index]
				end
			end
			function rng.Clone()
				return randomClass().new(state)
			end
			return rng
		end,
	}
end

local RaycastParams = {
	new = function()
		return {
			FilterType = Enum.RaycastFilterType.Exclude,
			FilterDescendantsInstances = {},
			IgnoreWater = false,
			CollisionGroup = "Default",
			RespectCanCollide = false,
			AddToFilter = noop,
		}
	end,
}
local OverlapParams = {
	new = function()
		return {
			FilterType = Enum.RaycastFilterType.Exclude,
			FilterDescendantsInstances = {},
			MaxParts = 0,
			CollisionGroup = "Default",
			RespectCanCollide = false,
			AddToFilter = noop,
		}
	end,
}

local DateTimeClass = {
	now = function()
		local unix = EPOCH + session.now
		return {
			UnixTimestamp = math.floor(unix),
			UnixTimestampMillis = math.floor(unix * 1000),
			ToUniversalTime = function()
				return os.date("!*t", math.floor(unix))
			end,
			ToLocalTime = function()
				return os.date("!*t", math.floor(unix))
			end,
			FormatUniversalTime = function()
				return os.date("!%Y-%m-%d %H:%M", math.floor(unix))
			end,
			FormatLocalTime = function()
				return os.date("!%Y-%m-%d %H:%M", math.floor(unix))
			end,
		}
	end,
}
DateTimeClass.fromUnixTimestamp = function()
	return DateTimeClass.now()
end

local InstanceClass = {
	new = newInstance,
	fromExisting = function(instance)
		return instance:Clone()
	end,
}

function makeEnvironment(node)
	return {
		game = session.game,
		Game = session.game,
		workspace = session.workspace,
		Workspace = session.workspace,
		script = node,
		require = function(target)
			if type(target) == "table" and getmetatable(target) == nodeMeta then
				return requireNode(target)
			end
			error(
				"require() in the preview only takes modules found through script or game:GetService (not asset ids)",
				2
			)
		end,
		Instance = InstanceClass,
		Vector3 = Vector3,
		Vector2 = Vector2,
		Vector3int16 = roblox.Vector3int16,
		Vector2int16 = roblox.Vector2int16,
		CFrame = CFrame,
		Color3 = Color3,
		BrickColor = roblox.BrickColor,
		UDim = roblox.UDim,
		UDim2 = UDim2,
		Rect = roblox.Rect,
		Ray = roblox.Ray,
		Enum = Enum,
		Font = roblox.Font,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		PhysicalProperties = roblox.PhysicalProperties,
		Region3 = roblox.Region3,
		Faces = roblox.Faces,
		Axes = roblox.Axes,
		TweenInfo = TweenInfo,
		RaycastParams = RaycastParams,
		OverlapParams = OverlapParams,
		DateTime = DateTimeClass,
		Random = randomClass(),
		task = taskLib,
		os = osTable(),
		tick = function()
			return EPOCH + session.now
		end,
		time = function()
			return session.now
		end,
		elapsedTime = function()
			return session.now
		end,
		wait = taskLib.wait,
		delay = taskLib.delay,
		spawn = taskLib.spawn,
		warn = function(...)
			print("     [warn]", ...)
		end,
		print = function(...)
			print("     [print]", ...)
		end,
		shared = session.shared,
		_G = session.G,
		settings = function()
			return { Rendering = { QualityLevel = Enum.QualityLevel.Automatic } }
		end,
		UserSettings = function()
			return {
				GameSettings = {
					SavedQualityLevel = Enum.SavedQualitySetting.Automatic,
					MasterVolume = 1,
					RotationType = Enum.RotationType.MovementRelative,
				},
				GetService = function(_, name)
					return stubService(name)
				end,
			}
		end,
	}
end

function requireNode(node)
	local file = rawget(node, "File")
	if not file then
		error(`{node:GetFullName()} is a folder, not a module`, 2)
	end
	if rawget(node, "Kind") == "LocalScript" then
		error(`{node:GetFullName()} is a LocalScript; use Client.run`, 2)
	end
	local cache = session.moduleCache
	if cache[file] ~= nil then
		if cache[file] == cache then
			error(`{node:GetFullName()} requires itself (a require loop)`, 2)
		end
		return cache[file]
	end
	cache[file] = cache -- marks "loading"
	local chunk = luau.load(rawget(node, "Source"), { debugName = file, environment = makeEnvironment(node) })
	local ok, result = xpcall(chunk, traceback)
	if not ok then
		cache[file] = nil
		error(result, 0)
	end
	if result == nil then
		cache[file] = nil
		error(`{node:GetFullName()} didn't return a value`, 0)
	end
	cache[file] = result
	return result
end

local function nodeAt(path)
	local parts = string.split(path, ".")
	local node
	if #parts == 1 then
		node = rawget(clientNode, "Children")[parts[1]]
			or error(`No client module called {parts[1]} (looked in {table.concat(overlay("client"), ", ")})`)
		return node
	end
	node = getService(parts[1])
	for index = 2, #parts do
		node = node[parts[index]]
	end
	return node
end

-- Loads a client module by name ("PlayMenu"), or any module by its game path
-- ("ReplicatedStorage.Shared.Config", "StarterPlayer.StarterPlayerScripts.Client.Hud")
function Client.require(path)
	return requireNode(nodeAt(path))
end

-- Runs a LocalScript like the client would, e.g. Client.run("Main")
function Client.run(path)
	local node = nodeAt(path)
	if rawget(node, "Kind") ~= "LocalScript" then
		error(path .. " isn't a LocalScript (*.client.luau)")
	end
	local chunk =
		luau.load(rawget(node, "Source"), { debugName = rawget(node, "File"), environment = makeEnvironment(node) })
	local ok, err = xpcall(chunk, traceback)
	if not ok then
		error(err, 0)
	end
end

-- Globals for a screens file: the Roblox types, plus Client and World
function Client.environment()
	local env = makeEnvironment(nil)
	env.Client = Client
	env.World = World
	env.require = function(target)
		if type(target) == "string" then
			return Client.require(target)
		end
		return requireNode(target)
	end
	return env
end

-- Approximate Absolute sizes -----------------------------------------------------------------

-- Lune doesn't lay out UI, so before each frame this fills AbsoluteSize and
-- AbsolutePosition with a simple version of Roblox's layout (UDim2, anchor,
-- padding, list and grid layouts, rough text widths). gui_render.mjs does
-- the real layout for the pictures; this is only for code that reads them.
local function udimPixels(udim, size)
	return udim.Scale * size + udim.Offset
end

local function roughTextSize(item)
	local ok, text = pcall(function()
		return item.Text
	end)
	if not ok or type(text) ~= "string" then
		return Vector2.zero
	end
	text = text:gsub("<[^>]->", "")
	local size = item.TextSize
	local longest, lines = 0, 0
	for line in (text .. "\n"):gmatch("(.-)\n") do
		lines += 1
		longest = math.max(longest, utf8.len(line) or #line)
	end
	return Vector2.new(longest * size * 0.56, lines * size)
end

local function layoutObject(item, x, y, w, h)
	pcall(function()
		item.AbsolutePosition = Vector2.new(x, y)
		item.AbsoluteSize = Vector2.new(w, h)
	end)
	if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
		local bounds = roughTextSize(item)
		pcall(function()
			item.TextBounds = bounds
			item.TextFits = bounds.X <= w + 0.5 and bounds.Y <= h + 0.5
		end)
	end
	local padLeft, padTop, padRight, padBottom = 0, 0, 0, 0
	local list, grid
	for _, child in item:GetChildren() do
		if child:IsA("UIPadding") then
			padLeft, padRight = udimPixels(child.PaddingLeft, w), udimPixels(child.PaddingRight, w)
			padTop, padBottom = udimPixels(child.PaddingTop, h), udimPixels(child.PaddingBottom, h)
		elseif child:IsA("UIListLayout") then
			list = child
		elseif child:IsA("UIGridLayout") then
			grid = child
		end
	end
	local cx, cy = x + padLeft, y + padTop
	local cw, ch = math.max(0, w - padLeft - padRight), math.max(0, h - padTop - padBottom)
	if item:IsA("ScrollingFrame") then
		pcall(function()
			item.AbsoluteWindowSize = Vector2.new(w, h)
			local canvas = item.CanvasSize
			item.AbsoluteCanvasSize =
				Vector2.new(math.max(w, udimPixels(canvas.X, w)), math.max(h, udimPixels(canvas.Y, h)))
		end)
	end
	local kids = {}
	for _, child in item:GetChildren() do
		if child:IsA("GuiObject") then
			table.insert(kids, child)
		end
	end
	if list or grid then
		local layout = list or grid
		table.sort(kids, function(a, b)
			if layout.SortOrder == Enum.SortOrder.Name then
				return a.Name < b.Name
			end
			return a.LayoutOrder < b.LayoutOrder
		end)
	end
	local cursor = 0
	local column, row = 0, 0
	for _, child in kids do
		local size = child.Size
		local childW = udimPixels(size.X, cw)
		local childH = udimPixels(size.Y, ch)
		if child.AutomaticSize ~= Enum.AutomaticSize.None then
			local bounds = roughTextSize(child)
			if child.AutomaticSize ~= Enum.AutomaticSize.Y then
				childW = math.max(childW, bounds.X)
			end
			if child.AutomaticSize ~= Enum.AutomaticSize.X then
				childH = math.max(childH, bounds.Y)
			end
		end
		local childX, childY
		if list then
			local gap = udimPixels(list.Padding, if list.FillDirection == Enum.FillDirection.Vertical then ch else cw)
			if list.FillDirection == Enum.FillDirection.Vertical then
				childX, childY = cx, cy + cursor
				cursor += childH + gap
			else
				childX, childY = cx + cursor, cy
				cursor += childW + gap
			end
		elseif grid then
			childW, childH = udimPixels(grid.CellSize.X, cw), udimPixels(grid.CellSize.Y, ch)
			local gapX, gapY = udimPixels(grid.CellPadding.X, cw), udimPixels(grid.CellPadding.Y, ch)
			local perRow = math.max(1, math.floor((cw + gapX) / math.max(1, childW + gapX)))
			childX, childY = cx + column * (childW + gapX), cy + row * (childH + gapY)
			column += 1
			if column >= perRow then
				column, row = 0, row + 1
			end
		else
			local position = child.Position
			local anchor = child.AnchorPoint
			childX = cx + udimPixels(position.X, cw) - anchor.X * childW
			childY = cy + udimPixels(position.Y, ch) - anchor.Y * childH
		end
		layoutObject(child, childX, childY, childW, childH)
	end
	if list or grid then
		pcall(function()
			local layout = list or grid
			layout.AbsoluteContentSize = if list and list.FillDirection == Enum.FillDirection.Vertical
				then Vector2.new(cw, cursor)
				else Vector2.new(cursor, ch)
		end)
	end
end

function Client.layout()
	local viewport = session.camera.ViewportSize
	for _, gui in session.playerGui:GetChildren() do
		if gui:IsA("ScreenGui") then
			local top = if gui.IgnoreGuiInset then 0 else session.inset
			pcall(function()
				gui.AbsoluteSize = Vector2.new(viewport.X, viewport.Y - top)
				gui.AbsolutePosition = Vector2.new(0, top)
			end)
			for _, child in gui:GetChildren() do
				if child:IsA("GuiObject") then
					local size, position, anchor = child.Size, child.Position, child.AnchorPoint
					local w, h = udimPixels(size.X, viewport.X), udimPixels(size.Y, viewport.Y - top)
					layoutObject(
						child,
						udimPixels(position.X, viewport.X) - anchor.X * w,
						top + udimPixels(position.Y, viewport.Y - top) - anchor.Y * h,
						w,
						h
					)
				end
			end
		end
	end
end

-- Driving the client ------------------------------------------------------------------------

-- Advances the fake clock by `seconds` in 60 fps frames: each frame fires
-- RenderStepped (and BindToRenderStep callbacks), Stepped and Heartbeat, then
-- wakes whatever task.wait / task.delay is due.
function Client.step(seconds)
	local frames = math.max(1, math.floor((seconds or 1 / 60) * 60 + 0.5))
	local dt = 1 / 60
	local run = session.runService
	for _ = 1, frames do
		session.now += dt
		syncParts(session.workspace)
		Client.layout()
		local bound = {}
		for name, entry in run.Bound do
			table.insert(bound, { Name = name, Priority = entry.Priority, Fn = entry.Fn })
		end
		table.sort(bound, function(a, b)
			return a.Priority < b.Priority
		end)
		for _, entry in bound do
			local ok, err = xpcall(entry.Fn, traceback, dt)
			if not ok then
				report(err)
			end
		end
		run.PreRender:Fire(dt)
		run.RenderStepped:Fire(dt)
		run.PreAnimation:Fire(dt)
		run.Stepped:Fire(session.now, dt)
		run.PreSimulation:Fire(dt)
		run.PostSimulation:Fire(dt)
		run.Heartbeat:Fire(dt)
		runDue()
	end
end

-- Seconds since the preview started, and the server clock the game sees
function Client.now()
	return session.now
end
function Client.serverTime()
	return EPOCH + session.now
end

-- Runs fn in a task thread (so it may wait); returns the thread and a table
-- that gets Done/Ok/Result when it finishes
function Client.spawn(fn, ...)
	local state = { Done = false }
	local args = table.pack(...)
	local thread = coroutine.create(function()
		local result = table.pack(xpcall(fn, traceback, table.unpack(args, 1, args.n)))
		state.Done = true
		state.Ok = result[1]
		state.Result = result[2]
		state.Results = result
	end)
	session.managed[thread] = true
	local ok, err = coroutine.resume(thread)
	if not ok then
		state.Done, state.Ok, state.Result = true, false, err
	end
	state.Thread = thread
	return state
end

-- What paused threads are waiting on, for "Build never finished" messages
function Client.waiting()
	local list = {}
	for _, reason in session.waitingOn do
		table.insert(list, reason)
	end
	return list
end

function Client.errors()
	return session.errors
end

-- Remotes the client sent, as { Remote = name, Args = { ... } }
function Client.sent()
	return session.sent
end

function Client.setAttributes(values)
	for name, value in values do
		session.player:SetAttribute(name, value)
	end
end
function Client.setAttribute(target, name, value)
	if value == nil and type(name) ~= "string" then
		error("Client.setAttribute(instance, name, value)")
	end
	if target == session.player then
		session.player:SetAttribute(name, value)
		return
	end
	target:SetAttribute(name, value)
	signalOf(target, "AttributeChanged"):Fire(name)
	signalOf(target, "Attribute:" .. name):Fire()
end

-- Sets a property and fires .Changed / GetPropertyChangedSignal like Roblox would
function Client.set(target, property, value)
	target[property] = value
	signalOf(target, "Property:" .. property):Fire()
	if target:IsA("ValueBase") then
		signalOf(target, "Changed"):Fire(value)
	else
		signalOf(target, "Changed"):Fire(property)
	end
end

-- leaderstats.<name>.Value (Credits or Bans)
function Client.setStat(name, value)
	local stat = session.leaderstats:FindFirstChild(name)
	if not stat then
		stat = Instance.new("IntValue")
		stat.Name = name
		stat.Parent = session.leaderstats
	end
	Client.set(stat, "Value", value)
end

-- Gives the player a stand-in R15 character (options: Health, MaxHealth, WalkSpeed)
function Client.spawnCharacter(options)
	options = options or {}
	local rig = World.rig({ Torso = Color3.fromRGB(40, 40, 50), Legs = Color3.fromRGB(30, 30, 36) })
	rig.Name = session.player.Name
	for _, item in rig:GetDescendants() do
		seed(item)
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	humanoid.MaxHealth = options.MaxHealth or 100
	humanoid.Health = options.Health or humanoid.MaxHealth
	humanoid.WalkSpeed = options.WalkSpeed or 16
	local animator = Instance.new("Animator")
	animator.Parent = humanoid
	rig.Parent = session.workspace
	session.player.Character = rig
	session.player.CharacterAdded:Fire(rig)
	return rig
end

local NO_KEY = (select(
	2,
	pcall(function()
		return Enum.KeyCode.Unknown
	end)
))
if typeof(NO_KEY) ~= "EnumItem" then
	NO_KEY = nil
end

local function inputObject(props)
	local input = {
		KeyCode = NO_KEY,
		UserInputType = Enum.UserInputType.None,
		UserInputState = Enum.UserInputState.Begin,
		Position = Vector3.zero,
		Delta = Vector3.zero,
	}
	for key, value in props do
		input[key] = value
	end
	function input.IsModifierKeyDown()
		return false
	end
	return input
end

-- Presses and releases a key, as if typed outside any TextBox
function Client.pressKey(keyCode, gameProcessed)
	local service = session.inputService
	service.InputBegan:Fire(
		inputObject({ KeyCode = keyCode, UserInputType = Enum.UserInputType.Keyboard }),
		gameProcessed == true
	)
	service.InputEnded:Fire(
		inputObject({
			KeyCode = keyCode,
			UserInputType = Enum.UserInputType.Keyboard,
			UserInputState = Enum.UserInputState.End,
		}),
		gameProcessed == true
	)
end

-- Clicks a button: mouse down, up, click and Activated
function Client.click(button)
	if not button then
		error("Client.click: no button (check the name or text you searched for)", 2)
	end
	local input = inputObject({ UserInputType = Enum.UserInputType.MouseButton1 })
	signalOf(button, "InputBegan"):Fire(input)
	if button:IsA("GuiButton") then
		signalOf(button, "MouseButton1Down"):Fire(0, 0)
		signalOf(button, "MouseButton1Up"):Fire(0, 0)
		signalOf(button, "MouseButton1Click"):Fire()
		signalOf(button, "Activated"):Fire(input, 1)
	end
	signalOf(button, "InputEnded"):Fire(input)
end

function Client.hover(item)
	signalOf(item, "MouseEnter"):Fire(0, 0)
end
function Client.unhover(item)
	signalOf(item, "MouseLeave"):Fire(0, 0)
end

-- Types text into a TextBox and presses Enter
function Client.type(box, text, pressEnter)
	focusedBox = box
	signalOf(box, "Focused"):Fire()
	Client.set(box, "Text", text)
	focusedBox = nil
	signalOf(box, "FocusLost"):Fire(pressEnter ~= false)
end

-- Fires a RemoteEvent at the client, as if the server sent it
function Client.fireClient(name, ...)
	remoteNamed(name).OnClientEvent:Fire(...)
end

-- Answers RemoteFunction:InvokeServer(...) for one remote
function Client.onInvoke(name, handler)
	session.invokeHandlers[name] = handler
end

function Client.remote(name)
	return remoteNamed(name)
end

-- Finds a descendant by a dotted path of names, starting at root (or the PlayerGui)
function Client.find(root, path)
	if type(root) == "string" then
		root, path = session.playerGui, root
	end
	local node = root
	for _, name in string.split(path, ".") do
		node = node and node:FindFirstChild(name)
	end
	return node
end

-- Finds the first GuiObject whose Text is exactly `text` (or matches it as a
-- Lua pattern when `pattern` is true)
function Client.findText(root, text, pattern)
	if type(root) == "string" then
		root, text, pattern = session.playerGui, root, text
	end
	for _, item in root:GetDescendants() do
		if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
			local value = item.Text
			if value == text or (pattern and string.find(value, text)) then
				return item
			end
		end
	end
	return nil
end

Client.Enum = Enum
Client.Instance = InstanceClass
Client.Color3 = Color3
Client.Vector2 = Vector2
Client.Vector3 = Vector3
Client.UDim2 = UDim2
Client.CFrame = CFrame
Client.task = taskLib

Client.reset()

return Client
