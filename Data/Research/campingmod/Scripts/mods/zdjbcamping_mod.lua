-- ====================================
-- DJB_Camping.lua
-- Main camping module for KCD2
-- ====================================
Script.ReloadScript("Scripts/Entities/EntityCommon.lua")
-- ====================================
-- Module Definition
-- ====================================

DJB_Camping = {
    -- Configuration values
    Config = {
        -- Common values
        SafeRadius = 1,
        ZOffset = -0.02,  -- Default Z offset to prevent z-fighting
        
        -- Entity models
        Models = {
            -- Shared 
            CampfireWood = "Objects/manmade/task_specific_props/household/firewood/branches/branches_a.cgf",
            DryingRackAnchor = "Objects/manmade/task_specific_props/household/firewood/branches/branches_a.cgf",

            -- Basic - no camping item
            BasicCampfire = "Objects/manmade/task_specific_props/food_processing/cooking/camp_cooking_d_old.cgf",
            BasicBed = "Objects/manmade/common_furniture/beds/low/bed_makeshift_a.cgf",
            BasicTent = "Objects/manmade/structures/living/tents/tent_small_forest_b.cgf",
            BasicPan = "Objects/manmade/task_specific_props/household/cooking_eating/pans/pan_a.cgf",
            BasicSack = "Objects/manmade/common_furniture/sacks/sack_b.cgf",

            -- Standard - has camping kit gear
            Campfire = "Objects/manmade/task_specific_props/food_processing/cooking/camp_cooking_c_old.cgf",
            Bed = "Objects/manmade/common_furniture/beds/low/bed_shabby_b.cgf", -- keep this
            Tent = "Objects/manmade/structures/living/tents/tent_small_shabby_a.cgf", --keep this
            TentGypsyVariation = "Objects/manmade/structures/living/tents/StandardTentGypsy.cgf",
            Sack = "Objects/manmade/common_furniture/sacks/sack_b_interactive.cgf",
            Pan = "Objects/manmade/task_specific_props/household/cooking_eating/pans/pan_d.cgf",

            -- Fancy - has fancy wayfarer kit
            FancyTent = "Objects/manmade/structures/living/tents/tent_small_rustic_a.cgf",
            FancyTentGypsyVariation = "Objects/manmade/structures/living/tents/FancyTentGypsy.cgf",
            FancyJug = "Objects/manmade/task_specific_props/household/cooking_eating/jugs/tin_jug_01.cgf",
            FancyBed = "Objects/manmade/common_furniture/beds/low/bed_makeshift_c.cgf",
            CampfireWoodFancy = "Objects/manmade/task_specific_props/household/firewood/firewood_chips_hand.cgf", 
            FancySack = "Objects/manmade/common_furniture/chests/chest-small-a.cgf",
            FancySack2 = "Objects/manmade/common_furniture/sacks/sack_b_interactive.cgf",
            FancyPan = "Objects/manmade/task_specific_props/household/cooking_eating/spits/spit.cgf",
            FancyCampfire = "Objects/manmade/task_specific_props/food_processing/cooking/camp_cooking_d_old.cgf",

            -- Unique
            GypsyTent = "Objects/manmade/structures/living/tents/gypsycamp_tent_b.cgf",

            -- Chairs
            Chair = "Objects/manmade/common_furniture/chairs/low/chair_rustic_d.cgf",
            BasicChair = "Objects/manmade/common_furniture/chairs/low/chair_trunk_c.cgf",
            FancyChair = "Objects/manmade/common_furniture/chairs/low/chair_rustic_a.cgf"
        },
        
        -- Placement distances
        Distance = {
            Campfire = 1,
            Bed = 1.0,
            Chair = 0.5
        },
        
        -- Bed trigger offsets
        BedTrigger = {
            Offset = {x = 0.15, y = -0.09, z = 0.35},
            Scale = {0.29, 0.29, 0.29}
        },
        
        -- Chair trigger offsets
        ChairTrigger = {
            Offset = {x = 0.15, y = -0.09, z = 0.35},
            Scale = {0.29, 0.29, 0.29}
        },

        -- Cooking trigger offsets
        FoodProcessingTrigger = {
            Offset = {x = 0.2583504, y = -0.6935883, z = 0.1670952},
            Scale = {0.4, 0.4, 0.4}
        },

        -- Terrain alignment parameters
        Alignment = {
            SlopeXMultiplier = 0.68,
            SlopeYMultiplier = 1.02,
            TerrainAlignmentStrength = 0.9  -- Controls how strongly entities conform to terrain
        },
        
        -- Orientation offsets for different components (in radians)
        OrientationOffsets = {
            Basic = {
                Bed = {
                    BedAnchor = 0,
                    BedLeftAnchor = math.pi / 2 - 0.4,
                    BedRightAnchor = math.pi,
                    BedBackAnchor = math.pi / 2,
                    BedFrontAnchor = math.pi + 0.3,
                    StashAnchor = math.pi,
                },
                Fire = {
                    fireAnchor = 0,
                },
                Chair = {
                    chairAnchor = 0,
                }
            },
            Refugee = {
                Bed = {
                    BedAnchor = 0,
                    BedLeftAnchor = math.pi / 2 - 0.4,
                    BedRightAnchor = 0,
                    BedBackAnchor = math.pi / 2,
                    BedFrontAnchor = math.pi + 0.3,
                    StashAnchor = math.pi,
                },
                Fire = {
                    fireAnchor = 0,
                },
                Chair = {
                    chairAnchor = 0,
                }
            },
            Wayfarer = {
                Bed = {
                    BedAnchor = math.pi /2 - 0.4,
                    BedLeftAnchor = math.pi / 2 - 0.4,
                    BedRightAnchor = -math.pi /2,
                    BedBackAnchor = math.pi / 2,
                    BedFrontAnchor = math.pi + 0.3,
                    StashAnchor = -math.pi / 2 +0.1,
                },
                Fire = {
                    fireAnchor = 0,
                },
                Chair = {
                    chairAnchor = 0,
                }
            },
            Cuman = {
                Bed = {
                    BedAnchor = 0,
                    BedLeftAnchor = math.pi,
                    BedRightAnchor = 0,
                    BedBackAnchor = -math.pi / 2,
                    BedFrontAnchor = math.pi + 0.3,
                    StashAnchor = math.pi,
                },
                Fire = {
                    fireAnchor = 0,
                },
                Chair = {
                    chairAnchor = 0,
                }
            },
            Poacher = {
                Bed = {
                    BedAnchor = math.pi / 2 + 0.7,
                    BedLeftAnchor = math.pi / 2 - 0.4, --rack
                    BedRightAnchor = math.pi /16, -- personal items
                    BedBackAnchor = math.pi / 2, --tent
                    BedFrontAnchor = math.pi + 0.6, --washing
                    StashAnchor = math.pi,
                },
                Fire = {
                    fireAnchor = 0,
                },
                Chair = {
                    chairAnchor = 0,
                }
            },
            Gypsy = {
                Bed = {
                    BedAnchor = math.pi / 2,
                    BedLeftAnchor = math.pi /2 - 0.7, --rack
                    BedRightAnchor = math.pi + 0.7, -- personal items
                    BedBackAnchor = -math.pi /2 - 0.9, --tent
                    BedFrontAnchor = math.pi /4 - 0.7, --washing
                    StashAnchor = math.pi,
                },
                Fire = {
                    fireAnchor = 0,
                },
                Chair = {
                    chairAnchor = 0,
                }
            },
        },
        -- Relative positioning offsets for props
        AnchorOffsets = {
            Basic = {
                Bed = {
                    bedAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = -0.1  
                    },
                    bedLeftAnchor = {
                        relativeRight = -2.75,      
                        relativeForward = -0.6,  
                        z = 0.13   
                    },
                    bedRightAnchor = {
                        relativeRight = -1.3,      
                        relativeForward = 0.3,  
                        z = 0.02   
                    },
                    bedBackAnchor = {
                        relativeRight = -0.3,      
                        relativeForward = 0.3,  
                        z = -0.75   
                    },
                    bedFrontAnchor = {
                        relativeRight = 1.4,      
                        relativeForward = 0.1,  
                        z = 0.2   
                    },
                    stashAnchor = {
                        relativeRight = -1.7,      
                        relativeForward = -0.2,  
                        z = 1.2
                    },
                },
                Fire = {
                    fireAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = -0.1   
                    },
                },
                Chair = {
                    chairAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                }
            },
            Refugee = {
                Bed = {
                    bedAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0  
                    },
                    bedLeftAnchor = {
                        relativeRight = -2.4,      
                        relativeForward = -0.6,  
                        z = 0.13   
                    },
                    bedRightAnchor = {
                        relativeRight = -0.6,      
                        relativeForward = 0.45,  
                        z = 0.02   
                    },
                    bedBackAnchor = {
                        relativeRight = 0.15,      
                        relativeForward = 0.05,  
                        z = 0   
                    },
                    bedFrontAnchor = {
                        relativeRight = 1.6,      
                        relativeForward = 0.15,  
                        z = 0.2   
                    },
                    stashAnchor = {
                        relativeRight = 1,      
                        relativeForward = -0.2,  
                        z = 1.2
                    },
                },
                Fire = {
                    fireAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },

                },
                Chair = {
                    chairAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                    -- chairLeftAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairRightAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairBackAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairFrontAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                }

            },
            Wayfarer = {
                Bed = {
                    bedAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0.01 
                    },
                    bedLeftAnchor = {
                        relativeRight = -2.85,      
                        relativeForward = -1,  
                        z = 0.13   
                    },
                    bedRightAnchor = {
                        relativeRight = -1.5,      
                        relativeForward = 0.1,  
                        z = 0.02   
                    },
                    bedBackAnchor = {
                        relativeRight = -0.6,      
                        relativeForward = 1,  
                        z = -0.03   
                    },
                    bedFrontAnchor = {
                        relativeRight = 2,      
                        relativeForward = 0.1,  
                        z = 0.2   
                    },
                    stashAnchor = {
                        relativeRight = -1.5,      
                        relativeForward = -0.1,  
                        z = 0.1
                    },
                },
                Fire = {
                    fireAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                    -- fireLeftAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- fireRightAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- fireBackAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- fireFrontAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                },
                Chair = {
                    chairAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                    -- chairLeftAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairRightAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairBackAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairFrontAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                }

            },
            Cuman = {
                Bed = {
                    bedAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0.03  
                    },
                    bedLeftAnchor = {
                        relativeRight = -1.6,      
                        relativeForward = -0.6,  
                        z = 0.13   
                    },
                    bedRightAnchor = {
                        relativeRight = -1,      
                        relativeForward = -1.2,  
                        z = 0.02   
                    },
                    bedBackAnchor = {
                        relativeRight = -0.1,      
                        relativeForward = -0.55,  
                        z = 0   
                    },
                    bedFrontAnchor = {
                        relativeRight = 1.15,      
                        relativeForward = -1.1,  
                        z = 0.2   
                    },
                    stashAnchor = {
                        relativeRight = 0.9,      
                        relativeForward = -1.1,  
                        z = 0.6
                    },
                },
                Fire = {
                    fireAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                    -- fireLeftAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- fireRightAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- fireBackAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- fireFrontAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                },
                Chair = {
                    chairAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                    -- chairLeftAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairRightAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairBackAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                    -- chairFrontAnchor = {
                    --     relativeRight = 2.4,      
                    --     relativeForward = -0.4,  
                    --     z = -0.35   
                    -- },
                }

            },
            Poacher = {
                Bed = {
                    bedAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0  
                    },
                    bedLeftAnchor = { --drying
                        relativeRight = -2.5,      
                        relativeForward = -0.3,  
                        z = 0.13   
                    },
                    bedRightAnchor = {
                        relativeRight = 1.7,      
                        relativeForward = -0.17,  
                        z = 0.02   
                    },
                    bedBackAnchor = {
                        relativeRight = 0.9,      
                        relativeForward = -0.65,  
                        z = 0.2   
                    },
                    bedFrontAnchor = { --washing
                        relativeRight = 1.7,      
                        relativeForward = -1.55,  
                        z = 0.2   
                    },
                    stashAnchor = {
                        relativeRight = 1.7,      
                        relativeForward = -0.17,  
                        z = 0.02
                    },
                },
                Fire = {
                    fireAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0.02   
                    },
                },
                Chair = {
                    chairAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                }

            },
            Gypsy = {
                Bed = {
                    bedAnchor = { --bed
                        relativeRight = -0.3,      
                        relativeForward = 0,  
                        z = -0.02  
                    },
                    bedLeftAnchor = { --drying
                        relativeRight = -2.6,      
                        relativeForward = -1,  
                        z = 0.13   
                    },
                    bedRightAnchor = { --personal stuff
                        relativeRight = 1.1,      
                        relativeForward = -0.3,  
                        z = -0.2   
                    },
                    bedBackAnchor = { --tent
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0.05   
                    },
                    bedFrontAnchor = { --washing
                        relativeRight = 2,      
                        relativeForward = -1.8,  
                        z = 0.2   
                    },
                    stashAnchor = {
                        relativeRight = 1.1,      
                        relativeForward = -0.3,  
                        z = 0.1   
                    },
                },
                Fire = {
                    fireAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0.02   
                    },

                },
                Chair = {
                    chairAnchor = {
                        relativeRight = 0,      
                        relativeForward = 0,  
                        z = 0   
                    },
                }
            },
        }
    },
    
    -- State tracking
    State = {
        isFireDeployed = false,
        isBedDeployed = false,
        isChairDeployed = false,
        isRackDeployed = false,
        isStashDeployed = false,
        isWashingBasinDeployed = false,
    },
    
    -- Entity references
    Entities = {
        Anchors = {
            Bed = {
                bedAnchor = nil,
                tentAnchor = nil,
                bedLeftAnchor = nil,
                bedRightAnchor = nil,
                bedFrontAnchor = nil,
                bedBackAnchor = nil,
            },
            Fire = {
                fireAnchor = nil,
                fireLeftAnchor = nil,
                fireRightAnchor = nil,
                fireFrontAnchor = nil,
                fireBackAnchor = nil,
            },
            Chair = {
                chairAnchor = nil,
                chairLeftAnchor = nil,
                chairRightAnchor = nil,
                chairFrontAnchor = nil,
                chairBackAnchor = nil,
            }
        },

        campfire = nil,
        campFireplaceSmartObject = nil,
        campfireLight = nil,
        campfireMediumLight = nil,
        campfireParticle = nil,
        campfireAnchor = nil,
        stash = nil,
        dryingRackAnchor = nil,
        dryingSmartObject = nil,
        dryingTrigger = nil,
        foodProcessingTrigger = nil,
        kettleTrigger = nil,
        runtimePrefabFire = nil,
        runtimePrefabSteam = nil,
        runtimePrefabCauldron = nil,
        bed = nil,
        bedTrigger = nil,
        chair = nil,
        chairTrigger = nil,
        Props = {}
    },
}

