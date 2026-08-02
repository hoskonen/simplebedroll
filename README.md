# Simple Bedroll

Simple Bedroll is a lightweight camping mod for Kingdom Come: Deliverance II.
Its central goal is to let Henry deploy one modest bedroll outdoors, sleep with
the native sleeping system, and pack it again without creating a large or
feature-heavy campsite.

The project is currently an early, command-driven prototype. The core technical
proof of concept works: a visible makeshift bed can be spawned in front of the
player, the native **Sleep** interaction appears, Henry can sleep there, and the
complete deployment can be removed afterward.

## Design goals

- Remain small, focused, and believable.
- Deploy only the equipment the player asks for.
- Use native game interactions wherever possible.
- Allow only one active bedroll at a time.
- Keep visual props separate from functional game entities.
- Avoid spawning a tent or a large decorated camping area by default.
- Make optional future features modular instead of turning the bedroll into a
  mandatory campsite system.

## Current status

Verified working in game:

- Spawning a visible vanilla makeshift bed model in front of Henry.
- Spawning a custom invisible bed entity with low sleep quality.
- Spawning the native `BedTrigger` interaction.
- Linking the trigger and bed in both directions.
- Showing the native **Sleep** prompt.
- Sleeping through the native sleeping system.
- Tracking the visual prop, functional bed, and trigger during the active Lua
  session.
- Removing all three components cleanly.
- Finding and removing orphaned development entities after a script reload.
- Keeping the loose development files and `Data/simplebedroll.pak` synchronized.

Not implemented or not yet verified:

- Player-facing deployment without a console command.
- Packing through an in-world interaction or inventory action.
- Inventory requirements or consumption of a bedroll item.
- Terrain height and slope alignment.
- Obstruction and unsuitable-location checks.
- Save/load reconstruction and trigger relinking.
- A stable public command layer such as `sbr_spawn` and `sbr_help`.
- Release packaging that excludes research-only files.

## Prototype installation

Place the complete `simplebedroll` directory under the game's `Mods` directory:

```text
KingdomComeDeliverance2/Mods/simplebedroll/
```

The folder must contain `mod.manifest` and `Data/simplebedroll.pak`. The current
prototype has no required LuaUtils or KCDUtils dependency. Developer-console
access is required until a player-facing deployment method is implemented.

## Development commands

The current prototype is controlled through the KCD2 Lua console.

Spawn the complete visible and functional test bed:

```lua
#SimpleBedRoll.SpawnFunctionalTestBed()
```

Report whether the visual prop, functional bed, and trigger still exist:

```lua
#SimpleBedRoll.FunctionalTestBedStatus()
```

Remove the complete test deployment:

```lua
#SimpleBedRoll.RemoveFunctionalTestBed()
```

There is also a lower-level prefab research tool. It is not part of the normal
bed deployment path:

```lua
#SimpleBedRoll.SpawnTestPrefab("prefab-guid")
#SimpleBedRoll.TestStatus()
#SimpleBedRoll.RemoveTestPrefab()
```

These names are temporary development APIs. A later developer-tools module is
planned with short commands such as:

- `sbr_help()` -- list available commands and examples in game.
- `sbr_spawn()` -- deploy the current test bedroll.
- `sbr_remove()` -- remove the deployed bedroll.
- `sbr_status()` -- summarize tracked deployment state.
- `sbr_probe_entities(radius)` -- inspect nearby entity names, classes,
  transforms, models, and links.

## How the prototype works

The deployed bedroll is composed of three entities with different jobs:

1. **Visual prop** -- a custom `SimpleBedRoll_VisualAnchor` entity renders the
   vanilla makeshift-bed CGF.
2. **Functional bed** -- an invisible `SimpleBedRoll_BedEntity` supplies the bed
   smart-object data, sleep quality, and native use request.
3. **Interaction trigger** -- a native `BedTrigger` displays the Sleep prompt and
   points to the functional bed.

The trigger links to the bed with an unnamed link. The bed links back to the
trigger as `mTrigger`. The visual entity deliberately has no responsibility for
sleeping; this keeps rendering and game functionality independently testable.

The current visual model is:

```text
Objects/manmade/common_furniture/beds/low/bed_makeshift_a.cgf
```

It can be changed in `Data/Scripts/SimpleBedRoll/Config.lua`.

## Visual-model investigation

The first visual experiment used this prefab GUID from an older copy of The
Camping Mod research:

```text
fb04fa50-3ee6-4ba5-ab51-df1862315de2
```

`Game.SpawnPrefab` accepted the request and returned `nil`, but no visible
prefab child appeared. The sleeping bed and trigger still worked, which proved
that the visibility failure was isolated from the functional bed.

A review of the current Camping Mod source revealed that its active bed path no
longer uses that prefab. It creates a normal prop entity with a direct CGF model,
enables unlimited view distance and shadows, and keeps a separate invisible bed
for functionality. Simple Bedroll now follows that smaller and proven pattern.

The direct-CGF iteration was verified in `kcd.log` on 2026-08-02:

```text
[SimpleBedRoll/FunctionalTest] visual prop spawned ... modelPath=Objects/manmade/common_furniture/beds/low/bed_makeshift_a.cgf
[SimpleBedRoll/FunctionalTest] linked trigger -> bed
[SimpleBedRoll/FunctionalTest] linked bed mTrigger -> trigger
[SimpleBedRoll/FunctionalTest] functional test bed ready
```

The same test confirmed that status reporting found all three entities and that
removal deleted the trigger, functional bed, and visual prop.

## Project layout

