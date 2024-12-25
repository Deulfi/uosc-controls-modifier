--[[
   MPV Dynamic Button State Manager for uosc Interface

   This script enhances the MPV player uosc interface by enabling dynamic button state management. 
   It allows buttons to have multiple states triggered by modifier keys (like mouse buttons) or commands, 
   providing a more interactive and context-sensitive control interface.

   Key Features:
   - Multiple states per button (default, right-click, middle-click, etc.) with inheritance of default values.
   - Automatic state updates through property observation.
   - Modifier key support via inputevent.lua for dynamic state switching with customizable revert delay.
   - JSON-based button configuration for easy setup.

   Button States:
   - Each button can have multiple states (state_1, state_2, state_3, etc.) defining:
       * icon: Material Design icon name
       * badge: Optional badge text
       * active: Boolean for active state
       * tooltip: Hover text
       * command: MPV command to execute
       * property: MPV property to observe for active state

   How it Works:
   1. Define buttons and their states in the options table.
   2. The script creates Button objects, managing multiple states and their properties.
   3. A ButtonManager orchestrates behavior, including:
      - Parsing modifier keys (inputevent.lua)
      - Registering message handlers for state changes
      - Setting up property observers
      - Managing input events
      - Handling default state and state transitions

   Usage:
   1. Configure buttons in the options table.
   2. Add button references to uosc.conf.
   3. Use modifier keys (like right mouse button) to access different states for dynamic, context-sensitive controls. (inputevent.lua)

   Requirements:
   - MPV player
   - uosc user interface
   - (Optional) inputevent.lua script for enhanced modifier key support

   Example Use Cases:
   - Change playlist controls when a modifier key is held.
   - Toggle between file and playlist looping.
   - Show different button options in fullscreen vs. windowed mode.

   Script Messages:
   - set-state_X: Switch to state X
   - set-default: Change default state (inputevent.lua)
   - revert-default: Revert to original default state (inputevent.lua)

   For more information and updates, visit the GitHub repository.

   Author: [Deulfi]
   License: [MIT]
   Repository: [Repository URL]
]]

--MARK: options
local options = {
  -- delay to revet button state, shouldn't be too small or it will revert before the mouseclick is registered
  revert_delay = 0.25, -- set high enough to avoid race conditions

  -- what modifier keys correspond to which state, holding down the right mouse button would change the buttons to the second state (state_2)
  -- state:key
  modifier_keys = "state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID",

  use_inputevent = true,
  --modifier_keys = "",
  --use_inputevent = false,
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

  --buttons = nil,
  

  buttons = 
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
          --badge_property = "video-params/h,+p,video-params/w,+x,video-params/h",
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
}
mp.utils = require "mp.utils"
mp.options = require "mp.options"
local script_name = mp.get_script_name()
mp.options.read_options(options, script_name)
local res_table = {}

--MARK: Button
-- Button Class
local Button = {}
Button.__index = Button

-- Default State Template
local DEFAULT_STATE = {
    icon = "",
    badge = nil,
    active = false,
    tooltip = "",
    command = string.format("script-message-to %s lable", script_name),
    property = ""
}

function Button.new(name, states)
    local self = setmetatable({}, Button)
    self.name = name
    self.states = states
    return self
end

function Button:initialize_states(default_state_name)
    -- Find and initialize the Default State
    local first_state = self.states[default_state_name]
    if first_state then
        -- Fill Default State with default values
        for key, value in pairs(DEFAULT_STATE) do
            first_state[key] = first_state[key] or value
        end
    end

    -- Fill other states with values from the first_state
    for state_name, state in pairs(self.states) do
        for key, fill_value in pairs(first_state or DEFAULT_STATE) do
            if state[key] == nil or state[key] == "" then
                state[key] = fill_value
            end
        end
    end

    return self
end
--MARK: translate_res
function Button.translate_res()
    local width = mp.get_property("video-params/w") or ""
    local height = mp.get_property("video-params/h") or ""
    local search_res = width .. "x" .. height

    for _, entry in ipairs(res_table) do
        if entry.resolution == search_res then
            mp.msg.debug("Found resolution: " .. entry.resolution .. " with description: " .. entry.description)
            return entry.description
        end
    end
    return height .. "p"
end
--MARK: translate_format
function Button.translate_format(format)

    local path = mp.get_property("path")
    local extension = path and path:match("%.([^%.]+)$")

    if not path and not extension then return end

    local video_types = options.video_types
    local audio_types = options.audio_types
    local image_types = options.image_types

    --mp.msg.debug(mp.get_property("video-codec"),mp.get_property("video-codec-name"), mp.get_property("audio-codec-name"), mp.get_property("video-format"))
    
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
            mp.msg.warn("Unknown file type for: " ,path, " or ", extension)
        end
    end
    return extension
