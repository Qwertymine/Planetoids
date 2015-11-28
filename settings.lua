dofile(minetest.get_modpath("planetoids").."/planets.lua")
dofile(minetest.get_modpath("planetoids").."/populator.lua")
local planets = planetoids.planets
local pop = planetoids.populator
planetoids.settings = {
	--scale to multiply the noise by(for performace)
	--if not a factor of 80, there may be some artifacting at the edge
	--of voxel manip blocks
	scale = nil,
	--TECHNICAL SETTING - Each voxelmanip is sub-divided into smaller
	--areas for generation - this is used for a custom optimisation
	--improves with size only for smaller sizes: 1^3 < small > 80^3
	blocksize = {x=5,y=5,z=5},

	--Used to choose "normal" planetoids, or "perlin" planetoids
	--normal are just raw-distance - perlin uses a perlin map to add 
	--further shape
	mode = "normal",

	--Sets the relative frequency of points
	--Each size of point must be included from maximum - 1
	--0 is supported, but doesn't need inclusion if not used
	--default is used if there is any issue finding a no. points
	--^ this should never happen however - so you set to nil
	point_distribution = {
		default = 1,
		[1] = 60,
		[2] = 40,
		[3] = 40,
		[4] = 40,
	},
	--Set the possible planet sizes
	--All are equally likely
	planet_size = {
		minimum = 5,
		maximum = 15,
		--Larger values increase the distance between planetoids
		--TECHNICAL SETTING - The world is divided into cubes to
		--generate planetoid positions
		--The size of each one is maximum * sector_scale
		--Sector_scale must be > 2 for algorithmic reasons
		sector_scale = 3,
	},
	--List of planet group tables
	--See planets.lua
	planet_types = {
		planets.stone,planets.soft,planets.tree,planets.glass,
	},
	--Tables to add basic surface population - e.g. for long grass
	--See populator.lua
	surface_populator = {
		enabled = true,
		pop.grass_pop,pop.jungle_pop,pop.sand_pop,pop.stone_pop,
		pop.drygrass_pop,pop.desertsand_pop,
	},
		
	--How distance from the centre of a biome is judged
	--Changes he shape of generated biomes
	--"euclidean" - sphere
	--"manhattan" - diamond
	--"chebyshev" - cube
	--"oddprod" - cross - WARNING does NOT keep liquids enclosed
	geometry = "euclidean",
}

--Override and additional settings for perlin mode
if planetoids.settings.mode == "perlin" then
	--Perlin planets are smaller - this table is the MAXIMUM size now
	--On average ~1/2 radius
	planetoids.settings.planet_size = {
		minimum = 15,
		maximum = 30,
		--This valus is reduced to offset the larger size of planets
		--in determining distance between them
		sector_scale = 2,
	}
	--Perlin ONLY settings below


	--Perlin map settings - see RubenWardy's modding book for explination
	--http://rubenwardy.com/minetest_modding_book/lua_api.html
	planetoids.settings.perlin_map = {
		lacunarity = 1.4,
		octaves = 2,
		persistence = 0.5,
		--reduce to reduce effect of noise, max 1
		scale = 0.6,
		seeddiff = 5349,
		spread = {x=10,y=10,z=10},
	}
	--TECHNICAL SETTING - Minimum density for planetoids to be generated
	--Setting this higher can lead to larger planetoids - but if too high
	--will lead to planetoids with terrain shaped only by the geometry 
	planetoids.settings.threshold = 0
	--Perlin planet crusts are thinner - crust_thickness is the MAXIMUM
	--This value is added to each crust thickness to counter this
	planetoids.settings.thickness_offset = 1
end


--This finalises the configuration - all settings must be above this
planetoids.configure()
