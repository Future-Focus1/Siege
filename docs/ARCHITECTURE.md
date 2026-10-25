# Architecture

Godot 4.7, GDScript, 2D physics. No third-party plugins.

## Layout

- `data/` — materials, pieces, weapons, perks, encounters, and the balance resource
- `scenes/` — thin scenes: menu, quick battle, campaign battle, workshop, piece, projectile
- `scripts/data` — resource types and the catalog
- `scripts/physics` — pieces, projectiles, impact, explosions, shields, debris
- `scripts/combat` — arena, catapult, camera, battle, scheduler, perks
- `scripts/builder` — placement, rules, workshop
- `scripts/campaign` — the five hand-built towers
- `scripts/ai` — shot choice
- `scripts/match` — actions, state, outcome
- `scripts/save` — versioned files under `user://siege/`
- `tests/` — one headless scene that runs the checks

`Game` is the only autoload. It holds the profile and changes scenes.

## Physics

Gravity is 1250. The solver steps at 60 Hz with interpolation on. Projectiles use shape CCD. Pieces start frozen. A real hit wakes the piece that was struck, and neighbors wake when the support path to the ground is gone. Foundations stay planted until a heavy hit or until they are badly damaged.

Damage uses approach speed from the previous physics frame. Below the speed and energy floors, the hit does nothing, so a resting stack does not grind itself apart. Each contact is counted once until the bodies separate.

Debris is capped. New bits are spawned on the next idle frame, not inside the physics callback. Old bits sleep, then disappear.

## Adding a weapon later

Add a `WeaponData` resource. The projectile already branches on `heavy`, `explosive`, and `pierce`. A new behaviour needs one more branch in the projectile and a line in the shield reaction. Fire Pot, Scattershot, Chain Shot, Massive Siege Stone, Shield Disruptor, and Multi-Projectile Volley are not implemented.

## Adding a defence later

The shield generator is the only defence. The arena attaches a `ShieldField` when it spawns that piece. Another defence would be another child created at the same point. The core is never invulnerable.

## Saves

Version 1. A tower file stores the placement lines and is rejected if the rules fail or the version is wrong. The profile stores difficulty, loadout, unlocks, best results, the chosen design, and settings. Match logs are separate JSON files. Clients are not trusted with damage or budgets; see `docs/MULTIPLAYER.md`.
