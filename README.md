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
2. Copy **ucm.conf** into `script-opts` (MPV only auto-reads `script-opts/<script-name>.conf`, so it must keep the name **ucm.conf**).

## Buttons
Each button is defined in ucm.conf (`button1`…`button15`) and referenced in uosc.conf with `button:<name>`:

```
# uosc.conf
controls=button:alt_control_items,button:alt_control_loop,gap,fullscreen,gap,button:alt_format,gap,<video>button:alt_resolution
```

### Button definition (ucm.conf)
A button is a name followed by comma-separated states; each state is a name plus `@`/`:`-separated fields:

```
# conf format: one line, states separated by commas, fields by @/:
button1=example,state_1@icon=list_alt:badge=1:active=true:tooltip=Files:command=script-message-to uosc open-file,state_2@icon=folder_open:tooltip=File Dialog:command=script-message-to uosc show-in-directory
```

Fields (all optional; a state inherits missing fields from its first state):
- **icon** — Material Design icon name ([picker](https://fonts.google.com/icons?icon.platform=web&icon.set=Material+Icons&icon.style=Rounded))
- **badge** — badge text; keep it short (use `gap` in uosc.conf to fix spacing)
- **active** — makes the button active (white background) when its value is true
- **tooltip** — hover text
- **command** — command(s) executed on press; `command1;command2;...`
- **hide** — hides the button (useful when you want to unhide it later via script)

### Global options (ucm.conf)
- **state_map** — which state corresponds to which inputevent modifier key, e.g. `state_map=state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID`. Without inputevent: `state_map=state_1,state_2,state_3`. Empty (`state_map=`): the first state of the first button becomes the default. Keys are registered with inputevent automatically.
- **state_cycle_map** — states cycled by `cycle` / `cycle-back` / `?(c)`. The first entry is the intended default state.
- **resolution_mapping** — `resolution:description` pairs for `?(p)` labels (defaults built in: HDTV, FHD, QHD, 4K, ...).
- **video_types / audio_types / image_types** — file types used by `?(f)` (defaults built in).
- **active_truthy_values** — string values that count as true for `active` (default `yes,true,1,inf`).
- **revert_delay** — extra delay before the buttons revert after an inputevent modifier key is released.

### Placeholders and special values
Any field can reference mpv properties; they update on the fly when the property changes:

| Notation | Meaning |
|---|---|
| `[[property_name]]` | Property reference in any field (e.g. `tooltip=[[video-codec]]`) |
| `[[property??value]]` | Marks the button active when the property equals `value` (e.g. `active=[[audio-device??auto]]`) |
| `[[property?!value]]` | Swap-default placeholder — used by `swap-default` |
| `[[property!!values]]` | Value cycle — creates a custom `user-data/<property>` cycled through `values` (like `cycle-values`) |
| `?(f)` | Media file format label (uses `video_types`/`audio_types`/`image_types`) |
| `?(p)` | Resolution label (uses `resolution_mapping`) |
| `?(c)` / `?(c-)` | State cycle — shows the current state; as a `command` it cycles to the next / previous state (`script-message-to ucm cycle` / `cycle-back`) |

Field values and coercion:
- **badge**: `UCM_NIL` or `{}` hides the badge (explicit nil); any other string (including `"false"`, `"0"`, `""`) is kept as literal badge text; empty after substitution hides automatically.
- **active**: `"true"`/`true` → active; `"false"`/`false` → inactive; other values are checked against `active_truthy_values` (anything not in the list = inactive). A `[[property]]` reference makes the button active while the property is true.
- **hide**: `"true"`/`true` → hidden; `"false"`/`false` → visible; other values preserved.

## Methods to switch states
1. **Modifier keys (inputevent)** — `state_map` entries with keys are registered automatically; hold the key to see the other states, release to revert.
2. **input.conf** — direct state changes:
   ```
   ctrl+1    script-message-to    ucm    set    state_1
   ctrl+2    script-message-to    ucm    set    state_2
   ctrl+3    script-message-to    ucm    cycle
   ctrl+4    script-message-to    ucm    cycle-back
   ```
3. **Property observers** — buttons whose fields reference `[[property]]` update automatically when the property changes.
4. **Auto-profiles** — e.g. show different default buttons in fullscreen vs. windowed mode (mpv.conf):
   ```
   [fullscreen-profile]
   profile-cond=(function()if get("fullscreen") then mp.commandv("script-message-to", "ucm", "set-default","fullscreen") return true end end)()

   [windowed-profile]
   profile-cond=(function() if not get("fullscreen") then mp.commandv("script-message-to", "ucm", "revert-default") return true end end)()
   ```

## Script messages
For `input.conf` / general use:
- **`set` statename** — all buttons with the given state show it.
- **`cycle`** / **`cycle-back`** — next / previous state (per `state_cycle_map`).
- **`set-default` statename** — mark a different state as the default.
- **`revert-default`** — restore the original default state.

For other scripts (recipient = the script name of the calling script; replies arrive as `receive-*` messages):
- **`get-buttons` recipient** / **`set-buttons` buttons_json** — get / set all buttons.
- **`get-button` recipient button_name** / **`set-button` button_name button_json** — get / set one button.
- **`get-state-map` recipient** — returns the current `state_map` (JSON, as `receive-state-map`).
- **`set-state-map` new_map** — sets the `state_map` (`state:KEY,...`) and re-registers inputevent bindings.
- **`get-cycle-states` recipient** / **`set-cycle-states` new_states** — get / set the `state_cycle_map`.
- **`update-button` button_name** — re-translates one button (should be automatic; manual fallback).

Example — other script setting the state map and reading a button:
```lua
mp.commandv('script-message-to', 'ucm', 'set-state-map', 'state_1:default,state_2:MBTN_RIGHT,state_3:MBTN_MID,state_2:x')

mp.commandv('script-message-to', 'ucm', 'get-button', script_name, 'alt_cycle')
mp.register_script_message('receive-button', function(name, json)
    print("name:", name, "json:", json)
end)
```

Example — changing one button's content via key (input.conf):
```
ctrl+7 script-message-to ucm set-button new_button {"state_1":{"icon":"play_arrow","tooltip":"Play","command":"set pause no"},"state_2":{"icon":"pause","tooltip":"Pause","command":"set pause yes"}}
```

## Note
- While some descriptions are similar to native uosc descriptions, the buttons that are created with this script are not as powerful as native uosc buttons and I suggest you use them when possible.
- The visibility of the buttons can be controlled via the uosc.conf file, so you can still hide buttons you don't want to see.
- This script is for more advanced users that can figure out what commands and properties to use themselves.

## Examples
Working scripts live in [examples/](examples/) — see in particular `ucm_inject_buttons.lua` (programmatic button injection, waits for `ucm_ready` before the state map and `ucm-refresh-done` before the button round-trip) and the commented examples inside `ucm.conf`.
