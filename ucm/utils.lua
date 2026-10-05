-- ucm/utils.lua
-- Shared constants, messages, and utility functions

local PATTERN = {
    any_prop = '%[%[([^%]]+)%]%]',
    compare = '^%[%[(.-)%?%?(.-)%]%]$',
    swap_default = '^%[%[(.-)%?%!(.-)%]%]$',
    value_cycle = '^%[%[(.-)%!%!(.-)%]%]$',
    any_complex_op = '^(.-)%?[%?!]',
    state_cycle = '%?%(c%)',
    state_cycle_back = '%?%(c%-%)',
    media_format = '%?%(f%)',
    media_resolution = '%?%(p%)',
}

local COMPLEX_OP = {
    compare = '??',
    swap_default = '?!',
    value_cycle = '!!',
}

local COMPLEX_PATTERN_BY_OP = {
    [COMPLEX_OP.compare] = PATTERN.compare,
    [COMPLEX_OP.swap_default] = PATTERN.swap_default,
    [COMPLEX_OP.value_cycle] = PATTERN.value_cycle,
}

local PARSER_PATTERN_BY_OP = {
    [COMPLEX_OP.compare] = PATTERN.compare,
    [COMPLEX_OP.swap_default] = PATTERN.swap_default,
    [COMPLEX_OP.value_cycle] = PATTERN.value_cycle,
}

local placeholders = {
    [PATTERN.media_format] = {
        type = 'format',
        props_active = {},
        props_passive = {'path', 'video-format', 'video-codec-name', 'video-codec', 'audio-codec-name'},
        fun = function(self) return self:getMediaFormatLabel() end,
    },
    [PATTERN.media_resolution] = {
        type = 'resolution',
        props_active = {},
        props_passive = {'video-params/h', 'video-params/w'},
        fun = function(self) return self:getVideoResolutionLabel() end,
    },
    [PATTERN.state_cycle] = {
        type = 'state',
        props_active = {'user-data/ucm_currstate'},
        props_passive = {},
        fun = function(self) return self.property_map.values['user-data/ucm_currstate'] end,
    },
}

local placeholders_complex = {
    [PATTERN.compare] = {
        fun = function(self, property_name, compare_value)
            local current_value = mp.get_property(property_name)
            return current_value == compare_value and 'true' or 'false'
        end,
    },
    [PATTERN.swap_default] = {
        fun = function() return 'false' end,
    },
    [PATTERN.value_cycle] = {
        fun = function(self, property_name)
            return self:value_cycle_display_value(property_name)
        end,
    },
}