-- ====================================
-- Utility Functions
-- ====================================

-- Send info text to player
function DJB_Camping:Notify(message, duration)
    duration = duration or 3
    Game.SendInfoText(message, false, nil, duration)
    self:Log(message)
end

-- Get the terrain position from a vector
function DJB_Camping:GetTerrainPosFromVec(vec)
    local rayStart = {x = vec.x, y = vec.y, z = vec.z + 50}
    local rayDir = {x = 0, y = 0, z = -700}
    local hits = Physics.RayWorldIntersection(rayStart, rayDir, 1, ent_terrain + ent_static, nil, nil, g_HitTable)
    
    if hits > 0 then
        return g_HitTable[1].pos
    else        
        return vec
    end
end

-- Get the terrain normal from a vector
function DJB_Camping:GetTerrainNormalFromVec(vec)
    local rayStart = {x = vec.x, y = vec.y, z = vec.z + 50}
    local rayDir = {x = 0, y = 0, z = -700}
    local hits = Physics.RayWorldIntersection(rayStart, rayDir, 1, ent_terrain + ent_static, nil, nil, g_HitTable)
    
    if hits > 0 then
        return g_HitTable[1].normal
    else        
        return {x = 0, y = 0, z = 1} -- Default to up vector if no terrain found
    end
