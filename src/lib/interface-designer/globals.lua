local I = require 'mimgui'
local new = I.new

local module = {}

module.version = "1.0.0"

module.iDesgn = {
	main_menu_flag = new.bool(false),
	about_submenu_flag = new.bool(false),
	show_demo_window_flag = new.bool(false),
	debug_window_flag = new.bool(false),
	new_text_submenu = new.bool(false),
	new_texture_modal = new.bool(false),
	linewidth_shadow_flag = new.bool(false),
	
	new_interface_modal = new.bool(false),
	open_interface_modal = new.bool(false),
	save_interface_modal = new.bool(false),
	save_interface_as_modal = new.bool(false),
	
	save_interface_path = new.char[250](),
	save_interface_filename = new.char[100](),
	save_interface_fullpath = new.char[350](),
	directory_tree = {},
	images_list = {},
	
	new_text_gxtname = new.char[7](),
	new_text_gxtstring = new.char[100](),
	
	clipboard = {},
	
	saved_data = {},
	SAVEFILE = "moonloader/lib/interface-designer/interface-designer.SAV",
}

module.SaveData = function (title)
	local iDesgn = module.iDesgn
	local elements = require("interface-designer.elements")
	iDesgn.saved_data[title] = {}
	iDesgn.saved_data[title].texts = elements.texts
	iDesgn.saved_data[title].boxes = elements.boxes
	
	-- Applying size multipliers to textures size before save
	local i
	for i = 1, #elements.textures do
		local t, s = elements.textures[i], elements.textures_size_multipliers[i]
		--local sizeX, sizeY, sMult = t.size[1], t.size[2], s
		t.size = { t.size[1]*s, t.size[2]*s }
		elements.textures_size_multipliers[i] = 1
	end
	iDesgn.saved_data[title].textures = elements.textures
	
	local file = io.open(iDesgn.SAVEFILE,'w')
    if file then
        file:write(encodeJson({
			saved_data		= iDesgn.saved_data,
			directory_tree	= iDesgn.directory_tree,
			images_list		= iDesgn.images_list,
		}))
        io.close(file)
    end
end

module.LoadData = function (title)
	local elements = require("interface-designer.elements")
	local iDesgn = module.iDesgn
	
	local file = module.ReadFile()
	if file then
		iDesgn.saved_data = file.saved_data
		iDesgn.directory_tree = file.directory_tree
		iDesgn.images_list = file.images_list
	else
		iDesgn.saved_data = {}
		iDesgn.directory_tree = {}
		iDesgn.images_list = {}
	end
	
	if title ~= nil then
		if iDesgn.saved_data[title] ~= nil then
			elements.texts = iDesgn.saved_data[title].texts
			elements.boxes = iDesgn.saved_data[title].boxes
			elements.textures = iDesgn.saved_data[title].textures
			elements.clearAllGxtEntries()
			elements.createAllDynamicGxtEntries(title)
			elements.releaseAllTextures()
			elements.renderAllTextures(title)
			return true
		else
			elements.texts = {}
			elements.boxes = {}
			elements.textures = {}
			elements.clearAllGxtEntries()
			elements.releaseAllTextures()
			return false
		end
	else return false
	end
end

module.SaveAllData = function ()
	local iDesgn = module.iDesgn
	local file = io.open(iDesgn.SAVEFILE,'w')
    if file then
        file:write(encodeJson({
			saved_data		= iDesgn.saved_data,
			directory_tree	= iDesgn.directory_tree,
			images_list		= iDesgn.images_list,
		}))
        io.close(file)
    end
end

local DIRECTORYTREE_FILE = "moonloader/lib/interface-designer/directorytree.json"

module.ReadFile = function() -- before: InitDirectoryTree
	local SAVEFILE = module.iDesgn.SAVEFILE
	if doesFileExist(SAVEFILE) then
		local file = io.open(SAVEFILE,'r')
		local data = file:read("*all")
		io.close(file)
		if data then
			return decodeJson(data)
		else return nil
		end
	else return nil
	end
end

module.RefreshDirectoryTree = function ()
	local SAVEFILE = module.iDesgn.SAVEFILE
	local utils = require("interface-designer.utils")
	local t = utils.RefreshDirectoryTree("/")
	local tree = utils.GetTree(t)
	local file = io.open(SAVEFILE,'w')
	if file then
		--file:write(encodeJson(tree))
		io.close(file)
	end
end

return module