-- ucm/property_manager.lua
local utils = require 'utils'
local FIELD_TYPES = { 'active', 'badge', 'tooltip', 'icon', 'hide', 'command' }

local PropertyManager = {}
PropertyManager.__index = PropertyManager

function PropertyManager.new(config, controlsdata, script_name)
    local self = setmetatable({}, PropertyManager)
    self.config = config
    self.controlsdata = controlsdata
    self.script_name = script_name
    self.property_map = {
        standard = {},
        values = {},
        buttons = {},
    }
    self.swap_observers = {}
    self._value_cycle_initialized = {}

    return self
end

function PropertyManager:track_states_properties(button_name, states)
    local function insert_data(prop, state_name, field_type, passive)
        if not self.property_map.buttons[button_name] then
            self.property_map.buttons[button_name] = {}
        end
        if not self.property_map.standard[prop] then
            self.property_map.standard[prop] = {}
            self:register_property(prop)
        end
        if not passive then
            table.insert(self.property_map.standard[prop], button_name)
        end
        table.insert(self.property_map.buttons[button_name], {state_name = state_name, prop = prop, type = field_type})
    end

    -- All six fields can reference props (any field evaluates props); each is tracked
    -- so property changes trigger substitution and a re-push.
    for state_name, state in pairs(states) do
        for index, field in ipairs({state.active, state.badge, state.tooltip, state.icon, state.hide, state.command}) do
            local field_type = FIELD_TYPES[index]
            if field == nil or type(field) ~= 'string' then
                field = nil
            end

            for _, prop in ipairs(utils.extract_properties(field) or {}) do
                insert_data(prop, state_name, field_type)
            end

            if field then
                for pattern, placeholder in pairs(utils.placeholders) do
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

            local parsed = utils.parse_complex_field_placeholder(field)
            if field_type == 'active' and parsed and parsed.op == utils.COMPLEX_OP.swap_default then
                self:register_swap_property(parsed.prop, button_name)
            end
        end
    end
end

function PropertyManager:register_property(prop_name)
    self.property_map.values[prop_name] = mp.get_property_native(prop_name)
    -- video-params/w and video-params/h are not standalone observable mpv
    -- properties; observe the parent table and extract the field.
    local is_video_params_field = prop_name:match('^video-params/(.+)$')
    local observe_prop = is_video_params_field and 'video-params' or prop_name
    mp.observe_property(observe_prop, 'native', function(_, value)
        if is_video_params_field and type(value) == 'table' then
            self.property_map.values[prop_name] = tostring(value[is_video_params_field] or '')
            mp.commandv('script-message-to', self.script_name, 'property-changed', prop_name, tostring(value[is_video_params_field] or ''))
        else
            self.property_map.values[prop_name] = value
            mp.commandv('script-message-to', self.script_name, 'property-changed', prop_name, tostring(value or ''))
        end
    end)
end

function PropertyManager:register_swap_property(prop_name, button_name)
    if self.swap_observers[prop_name] then return end
    self.swap_observers[prop_name] = true
    mp.observe_property(prop_name, 'string', function(_, value)
        if not value then return end
        mp.commandv('script-message-to', self.script_name, 'swap-default', value, button_name)
    end)
end

function PropertyManager:insert_values_in_field(original, new_values)
    local result = original
    for _, new_value in ipairs(new_values) do
        if not new_value.pattern or not new_value.new_value then
            utils.print_msg('insert_values_nil', 'error', original)
        end

        local string_newvalue = tostring(new_value.new_value)
        result = string.gsub(result, new_value.pattern, string_newvalue)
    end
    return result
end

