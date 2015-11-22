planetoids = {}
planetoids.layers = {}

--Layer def
--	name
--		string
--	dimensions
--		2 or 3
--	block_size
--		vector - norm 5^3 or nil
--	sector_lengths
--		vector - norm 300^3 or 2000^3
--	scale
--		integer - the sector lengths are multiplied by this, but the
--			noise produced has a lower resolution
--	biome_types
--		table of strings- random,multi-map,multi-tolerance-map,default-biome
--	biome_type_options
--		table - tolerances for heatmap
--	geometry
--		string - euclidean,manhattan,chebyshev
--
--Layer in mem
--	cache
--		table of tables
--	add_biome
--		function to add biomes to the layer
--
--
--Point in mem
--	pos
--		vector
--	biome
--		biome def table



--Returns the biome of the closest point from a table
--Must ensure that points cover the Moore environment of the sector

--[[
--TODO list
--Docs
--add more types of noise - cubic cell noise especially
--]]

--functions defined in local scope for performance
local minetest = minetest
local abs = math.abs
local floor = math.floor
local hash_pos = minetest.hash_node_position
local air = minetest.get_content_id("air")

dofile(minetest.get_modpath("planetoids").."/distance.lua")
dofile(minetest.get_modpath("planetoids").."/maps.lua")

--normal vector.add has a check for b not being a table, I don't need this
local vector_add = function(a,b)
	return {x=a.x+b.x,y=a.y+b.y,z=a.z+b.z}
end

--sector 0,0,0 has a smallest point at 0,0,0
local sector_to_pos = function(sector)
	local lengths = planetoids.settings.sector_lengths
	local pos = {}
	pos.x = lengths.x * sector.x
	pos.y = lengths.y * sector.y
	pos.z = lengths.z * sector.z
	return pos
end

--point 0,0,0 is in sector 0,0,0
local pos_to_sector = function(pos)
	local lengths = planetoids.settings.sector_lengths
	local sector = {x=pos.x,y=pos.y,z=pos.z}
	sector.x = floor(sector.x/lengths.x)
	sector.z = floor(sector.z/lengths.z)
	sector.y = floor(sector.y/lengths.y)
	return sector
end

local find_node = function(pos,points,dist_func)
	local dist = nil
	local node = nil
	for i=1,#points do
		local point = points[i]
		dist = dist_func(pos,point.pos)
		if dist < point.radius then
			if point.ptype.crust_thickness then
				if dist < point.radius - point.ptype.crust_thickness then
					return point.ptype.filling_material
				else
					if point.ptype.crust_top_material and pos.y >= point.pos.y then
						return point.ptype.crust_top_material
					end
					return point.ptype.crust_material
				end
			else
				return point.ptype.filling_material
			end
		end
	end
	return air
end

--block locations must start at (0,0,0)
--for 2d use (x,y) rather than (x,0,z)
local blockfiller = function(blockdata,blocksize,table,tablesize,blockstart)
	local tableit = blockstart 
	local ybuf,zbuf = tablesize.x - blocksize.x,(tablesize.y - blocksize.y)*tablesize.x
	local x,y,z = 1,1,1
	local blocklength = blocksize.x*blocksize.y*(blocksize.z or 1)
	for i=1,blocklength do
		if x > blocksize.x then
			x = 1
			y = y + 1
			tableit = tableit + ybuf
		end
		if y > blocksize.y then
			y = 1
			z = z + 1
			tableit = tableit + zbuf
		end
		table[tableit] = blockdata[i]
		tableit = tableit + 1
		x = x + 1
	end
end

--Uses PcgRandom for better range - a 32 bit random would limit sector sizes to
-- 600^3 due to randomness issues
local generate_points = function(sector,seed)
	local hash = hash_pos(sector)
	local offset = planetoids.settings.seed_offset
	local prand = PcgRandom(hash + (seed + offset) % 100000)

	--Distribution is completely user defined
	local point_dist = planetoids.settings.point_distribution
	local num = prand:next(1,point_dist.rand_max)
	local set = false
	local cum = 0
	for i=#point_dist,0,-1 do
		if point_dist[i] then
			cum = point_dist[i] + cum
			if num <= cum then
				num = i
				set = true
				break
			end
		end
	end

	--If no suitable number of points is found, 1 is set as a fallback
	if not set then
		num = planetoids.settings.planet_size.default
	end

	--Generate each point
	local seen = {}
	local points = {}
	while num > 0 do
		--The points are aligned to 0.1 of a block
		--This used to be to 1 block, but having multiple points at
		--the same distance was causing artifacts with the experimental gen
		local get_dist = planetoids.settings.get_dist
		local x = prand:next(0,planetoids.settings.sector_lengths.x-1)
		local y = prand:next(0,planetoids.settings.sector_lengths.y-1)
		local z = prand:next(0,planetoids.settings.sector_lengths.z-1)
		local pos = {x=x,y=y,z=z}
		local hashed = hash_pos(pos)
		if not seen[hashed] then
			pos = vector_add(pos,sector_to_pos(sector))
			local radius = prand:next(planetoids.settings.planet_size.minimum,
				planetoids.settings.planet_size.maximum)
			local touching = false
			for i,v in ipairs(points) do
				if radius + v.radius > get_dist(pos,v.pos) then
					touching = true
					break
				end
			end
			if not touching then
				point = {pos = pos,radius = radius}
				table.insert(points,point)
				seen[hashed] = pos
			end
		end
		num = num - 1
	end
	--The random number generator is returned for use in adding other 
	--properties to the points - biomes
	return points , prand
