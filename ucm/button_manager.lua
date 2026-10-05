-- ucm/button_manager.lua
local utils = require 'utils'
local Button = require 'button'
local PropertyManager = require 'property_manager'

local ButtonManager = {}
ButtonManager.__index = ButtonManager

function ButtonManager.new(config, controlsdata, script_name)
    local self = setmetatable({}, ButtonManager)
    self.config = config
    self.controlsdata = controlsdata
    self.script_name = script_name
    self.property_manager = PropertyManager.new(self.config, self.controlsdata, self.script_name)
    self.buttons = {}
    self.deduped_state_names = {}
    self.current_active_state = ''
    self.default_state_name = ''

    return self
end

function ButtonManager:unregister_all_handlers()
    mp.unregister_script_message('update-button')
    mp.unregister_script_message('property-changed')
    mp.unregister_script_message('swap-default')
    mp.unregister_script_message('set-default')
    mp.unregister_script_message('revert-default')
    mp.unregister_script_message('cancel_revert')
    mp.unregister_script_message('revert_inputevent')
    mp.unregister_script_message('set')
    mp.unregister_script_message('cycle-prop-values')
end

function ButtonManager:init()
    self:unregister_all_handlers()
    self.default_state_name = self.controlsdata.state_map['default']
    self.current_active_state = self.default_state_name

    self:parse_new_states()
    self:initialize_buttons()
    self:register_default_handlers()
    self:register_script_messages()
    self:refresh_all_buttons()

    mp.set_property_native('user-data/ucm_currstate', 1)

    mp.register_event('file-loaded', function()
        mp.add_timeout(0.1, function()
            self:refresh_all_buttons()
        end)
    end)
end

function ButtonManager:refresh_all_buttons()
    -- ponytail: full re-translate; fine at ~12 buttons, revisit if count grows
    local state = self.current_active_state
    if not state or state == '' then state = self.default_state_name end
    for button_name, button in pairs(self.buttons) do
        if button then
        button:refresh_translated(state, self)
        for other_state in pairs(button.states) do
            if other_state ~= state then
                button:refresh_translated(other_state, self)
            end
        end
            button:update_state(state, self)
        end
    end
    mp.commandv('script-message', 'ucm-refresh-done')
end

function ButtonManager:parse_new_states(partial_buttons)
    local source = partial_buttons or self.controlsdata.buttons
    for _, button_data in pairs(source) do
        local states_to_check = partial_buttons and button_data.states or button_data
        for state in pairs(states_to_check) do
            if not self.deduped_state_names[state] then
                utils.print_msg('discovered_shared_state', 'debug', state)
            end
            self.deduped_state_names[state] = true
        end
    end

    if type(self.controlsdata.state_cycle_map) == 'table' then
        for _, cycle_state in ipairs(self.controlsdata.state_cycle_map) do
            if not self.deduped_state_names[cycle_state] then
                self.deduped_state_names[cycle_state] = true
            end
        end
    end
end

function ButtonManager:approx_default(fallback_states)
    local state_count = {}
    local source = {}
    local source_name = ''

    if self.buttons and next(self.buttons) then
        source = self.buttons
        source_name = 'self.buttons'
        for button_name, button in pairs(source) do
            for state_name in pairs(button.states) do
                state_count[state_name] = (state_count[state_name] or 0) + 1
            end
        end
    elseif self.controlsdata.buttons and next(self.controlsdata.buttons) then
        source = self.controlsdata.buttons or {}
        source_name = 'self.controlsdata.buttons'
        for button_name, button_states in pairs(source) do
            for state_name in pairs(button_states) do
                state_count[state_name] = (state_count[state_name] or 0) + 1
            end
        end
    elseif fallback_states and next(fallback_states) then
        source = {temp_button = fallback_states}
        source_name = 'fallback_states'
        for state_name in pairs(fallback_states) do
            state_count[state_name] = (state_count[state_name] or 0) + 1
        end
    else
        utils.print_msg('approx_default_error', 'error')
        return ''
    end

    local max_count = 0
    local most_frequent_state = ''

    for state_name, count in pairs(state_count) do
        if count > max_count then
            max_count = count
            most_frequent_state = state_name
        end
    end

    utils.print_msg('approx_default_found', 'debug', source_name, most_frequent_state)

    if most_frequent_state and most_frequent_state ~= '' then
        self.controlsdata.state_map['default'] = most_frequent_state
        self.default_state_name = most_frequent_state
        utils.print_msg('approx_default_updated', 'debug', most_frequent_state)
    end

    return most_frequent_state
end

function ButtonManager:sync_button_states_from_raw(button, button_name, raw_states)
    local processed = utils.deep_copy(raw_states)
    processed = self.property_manager:expand_selfupdating_placeholders(processed)
    button.states = processed
    button.states_translated = {}
    local state_name = self.default_state_name
    if not state_name or state_name == '' then
        state_name = self:approx_default(processed)
    end
    button:initialize_states(state_name)
    self.property_manager:track_states_properties(button_name, button.states)
end

function ButtonManager:initialize_buttons()
    for button_name, button_states in pairs(self.controlsdata.buttons) do
        self:initialize_button(button_name, button_states)
    end