```text
simplebedroll/
├── mod.manifest
├── README.md
└── Data/
    ├── simplebedroll.pak
    ├── Entities/
    │   ├── SimpleBedRoll_BedEntity.ent
    │   └── SimpleBedRoll_VisualAnchor.ent
    ├── Scripts/
    │   ├── Entities/
    │   │   ├── SimpleBedRoll_BedEntity.lua
    │   │   └── SimpleBedRoll_VisualAnchor.lua
    │   ├── SimpleBedRoll/
    │   │   ├── Config.lua
    │   │   └── SimpleBedRoll.lua
    │   └── Systems/
    │       └── simplebedroll_init.lua
    └── Research/
        └── campingmod/
```

Current responsibilities:

- `simplebedroll_init.lua` loads the main module and binds gameplay startup.
- `Config.lua` stores data-only settings such as the visual model path.
- `SimpleBedRoll.lua` currently contains placement, spawning, linking, cleanup,
  status reporting, and prefab experiments.
- `SimpleBedRoll_BedEntity.lua` implements the invisible native sleeping object.
- `SimpleBedRoll_VisualAnchor.lua` implements the visible persistent prop.
- `Research/campingmod` contains reference material and is not original Simple
  Bedroll runtime code.

## Planned restructuring

After the visible-model prototype is merged, the main script should be divided
into modules with one clear responsibility each. A likely structure is:

```text
Scripts/SimpleBedRoll/
├── Config.lua
├── SimpleBedRoll.lua       # public API and coordination
├── Deployment.lua          # spawn, link, remove, recover
├── Placement.lua           # position, terrain, rotation, obstruction checks
├── Inventory.lua           # item requirements, consume and return operations
├── Persistence.lua         # save/load recovery and relinking
└── DevTools.lua            # help, status, probes, experimental commands
```

The exact split should follow actual responsibilities as they are implemented;
empty abstraction layers should not be added merely to match this outline.

## Roadmap

### 1. Developer tooling

- Add `sbr_help()` so commands can be discovered in game.
- Add stable short wrappers around the current test functions.
- Add `sbr_probe_entities(radius)` for nearby entity research.
- Improve status output with transforms, model paths, and entity links.

### 2. Placement

- Query terrain height at the requested deployment point.
- Align the visual prop to the terrain normal.
- Derive the functional bed and trigger transform from the final visual prop.
- Rotate offsets with the bed instead of applying them in world axes.
- Reject steep, obstructed, indoor, or otherwise unsuitable locations.

### 3. Lifecycle and persistence

- Represent the visual prop, bed, and trigger as one logical deployment.
- Recover entity references after load.
- Recreate or relink missing triggers safely.
- Remove incomplete or duplicated deployments.
- Verify sleeping, saving, loading, and packing in multiple world locations.

### 4. Player-facing deployment

Candidates to investigate:

- An inventory Use action.
- Dropping a bedroll item into the world.
- A contextual in-world interaction.
- A small configurable key command as a fallback.

The preferred option should feel native while keeping installation and runtime
requirements light.

### 5. Inventory-aware optional equipment

Deployment may later react to equipment Henry actually carries. For example, if
the player has suitable firewood, Simple Bedroll could optionally place one
small open cooking fire beside the bedroll. This should remain an explicit,
compact addition rather than expanding automatically into a large campsite.

Other inventory-backed ideas can be evaluated under the same rule: equipment
should be modest, believable, independently removable, and never required for
the basic sleeping feature.

## LuaUtils investigation

[LuaUtils](https://github.com/JerryYOJ/libKCD2/tree/master/Projects/LuaUtils)
is a native KCSE plugin that extends the game's item and equipment Lua APIs. It
could optionally improve exact inventory-instance tracking, listener-aware stack
changes, and moving an item between inventories.

It does not currently provide direct item-used or item-dropped callbacks, so it
does not by itself solve how deployment should be triggered. Because it adds a
native dependency, the initial goal is to keep Simple Bedroll functional without
it and consider LuaUtils as an optional enhancement only if its advantages become
important.

## Building the development PAK

The game loads the packaged files from `Data/simplebedroll.pak`. During current
development, update it from the `Data` directory with:

```powershell
7z u -tzip -mx=9 simplebedroll.pak Entities Scripts Research
```

Before a public release, create a fresh archive so older research entries cannot
remain inside it. From the `Data` directory:

```powershell
7z a -tzip -mx=9 simplebedroll-runtime.pak Entities Scripts
```

Inspect that new archive and install it as `simplebedroll.pak` only after its
contents have been verified.

After adding or changing an `.ent` entity definition, restart the game instead
of relying only on Lua script reloads.

## Testing checklist

For each placement iteration:

1. Spawn the bedroll while facing several directions.
2. Confirm the model is visible and rests on the ground.
3. Confirm the Sleep prompt appears at the model.
4. Sleep and inspect Henry's position and orientation.
5. Check `FunctionalTestBedStatus()`.
6. Remove the deployment.
7. Confirm no visual prop, bed, or trigger remains.
8. Repeat after a script reload and eventually after save/load.

Useful log prefixes:

```text
[SimpleBedRoll]
[SimpleBedRoll/FunctionalTest]
[SimpleBedRoll/BedEntity]
```

## References and credits

- [The Camping Mod](https://gitlab.com/kcd2-mods/the-camping-mod) provided useful
  research into KCD2 bed entities, triggers, visual props, placement, and cleanup.
- [libKCD2 LuaUtils](https://github.com/JerryYOJ/libKCD2/tree/master/Projects/LuaUtils)
  is being evaluated for optional inventory-management capabilities.

Simple Bedroll is an independent lightweight project and does not aim to
reproduce The Camping Mod's full campsite system.
