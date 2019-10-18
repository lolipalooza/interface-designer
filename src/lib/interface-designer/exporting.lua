local module = {}

local color = function (flt)
	return math.floor(flt*255+0.5)
end

local getFilename = function (full_path)
	local split	= require("interface-designer.utils").split
	local pieces = split(full_path, "[^/]+")
	return pieces[#pieces] -- return last
end

local removeExtension = function (filename)
	local split	= require("interface-designer.utils").split
	local pieces = split(filename, "[^%.]+") -- everything but dots .
	return pieces[1] -- return first
end

module.Export = {}

module.Export.CLEO = function ( title, raw )
	local EXPORTFILE = string.format("moonloader/lib/interface-designer/%s.txt", title)
	local file = io.open(EXPORTFILE,'w')
	if file then
		file:write( raw )
		io.close(file)
    end
end

module.CLEO_Generate = function (elements)
	local raw = ""
	
	local i = nil
	
	raw = raw .. "##################### gxt entries in .fxt file #########################\n"
	raw = raw .. "# Put this in CLEO/cleo_texts/*.fxt file\n"
	for i = 1, #elements.texts do
		local t = elements.texts[i]
		raw = raw .. string.format("%s\t%s\n", t.gxt[1], t.gxt[2])
	end
	
	raw = raw .. "\n########################## CLEO/SCM file ###################################\n"
	raw = raw .. "{$CLEO .cs}\n"
	raw = raw .. "thread 'MyThread' // You can change this\n\n"
	
	raw = raw .. "//-------------------- Initializations --------------------\n\n"
	raw = raw .. "// Optional: dynamic gxts (in case you don't want to use a .fxt file)\n"
	for i = 1, #elements.texts do
		local t = elements.texts[i]
		raw = raw .. string.format("0ADF: add_dynamic_GXT_entry '%s' text \"%s\"\n", t.gxt[1], t.gxt[2])
	end
	
	raw = raw .. "\n0581: enable_radar 0\n"
	raw = raw .. "0826: enable_hud 0\n"
	raw = raw .. "03F0: enable_text_draw 1\n"
	
	raw = raw .. "\n// Textures initializing\n"
	raw = raw .. "// you must create a .txd file with desired textures, and place it in models/txd\n"
	raw = raw .. "// txd name must be max 7 characters long, to fit in a short-string variable (8 bytes),\n"
	raw = raw .. "// and the textures must be max 15 characters long, to fit in a long-string variable (16 bytes)\n"
	raw = raw .. "0390: load_txd_dictionary 'dict' // .txd file will be loaded here\n"
	for i = 1, #elements.textures do
		local t = elements.textures[i]
		local name = removeExtension( getFilename(t.path) )
		raw = raw .. string.format("038F: load_texture \"%s\" as %d\n", name, i)
	end
	raw = raw .. "03E0: draw_text_behind_textures 1\n"
	
	raw = raw .. "\n// Loop example\n"
	raw = raw .. "repeat\n"
	raw = raw .. "wait 0\n"
	raw = raw .. "\t//gosub @TextsRepresentation1\n"
	raw = raw .. "\tgosub @TextsRepresentation2\n"
	raw = raw .. "\tgosub @DrawBoxes\n"
	raw = raw .. "\tgosub @DrawTextures\n"
	raw = raw .. "until false\n"

	raw = raw .. "\n// ------------------ This must go inside a Loop -----------------\n"
	raw = raw .. "\n{======================================================================\n"
	raw = raw .. "======================================================================}\n"
	raw = raw .. "// Optional: explicit, no use of scm_functions\n"
	raw = raw .. ":TextsRepresentation1\n"
	for i = 1, #elements.texts do
		raw = raw .. "\n// Text "..i.."\n"
		
		local t = elements.texts[i]
		if t.use_center then
			raw = raw .. "0342: set_text_draw_centered 1\n"
			raw = raw .. string.format("0344: set_text_draw_linewidth %.3f for_centered_text\n", t.linewidth)
		else
			raw = raw .. string.format("0343: set_text_draw_linewidth %.3f\n", t.linewidth)
		end
		if t.align_right then
			raw = raw .. "03E4: set_text_draw_align_right 1\n"
		end
		if t.enable_outline then
			raw = raw .. string.format("081C: draw_text_outline %d RGBA %d %d %d %d\n",
				t.outline, color(t.outl_r), color(t.outl_g), color(t.outl_b), color(t.outl_a))
		end
		if t.customize_shadow or t.shadow_size ~= 2 then
			raw = raw .. string.format("060D: draw_text_shadow %d rgba %d %d %d %d\n",
				t.shadow_size, color(t.sh_r), color(t.sh_g), color(t.sh_b), color(t.sh_a))
		end
		if	t.align_justify	then	raw = raw .. "0341: set_text_draw_align_justify 1\n"	end
		if not t.proportional then	raw = raw .. "0348: enable_text_draw_proportional 0\n"	end
		if	t.background	then	raw = raw .. "0345: enable_text_draw_background 1\n"	end
		if color(t.r)~=255 or color(t.g)~=255 or color(t.b)~=255 or color(t.a)~=255 then
			raw = raw .. string.format("0340: set_text_draw_RGBA %d %d %d %d\n", color(t.r), color(t.g), color(t.b), color(t.a))
		end
		raw = raw .. string.format("0349: set_text_draw_font %d // 0: gothic, 1: normal, 2: uppercase, 3: heading\n", t.font)
		raw = raw .. string.format("033F: set_text_draw_letter_size %.2f %.2f\n", t.size[1], t.size[2])
		raw = raw .. string.format("033E: set_draw_text_position %.3f %.3f GXT '%s' // %s\n", t.pos[1], t.pos[2], t.gxt[1], t.gxt[2])
		raw = raw .. string.format("// you can draw texts with numbers too - only if gxt has ~1~\n", t.pos[1], t.pos[2], t.gxt[1], t.gxt[2])
		raw = raw .. string.format("//045A: draw_text_1number %.3f %.3f GXT '%s' number 2 // %s\n", t.pos[1], t.pos[2], t.gxt[1], t.gxt[2])
		raw = raw .. string.format("//045B: draw_text_2numbers %.3f %.3f GXT '%s' numbers 23 11 // %s\n", t.pos[1], t.pos[2], t.gxt[1], t.gxt[2])
		raw = raw .. string.format("//07FC: text_draw_box_position_XY %.3f %.3f GXT_reference '%s' value 2.5 flag 2 // %s\n", t.pos[1], t.pos[2], t.gxt[1], t.gxt[2])
	end
	raw = raw .. "\nreturn\n"
	
	raw = raw .. "\n{======================================================================\n"
	raw = raw .. "======================================================================}\n"
	raw = raw .. "// Optional: text draw through scm_functions\n"
	raw = raw .. ":TextsRepresentation2\n"
	for i = 1, #elements.texts do
		local t = elements.texts[i]
		raw = raw .. string.format("\n10@s = '%s' // Text %d: \"%s\"\n", t.gxt[1], i, t.gxt[2])
		raw = raw .. string.format("0AB1: @SetDrawText_Extra 15 enable_outline %d outline %d outline_rgba %d %d %d %d customize_shadow %d shadow_size %d shadow_rgba %d %d %d %d justify %d proportional %d background %d\n",
			t.enable_outline and "1" or "0", t.outline, color(t.outl_r), color(t.outl_g), color(t.outl_b), color(t.outl_a),
			t.customize_shadow and "1" or "0", t.shadow_size, color(t.sh_r), color(t.sh_g), color(t.sh_b), color(t.sh_a),
			t.align_justify and "1" or "0", t.proportional and "1" or "0", t.background and "1" or "0")
		
		raw = raw .. string.format("0AB1: @SetDrawText 20 behind_textures 0 font %d linewidth %.1f position %.1f %.1f size %.2f %.2f gxt 10@ 11@ use_numbers 0 numbers 0 0 center_flag %d center_linewidth %.1f align_right %d customize_rgba 1 font_rgba %d %d %d %d\n",
			t.font, t.linewidth, t.pos[1], t.pos[2], t.size[1], t.size[2], t.use_center and "1" or "0", t.linewidth, t.align_right and "1" or "0", color(t.r), color(t.g), color(t.b), color(t.a))
	end
	raw = raw .. "\nreturn\n"
	raw = raw .. "\n\n" .. module.TextsScmFunctions
	
	raw = raw .. "\n{======================================================================\n"
	raw = raw .. "======================================================================}\n"
	raw = raw .. ":DrawBoxes\n"
	for i = 1, #elements.boxes do
		local b = elements.boxes[i]
		raw = raw .. string.format("038E: draw_box_position %.1f %.1f size %.1f %.1f RGBA %d %d %d %d // Box %d\n",
			b.pos[1], b.pos[2], b.size[1], b.size[2], color(b.color[1]), color(b.color[2]), color(b.color[3]), color(b.color[4]), i)
	end
	raw = raw .. "return\n"
	
	raw = raw .. "\n{======================================================================\n"
	raw = raw .. "======================================================================}\n"
	raw = raw .. ":DrawTextures\n"
	for i = 1, #elements.textures do
		local t = elements.textures[i]
		local resX, resY = getScreenResolution()
		local w, h = t.size[1]*640/resX, t.size[2]*448/resY
		local x, y = t.pos[1]*640/resX, t.pos[2]*448/resY
		raw = raw .. string.format("074B: draw_texture %d position %.1f %.1f scale %.1f -%.1f angle %.1f color_RGBA %d %d %d %d\n",
			i, x + w/2, y + h/2, w, h, t.rotation, color(t.color[1]), color(t.color[2]), color(t.color[3]), color(t.color[4]))
	end
	raw = raw .. "return\n"
	return raw
end

module.TextsScmFunctions = [[
{======================================================================
======================================================================}
:SetDrawText // behind_textures 0@ font 1@ linewidth 2@ position 3@ 4@ size 5@ 6@ gxt 7@ 8@ use_numbers 9@ numbers 10@ 11@ center_flag 12@ center_linewidth 13@ align_right 14@ customize_rgba 15@ font_rgba 16@ 17@ 18@ 19@
03E0: draw_text_behind_textures 0@
if 15@ == 1
then 0340: set_text_draw_RGBA 16@ 17@ 18@ 19@
else 0340: set_text_draw_RGBA 255 255 255 255
end
0349: set_text_draw_font 1@
if 12@ == 1
then
    0342: set_text_draw_centered 1
    0344: set_text_draw_linewidth 13@ for_centered_text
else 0343: set_text_draw_linewidth 2@
end
033F: set_text_draw_letter_size 5@ 6@
03E4: set_text_draw_align_right 14@
if 9@ == 0
then 033E: set_draw_text_position 3@ 4@ GXT 7@s
end
if 9@ == 1
then 045A: draw_text_1number 3@ 4@ GXT 7@s number 10@
end
if 9@ == 2
then 045B: draw_text_2numbers 3@ 4@ GXT 7@s numbers 10@ 11@
end
0AB2: ret 0

{======================================================================
======================================================================}
:SetDrawText_Extra // enable_outline_unused 0@ outline 1@ outline_rgba 2@ 3@ 4@ 5@ customize_shadow_unused 6@ shadow_size 7@ shadow_rgba 8@ 9@ 10@ 11@ justify 12@ proportional 13@ background 14@
081C: draw_text_outline 1@ RGBA 2@ 3@ 4@ 5@
060D: draw_text_shadow 7@ rgba 8@ 9@ 10@ 11@
0341: set_text_draw_align_justify 12@
0348: enable_text_draw_proportional 13@
0345: enable_text_draw_background 14@
0AB2: ret 0
]]

return module