local messages = {
    already_configured = 'Buttons already configured, skipping parsing',
    invalid_format = 'Button %d: Invalid format - expected \'button_name, config\'. Found: %s',
    no_states = "Button '%s': No state configurations provided",
    invalid_state = "Button '%s', State %d: Invalid state format - expected 'state_name@properties'",
    no_properties = "Button '%s', State '%s': No properties defined",
    invalid_property = "Button '%s', State '%s': Invalid property format at position %d - expected 'key=value'",
    empty_state = "Button '%s', State '%s': No valid properties found",
    no_valid_states = "Button '%s': No valid states configured",
    success_button = "Successfully translated button '%s' with %d states",
    success_total = 'Total buttons translated: %d',
    no_valid_buttons = 'No valid buttons configured from %s.conf',
    no_default_state = "No default state defined for button '%s'",
    invalid_state_table = "Invalid state '%s' for button '%s': must be a table",
    invalid_field_type = "Invalid type for field '%s' in state '%s' for button '%s': expected one of %s, got %s",
    invalid_default_state = "Using default values for invalid state '%s' in button '%s'",
    approx_default_error = 'approx_default: No button data available - self.buttons, fallback_states, and controlsdata.buttons are all empty',
    approx_default_found = 'approx_default: Using %s, found default state: %s',
    approx_default_updated = "approx_default: Updated state_map['default'] to: %s",
    update_button_data_unknown = 'update_button_data: unknown button %s',
    swap_default_unknown = 'swap_button_state_to_default: unknown button %s',
    swap_default_no_default = 'swap_button_state_to_default: no default state for button %s',
    swap_default_same_state = 'swap_button_state_to_default: state already matches default',
    swap_default_missing_states = 'swap_button_state_to_default: missing states for button %s: %s vs %s',
    swap_default_promoted = 'swap_button_state_to_default: %s promoted %s for %s',
    set_button_state_nil = 'ButtonManager:set_button_state; state_name is nil or empty',
    set_button_state_not_exist = 'State %s does not exist.',
    set_button_state_not_deduped = 'State %s not in deduped_state_names.',
    set_state_to = 'set state to: %s',
    register_handlers = 'register_message_handlers: set %s',
    update_defaults = 'ButtonManager:update_defaults; default_state_name: %s',
    no_default_skipping = 'No default state configured - skipping handler registration',
    invalid_new_default = 'Invalid new default state requested: %s',
    updating_state_map = 'Updating state mapping for: %s to: %s',
    cycle_prop_no_values = 'cycle-prop-values: no values provided for prop %s',
    insert_values_nil = 'insert_values_in_field: new_value is nil, original=%s',
    unknown_state = "Button '%s': unknown state '%s'",
    state_mappings_parsed = 'State mappings successfully parsed',
    state_map_debug = 'state_map: %s',
    state_cycle_map_debug = 'state_cycle_map: %s',
    resolution_mapping_updated = 'Updated resolution mapping for: %s to: %s',
    resolution_mapping_added = 'Added resolution mapping for: %s to: %s',
    no_state_map_inputevent = 'No state_map defined, inputevent will not be used',
    inputevent_bind_failed = 'Binding key with inputevent failed, inputevent will not be used',
    revert_inputevent = 'revert_inputevent',
    json_parse_error = '%s: %s',
    json_stringify_error = 'JSON stringify error: %s',
    json_parse_debug = 'json_parse_debug: %s (input: %s)',
    new_state_map_received = 'new state_map received',
    set_buttons_called = 'set-buttons called by: %s',
    buttons_received = 'buttons received',
    cycle_to_state = 'cycle to state: %s',
    new_states_not_string = 'new_states must be a string',
    new_state_map_not_string = 'new state_map must be a string',
    button_not_found = 'Button not found: %s',
    parse_button_failed = 'Failed to parse button states JSON',
    update_button = 'Update button %s',
    register_new_button = 'Register new button %s',
    button_added = 'Button added: %s',
    set_state_default = 'set state to default state',
    discovered_shared_state = 'Discovered shared state name: %s',
    swap_default_same = 'swap_button_state_to_default: state already matches default',
    swap_default_no_state = 'swap_button_state_to_default: no target state provided for button %s',
    set_button_state_unknown = "set_button_state: state '%s' not in state_map",
    update_button_not_found = 'update_button: button not found: %s',
    property_no_buttons = "property-changed: no buttons watch property '%s'",
    property_changed_updated = "property-changed: updated %s buttons for prop '%s'",
    swap_default_no_match = 'swap-default: no state matches value=%s for button %s',
    expand_commands_debug = 'expand_commands: substituted command: %s',
    expand_selfupdating_debug = 'expand_selfupdating: active=%s badge=%s tooltip=%s',
    handle_sub_skip = 'handle_substitution: no state/translated for button=%s state=%s',
    handle_sub_skip_field = 'handle_substitution: no field=%s for button=%s state=%s',
    handle_sub_skip_caller = 'handle_substitution: caller=%s does not match prop=%s',
    button_manager_init = 'ButtonManager: init complete, state_map=%s',
    sync_button_states_from_raw = 'sync_button_states_from_raw: button=%s',
    inputevent_debug_state_key = 'inputevent: non-default state/key: %s / %s',
}

local function parse_complex_field_placeholder(expr)
    if type(expr) ~= 'string' then return nil end

    local prop, value = expr:match(PATTERN.compare)
    if prop then
        return { op = COMPLEX_OP.compare, prop = prop, value = value }
    end

    prop, value = expr:match(PATTERN.swap_default)
    if prop then
        return { op = COMPLEX_OP.swap_default, prop = prop, value = value }
    end

    prop, value = expr:match(PATTERN.value_cycle)
    if prop then
        return { op = COMPLEX_OP.value_cycle, prop = prop, value = value }
    end

    return nil