end

-- Check if a position is suitable for placing camp items
function DJB_Camping:IsSuitableLocation(playerPos)
    local safeRadius = self.Config.SafeRadius
    local ents = System.GetEntitiesInSphere(playerPos, safeRadius)
    local numEntities = 0
    
    if ents and #ents > 0 then
        for i, e in pairs(ents) do
            local strClass = tostring(e.class)
            -- Skip player, torch, light, and audio entities
            if strClass ~= "Player" and strClass ~= "Torch" and strClass ~= "Light" and 
               not string.match(strClass, "Audio") and strClass ~= "PickableItem" then
                numEntities = numEntities + 1
            end
        end
    end
    
    return numEntities == 0
end

-- Calculate position in front of player
function DJB_Camping:GetPositionInFront(distance)
    local playerPos = player:GetWorldPos()
    local playerDir = player:GetDirectionVector()
    
    return {
        x = playerPos.x + (playerDir.x * distance),
        y = playerPos.y + (playerDir.y * distance),
        z = playerPos.z
    }
end

-- Helper function to determine the camping equipment to use based on inventory items available
function DJB_Camping:DetermineEquipmentVariation()
    -- Define array of possible equipment sets
    local possibleSets = {
        {
            name = "Basic", --no kit in inventory
            id = "629161b7-2933-4a05-be1c-f0a3952c6526", -- dummy id, not actually used
            bedPrefabId = "fb04fa50-3ee6-4ba5-ab51-df1862315de2", -- cloth blanket and rolled up pillow
            bedLeftPrefabId = "", -- reserved for drying rack
            bedRightPrefabId = "7b6ba9ac-e4a2-4148-a8b9-b4da4d28fd74", --candle in bowl, clothes, dagger
            bedFrontPrefabId = "", -- reserved for washing basin
            bedBackPrefabId = "0dfcf1ce-85d2-46dd-af43-97e4cc17d6f2", --forest tent with axe and sacks
            firePrefabId = "547633e0-629f-4af7-8d02-335290d9ce06", -- gneiss rocks and stick with mushroom on it
            chairPrefabId = "9a670393-a14e-4253-8675-5588acf7d57c", --stump with cloth on it
            quality = 0
        },
        {
            name = "Wayfarer",
            id = "baa3e84e-d001-4f0e-bdb7-58529794624a",
            bedPrefabId = "9821f017-e6b5-4710-9d14-6bd95fd92319", -- royal blue pillow, book, dagger
            bedLeftPrefabId = "", -- reserved for drying rack
            bedRightPrefabId = "e425692d-a55e-4e56-abbd-f1fc25538744", -- personal effects
            bedFrontPrefabId = "", -- reserved for washing basin
            bedBackPrefabId = "36aab634-a6a6-475d-a32f-c834645cdd40", -- tent
            firePrefabId = "81cf155f-0654-47bc-b7a4-ce90263ed96f", -- 
            chairPrefabId = "f3d38862-2b6e-458d-86af-b708790fc8a5",
            quality = 2
        },
        {
            name = "Refugee", --standard kit
            id = "871f3e63-6686-4e08-b963-393d549624d1",
            bedPrefabId = "55beeb2f-88f1-4f81-b854-233429bf0ab5", -- straw bed with sack and rosary beads
            bedLeftPrefabId = "", -- reserved for drying rack
            bedRightPrefabId = "f35fbaa2-a6bd-49c0-99e4-1c1b2dea1dd6", -- jug of mead, plate and bandage etc
            bedFrontPrefabId = "", -- reserved for washing basin
            bedBackPrefabId = "8fba1cd9-867a-45b1-9e50-537851852946", --shabby cloth tent with hanging lantern 
            firePrefabId = "3954e691-1817-4d63-acce-769699468f83", -- gneiss rocks and metal pan, cleaver, meat
            chairPrefabId = "015c543c-c55f-4caa-90f2-95cfac124f9e", --stump with cloth on it
            quality = 1
        },
        {
            name = "Cuman", 
            id = "a4f5ceb5-18e8-44a2-b456-8129b046d6be",
            bedPrefabId = "1600cfcd-7283-4dfd-92b0-1f5f2b028ca3", -- shaska under pillow, fur straw bed, wooden chest
            bedLeftPrefabId = "", -- reserved for drying rack
            bedRightPrefabId = "6bb4f29c-327d-4f28-a446-7f4ea3c6fed8", -- basket with mortar pestle, tools, sauerkraut
            bedFrontPrefabId = "", -- reserved for washing basin
            bedBackPrefabId = "d0020cce-c854-469f-91b5-3714cadb82de", --large square green cuman tent
            firePrefabId = "064b9851-443f-4f2a-b2e3-752fea5c1523", -- sausage maker with grill over gneiss roc 
            chairPrefabId = "1074836a-2447-495c-8c61-4d3f14c11384", --simple stool with red tassle cushion
            quality = 3
        },
        {
            name = "Poacher", 
            id = "d27b2e37-fec7-4e52-bb90-03e2db277789", 
            bedPrefabId = "b467eaeb-73d8-4846-83a1-91ee53c646dc", -- machete, leather boots, chest next to antlers
            bedLeftPrefabId = "", -- reserved for drying rack
            bedRightPrefabId = "bc056ddb-ac85-43be-87ac-41a71686fc91", -- personal effects
            bedFrontPrefabId = "", -- reserved for washing basin
            bedBackPrefabId = "99fa2278-00e7-4c03-ab62-0cbff22e1114", --
            firePrefabId = "0fed8ecd-1160-44d8-a0c3-d8ee97f00743", -- 
            chairPrefabId = "4d00434c-4286-44de-b51a-e02fa34c6614", --
            quality = 1
        },
        {
            name = "Gypsy", 
            id = "0dbd200d-a7ee-4d6e-ac28-20a6ccec2635", 
            bedPrefabId = "f3a6bf7d-5992-426f-b2cc-60558748bbf3", -- idol, rolled blanket, copper jug
            bedLeftPrefabId = "", -- reserved for drying rack
            bedRightPrefabId = "56efabb1-ab75-4f20-921d-0aea99acc15c", -- horse hoof pick, wine barrel, tool bucket
            bedFrontPrefabId = "", -- reserved for washing basin
            bedBackPrefabId = "836dcb1c-9d40-456f-bd1b-eb90647bee00", -- gypsy style fancy tent
            firePrefabId = "84dc09c8-77ab-46a8-b110-198a795b5063", -- 
            chairPrefabId = "4d00434c-4286-44de-b51a-e02fa34c6614", --
            quality = 3
        },
    }

    local bestSet = possibleSets[1] -- Default to basic set
    
    for _, set in ipairs(possibleSets) do
        if ItemUtils.HasItem(player, set.id) and set.quality > bestSet.quality then
            bestSet = set
        end
    end
    
    return bestSet
end

