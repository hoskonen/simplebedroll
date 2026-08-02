-- SimpleBedRoll user settings (Lua 5.1).
-- This table is intentionally data-only so an MCM adapter can override it later.

SimpleBedRoll_Config = {
    Placement = {
        BedDistance = 1.0,
    },

    Trigger = {
        Offset = {
            x = 0.15,
            y = -0.09,
            z = 0.35,
        },

        Scale = {
            0.29,
            0.29,
            0.29,
        },
    },

    Visual = {
        -- Lightweight vanilla makeshift bed used by the Camping Mod's basic tier.
        ModelPath = "Objects/manmade/common_furniture/beds/low/bed_makeshift_a.cgf",
    },
}
