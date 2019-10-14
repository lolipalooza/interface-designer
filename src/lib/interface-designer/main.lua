--[[===============================================================
===================================================================]]
local I = require 'mimgui'
local new = I.new

local MainMenu = require("interface-designer.menu.main-menu")

local iDesgn = require("interface-designer.globals").iDesgn

--[[===============================================================
===================================================================]]
I.OnInitialize(function()
	--iDesgn.directory_tree = require("interface-designer.globals").InitDirectoryTree()
end)

-- The Interface Designer Menu
I.OnFrame(function () return iDesgn.main_menu_flag[0] and not isGamePaused() end, function()
	MainMenu.Show()
end)

--[[===============================================================
===================================================================]]
-- A basic state machine for controling the menu
local stat = 0

local activateConditions = function()
	local activate_cheat = "intdes"
	local vk = require 'vkeys'
	
	return testCheat(activate_cheat) or
		(isKeyDown(vk.VK_LCONTROL) and isKeyDown(vk.VK_I))
end

local isRunning = function()
	return iDesgn.main_menu_flag[0]
end

local setEnviroment = function (flag)
	displayHud(flag)
	displayRadar(flag)
	setPlayerControl(playerchar, flag)
	useRenderCommands(not flag) -- 03F0: enable_text_draw 1
	setTextDrawBeforeFade(not flag) -- 03E0: draw_text_behind_textures 1
end

local run = function ()
	if stat == 0 then
		if activateConditions() then
			clearCharTasks(PLAYER_PED)
			setEnviroment(false)
			iDesgn.main_menu_flag[0] = true
			stat = 1
		end
	elseif stat == 1 then
		if not iDesgn.main_menu_flag[0] then
			stat = 0
			setEnviroment(true)
		end
	end
	
	if isRunning() then
		require("interface-designer.elements").Show()
	end
end


return { run = run, isRunning = isRunning, iDesgn = iDesgn }