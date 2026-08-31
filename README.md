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
- Spawning the native `BedTrigger` baseline.
- Linking the native trigger and bed in both directions.
- Showing the native **Sleep** prompt.
- Sleeping through the native sleeping system.
- Attaching the bedroll behavior adapter to one native trigger instance.
- Showing the held **Pick up** action and using it to pack the deployment.
- Tracking the visual prop, functional bed, and trigger during the active Lua
  session.
- Removing all three components cleanly.
- Finding and removing orphaned development entities after a script reload.

Not implemented or not yet verified:

- Player-facing deployment without a console command.
- Inventory requirements or consumption of a bedroll item.
- Terrain height and slope alignment.
- Obstruction and unsuitable-location checks.
- Save/load reconstruction and trigger relinking.
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

The current prototype is controlled through short commands in the KCD2 Lua
console:

```lua
#sbr_help()
#sbr_give_bedroll()
#sbr_spawn()
#sbr_status()
#sbr_remove()
#sbr_probe_entities()
#sbr_probe_entities(5)
```

`sbr_help()` prints the complete command list in game. The entity probe scans a
sphere around Henry, defaults to a 2-metre radius, and is limited to 20 metres to
avoid accidental heavy queries. Results are ordered by distance and include each
entity's class, name, ID, position, angles, model property, and links.
`sbr_give_bedroll(quantity, health)` adds the custom bedroll item class to
Henry's inventory; quantity defaults to 1 and health defaults to 1.0.

The original long-form deployment functions remain available for research and
compatibility:

```lua
#SimpleBedRoll.SpawnFunctionalTestBed()
#SimpleBedRoll.FunctionalTestBedStatus()
#SimpleBedRoll.RemoveFunctionalTestBed()
```

When the custom Simple Bedroll misc item is dropped into the world, the
prototype adds a held **Make camp** action beside the normal Pick up action. This
milestone only logs the world entity ID, item ID, class/name, and position; it
does not deploy the bed.
The interaction action is `simplebedroll_make_camp`, exposed as a writable
General keybind named `simplebedroll_ui_keybind`. The default keyboard binding is
`B`; controller binding follows the secondary-interaction face button used by
Take or Eat, `Y` / Triangle.

There is also a lower-level prefab research tool. It is not part of the normal
bed deployment path:

```lua
#SimpleBedRoll.SpawnTestPrefab("prefab-guid")
#SimpleBedRoll.TestStatus()
#SimpleBedRoll.RemoveTestPrefab()
```

## How the prototype works

The deployed bedroll is composed of three entities with different jobs:

1. **Visual prop** -- a custom `SimpleBedRoll_VisualAnchor` entity renders the
   vanilla makeshift-bed CGF.
2. **Functional bed** -- an invisible `SimpleBedRoll_BedEntity` supplies the bed
   smart-object data, sleep quality, and native use request.
3. **Interaction trigger** -- a native `BedTrigger` displays **Sleep**, exposes a
   held **Pick up** action, and points to the functional bed. Simple Bedroll
   attaches its pack handler only to this spawned trigger instance.

The trigger links to the bed with an unnamed link. The bed links back to the
trigger as `mTrigger`. Click behavior still runs through vanilla `BedTrigger`,
including its sleep eligibility checks. Holding **Pick up** calls the deployment
cleanup and removes the trigger, functional bed, and visual prop together. The
temporary label uses the vanilla `@ui_pickup_item` localization key; a later text
table can rename it to **Pack bedroll**.

The visual entity deliberately has no responsibility for sleeping; this keeps
rendering and game functionality independently testable. The behavior override
is scoped to the deployed trigger instance, so it does not modify other native
or vanilla beds.

An earlier iteration registered a new `.ent` class that copied the Lua
`BedTrigger` table. The entity spawned and linked without a Lua error, but the
game exposed neither Sleep nor Pick up. Native trigger interaction registration
is therefore treated as engine-owned state that Lua table composition alone does
not inherit. The current design keeps the registered native entity class and
changes only the one instance's `ReportUse` handler.

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
    │   │   ├── BedTrigger.lua
    │   │   ├── Config.lua
    │   │   ├── Deployment.lua
    │   │   ├── DevTools.lua
    │   │   ├── Placement.lua
    │   │   └── SimpleBedRoll.lua
    │   └── Systems/
    │       └── simplebedroll_init.lua
    └── Research/
        └── campingmod/
