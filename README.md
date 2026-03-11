# WorldMarkerCycler

Cycles through your World of Warcraft world markers using a keybind to place markers in a configurable order, and a second keybind to clear them all.

## Interface Version

Built for **World of Warcraft: Midnight** (`## Interface: 120000`).

## Features

- **Cycle keybind** — places the next world marker in your configured sequence at your cursor position.
- **Clear keybind** — removes all world markers and resets the cycle back to step 1.
- **Options panel** — open with `/wmc` or via ESC > Options > Addons > WorldMarkerCycler.
  - 8 configurable steps, each with a dropdown to assign a world marker (Star, Circle, Diamond, Triangle, Moon, Square, Cross, Skull) or skip the step with "None".
  - Duplicate-prevention: selecting a marker in one row removes it from all other rows' menus.
  - Settings persist across sessions via saved variables.

## Installation

1. Copy the `WorldMarkerCycler` folder into your `World of Warcraft\_retail_\Interface\AddOns\` directory.
2. Reload or log in to the game.

## Usage

1.  Type `/wmc` in chat or go to `ESC > Options > AddOns > WorldMarkerCycler` to open the configuration panel.
2.  Set up your desired marker sequence using the dropdown menus.
3.  Assign keybindings for cycling and clearing markers (see below).

## Keybindings

To use the addon, you must assign keybindings in the game's main menu:

1.  Press `ESC` to open the Game Menu.
2.  Click on **Key Bindings**.
3.  Find the **WorldMarkerCycler** section.
4.  Assign keys to the following actions:
    *   **WMC - Cycle**: Places the next marker in your sequence at your cursor.
    *   **WMC - Clear**: Removes all placed world markers.

Once bound, you can use these keys to manage world markers. Placing markers requires you to have Raid Leader or Assistant privileges.
