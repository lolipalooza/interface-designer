local module = {}

--[[===============================================================
DrawText(int font, float linewidth, float posx, float posy, float sizex, float sizey, GxtString gxt_text, table data = {bool use_number, int number, bool use_center, float center_linewidth, bool align_right, bool enable_outline, int outline, int outl_r, int outl_g, int outl_b, int outl_a, bool customize_rgba, int r, int g, int b, int a, bool customize_shadow, int shadow_size, int sh_r, int sh_g, int sh_b, int sh_a, bool background, bool proportional, bool align_justify})
===================================================================]]
function module.DrawText(font, linewidth, posx, posy, sizex, sizey, gxt_text, data)
	local d = data or {}
	
	local number, use_center, center_linewidth = d.number or nil, d.use_center or false, d.center_linewidth or 0.0
	local align_right, enable_outline, outline = d.align_right or false, d.enable_outline or false, d.outline or 0
	local outl_r, outl_g, outl_b, outl_a = d.outl_r or 0, d.outl_g or 0, d.outl_b or 0, d.outl_a or 0
	local r, g, b, a, customize_shadow, shadow_size = d.r or 255, d.g or 255, d.b or 255, d.a or 255, d.customize_shadow or false, d.shadow_size or 0
	local sh_r, sh_g, sh_b, sh_a, background = d.sh_r or 0, d.sh_g or 0, d.sh_b or 0, d.sh_a or 0, d.background or false
	local proportional, align_justify = (d.proportional==nil) and true or d.proportional, d.align_justify or false
	
	if enable_outline
	then setTextEdge(outline, outl_r, outl_g, outl_b, outl_a)
	else setTextEdge(outline, outl_r, outl_g, outl_b, outl_a)
	end
	
	if customize_shadow
	then setTextDropshadow(shadow_size, sh_r, sh_g, sh_b, sh_a)
	else setTextDropshadow(shadow_size, sh_r, sh_g, sh_b, sh_a)
	end
	
	setTextBackground(background)
	setTextProportional(proportional)
	setTextJustify(align_justify)
	setTextColour(r, g, b, a)
	setTextFont(font)
	
	if use_center then
		setTextCentre(true)
		setTextCentreSize(center_linewidth)
	else setTextWrapx(linewidth)
	end
	
	setTextScale(sizex, sizey)
	setTextRightJustify(align_right)
	
	if type(number) == "table" and #number == 2 then
		displayTextWith2Numbers(posx, posy, gxt_text, number[1], number[2])
	elseif type(number) == "table" and #number == 1 then
		displayTextWithNumber(posx, posy, gxt_text, number[1])
	elseif type(number) == "number"	then
		displayTextWithNumber(posx, posy, gxt_text, number)
	else displayText(posx, posy, gxt_text)
	end
end

--[[===============================================================
===================================================================]]
-- Lua implementation of PHP scandir function
-- https://www.gammon.com.au/scripts/doc.php?lua=io.popen
function module.scandir(directory)
    local i, t, popen = 0, {}, io.popen
	local linux_command = 'ls -a "%s"'
	local windows_command1 = 'dir "%s" /b /ad'	-- only directories
	local windows_command2 = 'dir "%s" /b'		-- directories and files
	local windows_command3 = 'dir "%s" /b /a-d'	-- only files
    local pfile = popen(string.format(windows_command2, getGameDirectory()..directory))
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

--[[===============================================================
===================================================================]]
-- https://www.gammon.com.au/scripts/doc.php?lua=os.execute
function module.scandir2(dir, flag, get_images)
	get_images = get_images or false
	flag = flag or 1 -- only directories by default
	local n = os.tmpname ()						-- get a temporary file name
	command = {
		'dir "%s" /s /b /ad > %s',		-- only directories
		'dir "%s" /s /b > %s',			-- directories and files
		'dir "%s" /s /b /a-d > %s',		-- only files
	}
	local path = getGameDirectory()..dir
	local i,t = 0,{}
	if not get_images then
		os.execute ( string.format(command[flag], path, n) ) -- execute a command
	else
		os.execute ( string.format('dir /s /b /a-d "%s\\*.jpg" "%s\\*.png" > "%s"', path, path, n) ) -- execute a command
	end
	for line in io.lines (n) do					-- display output
        i = i + 1
        t[i] = string.gsub(line, getGameDirectory().."\\", "") -- in line: replace all the game directory root path by ""
	end
	os.remove (n)								-- remove temporary file
	return t
