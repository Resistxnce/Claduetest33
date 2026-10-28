-- Extra guns for GunModels: their part lists, plus the extra part roles they
-- use. GunModels merges both into its own tables (see INSTALL.md), so the
-- first-person viewmodel, the tool other players see and bot guns all get
-- them. Their stats are in ConfigExtra.
local Shapes = require(script.Shapes)

local GunSpecsExtra = {
	Roles = Shapes.ROLES,
	Specs = {},
}

for _, moduleName in { "Classic", "SciFi" } do
	for id, spec in require(script[moduleName]) do
		GunSpecsExtra.Specs[id] = spec
	end
end

return GunSpecsExtra