```

Current responsibilities:

- `simplebedroll_init.lua` loads the main module and binds gameplay startup.
- `Config.lua` stores data-only placement, trigger, and visual settings.
- `SimpleBedRoll.lua` is the small composition root: it creates the public table,
  loads the modules in dependency order, and handles gameplay startup.
- `Placement.lua` finds Henry and calculates the current bed position and heading.
- `Deployment.lua` owns functional spawning, entity linking, status, recovery,
  and cleanup for a complete bedroll deployment.
- `DevTools.lua` owns command help, stable short wrappers, nearby-entity probes,
  and isolated prefab experiments.
- `SimpleBedRoll_BedEntity.lua` implements the invisible native sleeping object.
- `BedTrigger.lua` attaches the bedroll-only pack handler to the deployed native
  trigger while delegating Sleep back to the vanilla implementation.
- `SimpleBedRoll_VisualAnchor.lua` implements the visible persistent prop.
- `Research/campingmod` contains reference material and is not original Simple
  Bedroll runtime code.

## Module boundaries

The first behavior-preserving modular split uses this runtime structure:

```text
Scripts/SimpleBedRoll/
├── BedTrigger.lua          # native trigger instance behavior
├── Config.lua
├── SimpleBedRoll.lua       # public API and coordination
├── Deployment.lua          # spawn, link, remove, recover
├── Placement.lua           # position, terrain, rotation, obstruction checks
└── DevTools.lua            # help, status, probes, experimental commands
```

`Inventory.lua` and `Persistence.lua` should be added later only when those
responsibilities contain real behavior. Empty abstraction layers should not be
created merely to match a planned directory tree.

## Roadmap

### 1. Developer tooling

- Verify `sbr_help()` and the stable short wrappers in game.
- Exercise `sbr_probe_entities(radius)` in forests, settlements, interiors, near
  water, and around existing beds to learn which entity data is dependable.
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

### 5. Survival crafting and inventory policy

A promising direction is to treat the camp as a temporary survival craft rather
than a permanent convenience item. Deployment could require believable materials
such as branches and fabric. Packing after use could return reusable parts while
partly consuming or damaging expendable materials, making preparation and supply
management part of every journey.

This should be implemented as a separate inventory policy around deployment and
packing. The trigger and sleeping entities should not contain item-manager logic.
That boundary keeps recipe experiments, vanilla item GUIDs, custom items, and
optional LuaUtils support replaceable without destabilizing native sleep.

### 6. Inventory-aware optional equipment

Deployment may later react to equipment Henry actually carries. For example, if
the player has suitable firewood, Simple Bedroll could optionally place one
small open cooking fire beside the bedroll. This should remain an explicit,
compact addition rather than expanding automatically into a large campsite.

Other inventory-backed ideas can be evaluated under the same rule: equipment
should be modest, believable, and independently removable. Whether the bedroll's
basic recipe is mandatory should be decided after reliable inventory checks and
transaction-safe consume/return behavior have been prototyped.

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

The game loads the packaged files from `Data/simplebedroll.pak`. Development
builds are created with **KCD2 PAK Builder** using its single-click build action.
Codex edits and verifies the loose source files but does not rebuild the PAK;
run the builder after reviewing a source change and before testing it in game.

For a public build, include only runtime content from `Data/Entities` and
`Data/Scripts`. Exclude `Data/Research` and ensure the output PAK is not included
inside itself.

After adding or changing an `.ent` entity definition, restart the game instead
of relying only on Lua script reloads.

## Testing checklist

For each placement iteration:

1. Spawn the bedroll while facing several directions.
2. Confirm the model is visible and rests on the ground.
3. Confirm the Sleep prompt appears at the model.
4. Confirm a held **Pick up** action appears only on the custom bedroll.
5. Sleep and inspect Henry's position and orientation.
6. Check `FunctionalTestBedStatus()`.
7. Hold **Pick up** and confirm the complete deployment disappears.
8. Confirm no visual prop, bed, or trigger remains.
9. Repeat after a script reload and eventually after save/load.

Useful log prefixes:

```text
[SimpleBedRoll]
[SimpleBedRoll/FunctionalTest]
[SimpleBedRoll/BedEntity]
[SimpleBedRoll/BedTrigger]
[SimpleBedRoll/Help]
[SimpleBedRoll/EntityProbe]
```

## References and credits

- [The Camping Mod](https://gitlab.com/kcd2-mods/the-camping-mod) provided useful
  research into KCD2 bed entities, triggers, visual props, placement, and cleanup.
- [libKCD2 LuaUtils](https://github.com/JerryYOJ/libKCD2/tree/master/Projects/LuaUtils)
  is being evaluated for optional inventory-management capabilities.

Simple Bedroll is an independent lightweight project and does not aim to
reproduce The Camping Mod's full campsite system.