end

local function extract_properties(input_string)
    -- Fields can be non-strings (hide/active booleans); only strings hold [[props]].
    if type(input_string) ~= 'string' then return nil end
    local results = {}
    for match in input_string:gmatch(PATTERN.any_prop) do
        local property_name = match:match(PATTERN.any_complex_op) or match
        table.insert(results, property_name)
    end
    return #results > 0 and results or nil
end

local function split(input_string, primary_separator, key_value_separator)
    local result = {}
    if not input_string then return nil end
    for item in input_string:gmatch(string.format('([^%s]+)', primary_separator)) do
        if key_value_separator then
            local key, value = item:match('(.+)' .. key_value_separator .. '(.+)')
            if key and value then
                result[key] = value
            end
        else
            result[#result + 1] = item
        end
    end

    return result
end

-- MARK: Field separator helpers
-- Known field names used in button state definitions.
-- Used by split_fields() to distinguish field boundaries from colons in values.
local KNOWN_FIELDS = { 'active', 'badge', 'command', 'hide', 'icon', 'tooltip' }

-- Check if a string starting at pos is a field name (e.g. "command=...", "active=...").
-- Returns true only if the text matches a known field name followed by '='.
local function is_field_start(str, pos)
    local rest = str:sub(pos)
    for _, field in ipairs(KNOWN_FIELDS) do
        if rest:match('^[%s]*' .. field .. '=%S*') then
            return true
        end
    end
    return false
end

-- Split a property string on ':' but only when it's a field separator.
-- Button state fields are separated by ':', but values may contain colons
-- (e.g. commands with ports, UUIDs). This function walks the string
-- character by character, splitting only on ':' followed by a known field name.
-- Example: 'icon=loop:command=foo:bar:tooltip=test' => ['icon=loop', 'command=foo:bar', 'tooltip=test']
local function split_fields(str)
    local result = {}
    local current = ''
    local i = 1
    local len = #str
    while i <= len do
        local ch = str:sub(i, i)
        if ch == ':' and is_field_start(str, i + 1) then
            if current ~= '' then
                table.insert(result, current)
                current = ''
            end
        else
            current = current .. ch
        end
        i = i + 1
    end
    if current ~= '' then
        table.insert(result, current)
    end
    return result
end


local function escape_lua_pattern(s)
    return (s:gsub('([%^$()%%.%[%]*+%-?])', '%%%1'))
end

local function table_find(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

local function deep_copy(t)
    if t == nil or type(t) ~= 'table' then return nil end
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = type(v) == 'table' and deep_copy(v) or v
    end
    return t2
end

local function get_table_length(t)
    if t == nil or type(t) ~= 'table' then return 0 end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end
local _debug_file = nil

local function print_msg(msg_key, msg_type, ...)
    if not msg_key then msg_key = 'unknown_message_key' end
    if not msg_type then msg_type = 'debug' end
    local msg_string = messages[msg_key] or msg_key
    local msg = string.format(msg_string, ...)

    if msg_type == 'error' then
        mp.msg.error(msg)
    elseif msg_type == 'warn' then
        mp.msg.warn(msg)
    elseif msg_type == 'debug' then
        mp.msg.debug(msg)
    else
        mp.msg.info(msg)
    end
end

local function has_value(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

return {
    PATTERN = PATTERN,
    COMPLEX_OP = COMPLEX_OP,
    COMPLEX_PATTERN_BY_OP = COMPLEX_PATTERN_BY_OP,
    PARSER_PATTERN_BY_OP = PARSER_PATTERN_BY_OP,
    placeholders = placeholders,
    placeholders_complex = placeholders_complex,
    messages = messages,
    parse_complex_field_placeholder = parse_complex_field_placeholder,
    extract_properties = extract_properties,
    split = split,
    escape_lua_pattern = escape_lua_pattern,
    table_find = table_find,
    deep_copy = deep_copy,
    get_table_length = get_table_length,
    print_msg = print_msg,
    has_value = has_value,
    split_fields = split_fields,
}
