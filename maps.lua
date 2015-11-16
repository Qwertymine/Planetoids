--This file contains a list of simple custom maps
--These are to replace the old custom map model, and for optimisation
planetoids.maps = {}
local maps = planetoids.maps

--Height Maps
local get_height = function(pos)
	return pos.y
end

local scale = function(value,scale)
	return value*scale
end

local centre_height = function(value,centre)
	return value-centre
end

local zero = function()
	return 0
end

maps.height_map = {
	get3d = function(self,pos)
		return get_height(pos)
	end,
	get2d = zero,
	construct = function()
		return
	end,
}
maps.scaled_height_map = {
	get3d = function(self,pos)
		return scale(pos.y,self.scale)
	end,
	get2d = zero,
	construct = function(self,def)
		self.scale = def.scale
		return
	end
}
maps.centred_height_map = {
	get3d = function(self,pos)
		return centre_height(pos.y,self.centre)
	end,
	get2d = zero,
	construct = function(self,def)
		self.centre = def.centre
		return
	end,
}
maps.scaled_centred_height_map = {
	get3d = function(self,pos)
		return scale(centre_height(pos.y,self.centre),self.scale)
	end,
	get2d = zero,
	construct = function(self,def)
		self.centre = def.centre
		self.scale = def.scale
		return
	end,
}

--Distance functions

maps.centred_distance = {
	get3d = function(self,pos)
		return self.get_dist(self.centre,pos)
	end,
	get2d = function(self,pos)
		return self.get_dist(self.centre,pos)
	end,
	construct = function(self,def)
		self.dimensions = def.dimensions
		self.geometry = def.geometry
		self.centre = def.centre or {x=0,y=0,z=0}
		self.get_dist = planetoids.get_distance_function(self.geometry
			,self.dimensions)
	end,
}

maps.scaled_centred_distance = {
	get3d = function(self,pos)
		return scale(self.get_dist(self.centre,pos),self.scale)
	end,
	get2d = function(self,pos)
		return scale(self.get_dist(self.centre,pos),self.scale)
	end,
	construct = function(self,def)
		self.dimensions = def.dimensions
		self.geometry = def.geometry
		self.centre = def.centre or {x=0,y=0,z=0}
		self.scale = def.scale
		self.get_dist = planetoids.get_distance_function(self.geometry
			,self.dimensions)
	end,
}

local get_map_object = function(map_def)
	local object = {}
	--Get the map type, and fail if none exists
	local noise_map = maps[map_def.map_type]
	--Choose function to load based on dimensions given
	if map_def.dimensions == 3 then
		object.get_noise = noise_map.get3d
	else
		object.get_noise = noise_map.get2d
	end
	--Use the map constructor to initialise
	noise_map.construct(object,map_def)
	return object
end

planetoids.get_map_object = get_map_object

local register_map = function(map_def)
	if not planetoids.maps[map_def.name]
	and map_def.get3d
	and map_def.get2d
	and map_def.construct then
		planetoids.maps[map_def.name] = map_def
	end
end

planetoids.register_map = register_map
