--[[===============================================================
===================================================================]]
local I = require 'mimgui'
local new = I.new
local ffi = require "ffi"

local elements = require("interface-designer.elements")
local iDesgn = require("interface-designer.globals").iDesgn

local ImGuiWindowFlags_NoTitleBar				= bit.lshift(1,  0) -- Disable title-bar
local ImGuiWindowFlags_NoResize					= bit.lshift(1,  1) -- Disable user resizing with the lower-right grip
local ImGuiWindowFlags_NoMove					= bit.lshift(1,  2) -- Disable user moving the window
local ImGuiWindowFlags_NoScrollbar				= bit.lshift(1,  3) -- Disable scrollbars (window can still scroll with mouse or programmatically)
local ImGuiWindowFlags_NoScrollWithMouse		= bit.lshift(1,  4) -- Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
local ImGuiWindowFlags_NoCollapse				= bit.lshift(1,  5) -- Disable user collapsing window by double-clicking on it
local ImGuiWindowFlags_AlwaysAutoResize			= bit.lshift(1,  6) -- Resize every window to its content every frame
local ImGuiWindowFlags_NoBackground				= bit.lshift(1,  7) -- Disable drawing background color (WindowBg, etc.) and outside border. Similar as using SetNextWindowBgAlpha(0.0f).
local ImGuiWindowFlags_NoSavedSettings			= bit.lshift(1,  8) -- Never load/save settings in .ini file
local ImGuiWindowFlags_NoMouseInputs			= bit.lshift(1,  9) -- Disable catching mouse, hovering test with pass through.
local ImGuiWindowFlags_MenuBar					= bit.lshift(1, 10) -- Has a menu-bar
local ImGuiWindowFlags_HorizontalScrollbar		= bit.lshift(1, 11) -- Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
local ImGuiWindowFlags_NoFocusOnAppearing		= bit.lshift(1, 12) -- Disable taking focus when transitioning from hidden to visible state
local ImGuiWindowFlags_NoBringToFrontOnFocus	= bit.lshift(1, 13) -- Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
local ImGuiWindowFlags_AlwaysVerticalScrollbar	= bit.lshift(1, 14) -- Always show vertical scrollbar (even if ContentSize.y < Size.y)
local ImGuiWindowFlags_AlwaysHorizontalScrollbar= bit.lshift(1, 15) -- Always show horizontal scrollbar (even if ContentSize.x < Size.x)
local ImGuiWindowFlags_AlwaysUseWindowPadding	= bit.lshift(1, 16) -- Ensure child windows without border uses style.WindowPadding (ignored by default for non-bordered child windows, because more convenient)
local ImGuiWindowFlags_NoNavInputs				= bit.lshift(1, 18) -- No gamepad/keyboard navigation within the window
local ImGuiWindowFlags_NoNavFocus				= bit.lshift(1, 19) -- No focusing toward this window with gamepad/keyboard navigation (e.g. skipped by CTRL+TAB)
local ImGuiWindowFlags_UnsavedDocument			= bit.lshift(1, 20) -- Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. When used in a tab/docking context, tab is selected on closure and closure is deferred by one frame to allow code to cancel the closure (with a confirmation popup, etc.) without flicker.
local ImGuiWindowFlags_NoNav					= ImGuiWindowFlags_NoNavInputs or ImGuiWindowFlags_NoNavFocus
local ImGuiWindowFlags_NoDecoration				= ImGuiWindowFlags_NoTitleBar or ImGuiWindowFlags_NoResize or ImGuiWindowFlags_NoScrollbar or ImGuiWindowFlags_NoCollapse
local ImGuiWindowFlags_NoInputs					= ImGuiWindowFlags_NoMouseInputs or ImGuiWindowFlags_NoNavInputs or ImGuiWindowFlags_NoNavFocus


--[[===============================================================
===================================================================]]
local module = {}

--[[===============================================================
===================================================================]]
local GetDataPointers = function (t)
	return {
		pos			= new.float[2]( t.pos[1], t.pos[2] ),
		size		= new.float[2]( t.size[1], t.size[2] ),
		rotation	= new.float( t.rotation ),
		color		= new.float[4]( t.color[1], t.color[2], t.color[3], t.color[4] ),
		show_flag	= new.bool( not t.hidden_flag )
	}
end

local UpdateData = function (t, t_ptr)
	t.pos			= { t_ptr.pos[0], t_ptr.pos[1] }
	t.size			= { t_ptr.size[0], t_ptr.size[1] }
	t.rotation		= t_ptr.rotation[0]
	t.color			= { t_ptr.color[0], t_ptr.color[1], t_ptr.color[2], t_ptr.color[3] }
	t.hidden_flag	= not t_ptr.show_flag[0]
