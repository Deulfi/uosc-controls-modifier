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
            tooltip = "Playlist/Files",
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
            active = "[[uosc_shuffle!!no yes]]",
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
            badge = "1",
            command = "script-message-to ucm cycle",
            hide = false,
        },
        state_2 = {
            icon = "loop",
            tooltip = "cycle states",
            badge = "2",
            command = "script-message-to ucm cycle",
            hide = false,
        },
        state_3 = {
            icon = "loop",
            tooltip = "cycle states",
            badge = "3",
            command = "script-message-to ucm cycle",
            hide = false,
        },
    },
    audiodevice_button = {
        state_1 = {
            icon = "earbuds",
            active = "[[audio-device?!auto]]",
            tooltip = "Audiodevice is auto",
            command = "script-binding uosc/audio-device",
        },
        state_2 = {
            icon = "speaker",
            active = "[[audio-device?!wasapi/{4b4b5acd-acb3-45b5-8d4f-c078d36afcba}]]",
            tooltip = "Audiodevice is speaker",
            command = "set audio-device wasapi/{4b4b5acd-acb3-45b5-8d4f-c078d36afcba}",
        },
        state_3 = {
            icon = "headphones",
            active = "[[audio-device?!wasapi/{b925d73f-1320-40e3-a2da-334b3ef85225}]]",
            tooltip = "Audiodevice is headphones",
            command = "set audio-device wasapi/{b925d73f-1320-40e3-a2da-334b3ef85225}",
        },
    },
    download_button = {
        state_1 = {
            icon = "download",
            tooltip = "Send current stream to FFmpeg webhook",
            command = "script-message download-ffmpeg",
            hide = false,
        },
        state_2 = {
            tooltip = "Send current stream to MeTube",
            command = "script-message download-metube",
        },
    },
    new_button = {
        state_1 = { hide = true },
    },
}
local mp = require "mp"
mp.utils = require "mp.utils"
mp.options = require "mp.options"
local script_name = mp.get_script_name()
-- Guard: prevent duplicate loading from mpv auto-discovery
if script_name ~= "ucm_inject_buttons" then
    return
end
local state_key_map="state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID,state_2:x"

-- Target script is "ucm" (loaded from ucm/main.lua, identified by mpv as "ucm")
local target_script = "ucm"

-- Wait for ucm's ready broadcast before dispatching (a top-level send would race ucm's load)
mp.register_script_message('ucm_ready', function()
    mp.commandv('script-message-to', target_script, 'set-state-map', state_key_map)
end)

-- Track buttons already registered via declared config, to avoid overwriting them
local registered_buttons = {}
local _send_buttons

mp.register_script_message('receive-buttons', function(buttons_json)
    if not buttons_json then return end
    local ok, parsed = pcall(mp.utils.parse_json, buttons_json)
    if ok and parsed then
        registered_buttons = parsed
    end
    _send_buttons()
end)

-- Wait for ucm-refresh-done before sending buttons (ensures path/video props are populated)
local sent = false
_send_buttons = function()
    if sent then return end
    sent = true
    for button_name, button in pairs(buttons) do
        if not registered_buttons[button_name] then
            local button_json = mp.utils.format_json(button)
            local returns = mp.commandv('script-message-to', target_script, 'set-button', button_name, button_json)
            mp.msg.info("Setting button:", button_name, "returned:", returns)
        end
    end
end

mp.register_script_message('ucm-refresh-done', function()
    if sent then return end
    mp.commandv('script-message-to', target_script, 'get-buttons', mp.get_script_name())
end)
