planetoids.populator = {}
local p = planetoids.populator
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
	rarity = 30,
}

p.grass_pop = {
	node = "default:dirt_with_grass",
	population_chance = 0.5,
	red_flower,blue_flower,yellow_flower,white_flower,
	purple_flower,orange_flower,long_grass,
}


local jungle_grass = {
	node = "default:junglegrass",
	rarity = 1,
}

p.jungle_pop = {
	node = "default:jungleleaves",
	population_chance = 0.08,
	jungle_grass,
}


local reeds = {
	node = "default:papyrus",
	rarity = 5,
}

local long_grass = {
	node = "default:grass_5",
	rarity = 15,
}

p.sand_pop = {
	node = "default:sand",
	population_chance = 0.1,
	reeds,long_grass,
}
	
local dry_shrub = {
	node = "default:dry_shrub",
	rarity = 10,
}
local cactus = {
	node = "default:cactus",
	rarity = 1,
}

p.desertsand_pop = {
	node = "default:desert_sand",
	population_chance = 0.1,
	dry_shrub,cactus
}


local red_shroom = {
	node = "flowers:mushroom_red",
	rarity = 1,
}

local brown_shroom = {
	node = "flowers:mushroom_brown",
	rarity = 1,
}

p.stone_pop = {
	node = "default:stone",
	population_chance = 0.01,
	brown_shroom,red_shroom,
}
	

local drygrass = {
	node = "default:dry_grass_5",
	rarity = 15,
}

p.drygrass_pop = {
	node = "default:dirt_with_dry_grass",
	population_chance = 0.3,
	drygrass,
}
