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
}
local sand = {
	rarity = 1,
	filling_material = "default:sand",
}
local desert_sand = {
	crust_thickness = 2,
	filling_material = "default:desert_sand",
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

local tree = {
	rarity = 7,
	normal_tree,
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
		random_max = 20,
		random_min = 1,
		[1] = 1,
		--This is an example of how to 'skip' a value - 2 is skipped 
		[2] = 20,
		[3] = 20,
	},
	planet_size = {
		minimum = 5,
		maximum = 25,
	},
	planet_types = {
		stone,soft,tree
	},
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "manhattan",
}

