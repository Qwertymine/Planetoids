dofile(minetest.get_modpath("planetoids").."/planets.lua")
dofile(minetest.get_modpath("planetoids").."/populator.lua")
local planets = planetoids.planets
local pop = planetoids.populator
planetoids.settings = {
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
	mode = "perlin",
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
		planets.stone,planets.soft,planets.tree,planets.glass,
	},
	--tables to add basic surface population - e.g. for long grass
	surface_populator = {
		enabled = true,
		pop.grass_pop,pop.jungle_pop,pop.sand_pop,pop.stone_pop,
		pop.drygrass_pop,pop.desertsand_pop,
	},
		
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "euclidean",
}

--perlin specific settings
if planetoids.settings.mode == "perlin" then
	planetoids.settings.planet_size = {
		minimum = 15,
		maximum = 30,
		--size of sector as multiple of maximum, must be > 2
		sector_scale = 2,
	}
	planetoids.settings.perlin_map = {
		lacunarity = 1.4,
		octaves = 2,
		persistence = 0.5,
		--reduce to reduce effect of noise, max 1
		scale = 0.6,
		seeddiff = 5349,
		spread = {x=10,y=10,z=10},
	}
	planetoids.settings.threshold = 0
	planetoids.settings.thickness_offset = 1
end


planetoids.configure()
