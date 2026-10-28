# Echoes of the Ossuary

An isometric 3D Action-RPG / Roguelite Dungeon Crawler built in **Godot 4.x** with stylized low-poly aesthetics, fluid melee & ranged combat, procedural chamber generation, and permanent meta-progression.

---

## ⚔️ Key Features

- **Dynamic Melee & Ranged Combat:**
  - 3-hit melee combo sequence (Slash Left $\rightarrow$ Slash Right $\rightarrow$ Whirlwind Finisher).
  - Class-specific mechanics:
    - **Iron Warden (Knight):** Heavy sword & shield blocking, balanced defense.
    - **Blood Reaver (Barbarian):** Massive 2-handed cleaves & spinning leap strikes.
    - **Shadow Stalker (Rogue):** Rapid lunging daggers & evasion.
    - **Soul Siphon (Mage):** Homing ranged arcane projectiles.
- **Skeletal Animation & Socket System:**
  - Powered by KayKit CC0 rigged characters and animation libraries (`KayKit_Rig`).
  - Modular weapon socketing via `BoneAttachment3D` bound to `"handslot.r"` and `"handslot.l"`.
  - Seamless dual-mode fallback: procedural CSG animations if 3D assets are missing.
- **Procedural Dungeon Chambers (2-Meter Grid Standard):**
  - Grid-aligned wall, floor, door, pillar, and trap placement.
  - Multi-chamber progression leading from Sanctuary to the Skeletal Warden boss.
  - Abyss/Void protection barriers preventing player/enemy fallouts.
  - Instant descent through prominent runic soul beacons.
- **Combat Juice & Feedback:**
  - Directional hit-flash emission shaders.
  - Frame-freeze hitstop (`Engine.time_scale`).
  - Screen trauma shake & floating 3D billboard damage numbers (with critical strike scaling).
  - Procedural 16-bit PCM audio synthesizer for impacts, footsteps, soul pickup, and dungeon drones.
- **Meta-Progression & Bounties:**
  - Persistent Soul Echoes economy saved to `user://echoes_save.json`.
  - In-game Mission / Bounty HUD with claimable rewards.
  - Sanctuary upgrade altar for permanent stat increases.

---

## 🎮 Controls

| Action | Keyboard / Mouse |
| :--- | :--- |
| **Move** | `W`, `A`, `S`, `D` / Arrow Keys |
| **Aim** | Mouse Cursor |
| **Attack** | Left Mouse Button / `J` |
| **Dash / Evade** | `Spacebar` / `K` |
| **Interact / Open Chest** | `E` |
| **Missions / Bounties** | `Tab` / `M` |
| **Pause / Sanctuary Menu** | `Esc` |

---

## 🚀 Running the Project

### Option A: Via Godot Editor
1. Open Godot Engine 4.x.
2. Click **Import** and select the `project.godot` file in this repository.
3. Press **F5** (or the Play button in the top right) to launch.

### Option B: Quick Launch Scripts (Windows)
- Double-click `Run_Game.bat` to launch the game directly.
- Double-click `Open_In_Godot_Editor.bat` to open the project in the Godot Editor.

---

## 🎨 Asset Credits & Licensing
- 3D Models & Characters: [KayKit](https://kaylousberg.itch.io/) (CC0 1.0 Universal - Public Domain)
- Audio Synthesizers & Soundscapes: Built-in procedural 16-bit PCM synth (`AudioManager.gd`)
