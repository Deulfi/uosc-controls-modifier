-- ucm/main.lua
-- Entry point: config, init, IPC handlers

mp.options = require 'mp.options'
local mp_utils = require 'mp.utils'
local utils = require 'utils'
local Button = require 'button'
local ButtonManager = require 'button_manager'
local PropertyManager = require 'property_manager'
-- Local shortcuts for utils functions used in this file
local print_msg = utils.print_msg
local split = utils.split
local get_table_length = utils.get_table_length
local has_value = utils.has_value

-- MARK: config (from ucm.conf, static after load)
local config = {
    revert_delay = 1,
    resolution_mapping = '',
    video_types = '3g2,3gp,asf,av1,avi,f4v,flv,h264,h265,m2ts,m4v,mkv,mov,mp4,mp4v,mpeg,mpg,ogm,ogv,rm,rmvb,ts,vob,webm,wmv,y4m',
    audio_types = 'aac,ac3,aiff,ape,au,cue,dsf,dts,flac,m4a,mid,midi,mka,mp3,mp4a,oga,ogg,opus,spx,tak,tta,wav,weba,wma,wv',
    image_types = 'apng,avif,bmp,gif,j2k,jp2,jfif,jpeg,jpg,jxl,mj2,png,svg,tga,tif,tiff,webp,jpeg_pipe',
    -- String values that count as "true" for the active field (prop-resolved actives,
    -- e.g. [[loop-file]] -> inf/0). Replaces the retired falsy_values blacklist.
    active_truthy_values = 'yes,true,1,inf',
    supress_input_warnings_key = 'ctrl+alt+shift+ü',

    button1 = '',
    button2 = '',
    button3 = '',
    button4 = '',
    button5 = '',
    button6 = '',
    button7 = '',
    button8 = '',
    button9 = '',
    button10 = '',
    button11 = '',
    button12 = '',
    button13 = '',
    button14 = '',
    button15 = '',
}
-- MARK: controlsdata (runtime state, changed via IPC)
local controlsdata = {
    state_map = '',
    state_cycle_map = '',
    res_map_table = {
        { resolution = '1280x720', description = 'HDTV' },
        { resolution = '1920x1080', description = 'FHD' },
        { resolution = '2560x1440', description = 'QHD' },
        { resolution = '3840x2160', description = '4K' },
        { resolution = '7680x4320', description = '8K' },
        { resolution = '5120x2880', description = '5K' },
        { resolution = '1024x768', description = 'XGA' },
        { resolution = '1600x1200', description = 'UXGA' },
        { resolution = '2048x1080', description = '2K (DCI)' },
        { resolution = '4096x2160', description = '4K (DCI)' },
        { resolution = '640x480', description = 'VGA' },
        { resolution = '800x600', description = 'SVGA' },
    },
    buttons = nil,
}

local script_name = mp.get_script_name()
mp.options.read_options(config, script_name)
mp.options.read_options(controlsdata, script_name)
-- Split the comma list from the conf into a table (utils.has_value iterates tables).
config.active_truthy_values = utils.split(config.active_truthy_values, ',')

local ucm_bound_keys = {}

--MARK: parse_buttons_table
-- Build button configuration table from options
local function parse_buttons_table()

    if controlsdata.buttons then 
        print_msg("already_configured", "info")
        return 
    end
    controlsdata.buttons = {}
    
    local button_index = 1
    while true do
        local button_config = config[string.format("button%d", button_index)]
        if not button_config or button_config == "" then break end
        
        local button_name, remaining_config = button_config:match("^%s*([^,]+)%s*,%s*(.+)$")
        if not button_name then 
            print_msg("invalid_format", "warn", button_index, button_config)
            break 
        end
        
        button_name = button_name:gsub('"', '')
        local states = {}
        
        if not remaining_config or remaining_config == "" then
            print_msg("no_states", "warn", button_name)
            button_index = button_index + 1
            return
        end
        
        local state_definitions = split(remaining_config, ",")
        for state_index, state_def in ipairs(state_definitions) do
            local state_parts = split(state_def, "@")
            if #state_parts ~= 2 then
                print_msg("invalid_state", "warn", button_name, state_index)
                return
            end
            local state_name, properties = state_parts[1], state_parts[2]
            
            if not controlsdata.state_map then 
                controlsdata.state_map = { default = state_name } 
            end

            local property_pairs = utils.split_fields(properties)
            if not property_pairs then
                print_msg("no_properties", "warn", button_name, state_name)
                return
            end
            
            local state = {}
            
            for prop_index, prop in ipairs(property_pairs) do
                local name, content = unpack(split(prop, "="))
                if name and content then
                    state[name] = content
                else
                    print_msg("invalid_property", "warn", button_name, state_name, prop_index)
                end
            end
            
            if next(state) then
                states[state_name] = state
            else
                print_msg("empty_state", "warn", button_name, state_name)
            end
        end
        
        if next(states) then
            controlsdata.buttons[button_name] = states
            print_msg("success_button", "debug", button_name, get_table_length(states))
        else
            print_msg("no_valid_states", "warn", button_name)
        end
        
        button_index = button_index + 1
    end
    
    if next(controlsdata.buttons) then
        print_msg("success_total", "debug", get_table_length(controlsdata.buttons))
    else
        print_msg("no_valid_buttons", "warn", script_name)
    end
