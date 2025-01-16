# uosc-controls-modifier
   MPV Dynamic Button State Manager for uosc Interface

   ![uosc_control_modifier](https://github.com/user-attachments/assets/66d40b9c-b7c6-4147-b69f-2518597c33a8)


   This script enhances the MPV player uosc interface by enabling dynamic button state management. 
   It acts as a "framework" for defining multiple states for buttons and have them switch between states on certain events.
   It allows buttons to have multiple states triggered by modifier keys (like holding right mouse button pressed) or commands, 
   providing a more interactive and context-sensitive control interface. It is useful if you want certain seldomly used buttons
   still easily accessible with your mouse.
   
   Changes happen on certain events like:
   - Showing a different button while holding a modifier key [inputevent](https://github.com/natural-harmonia-gropius/input-event) is needed for this
   - Defining keys in input.conf to trigger a state change
   - Registered property observers to update the state of the button
   - Using mpv's (auto)profile to trigger a state change. Like switching to fullscreen or playing a mp3 file.
  
## Installation
Place **uosc-controls-modifier.lua** in your mpv `scripts` folder.
Default settings and examples are listed in **uosc-controls-modifier.conf**, copy it to your mpv `script-opts` folder to customize.

## Requirements:
  - [MPV player](https://mpv.io/)
  - [uosc user interface](https://github.com/tomasklaen/uosc)
  - (optional) [inputevent](https://github.com/natural-harmonia-gropius/input-event) (but recommended)

## Note
  - While some descriptions are similar to native uosc descriptions, the buttons that are created with this script are not as powerful as native uosc buttons and I suggest you use them when possible. 
  - Another thing of note is that the visibility of the buttons can be controlled via the uosc.conf file. This means you can still hide buttons that you don't want to see.
  - This script is for more advanced users that can figure out what commands and properties to use themselves.

## Script messages
Some script messages are provided for use in `input.conf`.  
Example usage: `ctrl+1 script-message-to uosc_controls_modifier set name_of_a_state`

`set` statename  
All buttons with the provided state will be updated to the state.

`set-button-state` buttonname statename 
Sets one button to a specific state. 

`cycle` 
Cycles to the next state (as defined in the conf file in either state_map or state_cycle_map)

`cycle-back` 
Cycles to the previous state (as above)


- Script messages that are only useful for other scripts. recipient is the script name of the script that is sending the message (name of your script).
`update-button` buttonname 
Updates the button state to the current state. This should always happen automatically, but you never know.

`get-cycle-states` recipient 
Gets the current cycle states as a json string.

`set-cycle-states` new_states 
Sets the cycle states to the provided json string.

`get-state-map` recipient 
Gets the current state map as a json string.

`set-state-map` new_map 
Sets the state map to the provided json string.

`get-buttons` recipient 
Gets all buttons as a json string.

`set-buttons` buttons_json 
Sets all buttons to the provided json string.

`get-button` recipient button_name 
Gets one button as a json string.

`set-button` button_name button_json 
Sets one button to the provided json string.


- script messages that are only useful if inputevent is used. For example if you define a state for fullscreen, then you could create an auto profile that sets the default state to fullscreen when in fullscreen mode and the state reverts back to fullscreen after an mod key is pressed.
`set-default` statename   
A different state will be marked as default state.

`revert-default`   
Reverts to the original default state.

## Button:
- Each button can have multiple states (state_1, state_2, state_3, etc.) defining:
      * icon: Material Design icon name
      * badge: Optional badge text
      * active: Boolean for active state
      * tooltip: Hover text
      * command: MPV command(s) to execute


   Usage:
   1. Configure buttons in the conf-file
   2. Add button references to uosc.conf  (button:name).
   3. Use one of the methods to switch states.

##  Examples:
   - Change buttons when a modifier key is held. They will be automatically registered with inputevent.lua
   ``` 
   # without inputevent
   state_map=state_1,state_2,state_3
   # with inputevent
   state_map=state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID
   ```
   - Toggle between states without modifier keys. (input.conf)
   ```
   ctrl+1    script-message-to    uosc_controls_modifier    set    state_1
   ctrl+2    script-message-to    uosc_controls_modifier    set    state_2
   ctrl+3    script-message-to    uosc_controls_modifier    set    state_3
   ctrl+4    script-message-to    uosc_controls_modifier    set    fullscreen
   ctrl+5    script-message-to    uosc_controls_modifier    cycle
   ctrl+6    script-message-to    uosc_controls_modifier    cycle-back
   ```
   - Interaction from other scripts.
   ```
   local state_map="state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID,state_2:x"

   mp.commandv('script-message-to', 'uosc_controls_modifier', 'set-state-map', state_map)
   ```
   or
   ```
   mp.commandv('script-message-to', 'uosc_controls_modifier', 'get-button', script_name, 'alt_cycle')
   mp.register_script_message('receive-button', function(name,json)
      print("name:", name, "json:", json)
   end)
   ```
   - Show different default buttons in fullscreen vs. windowed mode. This is only useful if you use modifier keys (mpv.conf)
   ```
   [fullscreen-profile]
   profile-cond=(function()if get("fullscreen") then mp.commandv("script-message-to", "uosc_controls_modifier", "set-default","fullscreen") return true end end)()

   [windowed-profile]
   profile-cond=(function() if not get("fullscreen") then mp.commandv("script-message-to", "uosc_controls_modifier", "revert-default") return true end end)()
   ```
   - uosc.conf controls with example buttons
   ```
   controls=button:alt_control_items,button:alt_control_loop,gap,fullscreen,gap,button:alt_format,gap,<video>button:alt_resolution
   ```
