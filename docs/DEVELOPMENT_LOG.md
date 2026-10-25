# Development log

Engine: Godot **4.7.2.stable.official.ed1daf0bf**, Linux x86_64, run from the home directory. It is not committed.

Headless checks:

```
godot --headless --path . res://tests/test_runner.tscn
```

Last verbose run on 2026-10-25: **ALL TESTS PASSED**, with no camera warning and no leaked resources on exit.

Passed: contact counted once, resting energy is zero, reload order, scheduler tie break, core victory, timeout tie, no overlap on the timber keep, all five campaign layouts and their loadouts are legal, overlap is rejected, a floating core is rejected, save round-trip restores Homestead and a bad version is rejected, an over-budget loadout is rejected, match actions reject an unknown weapon and power above 1, a shield spends 55 energy and weakens a boulder, easy and hard aim rolls differ, rapid reload is faster than siege master and siege master hits harder, trajectory error 0 px, a bolt stops on a block, a resting stack loses no durability, one hit raises one damage event, an explosion pushes a near body and not a far one, breaking the core ends the quick battle, a campaign scene spawns two separated keeps and does not end on the first frames.

The earlier camera warning and the leftover physics resources were real defects, and both are fixed. See the display notes below.

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

Seen on a display: Timber Outpost loaded with both cores at 100 percent, the piercing bolt ready at 4 seconds, the catapult at the lower left, and the enemy keep on the right. Pause and Menu were visible and did not cover the tower. A later pass fired the bolt, an explosive, and a shot into a shield. Those watches are in the section below. Shield math and reload order also ran headless.

## Milestone 4 — single player

Five encounters, unlocks in order, Easy / Normal / Hard aim and weapon choice, menus for the main game, level select, builder, loadout, settings, results, and a multiplayer page that does not matchmake. Profile saves difficulty, loadout, unlocks, and settings.

Seen on a display: main menu, the difficulty screen, and level select. Timber Outpost was open. The other four were locked. Starting that level opened the battle above. A later pass cleared it on Normal. The victory screen and the Stone Gate unlock are in the section below. The AI aim difference and the legal enemy loadouts also ran headless.

## Milestone 5 — mobile limits

Debris cap, sleeping pieces, frozen stacks until a real hit, simple shapes, generated noises, camera shake and slow motion already in the prototype. Debris is now created after the physics step, because spawning it inside a collision callback made Godot reject the shape.

Sounds were not heard. The machine has no sound card and Godot used the dummy driver. Frame time on a phone was not measured.

## Milestone 6 — match interface

Actions carry side, weapon, angle, and power. The local battle records them and writes a log. A local two-sided mode is on the multiplayer screen. No socket is opened. Authority rules are in `docs/MULTIPLAYER.md`.

The accept and reject rules ran headless. The local-duel button was clicked on the display. What the clock and the two keeps did is in the section below.

## Watched on a display, 2026-10-25

The window was about 540×960. Godot used the dummy audio driver, so nothing here was heard. Debug numbers were turned on in Settings before the sandbox shots. The campaign buttons for Packed Granary and Shielded Keep were still locked, so those two shots used Load Design and the builder's Test button.

### Timber Outpost on Normal

Level select started with only Timber Outpost open. A piercing bolt at 48° and 28% power followed the preview into the timber keep. Pieces rotated and fell. Their keep went from 100% to 87%, then 79%. The player keep stayed at 100%. The battle HUD said Victory. The results screen then said Victory, Timber Outpost, and "A keep was broken or fell clear of its supports." Back on level select, the button read "Timber Outpost · Cleared", Stone Gate was open with its briefing, and Packed Granary, Shielded Keep, and Iron Bastion stayed locked.

An earlier attempt, with only Explosive Shot and Heavy Boulder equipped, lost in a few seconds. The defender's piercing bolt was ready at 4 seconds, before those weapons, and it broke Homestead. Both cores were intact at the start of that battle. It was a real shot, not a spawn failure.

### Explosive Shot into a packed tower

Packed Granary loaded in the builder at 100/100 and was tested from Sandbox. The status line was switched to Explosive Shot. A shot at 37° and 38% power hit the packed middle. An orange burst appeared. Blocks flew left, up, and right, and the central beam was knocked sideways. The core dropped from 100% to 91%. Blocks in the burst flashed and broke into white debris. Blocks farther out, including the grey cap stones and a block thrown clear to the left, still showed full green durability bars.

### Shield generator

Shielded Keep was loaded the same way. The generator showed two cyan rings before the shot. An Explosive Shot at 31° and 33% power met the left side of the field and burst there. The keep core stayed at 100%, so the shot did not go on into the stone. Sampling the inner ring, the bright upper part of that ring was present before the hit and gone after it. The outer ring was still drawn. An explosive spends 40 of the field's 100 capacity, and the inner arc is drawn only as far as the energy that remains.

### Local duel

The multiplayer page still says online play is later and does not search for a match.

The first local test, with a piercing bolt equipped, ended on the opening shot. The clock read "You · Piercing Bolt · clock 4s". The timber keep fell. The results screen said Victory before the defender had a turn.

A second test used only Explosive Shot, so the defender's bolt was ready first. The view opened on the shielded keep: "Defender · Piercing Bolt · clock 4s · next 6s". The bolt knocked two wood blocks off the top. They stayed on the ground. The stone keep and the cyan shield remained, and both cores stayed at 100%. The camera then moved. The clock read "You · Explosive Shot · clock 6s · next 8s", and the timber keep was still standing when it came into view. That shot brought the timber keep down, so the camera did not travel back to the damaged keep before the victory screen. Across the swap, the keep that had just been hit was still there when the camera left, and the other keep was still the one the match started with.

### The two test warnings

Camera2D became current as it entered the tree, while interpolation was still inherited and the callback was the idle tick. Godot then forced the physics tick and warned once. The battle camera now turns interpolation off and keeps the idle tick in `_init`, before it can enter the tree. The builder camera does the same before it is added.

The exit leaks were a shield, a projectile, and an arena the tests constructed and never freed, plus catalog resources those objects still referenced. The tests free those nodes, clear the catalog, and wait one process frame and one physics frame before quitting.

A verbose headless run after that printed ALL TESTS PASSED and did not print the camera warning, leaked canvas items, leftover objects, or resources still in use.

## How to play

Open the project in Godot 4.7.2 and press Play.

- Quick Battle — drag back from the catapult and release. Reset rebuilds the timber keep.
- Single Player — pick a difficulty, then Timber Outpost. Later keeps unlock after a win.
- Tower Builder or Sandbox — edit, save, and test.
- Loadout — weapons and one perk, budget 12.
- Multiplayer — local test only. It does not find an opponent online.
