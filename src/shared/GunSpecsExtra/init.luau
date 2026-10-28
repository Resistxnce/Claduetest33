-- New guns, and new looks for the game's own guns, built like the guns in the
-- vault's Inspiration pictures. Each file in Guns/ is one gun's part list in
-- the GunModels format, named by the gun's id. A file with the same id as one
-- of the game's guns (Pistol, SMG, ...) replaces that gun's look; its stats
-- stay in Config. Stats for the new guns are in ConfigExtra.
--
-- GunModels calls GunSpecsExtra.install(GunModels, SPECS, ROLES) just before
-- it returns (see INSTALL.md). That adds these part lists and part roles, and
-- swaps in a makeParts that also understands:
--   Class = "WedgePart"                       for angled pieces
--   Mesh = Enum.MeshType.Sphere               for rounded pieces (an egg shape that fills the part's size)
--   spec.Factory = { Body, Accent, Material }  the gun's own colors, shown with the Factory (Default) skin
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Shapes = require(script.Shapes)

local GunSpecsExtra = {
	Roles = Shapes.ROLES,
	Specs = {},
}

local guns = script:FindFirstChild("Guns")
if guns then
	for _, module in guns:GetChildren() do
		if module:IsA("ModuleScript") then
			GunSpecsExtra.Specs[module.Name] = require(module)
		end
	end
end

function GunSpecsExtra.install(GunModels, specs, roles)
	for name, role in GunSpecsExtra.Roles do
		roles[name] = role
	end
	for id, spec in GunSpecsExtra.Specs do
		specs[id] = spec
	end

	-- The game's makeParts, plus wedges, rounded parts and Factory colors
	function GunModels.makeParts(weaponId, skinId)
		local spec = GunModels.spec(weaponId)
		local skin = Config.getSkin(skinId)
		local factory = if skin.Id == "Default" then spec.Factory else nil
		local body = if factory and factory.Body then factory.Body else skin.Body
		local bodyMaterial = if factory and factory.Material then factory.Material else skin.Material or Enum.Material.SmoothPlastic
		local accent = if factory and factory.Accent then factory.Accent else skin.Accent
		local list = {}
		local function add(entry, spins)
			local part = Instance.new(entry.Class or "Part")
			part.Name = entry.Name
			part.Size = entry.Size
			if entry.Shape then
				part.Shape = entry.Shape
			end
			if entry.Mesh then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = entry.Mesh
				mesh.Parent = part
			end
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Massless = true
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
			if entry.Role == "Body" then
				part.Color = if skin.Rainbow then Color3.fromHSV((#list * 0.13) % 1, 0.8, 1) else body
				part.Material = bodyMaterial
				part.Reflectance = if factory then 0 else skin.Reflectance or 0
			elseif entry.Role == "Accent" then
				part.Color = accent
				part.Material = Enum.Material.Neon
			else
				local role = roles[entry.Role]
				part.Color = role.Color
				part.Material = role.Material
			end
			part:SetAttribute("Role", entry.Role)
			table.insert(list, { Part = part, Offset = entry.Offset, Spins = spins })
		end
		for _, entry in spec.Parts do
			add(entry, false)
		end
		for _, entry in spec.Spinning or {} do
			add(entry, true)
		end
		return list
	end
end

return GunSpecsExtra
