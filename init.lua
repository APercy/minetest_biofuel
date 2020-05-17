----------
--biofuel
----------

local modname = "biofuel"

if minetest.get_modpath("technic") then
    if technic then
	    technic.register_extractor_recipe({input = {"farming:wheat 33"}, output = "biofuel:biofuel 1"})
	    technic.register_extractor_recipe({input = {"farming:corn 33"}, output = "biofuel:biofuel 1"})
	    technic.register_extractor_recipe({input = {"farming:potato 33"}, output = "biofuel:biofuel 1"})
	    technic.register_extractor_recipe({input = {"default:papyrus 99"}, output = "biofuel:biofuel 1"})
    end
end


if minetest.get_modpath("basic_machines") then
    if basic_machines then
	    basic_machines.grinder_recipes["farming:wheat"] = {50,"biofuel:biofuel",1}
	    basic_machines.grinder_recipes["farming:corn"] = {50,"biofuel:biofuel",1}
	    basic_machines.grinder_recipes["farming:potato"] = {50,"biofuel:biofuel",1}
	    basic_machines.grinder_recipes["default:papyrus"] = {70,"biofuel:biofuel",1}
    end
end

if minetest.get_modpath("default") then
	--[[minetest.register_craft({
		output = modname .. ":biofuel",
		recipe = {
			{"",              "farming:wheat"},
			{"farming:wheat", "farming:wheat"},
		}
	})]]--
	minetest.register_craft({
		output = modname .. ":biofuel_distiller",
		recipe = {
			{"default:copper_ingot", "default:copper_ingot", "default:copper_ingot"},
			{"default:steel_ingot" , "",                     "default:steel_ingot"},
			{"default:steel_ingot" , "default:steel_ingot",  "default:steel_ingot"},
		},
	})
end


-- biofuel
minetest.register_craftitem(modname .. ":biofuel",{
	description = "Bio Fuel",
	inventory_image = "biofuel_inv.png",
})

local ferment = {
	{"default:papyrus", modname .. ":biofuel"},
	{"farming:wheat", modname .. ":biofuel"},
	{"farming:corn", modname .. ":biofuel"},
	{"farming:baked_potato", modname .. ":biofuel"},
    {"farming:potato", modname .. ":biofuel"}
}

-- distiller
biofueldistiller_formspec = "size[8,9]"
	.. "list[current_name;src;2,1;1,1;]"
	.. "list[current_name;dst;5,1;1,1;]"
	.. "list[current_player;main;0,5;8,4;]"
	.. "listring[current_name;dst]"
	.. "listring[current_player;main]"
	.. "listring[current_name;src]"
	.. "listring[current_player;main]"
	.. "image[3.5,1;1,1;gui_furnace_arrow_bg.png^[transformR270]"

minetest.register_node( modname .. ":biofuel_distiller", {
	description = "Biofuel Distiller",
	tiles = {"metal.png", "aluminum.png", "copper.png" },
	drawtype = "mesh",
	mesh = "biofuel_distiller.b3d",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		choppy = 2, oddly_breakable_by_hand = 1, flammable = 2
	},
	legacy_facedir_simple = true,

	on_place = minetest.rotate_node,

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		meta:set_string("formspec", biofueldistiller_formspec)
		meta:set_string("infotext", "Biofuel Distiller")
		meta:set_float("status", 0.0)

		local inv = meta:get_inventory()

		inv:set_size("src", 1)
		inv:set_size("dst", 1)
	end,

	can_dig = function(pos,player)

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if not inv:is_empty("dst")
		or not inv:is_empty("src") then
			return false
		end

		return true
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		return stack:get_count()
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if listname == "src" then
			return stack:get_count()
		elseif listname == "dst" then
			return 0
		end
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)

		if minetest.is_protected(pos, player:get_player_name()) then
			return 0
		end

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)

		if to_list == "src" then
			return count
		elseif to_list == "dst" then
			return 0
		end
	end,

	on_metadata_inventory_put = function(pos)

		local timer = minetest.get_node_timer(pos)

		timer:start(5)
	end,

	on_timer = function(pos)

		local meta = minetest.get_meta(pos) ; if not meta then return end
		local inv = meta:get_inventory()

		-- is barrel empty?
		if not inv or inv:is_empty("src") then

			meta:set_float("status", 0.0)
			meta:set_string("infotext", "Fuel Distiller")

			return false
		end

		-- does it contain any of the source items on the list?
		local has_item

		for n = 1, #ferment do

			if inv:contains_item("src", ItemStack(ferment[n][1])) then

				has_item = n

				break
			end
		end

		if not has_item then
			return false
		end

		-- is there room for additional fermentation?
		if not inv:room_for_item("dst", ferment[has_item][2]) then

			meta:set_string("infotext", "Fuel Distiller (FULL)")

			return true
		end

		local status = meta:get_float("status")

		-- fermenting (change status)
		if status < 100 then
			meta:set_string("infotext", "Fuel Distiller " .. status .. "% done")
			meta:set_float("status", status + 5)
		else
			inv:remove_item("src", ferment[has_item][1])
			inv:add_item("dst", ferment[has_item][2])

			meta:set_float("status", 0,0)
		end

		if inv:is_empty("src") then
			meta:set_float("status", 0.0)
			meta:set_string("infotext", "Fuel Distiller")
		end

		return true
	end,
})