-- Get the appropriate model for a camp component based on the current tier
function DJB_Camping:GetModelForComponent(componentType)
    local tier = self:DetermineEquipmentVariation()
    
    -- Define tier-specific prefixes and special cases
    local prefix = ""
    if tier == "Basic" then
        prefix = "Basic"
    elseif tier == "Fancy" then
        prefix = "Fancy"
    end
    
    -- Special cases where naming doesn't follow the standard pattern
    if componentType == "Campfire" then
        if tier == "Basic" then
            return self.Config.Models.BasicCampfire
        elseif tier == "Fancy" then
            return self.Config.Models.FancyCampfire
        else
            return self.Config.Models.Campfire
        end
    elseif componentType == "CampfireWood" then
        if tier == "Fancy" then
            return self.Config.Models.CampfireWoodFancy
        else
            return self.Config.Models.CampfireWood
        end
    end
    
    -- Standard component pattern
    if tier == "Basic" or tier == "Fancy" then
        -- Create the model key with the appropriate prefix
        local modelKey = prefix .. componentType
        
        -- Check if the model exists in our config
        if self.Config.Models[modelKey] then
            return self.Config.Models[modelKey]
        end
    end
    
    -- Fall back to standard model if no tier-specific model is available
    return self.Config.Models[componentType]
end

-- Get the appropriate prop type for a component based on the current tier
function DJB_Camping:GetPropTypeForComponent(componentType)
    local tier = self:DetermineEquipmentVariation()
    
    -- Define tier-specific prefixes and special cases
    local prefix = ""
    if tier == "Basic" then
        prefix = "Basic"
    elseif tier == "Fancy" then
        prefix = "Fancy"
    end
    
    -- Special cases
    if componentType == "CampfireWood" and tier == "Fancy" then
        return "CampfireWoodFancy"
    end
    
    -- Check if there's a tier-specific prop type
    if tier == "Basic" or tier == "Fancy" then
        local propType = prefix .. componentType
        
        -- Check if the model exists in our config
        if self.Config.Models[propType] then
            return propType
        end
    end
    
    -- Fall back to standard prop type
    return componentType
end

-- ====================================
-- Base Entity Functions
-- ====================================

-- Create an entity with common parameters
function DJB_Camping:CreateEntity(params)
    local entity = System.SpawnEntity(params)
    
    if entity then
        self:Log("Created " .. params.name .. " successfully at " .. 
            tostring(params.position.x) .. ", " .. 
            tostring(params.position.y) .. ", " .. 
            tostring(params.position.z))
    else
        self:Log("Failed to create " .. params.name)
    end
    
    return entity
end

-- Places an entity that properly aligns to terrain
function DJB_Camping:PlaceTerrainAlignedEntity(entityClass, modelPath, componentName, distance, additionalProperties, set, type)
    -- Default distance if not specified
    distance = distance or 2.0
    
    -- Extract custom offsets if provided
    local customZOffset = 0
    local relativeRightOffset = 0  -- Offset perpendicular to player view (right is positive)
    local relativeForwardOffset = 0  -- Offset along player view (forward is positive)
    
    if additionalProperties then
        -- Extract relative positioning parameters
        if additionalProperties.customZOffset then
            customZOffset = additionalProperties.customZOffset
            additionalProperties.customZOffset = nil
        end
        
        if additionalProperties.relativeRightOffset then
            relativeRightOffset = additionalProperties.relativeRightOffset
            additionalProperties.relativeRightOffset = nil
        end
        
        if additionalProperties.relativeForwardOffset then
            relativeForwardOffset = additionalProperties.relativeForwardOffset
            additionalProperties.relativeForwardOffset = nil
        end
        
        -- Remove legacy absolute offsets if present to prevent unintended behavior
        if additionalProperties.customXOffset then
            additionalProperties.customXOffset = nil
        end
        
        if additionalProperties.customYOffset then
            additionalProperties.customYOffset = nil
        end
    end
    
    -- Get player position and view direction
    local playerPos = player:GetWorldPos()
    local playerDir = player:GetDirectionVector()
    
    -- Calculate the right vector (perpendicular to view direction)
    local rightDir = {
        x = -playerDir.y,  -- Perpendicular to player direction
        y = playerDir.x,
        z = 0
    }
    
    -- Calculate base spawn position in front of player
    local spawnPos = {
        x = playerPos.x + (playerDir.x * distance),
        y = playerPos.y + (playerDir.y * distance),
        z = playerPos.z
    }
    
    -- Apply relative offsets
    spawnPos.x = spawnPos.x + (rightDir.x * relativeRightOffset) + (playerDir.x * relativeForwardOffset)
    spawnPos.y = spawnPos.y + (rightDir.y * relativeRightOffset) + (playerDir.y * relativeForwardOffset)
    
    -- Get terrain position and normal for alignment
    local terrainPos = self:GetTerrainPosFromVec(spawnPos)
    local terrainNormal = self:GetTerrainNormalFromVec(spawnPos)
    
    -- Add Z offset to prevent z-fighting
    local zOffset = self.Config.ZOffset or 0.02  -- Default fallback value
    
    -- Apply Z offsets
    terrainPos.z = terrainPos.z + zOffset + customZOffset
    
    -- Calculate facing direction (facing the player)
    local facingAngle = math.atan2(-playerDir.y, -playerDir.x)
    
    -- In PlaceTerrainAlignedEntity function, modify how componentOffset is determined:
    local componentOffset = 0

    
    if self.Config then
        self:Log("DEBUG: self.Config exists")
        if self.Config.OrientationOffsets then
            self:Log("DEBUG: self.Config.OrientationOffsets exists")
            if self.Config.OrientationOffsets[set] then
                self:Log("DEBUG: self.Config.OrientationOffsets[" .. tostring(set) .. "] exists")
                if self.Config.OrientationOffsets[set][type] then
                    self:Log("DEBUG: self.Config.OrientationOffsets[" .. tostring(set) .. "][" .. tostring(type) .. "] exists")
                    if self.Config.OrientationOffsets[set][type][componentName] then
                        componentOffset = self.Config.OrientationOffsets[set][type][componentName]
                        self:Log("Applied orientation offset: " .. componentOffset)
                    else
                        self:Log("DEBUG: componentName '" .. tostring(componentName) .. "' not found")
                    end
                else
                    self:Log("DEBUG: type '" .. tostring(type) .. "' not found")
                end
            else
                self:Log("DEBUG: set '" .. tostring(set) .. "' not found")
            end
        else
            self:Log("DEBUG: self.Config.OrientationOffsets is nil")
        end
    else
        self:Log("DEBUG: self.Config is nil")
    end

    facingAngle = facingAngle + componentOffset

    -- Create the base entity parameters
    local entityParams = {
        class = entityClass,
        position = terrainPos,
        name = "DJB_" .. componentName,
        properties = {
            object_Model = "",
            bSaved_by_game = 1,
            bSerialize = 1
        }
    }
    
    -- Add any additional properties if provided
    if additionalProperties then
        for k, v in pairs(additionalProperties) do
            entityParams.properties[k] = v
        end
    end
    
    -- Spawn the entity
    local entity = self:CreateEntity(entityParams)
    
    if not entity then
        self:Log("Failed to create " .. componentName .. " entity")
        return nil
    end
    
    -- First set just the facing rotation (z-axis)
    entity:SetAngles({x = 0, y = 0, z = facingAngle})
    
    -- Set up rendering properties
    entity:SetViewDistUnlimited()
    entity:RenderShadow(true)
    
    --EntityCommon.MakeRenderProxyOptions(entity)
    EntityCommon.SetupCollisionFiltering(entity) -- Doesnt do shit for some cgf models, no idea why

    -- Calculate alignment based on terrain normal and facing direction
    local sinZ = math.sin(facingAngle)
    local cosZ = math.cos(facingAngle)
    
    -- Entity's forward direction vector after z-rotation
    local entityForward = {
        x = cosZ,
        y = sinZ,
        z = 0
    }
    
    -- Entity's right direction vector after z-rotation
    local entityRight = {
        x = -sinZ,
        y = cosZ,
        z = 0
    }
    
    -- Calculate rotation angles based on how much the terrain normal deviates from up
    local rollAngle = math.asin(-(entityRight.x * terrainNormal.x + entityRight.y * terrainNormal.y))
    local pitchAngle = math.asin(entityForward.x * terrainNormal.x + entityForward.y * terrainNormal.y)
    
    -- Apply the terrain alignment strength multiplier
    local alignmentStrength = self.Config.Alignment and self.Config.Alignment.TerrainAlignmentStrength or 0.9
    rollAngle = rollAngle * alignmentStrength
    pitchAngle = pitchAngle * alignmentStrength
    
    -- Apply the final rotations
    entity:SetAngles({
        x = rollAngle,
        y = pitchAngle,
        z = facingAngle
    })
    
    -- Log placement info
    self:Log("Created terrain-aligned " .. componentName .. " entity")
    self:Log("Position: " .. terrainPos.x .. ", " .. terrainPos.y .. ", " .. terrainPos.z)
    self:Log("Terrain normal: " .. terrainNormal.x .. ", " .. terrainNormal.y .. ", " .. terrainNormal.z)
    local angles = entity:GetAngles()
    self:Log("Applied angles: " .. angles.x .. ", " .. angles.y .. ", " .. angles.z)
    
    return entity
