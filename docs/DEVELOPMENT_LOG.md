# Development log

Engine: Godot **4.7.2.stable.official.ed1daf0bf**, Linux x86_64, run from the home directory. It is not committed.

Headless checks:

```
godot --headless --path . res://tests/test_runner.tscn
```

Last run on 2026-10-25: **ALL TESTS PASSED**.

Passed: contact counted once, resting energy is zero, reload order, scheduler tie break, core victory, timeout tie, no overlap on the timber keep, all five campaign layouts and their loadouts are legal, overlap is rejected, a floating core is rejected, save round-trip restores Homestead and a bad version is rejected, an over-budget loadout is rejected, match actions reject an unknown weapon and power above 1, a shield spends 55 energy and weakens a boulder, easy and hard aim rolls differ, rapid reload is faster than siege master and siege master hits harder, trajectory error 0 px, a bolt stops on a block, a resting stack loses no durability, one hit raises one damage event, an explosion pushes a near body and not a far one, breaking the core ends the quick battle, a campaign scene spawns two separated keeps and does not end on the first frames.

The suite prints a camera warning because physics interpolation moves Camera2D onto the physics tick. On exit it also reports leftover canvas and physics resources, because the process quits before those freed nodes finish. Those are not failed checks.

Import, if class names are new:

```
godot --headless --path . --import --quit
```

## Milestone 1 — prototype

Portrait project, drag aim, boulder, timber keep, impact damage, physical collapse, reset, victory, shake, particles, short slow motion.

On a display, a shot around 40 degrees and 83 percent power followed the preview and brought the keep down. The HUD said the keep had fallen.

## Milestone 2 — builder

Grid placement, rotate, remove, undo, redo, wood stone and metal, the structural pieces from the brief, budget 100, save and load under `user://siege/designs/`, validation that blocks overlap and unsupported cores and still allows a connected odd shape.

Seen on a display: the builder opened on Homestead at 73 / 100, with the piece buttons and the grid. Save and Test were not clicked in that pass. The save round-trip and the layout checks ran headless.

## Milestone 3 — weapons, shields, clock

Three weapon resources, perk resources, shield field, initiative clock, separate attack and defence arenas, combat HUD, loadout budget 12 kept apart from the build budget.

Seen on a display: Timber Outpost loaded with both cores at 100 percent, the piercing bolt ready at 4 seconds, the catapult at the lower left, and the enemy keep on the right. Pause and Menu were visible and did not cover the tower. A shot was not fired in that look. Shield math, reload order, and the two-keep spawn ran headless. A live shield flash and a live explosion were not watched.

## Milestone 4 — single player

Five encounters, unlocks in order, Easy / Normal / Hard aim and weapon choice, menus for the main game, level select, builder, loadout, settings, results, and a multiplayer page that does not matchmake. Profile saves difficulty, loadout, unlocks, and settings.

Seen on a display: main menu, the difficulty screen, and level select. Timber Outpost was open. The other four were locked. Starting that level opened the battle above. A full level was not cleared on the display, so the victory screen and the next unlock were not watched. The AI aim difference and the legal enemy loadouts ran headless.

## Milestone 5 — mobile limits

Debris cap, sleeping pieces, frozen stacks until a real hit, simple shapes, generated noises, camera shake and slow motion already in the prototype. Debris is now created after the physics step, because spawning it inside a collision callback made Godot reject the shape.

Sounds were not heard. The machine has no sound card and Godot used the dummy driver. Frame time on a phone was not measured.

## Milestone 6 — match interface

Actions carry side, weapon, angle, and power. The local battle records them and writes a log. A local two-sided mode is on the multiplayer screen. No socket is opened. Authority rules are in `docs/MULTIPLAYER.md`.

The accept and reject rules ran headless. The local-duel button was not clicked on the display.

## How to play

Open the project in Godot 4.7.2 and press Play.

- Quick Battle — drag back from the catapult and release. Reset rebuilds the timber keep.
- Single Player — pick a difficulty, then Timber Outpost. Later keeps unlock after a win.
- Tower Builder or Sandbox — edit, save, and test.
- Loadout — weapons and one perk, budget 12.
- Multiplayer — local test only. It does not find an opponent online.