function PropertyManager:ensure_value_cycle_initialized(short_prop, cycle_values, command)
    local ud_prop = 'user-data/' .. short_prop
    local gate_key = ud_prop .. '\0' .. cycle_values
    local command_parts = {}
    -- falsy_values is retired; only an empty command part is skipped.
    if command and command ~= '' then
        table.insert(command_parts, command)
    end

    if not self._value_cycle_initialized[gate_key] then
        self._value_cycle_initialized[gate_key] = true
        mp.set_property_native(ud_prop, utils.split_list(cycle_values, ' ')[1])

        table.insert(command_parts, string.format(
            [[script-message-to %s cycle-prop-values %s %s]],
            self.script_name,
            ud_prop,
            cycle_values
        ))
    end

    return table.concat(command_parts, '; ')
end

function PropertyManager:value_cycle_display_value(short_prop)
    local ud_prop = 'user-data/' .. short_prop
    local cur = mp.get_property_native(ud_prop)
    if cur == nil then
        cur = mp.get_property(ud_prop)
    end
    return tostring(cur or '')
end

function PropertyManager:expand_selfupdating_placeholders(button_states)
    local function rewrite_customprop_in_field(field_str, short_prop, cycle_values, operator)
        local ud_prop = 'user-data/' .. short_prop
        local needle = '[[' .. short_prop .. operator .. cycle_values .. ']]'
        local escaped = utils.escape_lua_pattern(needle)
        local rewritten = field_str:gsub(escaped, '[[' .. ud_prop .. ']]', 1)
        return rewritten
    end

    local function expand_complex_props(state, field_key)
        local field = state[field_key]
        if type(field) ~= 'string' then return end
        local props = utils.extract_properties(field)
        if not props then return end

        for _, prop in ipairs(props) do
            local parsed = utils.parse_complex_field_placeholder('[[' .. prop .. ']]')
            local operator = utils.COMPLEX_OP.value_cycle
            if parsed and parsed.op == operator then
                state.command = self:ensure_value_cycle_initialized(
                    parsed.prop,
                    parsed.value,
                    state.command
                )
                field = rewrite_customprop_in_field(field, parsed.prop, parsed.value, operator)
                state[field_key] = field
            end
        end
    end

    local function expand_commands(state)
        if not state.command then return end

        -- ?(c)/?(c-) in commands become cycle script messages (conf: button8)
        state.command = state.command:gsub(utils.PATTERN.state_cycle_back,
            'script-message-to ' .. self.script_name .. ' cycle-back')
        state.command = state.command:gsub(utils.PATTERN.state_cycle,
            'script-message-to ' .. self.script_name .. ' cycle')
    end

    for _, state in pairs(button_states) do
        if type(state) ~= 'table' then break end

        expand_commands(state)
        -- Complex-op expansion (??/?!/!!) applies to every field, not just the original three.
        for _, field_key in ipairs({'active', 'badge', 'tooltip', 'icon', 'hide', 'command'}) do
            expand_complex_props(state, field_key)
        end
    end
    return button_states
end

function PropertyManager:getVideoResolutionLabel()
    local width = self.property_map.values['video-params/w'] or ''
    local height = self.property_map.values['video-params/h'] or ''
    local search_res = width .. 'x' .. height

    for _, entry in ipairs(self.controlsdata.res_map_table) do
        if entry.resolution == search_res then
            return entry.description
        end
    end
    return height ~= '' and height .. 'p' or ''
end

function PropertyManager:getMediaFormatLabel()
    local path = self.property_map.values['path']
    local extension = path and path:match('%.([^%.]+)$')

    if not path then return '' end

    if extension and self.config.video_types:find(extension) then
        return self.property_map.values['video-format'] or self.property_map.values['video-codec-name'] or self.property_map.values['video-codec'] or self.property_map.values['audio-codec-name'] or ''
    elseif extension and self.config.audio_types:find(extension) then
        return self.property_map.values['audio-codec-name'] or ''
    elseif extension and self.config.image_types:find(extension) then
        return self.property_map.values['video-format'] or ''
    else
        if path and path:match('^%a+://') then
            return self.property_map.values['video-format'] or self.property_map.values['video-codec-name'] or self.property_map.values['video-codec'] or self.property_map.values['audio-codec-name'] or ''
        end
    end
    return ''
end

return PropertyManager