end

-- Places an entity that properly aligns to terrain at a specific world position
function DJB_Camping:PlaceTerrainAlignedEntityAtPosition(entityClass, modelPath, componentName, position, additionalProperties, set, type)
    
    -- Extract custom offsets if provided
    local customZOffset = 0
    local relativeRightOffset = 0  -- Offset perpendicular to player view (right is positive)
    local relativeForwardOffset = 0  -- Offset along player view (forward is positive)
    
    if additionalProperties then
        -- Extract relative positioning parameters
        if additionalProperties.customZOffset then
            customZOffset = additionalProperties.customZOffset
            additionalProperties.customZOffset = nil
        end
        
        if additionalProperties.relativeRightOffset then
            relativeRightOffset = additionalProperties.relativeRightOffset
            additionalProperties.relativeRightOffset = nil
        end
        
        if additionalProperties.relativeForwardOffset then
            relativeForwardOffset = additionalProperties.relativeForwardOffset
            additionalProperties.relativeForwardOffset = nil
        end
        
        -- Remove legacy absolute offsets if present to prevent unintended behavior
        if additionalProperties.customXOffset then
            additionalProperties.customXOffset = nil
        end
        
        if additionalProperties.customYOffset then
            additionalProperties.customYOffset = nil
        end
    end
    
    -- Get player position and view direction for relative offsets and facing calculation
    local playerPos = player:GetWorldPos()
    local playerDir = player:GetDirectionVector()
    
    -- Calculate the right vector (perpendicular to view direction)
    local rightDir = {
        x = -playerDir.y,  -- Perpendicular to player direction
        y = playerDir.x,
        z = 0
    }
    
    -- Use the provided position as the base spawn position
    local spawnPos = {
        x = position.x,
        y = position.y,
        z = position.z
    }
    
    -- Apply relative offsets if any are specified
    if relativeRightOffset ~= 0 or relativeForwardOffset ~= 0 then
        spawnPos.x = spawnPos.x + (rightDir.x * relativeRightOffset) + (playerDir.x * relativeForwardOffset)
        spawnPos.y = spawnPos.y + (rightDir.y * relativeRightOffset) + (playerDir.y * relativeForwardOffset)
    end
    
    -- Get terrain position and normal for alignment
    local terrainPos = self:GetTerrainPosFromVec(spawnPos)
    local terrainNormal = self:GetTerrainNormalFromVec(spawnPos)
    
    -- Add Z offset to prevent z-fighting
    local zOffset = self.Config.ZOffset or 0.02  -- Default fallback value
    
    -- Apply Z offsets
    terrainPos.z = terrainPos.z + zOffset + customZOffset
    
    -- Calculate facing direction (facing the player)
    local facingAngle = math.atan2(-playerDir.y, -playerDir.x)
    
    -- Determine component orientation offset
    local componentOffset = 0

    if self.Config then
        self:Log("DEBUG: self.Config exists")
        if self.Config.OrientationOffsets then
            self:Log("DEBUG: self.Config.OrientationOffsets exists")
            if self.Config.OrientationOffsets[set] then
                self:Log("DEBUG: self.Config.OrientationOffsets[" .. tostring(set) .. "] exists")
                if self.Config.OrientationOffsets[set][type] then
                    self:Log("DEBUG: self.Config.OrientationOffsets[" .. tostring(set) .. "][" .. tostring(type) .. "] exists")
                    if self.Config.OrientationOffsets[set][type][componentName] then
                        componentOffset = self.Config.OrientationOffsets[set][type][componentName]
                        self:Log("Applied orientation offset: " .. componentOffset)
                    else
                        self:Log("DEBUG: componentName '" .. tostring(componentName) .. "' not found")
                    end
                else
                    self:Log("DEBUG: type '" .. tostring(type) .. "' not found")
                end
            else
                self:Log("DEBUG: set '" .. tostring(set) .. "' not found")
            end
        else
            self:Log("DEBUG: self.Config.OrientationOffsets is nil")
        end
    else
        self:Log("DEBUG: self.Config is nil")
    end

    facingAngle = facingAngle + componentOffset

    -- Create the base entity parameters
    local entityParams = {
        class = entityClass,
        position = terrainPos,
        name = "DJB_" .. componentName,
        properties = {
            object_Model = "", 
            bSaved_by_game = 1,
            bSerialize = 1
        }
    }
    
    -- Add any additional properties if provided
    if additionalProperties then
        for k, v in pairs(additionalProperties) do
            entityParams.properties[k] = v
        end
    end
    
    -- Spawn the entity
    local entity = self:CreateEntity(entityParams)
    
    if not entity then
        self:Log("Failed to create " .. componentName .. " entity")
        return nil
    end
    
    -- First set just the facing rotation (z-axis)
    entity:SetAngles({x = 0, y = 0, z = facingAngle})
    
    -- Set up rendering properties
    entity:SetViewDistUnlimited()
    entity:RenderShadow(true)
    --EntityCommon.MakeRenderProxyOptions(entity)
    EntityCommon.SetupCollisionFiltering(entity) -- Doesnt do shit for some cgf models, no idea why

    -- Calculate alignment based on terrain normal and facing direction
    local sinZ = math.sin(facingAngle)
    local cosZ = math.cos(facingAngle)
    
    -- Entity's forward direction vector after z-rotation
    local entityForward = {
        x = cosZ,
        y = sinZ,
        z = 0
    }
    
    -- Entity's right direction vector after z-rotation
    local entityRight = {
        x = -sinZ,
        y = cosZ,
        z = 0
    }
    
    -- Calculate rotation angles based on how much the terrain normal deviates from up
    local rollAngle = math.asin(-(entityRight.x * terrainNormal.x + entityRight.y * terrainNormal.y))
    local pitchAngle = math.asin(entityForward.x * terrainNormal.x + entityForward.y * terrainNormal.y)
    
    -- Apply the terrain alignment strength multiplier
    local alignmentStrength = self.Config.Alignment and self.Config.Alignment.TerrainAlignmentStrength or 0.9
    rollAngle = rollAngle * alignmentStrength
    pitchAngle = pitchAngle * alignmentStrength
    
    -- Apply the final rotations
    entity:SetAngles({
        x = rollAngle,
        y = pitchAngle,
        z = facingAngle
    })
    
    -- Log placement info
    self:Log("Created terrain-aligned " .. componentName .. " entity at position")
    self:Log("Requested position: " .. position.x .. ", " .. position.y .. ", " .. position.z)
    self:Log("Final terrain position: " .. terrainPos.x .. ", " .. terrainPos.y .. ", " .. terrainPos.z)
    self:Log("Terrain normal: " .. terrainNormal.x .. ", " .. terrainNormal.y .. ", " .. terrainNormal.z)
    local angles = entity:GetAngles()
    self:Log("Applied angles: " .. angles.x .. ", " .. angles.y .. ", " .. angles.z)
    
    return entity
end

-- ====================================
-- Bed Creation Functions
-- ====================================

