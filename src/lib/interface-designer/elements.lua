--[[===============================================================
===================================================================]]
local module = {}

--[[===============================================================
===================================================================]]
module.gxt_texts = {}

module.clearAllGxtEntries = function ()
	require("interface-designer.globals").LoadData()
	local saved_data = require("interface-designer.globals").iDesgn.saved_data
	
	for key,value in pairs(saved_data) do
		local i, t = nil, value.texts
		for i = 1, #t do
			clearGxtEntry(t[i].gxt[1])
		end
	end
end

module.createAllDynamicGxtEntries = function (name)
	require("interface-designer.globals").LoadData()
	local saved_data = require("interface-designer.globals").iDesgn.saved_data
	
	local i, t = nil, saved_data[name].texts
	for i = 1, #t do
		setGxtEntry(t[i].gxt[1], t[i].gxt[2])
	end
end

module.addNewGxtEntry = function (key, text)
	setGxtEntry(key, text)
	table.insert(module.gxt_texts, {key, text})
end

module.doesDynamicGxtExist = function (texts_table, key)
	local i = nil
	for i = 1, #texts_table do
		if key == texts_table[i][1] then
			return true
		end
	end
	return false
end

--[[===============================================================
===================================================================]]
local color = function (flt)
	return math.floor(flt*255+0.5)
end

--[[===============================================================
===================================================================]]
module.textures_pointers = {}
module.textures_size_multipliers = {}

module.CreateTexture = function(texture_table)
	table.insert(module.textures, texture_table)
	local texture = renderLoadTextureFromFile(texture_table.path)
	table.insert(module.textures_pointers, texture)
	table.insert(module.textures_size_multipliers, 1)
end

module.releaseAllTextures = function ()
	local i, t = nil, module.textures_pointers
	for i = 1, #t do
		renderReleaseTexture(t[i])
	end
	module.textures_pointers = {}
end

module.renderAllTextures = function (name)
	require("interface-designer.globals").LoadData()
	local saved_data = require("interface-designer.globals").iDesgn.saved_data
	module.textures_size_multipliers = {}
	module.textures_pointers = {}
	
	local i, tex = nil, saved_data[name].textures
	print(encodeJson(tex))
	for i = 1, #tex do
		module.textures_pointers[i] = renderLoadTextureFromFile(tex[i].path)
		module.textures_size_multipliers[i] = 1
	end
end

local DrawTextures = function ()
	local rgbaToUint = require("interface-designer.utils").rgbaToUint
	local draw = 0
	for i = 1, #module.textures do
		local t, texture, s = module.textures[i], module.textures_pointers[i], module.textures_size_multipliers[i]
		if not t.hidden_flag then
			renderDrawTexture(texture, t.pos[1], t.pos[2], t.size[1]*s, t.size[2]*s, t.rotation,
				rgbaToUint(color(t.color[1]), color(t.color[2]), color(t.color[3]), color(t.color[4])))
		end
	end
end

--[[===============================================================
===================================================================]]
module.texts = {}

module.boxes = {}

module.textures = {}

module.CreateText = function(params)
	table.insert(module.texts, params)
	setGxtEntry(params.gxt[1], params.gxt[2])
end

module.CreateBox = function(params)
	table.insert(module.boxes, params)
end

module.Show = function()
	local DrawText = require("interface-designer.utils").DrawText
	local iDesgn = require("interface-designer.globals").iDesgn
	local i = nil
	
	-- Draw Texts
	for i = 1, #module.texts do
		local t = module.texts[i]
		if not t.hidden_flag then
			DrawText(t.font, t.linewidth, t.pos[1], t.pos[2], t.size[1], t.size[2], t.gxt[1], {
				use_center = t.use_center, center_linewidth = t.linewidth,
				align_right = t.align_right, align_justify = t.align_justify,
				enable_outline = t.enable_outline, outline = t.outline,
				customize_shadow = t.customize_shadow, shadow_size = t.shadow_size,
				r = color(t.r),
				g = color(t.g),
				b = color(t.b),
				a = color(t.a),
				outl_r = color(t.outl_r),
				outl_g = color(t.outl_g),
				outl_b = color(t.outl_b),
				outl_a = color(t.outl_a),
				sh_r = color(t.sh_r),
				sh_g = color(t.sh_g),
				sh_b = color(t.sh_b),
				sh_a = color(t.sh_a),
				background = iDesgn.linewidth_shadow_flag[0] or t.background, proportional = t.proportional
			})
		end
	end
	
	-- Draw Boxes
	for i = 1, #module.boxes do
		local b = module.boxes[i]
		if not b.hidden_flag then
			drawRect(b.pos[1], b.pos[2], b.size[1], b.size[2], color(b.color[1]), color(b.color[2]), color(b.color[3]), color(b.color[4]))
		end
	end
	
	--Draw Textures
	DrawTextures()
