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

local find_closest = function(pos,points,dist_func)
	local dist = nil
	local mini = math.huge
	local biome = nil
	for i=1,#points do
		local point = points[i]
		dist = dist_func(pos,point.pos)
		if dist < mini then
			mini = dist
			biome = point.biome
		end
	end
	return biome
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
	local num = prand:next(point_dist.random_min,point_dist.random_max)
	local set = false
	for i=#point_dist,1,-1 do
		if num >= point_dist[i] then
			num = i
			set = true
			break
		end
	end

	--If no suitable number of points is found, 1 is set as a fallback
	if not set then
		num = 1
	end

	--Generate each point
	local seen = {}
	local points = {}
	while num > 0 do
		--The points are aligned to 0.1 of a block
		--This used to be to 1 block, but having multiple points at
		--the same distance was causing artifacts with the experimental gen
		local x = prand:next(0,(planetoids.settings.sector_lengths.x-1)*10)
		local y = prand:next(0,(planetoids.settings.sector_lengths.y-1)*10)
		local z = prand:next(0,(planetoids.settings.sector_lengths.z-1)*10)
		local pos = {x=x/10,y=y/10,z=z/10}
		local hashed = hash_pos(pos)
		if not seen[hashed] then
			pos = vector_add(pos,sector_to_pos(sector))
			table.insert(points,pos)
			seen[hashed] = pos
		end
		num = num - 1
	end
	--The random number generator is returned for use in adding other 
	--properties to the points - biomes
	return points , prand
end

--This function is used to get the maps required for generate_biomed_points below
--The in-built maps have to be treated differently to the custom ones, as no
--extra data can be stored in the perlin map userdata
local function get_point_maps(point)
	local maps = {}
	for i,v in ipairs(planetoids.settings.biome_maps) do
		if v.perlin then
			if v.dims == 3 then
				maps[i] = v.perlin:get3d(point)
			else
				local point = {x=point.x,y=point.z}
				maps[i] = v.perlin:get2d(point)
			end
		else
			maps[i] = v:get_noise(point)
		end
	end
	return maps
end

--This is a wrapper around generate_points - this adds biomes and doesn't return the random
--number generator
local generate_biomed_points = function(sector,seed)
	local hash = hash_pos(sector)
	--This is a cache for storing points that were already generated
	--this should improve performance - but profiling breaks it
	if planetoids.cache[hash] then
		return planetoids.cache[hash]
	end
	local points,prand = generate_points(sector,seed,layer)
	local biome_types = planetoids.settings.biome_types
	local ret = {}
	for i=1,#points do
		local point = points[i]
		local biome = nil
		local maps = nil
		for method=1,#biome_types do
			local biome_meth = biome_types[method]
			if biome_meth == "random" then
				local num = prand:next(1,--[[TODO]])
				biome = planetoids.settings.biomes[num]
			elseif biome_meth == "multi-map" then
				if not maps then
					maps = get_point_maps(point)
				end
				local min_dist = math.huge
				for j,k in ipairs(planetoids.settings.biome_defs) do
					local this_dist = 0
					for l,m in ipairs(maps) do
						this_dist = this_dist + abs(k[l] - m)
					end
					if this_dist < min_dist then
						biome = k.name
						min_dist = this_dist
					end
				end
			elseif biome_meth == "multi-tolerance-map" then
				local tol = planetoids.settings.tolerance
				if not maps then
					maps = get_point_maps(point)
				end
				local biomes = {}
				for j,k in ipairs(planetoids.settings.biome_defs) do
					local add = true
					for l,m in ipairs(maps) do
						local diff = abs(k[l] - m)
						if diff > tol[l] then
							add = false
							break
						end
					end
					if add then
						table.insert(biomes,k)
					end
				end
				local bionum = #biomes
				if bionum ~= 0 then
					biome = biomes[prand:next(1,bionum)].name
				end
			else
				biome = biome_meth
			end
			if biome then
				break
			end
		end
		table.insert(ret,{
			pos = point,
			biome = biome,
		})
	end
	planetoids.cache[hash] = ret 
	return ret
