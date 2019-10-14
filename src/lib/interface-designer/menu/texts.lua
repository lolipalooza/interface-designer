--[[===============================================================
===================================================================]]
local I = require 'mimgui'
local new = I.new
local ffi = require "ffi"

local elements = require("interface-designer.elements")
local iDesgn = require("interface-designer.globals").iDesgn

--[[===============================================================
===================================================================]]
local module = {}

--[[===============================================================
===================================================================]]
local error_msg = ""

module.NewTextsModal = function()
	if iDesgn.new_text_submenu[0] then
		I.OpenPopup("Create new text")
		iDesgn.new_text_submenu = new.bool(false)
		iDesgn.new_text_gxtname = new.char[8]('DEMO')
		iDesgn.new_text_gxtstring = new.char[100]("Change text here.")
	end
			
	if I.BeginPopupModal("Create new text") then
		I.Text("Create new text")
		I.Separator()
		if I.InputText("Gxt entry",iDesgn.new_text_gxtname,8) then end
		if I.InputText("Gxt value",iDesgn.new_text_gxtstring,100) then end
		if I.Button("Cancel", I.ImVec2(120, 0)) then
			I.CloseCurrentPopup()
		end
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Create", I.ImVec2(120, 0)) then
			local gxt_entry, gxt_value = ffi.string(iDesgn.new_text_gxtname), ffi.string(iDesgn.new_text_gxtstring)
			if gxt_entry == ''	then
				error_msg = "You can't leave Gxt Entry field empty!"
			elseif gxt_value == ''	then
				error_msg = "You can't leave Gxt Value field empty!"
			elseif elements.isGxtTextDefined(gxt_entry) then
				error_msg = "The Gxt Entry '"..gxt_entry.."' has already taken. Please define another one!"
			else
				error_msg = ""
				elements.CreateText( elements.Text.New(gxt_entry, gxt_value) )
				I.CloseCurrentPopup()
			end
		end
		I.SameLine()
		I.Text(error_msg)
		I.EndPopup()
	end
end

--[[===============================================================
===================================================================]]
local modalIndex = nil
local t_ptr = {}