end

--This is a wrapper around generate_points - this adds biomes and doesn't return the random
--number generator
local generate_decorated_points = function(sector,seed)
	local hash = hash_pos(sector)
	--This is a cache for storing points that were already generated
	--this should improve performance - but profiling breaks it
	if planetoids.cache[hash] then
		return planetoids.cache[hash]
	end
	local points,prand = generate_points(sector,seed,layer)
	local planet_types = planetoids.settings.planet_types
	for i=1,#points do
		local point = points[i]
		
		--choose plaent type
		local cum = 0
		local ptype = prand:next(1,planet_types.rand_max)
		local set = false
		for i=#planet_types,1,-1 do
			cum = planet_types[i].rarity + cum
			if ptype <= cum then
				ptype = planet_types[i]
				set = true
				break
			end
		end
		--If no suitable number of points is found, 1 is set as a fallback
		if not set then
			ptype = planet_types[1]
		end

		--choose specific planet
		local num = prand:next(1,ptype.rand_max)
		local set = false
		local cum = 0
		for i=#ptype,1,-1 do
			cum = ptype[i].rarity + cum
			if num <= cum then
				ptype = ptype[i]
				set = true
				break
			end
		end
		--If no suitable number of points is found, 1 is set as a fallback
		if not set then
			ptype = ptype[1]
		end

		point.ptype = ptype
	end
	planetoids.cache[hash] = points 
	return points
end

--removes points from sector which collide with those in comp
--tries to shrink first
local function point_remover(sector,comp)
	local get_dist = planetoids.settings.get_dist
	for index,point in ipairs(sector) do
		for _,comp_point in ipairs(comp) do
				local dist = get_dist(point.pos,comp_point.pos)
			if comp_point.radius + point.radius > dist then
				point.radius = dist - comp_point.radius - 2
				if point.radius 
				< planetoids.settings.planet_size.minimum then
					point.radius = -math.huge
				end
			end
		end
	end
	--remove all invalid points
	for index=#sector,1,-1 do
		while (sector[index] and sector[index].radius == -math.huge) do
			table.remove(sector,index)
		end
	end
end

--returns true is sector has a higher precience than comp
--or both are the same value
local function sector_precidence(sector,comp)
	if sector.x ~= comp.x then
		if sector.x % 2 == 0 then
			return true
		else
			return false
		end
	elseif sector.y ~= comp.y then
		if sector.y % 2 == 0 then
			return true
		else
			return false
		end
	elseif sector.z ~= comp.z then
		if sector.z % 2 == 0 then
			return true
		else
			return false
		end
	end
	return true
end

local function remove_collisions(sector,source)
	local hash =  hash_pos(sector)
	local this_sector = source[hash]
	local comp = {x=0,y=0,z=0}
	for i=sector.x-1,sector.x+1 do
		local hash_x = i + 32768
		comp.x = i
		for j=sector.y-1,sector.y+1 do
			local hash_y = (j + 32768) * 65536
			comp.y = j
			for l=sector.z-1,sector.z+1 do
				comp.z = l
				local hash_z = (l + 32768) * 65536 * 65536
				if not sector_precidence(sector,comp) then
					local comp_sector = source[hash_z + hash_y + hash_x]
					if comp_sector then
						point_remover(this_sector,comp_sector)
					end
				end
			end
		end
	end
end

