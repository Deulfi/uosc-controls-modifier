--MARK: options
local options = {
  -- for mousebuttons: delay in ms to revert button state, if you want the updated state to be shown longer before reverting to default state.
  -- for keyboard: stays in the modified state until the key is released and the revert_delay is high enough.
  revert_delay = 1, 

  -- what modifier keys correspond to which state, holding down the right mouse button would change the buttons to the second state (state_2)
  -- state:key
  state_map = "",

  -- other order of states, if you want to cycle through them
  state_cycle_map="",

  res_map_table = {
    { resolution = "1280x720", description = "HDTV" },
    { resolution = "1920x1080", description = "FHD" },
    { resolution = "2560x1440", description = "QHD" },
    { resolution = "3840x2160", description = "4K" },
    { resolution = "7680x4320", description = "8K" },
    { resolution = "5120x2880", description = "5K" },
    { resolution = "1024x768", description = "XGA" },
    { resolution = "1600x1200", description = "UXGA" },
    { resolution = "2048x1080", description = "2K (DCI)" },
    { resolution = "4096x2160", description = "4K (DCI)" },
    { resolution = "640x480", description = "VGA" },
    { resolution = "800x600", description = "SVGA" }
  },
  resolution_mapping = "",

  
  -- formats that denote what format should be shown
  video_types = '3g2,3gp,asf,av1,avi,f4v,flv,h264,h265,m2ts,m4v,mkv,mov,mp4,mp4v,mpeg,mpg,ogm,ogv,rm,rmvb,ts,vob,webm,wmv,y4m',
  audio_types = 'aac,ac3,aiff,ape,au,cue,dsf,dts,flac,m4a,mid,midi,mka,mp3,mp4a,oga,ogg,opus,spx,tak,tta,wav,weba,wma,wv',
  image_types = 'apng,avif,bmp,gif,j2k,jp2,jfif,jpeg,jpg,jxl,mj2,png,svg,tga,tif,tiff,webp,jpeg_pipe',

  buttons = nil,
  buttonexample = 
  {
    example = 
    {
        state_8 = {
            icon = "example_3",
            tooltip = "example_3",
            badge = "3",
            active = "nil",
            hide = "false",
        },
        state_1 = {
            icon = "exmample",
            badge = "nil",
            active = "false",
            tooltip = "Playlist/Files",
            command = "some command or script-message-to uosc"
        },
        state_2 = {
            icon = "example_2",
            badge = "2",
            active = "true",
            tooltip = "example tooltip",
            command = "script-message-to uosc menu"
        }
    }
  },
  button1 = "",
  button2 = "",
  button3 = "",
  button4 = "",
  button5 = "",
  button6 = "",
  button7 = "",
  button8 = "",
  button9 = "",
  button10 = "",
  button11 = "",
  button12 = "",
  button13 = "",
  button14 = "",
  button15 = "",

  fill_up_states = true,
  falsy_values = { "", "no", "false", "0", false, nil, 0, "0", "nil" },
}
mp.utils = require "mp.utils"
local msg = require "mp.msg"
mp.options = require "mp.options"
local script_name = mp.get_script_name()
mp.options.read_options(options, script_name)

local track_state_properties = {}
local PropertyManager = {}
local ButtonManager = {}
local buttonmanager_setup_finished = false
local state_map = {}

local placeholders = {
    ["%?%(f%)"] = {
        type = "format",
        -- active props update the button on property change "file-loaded",
        props_active = {},
        -- passive props only update the value on property change
        props_passive = {"path","video-codec-name","video-format", "audio-codec-name"},
        fun = function(self) return self:getMediaFormatLabel() end,
    },
    ["%?%(p%)"] = {
        type = "resolution", 
        props_active = {},
        props_passive = {"video-params/h","video-params/w"},
        fun = function(self) return self:getVideoResolutionLabel() end,
    },
    ["%?%(c%)"] = {
        type = "state",
        props_active = {"user-data/ucm_currstate"},
        props_passive = {},
        fun = function(self) return self.property_map.values["user-data/ucm_currstate"] end,
    }
}

local placeholders_command = {
    {pattern = "%?%(c%-%)", command = "script-message-to " .. script_name .. " cycle-back"},
    {pattern = "%?%(c%)", command = "script-message-to " .. script_name .. " cycle"}
}

local messages = {
    already_configured = "Buttons already configured, skipping parsing",
    invalid_format = "Button %d: Invalid format - expected 'button_name, config'. Found: %s",
    no_states = "Button '%s': No state configurations provided",
    invalid_state = "Button '%s', State %d: Invalid state format - expected 'state_name@properties'",
    no_properties = "Button '%s', State '%s': No properties defined",
    invalid_property = "Button '%s', State '%s': Invalid property format at position %d - expected 'key=value'",
    empty_state = "Button '%s', State '%s': No valid properties found",
    no_valid_states = "Button '%s': No valid states configured",
    success_button = "Successfully translated button '%s' with %d states",
    success_total = "Total buttons translated: %d",
    no_valid_buttons = "No valid buttons configured from %s.conf",
    no_default_state ="No default state defined for button '%s'",
}


