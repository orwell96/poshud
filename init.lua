--Simple head-up display for current position, time and server lag.

-- Origin:
--ver 0.2.1 minetest_time

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------Minetest Time--kazea's code tweaked by cg72 with help from crazyR--------
----------------Zeno` simplified some math and additional tweaks ---------------
--------------------------------------------------------------------------------

poshud = {
	-- Position of hud
	posx = tonumber(minetest.settings:get("poshud.hud.offsetx") or 0.8),
	posy = tonumber(minetest.settings:get("poshud.hud.offsety") or 0.95)
}

--settings

colour = 0xFFFFFF  --text colour in hex format default is white
enable_star = true


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local player_hud = {}

local function generatehud(player)
	local name = player:get_player_name()
	local hud = {}
	hud.id = player:hud_add({
		hud_elem_type = "text",
		name = "poshud",
		position = {x=poshud.posx, y=poshud.posy},
		offset = {x=8, y=-8},
		text = "Initializing...",
		scale = {x=100,y=100},
		alignment = {x=1,y=0},
		number = colour, --0xFFFFFF,
	})
	player_hud[name] = hud
end
local function updatehud(player, text)
	local name = player:get_player_name()
	if not player_hud[name] then
		generatehud(player)
	end
	local hud = player_hud[name]
	if hud and text ~= hud.text then
		player:hud_change(hud.id, "text", text)
		hud.text = text
	end
end
local function removehud(player)
	local name = player:get_player_name()
	if player_hud[name] then
		player:hud_remove(player_hud[name].id)
	end
end
minetest.register_on_joinplayer(function(player)
	minetest.after(0,generatehud,player)
end)
minetest.register_on_leaveplayer(function(player)
		minetest.after(1,removehud,player)
end)

-- time
-- from https://gitlab.com/Rochambeau/mthudclock/blob/master/init.lua

local function floormod ( x, y )
	return (math.floor(x) % y);
end

local function get_time()
	local secs = (60*60*24*minetest.get_timeofday());
	local s = floormod(secs, 60);
	local m = floormod(secs/60, 60);
	local h = floormod(secs/3600, 60);
	return ("%02d:%02d"):format(h, m);
end

-- rotating star
local star={"\\", "|", "/", "-"}


-- Lag counters
-- adaption weights for averages
local w_avg1, w_avg2 = 0.001, 0.001
local dec_max = 0.99995

local ow_avg1, ow_avg2 = 1-w_avg1, 1-w_avg2
local l_avg1, l_avg2, l_max = 0.1, 0.1, 0.1
local h_text = "Initializing..."
local h_int = 2
local h_tmr = 0

local starc = 0

minetest.register_globalstep(function (dtime)
	-- make a lag sample
	l_avg1 = w_avg1*dtime  + ow_avg1*l_avg1
	l_avg2 = w_avg2*l_avg1 + ow_avg2*l_avg2
	l_max = math.max(l_max*dec_max, dtime)
	
	-- update hud text when necessary
	if h_tmr <= 0 then
		-- Update hud text that is the same for all players
		local s_lag = string.format("Lag: avg: %.2f (%.2f) max: %.2f", l_avg1, l_avg2, l_max)
		local s_time = "Time: "..get_time()
		
		local s_star = ""
		if enable_star then
			s_star = star[starc+1]
			starc = (starc + 1) % 4
		end
		
		h_text = s_time .. "   " .. s_star .. "\n" .. s_lag
		
		h_tmr = h_int
	else
		h_tmr = h_tmr - dtime
	end
	
	for _,player in ipairs(minetest.get_connected_players()) do
		local posi = player:get_pos()
		local posistr = math.floor(posi.x+0.5).." "..math.floor(posi.y+0.5).." "..math.floor(posi.z+0.5)
		updatehud(player, h_text.."\nPos: "..posistr)
	end
end);