module.Show = function ()
	-- Show all created texts
	local i = nil
	local resX, resY = getScreenResolution()
	local delete_modal_flag = false
	
	if #elements.texts > 0 then
		I.Text("Texts:")
	end
	
	for i = 1, #elements.texts do
		local t = elements.texts[i]
		t_ptr = elements.GetTextsDataPointers(t)
		local gxt_minified = (#t.gxt[2] > 26) and (string.sub(t.gxt[2], 1, 26).."...") or t.gxt[2]
		local hidden_text = t_ptr.show_flag[0] and "" or " [Hidden]"
		if I.CollapsingHeader("Text "..i..hidden_text..": '"..t.gxt[1].."' ("..gxt_minified..")") then
			--I.Checkbox("'"..t.gxt[1].."':", t_ptr.show_flag)
			--I.SameLine()
			I.Text("'"..t.gxt[1].."':")
			I.SameLine()
			if I.SmallButton("Edit gxt...##text"..i) then
				I.OpenPopup("Edit Gxt")
				iDesgn.new_text_gxtname = new.char[8](t.gxt[1])
				iDesgn.new_text_gxtstring = new.char[100](t.gxt[2])
				modalIndex = i
			end
			I.ComboStr("Font style##text"..i, t_ptr.font, 'Gothic\0Normal\0Uppercase\0Heading\0\0')
			I.ColorEdit4("Font color##text"..i, t_ptr.font_color)
			I.DragFloat("Linewidth##text"..i, t_ptr.linewidth, 1, 0, 700, "%.1f")
			I.SameLine()
			I.Checkbox("Shadow##text"..i, iDesgn.linewidth_shadow_flag)
			I.DragFloat2("Position##text"..i, t_ptr.pos, 1, 0, resX, "%.1f")
			I.DragFloat2("Size##text"..i, t_ptr.size, 0.01, -10, 10, "%.2f")
			I.Checkbox("Centered##text"..i, t_ptr.center_flag)				I.SameLine()
			I.Checkbox("Align Right##text"..i, t_ptr.align_right_flag)		I.SameLine()
			I.Checkbox("Justify##text"..i, t_ptr.justify)
			I.Checkbox("Outline##text"..i, t_ptr.outline_flag)
			I.SameLine()
			I.Checkbox("Shadow##text"..i, t_ptr.shadow_flag)
			I.SliderInt("Outline Value##text"..i, t_ptr.outline_value, -4, 4)
			I.SliderInt("Shadow Value##text"..i, t_ptr.shadow_value, -4, 4)
			I.ColorEdit4("Shadow color##text"..i, t_ptr.shadow_color)
			I.Checkbox("Background##text"..i, t_ptr.background)	I.SameLine()
			I.Checkbox("Proportional##text"..i, t_ptr.proportional)
			I.Separator()
			if I.Button("Delete text##text"..i, I.ImVec2(280, 0)) then
				I.OpenPopup("Delete text?")
				modalIndex = i
			end
		end
		
		-- General contextual menu (copy and paste general properties)
		if I.BeginPopupContextItem("texts context menu##text"..i) then
			local hide_show_text = t_ptr.show_flag[0] and "Hide##text"..i.."" or "Show##text"..i..""
			if I.Selectable(hide_show_text) then
				t_ptr.show_flag[0] = not t_ptr.show_flag[0]
				t.hidden_flag = not t_ptr.show_flag[0]
			end
			if I.Selectable("Highlight text##text"..i) then
			end
			I.Separator()
			if I.Selectable("Copy properties##text"..i) then elements.Text.CopyToClipboard(t) end
			if not(iDesgn.clipboard.text == nil) then
				if I.Selectable("Paste properties##text"..i) then
					elements.Text.PasteFromClipboard(t)
					t_ptr = elements.GetTextsDataPointers(t)
				end
			else I.TextDisabled("Paste properties")
			end
			if I.Selectable("Reset default properties##text"..i) then
				t.font									= 2
				t.linewidth								= 600
				t.pos									= {100, 100}
				t.size									= {0.2, 1.2}
				t.use_center							= false
				t.align_right							= false
				t.align_justify							= false
				t.enable_outline						= true
				t.customize_shadow						= false
				t.outline								= 0
				t.shadow_size							= 2
				t.r, t.g, t.b, t.a						= 1, 1, 1, 1
				t.outl_r, t.outl_g, t.outl_b, t.outl_a	= 0, 0, 0, 1
				t.sh_r, t.sh_g, t.sh_b, t.sh_a			= 0, 0, 0, 1
				t.background							= false
				t.proportional							= true
				t.hidden_flag							= false
				t_ptr = elements.GetTextsDataPointers(t)
			end
			I.Separator()
			if I.Selectable("Duplicate as...##text"..i) then
			end
			if I.Selectable("Remove##text"..i) then
				delete_modal_flag = true
				modalIndex = i
			end
			I.EndPopup()
		end
		elements.UpdateTextsData(t, t_ptr)
	end
	
	if delete_modal_flag then
		I.OpenPopup("Delete text?")
	end
	
	-- Remove a text
	if I.BeginPopupModal("Delete text?") then
		local t = elements.texts[modalIndex]
		I.Text("You are about to delete text '"..t.gxt[1].."'.\nContinue?\n\n")
		I.Separator()

		--I.PushStyleVar(ImGuiStyleVar_FramePadding, ImVec2(0, 0))
		--I.Checkbox("Don't ask me next time", asdf)
		--I.PopStyleVar()

		if I.Button("OK", I.ImVec2(120, 0)) then
			clearGxtEntry(t.gxt[1])
			table.remove(elements.texts, modalIndex)
			I.CloseCurrentPopup()
			modalIndex = nil
		end
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Cancel", I.ImVec2(120, 0)) then I.CloseCurrentPopup() end
		I.EndPopup()
	end
	
	-- Edit the gxt of a text
	if I.BeginPopupModal("Edit Gxt") then
		local t = elements.texts[modalIndex]
		I.Text("Edit Gxt (current: '"..t.gxt[1].."').")
		I.Text(error_msg)
		I.Separator()

		if I.InputText("Gxt entry",iDesgn.new_text_gxtname,8) then end
		if I.InputText("Gxt value",iDesgn.new_text_gxtstring,100) then end
		if I.Button("Cancel", I.ImVec2(120, 0)) then I.CloseCurrentPopup() end
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Change", I.ImVec2(120, 0)) then
			local gxt_entry, gxt_value = ffi.string(iDesgn.new_text_gxtname), ffi.string(iDesgn.new_text_gxtstring)
			if elements.isGxtTextDefined(gxt_entry) and not(gxt_entry == t.gxt[1]) then
				error_msg = "The Gxt Entry '"..gxt_entry.."' has already taken. Please define another one!"
			else
				error_msg = ""
				clearGxtEntry(t.gxt[1])
				setGxtEntry(gxt_entry, gxt_value)
				t.gxt[1], t.gxt[2] = gxt_entry, gxt_value
				I.CloseCurrentPopup()
				modalIndex = nil
			end
		end
		I.EndPopup()
	end
end

return module