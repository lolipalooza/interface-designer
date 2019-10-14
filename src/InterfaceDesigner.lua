script_name("InterfaceDesigner")
script_author("Mumifag Lalolanda")
script_version("1.0")
script_description("Interface Designer Tool")
require "lib.moonloader"

function main()
	local interfaceDesigner = require("interface-designer.main")
	while true do
		wait (0)
		
		interfaceDesigner.run()
		
		--[[if isKeyDown(require('vkeys').VK_LCONTROL) and isKeyDown(require('vkeys').VK_T) then
			require("interface-designer.globals").RefreshDirectoryTree()
			print(encodeJson( require("interface-designer.globals").InitDirectoryTree() ))
		end]]
	end
end

