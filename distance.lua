planetoids.geometry = {}

local geo = planetoids.geometry

local abs = math.abs
local floor = math.floor
local hash_pos = minetest.hash_node_position

local function greatest(x,y,z)
	if x>y then
		if x>z then
			return x
		else
			return z
		end
	else
		if y>z then
			return y
		else
			return z
		end
	end
end


geo.manhattan = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return x+z
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return x+y+z
	end,
}

geo.chebyshev = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return greatest(x,0,z)
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return greatest(x,y,z)
	end,
}

geo.euclidean = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return math.sqrt((x*x)+(z*z))
	end,
	_2d_fast = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return (x*x)+(z*z)
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return math.sqrt((x*x)+(y*y)+(z*z))
	end,
	_3d_fast = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return (x*x)+(y*y)+(z*z)
	end,
}

geo.oddprod = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		if x <= 1 then
			x=1
		end
		if z <= 1 then
			z=1
		end
		return abs(x*z)
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		if x <= 1 then
			x=1
		end
		if y <= 1 then
			y=1
		end
		if z <= 1 then
			z=1
		end
		return abs(x*y*z)
	end,
}

local get_distance_function = function (geometry, dimensions)
	if geo[geometry] then
		if dimensions == 3 then
			return geo[geometry]._3d
		else
			return geo[geometry]._2d
		end
	else
		return nil
	end
end

planetoids.get_distance_function = get_distance_function