-- Create a hidden bed entity for sleeping functionality
function DJB_Camping:SpawnBed(angleZ, position)

    -- Confirm there are no pre existing beds
    local removeAllPossibleBeds = System.GetEntitiesByClass("DJB_BedEntity")
        if #removeAllPossibleBeds < 1 then
            self:Log("No beds to be cleaned up before spawning")
        else
            for _, bed in ipairs(removeAllPossibleBeds) do
                self:Log("Found bed to be cleaned up: " .. bed:GetName())
                -- Discard
                bed:DeleteThis()
                self:Log("Removed it.")
            end
        end

    self.Entities.bed = nil
    self.State.isBedDeployed = false

    -- Create the hidden bed entity that handles sleeping functionality
    -- Determine quality of sleeping
    local set = self:DetermineEquipmentVariation()
    local quality = "low"
    if set.quality == 1 then
        quality = "medium"
    elseif set.quality == 2 then
        quality = "high"
    end
    self:Log("Bed quality determined to be: " .. quality .. " due to set: " .. tostring(set.name))

    -- Create the parameters
    local spawnParams = {
        class = "DJB_BedEntity",
        position = position,
        name = "DJB_Bed",
        properties = {
            Position = position,
            Angles = {x = 0, y = 0, z = angleZ},
            object_Model = "", 
            bSaved_by_game = 1,
            bSerialize = 1,
            Bed = {
                esSleepQuality = quality
            }
        }
    }
    
    -- Spawn the entity
    self.Entities.bed = self:CreateEntity(spawnParams)
    -- Hide it, as it's not meant to be seen or collided with
    self.Entities.bed:Hide(1)
    local debug = self.Entities.bed:GetAngles()
    self:Log("Bed entity has been created with angles: x: " .. tostring(debug.x) .. " y: " .. tostring(debug.y) .. " z: " .. tostring(debug.z))

    -- Update state
    self.State.isBedDeployed = true

    -- For basic tier, we need an invisible collider for the tent

    -- Remove any possible previous colliders
    local props = System.GetEntitiesByClass("DJB_PropEntity")
    for _, prop in ipairs(props) do
        local name = prop:GetName()
        if name == "DJB_BasicBedCollider" or name == "DJB_FancyBedCollider" then
            prop:DeleteThis()
        end
    end

    if set.quality == 0 then
        local spawnParams = {
            class = "DJB_PropEntity",
            position = self.Entities.Anchors.Bed.bedBackAnchor:GetPos(),
            name = "DJB_BasicBedCollider",
            HiddenInGame = true,
            properties = {
                object_Model = self.Config.Models.Tent, 
                bSaved_by_game = 1,
                bSerialize = 1,
            }
        }   
        self.Entities.basicBedCollider = self:CreateEntity(spawnParams)
        local tentAngles = self.Entities.Anchors.Bed.bedBackAnchor:GetAngles()
        self.Entities.basicBedCollider:SetAngles(tentAngles)
        self.Entities.basicBedCollider:DrawSlot(0,0)
    end

    if set.quality == 2 then
        local spawnParams = {
            class = "DJB_PropEntity",
            position = self.Entities.Anchors.Bed.bedBackAnchor:GetPos(),
            name = "DJB_FancyBedCollider",
            HiddenInGame = true,
            properties = {
                object_Model = self.Config.Models.Tent, 
                bSaved_by_game = 1,
                bSerialize = 1,
            }
        }
        self.Entities.fancyBedCollider = self:CreateEntity(spawnParams)
        self.Entities.fancyBedCollider:SetScale(1.3)
        local tentAngles = self.Entities.Anchors.Bed.bedBackAnchor:GetAngles()
        self.Entities.fancyBedCollider:SetAngles(tentAngles)
        self.Entities.fancyBedCollider:DrawSlot(0,0)
    end
    self:Log ("Bed spawning finished. Bed SO is saved as: " .. self.Entities.bed:GetName())
    
end