end

--[[===============================================================
===================================================================]]
local getPaths = function(textures_files)
	local split	= require("interface-designer.utils").split
	local join	= require("interface-designer.utils").join
	local i, output = nil, {}
	for i = 1, #textures_files do
		local arr = split(textures_files[i], "[^\\]+")
		arr[#arr] = nil -- Removing last element that is the filename dot extension
		table.insert(output, join(arr, "/"))
	end
	return output
end

local getFiles = function (textures_files)
	local split	= require("interface-designer.utils").split
	local i, output = nil, {}
	for i = 1, #textures_files do
		local arr = split(textures_files[i], "[^\\]+")
		table.insert(output, arr[#arr])
	end
	return output
end

local getPath = function(full_path)
	local split	= require("interface-designer.utils").split
	local join	= require("interface-designer.utils").join
	local pieces = split(full_path, "[^/]+")
	pieces[#pieces] = nil -- Removing last element that is the filename dot extension
	return join(pieces, "/")
end

local getFilename = function (full_path)
	local split	= require("interface-designer.utils").split
	local pieces = split(full_path, "[^/]+")
	return pieces[#pieces] -- return last
end

local error_msg = ""
local selected_path, selected_image = 0, 0
local textures_paths = {}
local textures_images = {}
local preview_texture = nil
local selected_texture_path = nil

local search_input_text = new.char[100]()

module.NewTextureModal = function()
	if iDesgn.new_texture_modal[0] then
		I.OpenPopup("Create new texture")
		iDesgn.new_texture_modal = new.bool(false)
		require("interface-designer.globals").LoadData()
		if iDesgn.images_list then
			textures_paths = getPaths(iDesgn.images_list)
			textures_paths = require("interface-designer.utils").removeDuplicates(textures_paths)
			textures_images = {
				paths = getPaths(iDesgn.images_list),
				names = getFiles(iDesgn.images_list),
			}
			selected_path = 1
		else
			textures_paths = {}
			textures_images = nil
			selected_path = 0
		end
		selected_image = 0
		preview_texture = nil
	end
			
	if I.BeginPopupModal("Create new texture") then
		I.Text("Create new texture")
		I.Separator()
		
		-- Al textures available inside current folder
		I.BeginChild("Textures", I.ImVec2(180, 320), true, ImGuiWindowFlags_HorizontalScrollbar)
			if textures_images then
				local i
				for i = 1, #textures_images.paths do
					if textures_images.paths[i] == textures_paths[selected_path] then
						if I.Selectable(textures_images.names[i], i == selected_image) then
							selected_image = i
							local image = textures_images.paths[i] .. "/" .. textures_images.names[i]
							preview_texture = I.CreateTextureFromFile(image)
							selected_texture_path = image
						end
					end
				end
			end
		I.EndChild()
		
		I.SameLine()
		
		I.BeginChild("Other", I.ImVec2(480, 320), false)
			-- All folders that have jpg or png files
			I.BeginChild("Directory Tree", I.ImVec2(480, 116), true, ImGuiWindowFlags_HorizontalScrollbar)
				if #textures_paths > 0 then
					local i
					for i=1, #textures_paths do
						if I.Selectable(textures_paths[i], i == selected_path) then
							selected_path, selected_image = i, 0
						end
					end
				else
				end
			I.EndChild()
			
			-- Image preview
			I.BeginChild("Image Preview", I.ImVec2(480, 150), true)
				if preview_texture then
					I.Image(preview_texture, I.ImVec2(140, 140))
				end
			I.EndChild()
			
			if I.Button("Refresh") then
				local get_images = true
				require("interface-designer.globals").LoadData()
				iDesgn.images_list = require("interface-designer.utils").scandir2("/", nil, get_images)
				if iDesgn.images_list then
					textures_paths = getPaths(iDesgn.images_list)
					textures_paths = require("interface-designer.utils").removeDuplicates(textures_paths)
					textures_images = {
						paths = getPaths(iDesgn.images_list),
						names = getFiles(iDesgn.images_list),
					}
					selected_path = 1
				else
					textures_paths = {}
					textures_images = nil
					selected_path = 0
				end
				selected_image = 0
				require("interface-designer.globals").SaveAllData()
			end
			I.SameLine()
			if I.InputText("Search", search_input_text, 100) then end -- Dummy for now. TODO
			
			if I.Button("Cancel", I.ImVec2(120, 0)) then
				I.CloseCurrentPopup()
			end
			I.SameLine()
			if I.Button("Create", I.ImVec2(120, 0)) then
				if selected_texture_path then
					elements.CreateTexture( elements.Texture.New(selected_texture_path) )
					I.CloseCurrentPopup()
				end
			end
		I.EndChild()
		
		I.EndPopup()
	end
end

--[[===============================================================
===================================================================]]
local size_mult = new.float(1)
local t_ptr = {}
local passed_index = nil

module.Show = function ()
	local i = nil
	local resX, resY = getScreenResolution()
	local delete_modal_flag = false
	
	if #elements.textures > 0 then
		I.Text("Textures:")
	end
	
	for i = 1, #elements.textures do
		local t = elements.textures[i]
		local filename = getFilename(t.path)
		local path = getPath(t.path)
		t_ptr = GetDataPointers(t)
		size_mult[0] = elements.textures_size_multipliers[i]
		local hidden_text = t_ptr.show_flag[0] and "" or " [Hidden]"
		
		if I.CollapsingHeader("Texture "..i..hidden_text) then
			I.Text("Texture "..i..": "..filename)
			I.SameLine()
			if I.SmallButton("Change##texture"..i) then
				local j
				require("interface-designer.globals").LoadData()
				if iDesgn.images_list then
					textures_paths = getPaths(iDesgn.images_list)
					textures_paths = require("interface-designer.utils").removeDuplicates(textures_paths)
					textures_images = {
						paths = getPaths(iDesgn.images_list),
						names = getFiles(iDesgn.images_list),
					}
					selected_path = nil
					for j = 1, #textures_paths do -- Get the path index of the current image texture
						if path == textures_paths[j] then
							selected_path = j
						end
					end
					if selected_path == nil then selected_path = 1 end
				else
					textures_paths = {}
					textures_images = nil
					selected_path = 0
				end
				selected_image = nil
				if textures_images then -- Get the image index of the current image texture
					for j = 1, #textures_images.names do
						if filename == textures_images.names[j] then
							selected_image = j
						end
					end
				end
				if selected_image == nil then selected_image = 0 end
				if selected_image ~= 0 and selected_path ~= 0 then
					preview_texture = I.CreateTextureFromFile(path .. "/" .. filename)
				end
				passed_index = i
				I.OpenPopup("Change texture source")
			end
			I.Text(t.path)
			I.DragFloat2("Position##texture"..i, t_ptr.pos, 1, 0, resX, "%.1f")
			I.DragFloat2("Size##texture"..i, t_ptr.size, 1, -resX, resX, "%.1f")
			I.DragFloat("Size multiplier##texture"..i, size_mult, 0.01, 0, 5, "%.2f")
			if I.Button("Apply multiplier to size##texture"..i) then
				t_ptr.size[0] = size_mult[0] * t_ptr.size[0]
				t_ptr.size[1] = size_mult[0] * t_ptr.size[1]
				size_mult[0] = 1
			end
			I.DragFloat("Rotation##texture"..i, t_ptr.rotation, 1, -700, 700, "%.1f")
			I.ColorEdit4("Color##texture"..i, t_ptr.color)
			I.Separator()
			if I.Button("Delete texture##texture"..i, I.ImVec2(280, 0)) then
				I.OpenPopup("Delete texture?")
				passed_index = i
			end
		end
		
		-- General contextual menu (copy and paste general properties)
		if I.BeginPopupContextItem("textures context menu##texture"..i) then
			local hide_show_text = t_ptr.show_flag[0] and "Hide##texture"..i.."" or "Show##texture"..i..""
			if I.Selectable(hide_show_text) then
				t_ptr.show_flag[0] = not t_ptr.show_flag[0]
				t.hidden_flag = not t_ptr.show_flag[0]
			end
			if I.Selectable("Highlight texture##texture"..i) then
			end
			I.Separator()
			if I.Selectable("Copy properties##texture"..i) then
				local s = size_mult[0]
				elements.Texture.CopyToClipboard({
					pos			= {t.pos[1], t.pos[2]},
					size		= {t.size[1]*s, t.size[2]*s},
					rotation	= t.rotation,
					color		= {t.color[1], t.color[2], t.color[3], t.color[4]},
				})
			end
			if not(iDesgn.clipboard.texture == nil) then
				if I.Selectable("Paste properties##texture"..i) then
					elements.Texture.PasteFromClipboard(t)
					t_ptr = GetDataPointers(t)
					size_mult[0] = 1
				end
			else I.TextDisabled("Paste properties")
			end
			if I.Selectable("Reset default properties##texture"..i) then
				t.pos		= {200, 90}
				t.size		= {100, 100}
				t.rotation	= 0
				t.color		= {1,1,1,1}
				t.hidden_flag	= false
				t_ptr = GetDataPointers(t)
				size_mult[0] = 1
			end
			I.Separator()
			if I.Selectable("Duplicate as...##texture"..i) then
			end
			if I.Selectable("Remove##texture"..i) then
				delete_modal_flag = true
				passed_index = i
			end
			I.EndPopup()
		end
		UpdateData(t, t_ptr)
		elements.textures_size_multipliers[i] = size_mult[0]
	end
	
	if delete_modal_flag then
		I.OpenPopup("Delete texture?")
	end
	
	-- Remove a texture
	if I.BeginPopupModal("Delete texture?") then
		local t = elements.textures[passed_index]
		local filename = getFilename(t.path)
		
		I.Text("You are about to delete texture "..passed_index.." ("..filename..").\nContinue?\n\n")
		I.Separator()

		if I.Button("OK", I.ImVec2(120, 0)) then
			renderReleaseTexture(elements.textures_pointers[passed_index])
			table.remove(elements.textures_pointers, passed_index)
			table.remove(elements.textures, passed_index)
			I.CloseCurrentPopup()
			passed_index = nil
		end
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Cancel", I.ImVec2(120, 0)) then I.CloseCurrentPopup() end
		I.EndPopup()
	end
	
	-- Change the file path of a texture
	if I.BeginPopupModal("Change texture source") then
		local t = elements.textures[passed_index]
		local filename = getFilename(t.path)
		
		I.Text("Change texture source (current: "..filename..").")
		I.Separator()
		
		-- Al textures available inside current folder
		I.BeginChild("Textures", I.ImVec2(180, 320), true, ImGuiWindowFlags_HorizontalScrollbar)
			if textures_images then
				local i
				for i = 1, #textures_images.paths do
					if textures_images.paths[i] == textures_paths[selected_path] then
						if I.Selectable(textures_images.names[i], i == selected_image) then
							selected_image = i
							local image = textures_images.paths[i] .. "/" .. textures_images.names[i]
							preview_texture = I.CreateTextureFromFile(image)
							selected_texture_path = image
						end
					end
				end
			end
		I.EndChild()
		
		I.SameLine()
		
		I.BeginChild("Other", I.ImVec2(480, 320), false)
			-- All folders that have jpg or png files
			I.BeginChild("Directory Tree", I.ImVec2(480, 116), true, ImGuiWindowFlags_HorizontalScrollbar)
				if #textures_paths > 0 then
					local i
					for i=1, #textures_paths do
						if I.Selectable(textures_paths[i], i == selected_path) then
							selected_path, selected_image = i, 0
						end
					end
				else
				end
			I.EndChild()
			
			-- Image preview
			I.BeginChild("Image Preview", I.ImVec2(480, 150), true)
				if preview_texture then
					I.Image(preview_texture, I.ImVec2(140, 140))
				end
			I.EndChild()
			
			if I.Button("Refresh") then
				local get_images = true
				require("interface-designer.globals").LoadData()
				iDesgn.images_list = require("interface-designer.utils").scandir2("/", nil, get_images)
				if iDesgn.images_list then
					textures_paths = getPaths(iDesgn.images_list)
					textures_paths = require("interface-designer.utils").removeDuplicates(textures_paths)
					textures_images = {
						paths = getPaths(iDesgn.images_list),
						names = getFiles(iDesgn.images_list),
					}
					selected_path = 1
				else
					textures_paths = {}
					textures_images = nil
					selected_path = 0
				end
				selected_image = 0
				require("interface-designer.globals").SaveAllData()
			end
			I.SameLine()
			if I.InputText("Search", search_input_text, 100) then end -- Dummy for now. TODO
			
			if I.Button("Cancel", I.ImVec2(120, 0)) then
				I.CloseCurrentPopup()
			end
			I.SameLine()
			if I.Button("Change", I.ImVec2(120, 0)) then
				if selected_texture_path then
					t.path = selected_texture_path
					elements.textures_pointers[passed_index] = renderLoadTextureFromFile(t.path)
					I.CloseCurrentPopup()
				end
			end
		I.EndChild()
		
		I.EndPopup()
	end
end

--[[===============================================================
===================================================================]]
return module