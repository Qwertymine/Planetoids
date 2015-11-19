local coal = {
	rarity = 10,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_coal",
}
local lava = {
	rarity = 5,
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
	rarity = 3,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_copper",
}
local diamond = {
	rarity = 1,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_diamond",
}
local mese = {
	rarity = 1,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:stone_with_mese",
}
local gravel = {
	rarity = 1,
	crust_material = "default:stone",
	crust_thickness = 2,
	filling_material = "default:gravel",
}

local stone = {
	rarity = 10,
	coal,lava,iron,copper,diamond,mese,gravel,
}

local dirt = {
	rarity = 1,
	filling_material = "default:dirt",
	crust_thickness = 1,
	crust_material = "default:dirt",
	crust_top_material = "default:dirt_with_grass",
}

local sand = {
	rarity = 1,
	filling_material = "default:sand",
	crust_thickness = 1,
	crust_top_material = "default:sand",
	crust_material = "default:sandstone",
}
local desert_sand = {
	rarity = 1,
	crust_thickness = 1,
	filling_material = "default:desert_sand",
	crust_top_material = "default:desert_sand",
	crust_material = "default:desert_stone",
}

local soft = {
	rarity = 4,
	dirt,sand,desert_sand,
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
	rarity = 1,
	water,river_water,
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
		[0] = 80,
		[1] = 60,
		[2] = 40,
	},
	planet_size = {
		minimum = 5,
		maximum = 15,
	},
	planet_types = {
		stone,soft,tree,glass,
	},
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "euclidean",
}

planetoids.configure()