end

module.isGxtTextDefined = function (key)
	local i = nil
	for i = 1, #module.texts do
		local t = module.texts[i]
		if key == t.gxt[1] then
			return true
		end
	end
	return false
end

module.atLeastOneElementExists = function ()
	return (#module.texts > 0) or (#module.boxes > 0) or (#module.textures > 0)
end

module.Reset = function ()
	module.texts = {}
	module.clearAllGxtEntries()
	module.textures = {}
	module.releaseAllTextures()
	module.boxes = {}
end

module.GetBoxesDataPointers = function (b)
	local I = require 'mimgui'
	local new = I.new
	
	local box_pos = new.float[2](b.pos[1], b.pos[2])
	local box_size = new.float[2](b.size[1], b.size[2])
	local box_color = new.float[4](b.color[1], b.color[2], b.color[3], b.color[4])
	local box_show = new.bool(not b.hidden_flag)
	
	return box_pos, box_size, box_color, box_show
end

module.UpdateBoxesData = function (b, box_pos, box_size, box_color, box_show)
	b.pos[1], b.pos[2] = box_pos[0], box_pos[1]
	b.size[1], b.size[2] = box_size[0], box_size[1]
	b.color[1], b.color[2], b.color[3], b.color[4] = box_color[0], box_color[1], box_color[2], box_color[3]
	b.hidden_flag = not box_show[0]
end

module.GetTextsDataPointers = function (t)
	local I = require 'mimgui'
	local new = I.new
	return {
		font 				= new.int(t.font),
		linewidth 			= new.float(t.linewidth),
		pos 				= new.float[2](t.pos[1], t.pos[2]),
		size 				= new.float[2](t.size[1], t.size[2]),
		center_flag 		= new.bool(t.use_center),
		align_right_flag 	= new.bool(t.align_right),
		justify 			= new.bool(t.align_justify),
		outline_flag 		= new.bool(t.enable_outline),
		shadow_flag 		= new.bool(t.customize_shadow),
		outline_value 		= new.int(t.outline),
		shadow_value 		= new.int(t.shadow_size),
		font_color 			= new.float[4](t.r, t.g, t.b, t.a),
		shadow_color 		= new.float[4](t.sh_r, t.sh_g, t.sh_b, t.sh_a),
		background 			= new.bool(t.background),
		proportional 		= new.bool(t.proportional),
		show_flag 			= new.bool(not t.hidden_flag),
	}
end

module.UpdateTextsData = function (t, t_ptr)
	t.font									= t_ptr.font[0]
	t.linewidth								= t_ptr.linewidth[0]
	t.pos[1], t.pos[2]						= t_ptr.pos[0], t_ptr.pos[1]
	t.size[1], t.size[2]					= t_ptr.size[0], t_ptr.size[1]
	t.use_center							= t_ptr.center_flag[0]
	t.align_right							= t_ptr.align_right_flag[0]
	t.align_justify							= t_ptr.justify[0]
	t.enable_outline						= t_ptr.outline_flag[0]
	t.customize_shadow						= t_ptr.shadow_flag[0]
	t.outline								= t_ptr.outline_value[0]
	t.shadow_size							= t_ptr.shadow_value[0]
	t.r, t.g, t.b, t.a						= t_ptr.font_color[0], t_ptr.font_color[1], t_ptr.font_color[2], t_ptr.font_color[3]
	t.outl_r, t.outl_g, t.outl_b, t.outl_a	= t_ptr.shadow_color[0], t_ptr.shadow_color[1], t_ptr.shadow_color[2], t_ptr.shadow_color[3]
	t.sh_r, t.sh_g, t.sh_b, t.sh_a			= t_ptr.shadow_color[0], t_ptr.shadow_color[1], t_ptr.shadow_color[2], t_ptr.shadow_color[3]
	t.background							= t_ptr.background[0]
	t.proportional							= t_ptr.proportional[0]
	t.hidden_flag							= not t_ptr.show_flag[0]
end

module.Text = {}
module.Box = {}
module.Texture = {}

module.Text.CopyToClipboard = function (text)
	local clipboard = require("interface-designer.globals").iDesgn.clipboard
	clipboard = {
		text = {
			font 				= text.font,
			linewidth 			= text.linewidth,
			pos 				= {text.pos[1], text.pos[2]},
			size 				= {text.size[1], text.size[2]},
			center_flag 		= text.use_center,
			align_right_flag 	= text.align_right,
			justify 			= text.align_justify,
			outline_flag 		= text.enable_outline,
			shadow_flag 		= text.customize_shadow,
			outline_value 		= text.outline,
			shadow_value 		= text.shadow_size,
			font_color 			= {text.r, text.g, text.b, text.a},
			shadow_color 		= {text.sh_r, text.sh_g, text.sh_b, text.sh_a},
			background 			= text.background,
			proportional 		= text.proportional,
			hidden_flag			= text.hidden_flag,
		}
	}
	require("interface-designer.globals").iDesgn.clipboard = clipboard
end

module.Text.PasteFromClipboard = function (text)
	local clipboard = require("interface-designer.globals").iDesgn.clipboard
	if clipboard.text ~= nil then
		local ct = clipboard.text
		text.font						= ct.font
		text.linewidth					= ct.linewidth
		text.pos[1], text.pos[2]		= ct.pos[1], ct.pos[2]
		text.size[1], text.size[2]		= ct.size[1], ct.size[2]
		text.use_center					= ct.center_flag
		text.align_right				= ct.align_right_flag
		text.align_justify				= ct.justify
		text.enable_outline				= ct.outline_flag
		text.customize_shadow			= ct.shadow_flag
		text.outline					= ct.outline_value
		text.shadow_size				= ct.shadow_value
		text.r, text.g, text.b, text.a						= ct.font_color[1], ct.font_color[2], ct.font_color[3], ct.font_color[4]
		text.outl_r, text.outl_g, text.outl_b, text.outl_a	= ct.shadow_color[1], ct.shadow_color[2], ct.shadow_color[3], ct.shadow_color[4]
		text.sh_r, text.sh_g, text.sh_b, text.sh_a			= ct.shadow_color[1], ct.shadow_color[2], ct.shadow_color[3], ct.shadow_color[4]
		text.background					= ct.background
		text.proportional				= ct.proportional
		text.hidden_flag				= ct.hidden_flag
	end
end

module.Text.New = function (gxt_entry, gxt_value)
	return {
		font							= 2,
		linewidth						= 600,
		pos								= {100, 100},
		size							= {0.2, 1.2},
		gxt 							= {gxt_entry, gxt_value},
		use_center						= false,
		align_right						= false,
		align_justify					= false,
		enable_outline					= true,
		customize_shadow				= false,
		outline							= 0,
		shadow_size						= 2,
		r		= 1,	g		= 1,	b		= 1,	a		= 1,
		outl_r	= 0,	outl_g	= 0,	outl_b	= 0,	outl_a	= 1,
		sh_r	= 0,	sh_g	= 0,	sh_b	= 0,	sh_a	= 1,
		background						= false,
		proportional					= true,
		hidden_flag						= false,
	}
end

module.Box.CopyToClipboard = function (box)
	require("interface-designer.globals").iDesgn.clipboard = {
		box = {
			pos 		= {box.pos[1], box.pos[2]},
			size 		= {box.size[1], box.size[2]},
			color 		= {box.color[1], box.color[2], box.color[3], box.color[4]},
			hidden_flag	= box.hidden_flag,
		}
	}
end

module.Box.PasteFromClipboard = function (box)
	local clipboard = require("interface-designer.globals").iDesgn.clipboard
	if clipboard.box ~= nil then
		local cb = clipboard.box
		box.pos			= {cb.pos[1], cb.pos[2]}
		box.size		= {cb.size[1], cb.size[2]}
		box.color		= {cb.color[1], cb.color[2], cb.color[3], cb.color[4]}
		box.hidden_flag	= cb.hidden_flag
	end
end

module.Box.New = function ()
	return {pos={200, 90}, size={350, 110}, color={0,0,0,0.45}, hidden_flag=false}
end

module.Texture.New = function (path)
	return {
		path		= path,
		pos			= {200, 90},
		size		= {100, 100},
		rotation	= 0,
		color		= {1,1,1,1},
		hidden_flag	= false,
	}
end

module.Texture.CopyToClipboard = function (t)
	require("interface-designer.globals").iDesgn.clipboard = {
		texture = {
			pos 		= {t.pos[1], t.pos[2]},
			size 		= {t.size[1], t.size[2]},
			rotation	= t.rotation,
			color 		= {t.color[1], t.color[2], t.color[3], t.color[4]},
		}
	}
end

module.Texture.PasteFromClipboard = function (t)
	local clipboard = require("interface-designer.globals").iDesgn.clipboard
	if clipboard.texture ~= nil then
		local ct = clipboard.texture
		t.pos			= {ct.pos[1], ct.pos[2]}
		t.size			= {ct.size[1], ct.size[2]}
		t.rotation		= ct.rotation
		t.color			= {ct.color[1], ct.color[2], ct.color[3], ct.color[4]}
	end
end

--[[===============================================================
===================================================================]]
return module