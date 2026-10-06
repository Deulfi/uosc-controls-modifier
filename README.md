# uosc-controls-modifier (ucm)
MPV Dynamic Button State Manager for the uosc interface

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
- Using mpv's (auto)profile to trigger a state change. Like switching to fullscreen or playing an mp3 file.

## Requirements
- [MPV player](https://mpv.io/)
- [uosc user interface](https://github.com/tomasklaen/uosc)
- (optional) [inputevent](https://github.com/natural-harmonia-gropius/input-event) (but recommended)

## Installation
1. Copy the **ucm/** folder into your mpv `scripts` folder. MPV loads it as the script named **`ucm`**.
2. Copy **ucm.conf** into `script-opts` (MPV only auto-reads `script-opts/<script-name>.conf`). The conf carries the full button syntax plus commented example buttons.

## Buttons
Each button is defined in ucm.conf (`button1`…`button15`) and referenced in uosc.conf with `button:<name>`.
Each button has multiple states (`state_1`, `state_2`, …), each with optional fields:

- **icon** — Material Design icon name
- **badge** — badge text
- **active** — makes the button active (white background) when true
- **tooltip** — hover text
- **command** — command(s) executed on press
- **hide** — hides the button (useful to unhide it later via script)

States can be switched by:
1. Holding a modifier key — states mapped in `state_map` are registered with inputevent automatically.
2. Keys in `input.conf` (script messages below).
3. Property observers — fields referencing `[[property]]` update on the fly.
4. Auto-profiles — `set-default` / `revert-default` (examples below).

The button definition syntax, placeholders (`[[…]]`, `?(f)`, `?(p)`, `?(c)`), field coercion and fill-up rules are documented inside [ucm.conf](ucm.conf).

## Script messages
For `input.conf` / general use:
- **`set` statename** — all buttons with the given state show it.
- **`cycle`** / **`cycle-back`** — next / previous state (per `state_cycle_map`).
- **`set-default` statename** — mark a different state as the default.
- **`revert-default`** — restore the original default state.

For other scripts (recipient = the calling script's name; replies arrive as `receive-*` messages):
- **`get-buttons` recipient** / **`set-buttons` buttons_json** — get / set all buttons.
- **`get-button` recipient button_name** / **`set-button` button_name button_json** — get / set one button.
- **`get-state-map` recipient** / **`set-state-map` new_map** — get / set the `state_map`.
- **`get-cycle-states` recipient** / **`set-cycle-states` new_states** — get / set the `state_cycle_map`.
- **`update-button` button_name** — re-translates one button (should be automatic; manual fallback).

## Examples
- `state_map` variations (ucm.conf):
  ```
  # with inputevent
  state_map=state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID
  # without inputevent
  state_map=state_1,state_2,state_3
  # without both, the first state of the first button becomes the default
  state_map=
  ```
- Toggle between states without modifier keys (input.conf):
  ```
  ctrl+1    script-message-to    ucm    set    state_1
  ctrl+2    script-message-to    ucm    set    state_2
  ctrl+3    script-message-to    ucm    cycle
  ctrl+4    script-message-to    ucm    cycle-back
  ```
- Different default buttons in fullscreen vs. windowed mode (mpv.conf):
  ```
  [fullscreen-profile]
  profile-cond=(function()if get("fullscreen") then mp.commandv("script-message-to", "ucm", "set-default","fullscreen") return true end end)()

  [windowed-profile]
  profile-cond=(function() if not get("fullscreen") then mp.commandv("script-message-to", "ucm", "revert-default") return true end end)()
  ```
- uosc.conf controls with example buttons:
  ```
  controls=button:alt_control_items,button:alt_control_loop,gap,fullscreen,gap,button:alt_format,gap,<video>button:alt_resolution
  ```
- Interaction from other scripts:
  ```lua
  mp.commandv('script-message-to', 'ucm', 'set-state-map', 'state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID,state_2:x')

  mp.commandv('script-message-to', 'ucm', 'get-button', script_name, 'alt_cycle')
  mp.register_script_message('receive-button', function(name, json)
      print("name:", name, "json:", json)
  end)
  ```
- Changing a button's content via key (input.conf, compact JSON without spaces):
  ```
  ctrl+7 script-message-to ucm set-button new_button {"state_1":{"icon":"play_arrow","tooltip":"Play","command":"set pause no"},"state_2":{"icon":"pause","tooltip":"Pause","command":"set pause yes"}}
  ```

## Docs
- Button syntax, placeholders, field coercion: commented at the top of [ucm.conf](ucm.conf).
- Full documentation: [wiki](https://github.com/Deulfi/uosc-controls-modifier/wiki).

## Note
- While some descriptions are similar to native uosc descriptions, the buttons that are created with this script are not as powerful as native uosc buttons and I suggest you use them when possible.
- The visibility of the buttons can be controlled via the uosc.conf file, so you can still hide buttons you don't want to see.
- This script is for more advanced users that can figure out what commands and properties to use themselves.
