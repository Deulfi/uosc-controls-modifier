-- Simple plugin to create a uosc button to toggle the sponsorblock script
-- you need to add
--      mp.commandv('script-message-to', 'ucm_sponsorblock_minimal_plugin', 'update-icon', tostring(ON))
-- to sponsorskip-minimal like shown here

-- function toggle()
-- 	if ON then
-- 		mp.unobserve_property(skip_ads)
-- 		mp.osd_message("[sponsorblock] off")
-- 		--mp.set_property("user-data/sponsorblock", "true")
-- 		ON = false
-- 	else
-- 		mp.observe_property("time-pos", "native", skip_ads)
-- 		mp.osd_message("[sponsorblock] on")
-- 		--mp.set_property("user-data/sponsorblock", "false")
-- 		ON = true
-- 	end
-- 	mp.commandv('script-message-to', 'ucm_sponsorblock_minimal_plugin', 'update-icon', tostring(ON))
-- end
--
-- and add to your memo.conf to control controls
--  <stream>button:Sponsorblock_Button


mp.utils = require "mp.utils"
local script_name = mp.get_script_name()

local button_name = "Sponsorblock_Button2"

local button = {
    state_1 = {
        icon = "shield",
        tooltip = "Sponsorblock",
        command = "script-message sponsorblock toggle"
    }
}

mp.register_script_message('update-icon', function(state)
    button.state_1.icon = (state == "true") and "shield" or "remove_moderator"
    mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-button', button_name, mp.utils.format_json(button))
end)


local result = mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-button', button_name, mp.utils.format_json(button))

if result then
    mp.msg.info("Button created/updated")
else
    mp.msg.error("Button creation failed")
end