end

function ButtonManager:initialize_button(button_name, button_states)
    local button = Button.new(button_name, {}, self.config, self.controlsdata, self.script_name)
    self:sync_button_states_from_raw(button, button_name, button_states)
    self.buttons[button_name] = button
    utils.print_msg('button_added', 'debug', button_name)
end

function ButtonManager:register_new_button(button_name, button_states)
    self:initialize_button(button_name, button_states)
    self:parse_new_states({ [button_name] = { states = self.buttons[button_name].states } })
    self:refresh_all_buttons()
end

function ButtonManager:update_button_data(button_name, button_states)
    local button = self.buttons[button_name]
    if not button then
        utils.print_msg('update_button_data_unknown', 'debug', button_name)
        return
    end
    self:sync_button_states_from_raw(button, button_name, button_states)
    self:parse_new_states({ [button_name] = { states = button.states } })
    self:refresh_all_buttons()
    button:update_state(self.current_active_state, self)
end

function ButtonManager:swap_button_state_to_default(button_name, state_that_should_be_default, prop_name)
    local button = self.buttons[button_name]
    if not button then
        utils.print_msg('swap_default_unknown', 'debug', button_name)
        return false
    end

    local current_default = button.default_state_name or self.default_state_name
    if not current_default or current_default == '' then
        utils.print_msg('swap_default_no_default', 'debug', button_name)
        return false
    end

    if not state_that_should_be_default or state_that_should_be_default == '' then
        return false
    end

    if state_that_should_be_default == current_default then
        return false
    end

    local states = button.states or {}
    local translated = button.states_translated or {}
    local default_state = states[current_default]
    local target_state = states[state_that_should_be_default]
    if not default_state or not target_state then
        utils.print_msg('swap_default_missing_states', 'debug', button_name, current_default, state_that_should_be_default)
        return false
    end


    button:ensure_translated(current_default, self)
    button:ensure_translated(state_that_should_be_default, self)
    states[current_default], states[state_that_should_be_default] = target_state, default_state
    translated[current_default], translated[state_that_should_be_default] =
        translated[state_that_should_be_default], translated[current_default]

    if self.current_active_state == current_default then
        button.active_state = translated[current_default] or states[current_default]
    end

    button:update_state(button.default_state_name, self)
    utils.print_msg('swap_default_promoted', 'debug', button_name, state_that_should_be_default, prop_name or '')
end

function ButtonManager:set_button_state(state_name)
    utils.print_msg('set_state_to', 'debug', state_name)
    if not state_name or state_name == '' then
        utils.print_msg('set_button_state_nil', 'debug')
        return
    end
    if not self.deduped_state_names[state_name] then
        if not self.controlsdata.state_map[state_name] and not utils.has_value(self.controlsdata.state_cycle_map, state_name) then
            utils.print_msg('set_button_state_unknown', 'warn', state_name)
            return
        end
    end
    self.current_active_state = state_name

    for _, button in pairs(self.buttons) do
        button:update_state(state_name, self)
    end
end

function ButtonManager:show_default()
    self:set_button_state(self.default_state_name)
end