-- Spawns anchors and uses them to instantiate the prefabs for bed decorations
function DJB_Camping:SpawnAllBedPrefabs()
    -- Make sure tables exist
    if not self.Entities.Anchors then
        self.Entities.Anchors = {}
    end
    if not self.Config.AnchorOffsets then
        self.Config.AnchorOffsets = {}
    end
    
    -- Determine camping equipment set to use
    local set = self:DetermineEquipmentVariation()
    self:Log("Using " .. tostring(set.name) .. " props for bed")

    -- Use the terrain alignment function to create the bed prefab anchor and store reference to it
    self.Entities.Anchors.Bed.bedAnchor = self:PlaceTerrainAlignedEntity(
        "DJB_PropEntity", 
        "Objects/manmade/common_furniture/chairs/low/chair_rustic_d.cgf", 
        "BedAnchor", 
        self.Config.Distance.Bed,
        {
            relativeRightOffset = self.Config.AnchorOffsets[set.name].Bed.bedAnchor.relativeRight,
            relativeForwardOffset = self.Config.AnchorOffsets[set.name].Bed.bedAnchor.relativeForward,
            customZOffset = self.Config.AnchorOffsets[set.name].Bed.bedAnchor.z
        },
        set.name,
        "Bed"
    )
    if self.Entities.Anchors.Bed.bedAnchor then
        self:Log(self.Entities.Anchors.Bed.bedAnchor:GetName() .. " created with terrain alignment")
        self.Entities.Anchors.Bed.bedAnchor:Hide(1)
        Game.SpawnPrefab(self.Entities.Anchors.Bed.bedAnchor.id, set.bedPrefabId, 0)
        local ent = self.Entities.Anchors.Bed.bedAnchor
        if ent ~=nil then ent.Properties.sPrefabID = set.bedPrefabId end
    else
        self:Log("ERROR: Failed to create DJB_BedAnchor")
    end

    -- Create the left side anchor
    self.Entities.Anchors.Bed.bedLeftAnchor = self:PlaceTerrainAlignedEntity(
        "DJB_PropEntity",
        "Objects/manmade/common_furniture/chairs/low/chair_rustic_d.cgf", 
        "BedLeftAnchor",
        self.Config.Distance.Bed,
        {
            relativeRightOffset = self.Config.AnchorOffsets[set.name].Bed.bedLeftAnchor.relativeRight,
            relativeForwardOffset = self.Config.AnchorOffsets[set.name].Bed.bedLeftAnchor.relativeForward,
            customZOffset = self.Config.AnchorOffsets[set.name].Bed.bedLeftAnchor.z
        },
        set.name,
        "Bed"
    )
    if self.Entities.Anchors.Bed.bedLeftAnchor then
        self:Log(self.Entities.Anchors.Bed.bedLeftAnchor:GetName() .. " created with terrain alignment")
        self.Entities.Anchors.Bed.bedLeftAnchor:Hide(1)
        Game.SpawnPrefab(self.Entities.Anchors.Bed.bedLeftAnchor.id, set.bedLeftPrefabId, 0)
        local ent = self.Entities.Anchors.Bed.bedLeftAnchor
        if ent ~=nil then ent.Properties.sPrefabID = set.bedLeftPrefabId end
    else
        self:Log("ERROR: Failed to create DJB_BedLeftAnchor")
    end
    -- Create the right side anchor
    self.Entities.Anchors.Bed.bedRightAnchor = self:PlaceTerrainAlignedEntity(
        "DJB_PropEntity",
        "Objects/manmade/common_furniture/chairs/low/chair_rustic_d.cgf", 
        "BedRightAnchor",
        self.Config.Distance.Bed,
        {
            relativeRightOffset = self.Config.AnchorOffsets[set.name].Bed.bedRightAnchor.relativeRight,
            relativeForwardOffset = self.Config.AnchorOffsets[set.name].Bed.bedRightAnchor.relativeForward,
            customZOffset = self.Config.AnchorOffsets[set.name].Bed.bedRightAnchor.z
        },
        set.name,
        "Bed"
    )
    if self.Entities.Anchors.Bed.bedRightAnchor then
        self:Log(self.Entities.Anchors.Bed.bedRightAnchor:GetName() .. " created with terrain alignment")
        self.Entities.Anchors.Bed.bedRightAnchor:Hide(1)
        Game.SpawnPrefab(self.Entities.Anchors.Bed.bedRightAnchor.id, set.bedRightPrefabId, 0)
        local ent = self.Entities.Anchors.Bed.bedRightAnchor
        if ent ~=nil then ent.Properties.sPrefabID = set.bedRightPrefabId end
    else
        self:Log("ERROR: Failed to create DJB_BedRightAnchor")
    end
    -- Create the front side anchor
    self.Entities.Anchors.Bed.bedFrontAnchor = self:PlaceTerrainAlignedEntity(
        "DJB_PropEntity",
        "Objects/manmade/common_furniture/chairs/low/chair_rustic_d.cgf", 
        "BedFrontAnchor",
        self.Config.Distance.Bed,
        {
            relativeRightOffset = self.Config.AnchorOffsets[set.name].Bed.bedFrontAnchor.relativeRight,
            relativeForwardOffset = self.Config.AnchorOffsets[set.name].Bed.bedFrontAnchor.relativeForward,
            customZOffset = self.Config.AnchorOffsets[set.name].Bed.bedFrontAnchor.z
        },
        set.name,
        "Bed"
    )
    if self.Entities.Anchors.Bed.bedFrontAnchor then
        self:Log(self.Entities.Anchors.Bed.bedFrontAnchor:GetName() .. " created with terrain alignment")
        self.Entities.Anchors.Bed.bedFrontAnchor:Hide(1)
        Game.SpawnPrefab(self.Entities.Anchors.Bed.bedFrontAnchor.id, set.bedFrontPrefabId, 0)
        local ent = self.Entities.Anchors.Bed.bedFrontAnchor
        if ent ~=nil then ent.Properties.sPrefabID = set.bedFrontPrefabId end
    else
        self:Log("ERROR: Failed to create DJB_BedFrontAnchor")
    end
    -- Create the back side anchor (tent)
    self.Entities.Anchors.Bed.bedBackAnchor = self:PlaceTerrainAlignedEntity(
        "DJB_PropEntity",
        "Objects/manmade/common_furniture/chairs/low/chair_rustic_d.cgf", 
        "BedBackAnchor",
        self.Config.Distance.Bed,
        {
            relativeRightOffset = self.Config.AnchorOffsets[set.name].Bed.bedBackAnchor.relativeRight,
            relativeForwardOffset = self.Config.AnchorOffsets[set.name].Bed.bedBackAnchor.relativeForward,
            customZOffset = self.Config.AnchorOffsets[set.name].Bed.bedBackAnchor.z
        },
        set.name,
        "Bed"
    )
    if self.Entities.Anchors.Bed.bedBackAnchor then  
        self:Log(self.Entities.Anchors.Bed.bedBackAnchor:GetName() .. " created with terrain alignment")
        self.Entities.Anchors.Bed.bedBackAnchor:Hide(1)
        -- Spawn the prefab
        Game.SpawnPrefab(self.Entities.Anchors.Bed.bedBackAnchor.id, set.bedBackPrefabId, 0)
        local ent = self.Entities.Anchors.Bed.bedBackAnchor
        if ent ~=nil then ent.Properties.sPrefabID = set.bedBackPrefabId end
    else
        self:Log("ERROR: Failed to create DJB_BedBackAnchor")
    end

    -- Create the stash anchor 
    self.Entities.Anchors.Bed.stashAnchor = self:PlaceTerrainAlignedEntity(
        "DJB_PropEntity",
        "Objects/manmade/common_furniture/chairs/low/chair_rustic_d.cgf", 
        "StashAnchor",
        self.Config.Distance.Bed,
        {
            relativeRightOffset = self.Config.AnchorOffsets[set.name].Bed.stashAnchor.relativeRight,
            relativeForwardOffset = self.Config.AnchorOffsets[set.name].Bed.stashAnchor.relativeForward,
            customZOffset = self.Config.AnchorOffsets[set.name].Bed.stashAnchor.z
        },
        set.name,
        "Stash"
    )
    if self.Entities.Anchors.Bed.stashAnchor then  
        self:Log(self.Entities.Anchors.Bed.stashAnchor:GetName() .. " created with terrain alignment")
        self.Entities.Anchors.Bed.stashAnchor:Hide(1)
    else
        self:Log("ERROR: Failed to create DJB_StashAnchor")
    end

    self:Log("SpawnAllBedAnchors() has finished execution with selected set: " .. tostring(set.name))
end

-- Create the bed trigger for interaction
function DJB_Camping:SpawnBedTrigger(spawnPos)

    -- Clean up any possible left over trigger
    local beds = System.GetEntitiesByClass("BedTrigger")
    for _, bed in ipairs(beds) do
        local name = bed:GetName()
        if name == "CampBed_Trigger" then
            bed:DeleteThis()
            self.Entities.bedTrigger = nil
        end
    end

    -- Calculate trigger position based on the offset
    local offset = self.Config.BedTrigger.Offset
    local triggerPos = {
        x = spawnPos.x + offset.x,
        y = spawnPos.y + offset.y,
        z = spawnPos.z + offset.z
    }
    local triggerParams = {
        class = "BedTrigger",
        name = "CampBed_Trigger",
        position = triggerPos,
        scale = self.Config.BedTrigger.Scale,
        properties = {
            InteractorPriorityOverride = 1,
            Click = {
                bIsActive = true,
                bedEntity = self.Entities.bed,
                UseMessage = "@ui_hud_sleep",
                bAllowNoOwner = 0,
                bCheckOwner = 0,
                esActionType = "Stance",
                sAction = "lying",
            }
        }
    }
    self.Entities.bedTrigger = self:CreateEntity(triggerParams)
    self:Log("Spawned BedTrigger: " .. self.Entities.bedTrigger:GetName())
end

-- Link bed entity to its trigger
function DJB_Camping:LinkBedEntities()
    self.Entities.bedTrigger:CreateLink("", self.Entities.bed.id)
    self.Entities.bed:CreateLink("mTrigger", self.Entities.bedTrigger.id)
    self:Log("Linked bed entities")
end

-- Update RemoveAllBedProps to handle tier-specific props
function DJB_Camping:RemoveAllBedProps()
    if not self.Entities.Anchors then
        self:Log("No Anchors table found")
        return
    end
    
    -- Define bed-related prop types across all sets
    local bedRelatedProps = {
        "bedAnchor",
        "bedLeftAnchor",
        "bedRightAnchor",
        "bedFrontAnchor",
        "bedBackAnchor",
        "stashAnchor",
    }
    
    -- Remove each prop type
    for _, propKey in ipairs(bedRelatedProps) do
        if self.Entities.Anchors.Bed[propKey] then
            local entity = self.Entities.Anchors.Bed[propKey]
            if entity and entity.id then
                Game.DeletePrefab(entity.id)
                entity:DeleteThis()
                self.Entities.Anchors.Bed[propKey] = nil
                self:Log("Removed " .. propKey)
            else
                self:Log("WARNING: " .. propKey .. " exists but has no valid entity or ID")
            end
        end
    end

    if self.Entities.basicBedCollider then
        System.RemoveEntity(self.Entities.basicBedCollider.id)
    end
    
    if self.Entities.fancyBedCollider then
        System.RemoveEntity(self.Entities.fancyBedCollider.id)
    end

    if self.Entities.stash then
        System.RemoveEntity(self.Entities.stash.id)
    end
    self:Log("All bed props removed")
end