local function generate_point_area(minp,maxp,seed)
	local min_sector = pos_to_sector(minp)
	local max_sector = pos_to_sector(maxp)
	local sectors = {}
	--populate table with sectors
	for i=min_sector.x-2,max_sector.x+2 do
		local hash_x = i + 32768
		for j=min_sector.y-2,max_sector.y+2 do
			local hash_y = (j + 32768) * 65536
			for l=min_sector.z-2,max_sector.z+2 do
				local hash_z = (l + 32768) * 65536 * 65536
				sectors[hash_z + hash_y + hash_x] = generate_decorated_points({x=i,y=j,z=l},seed)
			end
		end
	end
	--Remove colliding points
	for i=min_sector.x-1,max_sector.x+1 do
		for j=min_sector.y-1,max_sector.y+1 do
			for l=min_sector.z-1,max_sector.z+1 do
				remove_collisions({x=i,y=j,z=l},sectors)
			end
		end
	end
	--return the table - still hashed for use in later functions
	return sectors
end


local generate_block = function(blocksize,blockcentre,blockmin,seed,source,byot)
	local points = {}
	local block = byot or {}
	local index = 1
	local geo = planetoids.settings.geometry
	local blockmax = {x=blockmin.x+(blocksize.x-1),y=blockmin.y+(blocksize.y -1)
		,z=blockmin.z+(blocksize.z-1)}
	local sector = pos_to_sector(blockcentre)
	local get_dist = planetoids.settings.get_dist
	local cube_max_dist = get_dist(blockmin,blockcentre)
	-- points in moore raduis
	local x,y,z = -1,-1,-1
	for i=1,27 do
		if x > 1 then
			x = -1
			y = y + 1
		end
		if y > 1 then
			y = -1
			z = z + 1
		end

		local temp = source[hash_pos({x=sector.x+x,y=sector.y+y,z=sector.z+z})]
		for i,v in ipairs(temp) do
			local dist = get_dist(blockcentre,v.pos)
			if dist < v.radius + cube_max_dist then
				points[index] = v
				v.dist = dist
				index = index + 1
			end
		end
		x = x + 1

	end
	
	if #points == 0 then
		local tablesize = blocksize.x*blocksize.y*blocksize.z
		local x,y,z = blockmin.x,blockmin.y,blockmin.z
		for i = 1,tablesize do
			if x > blockmax.x then
				x = blockmin.x
				y = y + 1
			end
			if y > blockmax.y then
				y = blockmin.y
				z = z + 1
			end
			block[i] = air
			x = x + 1
		end
	else
		local tablesize = blocksize.x*blocksize.y*blocksize.z
		local x,y,z = blockmin.x,blockmin.y,blockmin.z
		for i = 1,tablesize do
			if x > blockmax.x then
				x = blockmin.x
				y = y + 1
			end
			if y > blockmax.y then
				y = blockmin.y
				z = z + 1
			end
			block[i] = find_node({x=x,y=y,z=z}
				,points,get_dist)
			x = x + 1
		end
	end
	return block
end

local shared_block_byot = {}

--map is generated in blocks
--this allows for distance testing to reduce the number of points to test
local get_biome_map_3d_experimental = function(minp,maxp,seed,byot)
	--normal block size
	local blsize = planetoids.settings.blocksize or {x=5,y=5,z=5}
	local halfsize = {x=blsize.x/2,y=blsize.y/2,z=blsize.z/2}
	local centre = {x=minp.x+halfsize.x,y=minp.y+halfsize.y,z=minp.z+halfsize.z}
	--the size of this block
	local blocksize = {x=blsize.x,y=blsize.y,z=blsize.z}
	local blockmin = {x=minp.x,y=minp.y,z=minp.z}
	local mapsize = {x=maxp.x-minp.x+1,y=maxp.y-minp.y+1,z=maxp.z-minp.z+1}
	--bring your own table - reduce garbage collections
	local map = byot or {}
	local block_byot = nil
	if byot then
		block_byot = shared_block_byot
	end

	local source = generate_point_area(minp,maxp,seed)
	for z=minp.z,maxp.z,blsize.z do
		centre.z = z + halfsize.z
		blockmin.z = z
		if z + (blsize.z - 1) > maxp.z then
			blocksize.z = blsize.z - ((z + (blsize.z - 1)) - maxp.z)
			centre.z = z + blocksize.z/2
		end
		for y=minp.y,maxp.y,blsize.y do
			centre.y = y + halfsize.y
			blockmin.y = y
			if y + (blsize.y - 1) > maxp.y then
				blocksize.y = blsize.y - ((y + (blsize.y - 1)) - maxp.y)
				centre.y = y + blocksize.y/2
			end
			for x=minp.x,maxp.x,blsize.x do
				centre.x = x + halfsize.x
				blockmin.x = x
				if x + (blsize.x - 1) > maxp.x then
					blocksize.x = blsize.x - ((x + (blsize.x -1)) - maxp.x)
					centre.x = x + blocksize.x/2
				end
				local temp = generate_block(blocksize,centre,blockmin
					,seed,source,block_byot)
				local blockstart = blockmin.x - minp.x + 1
					+ (blockmin.y - minp.y)*mapsize.x 
					+ (blockmin.z - minp.z)*mapsize.x*mapsize.y 
				blockfiller(temp,blocksize,map,mapsize,blockstart)
			end
		end
	end

	return map
