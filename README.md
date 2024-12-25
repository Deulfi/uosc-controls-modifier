   MPV Dynamic Button State Manager for uosc Interface

   This script enhances the MPV player uosc interface by enabling dynamic button state management. 
   It allows buttons to have multiple states triggered by modifier keys (like mouse buttons) or commands, 
   providing a more interactive and context-sensitive control interface.

   Key Features:
   - Multiple states per button (default, right-click, middle-click, etc.) with inheritance of default values.
   - Automatic state updates through property observation.
   - Modifier key support for dynamic state switching with customizable revert delay.
   - JSON-based button configuration for easy setup.

   Button States:
   - Each button can have multiple states (state_1, state_2, state_3, etc.) defining:
       * icon: Material Design icon name
       * badge: Optional badge text
       * active: Boolean for active state
       * tooltip: Hover text
       * command: MPV command to execute

   How it Works:
   1. Define buttons and their states in the options table.
   2. The script creates Button objects, managing multiple states and their properties.
   3. A ButtonManager orchestrates behavior, including:
      - Parsing modifier keys
      - Registering message handlers for state changes
      - Setting up property observers
      - Managing input events
      - Handling default state and state transitions

   Usage:
   1. Configure buttons in the options table.
   2. Add button references to uosc.conf.
   3. Use modifier keys (like right mouse button) to access different states for dynamic, context-sensitive controls.

   Requirements:
   - MPV player
   - uosc user interface

   Example Use Cases:
   - Change playlist controls when a modifier key is held.
   - Toggle between file and playlist looping.
   - Show different button options in fullscreen vs. windowed mode.

   Script Messages:
   - set state_X: Switch to state X
   - set default: Change default state
   - revert default: Revert to original default state
