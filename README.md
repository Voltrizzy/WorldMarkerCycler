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

| Action | How |
|---|---|
| Open options | `/wmc` |
| Place next marker | Assign a keybind under ESC > Key Bindings > WorldMarkerCycler |
| Clear all markers | Assign a keybind under ESC > Key Bindings > WorldMarkerCycler |

## Notes

- Placing markers requires raid leader or raid assistant rank.
- The addon uses `RunMacroText("/wm [@cursor] N")` to place markers at your cursor position, identical to using the built-in macro.