end
--MARK: parse_state_mappings
local function parse_state_mappings(new_state_map, new_cycle_map)
    local state_map_to_parse = new_state_map or controlsdata.state_map
    local cycle_map_to_parse = new_cycle_map or controlsdata.state_cycle_map
    local state_map = {}
    local cycle_states = {}
    if state_map_to_parse and state_map_to_parse ~= "" then
        local items = split(state_map_to_parse, ",")
        
        for index, item in ipairs(items) do
            local state_name, key = unpack(split(item, ":"))
            
            -- Add to cycle states first
            if not has_value(cycle_states, state_name) then
                table.insert(cycle_states, state_name)
            end
            
            -- Then handle modifier mapping
            if key then
                state_map[key] = state_name
            elseif index == 1 then
                state_map["default"] = state_name --no modifier buttons defined, generating default
            elseif index >= 2 then
                state_map["key_" .. index] = state_name --generic names generic names after first generic names
            end
        end
    else
        state_map = { default = "" }
        cycle_states = nil
    end

    controlsdata.state_map = state_map

    print_msg("state_mappings_parsed", "debug")
    print_msg("state_map_debug", "debug", mp_utils.to_string(controlsdata.state_map))
    if cycle_map_to_parse ~= "" and type(cycle_map_to_parse) == "string" then 
        cycle_map_to_parse = split(cycle_map_to_parse, ",")
    end
    controlsdata.state_cycle_map = cycle_states or cycle_map_to_parse or {}
    
    print_msg("state_cycle_map_debug", "debug", mp_utils.to_string(controlsdata.state_cycle_map))
end
--MARK: parse_resolution_mappings
local function parse_resolution_mappings()
    if config.resolution_mapping == "" then return end

    local new_mappings = split(config.resolution_mapping, ",", ":")
    for resolution, display_name in pairs(new_mappings) do
        local changed = false
        for _, mappings in ipairs(controlsdata.res_map_table) do
            if mappings.resolution == resolution then
                mappings.description = display_name
                changed = true
                print_msg("resolution_mapping_updated", "info", resolution, display_name)
                break
            end
        end
        if not changed then
            table.insert(controlsdata.res_map_table, {
                resolution = resolution,
                description = display_name
                
            })
            print_msg("resolution_mapping_added", "debug", resolution, display_name)
        end
    end
end