end

--MARK: update_state
function Button:update_state(state_name)
    function replace_properties(input)
        if type(input) ~= "string" then return nil end
        if input == "" then return nil end
        
        local result = input
        local has_properties = false
        
        for prop in input:gmatch("%[%[([^%]]+)%]%]") do
            has_properties = true 

            local value = mp.get_property(prop)
            if not value then
                result = 'prop not found'
            
            
            elseif value and not (value == nil or value == "" or value == "no" or value == 0) then
                local pattern = "%[%[" .. prop:gsub("[%.%[%]%(%)%%%+%-%*%?%^%$]", "%%%1") .. "%]%]"
                result = result:gsub(pattern, value)
            else 
                result = nil
            end
        end

    -- Handle resolution translation after property replacement
    if result and result:match("%?%(p%)") then
        local res = Button.translate_res() or ""
        result = result:gsub("%?%(p%)", res)
        has_properties = true
    end
    -- Handle format translation after property replacement
    if input and input:match("%?%(f%)") then
        local format = Button.translate_format() or ""
        result = result:gsub("%?%(f%)", format)
        has_properties = true
    end


        return has_properties and result or nil, has_properties
    end
    
    local state = self.states[state_name]
    if state then
        local tooltip, tooltip_is_property = replace_properties(state.tooltip)
        local badge,   badge_is_property   = replace_properties(state.badge)
        local active,  active_is_property  = replace_properties(state.active)
        
        mp.commandv('script-message-to', 'uosc', 'set-button', self.name, mp.utils.format_json({
            icon    = state.icon,
            badge   = badge or state.badge,
            active  = not active_is_property and state.active or active,
            tooltip = not tooltip_is_property and state.tooltip or tooltip,
            command = state.command,
        }))
    else
        mp.msg.error("Unknown state:",state)
    end
end
--MARK: ButtonManager
-- ButtonManager Class
local ButtonManager = {}
ButtonManager.__index = ButtonManager

function ButtonManager.new()
    local self = setmetatable({}, ButtonManager)
    self.buttons = {}
    self.key_states = {}
    self.unique_states = {}
    self.current_active_state = ""
    return self
end

function ButtonManager:init(key_states)
    self.key_states = key_states
    self.default_state_names = {[self.key_states['default']] = true}
    self.current_active_state = 'default'
    self:lookup_unique_states()
    self:initialize_buttons()

    local function temp()
        self:show_default(nil)
        mp.unobserve_property(temp)
    end
    mp.observe_property("idle", "string", temp)
end

function ButtonManager:lookup_unique_states()
    for _, button in pairs(options.buttons) do
        for state in pairs(button) do
            self.unique_states[state] = true
        end
    end
end

function ButtonManager:initialize_buttons()
    for button_name, button_states in pairs(options.buttons) do
        local button = Button.new(button_name, button_states)
        button:initialize_states(self.key_states['default'])
        
        -- Fill missing states
        for state in pairs(self.unique_states) do
            if not button.states[state] then
                button.states[state] = button.states[self.key_states['default']]
            end
        end
        self.buttons[button_name] = button
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

function ButtonManager:show_default(delay)
    local state_name = self.key_states['default']
    
    if delay then
        -- update it before changing it to default because we assume we clicked a button and want
        -- to show a changed active state of the button
        mp.add_timeout(options.revert_delay, function()
            self:set_button_state(self.current_active_state)
            mp.add_timeout(0.1, function()
                self:set_button_state(state_name)
            end)
        end)
    else
       self:set_button_state(state_name)
    end
end

function ButtonManager:register_message_handlers()
    for state_name in pairs(self.unique_states) do
        print("state_name", state_name)
        if state_name then
            mp.register_script_message('set-' .. state_name, function()
                self:set_button_state(state_name, options.use_inputevent)
            end)
        end
    end
end

function ButtonManager:update_button(button_name)
    self.buttons[button_name]:update_state(self.current_active_state)
