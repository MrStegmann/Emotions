<div align="center">

# Emotions

**Fast-click conceptual menu for WoW Epsilon emote commands.**

[![World of Warcraft - Epsilon](https://img.shields.io/badge/World_of_Warcraft-Epsilon-blue?style=flat-square)](#)
[![Version 1.0.0](https://img.shields.io/badge/Version-1.0.0-brightgreen?style=flat-square)](#)
[![Lua](https://img.shields.io/badge/Language-Lua-00007A?style=flat-square&logo=lua&logoColor=white)](#)

</div>

Emotions is a World of Warcraft addon designed specifically for the Epsilon WoW server. It provides a fast-click, conceptual menu for executing emote commands (e.g., `.mod stand 720`), eliminating the need to type them out manually. With Emotions, you can easily save, label, organize, and quickly trigger your favorite emotes.

> [!TIP]
> The addon automatically persists your custom emotes and configurations across sessions using `SavedVariables`.

## Features

- **Conceptual Menu Interface:** A clean, intuitive UI to access all your saved emotes.
- **Custom Labels:** Assign custom names to your emotes for easy identification.
- **Fast-Click Execution:** Trigger emotes instantly with a single click.
- **Pagination:** Supports an unlimited number of emotes across multiple menu pages.
- **Search Filtering:** Quickly find specific emotes by name or ID using the built-in search box.
- **Draggable Menu:** Drag the conceptual menu anywhere on your screen—the addon will remember its exact position.
- **Persistent Storage:** Your custom emotes and layouts are saved safely across gaming sessions.
- **Quick Access:** A convenient launcher button seamlessly integrated into the chat frame, plus a dedicated close button.

## Usage

1. Open the **Emotions** menu by clicking the launcher icon near the chat window.
2. Click the **[+]** icon (Add Button) to create a new emote entry.
3. Enter a descriptive **Label** and the corresponding **Emote ID** (e.g., `720` for `.mod stand 720`).
4. Click **Save** to add it to your menu.
5. Simply click on any saved emote in the menu to instantly execute the command in-game.
6. Use the **Search Box** at the top of the menu to instantly filter and sort your saved emotes alphabetically.
7. **Left-Click & Drag** the menu to move it anywhere on your screen. The position will be saved automatically.
8. Click the gear icon to toggle **Edit Mode**, allowing you to update or remove existing emotes.
9. Click the **"X"** button to easily close the menu.

## Installation

1. Clone or download this repository.
2. Place the `Emotions` folder into your World of Warcraft `_retail_/Interface/AddOns/` directory.
3. Launch World of Warcraft and ensure the addon is enabled in the AddOns menu at the character selection screen.

## Architecture

This project follows strict engineering practices tailored for the WoW UI environment:

- **Single Responsibility Principle (SRP):** Clean separation of concerns across different files and modules.
- **Event-Driven:** Robust handling of WoW API lifecycle events like `ADDON_LOADED` and `PLAYER_LOGIN`.
- **Modular Namespace:** Carefully encapsulated code to prevent global variable pollution.
