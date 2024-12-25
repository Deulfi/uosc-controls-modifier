   # uosc-controls-modifier
   MPV Dynamic Button State Manager for uosc Interface

   This script enhances the MPV player uosc interface by enabling dynamic button state management. 
   It acts as a "freamework" to have multiple buttons apear to occupie the same space on the uosc interface.
   It allows buttons to have multiple states triggered by modifier keys (like mouse buttons) or commands, 
   providing a more interactive and context-sensitive control interface.
   
   changes happen on certain events like:
   - showing a different button while holding a modifier key (like holding the right mouse button)[inputevent](https://github.com/natural-harmonia-gropius/input-event) is needed for this
   - defining keys in input.conf to trigger a state change
   - registered property observers to update the state of the button
   - using mpvs profiles
  
## Installation
Place **uosc-controls-modifier.lua** in your mpv `scripts` folder.
Default settings and examples are listed in **uosc-controls-modifier.conf**, copy it to your mpv `script-opts` folder to customize.

## Requirements:
  - [MPV player](https://mpv.io/)
  - [uosc user interface](https://github.com/tomasklaen/uosc)
  - (optional) [inputevent](https://github.com/natural-harmonia-gropius/input-event)

## Note
  - while some descriptions are similar to native uosc descriptions, the buttons that are created with this script are not as powerful as native uosc buttons and I sugesst you use them wherever possible. 
  - Another thing of note is that the visibility of the buttons can be controlled via the uosc.conf file. This means you can still hide buttons that you don't want to see in certain conditions.

## Script messages
Some script messages are provided for use in `input.conf`.  
Example usage: `ctrl+1 script-message-to uosc_controls_modifier set state_1`

`set` statename  
All buttons with the provided state name will be shown. Default state will be shown for all other buttons.

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
   3. Use modifier keys (like right mouse button) to access different states for dynamic, context-sensitive controls.



##  Examples:
   - Change playlist controls when a modifier key is held. They will be automatically registered with inputevent.lua
   ``` 
   modifier_keys=state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID
   ```
   - Toggle between states without modifier keys. (input.conf)
   ```
   ctrl+1    script-message-to    uosc_controls_modifier    set    state_1
   ctrl+2    script-message-to    uosc_controls_modifier    set    state_2
   ctrl+3    script-message-to    uosc_controls_modifier    set    state_3
   ctrl+4    script-message-to    uosc_controls_modifier    set    fullscreen
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
   controls=button:alt_control_items,button:alt_control_loop,gap,fullscreen,gap,button:alt_format,gap,<video>button:alt_resolution,
   ```


