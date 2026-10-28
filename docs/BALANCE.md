# Balance

Numbers live in `data/`. Change the resources, not the scripts, unless a rule itself is wrong.

## Two budgets

They are separate.

- Structure budget: 100. Pays for blocks, beams, the core, and shields. It does not pay for weapons.
- Loadout budget: 12. Pays for the weapons you bring and one perk. It does not pay for bricks.

A heavy boulder costs 6. An explosive shot costs 4. A piercing bolt costs 3. Perks cost 2 or 3. Boulder plus bolt plus Marksman is 11. All three weapons plus a perk does not fit.

## Materials

Wood is cheap and light, and explosions hurt it. Stone is heavy and soaks up impacts. Metal costs the most and protects connections. The core uses its own material and can still break.

Cost is the piece base cost times the material scale, rounded, with a floor of 1. Shields cost 16. The core costs 10. Those two ignore the material scale.

## Weapons

| Weapon | Mass | Reload | Launch | Role |
| --- | --- | --- | --- | --- |
| Heavy Boulder | 8 | 9s | 1280 | Knocks supports loose. A full shield can swallow one hit. |
| Explosive Shot | 2.6 | 6.5s | 1400 | Blasts a packed cluster. Spread-out towers waste the radius. |
| Piercing Bolt | 0.55 | 4s | 1680 | Fast and accurate. Punches light pieces. Stops on heavy stone, metal, foundations, and the core. |

Reload times are the first moment that weapon may fire. The clock pauses during aiming. Single player does not limit how long you may aim unless Settings turns on the 20 second limit.

Explosion impulse and damage fall off with distance. Material explosion resistance reduces the hurt.

## Shields

Capacity 100, radius 260, recharge 6 per virtual second. Recharge happens when the battle clock jumps, not while you aim and not while rubble is settling.

A hit spends `shield_drain` (55 boulder, 40 explosive, 14 bolt), limited by the energy left. If a boulder still has most of its drain paid, the hit is mostly absorbed. If the shield is nearly empty, the same boulder only softens. Bolts are barely slowed and still pass. A charged shield detonates an explosive early. Nothing is immune.

## Perks

One at a time. Each help has a cost.

- Rapid Reload: reload ×0.80, launch speed ×0.95. Cost 3.
- Siege Master: damage ×1.18, reload ×1.12. Cost 3.
- Reinforced Foundations: grounded pieces and anchors gain durability ×1.40 and mass ×1.15. Cost 2.
- Shield Specialist: capacity ×1.35, recharge ×1.20, radius ×0.90. Cost 2.
- Marksman: aim error ×0.55, damage ×0.92. Cost 2.
- Lightweight Engineering: wood mass ×0.75, wood durability ×0.88. Cost 2.

## Building rules

Grid is 8 by 12 cells of 64 px. No overlap. Pieces must sit inside the grid. Saving and fighting require exactly one core, and every piece must connect to the ground by edge contact, not by corners alone. An odd shape is legal if that path exists. The editor lets you leave a tower unfinished. Test and Save do not.

The same rules apply to the five campaign keeps.

## Battle result

Battle limit is 90 virtual seconds. Resolve each shot until the arena is quiet or 7 seconds pass. On timeout, score is core health ratio × 0.7 plus the share of pieces still intact × 0.3. If the scores differ by less than 0.02, it is a tie.

## Difficulty

Easy prefers the bolt, samples coarsely, and scatters the shot by about 12 degrees. It aims at the middle of the tower.

Normal scatters by about 6 degrees and prefers explosives when the keep is mostly wood.

Hard scatters by about 2 degrees, aims at the core and weak joints, and picks a bolt when the core looks exposed.

Marksman scales that scatter. Health is not increased.
