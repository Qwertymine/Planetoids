local seed = minetest.get_mapgen_params().seed
minetest.register_craftitem("vcnlib:biome_wand", {
	description = "Biome Wand",
	inventory_image = "farming_tool_diamondhoe.png",
	on_place = function(itemstack, placer, pointed_thing)
		--test_biomed_points(pointed_thing.above)
		--minetest.chat_send_all((vcnlib.test))
		--minetest.chat_send_all(vcnlib.pos_to_sector(pointed_thing.above,vcnlib.test).x)
		local pos = pointed_thing.above
		local scale = vcnlib.layers.test.scale
		if scale then
			minetest.chat_send_all(vcnlib.get_node_biome(({x=math.floor(pos.x/scale),y=math.floor(pos.y/scale),z=math.floor(pos.z/scale)}),seed,vcnlib.layers.test))
		else
			minetest.chat_send_all(vcnlib.get_node_biome(pos,seed,vcnlib.layers.test))
		end
	end,
})

minetest.register_craft({
	output = "vcnlib:biome_wand",
	recipe = {
		{"default:diamond","default:diamond","default:diamond"},
		{"default:diamond","default:stick",  "default:diamond"},
		{"default:diamond","default:stick",  "default:diamond"},
	},
})