end

planetoids.experimental_3d = get_biome_map_3d_experimental

--This function can be used to scale any compliant 3d map generator
--This adds an extra overhead - but this is negligable
local scale_3d_map_flat = function(minp,maxp,seed,map_gen,byot,scale_byot)
	local scale = planetoids.settings.scale
	local minp,rmin = minp,minp
	local maxp,rmax = maxp,maxp
	if scale then
		minp = {x=floor(minp.x/scale),y=floor(minp.y/scale)
			,z=floor(minp.z/scale)}
			--Replace def_table with map object
		maxp = {x=floor(maxp.x/scale),y=floor(maxp.y/scale)
			,z=floor(maxp.z/scale)}
	end

	local ret
	if scale then
		ret = scale_byot or {}
	else
		ret = byot or {}
	end

	ret = map_gen(minp,maxp,seed,ret)

	if scale then
		local nixyz = 1
		local scalxyz = 1
		local scalsidx = abs(maxp.x - minp.x) + 1
		local scalsidy = abs(maxp.y - minp.y) + 1
		local sx,sy,sz,ix,iy = 0,0,0,1,1
		local table_size = ((rmax.z - rmin.z) + 1)*((rmax.y - rmin.y) + 1)
			*((rmax.x - rmin.x) + 1)
		local x,y,z = rmin.x,rmin.y,rmin.z
		local newret = byot or {}
		for z=rmin.z,rmax.z do
		sy = 0
			for y=rmin.y,rmax.y do
			sx = 0
				for x=rmin.x,rmax.x do
					newret[nixyz] = ret[scalxyz]
					nixyz = nixyz + 1
					sx = sx + 1
					if sx == scale then
						scalxyz = scalxyz + 1
						sx = 0
					end
				end
				sy = sy + 1
				if sy ~= scale then
					scalxyz = ix
				else
					scalxyz = ix + scalsidx
					ix = scalxyz
					sy = 0
				end
			end
			sz = sz + 1
			if sz ~= scale then
				scalxyz = iy
				ix = iy
			else
				sz = 0
				scalxyz = iy + scalsidy*scalsidx
				iy = scalxyz
				ix = iy
			end
		end
		ret = newret
	end
	return ret
end

local shared_scale_byot = {}

--This is a single function which can be called to produce a biomemap
--for any layer type
--Attempts to choose the most optimal type for a given layer
--All scale code is condtional, so is safe to add to any mapgen
planetoids.get_map_flat = function(minp,maxp,seed,byot)
	local scale_byot = nil
	if byot then
		scale_byot = shared_scale_byot
	end

	local map_gen = get_biome_map_3d_experimental

	return scale_3d_map_flat(minp,maxp,seed,map_gen,byot,scale_byot)
end

planetoids.configure = function()
	local set = planetoids.settings

	--Default seed offset, to avoid errors layer where it is required
	set.seed_offset = set.seed_offset or 0

	--Number indexed table of biome names
	set.biomes = {}
	--Key indexed table of biomes - indexed by biome.name
	set.biome_settings ={}
	set.biome_number = 0
	--Layer object member functions
	set.get_biome_list = function(self,to_get)
		return self.biomes
	end

	--setup random functions
	local sum = 0
	for i=#point_dist,0,-1 do
		if point_dist[i] then
			sum = point_dist[i] + sum
		end
	end
	set.point_distribution.rand_max = sum

	--setup surface population table
	set.pop = {}
	for _,node_table in ipairs(set.surface_populator) do
		local inner_sum = 0
		for _,rep_table in ipairs(node_table) do
				--change node names to node ids
				rep_table.node = minetest.get_content_id(rep_table.node)

				inner_sum = inner_sum + rep_table.rarity
		end

		node_table.rand_max = inner_sum
		node_table.rarity = node_table.population_chance * 10000
		set.pop[minetest.get_content_id(node_table.node)] = node_table
	end


	sum = 0
	for i,v in ipairs(set.planet_types) do
		local inner_sum = 0
		for j,w in ipairs(v) do
			--change node names to node ids
			if w.crust_material then
				w.crust_material = minetest.get_content_id(w.crust_material)
			end
			if w.crust_top_material then
				w.crust_top_material = minetest.get_content_id(w.crust_top_material)
			end
			if w.filling_material then
				w.filling_material = minetest.get_content_id(w.filling_material)
			end

			inner_sum = inner_sum + w.rarity
		end
		v.rand_max = inner_sum

		sum = sum + v.rarity
	end

	set.planet_types.rand_max = sum
	--setup scale factor
	if set.planet_size.sector_scale < 2 then
		set.planet_size.sector_scale = 2
	end
	--setup sector lengths
	local length = set.planet_size.maximum * set.planet_size.sector_scale
	set.sector_lengths = {x=length,y=length,z=length}
	
	--setup geometry function
	set.dist = planetoids.geometry[set.geometry]
	set.get_dist = set.dist._3d

	--variable to track wether the noise maps have been initialised
	if set.biome_maps then
		set.maps_init = false
	else
		set.maps_init = true
	end

	--setup layer cache to chache generated points
	set.cache = setmetatable({},planetoids.meta_cache)
	planetoids.cache = set.cache
