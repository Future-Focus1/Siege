# SIEGE

Portrait physics siege game for Godot 4.7.2.

Open the project and press Play. From the main menu:

- Quick Battle fires a heavy boulder at a timber keep. Drag backward from the catapult, then release.
- Single Player is five hand-built keeps. Easy, Normal, and Hard change the defender's aim, not its health.
- Tower Builder and Sandbox edit a keep and let you shoot it.
- Multiplayer does not search for players. The local test runs both sides on this machine.

Headless checks:

```
godot --headless --path . res://tests/test_runner.tscn
```

Design notes are in `docs/`.
