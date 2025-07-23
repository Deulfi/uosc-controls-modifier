local buttons = {
    alt_control_items = {
        state_1 = {
            icon = "list_alt",
            tooltip = "Playlist/Files",
            command = "script-message-to uosc items",
        },
        state_2 = {
            tooltip = "Files",
            command = "script-message-to uosc open-file",
        },
        state_3 = {
            icon = "folder_open",
            tooltip = "File Dialog",
            command = "script-message-to uosc show-in-directory",
        },
        fullscreen = {
            icon = "list_alt",
            tooltip = "fullscreen",
            command = "script-message-to uosc items",
        },
    },
    alt_control_loop = {
        state_1 = {
            icon = "repeat",
            active = "[[loop-playlist]]",
            tooltip = "Loop playlist",
            command = "no-osd cycle-values loop-playlist no inf",
        },
        state_2 = {
            icon = "repeat_one",
            active = "[[loop-file]]",
            tooltip = "Loop file",
            command = "no-osd cycle-values loop-file no inf",
        },
    },
    alt_format = {
        state_1 = {
            badge = "?(f)",
            tooltip = "[[video-codec]]",
        },
    },
    alt_resolution = {
        state_1 = {
            badge = "?(p)",
            tooltip = "[[video-params/w]]x[[video-params/h]]",
            command = "script-message-to uosc stream-quality",
        },
    },
    alt_shuffle = {
        state_1 = {
            icon = "shuffle",
            active = "[[user-data/uosc_shuffle?no yes]]",
            tooltip = "Shuffle",
            command = "script-binding uosc/shuffle",
        },
        state_2 = {
            icon = "transform",
            tooltip = "Shuffle Playlist",
            command = "playlist-shuffle",
        },
        state_3 = {
            icon = "low_priority",
            tooltip = "Unshuffle Playlist",
            command = "playlist-unshuffle",
        },
    },
    alt_previous = {
        state_1 = {
            icon = "arrow_back_ios",
            tooltip = "Previous",
            command = "script-binding uosc/prev",
        },
        state_2 = {
            tooltip = "Previous Chapter",
            command = "add chapter -1",
        },
    },
    alt_next = {
        state_1 = {
            icon = "arrow_forward_ios",
            tooltip = "Next",
            command = "script-binding uosc/next",
        },
        state_2 = {
            tooltip = "Next Chapter",
            command = "add chapter 1",
        },
    },
    alt_cycle = {
        state_1 = {
            icon = "loop",
            tooltip = "cycle states",
            badge = "?(c)",
            command = "?(c)",
        },
    },
}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
local script_name = mp.get_script_name()

local state_map="state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID,state_2:x"
local state_map2="state_1,state_2,state_3"

mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-state-map', state_map)

for button_name, button in pairs(buttons) do
    local button_json = mp.utils.format_json(button)
    local returns = mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-button', button_name, button_json)
    mp.msg.info("Setting button:", button_name, "returned:", returns)
end
