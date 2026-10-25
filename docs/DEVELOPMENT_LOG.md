# Development log

Engine: Godot **4.7.2.stable.official.ed1daf0bf**, downloaded from the official 4.7.2 Linux x86_64 build and run from the home directory. It is not committed.

Headless test command:

```
godot --headless --path . res://tests/test_runner.tscn
```

## Milestone 1 — playable prototype

Shipped:

- Portrait project, 1080×1920, canvas stretch, fixed 60 Hz physics, interpolation, CCD on projectiles.
- Drag aim for mouse and touch. Power and angle come from the pull. The preview uses the same semi-implicit step as the rigid body, and a headless check matched it to 0 px over 30 steps.
- One heavy boulder, a timber-and-stone keep, impact damage with a speed threshold and one application per contact, support loss that wakes pieces so the collapse is physical.
- Reset, core destruction victory, camera shake, burst particles, a short slow-motion on a big collapse.
- Main menu → Quick Battle.

Verified on 2026-10-25:

- Headless suite: **ALL TESTS PASSED** (contact latch, resting energy, reload order, scheduler, core outcome, tie, layout overlap, trajectory match, projectile blocked, resting stack, single hit, explosion impulse, core destruction ends the match).
- On a display: a dragged shot at about 40° and 83% power followed the preview, broke the keep, and showed “The Keep has fallen.” Audio could not be checked; the machine has no sound card and Godot fell back to the dummy driver.

Known limits: quick battle only, one weapon in that scene, no builder, no campaign, no shields yet. The other two weapons exist as data and the projectile script already branches for explosive and piercing shots.
