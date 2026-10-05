-- Simple plugin to create a uosc button to toggle the sponsorblock_chapterized script
-- needs uosc_controls_modifier.lua  https://github.com/Deulfi/uosc-controls-modifier
-- Add script directory to package.path
local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
script_dir = script_dir:gsub("\\", "/") .. "?.lua;"
package.path = package.path .. ";" .. script_dir
-- and add to your uosc.conf control=
--  button:Sponsorblock_Button
-- and set use_ucm_plugin to yes in sponsorblock_chapterized.conf
local mp = require 'mp'
mp.utils = require "mp.utils"

local button_name = "Sponsorblock_Button"

local button = {
    state_1 = {
        icon = "shield",
        tooltip = "Sponsorblock",
        command = "script-message sponsorblock toggle",
        badge = "UCM_NIL",
        hide = true
    },
    state_2 = {
        icon = "refresh",
        tooltip = "Manual (re)pull Sponsorblockdata",
        command = "script-message-to sponsorblock_chapterized manual_sponsorblock_pull",
        badge = "UCM_NIL",
        hide = false
    },
}

mp.register_script_message('update-icon', function(state, num_seg_found)
    mp.msg.debug("update-icon sponsorblock enabled:", state, "segments:", num_seg_found)
    button.state_1.icon = (state == "true") and "shield" or "remove_moderator"
    button.state_1.hide = false
    button.state_1.badge = num_seg_found
    mp.commandv('script-message-to', 'ucm', 'set-button', button_name, mp.utils.format_json(button))
end)

mp.register_script_message('ucm_ready', function()
    mp.commandv('script-message-to', 'ucm', 'set-button', button_name, mp.utils.format_json(button))
    mp.msg.info("Sponsorblock button created/updated")
end)



