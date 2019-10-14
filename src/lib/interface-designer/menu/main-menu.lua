--[[===============================================================
===================================================================]]
local I = require 'mimgui'
local new = I.new

local elements = require("interface-designer.elements")
local iDesgn = require("interface-designer.globals").iDesgn

local Texts = require("interface-designer.menu.texts")
local Boxes = require("interface-designer.menu.boxes")
local Textures = require("interface-designer.menu.textures")

--[[===============================================================
===================================================================]]
local module = {}

local ReadLogFile = function ()
	local file = io.open("moonloader/moonloader.log",'r')
    if file then
        local data = file:read("*all")
        io.close(file)
		return data
	else return ""
    end
end

local log_file_raw = new.char[1024 * 10000]( ReadLogFile() )

--[[===============================================================
===================================================================]]
module.Show = function ()
	I.Begin("InterfaceDesigner", iDesgn.main_menu_flag, I.WindowFlags.MenuBar)
	
	if I.BeginMenuBar() then
		if I.BeginMenu("Menu") then
			if I.MenuItemBool("New", nil, false, elements.atLeastOneElementExists())		then iDesgn.new_interface_modal		= new.bool(true) end
			if I.MenuItemBool("Open", "Ctrl+O")												then iDesgn.open_interface_modal	= new.bool(true) end
			if I.BeginMenu("Open Recent") then
				if I.MenuItemBool("fish_hat.c") then end
				if I.MenuItemBool("fish_hat.inl") then end
				if I.MenuItemBool("fish_hat.h") then end
				if I.BeginMenu("More..") then
					if I.MenuItemBool("Hello") then end
					if I.MenuItemBool("Sailor") then end
					I.EndMenu()
				end
				I.EndMenu()
			end
			I.Separator()
			if I.MenuItemBool("Save", "Ctrl+S", false, false)	then iDesgn.save_interface_modal	= new.bool(true) end
			if I.MenuItemBool("Save As..", nil, false, elements.atLeastOneElementExists())	then iDesgn.save_interface_as_modal	= new.bool(true) end
			I.Separator()
			if I.BeginMenu("Export as...") then
				if I.MenuItemBool("Plain data", nil, false, elements.atLeastOneElementExists()) then end
				I.TextDisabled("CLEO/SCM")
				I.TextDisabled("Lua")
				I.TextDisabled("C++")
				I.Separator()
				I.TextDisabled("All formats")
				I.EndMenu()
			end
			I.EndMenu()
		end
		if I.BeginMenu("Edit") then
			if I.MenuItemBool("New Text") then
				iDesgn.new_text_submenu = new.bool(true)
			end
			if I.MenuItemBool("New Box") then
				elements.CreateBox( elements.Box.New() )
			end
			if I.MenuItemBool("New Texture") then
				iDesgn.new_texture_modal = new.bool(true)
			end
			I.Separator()
			if I.MenuItemBool("New Text Array") then end
			if I.MenuItemBool("New Box Array") then end
			I.Separator()
			if I.MenuItemBool("New Group") then end
			I.EndMenu()
		end
		if I.BeginMenu("Help") then
			if I.MenuItemBool("Reinit Interface Designer (in case of errors)") then
				displayHud(true)
				displayRadar(true)
				setPlayerControl(playerchar, true)
				useRenderCommands(false) -- 03F0: enable_text_draw 1
				setTextDrawBeforeFade(false) -- 03E0: draw_text_behind_textures 1
				local script = thisScript()
				script.this:reload()
			end
			I.Separator()
			if I.MenuItemBool("Show Demo Window") then iDesgn.show_demo_window_flag[0] = true end
			if I.MenuItemBool("Debug Window") then iDesgn.debug_window_flag[0] = true end
			if I.MenuItemBool("About Interface Designer...") then iDesgn.about_submenu_flag[0] = true end
			I.EndMenu()
		end
		
		I.EndMenuBar()
	end
	
	-- Modals
	Texts.NewTextsModal()
	Textures.NewTextureModal()
	
	-- Show Texts
	Texts.Show()
	
	if #elements.texts > 0 and #elements.boxes > 0 then		I.Separator()		end
	
	-- Show Boxes
	Boxes.Show()
	
	if #elements.textures > 0 and (#elements.boxes > 0 or #elements.texts) then		I.Separator()		end
	
	-- Show Textures
	Textures.Show()
	
	I.End()
	
	if iDesgn.about_submenu_flag[0] then
		I.Begin("About", iDesgn.about_submenu_flag)
			I.Text("Interface Designer")
			I.Separator()
			I.Text("version "..require("interface-designer.globals").version)
		I.End()
	end
	
	-- Debug: ShowDemoWindow()
	if iDesgn.show_demo_window_flag[0] then
		I.ShowDemoWindow(iDesgn.show_demo_window_flag)
	end
	
	-- New Interface Modal
	if iDesgn.new_interface_modal[0] then
		iDesgn.new_interface_modal = new.bool(false)
		I.OpenPopup("New Interface")
	end
	if I.BeginPopupModal("New Interface") then
		I.Text("You are starting a new interface.\nAll changes unsaved will be lost\nContinue?\n\n")
		I.Separator()
		if I.Button("OK", I.ImVec2(120, 0)) then
			elements.Reset()
			I.CloseCurrentPopup()
		end
		I.SetItemDefaultFocus()
		I.SameLine()
		if I.Button("Cancel", I.ImVec2(120, 0)) then I.CloseCurrentPopup() end
		I.EndPopup()
	end
	
	-- Save As... Modal
	require("interface-designer.menu.save-as-modal").SaveAs_Modal()
	
	-- Open Interface Modal
	require("interface-designer.menu.open-interface-modal").OpenInterface_Modal()
	
	-- Debug Window
	if iDesgn.debug_window_flag[0] then
		I.Begin("Debug Window", iDesgn.debug_window_flag)
			I.Text("Log viewer")
			I.SameLine()
			if I.SmallButton("Refresh log file") then log_file_raw = new.char[1024 * 10000]( ReadLogFile() ) end
			I.InputTextMultiline("Log", log_file_raw, 1024 * 10000, I.ImVec2(980, 600))
			I.Separator()
			if I.Button("Close") then iDesgn.debug_window_flag[0] = false end
		I.End()
	end
end

--[[===============================================================
===================================================================]]
return module