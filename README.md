# Simple Bedroll

## Goal

Allow the player to deploy a modest bedroll outdoors, sleep using the
native sleeping system, and pack the bedroll afterward.

## Initial scope

- One deployable bedroll
- One active bedroll at a time
- Native sleep interaction
- Safe deployment and packing
- Save/load-safe state
- No tent, fire, cooking, crafting, or campsite system

## Investigation log

### The Camping Mod

- Initialization:
- Placement:
- Spawn API:
- Sleeping object:
- Cleanup:
- Persistence:

### Vanilla assets

| Candidate | Identifier | Visual asset | Usable bed | Notes |
|---|---|---|---|---|

## Open questions

- Can a complete vanilla sleeping prefab be spawned dynamically?
- Does it remain interactive after save/load?
- Can the sleep and packing interactions coexist?
- Is an inventory Use action available without GFX changes?