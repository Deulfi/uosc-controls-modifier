-- Test script for uosc_controls_modifier.lua
mp.utils = require "mp.utils"
local script_name = mp.get_script_name()

-- Test receiving and modifying buttons
mp.register_script_message('test_all_buttons', function()
    -- Request all buttons
    mp.commandv('script-message-to', 'uosc_controls_modifier', 'get-buttons', script_name)
end)

mp.register_script_message('receive-buttons', function(buttons)
    --print("Received all buttons:", buttons)
    --print("Received all buttons:")
    -- Modify and send back
    mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-buttons', buttons)
end)

-- Test single button modification
mp.register_script_message('test_single_button', function(button_name)
    mp.commandv('script-message-to', 'uosc_controls_modifier', 'get-button', script_name, button_name)
end)

mp.register_script_message('receive-button', function(button_name, button_json)
    --print("Testing button:", button_name)
    --print("Original button config:", button_json)
    
    local button = mp.utils.parse_json(button_json)
    
    -- Test modifications
    button.state_1.icon = "testing_icon"
    button.state_1.tooltip = "Testing Tooltip"
    button.state_1.badge = "TEST"
    
    -- Test adding new state
    button.state_test = {
        icon = "test_state",
        tooltip = "Test State",
        badge = "T",
        command = "script-message test_command"
    }
    
    --print("Modified button config:", mp.utils.format_json(button))
    mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-button', button_name, mp.utils.format_json(button))

    mp.add_timeout(3, function()
        mp.commandv('script-message-to', 'uosc_controls_modifier', 'set', 'state_test')
    end)
end)

-- Additional test cases
local function run_tests()
    local test_button = "new_button"
    local test_value = '{"state_1":{"icon":"test","tooltip":"[[duration]]","badge":"[[chapters]]","command":"cycle pause"}}'
    --ctrl+7 script-message-to uosc_controls_modifier set-button new_button {"state_1":{"badge":"1234567890"},"state_2":{"badge":""}}
    -- Test property handling
    mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-button', test_button, test_value)

    -- Test state switching
    mp.add_timeout(3, function()
        mp.commandv('script-message-to', 'uosc_controls_modifier', 'set', 'state_2')
    end)

    -- Test default state reverting
    mp.add_timeout(4, function()
        mp.commandv('script-message-to', 'uosc_controls_modifier', 'revert-default')
    end)

    -- Run tests on file load
    mp.register_event("file-loaded", run_tests)
end



-- Keybind to trigger test suite
mp.add_key_binding("Ctrl+Alt+t", "run_uosc_modifier_tests", function()
    --print("Starting uosc_controls_modifier tests")
    mp.commandv('script-message-to', script_name, 'test_all_buttons')
    mp.commandv('script-message-to', script_name, 'test_single_button', 'alt_control_items')
    run_tests()
end)

-- make newbutton invisible
mp.commandv('script-message-to', 'uosc', 'set-button', 'new_button', mp.utils.format_json({
    icon    = '',
    badge   = nil,
    active  = nil,
    tooltip = nil,
    command = 'script-message-to ' .. script_name .. "init_call",
}))

mp.register_script_message('init_call', function()
    mp.msg.info("init_call")
end)