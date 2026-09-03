-- SimpleBedRoll user settings (Lua 5.1).
-- This table is intentionally data-only so an MCM adapter can override it later.

SimpleBedRoll_Config = {
    Placement = {
        BedDistance = 1.0,
    },

    Trigger = {
        -- Uses a vanilla localization key until the mod has its own text table.
        PackHint = "@ui_pickup_item",

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

    Prefabs = {
        CandleLit = {
            Path = "Data/Prefabs/simplebedroll/SBRCandleFullLitv1.xml",
            Guid = "da23c351-21cd-4430-8dc9-fc8c459086b7",
        },
    },

    CampProps = {
        Candle = {
            Name = "SimpleBedRoll_TestCampCandle",
            ModelPath = "Objects/manmade/common_illumination/candle_a.cgf",

            Offset = {
                right = 1.00,
                forward = 0.15,
                z = 0.0,
            },

            GroundOffset = 0.02,

            Light = {
                Name = "SimpleBedRoll_TestCampCandleLight",

                Offset = {
                    right = 0.0,
                    forward = 0.0,
                    z = 0.12,
                },

                Radius = 2.5,
                AttenuationBulbSize = 0.1,

                Color = {
                    x = 0.462077,
                    y = 0.158961,
                    z = 0.0561285,
                    DiffuseMultiplier = 0.01,
                    SpecularMultiplier = 1.5,
                    VolumetricMultiplier = 4,
                    GIMultiplier = 1,
                },

                Style = {
                    LightAnimType = "LoopRandomSeed",
                    AnimationSpeed = 0.5,
                    AnimationPhase = 9,
                    LightStyle = 20,
                    Flare = "",
                    LightAnimation = "",
                },

                Projector = {
                    Texture = "",
                    SpotShadow = true,
                    SpotShadowBack = true,
                    SpotShadowBottom = true,
                    SpotShadowLeft = true,
                    SpotShadowRight = true,
                    SpotShadowTop = false,
                    Fov = 90,
                    NearPlane = 0,
                },

                Shadows = {
                    CastShadows = 3,
                },

                Options = {
                    VerticalClipDistanceDownward = 1.5,
                    VerticalClipDistanceUpward = 3,
                    AffectsThisAreaOnly = true,
                    GIMode = "None",
                },
            },

            Flame = {
                Name = "SimpleBedRoll_TestCampCandleFlame",
                Effect = "WH_Particels.fires.candle",

                Offset = {
                    right = 0.003486633,
                    forward = 0.001457214,
                    z = 0.15,
                },

                Rotation = {
                    x = 0.7071068,
                    y = 0.7071068,
                    z = 0,
                    w = 0,
                },
            },
        },
    },
}
