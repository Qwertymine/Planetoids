planetoids.planets = {}
local p = planetoids.planets
local coal = {
	rarity = 30,
	crust_material = "default:stone",
	--thickness is MAXthickness - due to perlin noise variation
	--it will be lower
	crust_thickness = 3,
	filling_material = "default:stone_with_coal",
}
local lava = {
	rarity = 20,
	crust_material = "default:stone",
	crust_thickness = 3,
	filling_material = "default:lava_source",
}
local iron = {
	rarity = 7,
	crust_material = "default:stone",
	crust_thickness = 3,
	filling_material = "default:stone_with_iron",
}
local copper = {
	rarity = 5,
	crust_material = "default:stone",
	crust_thickness = 3,
	filling_material = "default:stone_with_copper",
}
local diamond = {
	rarity = 2,
	crust_material = "default:stone",
	crust_thickness = 3,
	filling_material = "default:stone_with_diamond",
}
local mese = {
	rarity = 2,
	crust_material = "default:stone",
	crust_thickness = 3,
	filling_material = "default:stone_with_mese",
}
local gravel = {
	rarity = 2,
	crust_material = "default:stone",
	crust_thickness = 3,
	filling_material = "default:gravel",
}
local mossy_cobble = {
	rarity = 1,
	crust_material = "default:mossycobble",
	crust_thickness = 4,
	filling_material = "default:lava_source",
}

p.stone = {
	rarity = 10,
	coal,lava,iron,copper,diamond,mese,gravel,
	mossy_cobble,
}

local dirt = {
	rarity = 12,
	filling_material = "default:dirt",
	crust_thickness = 2,
	crust_material = "default:dirt",
	crust_top_material = "default:dirt_with_grass",
}
local dirt_dry = {
	rarity = 4,
	filling_material = "default:dirt",
	crust_thickness = 2,
	crust_material = "default:dirt",
	crust_top_material = "default:dirt_with_dry_grass",
}
local dirt_snow = {
	rarity = 2,
	filling_material = "default:dirt",
	crust_thickness = 2,
	crust_material = "default:dirt",
	crust_top_material = "default:dirt_with_snow",
}

local ice = {
	rarity = 3,
	filling_material = "default:ice",
	crust_thickness = 4,
	crust_material = "default:snowblock",
}

local sand_clay = {
	rarity = 3,
	filling_material = "default:sand",
	crust_thickness = 4,
	crust_top_material = "default:sand",
	crust_material = "default:clay",
}
local sand_sandstone = {
	rarity = 5,
	filling_material = "default:sand",
	crust_thickness = 2,
	crust_top_material = "default:sand",
	crust_material = "default:sandstone",
}
local desert_sand = {
	rarity = 5,
	crust_thickness = 4,
	filling_material = "default:desert_sand",
	crust_top_material = "default:desert_sand",
	crust_material = "default:desert_stone",
}

p.soft = {
	rarity = 12,
	dirt,sand_sandstone,sand_clay,desert_sand,
	ice,dirt_snow,dirt_dry,
}

local normal_tree = {
	rarity = 1,
	crust_material = "default:leaves",
	crust_thickness = 3,
	filling_material = "default:tree",
}
local pine_tree = {
	rarity = 1,
	crust_material = "default:pine_needles",
	crust_thickness = 3,
	filling_material = "default:pine_tree",
}
local acacia_tree = {
	rarity = 1,
	crust_material = "default:acacia_leaves",
	crust_thickness = 3,
	filling_material = "default:acacia_tree",
}
local jungle_tree = {
	rarity = 1,
	crust_material = "default:jungleleaves",
	crust_thickness = 3,
	filling_material = "default:jungletree",
}

p.tree = {
	rarity = 7,
	normal_tree,pine_tree,jungle_tree,acacia_tree,
}

local water = {
	rarity = 1,
	crust_thickness = 3,
	crust_material = "default:glass",
	filling_material = "default:water_source",
}

local river_water = {
	rarity = 1,
	crust_thickness = 3,
	crust_material = "default:glass",
	filling_material = "default:river_water_source",
}

p.glass = {
	rarity = 2,
	water,river_water,
}

