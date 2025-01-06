--MARK: options
local options = {
  -- delay to revet button state, shouldn't be too small or it will revert before the mouseclick is registered
  revert_delay = 0.25, -- set high enough to avoid race conditions

  -- what modifier keys correspond to which state, holding down the right mouse button would change the buttons to the second state (state_2)
  -- state:key
  modifier_keys = "default:state_1,MBTN_RIGHT:state_2,MBTN_MID:state_3",

  use_inputevent = true,

  state_cycle_map="state_1,state_2,state_3",

  --res_table = {
  --  { resolution = "1280x720", description = "HDTV" },
  --  { resolution = "1920x1080", description = "FHD" },
  --  { resolution = "2560x1440", description = "QHD" },
  --  { resolution = "3840x2160", description = "4K" },
  --  { resolution = "7680x4320", description = "8K" },
  --  { resolution = "5120x2880", description = "5K" },
  --  { resolution = "1024x768", description = "XGA" },
  --  { resolution = "1600x1200", description = "UXGA" },
  --  { resolution = "2048x1080", description = "2K (DCI)" },
  --  { resolution = "4096x2160", description = "4K (DCI)" },
  --  { resolution = "640x480", description = "VGA" },
  --  { resolution = "800x600", description = "SVGA" }
  --},

  res_translation = "1280x720:HDTV,1920x1080:FHD,2560x1440:QHD,3840x2160:4K,7680x4320:8K,5120x2880:5K,1024x768:XGA,1600x1200:UXGA,2048x1080:2K (DCI),4096x2160:4K (DCI),640x480:VGA,800x600:SVGA",
  
  -- videoformats that denote music and where the audio format should be shown
  video_types = '3g2,3gp,asf,av1,avi,f4v,flv,h264,h265,m2ts,m4v,mkv,mov,mp4,mp4v,mpeg,mpg,ogm,ogv,rm,rmvb,ts,vob,webm,wmv,y4m',
  audio_types = 'aac,ac3,aiff,ape,au,cue,dsf,dts,flac,m4a,mid,midi,mka,mp3,mp4a,oga,ogg,opus,spx,tak,tta,wav,weba,wma,wv',
  image_types = 'apng,avif,bmp,gif,j2k,jp2,jfif,jpeg,jpg,jxl,mj2,png,svg,tga,tif,tiff,webp,jpeg_pipe',

  buttons = nil,
  

  buttons_test = 
  {
      example = -- name of the button, put this name in uosc.conf button:name
      {
        state_1 = 
        {
          icon     = "exmample", -- https://fonts.google.com/icons?selected=Material+Icons&icon.style=Rounded
          badge    = nil,
          active   = false,
          tooltip  = "Playlist/Files",
          command  = "some command or script-message-to uosc",
-- property that will be observed to change active state of the button
        },
        state_2 = 
        {
          icon     = "example_2",
          badge    = "2",
          active   = true,
          tooltip  = "example_2",
          command  = "script-message-to uosc menu",
        },
        state_3 = 
        {
          icon     = "example_3",
          badge    = "3",
          active   = nil,
          tooltip  = "example_3",
          command  = "",
        }
      },
      alt_control_items =
      {
        state_1 = 
        {
          icon    = "list_alt",
          tooltip = "Playlist/Files",
          command = "script-message-to uosc items",
        },
        state_2 = 
        {
          tooltip = "Files",
          command = "script-message-to uosc open-file",
        },
        state_3 = 
        {
          icon    = "folder_open",
          tooltip = "File Dialog",
          command = "script-message-to uosc show-in-directory",
        },
        fullscreen = 
        {
          icon    = "pause",
          tooltip = "test",
          command = "script-message-to uosc show-in-directory",
        }
      },
      alt_control_loop =
      {
        state_1 = 
        {
          icon     = "repeat",
          active   = "[[loop-playlist]]",
          tooltip  = "Loop playlist",
          command  = "no-osd cycle-values loop-playlist no inf",
          --property = "loop-playlist",
        },
        state_2 = 
        {
          icon     = "repeat_one",
          active   = "[[loop-file]]",
          tooltip  = "Loop file",
          command  = "no-osd cycle-values loop-file no inf",
          --property = "loop-file",
        },
      },
      alt_format =
      {
        state_1 = 
        {
          badge    = "?(f)",
          tooltip  = "[[video-codec]]",
          --badge_property = "video-format,video-codec",
        },
      },

      alt_resolution =
      {
        state_1 = 
        {
          badge    = "?(p)",
          tooltip  = "[[video-params/w]]x[[video-params/h]]",
        },
      },
  },

  buttonexample = 
  {example = {
    state_8 = {
        icon = "example_3",
        tooltip = "example_3",
        badge = "3",
        active = "nil"
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
  button16 = "",
  button17 = "",
  button18 = "",
  button19 = "",
  button20 = "",
  button21 = "",
  button22 = "",
  button23 = "",
  button24 = "",
  button25 = "",
  button26 = "",
  button27 = "",
  button28 = "",
  button29 = "",
  button30 = "",

  fill_up_states = false,
}
mp.utils = require "mp.utils"
mp.options = require "mp.options"
local script_name = mp.get_script_name()
mp.options.read_options(options, script_name)
local res_table = {}
local modifier_state_map = {}
local PropertyManager = {}
local placeholders = {
    ["%?%(f%)"] = {"file-loaded", "video-format", "video-codec-name", "audio-codec-name"},
    ["%?%(p%)"] = {"file-loaded", "video-params/w", "video-params/h"},
    ["%?%(c%)"] = {"user-data/ucm_currstate"}
}


--MARK: extract props
-- Helper function to extract properties enclosed in double square brackets
local function extract_properties(input_string)
    if not input_string then return nil end
    local results = {}
    --for match in input_string:gmatch("%[%[(.-)%]%]") do
    for match in input_string:gmatch("%[%[([^%]]+)%]%]") do
        table.insert(results, match)
    end
    return #results > 0 and results or nil
end

--MARK: split
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
--MARK: shallow_copy
function shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end


--MARK: Button
-- Button Class
local Button = {}
Button.__index = Button

-- Default State Template
local DEFAULT_STATE = {
    icon = "",
    badge = "nil",
    active = "false",
    tooltip = "",
    command = string.format("script-message-to %s lable", script_name), --Do Nothing
}

function Button.new(name, states)
    local self = setmetatable({}, Button)
    self.name = name
    self.states = states
    self.active_state = nil
    self.default_state_name = ""
    return self
end

function Button:initialize_states(default_state_name)
    -- Find and initialize the Default State
    self.default_state_name = default_state_name
    self.active_state = self.states[default_state_name]
    local first_state = self.states[default_state_name]
    if first_state then
        -- Fill Default State with default values
        for key, value in pairs(DEFAULT_STATE) do
            first_state[key] = first_state[key] or value
        end
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
    end
    return self
end


--MARK: translate_res
function Button.getVideoResolutionLabel()
    local width = mp.get_property("video-params/w") or ""
    local height = mp.get_property("video-params/h") or ""
    local search_res = width .. "x" .. height

    for _, entry in ipairs(res_table) do
        if entry.resolution == search_res then
            --mp.msg.debug("Found resolution: " .. entry.resolution .. " with description: " .. entry.description)
            return entry.description
        end
    end
    return height .. "p"
end

--MARK: translate_format
function Button.getMediaFormatLabel(format)

    local path = mp.get_property("path")
    local extension = path and path:match("%.([^%.]+)$")

    if not path and not extension then return end

    local video_types = options.video_types
    local audio_types = options.audio_types
    local image_types = options.image_types
    
    if extension and video_types:find(extension) then
        return mp.get_property("video-format") or mp.get_property("video-codec-name")
    elseif extension and audio_types:find(extension) then
        return mp.get_property("audio-codec-name")
    elseif extension and image_types:find(extension) then
        return mp.get_property("video-format")
    else
        -- assume its a stream?
        --if not extension or path:match("^https?://") then
        if path and path:match("^%a+://") then

            return mp.get_property("video-format") or 
                   mp.get_property("video-codec-name") or 
                   mp.get_property("video-codec") or 
                   mp.get_property("audio-codec-name")
        else
            mp.msg.warn("Unknown file type for: " ,path, "or", extension)
        end
    end
    return extension
end
--MARK: replace_props
function Button:replace_properties(input, active)
    --mp.msg.debug("input: ", input)
    if type(input) ~= "string" then return nil end
    if input == "" then return nil end

    local function replace_special_notation(input, pattern, replacement)
        if input and input:match(pattern) then
            local replacement_value = type(replacement) == "function" and replacement() or replacement
            input = input:gsub(pattern, replacement_value)
        end
        return input
    end

    input = replace_special_notation(input, "%?%(p%)", Button.getVideoResolutionLabel)
    input = replace_special_notation(input, "%?%(f%)", Button.getMediaFormatLabel)
    --input = replace_special_notation(input, "%?%(c%)", self.manager.current_active_state_number)
    input = replace_special_notation(input, "%?%(c%)", function() 
        return mp.get_property_number("user-data/ucm_currstate") or 1 end)


    local result = input
    local props = extract_properties(input) 
    if not props then return input end
    
    --mp.msg.error("props: ", mp.utils.format_json(props))
    
    for _, prop in ipairs(props) do

        local value = mp.get_property_native(prop)
        --mp.msg.error("prop: ", prop, " value: ", value, "result: ", result, "typweof: ", type(value))

        if value == nil then return "prop not found " .. prop end
        
        if active and (value == "" or 
                       value == "no" or 
                       value == "false" or
                       value == false or
                       value == "0" or 
                       value == 0) then
            return false
        end


        local pattern = "%[%[" .. prop:gsub("[%.%[%]%(%)%%%+%-%*%?%^%$]", "%%%1") .. "%]%]"
        result = result:gsub(pattern, value)

    end

    return result or nil
end
--MARK: replace cmds
function Button:replace_commands(input)
    local special_notation = {
        {
            shortcut = "%?%(c%-%)",
            action = "script-message-to " .. script_name .. " cycle-back"
        },
        {
            shortcut = "%?%(c%)",
            action = "script-message-to " .. script_name .. " cycle"
        }
        -- New patterns can be added here following the same structure:
        -- { pattern = "pattern_to_match", replacement = "command_to_execute" }
    }

    local result = tostring(input)
    
    for _, mapping in ipairs(special_notation) do
        if result:match(mapping.shortcut) then
            result = result:gsub(mapping.shortcut, mapping.action)
        end
    end

    return result
end

function Button:update_default_state()
    self:update_state(self.default_state_name)
end
--MARK: update_state
function Button:update_state(state_name)

    --for states in pairs(self.states) do
    --    mp.msg.error("name", self.name, "state: ", states, "state_name: ", state_name)
    --end

    local state = self.states[state_name] or self.active_state
    --mp.msg.error("name", self.name, "state: ", state, "state_name: ", state_name)
    if state then
        self.active_state = state
        --if state then state.active = (state.active == "true") end
        --if state.active == "true" then state.active = true end
        if state.active == "false" then state.active = false end
        if state.badge == "nil" then state.badge = nil end

        local tooltip = self:replace_properties(state.tooltip)
        local badge   = self:replace_properties(state.badge)
        local active  = self:replace_properties(state.active, true)
        local command = self:replace_commands(state.command)

        mp.commandv('script-message-to', 'uosc', 'set-button', self.name, mp.utils.format_json({
            icon    = state.icon,
            badge   = badge,
            active  = active,
            tooltip = tooltip,
            command = command,
        }))
    else
        if options.fill_up_states then
            mp.msg.warn("Unknown state:",state, "name:", state_name, "button:", self.name)
        end
    end
end
--MARK: ButtonManager
-- ButtonManager Class
local ButtonManager = {}
ButtonManager.__index = ButtonManager

function ButtonManager.new()
    local self = setmetatable({}, ButtonManager)
    self.buttons              = {}
    self.property_manager = PropertyManager.new(self)
    self.modifier_state_map           = {}
    self.unique_states        = {}
    self.current_active_state = ""
    --self.current_active_state_number = 1
    self.default_state_name = ""
    --self.property_observers = {}
    return self
end

function ButtonManager:init()
    self.modifier_state_map = options.modifier_state_map
    self.default_state_name = self.modifier_state_map['default']
    --self.current_active_state = 'default'
    self.current_active_state = self.default_state_name
    
    self:initialize_buttons()
    self:manage_unique_states()
    --mp.set_property("user-data/ucm_currstate", 1)

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
            end
            self.unique_states[state] = true
        end
    end

    if next(new_states) and not options.fill_up_states then
        mp.msg.debug("Updating existing buttons with new states")
        for _, button in ipairs(self.buttons) do
            for _, state in ipairs(self.unique_states_map) do
                if not button.states[state] then
                    mp.msg.debug("Adding state " .. state .. " to button " .. button.name)
                    button.states[state] = button.states[self.modifier_state_map['default']]
                end
            end
        end
    end
end

--MARK: init buttons
function ButtonManager:initialize_buttons()
    for button_name, button_states in pairs(options.buttons) do
        self:initialize_button(button_name, button_states)
    end
end
function ButtonManager:initialize_button(button_name, button_states)
    local processed_states = self.property_manager:translate_button_properties(button_name, button_states)
    local button = Button.new(button_name, processed_states)
    --local button = Button.new(button_name, button_states)
    if self.modifier_state_map and self.modifier_state_map['default'] then
        button:initialize_states(self.modifier_state_map['default'])
        
        -- script message to set state for one button
        mp.register_script_message('set-button-state', function(button_name,state_name)
            self.buttons[button_name]:update_state(state_name)
        end)

        self.buttons[button_name] = button
    else
        mp.msg.error("No default state defined")
    end
end

--MARK: set_button_state
function ButtonManager:set_button_state(state_name)
    mp.msg.trace("setting button state to " .. state_name)
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
        mp.msg.debug("register_message_handlers", 'set ' .. state_name)
        if state_name then
            mp.register_script_message('set', function(state_name)
                if state_name == 'default' then
                    self:show_default()
                    mp.set_property_number("user-data/ucm_currstate", 1)
                    return
                end
                -- curent cycle index for updating (possible for cycle button badge)
                for i, state in ipairs(options.state_cycle_map) do
                    if state == state_name then
                        mp.set_property_number("user-data/ucm_currstate", i)
                        break
                    end
                end

                self:set_button_state(state_name)
            end)
        end
    end
end

--MARK: prop_observers
function ButtonManager:update_button(button_name)
    if not self.buttons[button_name] then return end
    self.buttons[button_name]:update_state(self.current_active_state)
end

function ButtonManager:register_property_observers()
    for button_name, button in pairs(self.buttons) do
        self.property_manager:watch_button_properties(button_name, button)
    end
end



-- in case we want another state as default. For example, if we want ta have state_3 as default in fullscreen
-- we can use the set_default script message in other scripts/auto profile
--MARK: default_handlers
--- Registers handlers for managing default button states and state restoration
--- @param self ButtonManager The ButtonManager instance
function ButtonManager:register_default_handlers()
    -- Store initial modifier state configuration for restoration
    local initial_state_map = shallow_copy(self.modifier_state_map)
    local initial_default = self.default_state_name

    -- Handler to change the default state
    mp.register_script_message('set-default', function(new_default_state)
        local previous_default = self.modifier_state_map['default']
        
        -- Swap states to maintain mappings
        for key, state_name in pairs(self.modifier_state_map) do
            if state_name == new_default_state then
                self.modifier_state_map[key] = previous_default
            end
        end
        
        -- Set new default and update display
        self.modifier_state_map['default'] = new_default_state
        self.default_state_name = new_default_state
        self:show_default()
    end)

    -- Handler to restore original default state configuration
    mp.register_script_message('revert-default', function()
        self.modifier_state_map = shallow_copy(initial_state_map)
        self.default_state_name = initial_default
        self:show_default()
    end)
end

--MARK: prop manager
PropertyManager.__index = PropertyManager

function PropertyManager.new(button_manager)
    local self = setmetatable({}, PropertyManager)
    self.observers = {}
    self.cache = {}
    self.watch_list = {}
    self.button_manager = button_manager

    mp.register_script_message('cycle-prop-values', function(prop, ...)
        local values = {...}
        local current = mp.get_property_native(prop)
        local current_idx = table_find(values, current) or 0
        local next_value = values[(current_idx % #values) + 1]
        mp.set_property(prop, next_value)
    end)

    return self
end

function PropertyManager:register_property(property_name, callback)
    if not self.observers[property_name] then
        self.observers[property_name] = {}
        mp.observe_property(property_name, "string", function(_, value)
            self.cache[property_name] = value
            self:notify_observers(property_name, value)
        end)
    end
    table.insert(self.observers[property_name], callback)
end

function PropertyManager:notify_observers(property_name, value)
    if self.observers[property_name] then
        for _, callback in ipairs(self.observers[property_name]) do
            callback(value)
        end
    end
end

function PropertyManager:get_property(property_name)
    if self.cache[property_name] == nil then
        self.cache[property_name] = mp.get_property(property_name)
    end
    return self.cache[property_name]
end

function PropertyManager:process_state_fields(button_name, button_states, callback)
    for _, state in pairs(button_states) do
        for _, field in ipairs({'active', 'badge', 'tooltip'}) do
            if state[field] then
                callback(state, field, button_name)
            end
        end
    end
end

function PropertyManager:handle_properties(field, button_name)
    -- Handle standard properties
    local props = self:extract_properties(field)
    for _, prop in ipairs(props) do
        self:register_property(prop, function()
            self.button_manager:update_button(button_name)
        end)
    end
    -- Handle placeholder properties
    for pattern, props in pairs(placeholders) do
        if field:find(pattern) then
            for _, prop in ipairs(props) do
                self:register_property(prop, function()
                    self.button_manager:update_button(button_name)
                end)
            end
        end
    end
end

function PropertyManager:watch_button_properties(button_name, button)
    --for _, state in pairs(button.states) do
    --    for _, field in ipairs({state.active, state.badge, state.tooltip}) do
    --        if field then
    --            self:handle_properties(field, button_name)
    --        end
    --    end
    --end
    self:process_state_fields(button_name, button.states, function(field, button_name)
        self:handle_properties(field, button_name)
    end)
end

function PropertyManager:extract_properties(input_string)
    if not input_string then return {} end
    local properties = {}
    for prop in input_string:gmatch("%[%[([^%]]+)%]%]") do
        table.insert(properties, prop)
    end
    return properties
end

function PropertyManager:translate_button_properties(button_name, button_states)
    self:process_state_fields(button_name, button_states, function(state, field)
        local props = self:extract_properties(state[field])
        if props then
            local processed_string, command = self:process_cycle_properties(
                state[field],
                props,
                state.command
            )
            state.command = command
            state[field] = processed_string
        end
    end)
    
    --for state_name, state in pairs(button_states) do
    --    -- Process dynamic properties
    --    local dynamic_fields = {"active", "tooltip", "badge"}
    --    for _, field in ipairs(dynamic_fields) do
    --        if state[field] then
    --            local props = self:extract_properties(state[field])
    --            if props then
    --                local processed_string, command = self:process_cycle_properties(
    --                    state[field],
    --                    props,
    --                    state.command
    --                )
    --                state.command = command
    --                state[field] = processed_string
    --            end
    --        end
    --    end
    --end
    --
    options.buttons[button_name] = button_states
    return button_states
end

--MARK: cust props
function PropertyManager:process_cycle_properties(input_string, properties, command_string)
    if not input_string then return input_string, command_string end
    
    local result = input_string
    local commands = command_string or ""
    
    for _, prop in ipairs(properties) do
        if prop:match("^user%-data/") and prop:find("%?") then
            local property_name, cycle_values = unpack(split(prop, "?"))
            local initial_value = split(cycle_values, " ")[1]
            
            commands = commands ~= "" and (commands .. ";") or ""
            commands = commands .. string.format(
                [[script-message-to %s cycle-prop-values %s %s]], 
                script_name, 
                property_name, 
                cycle_values
            )
            
            result = result:gsub("%[%[.-%]%]", "[[" .. property_name .. "]]")
            mp.set_property_native(property_name, initial_value)
        end
    end
    
    return result, commands
end

function PropertyManager:clear_cache()
    self.cache = {}
end


--MARK: parse_but_tbl
-- Build button configuration table from options
local function parse_buttons_table()
    if options.buttons then return end
    options.buttons = {}
    
    local button_index = 1
    while true do
        local button_config = options[string.format("button%d", button_index)]
        if not button_config or button_config == "" then break end
        
        -- Extract button name and remaining configuration
        local button_name, remaining_config = button_config:match("^%s*([^,]+)%s*,%s*(.+)$")
        if not button_name then break end
        
        button_name = button_name:gsub('"', '')
        local states = {}
        
        -- Parse each state definition while maintaining order
        local state_definitions = split(remaining_config, ",")
        for _, state_def in ipairs(state_definitions) do
            local state_name, properties = unpack(split(state_def, "@"))
            
            -- Initialize modifier_state_map with first state as default
            if not options.modifier_state_map then 
                options.modifier_state_map = { default = state_name } 
            end

            local property_pairs = split(properties, ":")
            if state_name and property_pairs then
                local state = {}
                
                
                -- Parse properties while maintaining order
                for _, prop in ipairs(property_pairs) do
                    local key, value = unpack(split(prop, "="))
                    if key and value then
                        state[key] = value
                    end
                end
                
                --state = process_state_properties(state)
                states[state_name] = state
            end
        end
        options.buttons[button_name] = states
        button_index = button_index + 1
    end
end

--MARK: parse_modkey
local function parse_modifier_keys()

    if options.modifier_keys == "" then return end
    
    if not options.modifier_keys or type(options.modifier_keys) ~= "string" then
        mp.msg.warn("Invalid modifier_keys configuration")
        return modifier_state_map
    end

    local modifier_state_map = split(options.modifier_keys, ",", ":")

    if not modifier_state_map or not modifier_state_map["default"] then
        mp.msg.error("No default state defined in modifier_keys:", mp.utils.to_string(options.modifier_keys))
    end
    options.modifier_state_map = modifier_state_map
    --return modifier_state_map
end

local function parse_cycle_map(new_states)
    local states_to_parse = new_states or options.state_cycle_map
    if not states_to_parse then return end
    if type(states_to_parse) ~= "string" then return end
    options.state_cycle_map = split(options.state_cycle_map, ",")
end

local function parse_resolution_mappings()
    if not options.res_translation or options.res_translation == "" then
        mp.msg.error("No or faulty resolution mappings defined in options")
        return
    end

    local mappings = split(options.res_translation, ",", ":")
    for resolution, display_name in pairs(mappings) do
        table.insert(res_table, {
            resolution = resolution,
            description = display_name
        })
    end
end

--MARK: inpute_event
local function setup_input_events()

    for key, state_name in pairs(options.modifier_state_map) do
        if state_name ~= 'default' then
            local on = {
                --press = "script-message-to " .. script_name .. " revert_inputevent", ??? why and why did this work?????
                press   = string.format("script-message-to %s set %s", script_name, state_name),
                release = string.format("script-message-to %s revert_inputevent", script_name)
            }
            mp.commandv('script-message-to', 'inputevent', 'bind', key, mp.utils.format_json(on))
        end
    end
    -- Register revert_inputevent message handler
    mp.register_script_message('revert_inputevent', function()
        --mp.set_property_number("user-data/ucm_currstate", 0)
        mp.add_timeout((options.revert_delay/10) + 0.20, function()
            mp.set_property_number("user-data/ucm_currstate", 1)
            mp.commandv('script-message-to', script_name, 'set', 'default')
        end)
    end)
end


function setup_manager(manager)
    manager = ButtonManager.new()
    manager:init(modifier_state_map)
    manager:register_message_handlers()
    manager:register_property_observers()
    manager:register_default_handlers()
    return manager
end

--MARK: Main
parse_modifier_keys()
parse_cycle_map()
parse_resolution_mappings()
parse_buttons_table()
if options.use_inputevent then
    setup_input_events() 
end
local manager = nil
manager = setup_manager(manager)



--MARK: script msg
mp.register_script_message('cycle', function()
    local current_state = mp.get_property_number("user-data/ucm_currstate") or 1
    local num_states = #options.state_cycle_map
    local next_state = ((current_state) % num_states) + 1
    
    mp.set_property_number("user-data/ucm_currstate", next_state)
    manager:set_button_state(options.state_cycle_map[next_state])
end)
mp.register_script_message('cycle-back', function()
    local current_state = mp.get_property_number("user-data/ucm_currstate") or 1
    local num_states = #options.state_cycle_map
    local next_state = ((current_state - 2) % num_states) + 1
    
    mp.set_property_number("user-data/ucm_currstate", next_state)
    manager:set_button_state(options.state_cycle_map[next_state])
end)
mp.register_script_message('extend-cycle-states', function(new_states_to_cycle)
    if not type(new_states_to_cycle) == "string" then mp.msg.error("new_states_to_cycle must be a string") return end
    local new_states = split(new_states_to_cycle, ",")
    for _, new_state in ipairs(new_states) do
        table.insert(options.state_cycle_map, new_state)
    end
end)
mp.register_script_message('get-cycle-states', function(receiver)
    local cycle_states_json = mp.utils.format_json(options.state_cycle_map)
    mp.commandv('script-message-to', receiver, 'receive-cycle-states', cycle_states_json)
end)
mp.register_script_message('set-cycle-states', function(new_states)
    if type(new_states) ~= "string" then
        mp.msg.error("new_states must be a string")
        return
    end
    parse_cycle_map(new_states)
end)

mp.register_script_message('get-buttons', function(button_receiver)
    local buttons_json = mp.utils.format_json(manager.buttons)
    mp.commandv('script-message-to', button_receiver, 'receive-buttons', buttons_json)
    return true
end)
mp.register_script_message('set-buttons', function(buttons_json)
    local parsed_buttons = mp.utils.parse_json(buttons_json)
    
    local translated = {}
    for button_name, button_data in pairs(parsed_buttons) do
        translated[button_name] = button_data.states
    end
    options.buttons = translated
    manager = setup_manager(modifier_state_map)
end)
mp.register_script_message('set-button', function(...)
    local args = {...}
    local button_name = args[1]
    local states_json = table.concat(args, " ", 2)
    
    local button_states = mp.utils.parse_json(states_json)
    manager:manage_unique_states(button_states)

    
    for _,state in pairs(button_states) do
        state = process_state_properties(state)
    end
    manager:initialize_button(button_name, button_states)
    manager:set_button_state(manager.current_active_state)
end)

mp.register_script_message('get-button', function(button_receiver, button_name)
    if manager.buttons[button_name] then
        local button_json = mp.utils.format_json(manager.buttons[button_name].states)
        mp.commandv('script-message-to', button_receiver, 'receive-button', button_name, button_json)
    else
        mp.msg.error("Button not found", button_name)
    end
end)

--TODO: ButtonManager:initialize_button remove dependencie of propstatemap
--TODO: current state as property?
--TODO: dont check everytime for properties but create a new table for them and let handler and observer handle them?
--TODO: check if props are initially set. what does this mean?
--TODO: mini controls button menu after uosc pr got acepted? Menubutton is visible and 3 buttons with content are invisible
--TODO: first click shows first state until nth state and a final click makes the content button invisible again.
--TODO: would be usefull for one state contrast one state brightness etc.