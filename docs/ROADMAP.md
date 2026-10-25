# Roadmap

Shipped in this project: the portrait prototype, the builder, three weapons, shields, perks, five campaign keeps, menus, saves, and a local two-sided match that shares one action log.

## Still rough

- Phone export is not set up. The project is portrait and uses large buttons, but it has not been run on a device.
- Sounds are short generated noises. This machine has no sound card, so they have not been heard.
- The defender's aim is a scored sample of angles, not a learned player.

## Later, not started

- More weapons: Fire Pot, Scattershot, Chain Shot, Massive Siege Stone, Shield Disruptor, Multi-Projectile Volley.
- More defences besides the shield generator.
- Procedural keeps.
- A real server. See `docs/MULTIPLAYER.md`. Phase 3 is a host that accepts actions and runs the physics. Phase 4 is matchmaking, snapshots, and reconnect. None of that exists, and the menu does not pretend it does.
- No real-money shop and no power that only long playtime can buy. Unlocks open the next keep. They do not raise your budget.