end

planetoids.meta_cache = {
	__mode = "v",
}

dofile(minetest.get_modpath("planetoids").."/settings.lua")


--MAPGEN

local c_air     = minetest.get_content_id("air")
local c_ignore  = minetest.get_content_id("ignore")
local c_error   = minetest.get_content_id("default:obsidian")
local c_leaves   = minetest.get_content_id("default:leaves")
local c_tree   = minetest.get_content_id("default:tree")

--Bring your own table for voronoi noise
local planets = {}




minetest.register_on_generated(function(minp, maxp, seed)
	local pr = PseudoRandom(seed)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()

	local side_length = math.abs(maxp.x - minp.x) + 1
	local biglen = side_length+32

	local chulens = {x=side_length, y=side_length, z=side_length}

	if not map_seed then
		map_seed = minetest.get_mapgen_params().seed
	end

	local planets = planets
	planets = planetoids.get_map_flat(minp,maxp,map_seed,planets)
	local set = planetoids.settings

	local nixyz = 1
	local nixz = 1
	for z = minp.z,maxp.z do
		for y = minp.y,maxp.y do
			local vi = area:index(minp.x,y,z)
			for x = minp.x,maxp.x do
				if planets[nixyz] == c_air then
				elseif planets[nixyz] ~= c_ignore then
					data[vi] = planets[nixyz]
					--simple population
					local pop = set.pop[planets[nixyz]]
					if set.surface_populator.enabled and pop and y < maxp.y 
					and planets[nixyz+side_length] == c_air 
					and math.random(1,10000) < pop.rarity then
						local num = math.random(1,pop.rand_max)
						local cum = 0
						for i=#pop,1,-1 do
							cum = pop[i].rarity + cum
							if num <= cum then
								data[area:index(x,y+1,z)] = pop[i].node
								break
							end
						end
					end
				else
					data[vi] = c_error
				end

				nixyz = nixyz + 1
				nixz = nixz + 1
				vi = vi + 1
			end
			nixz = nixz - side_length
		end
		nixz = nixz + side_length
	end
	vm:set_data(data)
	vm:set_lighting({day=15, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
end)

minetest.register_on_generated(function(minp, maxp, seed)
	local pr = PseudoRandom(seed)
	local max = planetoids.settings.planet_size.maximum
	if minp.x > max or maxp.x < -max or
	minp.z > max or maxp.z < -max or
	minp.y > 0 or maxp.y < -2 * max then
		return
	end

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()

	local side_length = math.abs(maxp.x - minp.x) + 1

	if not map_seed then
		map_seed = minetest.get_mapgen_params().seed
	end

	local get_dist = planetoids.settings.get_dist
	local centre = {x=0,y=-max,z=0}
	local pos = {x=0,y=0,z=0}

	local nixyz = 1
	local nixz = 1
	for z = minp.z,maxp.z do
		pos.z = z
		for y = minp.y,maxp.y do
			pos.y = y
			local vi = area:index(minp.x,y,z)
			for x = minp.x,maxp.x do
				pos.x = x
				local dist = get_dist(pos,centre)
				if dist < max then
					if dist < max - 2 then
						data[vi] = c_tree
					else
						data[vi] = c_leaves
					end
				end

				nixyz = nixyz + 1
				nixz = nixz + 1
				vi = vi + 1
			end
			nixz = nixz - side_length
		end
		nixz = nixz + side_length
	end
	vm:set_data(data)
	vm:set_lighting({day=15, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
end)
