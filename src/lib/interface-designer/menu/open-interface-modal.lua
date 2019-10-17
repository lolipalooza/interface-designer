local I = require 'mimgui'
local new = I.new

local elements = require("interface-designer.elements")
local iDesgn = require("interface-designer.globals").iDesgn

local module = {}

local save_list = {}
local save_selected_slot = 1
local savetitle = new.char[100]()
local autosave_exists = false
local autosave_slot = 0

module.OpenInterface_Modal = function ()
	if iDesgn.open_interface_modal[0] then
		iDesgn.open_interface_modal = new.bool(false)
		save_selected_slot = 1
		save_list = {}
		savetitle = new.char[100]()
		require("interface-designer.globals").LoadData()
		if iDesgn.saved_data ~= nil then
			for key,value in pairs(iDesgn.saved_data) do
				table.insert(save_list, key)
				autosave_exists = (autosave_exists or key=="AUTOSAVE") and true or false
			end
			savetitle = new.char[100]( save_list[save_selected_slot] )
		else iDesgn.saved_data = {}
		end
		I.OpenPopup("Open Interface")
	end
	if I.BeginPopupModal("Open Interface") then
		local ffi = require "ffi"
		
		I.Text("Saved files list:\n")
		I.Separator()
		
		I.BeginChild("Asdf", I.ImVec2(380,220), false)
		local i
		if #save_list > 0 then
			for i = 1, #save_list do
				if save_list[i] ~= "AUTOSAVE" then
					if I.Selectable(save_list[i], save_selected_slot == i) then
						save_selected_slot = i
						savetitle = new.char[100]( save_list[i] )
					end
				end
			end
		else
			I.Text("(no saved file created yet...)")
		end
		I.EndChild()
		
		if autosave_exists then
			I.Separator()
			I.BeginChild("Asdf2", I.ImVec2(380,20), false)
			if I.Selectable("AUTOSAVE", save_selected_slot == #save_list+1) then
				save_selected_slot = #save_list + 1
				savetitle = new.char[100]( "AUTOSAVE" )
			end
			I.EndChild()
		end
		
		if I.Button("Open", I.ImVec2(180,0)) then
			if ffi.string(savetitle) ~= "" then
				require("interface-designer.globals").LoadData( ffi.string(savetitle) )
				I.CloseCurrentPopup()
			end
		end
		
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Cancel", I.ImVec2(180,0)) then I.CloseCurrentPopup() end
	end
end

return module