end
--MARK: prop_observers
function ButtonManager:register_property_observers()
    local property_to_buttons = {}
    
    local function register_property_observer(prop, button_name)
        if type(prop) ~= "string" or prop == "" then return end
        
        if not property_to_buttons[prop] then
            property_to_buttons[prop] = {}
            mp.observe_property(prop, "string", function()
                -- Only update buttons that depend on this property
                for btn_name in pairs(property_to_buttons[prop]) do
                    self:update_button(btn_name)
                end
            end)
        end
        property_to_buttons[prop][button_name] = true
    end

    local function extract_properties(str, button_name)
        if not str then return end
        str = tostring(str)

        if str:find("%?%(f%)") then
            if not property_to_buttons["file-loaded"] then
                property_to_buttons["file-loaded"] = {}
                mp.register_event("file-loaded", function()
                    for btn_name in pairs(property_to_buttons["file-loaded"]) do
                        self:update_button(btn_name)
                    end
                end)
            end
            property_to_buttons["file-loaded"][button_name] = true
        end

        for prop in str:gmatch("%[%[(.-)%]%]") do
            register_property_observer(prop, button_name)
        end
    end

    for button_name, button in pairs(self.buttons) do
        for _, state in pairs(button.states) do
            if state.active then
                extract_properties(state.active, button_name)
            end
            if state.badge then
                extract_properties(state.badge, button_name)
            end
            if state.tooltip then
                extract_properties(state.tooltip, button_name)
            end
        end
    end
end


-- in case we want another state as default. For example, if we want ta have state_3 as default in fullscreen
-- we can use the set_default script message in other scripts/auto profile
function ButtonManager:register_default_handlers()
    print("register_default_handlers", mp.utils.format_json(self.key_states))
    local saved_key_states = shallow_copy(self.key_states)

    mp.register_script_message('set-default', function(new_default_state)
        local old_state = self.key_states['default']
        for key, state_name in pairs(self.key_states) do
            if state_name == new_default_state then
                self.key_states[key] = old_state
            end
        end
        self.key_states['default'] = new_default_state
        self:show_default()
    end)

    mp.register_script_message('revert-default', function()
        self.key_states = shallow_copy(saved_key_states)
        self:show_default()
    end)
end

--MARK: build buttons
function build_buttons_table()
    local i = 1
    if options.buttons then return end
    options.buttons = {}  -- Initialize options.buttons if not already set

    while true do
        local button = options[string.format("button%d", i)]
        if not button or #button == 0 then break end
        
        local button_name = button:match("^%s*([^,]+)%s*"):gsub('"', '')
        local rest = button:match(",%s*(.+)$")
        
        if button_name and rest then
            local states = {}
            
            for state_def in rest:gmatch("[^,]+") do
                local state_name, properties = state_def:match("^%s*([^@]+)@(.+)")
                if state_name then
                    local state = {}
                    
                    for prop in properties:gmatch("[^:]+") do
                        local key, value = prop:match("^%s*(%w+)=(.+)%s*$")
                        if key and value then
                            state[key] = value:gsub('"', '')
                        end
                    end
                    
                    states[state_name] = state
                end
            end
            
            options.buttons[button_name] = states
        end
        i = i + 1
    end
end




--MARK: shallow_copy
function shallow_copy(t)
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
end

--MARK: parse_mk
local function parse_modifier_keys()
    local key_states = {}

    if options.modifier_keys == "" then return end
    
    if not options.modifier_keys or type(options.modifier_keys) ~= "string" then
        mp.msg.warn("Invalid modifier_keys configuration")
        return key_states
    end

    for state_key in options.modifier_keys:gmatch("([^,]+)") do
        local state_name, key = state_key:match("^%s*([^:]+)%s*:%s*([^%s,]+)%s*$")
        if state_name and key then
            key_states[key] = state_name
        else
            mp.msg.warn(string.format("Invalid modifier key format: %s", state_key))
        end
    end

    if not key_states["default"] then
        mp.msg.warn("No default state defined, adding 'state_1:default'")
        key_states["default"] = "state_1"
    end

    return key_states
end

--MARK: inpute_event
local function setup_input_events(key_states, manager)

    for key, state_name in pairs(key_states) do
        if state_name ~= 'default' then
            local on = {
                press = "script-message-to " .. mp.get_script_name() .. " set-" .. state_name,
                release = "script-message-to " .. mp.get_script_name() .. " revert_inputevent"
            }
            mp.commandv('script-message-to', 'inputevent', 'bind', key, mp.utils.format_json(on))
        end
    end
    -- Register revert_inputevent message handler
    mp.register_script_message('revert_inputevent', function()
        manager:show_default("delay")
    end)
end

local function translate_res_translation()
    for res_desc in options.res_translation:gmatch("([^,]+)") do
        local resolution, description = res_desc:match("([^:]+):([^:]+)")
        if resolution and description then
            table.insert(res_table, { resolution = resolution, description = description })
        else
            mp.msg.warn("Invalid resolution translation format: " .. res_desc)
        end
    end
    return res_table
end

--MARK: Main
res_table = translate_res_translation()
--build_buttons_table()

local key_states = parse_modifier_keys()

local manager = ButtonManager.new()
manager:init(key_states)
manager:register_message_handlers()
manager:register_property_observers()
if options.use_inputevent then
    setup_input_events(key_states, manager) 
end
manager:register_default_handlers()





