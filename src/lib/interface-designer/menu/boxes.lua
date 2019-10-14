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
local modalIndex = nil
local box_pos, box_size, box_color

module.Show = function()
	local i = nil
	local resX, resY = getScreenResolution()
	local delete_modal_flag = false
	
	if #elements.boxes > 0 then
		I.Text("Boxes:")
	end
	
	for i = 1, #elements.boxes do
		local b = elements.boxes[i]
		box_pos, box_size, box_color, box_show = elements.GetBoxesDataPointers(b)
		local hidden_text = box_show[0] and "" or " [Hidden]"
		if I.CollapsingHeader("Box "..i..hidden_text.."") then
			I.Text("Box "..i.."")
			I.DragFloat2("Position##box"..i, box_pos, 1, 0, resX, "%.1f")
			I.DragFloat2("Size##box"..i, box_size, 1, 1, resX, "%.1f")
			I.ColorEdit4("Box color##box"..i, box_color)
			I.Separator()
			if I.Button("Delete box##box"..i, I.ImVec2(280, 0)) then
				I.OpenPopup("Delete box?")
				modalIndex = i
			end
		end
		
		-- General contextual menu (copy and paste general properties)
		if I.BeginPopupContextItem("boxes context menu##box"..i) then
			local hide_show_text = box_show[0] and "Hide##box"..i.."" or "Show##box"..i..""
			if I.Selectable(hide_show_text) then
				box_show[0] = not box_show[0]
				b.hidden_flag = not box_show[0]
			end
			if I.Selectable("Highlight box##box"..i) then
			end
			I.Separator()
			if I.Selectable("Copy properties##box"..i) then elements.Box.CopyToClipboard(b) end
			if not(iDesgn.clipboard.box == nil) then
				if I.Selectable("Paste properties##box"..i) then
					elements.Box.PasteFromClipboard(b)
					box_pos, box_size, box_color, box_show = elements.GetBoxesDataPointers(b)
				end
			else I.TextDisabled("Paste properties")
			end
			if I.Selectable("Reset default properties##box"..i) then
				b.pos			= {200, 90}
				b.size			= {350, 110}
				b.color			= {0,0,0,0.45}
				b.hidden_flag	= false
				box_pos, box_size, box_color, box_show = elements.GetBoxesDataPointers(b)
			end
			I.Separator()
			if I.Selectable("Duplicate as...##box"..i) then
			end
			if I.Selectable("Remove##box"..i) then
				delete_modal_flag = true
				modalIndex = i
			end
			I.EndPopup()
		end
		
		elements.UpdateBoxesData(b, box_pos, box_size, box_color, box_show)
	end
	
	if delete_modal_flag then
		I.OpenPopup("Delete box?")
	end
	
	-- Remove a box
	if I.BeginPopupModal("Delete box?") then
		local b = elements.boxes[modalIndex]
		I.Text("You are about to delete box "..modalIndex..".\nContinue?\n\n")
		I.Separator()

		if I.Button("OK", I.ImVec2(120, 0)) then
			table.remove(elements.boxes, modalIndex)
			I.CloseCurrentPopup()
			modalIndex = nil
		end
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Cancel", I.ImVec2(120, 0)) then I.CloseCurrentPopup() end
		I.EndPopup()
	end
end

return module