# Multiplayer boundaries

Online play is not implemented. The menu says so. The local two-sided test runs both keeps on this machine and writes the same match log a server would want. It does not open a socket.

## Who owns what

A future match is server-authoritative. The phone sends an action: who is shooting, which weapon, the angle, and the power, plus the loadout and tower that were already validated. The server checks the loadout budget, the tower rules, and that the weapon is actually ready on the shared clock. The server runs the physics, shields, damage, and the result. The phone does not get to announce that it won.

Do not lockstep the two clients' physics. Devices will not reproduce the same rubble. The server's simulation is the match. Later, the server can send snapshots of piece positions and health so a client can show the result. That snapshot path is not built.

## What is already local

`MatchAction` is the input. `MatchState.accept` rejects the wrong side, a weapon that is not in the allowed list, an angle outside 8–82 degrees, or power outside 0–1. The battle also refuses a weapon that the clock says is not ready. Accepted actions and the result are appended to `user://siege/logs/`.

Tower files are versioned. A file from a newer version, or a layout that overlaps or leaves the core hanging, will not load. That is the check a server should repeat. Do not trust a client's claim about budget, damage, or victory.

## What a backend still needs

- Accounts and a match record the server stores, not the phone.
- A queue or room list. Not built.
- The authoritative simulation, isolated from the rendering client.
- Snapshot and event messages for spectators and reconnect.
- A clock for aim time, so a live match cannot aim forever. The setting exists and defaults off for solo play.

Until those exist, there is no online multiplayer.