end

local generate_block = function(blocksize,blockcentre,blockmin,seed,byot)
	local points = {}
	local block = byot or {}
	local index = 1
	local geo = planetoids.settings.geometry
	local blockmax = {x=blockmin.x+(blocksize.x-1),y=blockmin.y+(blocksize.y -1)
		,z=blockmin.z+(blocksize.z-1)}
	local sector = pos_to_sector(blockcentre)
	local get_dist = planetoids.settings.get_dist
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
		local temp = generate_biomed_points(vector_add(sector,{x=x,y=y,z=z})
			,seed)
		for i,v in ipairs(temp) do
			points[index] = v
			v.dist = get_dist(blockcentre,v.pos)
			index = index + 1
		end
		x = x + 1
	end
	
	table.sort(points,function(a,b) return a.dist < b.dist end) 
	local to_nil = false
	local max_dist = points[1].dist + get_dist(blockmin,blockcentre)
	for i=1,#points do
		if to_nil then
			points[i] = nil
		elseif points[i].dist > max_dist then
			to_nil = true
		end
	end
	--Switch to fast distance type when doing comparison only calcs
	get_dist = planetoids.settings.get_dist_fast
	if #points == 1 then
		local tablesize = blocksize.x*blocksize.y*blocksize.z
		local x,y,z = blockmin.x,blockmin.y,blockmin.z
		local biome = point[1].biome
		for i = 1,tablesize do
			if x > blockmax.x then
				x = blockmin.x
				y = y + 1
			end
			if y > blockmax.y then
				y = blockmin.y
				z = z + 1
			end
			block[i] = biome
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
			block[i] = find_closest({x=x,y=y,z=z}
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
	local blsize = planetoids.settigns.blocksize or {x=5,y=5,z=5}
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
					,seed,block_byot)
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

local function init_maps()
	--Setup layer maps if there are any
	for map_index,def_table in ipairs(planetoids.settings.biome_maps) do
		--Add layer offset to map seed offset
		if def_table.seed_offset then
			def_table.seed_offset = def_table.seed_offset + planetoids.settings.seed_offset
		end
		--Variable to contruct the final map object
		local biome_map = nil
		--The noise type is solely detrmined by the map_type
		if def_table.map_type == "perlin" then
			biome_map = {}
			biome_map.dimensions = def_table.dimensions or 2
			biome_map.perlin = minetest.get_perlin(def_table)
		else
			biome_map = planetoids.get_map_object(def_table)
		end
		--Replace def_table with map object
		planetoids.settings.biome_maps[map_index] = biome_map
	end
	planetoids.settings.maps_init = true
end


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

	if not planetoids.maps_init then
		init_maps()
	end
	
	local map_gen = get_biome_map_3d_experimental

	return scale_3d_map_flat(minp,maxp,seed,map_gen,byot,scale_byot)
end

planetoids.configure = function(settings)
	planetoids.settings = settings
	local set = planetoids.settings

	--Default seed offset, to avoid errors layer where it is required
	set.seed_offset = set.seed_offset or 0

	--Number indexed table of biome names
	set.biomes = {}
	--Key indexed table of biomes - indexed by biome.name
	set.biome_settingss ={}
	set.biome_number = 0
	--Layer object member functions
	set.get_biome_list = function(self,to_get)
		return self.biomes
	end
	--setup geometry function
	set.dist = planetoids.geometry[set.geometry]

	--setup random functions
	local sum = 0
	for i,v in ipairs(set.point_distribution) do
		sum = sum + v
	end
	set.point_distribution.rand_max = sum

	sum = 0
	for i,v in ipairs(set.planet_types) do
		local inner_sum = 0
		for j,w in ipairs(v) do
			inner_sum = inner_sum + w.rarity
		end
		v.rand_max = inner_sum

		sum = sum + v.rarity
	end

	set.planet_types.rarity = sum
		
	
	set.get_dist = set.dist._3d
	set.get_dist_fast = set.dist._3d_fast or set.get_dist

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