-- Create standardized bed trigger with correct parameters
function DJB_Camping:CreateBedTriggerForEntity(bedEntity, triggerPos, index)
    -- Set up trigger parameters
    local triggerParams = {
        class = "BedTrigger",
        name = "DJB_Bed_Trigger_" .. tostring(index or 0),
        position = triggerPos,
        orientation = bedEntity:GetAngles(),
        properties = {
            bSerialize = true,
            bSaved_by_game = true,
            Saved_by_game = true,
            InteractorPriorityOverride = 1,
            Click = {
                bIsActive = true,
                bAllowNoOwner = 0,
                bCheckOwner = 1,
                esActionType = "Stance",
                sAction = "lying",
                UseMessage = "@ui_hud_sleep",
                UseNotOwnerMessage = "@ui_hud_sleep"
            }
        }
    }
    
    return self:CreateEntity(triggerParams)
end

--=============================================================================================
-- Main bed placement function
function DJB_Camping:PlaceBed()
    -- Check if bed is already deployed
    local preexistingBeds = System.GetEntitiesByClass("DJB_BedEntity")
    if #preexistingBeds >= 1 then
        self.State.isBedDeployed = true
        self:Log("Found a bed entity, will not place another")
        self:Notify("@ui_djb_camping_bed_already_deployed")
        return false
    else
        self.State.isBedDeployed = false
        self:Log("Did not find a bed entity, proceeding to place one")
    end
    
    -- Check for obstructions
    -- Get position to be placed
    local bedPosition = self:GetPositionInFront(self.Config.Distance.Bed)
    if not self:IsSuitableLocation(bedPosition) then
        self:Notify("@ui_djb_camping_unsuitable_bed_location")
        return false
    end

    -- Spawn all visual prop anchors with terrain alignment
    -- These must be spawned first, the functional smart objects are placed based off their
    -- positioning.
    self:SpawnAllBedPrefabs()
    
    -- Work out what angles for the bed entity (based off where the prop is) 
    local bedAngles = self.Entities.Anchors.Bed.bedAnchor:GetAngles()
    local angleZ = bedAngles.z
    
    -- Spawn invisible bed entity
    self:SpawnBed(angleZ, bedPosition)

    -- Spawn drying rack if available
    if ItemUtils.HasItem(player, "61ab2690-fe1b-48b7-843b-d18bcced1b94") then
        -- Adjust SO positioning
            local anchorPos = self.Entities.Anchors.Bed.bedLeftAnchor:GetPos()
            local newPos = {
                x = anchorPos.x,
                y = anchorPos.y,
                z = anchorPos.z - 0.4
            }
            self:SpawnDryingRack(newPos)
    end

    -- b8feddb3-1708-4c90-98ba-24dcf7ed62c7
    -- Spawn laundry kit if available
    if ItemUtils.HasItem(player, "b8feddb3-1708-4c90-98ba-24dcf7ed62c7") then
        self:SpawnWashingBasin(self.Entities.Anchors.Bed.bedFrontAnchor:GetPos())
    end

    -- Spawn bed trigger at the bed prop position
    self:SpawnBedTrigger(self.Entities.Anchors.Bed.bedAnchor:GetPos())
    
    -- Link the bed and trigger entities
    self:LinkBedEntities()

    -- Spawn Stash
    --self:SpawnChest(self.Entities.Anchors.Bed.stashAnchor:GetPos())
    
    -- Update state
    self.State.isBedDeployed = true
    
    -- Notify success
    self:Notify("@ui_djb_camping_bed_placed")
    return true
end

--=============================================================================================
-- Pack up the bed
function DJB_Camping:PackUpBed()
    
    local existingBeds = System.GetEntitiesByClass("DJB_BedEntity")
    if #existingBeds < 1 then 
        self:Log("No beds found, returning")
        self:Notify("@ui_djb_camping_no_bed_deployed")
        return false 
    else
        for _, bed in ipairs(existingBeds) do
            self:Log("Found existing bed: " .. bed:GetName())
            bed:DeleteThis()
            self:Log("Removed it.")
        end
        self:Log("Bed/s removed")
    end
    self.State.isBedDeployed = false
    self.Entities.bed = nil

    -- Clean up any possible left over trigger
    local beds = System.GetEntitiesByClass("BedTrigger")
    for _, bed in ipairs(beds) do
        local name = bed:GetName()
        if name == "CampBed_Trigger" then
            bed:DeleteThis()
        end
    end
    self.Entities.bedTrigger = nil

    -- Check if there's actually a drying rack to pack up
    local existingDryingRacks = System.GetEntitiesByClass("DJB_DryingRackEntity")
    
    if #existingDryingRacks < 1 then 
        self:Log("No drying racks found, no further drying rack actions")
    else
        for _, rack in ipairs(existingDryingRacks) do
            self:Log("Found existing drying rack: " .. rack:GetName())
            rack:DeleteThis()
            self:Log("Removed it.")
        end
        Game.DeletePrefab(self.Entities.Anchors.Bed.bedLeftAnchor.id)
        self:Log("Drying Rack/s removed")
    end
    self.State.isRackDeployed = false
    self.Entities.dryingSmartObject = nil

    -- Clean up any possible left over trigger first
    local rackTriggers = System.GetEntitiesByClass("FoodProcessingTrigger")
    for _, rackTrigger in ipairs(rackTriggers) do
        local name = rackTrigger:GetName()
        if name == "DJB_DryingTrigger" then
            rackTrigger:DeleteThis()
        end
    end
    self.Entities.dryingTrigger = nil
    
    -- Check for washing basin to pack up 
    local existingWashingBasins = System.GetEntitiesByClass("DJB_WashingBasinEntity")
    
    if #existingWashingBasins < 1 then 
        self:Log("No washing basins found, no further actions")
    else
        for _, basin in ipairs(existingWashingBasins) do
            self:Log("Found existing basin: " .. basin:GetName())
            basin:DeleteThis()
            self:Log("Removed it.")
        end
        Game.DeletePrefab(self.Entities.Anchors.Bed.bedFrontAnchor.id)
        self:Log("Drying Rack/s removed")
    end
    self.State.isBasinDeployed = false
    self.Entities.washingBasin = nil

    -- Clean up any possible left over trigger 
    local basinTriggers = System.GetEntitiesByClass("WaterTubeActionTrigger")
    for _, basinTrigger in ipairs(basinTriggers) do
        local name = basinTrigger:GetName()
        if name == "DJB_BasinTrigger" then
            basinTrigger:DeleteThis()
        end
    end
    self.Entities.basinTrigger = nil

    -- Remove all props
    self:RemoveAllBedProps()
    
    -- Confirm there are no pre existing stashes
    local stashes = System.GetEntitiesByClass("Stash")
    for _, stash in ipairs(stashes) do
        local name = stash:GetName()
        if name == "DJB_Stash" then
            stash:DeleteThis()
        end
    end
    self.Entities.stash = nil

    -- Destroy possible colliders
    local props = System.GetEntitiesByClass("DJB_PropEntity")
    for _, prop in ipairs(props) do
        local name = prop:GetName()
        if name == "DJB_FancyBedCollider" then
            prop:DeleteThis()
            self.Entities.fancyBedCollider = nil
        elseif name == "DJB_BasicBedCollider" then
            prop:DeleteThis()
            self.Entities.basicBedCollider = nil
        end
    end

    -- Notify success
    self:Notify("@ui_djb_camping_bed_packed")
    return true
end

--=============================================================================================
-- Pack up all camp components
function DJB_Camping:PackUpCamp()
    local anythingPacked = false
    
    -- Pack up campfire if deployed
    if self.State.isFireDeployed then
        self:PackUpCampfire()
        anythingPacked = true
    end
    
    -- Pack up bed if deployed
    if self.State.isBedDeployed then
        self:PackUpBed()
        anythingPacked = true
    end

    -- Pack up chair if deployed
    if self.State.isChairDeployed then
        self:PackUpChair()
        anythingPacked = true
    end
    
    -- Show message if nothing was deployed
    if not anythingPacked then
        self:Notify("@ui_djb_camping_no_components_deployed")
        return false
    end
    
    return true
end

--=============================================================================================
