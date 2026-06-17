Config = {}

-- in seconds - how often new random stock is generated
Config.RefreshInterval = 15 * 15  -- 15 minutes

-- from which account to take money: 'bank' or 'cash'
Config.MoneyAccount = 'cash'

-- how many listings each rarity tab should have (Common..Legendary)
Config.ListingsPerRarity = 6

Config.garagetype = {   
    ["lowgarage"]     = 2,
    ["midgarage"]     = 4,       
    ["highgarage"]    = 6,
    ['premiumgarage'] = 10
}

Config.SpawnPoints = {
    rancho = {
        { coords = vector3(278.53, -2072.98, 16.29), heading = 90.0 },
    },

    legionsquare = {
        { coords = vector3(240.1304, -784.9873, 29.8652), heading = 69.7916 },
        { coords = vector3(185.1136, -1015.8984, 28.5690), heading = 205.4294 },
    },

    sandyshores = {
        { coords = vector3(1963.5946, 3766.0422, 31.4778), heading = 30.7214 },
        { coords = vector3(1384.5477, 3599.2727, 34.1773), heading = 198.3278 },
        { coords = vector3(1971.2253, 3831.3552, 31.2882), heading = 299.8953 },
    },

    paletobay = {
        { coords = vector3(-174.7540, 6444.3662, 30.7725), heading = 45.7488 },
        { coords = vector3(142.7924, 6652.3525, 30.7920), heading = 311.9193 },
        { coords = vector3(-781.3002, 5570.0576, 32.7665), heading = 1.1949 },
        { coords = vector3(-130.2820, 6207.3232, 30.4883), heading = 314.1952 },
        { coords = vector3(-84.2782, 6340.0586, 30.7715), heading = 134.6518 },
    },

    mountgordo = {
        { coords = vector3(1571.0649, 6467.5342, 23.8104), heading = 32.2286 },
        { coords = vector3(1600.3921, 6450.4854, 24.5121), heading = 341.4713 },
    },

    grapeseed = {
        { coords = vector3(2015.0604, 4981.7319, 40.5219), heading = 46.2154 },
        { coords = vector3(2457.8752, 4997.7598, 45.3290), heading = 258.0241 },
        { coords = vector3(1906.4528, 4927.0664, 48.1927), heading = 156.8828 },
    },

    harmony = {
        { coords = vector3(647.2302, 2757.2551, 41.2621), heading = 5.0567 },
        { coords = vector3(374.6247, 2647.5710, 43.7755), heading = 294.9830 },
    },

    vinewoodhills = {
        { coords = vector3(-627.5223, 683.4720, 149.6228), heading = 259.2438 },
        { coords = vector3(654.8678, 684.5685, 128.1919), heading = 245.8354 },
        { coords = vector3(-1078.1852, 796.6332, 165.0509), heading = 189.0265 },
    },

    richman = {
        { coords = vector3(-1613.0946, 185.3405, 59.0895), heading = 120.5467 },
        { coords = vector3(-2004.9319, 455.2133, 101.8818), heading = 268.3520 },
    },

    terminal = {
        { coords = vector3(1209.0000, -3197.3684, 5.3092), heading = 182.3996 },
        { coords = vector3(1197.2903, -3330.5352, 5.3093), heading = 88.3438 },
    },

    delperrobeach = {
        { coords = vector3(-1606.6072, -1028.0897, 12.3694), heading = 139.1455 },
        { coords = vector3(-1856.8645, -609.6838, 10.7276), heading = 321.9624 },
    },

    downtownvinewood = {
        { coords = vector3(194.4374, 58.9984, 82.9041), heading = 255.7469 },
    },

    hawick = {
        { coords = vector3(302.6384, -176.4226, 56.6888), heading = 74.3025 },
    },

    mirrorpark = {
        { coords = vector3(1189.5554, -553.5063, 63.8583), heading = 355.6094 },
        { coords = vector3(1353.8059, -553.9949, 73.3487), heading = 155.1832 },
    },

    -- fallback if listing has unknown / no location
    default = {
        { coords = vector3(713.7291, -2256.9707, 28.5495), heading = 86.2145 },
    }
}

Config.ListingLocations = {
    { key = "rancho",          label = "Rancho" },
    { key = "legionsquare",    label = "Legion Square" },
    { key = "sandyshores",     label = "Sandy Shores" },
    { key = "paletobay",       label = "Paleto Bay" },
    { key = "mountgordo",      label = "Mount Gordo" },
    { key = "grapeseed",       label = "Grapeseed" },
    { key = "harmony",         label = "Harmony" },
    { key = "vinewoodhills",   label = "Vinewood Hills" },
    { key = "richman",         label = "Richman" },
    { key = "terminal",        label = "Terminal" },
    { key = "delperrobeach",   label = "Del Perro Beach" },
    { key = "downtownvinewood",label = "Downtown Vinewood" },
    { key = "hawick",          label = "Hawick" },
    { key = "mirrorpark",      label = "Mirror Park" },
    { key = "default",         label = "City Center" },
}

-- vehicle definitions
Config.Vehicles = {
    {
        model     = "euros",
        label     = "Annis Euros",
        image     = "https://static.wikia.nocookie.net/gtawiki/images/0/05/Euros-GTAOee-FrontQuarter.png/revision/latest/scale-to-width-down/1000?cb=20251012113507",
        minPrice  = 30000,
        maxPrice  = 115000,
        class     = "Coupe",
        rarity    = 2
    },
    {
        model     = "elegy",
        label     = "Annis Elegy Retro Custom",
        image     = "https://static.wikia.nocookie.net/gtawiki/images/8/8a/ElegyRetroCustom-GTAOee-FrontQuarter.png/revision/latest/scale-to-width-down/1000?cb=20251012112729",
        minPrice  = 70000,
        maxPrice  = 200000,
        class     = "Coupe",
        rarity    = 3
    },
    {
        model     = "komoda",
        label     = "Lampadati Komoda",
        image     = "https://static.wikia.nocookie.net/gtawiki/images/2/24/Komoda-GTAO-front.png/revision/latest/scale-to-width-down/1000?cb=20191213212708",
        minPrice  = 70000,
        maxPrice  = 117000,
        class     = "Sedan",
        rarity    = 4
    },
    -- add more...
}