end

--[[===============================================================
===================================================================]]
--http://www.lua.org/manual/5.2/manual.html#pdf-string.gmatch
-- Note: pattern must fit all the thing you want in the array (must exclude the separator)
-- For example: if you want to split by commas ",", use as pattern: "[^,]+"
-- (pattern basically is: 'everything that's not a comma' and must be more than one character)
-- split("foo,bar,more", "[^,]+") will return: {"foo", "bar", "more"}
function module.split(s, pattern)
	local i, t = nil, {}
    for v in string.gmatch(s, pattern) do
		table.insert(t, v)
    end
	return t
end

-- http://lua-users.org/wiki/SplitJoin
module.join = function (arr, glue)
	return table.concat(arr, glue)
end

--http://lua-users.org/wiki/StringRecipes
function module.startswith(str, start)
   return str:sub(1, #start) == start
end

function module.endswith(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

--[[===============================================================
===================================================================]]
module.removeDuplicates = function (array)
	local not_duplicates_array, i = {}, nil
	table.insert(not_duplicates_array, array[1])
	for i = 2, #array do
		if array[i] ~= array[i-1] then
			table.insert(not_duplicates_array, array[i])
		end
	end
	return not_duplicates_array
end

--[[===============================================================
===================================================================]]
module.INT32_MIN = -((2^32)/2-1)
module.INT32_MAX = (2^32)/2

function module.Inc(var, step, vmin, vmax, loop_flag)
	step, vmin, vmax = step or 1, vmin or module.INT32_MIN, vmax or module.INT32_MAX
	
	-- loop_flag is true by default (when is not specified)
	if not(loop_flag==nil) then		loop_flag = loop_flag and true			else		loop_flag = true		end
	
	var = var + step
	if		var > vmax	then	--var = loop_flag and vmin or vmax
		if loop_flag then var = vmin
		else var = vmax
		end
	elseif	var < vmin	then	--var = loop_flag and vmax or vmin
		if loop_flag then var = vmax
		else var = vmin
		end
	end
	return var
end

function module.Dec(var, step, vmin, vmax, loop_flag)
	return module.Inc(var, -step, vmin, vmax, loop_flag)
end

--[[===============================================================
===================================================================]]
function module.RefreshDirectoryTree(dir)
	local utils = require("interface-designer.utils")
	local i, t, tree = nil, nil, {}
	t = utils.scandir2(dir)
	local first = utils.split(t[1], "[^\\]+")
	local lvl = #first
	for i = 1, #t do
		local paths = utils.split(t[i], "[^\\]+")
		local j, str = nil, ""
		for j = lvl, #paths do
			str = str .. "/" .. paths[j]
		end
		t[i] = string.sub(str, 2) -- ignore the first "/"
	end
	return t
end

--[[===============================================================
===================================================================]]
module.RecursiveGetSubtrees = function (tree, folders, index)
	if folders[index+1] ~= nil then
		local subtree = tree[ folders[index] ]
		if subtree[ folders[index+1] ] == nil then	subtree[ folders[index+1] ] = {}	end
		
		module.RecursiveGetSubtrees(subtree, folders, index+1)
	end
end

module.GetTree = function (dir_array) -- recursive function
	local utils = require("interface-designer.utils")
	local i, tree = nil, {}
	
	for i = 1, #dir_array do
		local folders = utils.split(dir_array[i], "[^/]+")
		
		if folders[1] ~= nil then
			if tree[ folders[1] ] == nil then	tree[ folders[1] ] = {}		end
			
			module.RecursiveGetSubtrees(tree, folders, 1)
		end
	end
	return tree
end

--[[===============================================================
===================================================================]]
module.rgbaToUint = function (r, g, b, a)
	return r + g*0x100 + b*0x100*0x100 + a*0x100*0x100*0x100
end

--[[===============================================================
===================================================================]]
return module