function ButtonManager:register_script_messages()
    mp.register_script_message('update-button', function(button_name)
        self:update_button(button_name)
    end)

    mp.register_script_message('property-changed', function(prop_name, value)
        self.property_manager.property_map.values[prop_name] = value
        local affected_buttons = self.property_manager.property_map.standard[prop_name] or {}
        for _, button_name in ipairs(affected_buttons) do
            local button = self.buttons[button_name]
            if button then
                -- Update ALL states that reference this property
                for state_name in pairs(button.states) do
                    if button.states[state_name] then
                        button:refresh_translated(state_name, self)
                    end
                end
                -- Update display for current active state (or fallback)
                if button.states[self.current_active_state] then
                    button:update_state(self.current_active_state, self)
                elseif button.states_translated[self.default_state_name] then
                    button:update_state(self.default_state_name, self)
                end
            end
        end
    end)

    mp.register_script_message('swap-default', function(value, button_name)
        if not value then return end

        local button = self.buttons[button_name]
        if not button or not button.states then return end
        local button_states = button.states

        for state_name, state in pairs(button_states) do
            local parsed = utils.parse_complex_field_placeholder(state and state.active)
            if parsed
                and parsed.op == utils.COMPLEX_OP.swap_default
                and parsed.value == value
            then
                if self:swap_button_state_to_default(button_name, state_name, parsed.prop) then
                    break
                end
            end
        end
    end)

    mp.register_script_message('cycle-prop-values', function(prop, ...)
        local values = {...}
        local current = mp.get_property_native(prop)
        local current_idx = utils.table_find(values, current) or 0
        if not values[1] then
            utils.print_msg("cycle_prop_no_values", "error", prop)
            return
        end
        local next_value = values[(current_idx % #values) + 1]
        mp.set_property(prop, next_value)
    end)
    mp.register_script_message('set', function(state_name)
        if state_name == 'default' then
            mp.set_property_number('user-data/ucm_currstate', 1)
            self:show_default()
            return
        end
        for i, state in ipairs(self.controlsdata.state_cycle_map or {}) do
            if state == state_name then
                mp.set_property_number('user-data/ucm_currstate', i)
                break
            end
        end
        self:set_button_state(state_name)
    end)
end

function ButtonManager:update_button(button_name)
    if not self.buttons[button_name] then return end
    self.buttons[button_name]:update_state(self.current_active_state, self)
end

function ButtonManager:update_defaults()
    if not self.controlsdata.state_map then return false end

    self.default_state_name = self.controlsdata.state_map['default']

    if not self.default_state_name then return false end

    utils.print_msg('update_defaults', 'debug', self.default_state_name)

    for _, button in pairs(self.buttons) do
        button.default_state_name = self.default_state_name
    end
    self:show_default()
end

function ButtonManager:register_default_handlers()
    if not self.default_state_name or self.default_state_name == '' then
        utils.print_msg('no_default_skipping', 'debug')
        return
    end

    mp.unregister_script_message('set-default')
    mp.unregister_script_message('revert-default')

    local initial_config = {
        state_map = utils.deep_copy(self.controlsdata.state_map),
        cycle_map = utils.deep_copy(self.controlsdata.state_cycle_map),
        default_state = self.default_state_name
    }

    mp.register_script_message('set-default', function(new_default_state)
        if not new_default_state or not self.deduped_state_names[new_default_state] then
            utils.print_msg('invalid_new_default', 'debug', new_default_state)
            return
        end

        local previous_default = self.controlsdata.state_map['default']

        local prev_index = utils.table_find(self.controlsdata.state_cycle_map, previous_default)
        local new_index = utils.table_find(self.controlsdata.state_cycle_map, new_default_state)

        if prev_index then
            if new_index then
                self.controlsdata.state_cycle_map[prev_index], self.controlsdata.state_cycle_map[new_index] =
                    self.controlsdata.state_cycle_map[new_index], self.controlsdata.state_cycle_map[prev_index]
            else
                self.controlsdata.state_cycle_map[prev_index] = new_default_state
            end
        end

        for key, state_name in pairs(self.controlsdata.state_map) do
            if state_name == previous_default then
                mp.msg.debug('Updating state mapping for:', key, 'to:', new_default_state)
                self.controlsdata.state_map[key] = new_default_state
            end
        end

        mp.set_property_number('user-data/ucm_currstate', 1)

        self.controlsdata.state_map['default'] = new_default_state
        self.default_state_name = new_default_state

        self:show_default()
    end)

    mp.register_script_message('revert-default', function()
        self.controlsdata.state_map = utils.deep_copy(initial_config.state_map)
        self.default_state_name = initial_config.default_state
        self.controlsdata.state_cycle_map = utils.deep_copy(initial_config.cycle_map)
        self:show_default()
    end)
end

-- MARK: handle_subs
function ButtonManager:handle_substitution(button, data)
    local state_name, prop_name, field_type = data.state_name, data.prop, data.type

    button:ensure_translated(state_name, self)

    local state = button.states[state_name]
    local translated = button.states_translated[state_name]

    if not state or not translated then return end

    local orig_field = state[field_type]
    -- Non-string fields (hide/active booleans) hold no placeholders; substitution is string-only.
    if type(orig_field) ~= 'string' then return end

    local new_values = {}
    local props = utils.extract_properties(orig_field)
    if props and (prop_name == '__all__' or utils.has_value(props, prop_name)) then

        for _, old_prop_name in ipairs(props) do
            local prop_value = self.property_manager.property_map.values[old_prop_name]
            local value = prop_value ~= nil and tostring(prop_value) or ''
            local pattern = ('[[' .. old_prop_name .. ']]'):gsub('([%.%-%+%[%]%(%)%$%^%?%*])', '%%%1')
            table.insert(new_values, {pattern = pattern, new_value = value})
        end
    end

    for raw_pattern, placeholder in pairs(utils.placeholders) do
        if orig_field:match(raw_pattern) then
            local value = placeholder.fun(self.property_manager)
            table.insert(new_values, {pattern = raw_pattern, new_value = value})
        end
    end

    local parsed = utils.parse_complex_field_placeholder(orig_field)
    local raw_pattern = parsed and utils.COMPLEX_PATTERN_BY_OP[parsed.op] or nil
    local placeholder = raw_pattern and utils.placeholders_complex[raw_pattern] or nil
    if parsed and placeholder then
        if parsed.op == utils.COMPLEX_OP.value_cycle then
            self.property_manager:ensure_value_cycle_initialized(parsed.prop, parsed.value, state.command)
        end
        local use_complex = (field_type == 'active' and parsed.op ~= utils.COMPLEX_OP.value_cycle)
            or parsed.op == utils.COMPLEX_OP.value_cycle
        if use_complex then
            local value = placeholder.fun(self.property_manager, parsed.prop, parsed.value)
            table.insert(new_values, {pattern = raw_pattern, new_value = value})
        end
    end

    translated[field_type] = self.property_manager:insert_values_in_field(orig_field, new_values)
end

return ButtonManager
