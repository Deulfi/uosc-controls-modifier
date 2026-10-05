local mp_utils = require('mp.utils')
-- ucm/button.lua
local utils = require 'utils'

local function make_default_state()
    return {
        icon    = '',
        badge   = nil,
        active  = false,
        tooltip = '',
        command = 'noop',
    }
end
local Button = {}
Button.__index = Button


local STATE_SCHEMA = {
    valid_fields = {
        icon    = {'string', 'nil'},
        badge   = {'string', 'nil'},
        active  = {'string', 'boolean', 'nil'},
        tooltip = {'string', 'nil'},
        command = {'string'},
        hide    = {'string', 'boolean', 'nil'},
    },
}

local function validate_button_state(state_name, state, button_name)
    if type(state) ~= 'table' then
        utils.print_msg('invalid_state_table', 'error', state_name, button_name)
        return false
    end

    for field, value in pairs(state) do
        local valid_types = STATE_SCHEMA.valid_fields[field]
        if valid_types then
            local value_type = type(value)
            local type_valid = false
            for _, valid_type in ipairs(valid_types) do
                if value_type == valid_type or (value == nil and valid_type == 'nil') then
                    type_valid = true
                    break
                end
            end
            if not type_valid then
                utils.print_msg('invalid_field_type', 'error', field, state_name, button_name, table.concat(valid_types, ', '), value_type)
                return false
            end
        end
    end

    return true
end

function Button.new(name, states, config, controlsdata, script_name)
    local self = setmetatable({}, Button)
    self.name = name
    self.states = states
    self.states_translated = {}
    self.active_state = nil
    self.default_state_name = ''
    self.config = config
    self.controlsdata = controlsdata
    self.script_name = script_name
    return self
end

function Button:initialize_states(default_state_name)
    for state_name, state in pairs(self.states) do
        if not validate_button_state(state_name, state, self.name) then
            utils.print_msg('invalid_default_state', 'warn', state_name, self.name)
            self.states[state_name] = utils.deep_copy(make_default_state())
        end
    end

    self.default_state_name = default_state_name

    local first_state = self.states[self.default_state_name]
    if not first_state then
        utils.print_msg('no_default_state', 'error', self.name)
        return
    end

    for key, value in pairs(make_default_state()) do
        if first_state[key] == nil then first_state[key] = value end
    end

    -- Fill-up mutates RAW states by design: the raw layer is the source of truth.
    for state_name, state in pairs(self.states) do
        for key, fill_value in pairs(first_state or make_default_state()) do
            if (state[key] == nil or state[key] == '') and
               not (key == 'active' and utils.extract_properties(fill_value)) then
                state[key] = fill_value
            end
        end
    end

    -- show default; update_state deferred to refresh_all_buttons
    return self
end

function Button:update_state(state_name, button_manager)
    if not self.states_translated then
        self.states_translated = {}
    end
    self:ensure_translated(state_name, button_manager)
    local state = self.states_translated and self.states_translated[state_name]
    -- If requested state doesn't exist, fall back to default state
    if not state and self.states_translated[self.default_state_name] then
        state = self.states_translated[self.default_state_name]
    end
    if not state then
        return
    end

    self.active_state = state

    -- Explicit nil intent (UCM_NIL / {}) across all fields. Runs first so the
    -- sentinel can't fall into the coercion checks below.
    -- The old falsy_values blacklist is retired on purpose (ucm_for_git.conf,
    -- "Field coercion rules"): nil is expressed explicitly, "false"/"0"/"" are literal text.
    if state.badge == 'UCM_NIL' or state.badge == '{}' then state.badge = nil end
    if state.tooltip == 'UCM_NIL' or state.tooltip == '{}' then state.tooltip = nil end
    if state.command == 'UCM_NIL' or state.command == '{}' then state.command = nil end
    if state.hide == 'UCM_NIL' or state.hide == '{}' then state.hide = nil end
    if state.icon == 'UCM_NIL' or state.icon == '{}' then state.icon = nil end
    if state.active == 'UCM_NIL' or state.active == '{}' then state.active = nil end

    -- active: booleans pass through; strings coerced against the active_truthy_values
    -- whitelist (default yes,true,1,inf). Whitelist because prop-resolved actives
    -- (e.g. [[loop-file]] -> "inf"/"0") have no fixed falsy list. Do not reintroduce falsy_values.
    if type(state.active) == 'string' then
        state.active = utils.has_value(self.config.active_truthy_values, state.active)
    elseif type(state.active) ~= 'boolean' then
        state.active = false
    end

    -- badge: only '' maps to nil (an empty badge still renders as an empty badge in uosc);
    -- all other strings, incl. "false"/"0", are literal badge text.
    if type(state.badge) == 'string' and state.badge == '' then state.badge = nil end

    -- hide: 'true'/true hides, 'false'/false shows, other values preserved as-is (no coercion).
    if state.hide == 'true' then state.hide = true end
    if state.hide == 'false' then state.hide = false end
    mp.commandv('script-message-to', 'uosc', 'set-button', self.name, mp_utils.format_json({
        icon    = state.icon,
        badge   = state.badge,
        active  = state.active,
        tooltip = state.tooltip,
        command = state.command,
        hide    = state.hide or false,
    }))
end

-- Copy the raw state into states_translated and run the full placeholder
-- substitution pass over it (forced, even if already translated).
function Button:refresh_translated(state_name, manager)
    self.states_translated[state_name] = utils.deep_copy(self.states[state_name])
    if manager then
        -- Substitution pass: every state field can hold [[prop]]/?(f)/?(p)/complex ops.
        for _, ft in ipairs({'active', 'badge', 'tooltip', 'icon', 'hide', 'command'}) do
            manager:handle_substitution(self, {state_name = state_name, prop = '__all__', type = ft})
        end
    end
    return self
end

-- Like refresh_translated, but skips when the state is already translated
-- or doesn't exist (lazy translation).
function Button:ensure_translated(state_name, manager)
    if self.states_translated[state_name] or not self.states[state_name] then
        return self
    end
    return self:refresh_translated(state_name, manager)
end

return Button
