local I = require 'mimgui'
local new = I.new

local elements = require("interface-designer.elements")
local iDesgn = require("interface-designer.globals").iDesgn

local savepath, chosen_path = "", ""
local error_msg = ""
--local tree = require("interface-designer.globals").ReadFile().directorytree

local save_slot = new.int(0)
local save_list = {}

local savetitle = new.char[100]()
local save_selected_slot = 0

local module = {}

module.RecursiveGetTrees = function (tree, current_path)
	current_path = current_path or ""
	local i = 0
	for key,value in pairs(tree) do
		current_path = (current_path == "") and key or (current_path .. "/" .. key)
		if I.TreeNodeExStr(key) then
			if type(value) == "table" then
				module.RecursiveGetTrees(value, current_path)
			end
			I.Text(current_path)
			I.TreePop()
		else
			I.SameLine()
			if I.SmallButton("Choose "..i) then
				chosen_path = current_path
			end
			i=i+1
		end
		current_path = string.gsub(current_path, "/" .. key, "")	-- replace in "path/folder", "/folder" by "", it will not do anything if the path was only "folder"
		current_path = string.gsub(current_path, key, "")			-- replace "folder" by "" in path, it will not do anything if previous worked, but if path is "folder", it will clear it
	end
end

module.SaveAs_Modal = function ()
	if iDesgn.save_interface_as_modal[0] then
		iDesgn.save_interface_as_modal = new.bool(false)
		iDesgn.save_interface_filename = new.char[100]("new_interface")
		savepath = "moonloader/lib/interface-designer"
		chosen_path = savepath
		save_list = {}
		require("interface-designer.globals").LoadData()
		if iDesgn.saved_data ~= nil then
			for key,value in pairs(iDesgn.saved_data) do
				table.insert(save_list, key)
			end
		else iDesgn.saved_data = {}
		end
		I.OpenPopup("Save As...")
	end
	if I.BeginPopupModal("Save As...") then
		local ffi = require "ffi"
		
		--[[I.Text("Select filename and directory...\n\n")
		I.Separator()
		
		I.Text("Path: <GTA SA folder>/" .. savepath .. "/" .. ffi.string(iDesgn.save_interface_filename) .. ".json" )
		I.SameLine()
		if I.SmallButton("Change") then
			I.OpenPopup("Change path")
		end
		if I.BeginPopupModal("Change path") then
			I.Text("Browse the game directory and choose the desired path.")
			I.Separator()
			
			I.Text(getGameDirectory()..":")
			if tree then
				module.RecursiveGetTrees(tree)
			end
			
			I.Separator()
			I.Text("Chosen Path: "..chosen_path)
			if I.Button("Cancel", I.ImVec2(120, 0)) then I.CloseCurrentPopup() end
			I.SameLine()
			if I.Button("OK", I.ImVec2(120, 0)) then
				savepath = chosen_path
				I.CloseCurrentPopup()
			end
			I.EndPopup()
		end
		if I.InputTextWithHint(".json", "filename", iDesgn.save_interface_filename,100) then
			local filename = ffi.string(iDesgn.save_interface_filename)
			filename = string.gsub( filename, ".", "")
		end]]
		--I.ListBoxStr_arr("Saved data\nEnter new name\nor select one to overwrite", save_slot, save_list, 50, 10)
		
		I.Text("Saved files list:\n")
		I.Separator()
		
		I.BeginChild("Asdf", I.ImVec2(380,220), false)
		local i
		if #save_list > 0 then
			for i = 1, #save_list do
				if I.Selectable(save_list[i], save_selected_slot == i) then
					save_selected_slot = i
					savetitle = new.char[100]( save_list[i] )
				end
			end
		else
			I.Text("(no saved file created yet...)")
		end
		I.EndChild()
		
		I.Text("Enter name:")
		I.SameLine()
		I.SetNextItemWidth(200)
		if I.InputTextWithHint("", "Name of file to save", savetitle, 100) then end
		I.SameLine()
		if I.Button("Save") then
			if ffi.string(savetitle) == "" then
				error_msg = "Error: You can't leave name field empty!"
				I.OpenPopup("Error")
			else
				if iDesgn.saved_data[ ffi.string(savetitle) ] ~= nil then
					I.OpenPopup("Overwrite data?")
				else
					require("interface-designer.globals").SaveData(ffi.string(savetitle))
					I.CloseCurrentPopup()
				end
			end
		end
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Cancel") then I.CloseCurrentPopup() end
		if I.BeginPopupModal("Error") then
			I.Text(error_msg)
			I.Separator()
			if I.Button("OK", I.ImVec2(240, 0)) then
				error_msg = ""
				I.CloseCurrentPopup()
			end
			I.EndPopup()
		end
		local overwriten_data_successfully = false
		if I.BeginPopupModal("Overwrite data?") then
			I.Text("Warning:\n\nFile '"..ffi.string(savetitle).."' already exists.")
			I.Text("Do you want to overwrite?\n\n")
			I.Separator()
			if I.Button("Cancel", I.ImVec2(120, 0)) then I.CloseCurrentPopup() end
			I.SetItemDefaultFocus()
			I.SameLine()
			if I.Button("OK", I.ImVec2(120, 0)) then
				require("interface-designer.globals").SaveData(ffi.string(savetitle))
				overwriten_data_successfully = true
				I.CloseCurrentPopup()
			end
			I.EndPopup()
		end
		if overwriten_data_successfully then
			I.CloseCurrentPopup()
		end
		I.EndPopup()
	end
end

--[[if I.TreeNodeStr("Basic trees") then
	local i
	for i = 1, 4 do
		if i == 1 then
			I.SetNextItemOpen(true, 2)
		end
		if I.TreeNodeStr("Child "..i) then
			I.Text("blah blah")
			I.SameLine()
			if I.SmallButton("button") then end
			I.TreePop()
		end
	end
	I.TreePop();
end]]

return module