--MARK: Utils
-- Helper function to extract properties enclosed in double square brackets
local function extract_properties(input_string)
    if not input_string then return nil end
    local results = {}
    for match in input_string:gmatch("%[%[([^%]]+)%]%]") do
        table.insert(results, match)
    end
    return #results > 0 and results or nil
end


local function split(input_string, primary_separator, key_value_separator)
    local result = {}
    if not input_string then return nil end
    for item in input_string:gmatch(string.format("([^%s]+)", primary_separator)) do
        if key_value_separator then
            local key, value = item:match("(.+)" .. key_value_separator .. "(.+)")
            if key and value then
                result[key] = value
            end
        else
            result[#result + 1] = item
        end
    end
    
    return result
end

--- Finds the index of a value in a table
--- @param tbl table The table to search
--- @param value any The value to find
--- @return number|nil Index of the value or nil if not found
local function table_find(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

local function shallow_copy(t)
    if t == nil or type(t) ~= "table" then return nil end
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

local function get_table_length(t)
    if t == nil or type(t) ~= "table" then return nil end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function print_msg(msg_key, msg_type, ...)
    if not msg_key then msg_key = "qwe" end
    if not msg_type then msg_type = "debug" end
    local msg_string = messages[msg_key] or msg_key
    local msg = string.format(msg_string, ...)
    if msg_type == "error" then
        mp.msg.error(msg)
    elseif msg_type == "warn" then
        mp.msg.warn(msg)
    elseif msg_type == "debug" then
        mp.msg.debug(msg)
    else
        mp.msg.info(msg)
    end
end

local function has_value(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end
--MARK: ##########





--MARK: Button Class
local Button = {}
Button.__index = Button

-- Default State Template
local DEFAULT_STATE = {
    icon    = "",
    badge   = nil,
    active  = false,
    tooltip = "",
    command = string.format("script-message-to %s lable", script_name), --Do Nothing
}
local STATE_SCHEMA = {
    valid_fields = {
        icon    = {"string", "nil"},
        badge   = {"string", "nil"},
        active  = {"string", "boolean", "nil"},
        tooltip = {"string", "nil"},
        command = {"string"}
    }
}
--MARK: validate_state
function validate_button_state(state_name, state, button_name)
    if type(state) ~= "table" then
        mp.msg.error(string.format("Invalid state '%s' for button '%s': must be a table", state_name, button_name))
        return false
    end

    -- Only validate fields that are present
    for field, value in pairs(state) do
        local valid_types = STATE_SCHEMA.valid_fields[field]
        if valid_types then
            local value_type = type(value)
            local type_valid = false
            for _, valid_type in ipairs(valid_types) do
                if value_type == valid_type or (value == nil and valid_type == "nil") then
                    type_valid = true
                    break
                end
            end
            if not type_valid then
                mp.msg.error(string.format("Invalid type for field '%s' in state '%s' for button '%s': expected one of %s, got %s",
                    field, state_name, button_name, table.concat(valid_types, ", "), value_type))
                return false
            end
        end
    end

    return true
end
--MARK: new
function Button.new(name, states)
    local self = setmetatable({}, Button)
    self.name = name
    self.states = states
    self.states_translated = {}
    self.active_state = nil
    self.default_state_name = ""
    return self
end
--MARK: init
function Button:initialize_states(default_state_name)
    -- Validate all states
    for state_name, state in pairs(self.states) do
        if not validate_button_state(state_name, state, self.name) then
            mp.msg.warn(string.format("Using default values for invalid state '%s' in button '%s'", 
                state_name, self.name))
            self.states[state_name] = shallow_copy(DEFAULT_STATE)
        end

    end

    self.default_state_name = default_state_name
    self.active_state = self.states_translated[self.default_state_name]

    -- Fill states with defaults
    local first_state = self.states[self.default_state_name]
    if not first_state then
        print_msg("no default state", 'error', self.name)
        return
    end
    -- Fill Default State with default values
    for key, value in pairs(DEFAULT_STATE) do
        first_state[key] = first_state[key] or value
    end

    -- Fill other states with values from the first_state (default)
    for state_name, state in pairs(self.states) do
        for key, fill_value in pairs(first_state or DEFAULT_STATE) do
            -- Only fill empty state values, except for 'active' properties
            -- This prevents unwanted property inheritance between states
            -- Example: state_1 with property-based active state should not copy to state_2, because
            -- state_2 is static
            if (state[key] == nil or state[key] == "") and 
               not (key == "active" and extract_properties(fill_value)) then
                state[key] = fill_value

            end
        end

        -- Initialize translated states
        self.states_translated[state_name] = shallow_copy(self.states[state_name])
    end
    -- show default
    self:update_state(self.default_state_name)
    return self
end

--MARK: update_state
function Button:update_state(state_name)
    local state = self.states_translated and self.states_translated[state_name] or self.active_state
    if not state then
        if options.fill_up_states then
            mp.msg.warn("Unknown state:",state, "name:", state_name, "button:", self.name)
        end
        return
    end

    self.active_state = state
    
    if  has_value(options.falsy_values, state.active) then
            state.active = false 
    end

    if state.badge   == "nil" then state.badge   = nil end
    if state.tooltip == "nil" then state.tooltip = nil end

    if state.hide == "true" then state.hide = true end
    if state.hide == "false" then state.hide = false end

    --msg.error("Button name: ", self.name,"state_name: ", state_name, "tooltip ", state.tooltip)

    mp.commandv('script-message-to', 'uosc', 'set-button', self.name, mp.utils.format_json({
        icon    = state.icon,
        badge   = state.badge,
        active  = state.active,
        tooltip = state.tooltip,
        command = state.command,
        hide    = state.hide or false,
    }))
end
--MARK: ############




--MARK: ButtonManager
--ButtonManager Class
ButtonManager.__index = ButtonManager
function ButtonManager.new()
    local self = setmetatable({}, ButtonManager)
    self.property_manager     = PropertyManager.new()
    self.buttons              = {}
    self.state_map            = {}
    self.unique_states        = {}
    self.current_active_state = ""
    self.default_state_name   = ""
    
    return self
end

function ButtonManager:init()
    self.state_map = options.state_map
    self.default_state_name = self.state_map['default']
    self.current_active_state = self.default_state_name
    
    self:initialize_buttons()
    self:manage_unique_states()
    self:register_default_handlers()

    mp.register_script_message('update-button', function(button_name)
        self:update_button(button_name)
    end)

    -- NEW: Add the property change handler here
    mp.register_script_message('property-changed', function(prop_name, value)
        local affected_buttons = self.property_manager.property_map.standard[prop_name] or {}
        for _, button_name in ipairs(affected_buttons) do
            local button = self.buttons[button_name]
            if button then
                for _, data in ipairs(self.property_manager.property_map.buttons[button_name] or {}) do
                    self:handle_substitution(button, prop_name, data)
                end
                button:update_state(self.current_active_state)
            end
        end
    end)

    -- File-loaded event needed because some buttons use special placeholders (?(f), etc.)
    -- with passive properties that don't have automatic observers. Without this refresh,
    -- these buttons would show placeholder text instead of actual values.
    mp.register_event("file-loaded", function()
        -- Small timeout to make sure all properties are initialized by MPV
        mp.add_timeout(0.1, function()
            self:refresh_all_buttons()
        end)
    end)
    buttonmanager_setup_finished = true
end

-- refresh, mostly for startup
function ButtonManager:refresh_all_buttons()
    for button_name, data in pairs(self.property_manager.property_map.buttons) do
        local button = self.buttons[button_name]
        if button then
            for _, data in ipairs(data) do
                self:handle_substitution(button, data.prop, data)
            end
            button:update_state(self.current_active_state)
        end
    end
end

--MARK: manage uniques
function ButtonManager:manage_unique_states(button_states)
    local source = button_states or options.buttons
    local new_states = {}

    -- Extract states from either button_states or options.buttons
    for _, button_data in pairs(source) do
        local states_to_check = button_states and button_data.states or button_data
        for state in pairs(states_to_check) do
            if not self.unique_states[state] then
                mp.msg.debug("Found new state: " .. state)
                new_states[state] = true
                -- Register message handler for the new state
                self:register_message_handler(state)
            end
            self.unique_states[state] = true
        end
    end

    -- Always update ALL buttons with ALL unique states to prevent race conditions
    if options.fill_up_states and next(self.buttons) then 
        mp.msg.debug("Updating existing buttons with new states")
        for index, button in pairs(self.buttons) do
            -- Get the default state for this button
            local default_state_name = button.default_state_name or self.default_state_name
            local default_state = button.states[default_state_name]
            local default_translated = button.states_translated[default_state_name]
            
            if not default_state then
                mp.msg.warn("No default state found for button " .. button.name .. ", skipping state fill-up")
                goto continue
            end
            
            for state in pairs(self.unique_states) do
                if not button.states[state] then
                    mp.msg.debug("Adding state " .. state .. " to button " .. button.name)
                    button.states[state] = shallow_copy(default_state)
                    -- we don't want to copy the translated states but we want to have the same values always
                    -- shouldn't matter if we change a value in the default state or any other. they are always the same value
                    -- the translated_states are the values we actually give uosc to process.
                    button.states_translated[state] = button.states_translated[default_state_name]
                end
            end
            ::continue::
        end
    end
end


--MARK: init buttons
function ButtonManager:initialize_buttons()
    for button_name, button_states in pairs(options.buttons) do
        self:initialize_button(button_name, button_states)
    end
end
-- better than nothing
function ButtonManager:aprox_default(fallback_states)
    local state_count = {}
    local source = nil
    local source_name = ""
    
    -- Try self.buttons first
    if self.buttons and next(self.buttons) then
        source = self.buttons
        source_name = "self.buttons"
        for button_name, button in pairs(source) do
            for state_name in pairs(button.states) do
                state_count[state_name] = (state_count[state_name] or 0) + 1
            end
        end
    -- Try options.buttons
    elseif options.buttons and next(options.buttons) then
        source = options.buttons
        source_name = "options.buttons"
        for button_name, button_states in pairs(source) do
            for state_name in pairs(button_states) do
                state_count[state_name] = (state_count[state_name] or 0) + 1
            end
        end
    -- Try fallback_states parameter
    elseif fallback_states and next(fallback_states) then
        source = {temp_button = fallback_states}
        source_name = "fallback_states"
        for state_name in pairs(fallback_states) do
            state_count[state_name] = (state_count[state_name] or 0) + 1
        end
    else
        mp.msg.error("aprox_default: No button data available - self.buttons, fallback_states, and options.buttons are all empty")
        return ""
    end

    local max_count = 0
    local most_frequent_state = ""

    for state_name, count in pairs(state_count) do
        if count > max_count then
            max_count = count
            most_frequent_state = state_name
        end
    end

    mp.msg.debug(string.format("aprox_default: Using %s, found default state: %s", source_name, most_frequent_state))

    -- Fix broken/missing state_map
    if most_frequent_state and most_frequent_state ~= "" then
        self.state_map['default'] = most_frequent_state
        self.default_state_name = most_frequent_state
        mp.msg.debug("aprox_default: Updated state_map['default'] to:", most_frequent_state)
    end

    return most_frequent_state
end

function ButtonManager:initialize_button(button_name, button_states)
    local processed_states = self.property_manager:translate_button_properties(button_name, button_states)
    
    local button = Button.new(button_name, processed_states)
    -- if self.default_state_name is empty or nil, aprox a default
    local state_name = self.default_state_name
    if not state_name or state_name == "" then
        state_name = self:aprox_default(button_states)
    end
    button:initialize_states(state_name)
    self.property_manager:track_states_properties(button_name, button.states)
    
    self.buttons[button_name] = button
    msg.debug("Button added:", button_name)
end
--MARK: register_button
function ButtonManager:register_new_button(button_name, button_states)
    -- First initialize the button
    self:initialize_button(button_name, button_states)
    -- Then manage unique states to fill up all buttons (including the new one)
    self:manage_unique_states({[button_name] = {states = button_states}})
end


--MARK: update_button_data
function ButtonManager:update_button_data(button_name, button_states)

    -- Update the button's states
    local button = self.buttons[button_name]
    button.states = button_states
    
    -- Re-translate properties and reinitialize
    local processed_states = self.property_manager:translate_button_properties(button_name, button_states)
    button.states = processed_states
    button.states_translated = {}
    
    -- Reinitialize the button with new states
    -- if self.default_state_name is empty or nil, aprox a default
    local state_name = self.default_state_name
    if not state_name or state_name == "" then
        state_name = self:aprox_default(button_states)
    end
    button:initialize_states(state_name)
    
    -- Update property tracking
    self.property_manager:track_states_properties(button_name, button.states)
    
    -- Manage unique states for the updated button
    self:manage_unique_states({[button_name] = {states = button_states}})
    
    -- Update the button display
    button:update_state(self.current_active_state)
end


--MARK: set_button_state
function ButtonManager:set_button_state(state_name)
    mp.msg.trace("setting button state to " , state_name)
    if not state_name or state_name == "" then
        mp.msg.debug("ButtonManager:set_button_state; state_name is nil or empty")
        return 
    end
    if not self.unique_states[state_name] then
        if not options.state_map[state_name] then return end
        mp.msg.warn(string.format("State %s does not exist.", state_name))
        mp.msg.debug(string.format("State %s not in unique states.", state_name))
        return
    end
    self.current_active_state = state_name

    for _, button in pairs(self.buttons) do
        button:update_state(state_name)
    end
end

--MARK: show default
function ButtonManager:show_default()
    self:set_button_state(self.default_state_name)
end



--MARK: reg msg handlers
function ButtonManager:register_message_handlers()
    for state_name in pairs(self.unique_states) do
        self:register_message_handler(state_name)
    end
end
function ButtonManager:register_message_handler(state_name)
    mp.msg.debug("register_message_handlers", 'set ' .. state_name)
    if not state_name then return end

    mp.register_script_message('set', function(state_name)
        if state_name == 'default' then
            mp.msg.debug("set state to default state")
            mp.set_property_number("user-data/ucm_currstate", 1)
            self:show_default()
            return
        end
        -- curent cycle index for updating (possible for cycle button badge)
        for i, state in ipairs(options.state_cycle_map) do
            if state == state_name then    
                mp.set_property_number("user-data/ucm_currstate", i)
                break
            end
        end
        mp.msg.error("set ",state_name)
        self:set_button_state(state_name)  
    end)
end
function ButtonManager:update_button(button_name)
    if not self.buttons[button_name] then return end
    self.buttons[button_name]:update_state(self.current_active_state)
end

function ButtonManager:update_defaults()
    if not options.state_map then return false end

    self.state_map = options.state_map
    self.default_state_name = self.state_map['default']

    if not self.default_state_name then return false end

    mp.msg.debug("ButtonManager:update_defaults; default_state_name: ", self.default_state_name)
    
    for _, button in pairs(self.buttons) do
        button.default_state_name = self.default_state_name
    end
    self:show_default() 
end


-- in case we want another state as default. For example, if we want ta have state_3 as default in fullscreen
-- we can use the set_default script message in other scripts/auto profile
--MARK: default_handlers
--- Registers handlers for managing default button states and state restoration
--- @param self ButtonManager The ButtonManager instance
function ButtonManager:register_default_handlers()
    -- Only proceed if we have a valid default state
    if not self.default_state_name or self.default_state_name == "" then
        mp.msg.debug("No default state configured - skipping handler registration")
        return
    end

    -- Store initial configuration snapshots
    local initial_config = {
        state_map = shallow_copy(self.state_map),
        cycle_map = shallow_copy(options.state_cycle_map),
        default_state = self.default_state_name
    }
    local button_original_defaults={}

    -- Handler to change default state
    mp.register_script_message('set-default', function(new_default_state)
        if not new_default_state or not self.unique_states[new_default_state] then
            mp.msg.debug("Invalid new default state requested:", new_default_state)
            return
        end


        --if button_name == "alt_next" then
        --    print("button_name", button_name)
        --    print("new_default_state", new_default_state)
        --    for state_name, state in pairs(button.states) do
        --        print("state_name", state_name)
        --        print("state", mp.utils.to_string(state))
        --    end
        --    for button_name, button in pairs(self.buttons) do
        --    end
        --end

        -- Replace previous default with new state in cycle map

        local previous_default = self.state_map['default']
        
        -- Update cycle map positions
        local prev_index = table_find(options.state_cycle_map, previous_default)
        local new_index = table_find(options.state_cycle_map, new_default_state)

        if prev_index then
            if new_index then
                -- Swap existing states
                options.state_cycle_map[prev_index], options.state_cycle_map[new_index] = 
                    options.state_cycle_map[new_index], options.state_cycle_map[prev_index]
            else
                -- Replace previous default with new state
                options.state_cycle_map[prev_index] = new_default_state
            end
        end

        -- Update state mappings
        for key, state_name in pairs(self.state_map) do
            if state_name == previous_default then
                mp.msg.error("Updating state mapping for:", key, "to:", new_default_state)
                self.state_map[key] = new_default_state
            end
        end
        
        -- Reset cycle state counter
        mp.set_property_number("user-data/ucm_currstate", 1)

        -- Set new default
        self.state_map['default'] = new_default_state
        self.default_state_name = new_default_state
        
        -- Update display
        self:show_default()

        --msg.debug("initial_config", mp.utils.to_string(initial_config))
        --msg.debug("new_default_state", new_default_state)
        --msg.debug("self.state_map", mp.utils.to_string(self.state_map))
        --msg.debug("self.default_state_name", self.default_state_name)
        --msg.debug("options.state_cycle_map", mp.utils.to_string(options.state_cycle_map))
    end)

    -- Handler to restore original configuration
    mp.register_script_message('revert-default', function()
        for button_name, button in pairs(self.buttons) do
            --msg.debug("button_name", button_name)
            for state_name, state in pairs(button.states) do
                --msg.debug("state_name", state_name)
                --msg.debug("state", mp.utils.to_string(state))
            end
        end
        self.state_map = shallow_copy(initial_config.state_map)
        self.default_state_name = initial_config.default_state
        options.state_cycle_map = shallow_copy(initial_config.cycle_map)
        self:show_default()
    end)
end

-- MARK: handle_subs
function ButtonManager:handle_substitution(button, caller, data)
    local state_name, prop_name, field_type = data.state_name, data.prop, data.type
    if caller ~= prop_name then return end

    local state = button.states[state_name]
    local translated = button.states_translated[state_name]

    if not state or not translated then return end
    
    local orig_field = state[field_type]
    if not orig_field then return end

    local new_values = {}
    
    -- Handle standard properties
    local props = extract_properties(orig_field)
    if props and has_value(props, prop_name) then
        for _, old_prop_name in ipairs(props) do
            local value = self.property_manager.property_map.values[old_prop_name] or ""
            local pattern = ("[[" .. old_prop_name .. "]]"):gsub("([%.%-%+%[%]%(%)%$%^%?%*])", "%%%1")
            table.insert(new_values, {pattern = pattern, new_value = value})
        end
    end
    
    -- Handle special notations
    for raw_pattern, placeholder in pairs(placeholders) do
        if orig_field:match(raw_pattern) then
            local value = placeholder.fun(self.property_manager) or ""
            table.insert(new_values, {pattern = raw_pattern, new_value = value})
        end
    end
    
    translated[field_type] = self.property_manager:insert_values_in_field(orig_field, new_values)
end

--MARK: ###########





--MARK: prop manager

PropertyManager.__index = PropertyManager

--function PropertyManager.new(button_manager)
function PropertyManager.new()
    local self = setmetatable({}, PropertyManager)
    --self.button_manager = button_manager
    self.property_map = {
        standard    = {},    
        special     = {},
        values      = {},  
        field_types = {},   
        buttons     = {},     
    }

    mp.register_script_message('cycle-prop-values', function(prop, ...)
        local values = {...}
        local current = mp.get_property_native(prop)
        local current_idx = table_find(values, current) or 0
        local next_value = values[(current_idx % #values) + 1]
        mp.set_property(prop, next_value)
    end)

    mp.set_property_native("user-data/ucm_currstate", 1)

    return self
end

--MARK: track_btn_props
function PropertyManager:track_states_properties(button_name, states)

    local function insert_data(prop, state_name, field_type, passive)
        if not self.property_map.buttons[button_name] then
            self.property_map.buttons[button_name] = {}
        end
        if not self.property_map.standard[prop] then
            self.property_map.standard[prop] = {}
            -- register an observer for the property
            self:register_property(prop)
        end
        if not passive then
            table.insert(self.property_map.standard[prop], button_name)     
        end
        table.insert(self.property_map.buttons[button_name] , {state_name = state_name, prop = prop, type = field_type})
    end

    for state_name, state in pairs(states) do
        for index, field in ipairs({state.active, state.badge, state.tooltip}) do
            local field_types = {"active", "badge", "tooltip"}
            local field_type = field_types[index]

            if type(field) ~= "string" then field = tostring(field) end
            -- Handle standard properties [[prop]]
            for index, prop in ipairs(extract_properties(field) or {}) do
                insert_data(prop, state_name, field_type)
            end

            -- Same for special notations ?(x)
            for pattern, placeholder in pairs(placeholders) do
                if field:match(pattern) then
                    for _, prop in ipairs(placeholder.props_active) do
                        insert_data(prop, state_name, field_type)
                    end
                    for _, prop in ipairs(placeholder.props_passive) do
                        insert_data(prop, state_name, field_type, 'passive')
                    end
                end
            end
        end
    end
end
--MARK: register_prop
function PropertyManager:register_property(prop_name)
    self.property_map.values[prop_name] = mp.get_property_native(prop_name)
    
    mp.observe_property(prop_name, "native", function(_, value)
        self.property_map.values[prop_name] = value
        mp.commandv('script-message-to', script_name, 'property-changed', prop_name, tostring(value or ""))
    end)
end

function PropertyManager:insert_values_in_field(original, new_values)
    local result = original
    for _, new_value in ipairs(new_values) do
        result = string.gsub(result, new_value.pattern, new_value.new_value)
    end
    return result
end

--MARK: transl_btn_props
function PropertyManager:translate_button_properties(button_name, button_states)
    for _, state in pairs(button_states) do
        if type(state) ~= "table" then break end
        
        -- Translate command placeholders
        if state.command then
            for _, placeholder in ipairs(placeholders_command) do
                state.command = state.command:gsub(placeholder.pattern, placeholder.command)
            end
        end
        
        for _, field in ipairs({'active', 'badge', 'tooltip'}) do
            if state[field] and type(state[field]) == "string" then
                local props = extract_properties(state[field])
                if props then
                    state[field], state.command = self:process_selfupdating_props(state[field], props, state.command)
                end
            end
        end
    end
    return button_states
end

--MARK: cust props
function PropertyManager:process_selfupdating_props(field_as_string, properties, commands)

    local result = field_as_string
    local command_parts = {}
    
    -- Add initial commands if they exist
    if commands and commands ~= "" and commands ~= "nil" then
        table.insert(command_parts, commands)
    end

    for _, prop in ipairs(properties) do
        if prop:match("^user%-data/") and prop:find("%?") then
            local property_name, cycle_values = unpack(split(prop, "?"))
            local initial_value = split(cycle_values, " ")[1]
            
            -- Add separator if we already have commands
            if #command_parts > 0 then
                table.insert(command_parts, ";")
            end
            
            table.insert(command_parts, string.format(
                [[script-message-to %s cycle-prop-values %s %s]],
                script_name,
                property_name,
                cycle_values
            ))
 
            result = result:gsub("%[%[.-%]%]", "[[" .. property_name .. "]]")
            mp.set_property_native(property_name, initial_value)
        end
    end
    
    return result, table.concat(command_parts)
end


--MARK: res_lable
function PropertyManager:getVideoResolutionLabel()
    local width = self.property_map.values["video-params/w"] or ""
    local height = self.property_map.values["video-params/h"] or ""
    local search_res = width .. "x" .. height

    for _, entry in ipairs(options.res_map_table) do
        if entry.resolution == search_res then
            return entry.description
        end
    end
    return height and height .. "p" or nil
end
--MARK: format_lable
function PropertyManager:getMediaFormatLabel()
    local path = self.property_map.values["path"]
    local extension = path and path:match("%.([^%.]+)$")

    if not path and not extension then return "idle" end

    if extension and options.video_types:find(extension) then
        return self.property_map.values["video-format"] or self.property_map.values["video-codec-name"]
    elseif extension and options.audio_types:find(extension) then
        return self.property_map.values["audio-codec-name"]
    elseif extension and options.image_types:find(extension) then
        return self.property_map.values["video-format"]
    else
        if path and path:match("^%a+://") then
            return self.property_map.values["video-format"] or 
                   self.property_map.values["video-codec-name"] or 
                   self.property_map.values["video-codec"] or 
                   self.property_map.values["audio-codec-name"]
        end
    end
    return extension
end



--MARK: parse_but_tbl
-- Build button configuration table from options
local function parse_buttons_table()

    if options.buttons then 
        print_msg("already_configured", "info")
        return 
    end
    options.buttons = {}
    
    local button_index = 1
    while true do
        local button_config = options[string.format("button%d", button_index)]
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
            
            if not options.state_map then 
                options.state_map = { default = state_name } 
            end

            local property_pairs = split(properties, ":")
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
            options.buttons[button_name] = states
            print_msg("success_button", "debug", button_name, get_table_length(states))
        else
            print_msg("no_valid_states", "warn", button_name)
        end
        
        button_index = button_index + 1
    end
    
    if next(options.buttons) then
        print_msg("success_total", "debug", get_table_length(options.buttons))
    else
        print_msg("no_valid_buttons", "warn", script_name)
    end
end
--MARK: parse state maps
local function parse_state_mappings(new_state_map, new_cycle_map)
    local state_map_to_parse = new_state_map or options.state_map
    local cycle_map_to_parse = new_cycle_map or options.state_cycle_map
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
                state_map["key_" .. index] = state_name --after first just give generic names
            end
        end
    else
        state_map = { default = "" }
        cycle_states = nil
    end

    options.state_map = state_map

    mp.msg.debug("State mappings successfully parsed")
    mp.msg.debug("state_map:", mp.utils.to_string(options.state_map))


    if cycle_map_to_parse ~= "" and type(cycle_map_to_parse) == "string" then 
        cycle_map_to_parse = split(cycle_map_to_parse, ",")
    end
    options.state_cycle_map = cycle_states or cycle_map_to_parse or {}
    
    mp.msg.debug("state_cycle_map:"   , mp.utils.to_string(options.state_cycle_map))
end


--MARK: parse_res_map
local function parse_resolution_mappings()
    if options.res_translation == "" then return end

    local new_mappings = split(options.resolution_mapping, ",", ":")
    for resolution, display_name in pairs(new_mappings) do
        local changed = false
        for _, mappings in ipairs(options.res_map_table) do
            if mappings.resolution == resolution then
                mappings.description = display_name
                changed = true
                mp.msg.info("Updated resolution mapping for:", resolution, "to:", display_name)
                break
            end
        end
        if not changed then
            table.insert(options.res_map_table, {
                resolution = resolution,
                description = display_name
                
            })
            mp.msg.debug("Added resolution mapping for:", resolution, "to:", display_name)
        end
    end
end

--MARK: inpute_event
local function setup_input_events()
    if not options.state_map or get_table_length(options.state_map) == 0 then
        mp.msg.warn("No state_map defined, inputevent will not be used")
        options.use_inputevent = false
        return
    end

    for key, state_name in pairs(options.state_map) do
        -- used for debugging
        local is_mouse = key:find("^MBTN_") and true or false

        if state_name == 'default' or key:find("^key_%d+$") then return end

        local on = {
            press      = string.format("script-message-to %s set %s",               script_name, state_name),
            release    = string.format("script-message-to %s revert_inputevent %s", script_name, is_mouse),
            ["repeat"] = string.format("script-message-to %s cancel_revert",        script_name)
        }

        
        local success = mp.commandv('script-message-to', 'inputevent', 'bind', key, mp.utils.format_json(on))

        if not success then
            mp.msg.info("Binding key with inputevent failed, inputevent will not be used")
            return
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
        mp.msg.debug("revert_inputevent")
        -- Create new timer that is either killed as long as keyboard key is pressed or runs out if mousebutton
        revert_timer = mp.add_timeout(0.3 + options.revert_delay/10, function()
            --mp.set_property_number("user-data/ucm_currstate", 1)
            mp.commandv('script-message-to', script_name, 'set', 'default')
        end)
    end)
end


function setup_managers(manager)
    manager = ButtonManager.new()
    manager:init(state_map)
    return manager
end

--MARK: Main
parse_state_mappings()
parse_resolution_mappings()
parse_buttons_table()
setup_input_events() 

local manager = nil
manager = setup_managers(manager)


--MARK: script msg
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
    local success, result = pcall(mp.utils.parse_json, json_string)
    if not success then
        mp.msg.error(error_context or "JSON parse error:", result)
        return nil
    end
    if type(result) ~= "table" then
        mp.msg.error(type(result), "?",error_context or "Invalid data format - expected table")
        mp.msg.debug("result:", result, "json_string:", result)
        return nil
    end
    return result
end

local function safe_json_stringify(data, error_context)
    local success, result = pcall(mp.utils.format_json, data)
    if not success then
        mp.msg.error(error_context or "JSON stringify error:", result)
        return nil
    end
    return result
end

mp.register_script_message('cycle', function()
    if not options.state_cycle_map then return end
    local current_state = mp.get_property_number("user-data/ucm_currstate") or 1
    local num_states = #options.state_cycle_map
    local next_state = ((current_state) % num_states) + 1
    
    mp.set_property_number("user-data/ucm_currstate", next_state)
    manager:set_button_state(options.state_cycle_map[next_state])
    return true
end)

mp.register_script_message('cycle-back', function()
    local current_state = mp.get_property_number("user-data/ucm_currstate") or 1
    local num_states = #options.state_cycle_map
    local next_state = ((current_state - 2) % num_states) + 1
    
    mp.set_property_number("user-data/ucm_currstate", next_state)
    manager:set_button_state(options.state_cycle_map[next_state])
    return true
end)

mp.register_script_message('get-cycle-states', function(receiver)
    local json_string = safe_json_stringify(options.state_cycle_map, "get-cycle-states failed")
    if not json_string then return end
    mp.commandv('script-message-to', receiver, 'receive-cycle-states', json_string)
    return true
end)

mp.register_script_message('set-cycle-states', function(new_states)
    if type(new_states) ~= "string" then
        mp.msg.error("new_states must be a string")
        return
    end
    options.state_cycle_map = split(new_states, ",")
    return true
end)

mp.register_script_message('get-state-map', function(receiver)
    local state_map_string = table.concat(options.state_cycle_map, ", ")
    mp.commandv('script-message-to', receiver, 'receive-state-map', state_map_string)
    return true
end)
mp.register_script_message('set-state-map', function(new_map)
    if type(new_map) ~= "string" then
        mp.msg.error("new state_map must be a string")
        return
    end
    print_msg("new state_map received", 'debug')
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
mp.register_script_message('set-buttons', function(buttons_json)
    local parsed_buttons = safe_json_parse(buttons_json, "set-buttons failed")
    if not parsed_buttons then return end
    print_msg("buttons received", 'debug')

    if not parsed_buttons then return end

    -- Check for default state using parsed data
    if not manager.default_state_name or manager.default_state_name == "" then
        -- Get first button and its first state
        for button_name, button_data in pairs(parsed_buttons) do
            for state_name, _ in pairs(button_data.states or button_data) do
                manager.default_state_name = state_name
                options.state_map = { default = state_name }
                break
            end
            break  -- Only check first button
        end
    end

    local translated = {}
    for button_name, button_data in pairs(parsed_buttons) do
        translated[button_name] = button_data.states
    end
    options.buttons = get_table_length(translated) > 0 and translated or parsed_buttons
    manager = setup_managers(manager)
    return true
end)

mp.register_script_message('get-button', function(button_receiver, button_name)
    if manager.buttons[button_name] then
        local button_json = safe_json_stringify(manager.buttons[button_name].states, "get-button failed")
        if not button_json then return end
        mp.commandv('script-message-to', button_receiver, 'receive-button', button_name, button_json)
    else
        mp.msg.error("Button not found", button_name)
    end
    return true
end)
local retry_count = 0
mp.register_script_message('set-button', function(...)
    local args = {...}
    local button_name = args[1]
    local states_json = table.concat(args, " ", 2)
    local button_states = safe_json_parse(states_json, "set-button failed")

    if not button_states then 
        mp.msg.debug("Failed to parse button states JSON")
        return false
    end

    if manager.buttons[button_name] then
        manager:update_button_data(button_name, button_states)
    else
        manager:register_new_button(button_name, button_states)
    end

    return true
end)

--TODO: fill up states not working anymore. me.v.2.0: ??? it is working, look at the debug messages?
--TODO: change user-data/ucm_currstate when using set-default. inputevent reregister? because state_2 is rightclick and now default...
        -- just use a var that corrects the state name, like state_2? uuhhm you meant state_1... since its only 2 states that can be flipped no bigie
        -- me.v.2.0: ??? no clue.
--TODO: try to fix inbuild mpv cycle props with custom props. noooope mpv bug? shitty documentation? duuno
--TODO: mini controls button menu after uosc pr got acepted? Menubutton is visible and 3 buttons with content are invisible
--       first click shows first state until nth state and a final click makes the content button invisible again.
--       would be usefull for one state contrast one state brightness etc.