--MARK: setup_input_events
local function setup_input_events()
    -- Unbind all previously bound keys (S4 fix)
    for _, key in ipairs(ucm_bound_keys) do
        mp.commandv('script-message-to', 'inputevent', 'unbind', key)
    end
    ucm_bound_keys = {}
    if not controlsdata.state_map or get_table_length(controlsdata.state_map) == 0 then
        print_msg("no_state_map_inputevent", "warn")
        return
    end

    for key, state_name in pairs(controlsdata.state_map) do
        -- used for debugging
        local is_mouse = key:find("^MBTN_") and true or false
        if not (state_name == 'default' or key:find("^key_%d+$")) then
        local on = {
            press      = string.format("script-message-to %s set %s",               script_name, state_name),
            release    = string.format("script-message-to %s revert_inputevent %s", script_name, is_mouse),
            ["repeat"] = string.format("script-message-to %s cancel_revert",        script_name)
        }

        if config.supress_input_warnings_key then
            if key == 'default' then key = config.supress_input_warnings_key end
        end

        local success = mp.commandv('script-message-to', 'inputevent', 'bind', key, mp_utils.format_json(on))

        if not success then
            print_msg("inputevent_bind_failed", "info")
            return
        end
        ucm_bound_keys[#ucm_bound_keys + 1] = key
        end
        
    end
    local revert_timer = nil
    -- Cancel existing timer if it exists
    mp.register_script_message('cancel_revert', function()
        if revert_timer then
            revert_timer:kill()
        end
    end)
    
    -- Register revert_inputevent message handler
    mp.register_script_message('revert_inputevent', function(is_mouse)
        print_msg("revert_inputevent")
        -- Create new timer that is either killed as long as keyboard key is pressed or runs out if mousebutton
        revert_timer = mp.add_timeout(0.3 + config.revert_delay/10, function()
            --mp.set_property_number("user-data/ucm_currstate", 1)
            mp.commandv('script-message-to', script_name, 'set', 'default')
        end)
    end)
end
function Setup_manager(manager, script_name)
    manager = ButtonManager.new(config, controlsdata, script_name)
    manager:init()
    return manager
end


--MARK: Main initialization
parse_state_mappings()
parse_resolution_mappings()
parse_buttons_table()
setup_input_events() 

local manager = nil
manager = Setup_manager(manager, script_name)

mp.commandv('script-message', 'ucm_ready', "true")
--MARK: IPC handlers (register_script_message calls)
--mp.register_script_message('update-button', function(button_name)
--mp.register_script_message('set', function(state_name)
--mp.register_script_message('set-default', function(new_default_state)
--mp.register_script_message('revert-default', function()
--mp.register_script_message('cycle', function()
--mp.register_script_message('cycle-back', function()
--mp.register_script_message('get-cycle-states', function(receiver)
--mp.register_script_message('set-cycle-states', function(new_states)
--mp.register_script_message('get-state-map', function(receiver)
--mp.register_script_message('set-state-map', function(new_map)
--mp.register_script_message('get-buttons', function(button_receiver)
--mp.register_script_message('set-buttons', function(buttons_json)
--mp.register_script_message('get-button', function(button_receiver, button_name)
--mp.register_script_message('set-button', function(...)
local function safe_json_parse(json_string, error_context)
    local success, result = pcall(mp_utils.parse_json, json_string)
    if not success then
        print_msg("json_parse_error", "error", error_context or "JSON parse error", tostring(result))
        return nil
    end
    if type(result) ~= "table" then
        print_msg("invalid_data_format", "error", type(result), error_context or "Invalid data format - expected table")
        print_msg("json_parse_debug", "debug", tostring(result), json_string)
        return nil
    end
    return result
end

local function safe_json_stringify(data, error_context)
    local success, result = pcall(mp_utils.format_json, data)
    if not success then
        print_msg("json_stringify_error", "error", error_context or "JSON stringify error")
        return nil
    end
    return result
end

mp.register_script_message('cycle', function()
    if not controlsdata.state_cycle_map then return end
    local current_state = mp.get_property_number("user-data/ucm_currstate") or 1
    local num_states = #controlsdata.state_cycle_map
    local next_state = num_states > 0 and ((current_state) % num_states) + 1 or 1
    
    mp.set_property_number("user-data/ucm_currstate", next_state)
    manager.property_manager.property_map.values["user-data/ucm_currstate"] = next_state
    manager:set_button_state(controlsdata.state_cycle_map[next_state])
    print_msg("cycle_to_state", "debug", next_state)
    return true
end)

mp.register_script_message('cycle-back', function()
    local current_state = mp.get_property_number("user-data/ucm_currstate") or 1
    local num_states = #controlsdata.state_cycle_map
    -- 1-based modulo backward: (i-2) % n + 1
    local next_state = num_states > 0 and ((current_state - 2) % num_states) + 1 or 1
    
    mp.set_property_number("user-data/ucm_currstate", next_state)
    manager:set_button_state(controlsdata.state_cycle_map[next_state])
    return true
end)

mp.register_script_message('get-cycle-states', function(receiver)
    local json_string = safe_json_stringify(controlsdata.state_cycle_map, "get-cycle-states failed")
    if not json_string then return end
    mp.commandv('script-message-to', receiver, 'receive-cycle-states', json_string)
    return true
end)

mp.register_script_message('set-cycle-states', function(new_states)
    if type(new_states) ~= "string" then
        print_msg("new_states_not_string", "error")
        return
    end
    controlsdata.state_cycle_map = split(new_states, ",")
    -- Re-parse to pick up new cycle states
    manager:parse_new_states()
    return true
end)

mp.register_script_message('get-state-map', function(receiver)
    local state_map_string = table.concat(controlsdata.state_cycle_map, ", ")
    mp.commandv('script-message-to', receiver, 'receive-state-map', state_map_string)
    return true
end)
mp.register_script_message('set-state-map', function(new_map)
    if type(new_map) ~= "string" then
        print_msg("new_state_map_not_string", "error")
        return
    end
    print_msg("new_state_map_received", 'debug')
    parse_state_mappings(new_map)
    setup_input_events()
    manager:update_defaults()
    manager:register_default_handlers()
    return true
end)
mp.register_script_message('get-buttons', function(button_receiver)
    local buttons_json = safe_json_stringify(manager.buttons, "get-buttons failed")
    if not buttons_json then return end
    mp.commandv('script-message-to', button_receiver, 'receive-buttons', buttons_json)
    return true
end)
mp.register_script_message('set-buttons', function(buttons_json, caller)
    print_msg("set_buttons_called", "debug", caller)
    local parsed_buttons = safe_json_parse(buttons_json, "set-buttons failed")
    if not parsed_buttons then return end
    print_msg("buttons_received", 'debug')

    -- Check for default state using parsed data
    if not manager.default_state_name or manager.default_state_name == "" then
        -- Get first button and its first state
        for button_name, button_data in pairs(parsed_buttons) do
            for state_name, _ in pairs(button_data.states or button_data) do
                manager.default_state_name = state_name
                manager.current_active_state = manager.default_state_name
                controlsdata.state_map = { default = state_name }
                break
            end
            break  -- Only check first button
        end
    end

    local translated = {}
    for button_name, button_data in pairs(parsed_buttons) do
        translated[button_name] = button_data.states
    end
    controlsdata.buttons = get_table_length(translated) > 0 and translated or parsed_buttons
    -- Update existing manager in-place instead of full rebuild (S24 fix)
    manager:unregister_all_handlers()
    manager:parse_new_states()
    manager:initialize_buttons()
    manager:register_default_handlers()
    manager:register_script_messages()
    manager:refresh_all_buttons()
    return true
end)
mp.register_script_message('get-button', function(button_receiver, button_name)
    if manager.buttons[button_name] then
        local button_json = safe_json_stringify(manager.buttons[button_name].states, "get-button failed")
        if not button_json then return end
        mp.commandv('script-message-to', button_receiver, 'receive-button', button_name, button_json)
    else
        print_msg("button_not_found", "error", button_name)
    end
    return true
end)
mp.register_script_message('set-button', function(...)
    local args = {...}
    local button_name = args[1]
    local states_json = table.concat(args, " ", 2)
    local button_states = safe_json_parse(states_json, "set-button failed")

    if not button_states then 
        print_msg("parse_button_failed", "debug")
        return false
    end

    if manager.buttons[button_name] then
        print_msg("update_button", "debug", button_name)
        manager:update_button_data(button_name, button_states)
    else
        print_msg("register_new_button", "debug", button_name)
        manager:register_new_button(button_name, button_states)
    end

    return true
end)
--TODO: for set buttons, if there is a key in the table, assume nil is intended to be nil and not empty for cloning.
--TODO: can confirm, without icon on state_2 it got it from state_1, but the pointer and not a copy. set-button logic is flawed.
        -- should be the update_button_data flow.
--TODO: add some logic that sends a message when ucm is ready to receive buttons or implement set-button(s) in such a way, that it holds them
        -- until ucm is ready for them. timeout? 
--TODO: there is possible some unintended inheritance on for example badge. set state_1 badge to 4 and state_2.badge was also for
        -- cant even nil it because of the bug below.
--TODO: set-button does not work with nil values. e.g. you want to hide the badge on state_2.
--TODO: fix button.state.hide not working with boolean anymore.
--TODO: hide = true in the default state should be copied to filled up states, or they would show up when cycling states.
        --bug: its seemingly overwriting hide values. e.g. state_1 hide = true and state_2 hide = false, if you switch from 2 to 1, 1 is visible after.
--TODO: update via set-button breaks the observer that make the shuffle button active / inactive
--TODO: fill up states not working anymore. me.v.2.0: ??? it is working, look at the debug messages?
--TODO: change user-data/ucm_currstate when using set-default. inputevent reregister? because state_2 is rightclick and now default...
        -- just use a var that corrects the state name, like state_2? uuhhm you meant state_1... since its only 2 states that can be flipped no bigie
        -- me.v.2.0: ??? no clue.
--TODO: try to fix inbuild mpv cycle props with custom props. noooope mpv bug? shitty documentation? dunno
--TODO: mini controls button menu after uosc pr got acepted (well, it got denied[not without reason])? Menubutton is visible and 3 buttons with content are invisible
--       first click shows first state until nth state and a final click makes the content button invisible again.
--       would be usefull for one state contrast one state brightness etc.
