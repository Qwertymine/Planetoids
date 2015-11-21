local coal = {
	rarity = 30,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_coal",
}
local lava = {
	rarity = 15,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:lava_source",
}
local iron = {
	rarity = 5,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_iron",
}
local copper = {
	rarity = 5,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_copper",
}
local diamond = {
	rarity = 2,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_diamond",
}
local mese = {
	rarity = 2,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_mese",
}
local gravel = {
	rarity = 2,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:gravel",
}

local stone = {
	rarity = 10,
	coal,lava,iron,copper,diamond,mese,gravel,
}

local dirt = {
	rarity = 2,
	filling_material = "default:dirt",
	crust_thickness = 1,
	crust_material = "default:dirt",
	crust_top_material = "default:dirt_with_grass",
}
local dirt_dry = {
	rarity = 2,
	filling_material = "default:dirt",
	crust_thickness = 1,
	crust_material = "default:dirt",
	crust_top_material = "default:dirt_with_dry_grass",
}
local dirt_snow = {
	rarity = 2,
	filling_material = "default:dirt",
	crust_thickness = 1,
	crust_material = "default:dirt",
	crust_top_material = "default:dirt_with_snow",
}

local ice = {
	rarity = 3,
	filling_material = "default:ice",
	crust_thickness = 3,
	crust_material = "default:snow",
}

local sand_clay = {
	rarity = 3,
	filling_material = "default:sand",
	crust_thickness = 4,
	crust_top_material = "default:sand",
	crust_material = "default:clay",
}
local sand_sandstone = {
	rarity = 6,
	filling_material = "default:sand",
	crust_thickness = 1,
	crust_top_material = "default:sand",
	crust_material = "default:sandstone",
}
local desert_sand = {
	rarity = 6,
	crust_thickness = 1,
	filling_material = "default:desert_sand",
	crust_top_material = "default:desert_sand",
	crust_material = "default:desert_stone",
}

local soft = {
	rarity = 14,
	dirt,sand_sandstone,sand_clay,desert_sand,
	ice,dirt_snow,dirt_dry,
}

local normal_tree = {
	rarity = 1,
	crust_material = "default:leaves",
	crust_thickness = 2,
	filling_material = "default:tree",
}
local pine_tree = {
	rarity = 1,
	crust_material = "default:pine_needles",
	crust_thickness = 2,
	filling_material = "default:pine_tree",
}
local acacia_tree = {
	rarity = 1,
	crust_material = "default:acacia_leaves",
	crust_thickness = 2,
	filling_material = "default:acacia_tree",
}
local jungle_tree = {
	rarity = 1,
	crust_material = "default:jungleleaves",
	crust_thickness = 2,
	filling_material = "default:jungletree",
}

local tree = {
	rarity = 7,
	normal_tree,pine_tree,jungle_tree,acacia_tree,
}

local water = {
	rarity = 1,
	crust_thickness = 2,
	crust_material = "default:glass",
	filling_material = "default:water_source",
}

local river_water = {
	rarity = 1,
	crust_thickness = 2,
	crust_material = "default:glass",
	filling_material = "default:river_water_source",
}

local glass = {
	rarity = 2,
	water,river_water,
}

--basic populator tables
local red_flower = {
	node = "flowers:rose",
	rarity = 1,
}
local blue_flower = {
	node = "flowers:geranium",
	rarity = 1,
}
local yellow_flower = {
	node = "flowers:dandelion_yellow",
	rarity = 1,
}
local white_flower = {
	node = "flowers:dandelion_white",
	rarity = 1,
}
local purple_flower = {
	node = "flowers:viola",
	rarity = 1,
}
local orange_flower = {
	node = "flowers:tulip",
	rarity = 1,
}
local long_grass = {
	node = "default:grass_5",
	rarity = 15,
}

local grass_pop = {
	node = "default:grass",
	population_chance = 0.5,
	red_flower,green_flower,blue_flower,yellow_flower,white_flower,
	purple_flower,orange_flower,long_grass,
}


local jungle_grass = {
	node = "default:junglegrass",
	rarity = 1,
}

local jungle_pop = {
	node = "default:jungleleaves",
	population_chance = 0.2,
	jungle_grass,
}


local reeds = {
	node = "default:papyrus",
	rarity = 5,
}

local sand_pop = {
	node = "default:sand",
	population_chance = 0.1,
	reeds,long_grass,
}
	
local reeds = {
	node = "default:dry_shrub",
	rarity = 1,
}

local desertsand_pop = {
	node = "default:desert_sand",
	population_chance = 0.1,
	dry_shrub,
}


local red_shroom = {
	node = "flowers:mushroom_red",
	rarity = 1,
}

local brown_shroom = {
	node = "flower:mushroom_brown",
	rarity = 1,
}

local stone_pop = {
	node = "default:stone",
	population_chance = 0.1,
	brown_shroom,red_shroom,
}
	

local drygrass = {
	node = "default:dry_grass_5",
	rarity = 15,
}

local drygrass_pop = {
	node = "default:grass",
	population_chance = 0.5,
	drygrass,
}

planetoids.settings = {
	--a number added to the world seed to amke different noises
	seed_offset = 5,
	--scale to multiply the noise by(for performace)
	--if not a factor of 80, there may be some artifacting at the edge
	--of voxel manip blocks
	scale = nil,
	--This sets the size of the blocks that it generates, performance
	--improves with size only for smaller sizes: 1^3 < small > 80^3
	blocksize = {x=5,y=5,z=5},
	--This is the distribution of how many points are generated in each
	--sector
	--The index is the number of points - these MUST be continuous
	--The number value is the minimum random number required for that value
	--to be chosen
	point_distribution = {
		default = 1,
		[1] = 60,
		[2] = 40,
		[3] = 40,
		[4] = 40,
	},
	planet_size = {
		minimum = 5,
		maximum = 15,
		--size of sector as multiple of maximum, must be > 2
		sector_scale = 3,
	},
	planet_types = {
		stone,soft,tree,glass,
	},
	--tables to add basic surface population - e.g. for long grass
	surface_populator = {
		grass_pop,jungle_pop,sand_pop,stone_pop,
		drygrass_pop,desertsand_pop,
	}
		
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "chebyshev",
}

planetoids.configure()
