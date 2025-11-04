/////////////////////////////////////////
// -- Dubz Scrap System Config File -- //
/////////////////////////////////////////

DVS = DVS or {}

-- Basic HUD placement
DVS.UI = {
    UI_X = 30,
    UI_Y = 30,
    UI_Width = 260,
    UI_Height = 40
}

------------------------------------------
-- UI Colors & Rarity Colors (customize) --
------------------------------------------
DVS.UIColors = {
    Background    = Color(0, 0, 0, 150),
    Frame         = Color(40, 40, 40, 180),
    TextPrimary   = Color(255, 255, 255),
    TextHighlight = Color(0, 200, 255),
    ProgressBar   = Color(0, 170, 255, 220),
    ProgressBarBG = Color(0, 0, 0, 180),
    XPBar         = Color(0, 120, 255),
    XPBarBG       = Color(30, 30, 30, 200),
    Notification  = Color(255, 215, 0)
}

DVS.RarityColors = {
    common    = Color(180, 180, 180),
    uncommon  = Color(100, 255, 100),
    rare      = Color(100, 150, 255),
    epic      = Color(180, 100, 255),
    legendary = Color(255, 150, 50)
}

----------------------------------
-- Model Settings for Entities  --
----------------------------------
DVS.Models = {
    Vendor   = "models/Humans/Group01/male_07.mdl",
    Scrapper = "models/props_wasteland/laundry_washer003.mdl",
    Scrap = {
        "models/props_debris/metal_panelchunk02d.mdl",
        "models/props_debris/metal_panelchunk02e.mdl",
        "models/props_debris/metal_panelshard01a.mdl",
        "models/props_debris/metal_panelshard01b.mdl",
        "models/props_debris/metal_panelshard01d.mdl",
        "models/props_debris/metal_panelshard01c.mdl"
    },
    Lootables = {
        "models/props_junk/TrashDumpster01a.mdl",
        "models/props_junk/TrashBin01a.mdl",
        "models/props_c17/furnituredrawer001a.mdl",
        "models/props_c17/Lockers001a.mdl",
        "models/props_vehicles/car004a_physics.mdl"
    }
}

-------------------------
-- Vendor Voice Lines  --
-------------------------
DVS.VendorVoices = {
    Interval = {min = 25, max = 60},
    Lines = {
        "vo/npc/male01/hi01.wav",
        "vo/npc/male01/answer36.wav",
        "vo/npc/male01/question25.wav",
        "vo/npc/male01/squad_away02.wav",
        "vo/npc/male01/okimready03.wav",
        "vo/npc/male01/yeah02.wav"
    }
}

----------------------
-- Vendor Defaults  --
----------------------
DVS.DefaultVendor = {
    ScrapSellRange   = { min = 6, max = 24 },
    RefreshInterval  = 900,
    PriceFluctuation = 0.25
}

-----------------------
-- Faction Vendors   --
-----------------------
DVS.Factions = DVS.Factions or {
    ["Civilians"] = {
        ScrapSellRange   = { min = 6,  max = 24 },
        RefreshInterval  = 900,
        PriceFluctuation = 0.25,
        ShopItems = {
            Entities = {
                { name = "Money Printer", class = "money_printer", baseprice = 800 },
                { name = "Money Printer", class = "money_printer", baseprice = 800 },
                { name = "Money Printer", class = "money_printer", baseprice = 800 },
                { name = "Money Printer", class = "money_printer", baseprice = 800 },
            },
            Weapons = {
                { name = "Pistol",  class = "weapon_pistol",  baseprice = 250 },
                { name = "SMG",     class = "weapon_smg1",    baseprice = 400 }
            }
        }
    },
    ["Guards"] = {
        ScrapSellRange   = { min = 10,  max = 28 },
        RefreshInterval  = 1200,
        PriceFluctuation = 0.15,
        ShopItems = {
            Entities = {
                { name = "Money Printer", class = "money_printer", baseprice = 800 },
            },
            Weapons = {
                { name = "Shotgun", class = "weapon_shotgun", baseprice = 600 },
                { name = "AR2",     class = "weapon_ar2",     baseprice = 1000 }
            }
        }
    }
}

-----------------------
-- Global Events     --
-----------------------
DVS.Events = {
    Enabled = false,
    Name = "Scrap Surge Weekend",
    Duration = 3600,
    Multipliers = {
        ScrapSellBoost = 1.5,
        LootChanceBoost = 1.25,
        XPGainBoost = 2.0
    },
    Broadcast = true
}

----------------------------
-- Zombie/NPC Integration --
----------------------------
DVS.ZombieIntegration = {
    Enabled = false,
    NPCs = {
        { class = "npc_zombie",       chance = 40 },
        { class = "npc_fastzombie",   chance = 25 },
        { class = "npc_poisonzombie", chance = 10 }
    },
    LootTable = {
        ScrapPieces = { min = 0, max = 2, chance = 50 },
        Entities = {
            { name = "Money Printer", class = "money_printer", chance = 5 }
        },
        Weapons = {
            { name = "Pistol",  class = "weapon_pistol",   chance = 25 },
            { name = "SMG",     class = "weapon_smg1",     chance = 15 },
            { name = "Shotgun", class = "weapon_shotgun",  chance = 10 }
        }
    }
}

----------------------
-- Looting Settings --
----------------------
DVS.Looting = {
    LootTime    = 4,
    Cooldown    = 30,
    MaxDistance = 120,
}

----------------------
-- XP / Leveling    --
----------------------
DVS.XP = {
    BaseGain = 5,
    RarityXP = {
        common = 5, uncommon = 10, rare = 20, epic = 35, legendary = 50
    },
    LevelScale = 100,
    LootSpeedPerLevel = 0.02,
    LootBonusMilestones = {5, 10, 20},
    RarityBoostPerLevel = 0.02
}

----------------------
-- Lootables        --
----------------------
DVS.Lootables = {
    Table = {
        ScrapPieces = { min = 1, max = 4, chance = 100 },
        Weapons = {
            { class = "weapon_pistol", chance = 5 },
            { class = "weapon_smg1",   chance = 3 }
        },
        Entities = {
            { class = "money_printer", chance = 2 }
        },
        Props = {
            { model = "models/props_junk/SawBlade001a.mdl",  chance = 40 },
            { model = "models/props_junk/wood_crate001a.mdl", chance = 25 }
        },
        Rolls = 3
    }
}

--------------------
-- Scrapper Config --
--------------------
DVS.Scrapper = {
    Duration = 3,
    ScrapOutput = {min = 1, max = 3},
    AllowedItems = {
        "ent_dmg_battery",
        "weapon_pistol",
        "weapon_smg1",
        "weapon_shotgun"
    },
    XPReward = {
        Base = 5,        -- flat XP per scrapping job
        PerScrap = 1,     -- XP per scrap piece produced
        LevelScale = 0.03 -- XP increases 3% per player scrap level
    },
    Sounds = {
        Start  = "ambient/machines/machine3.wav",
        Loop   = "ambient/machines/machine3.wav",
        End    = "ambient/machines/machine_stop1.wav",
        Clunks = {
            "ambient/materials/metal_stress2.wav",
            "ambient/materials/metal_stress3.wav",
            "ambient/materials/metal_solid_impact1.wav",
            "ambient/materials/metal_stress4.wav"
        }
    }
}
