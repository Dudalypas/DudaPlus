local QBCore = exports['qb-core']:GetCoreObject()

local currentListings = {}
local lastRefresh = 0

local VehicleColors = {
    { label = "Black",        primary = 0,   secondary = 0   },
    { label = "White",        primary = 111, secondary = 111 },
    { label = "Red",          primary = 27,  secondary = 27  },
    { label = "Blue",         primary = 64,  secondary = 64  },
    { label = "Dark Blue",    primary = 62,  secondary = 62  },
    { label = "Yellow",       primary = 88,  secondary = 88  },
    { label = "Orange",       primary = 38,  secondary = 38  },
    { label = "Green",        primary = 50,  secondary = 50  },
    { label = "Dark Green",   primary = 49,  secondary = 49  },
    { label = "Silver",       primary = 4,   secondary = 4   },
    { label = "Gray",         primary = 5,   secondary = 5   },
    { label = "Graphite",     primary = 6,   secondary = 6   },
        -- Blacks / Greys
    { label = "Carbon Black",      primary = 147, secondary = 147 },
    { label = "Anthracite",        primary = 11,  secondary = 11  },
    { label = "Dark Steel",        primary = 3,   secondary = 3   },
    { label = "Light Gray",        primary = 7,   secondary = 7   },

    -- Whites
    { label = "Ice White",         primary = 112, secondary = 112 },
    { label = "Pearl White",      primary = 113, secondary = 113 },

    -- Reds
    { label = "Dark Red",          primary = 143, secondary = 143 },
    { label = "Wine Red",          primary = 146, secondary = 146 },
    { label = "Bright Red",        primary = 28,  secondary = 28  },

    -- Blues
    { label = "Midnight Blue",     primary = 141, secondary = 141 },
    { label = "Saxon Blue",        primary = 63,  secondary = 63  },
    { label = "Ultra Blue",        primary = 70,  secondary = 70  },
    { label = "Navy Blue",         primary = 61,  secondary = 61  },

    -- Greens
    { label = "Racing Green",      primary = 53,  secondary = 53  },
    { label = "Olive Green",       primary = 52,  secondary = 52  },
    { label = "Lime Green",        primary = 55,  secondary = 55  },

    -- Yellows / Oranges
    { label = "Mustard Yellow",    primary = 89,  secondary = 89  },
    { label = "Sunrise Orange",    primary = 36,  secondary = 36  },

    -- Brown
    { label = "Bronze",            primary = 90,  secondary = 90  },
    { label = "Dark Bronze",       primary = 91,  secondary = 91  },
    { label = "Beige",             primary = 106, secondary = 106 },

    -- Silvers
    { label = "Aluminum",          primary = 8,   secondary = 8   },
    { label = "Steel Gray",        primary = 9,   secondary = 9   }
}

local RarityLabels = {
    [1] = "Common",
    [2] = "Upper-Common",
    [3] = "Enthusiast",
    [4] = "Epic / Collector",
    [5] = "Legendary"
}

local RarityMultipliers = Config.RarityMultipliers or {}
local RarityUpgradeCfg = Config.RarityUpgrade or {}
local RarityUpgradeCosts = RarityUpgradeCfg.costs or {}
local RarityUpgradeMax = RarityUpgradeCfg.maxRarity or 5
local RarityUpgradeAccount = RarityUpgradeCfg.account or Config.MoneyAccount or 'bank'
local RarityUpgradeWarning = RarityUpgradeCfg.warningR5
local ActiveRarityUpgrades = {}

local HandlingConfig = Config.ConditionHandling or {}
HandlingConfig.floats = HandlingConfig.floats or {}
HandlingConfig.ints = HandlingConfig.ints or {}
HandlingConfig.vectors = HandlingConfig.vectors or {}

local function clampNumber(val, min, max)
    val = tonumber(val)
    if not val then return nil end
    if min ~= nil and val < min then val = min end
    if max ~= nil and val > max then val = max end
    return val
end

local function safeJsonDecode(payload)
    if not payload or payload == '' then return nil end
    local ok, data = pcall(json.decode, payload)
    if not ok then return nil end
    return data
end

local function NormalizePlate(p)
    p = tostring(p or "")
    p = p:gsub("%z", "")                 -- remove nulls just in case
    p = p:gsub("^%s*(.-)%s*$", "%1")     -- trim ends (kills GTA padding)
    p = p:upper()
    p = p:gsub("%s+", " ")               -- collapse multiple spaces to one
    return p
end

local function PlateCanonical(p)
    return NormalizePlate(p)
end

local function PlateDisplay(p)
    p = PlateCanonical(p)
    if p == "" then return "" end
    if #p > 7 then p = p:sub(1, 7) end
    return " " .. p
end

local function getRarityLabel(r)
    return RarityLabels[tonumber(r) or 0] or ("R" .. tostring(r or "?"))
end

local function getRarityMultiplier(r)
    local mult = RarityMultipliers[tonumber(r) or 0]
    if not mult then mult = 1.0 end
    return mult
end

local function buildRarityUpgradeQuote(rarity, Player)
    local current = tonumber(rarity) or 1
    if current < 1 then current = 1 end
    if current > RarityUpgradeMax then current = RarityUpgradeMax end

    local result = {
        current = current,
        currentLabel = getRarityLabel(current),
        currentMultiplier = getRarityMultiplier(current),
        account = RarityUpgradeAccount,
        maxed = true
    }

    local entry = RarityUpgradeCosts[current]
    local nextTier = entry and entry.next or (current + 1)
    if not entry or not nextTier or nextTier <= current or current >= RarityUpgradeMax then
        if Player then
            result.balance = Player.Functions.GetMoney(RarityUpgradeAccount)
        end
        return result
    end

    if nextTier > RarityUpgradeMax then
        nextTier = RarityUpgradeMax
    end

    local cost = tonumber(entry.cost) or 0

    result.maxed = false
    result.next = nextTier
    result.nextLabel = getRarityLabel(nextTier)
    result.nextMultiplier = getRarityMultiplier(nextTier)
    result.cost = cost

    if Player then
        local balance = Player.Functions.GetMoney(RarityUpgradeAccount)
        result.balance = balance
        if balance ~= nil then
            result.canAfford = balance >= cost
            if not result.canAfford then
                result.shortfall = cost - balance
            end
        end
    end

    if current == (RarityUpgradeMax - 1) and RarityUpgradeWarning and RarityUpgradeWarning ~= '' then
        result.warning = RarityUpgradeWarning
    end

    return result
end

local function sanitizeVector(vec, limits)
    if type(vec) ~= 'table' then return nil end
    local x, y, z = tonumber(vec.x), tonumber(vec.y), tonumber(vec.z)
    if not x or not y or not z then return nil end

    local xLimits = limits and limits.x or {}
    local yLimits = limits and limits.y or {}
    local zLimits = limits and limits.z or {}

    x = clampNumber(x, xLimits.min or -1000.0, xLimits.max or 1000.0)
    y = clampNumber(y, yLimits.min or -1000.0, yLimits.max or 1000.0)
    z = clampNumber(z, zLimits.min or -1000.0, zLimits.max or 1000.0)
    if not x or not y or not z then return nil end

    return { x = x, y = y, z = z }
end

local function sanitizeHandlingPayload(payload)
    if type(payload) ~= 'table' then return nil end

    local floats, ints, vectors = {}, {}, {}
    local hasData = false

    if type(payload.floats) == 'table' then
        for field, value in pairs(payload.floats) do
            local limits = HandlingConfig.floats[field]
            if limits then
                local num = clampNumber(value, limits.min, limits.max)
                if num then
                    floats[field] = num
                    hasData = true
                end
            end
        end
    end

    if type(payload.ints) == 'table' then
        for field, value in pairs(payload.ints) do
            local limits = HandlingConfig.ints[field]
            if limits then
                local num = clampNumber(value, limits.min, limits.max)
                if num then
                    ints[field] = math.floor(num + 0.0)
                    hasData = true
                end
            end
        end
    end

    if type(payload.vectors) == 'table' then
        for field, vec in pairs(payload.vectors) do
            local limits = HandlingConfig.vectors[field]
            if limits then
                local sanitized = sanitizeVector(vec, limits)
                if sanitized then
                    vectors[field] = sanitized
                    hasData = true
                end
            end
        end
    end

    if not hasData then return nil end
    if next(floats) == nil then floats = nil end
    if next(ints) == nil then ints = nil end
    if next(vectors) == nil then vectors = nil end

    return {
        floats = floats,
        ints = ints,
        vectors = vectors
    }
end

local function copyHandlingPayload(payload)
    if type(payload) ~= 'table' then return nil end
    local out = {}

    if type(payload.floats) == 'table' then
        out.floats = {}
        for k, v in pairs(payload.floats) do
            out.floats[k] = v
        end
    end

    if type(payload.ints) == 'table' then
        out.ints = {}
        for k, v in pairs(payload.ints) do
            out.ints[k] = v
        end
    end

    if type(payload.vectors) == 'table' then
        out.vectors = {}
        for k, vec in pairs(payload.vectors) do
            if type(vec) == 'table' then
                out.vectors[k] = { x = vec.x, y = vec.y, z = vec.z }
            end
        end
        if next(out.vectors) == nil then
            out.vectors = nil
        end
    end

    if not out.floats and not out.ints and not out.vectors then
        return nil
    end

    return out
end

local function computeEffectiveHandling(baseTune, vcondition)
    if not baseTune then return nil end
    local final = copyHandlingPayload(baseTune)
    if not final then return nil end

    local damages = type(vcondition) == 'table' and vcondition.damages or nil
    if not damages or not Config.DamageTypes then
        return final
    end

    for _, dmg in ipairs(damages) do
        local def = Config.DamageTypes[dmg.id]
        if def and type(def.effects) == 'table' then
            local sev = clampNumber(dmg.sev or 0.5, 0.0, 1.0) or 0.0
            for _, eff in ipairs(def.effects) do
                local effVal = tonumber(eff.value)
                if eff.kind == 'float' and final.floats and final.floats[eff.field] ~= nil and effVal then
                    local cur = final.floats[eff.field]
                    if eff.type == 'mul' then
                        cur = cur * (1.0 - sev * (1.0 - effVal))
                    elseif eff.type == 'add' then
                        cur = cur + sev * effVal
                    end
                    local limits = HandlingConfig.floats[eff.field]
                    if limits then
                        cur = clampNumber(cur, limits.min, limits.max) or cur
                    end
                    final.floats[eff.field] = cur
                elseif eff.kind == 'int' and final.ints and final.ints[eff.field] ~= nil and effVal then
                    local cur = final.ints[eff.field]
                    if eff.type == 'mul' then
                        cur = cur * (1.0 - sev * (1.0 - effVal))
                    elseif eff.type == 'add' then
                        cur = cur + sev * effVal
                    end
                    local limits = HandlingConfig.ints[eff.field]
                    if limits then
                        cur = clampNumber(cur, limits.min, limits.max) or cur
                    end
                    final.ints[eff.field] = math.floor(cur + 0.5)
                elseif eff.kind == 'vector' and final.vectors and final.vectors[eff.field] and type(final.vectors[eff.field]) == 'table' then
                    local vec = final.vectors[eff.field]
                    if eff.type == 'add' and type(effVal) == 'number' then
                        vec.x = vec.x + effVal * sev
                        vec.y = vec.y + effVal * sev
                        vec.z = vec.z + effVal * sev
                    end
                    local limits = HandlingConfig.vectors[eff.field]
                    if limits then
                        vec.x = clampNumber(vec.x, limits.x.min, limits.x.max) or vec.x
                        vec.y = clampNumber(vec.y, limits.y.min, limits.y.max) or vec.y
                        vec.z = clampNumber(vec.z, limits.z.min, limits.z.max) or vec.z
                    end
                end
            end
        end
    end

    return final
end

local function ensureVehicleColumns()
    CreateThread(function()
        Wait(500)

        local function ensure(column, ddl)
            local ok, exists = pcall(function()
                local result = MySQL.scalar.await(
                    'SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "player_vehicles" AND COLUMN_NAME = ?',
                    { column }
                )
                return result and result > 0
            end)

            if ok and not exists then
                pcall(function()
                    MySQL.query.await(ddl)
                end)
            end
        end

        ensure('handling', 'ALTER TABLE player_vehicles ADD COLUMN handling LONGTEXT NULL')
        ensure('vcondition', 'ALTER TABLE player_vehicles ADD COLUMN vcondition LONGTEXT NULL')
    end)
end

ensureVehicleColumns()

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function randFloat(a, b)
    return a + (b - a) * math.random()
end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function getRarityConfig(rarity)
    local r = tonumber(rarity) or 1
    if r < 1 then r = 1 end
    if r > 5 then r = 5 end
    return Config.Rarity and Config.Rarity[r] or nil, r
end

local function skewedRandom01(skewToHigh, pow)
    local u = math.random()
    pow = pow or 1.5
    if skewToHigh then
        return 1.0 - (u ^ pow)
    end
    return (u ^ pow)
end

local function getRarityBounds(rarityCfg)
    local minKm = tonumber(rarityCfg.mileageMin) or 0
    local maxKm = tonumber(rarityCfg.mileageMax) or tonumber(rarityCfg.full) or (minKm + 100000)
    if maxKm <= minKm then
        maxKm = minKm + 1
    end
    return minKm, maxKm
end

local function rollMileageKm(rarity)
    local rarityCfg, normalized = getRarityConfig(rarity)
    if not rarityCfg then
        return math.random(0, 300000), normalized
    end

    local minKm, maxKm = getRarityBounds(rarityCfg)
    local u = skewedRandom01(rarityCfg.skewToHigh, rarityCfg.skewPow)
    local km = math.floor(minKm + (maxKm - minKm) * u)
    return km, normalized
end

local function computeConditionPercent(rarity, mileageKm)
    local rarityCfg = getRarityConfig(rarity)
    if not rarityCfg then return 0.0 end
    local minKm, maxKm = getRarityBounds(rarityCfg)
    local span = maxKm - minKm
    if span <= 0 then span = 1 end
    local pct = ((tonumber(mileageKm) or minKm) - minKm) / span
    return clampNumber(pct, 0.0, 1.0) or 0.0
end

local function pickConditionLabel(percent)
    local labels = Config.ConditionLabels or {}
    if #labels == 0 then
        return percent <= 0.2 and "Fresh" or (percent <= 0.6 and "Used" or "Worn")
    end

    for _, entry in ipairs(labels) do
        if percent <= entry.threshold then
            return entry.label
        end
    end

    return labels[#labels].label
end

local function computeDamageCount(rarityCfg, mileageKm, percent)
    local maxDamages = rarityCfg.maxDamages or 0
    if maxDamages <= 0 then return 0 end

    local target = math.floor(percent * maxDamages + 0.0001)
    local hi = tonumber(rarityCfg.hi) or math.huge
    local full = tonumber(rarityCfg.full) or math.huge

    if mileageKm >= hi then
        target = math.max(target, 1)
    end

    if mileageKm >= full then
        target = maxDamages
    end

    if target > maxDamages then target = maxDamages end
    if target < 0 then target = 0 end
    return target
end

local function wearFromMileage(rarity, mileageKm)
    return computeConditionPercent(rarity, mileageKm)
end

local function rollDamages(rarity, mileageKm, conditionPercent)
    local rarityCfg = getRarityConfig(rarity)
    local damageDefs = Config.DamageTypes or {}
    if not rarityCfg or not next(damageDefs) then return {}, 0 end

    local percent = conditionPercent
    if percent == nil then
        percent = computeConditionPercent(rarity, mileageKm)
    end

    local damageCount = computeDamageCount(rarityCfg, mileageKm, percent)
    if damageCount <= 0 then
        return {}, 0
    end

    local primary, fallback = {}, {}
    for id, def in pairs(damageDefs) do
        if percent >= (def.minWear or 0.0) then
            primary[#primary + 1] = id
        else
            fallback[#fallback + 1] = id
        end
    end

    local orderedPool = {}
    if #primary > 0 then
        shuffle(primary)
        for _, id in ipairs(primary) do
            orderedPool[#orderedPool + 1] = id
        end
    end
    if #fallback > 0 then
        shuffle(fallback)
        for _, id in ipairs(fallback) do
            orderedPool[#orderedPool + 1] = id
        end
    end

    if #orderedPool == 0 then
        for id in pairs(damageDefs) do
            orderedPool[#orderedPool + 1] = id
        end
        shuffle(orderedPool)
    end

    local out, used = {}, {}
    local idx = 1
    while #out < damageCount and idx <= #orderedPool do
        local damageId = orderedPool[idx]
        if not used[damageId] then
            local def = damageDefs[damageId]
            if def then
                local sevMin = def.sevMin or 0.3
                local sevMax = def.sevMax or 1.0
                local sev = clampNumber(lerp(sevMin, sevMax, percent), 0.0, 1.0) or 0.0
                out[#out + 1] = {
                    id = damageId,
                    label = def.label or damageId,
                    sev = sev
                }
                used[damageId] = true
            end
        end
        idx = idx + 1
    end

    return out, #out
end

local function buildVCondition(rarity, mileageKm, damages, conditionPercent, conditionLabel, damageCount, conditionScore, damageSummary)
    local dmgCount = damageCount or (damages and #damages or 0)
    local pct = conditionPercent or wearFromMileage(rarity, mileageKm)
    local summary = damageSummary or {
        count = dmgCount,
        avgSeverity = 0.0,
        penalty = 0.0
    }
    local score = conditionScore or (1.0 - pct)

    return {
        rarity = rarity,
        mileageKm = mileageKm,
        wear = pct,
        conditionPercent = pct,
        conditionScore = clampNumber(score, 0.05, 1.0) or 0.05,
        conditionLabel = conditionLabel or pickConditionLabel(pct),
        damageCount = dmgCount,
        damageSummary = summary,
        damages = damages or {},
        dudaplusEffective = false
    }
end

local function computeConditionScore(rarity, conditionPercent, damages)
    local rarityCfg = getRarityConfig(rarity)
    local maxDamages = rarityCfg and rarityCfg.maxDamages or 1
    if not maxDamages or maxDamages <= 0 then
        maxDamages = 1
    end

    local count, sum = 0, 0.0
    if type(damages) == 'table' then
        for _, dmg in ipairs(damages) do
            local sev = clampNumber(dmg.sev, 0.0, 1.0) or 0.0
            sum = sum + sev
            count = count + 1
        end
    end

    local avgSeverity = count > 0 and (sum / count) or 0.0
    local damagePenalty = avgSeverity / maxDamages

    local totalPenalty = (conditionPercent or 0.0) + damagePenalty
    local score = clampNumber(1.0 - totalPenalty, 0.05, 1.0) or 0.05

    return score, {
        count = count,
        avgSeverity = avgSeverity,
        penalty = damagePenalty
    }
end

local function computePriceFromCondition(minPrice, maxPrice, conditionScore)
    local minP = tonumber(minPrice) or 0
    local maxP = tonumber(maxPrice) or minP
    if maxP < minP then
        maxP = minP
    end

    local score = clampNumber(conditionScore, 0.05, 1.0) or 0.05
    local raw = minP + (maxP - minP) * score
    local price = math.floor(raw + 0.5)

    if price < minP then price = minP end
    if price > maxP then price = maxP end
    return price
end

local function GetRandomListingLocation()
    if not Config.ListingLocations or #Config.ListingLocations == 0 then
        return "default", "Unknown"
    end

    local choice = Config.ListingLocations[math.random(1, #Config.ListingLocations)]
    local key = choice.key or "default"
    local label = choice.label or key

    if not Config.SpawnPoints[key] then
        key = "default"
        label = "Unknown"
    end

    return key, label
end

local function buildListing(vehicle)
    if not vehicle then return nil end

    local rarity = tonumber(vehicle.rarity) or 1
    if rarity < 1 then rarity = 1 end
    if rarity > 5 then rarity = 5 end

    local mileageKm = rollMileageKm(rarity)
    local conditionPercent = computeConditionPercent(rarity, mileageKm)
    local conditionLabel = pickConditionLabel(conditionPercent)
    local damages, damageCount = rollDamages(rarity, mileageKm, conditionPercent)
    local conditionScore, damageSummary = computeConditionScore(rarity, conditionPercent, damages)
    local price = computePriceFromCondition(vehicle.minPrice, vehicle.maxPrice, conditionScore)
    local vcond = buildVCondition(rarity, mileageKm, damages, conditionPercent, conditionLabel, damageCount, conditionScore, damageSummary)

    local spawnKey, locationLabel
    if vehicle.spawnKey then
        spawnKey = vehicle.spawnKey
        locationLabel = vehicle.location
        if not locationLabel then
            for _, loc in ipairs(Config.ListingLocations or {}) do
                if loc.key == spawnKey then
                    locationLabel = loc.label
                    break
                end
            end
        end
        locationLabel = locationLabel or spawnKey
    else
        spawnKey, locationLabel = GetRandomListingLocation()
    end

    local color = VehicleColors[math.random(#VehicleColors)]
    if not color then
        color = { label = "Default", primary = 0, secondary = 0 }
    end

    return {
        id = vehicle.model .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999)),
        model = vehicle.model,
        label = vehicle.label,
        price = price,
        stock = 1,
        rarity = rarity,
        mileageKm = mileageKm,
        conditionPercent = conditionPercent,
        conditionScore = conditionScore,
        conditionLabel = conditionLabel,
        damageCount = damageCount,
        damageSummary = damageSummary,
        vcondition = vcond,
        class = vehicle.class or "Other",
        image = vehicle.image or "img/default.jpg",
        spawnKey = spawnKey,
        location = locationLabel,
        color = {
            label = color.label,
            primary = color.primary,
            secondary = color.secondary
        }
    }
end

local function generateListings()
    currentListings = {}

    local perRarity = Config.ListingsPerRarity or 6
    if perRarity < 1 then perRarity = 1 end

    local rarityPools = {}
    for _, vehicle in ipairs(Config.Vehicles or {}) do
        local rarity = tonumber(vehicle.rarity) or 1
        if rarity < 1 then rarity = 1 end
        if rarity > 5 then rarity = 5 end
        rarityPools[rarity] = rarityPools[rarity] or {}
        table.insert(rarityPools[rarity], vehicle)
    end

    for rarity = 1, 5 do
        local pool = rarityPools[rarity]
        if pool and #pool > 0 then
            shuffle(pool)
            local produced = 0
            while produced < perRarity do
                local vehicle = pool[((produced) % #pool) + 1]
                local listing = buildListing(vehicle)
                if not listing then
                    break
                end
                table.insert(currentListings, listing)
                produced = produced + 1
            end

            if produced < perRarity then
                print(("[dudaplus] only generated %d/%d listings for rarity %d"):format(produced, perRarity, rarity))
            end
        else
            print(("[dudaplus] no vehicles configured for rarity %d; skipping category."):format(rarity))
        end
    end

    if #currentListings > 1 then
        shuffle(currentListings)
    end

    lastRefresh = os.time()
    print(("[dudaplus] generated %d listings"):format(#currentListings))
end

local function RandomPlateLT()
    local letters = "ABCDEFGHIJKLMNOPRSTUVYZ"
    local function L()
        local i = math.random(1, #letters)
        return letters:sub(i, i)
    end
    local nums = math.random(0, 999)
    return string.format(" %s%s%s %03d", L(), L(), L(), nums)
end

local function GivePlayerVehicle(Player, listing)
    local src = Player.PlayerData.source
    local plate = NormalizePlate(RandomPlateLT())
    local modelHash = joaat(listing.model)

    local spawnKey = listing.spawnKey or "default"
    local spawnGroup = Config.SpawnPoints[spawnKey] or Config.SpawnPoints.default
    if not spawnGroup or #spawnGroup == 0 then
        spawnGroup = Config.SpawnPoints.default
    end

    local spot = spawnGroup[math.random(1, #spawnGroup)]
    local coords = spot.coords
    local heading = spot.heading or 0.0

local props = {
    model = modelHash,
    plate = plate,

    -- QBCore props fields:
    color1 = listing.color.primary,
    color2 = listing.color.secondary,

    -- optional: keep your own field too if you want
    color = listing.color
}


    local rarity = tonumber(listing.rarity) or 1
    local mileageKm = listing.mileageKm or rollMileageKm(rarity)
    local conditionPercent = listing.conditionPercent
    local conditionLabel = listing.conditionLabel
    local conditionScore = listing.conditionScore
    local damageSummary = listing.damageSummary
    local damages = listing.vcondition and listing.vcondition.damages or nil

    if type(damages) ~= 'table' then
        damages = nil
    end

    if not conditionPercent then
        conditionPercent = computeConditionPercent(rarity, mileageKm)
    end
    if not conditionLabel then
        conditionLabel = pickConditionLabel(conditionPercent)
    end
    if not damages then
        local rolledDamages, damageCount = rollDamages(rarity, mileageKm, conditionPercent)
        damages = rolledDamages
        listing.damageCount = damageCount
    end

    if not conditionScore or not damageSummary then
        local score, summary = computeConditionScore(rarity, conditionPercent, damages)
        conditionScore = conditionScore or score
        damageSummary = damageSummary or summary
    end

    local vcond = listing.vcondition
    if type(vcond) ~= 'table' then
        vcond = buildVCondition(rarity, mileageKm, damages, conditionPercent, conditionLabel, listing.damageCount, conditionScore, damageSummary)
    else
        vcond.mileageKm = mileageKm
        vcond.conditionPercent = conditionPercent
        vcond.conditionScore = conditionScore or vcond.conditionScore
        vcond.conditionLabel = conditionLabel
        vcond.damageCount = listing.damageCount or (damages and #damages or 0)
        vcond.damageSummary = damageSummary or vcond.damageSummary
        vcond.damages = damages or {}
        vcond.wear = conditionPercent
    end

    listing.vcondition = vcond
    listing.mileageKm = mileageKm
    listing.conditionPercent = conditionPercent
    listing.conditionScore = vcond.conditionScore
    listing.conditionLabel = conditionLabel
    listing.damageCount = vcond.damageCount
    listing.damageSummary = vcond.damageSummary

    MySQL.insert(
        'INSERT INTO player_vehicles (citizenid, vehicle, mods, plate, hash, state, garage, handling, vcondition, vehicle_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            Player.PlayerData.citizenid,
            listing.model,
            json.encode(props),
            plate,
            modelHash,
            0,
            'dudaplus',
            json.encode({}),
            json.encode(vcond),
            listing.label
        }
    )

    TriggerClientEvent('dudaplus:client:spawnPurchasedVehicle', src, {
        model = listing.model,
        plate = PlateDisplay(plate),
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading,
        spawnKey = spawnKey,
        location = listing.location or spawnKey,
        color = listing.color,
        vcondition = vcond,
        mileageKm = mileageKm,
        conditionPercent = vcond.conditionPercent,
        conditionScore = vcond.conditionScore,
        conditionLabel = vcond.conditionLabel,
        damageCount = vcond.damageCount,
        damageSummary = vcond.damageSummary
    })

    -- call this after purchase / when garage updates, etc.
TriggerClientEvent('duda_tracker:refresh', src)

    TriggerClientEvent('QBCore:Notify', src,
        ('You bought %s (%s) for $%s. Go pick it up in %s.'):format(
            listing.label,
            plate,
            listing.price,
            listing.location or spawnKey
        ),
        'success'
    )
end

CreateThread(function()
    math.randomseed(os.time())
    generateListings()

    while true do
        Wait(1000)
        if os.time() - lastRefresh >= Config.RefreshInterval then
            generateListings()
        end
    end
end)

RegisterNetEvent("dudaplus:requestListings", function()
    local src = source
    TriggerClientEvent("dudaplus:setListings", src, currentListings, lastRefresh + Config.RefreshInterval)
end)

local function GetPlayerParkingCapacity(citizenid, cb)
    if not citizenid then
        cb(0)
        return
    end

    MySQL.query('SELECT garagetype FROM bp_garages WHERE garageowner = ?', { citizenid }, function(rows)
        local capacity = 0

        for _, row in ipairs(rows or {}) do
            local gt = row.garagetype

            if gt then
                local decoded = nil
                if type(gt) == "string" and (#gt > 2) and (gt:find("%[") or gt:find("{")) then
                    local ok, res = pcall(json.decode, gt)
                    if ok and type(res) == "table" then
                        decoded = res
                    end
                end

                if decoded then
                    for _, t in ipairs(decoded) do
                        local cap = Config.garagetype[t]
                        if cap then
                            capacity = capacity + cap
                        end
                    end
                else
                    local cap = Config.garagetype[gt]
                    if cap then
                        capacity = capacity + cap
                    end
                end
            end
        end

        cb(capacity)
    end)
end

local function GetPlayerOwnedVehicleCount(citizenid, cb)
    if not citizenid then
        cb(0)
        return
    end

    MySQL.query('SELECT COUNT(*) as cnt FROM player_vehicles WHERE citizenid = ?', { citizenid }, function(rows)
        local count = 0
        if rows and rows[1] and rows[1].cnt then
            count = rows[1].cnt
        end
        cb(count)
    end)
end

QBCore.Functions.CreateCallback('dudaplus:getRarityUpgradeQuote', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil, 'player_not_found')
        return
    end

    local normalized = NormalizePlate(type(plate) == 'string' and plate or '')
    if normalized == "" then
        cb(nil, 'invalid_plate')
        return
    end

    local row = MySQL.single.await('SELECT vcondition FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        normalized,
        Player.PlayerData.citizenid
    })

    if not row then
        cb(nil, 'not_owner')
        return
    end

    local vcond = safeJsonDecode(row.vcondition) or {}
    local rarity = tonumber(vcond.rarity) or 1
    local quote = buildRarityUpgradeQuote(rarity, Player)
    quote.plate = normalized
    cb(quote, 'ok')
end)

RegisterNetEvent('dudaplus:upgradeVehicleRarity', function(payload)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local plate = payload
    if type(payload) == 'table' then
        plate = payload.plate or payload.plateText
    end

    local normalized = NormalizePlate(type(plate) == 'string' and plate or '')
    if normalized == "" then
        TriggerClientEvent('QBCore:Notify', src, 'Select a valid vehicle first.', 'error')
        return
    end

    if ActiveRarityUpgrades[normalized] then
        TriggerClientEvent('QBCore:Notify', src, 'Rarity upgrade already running for this vehicle.', 'error')
        return
    end

    ActiveRarityUpgrades[normalized] = true

    local function finalize()
        ActiveRarityUpgrades[normalized] = nil
    end

    local ok, err = pcall(function()
        local citizenid = Player.PlayerData.citizenid
        local row = MySQL.single.await('SELECT vcondition, vehicle_name FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
            normalized,
            citizenid
        })

        if not row then
            TriggerClientEvent('QBCore:Notify', src, 'Vehicle not found in your garage.', 'error')
            return
        end

        local vcond = safeJsonDecode(row.vcondition) or {}
        local currentRarity = tonumber(vcond.rarity) or 1
        local quote = buildRarityUpgradeQuote(currentRarity, Player)
        if not quote or quote.maxed then
            TriggerClientEvent('QBCore:Notify', src, 'This vehicle already reached its rarity cap.', 'error')
            return
        end

        if not quote.cost or quote.cost <= 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Upgrade unavailable for this tier.', 'error')
            return
        end

        if quote.canAfford == false then
            TriggerClientEvent('QBCore:Notify', src, 'You cannot afford this upgrade.', 'error')
            return
        end

        local removed = Player.Functions.RemoveMoney(RarityUpgradeAccount, quote.cost,
            ('dudaplus-rarity-upgrade-%s'):format(normalized))
        if not removed then
            TriggerClientEvent('QBCore:Notify', src, 'Unable to charge your account.', 'error')
            return
        end

        vcond.rarity = quote.next
        local encoded = json.encode(vcond)
        local affected = MySQL.update.await('UPDATE player_vehicles SET vcondition = ? WHERE plate = ? AND citizenid = ?', {
            encoded,
            normalized,
            citizenid
        })

        if not affected or affected <= 0 then
            Player.Functions.AddMoney(RarityUpgradeAccount, quote.cost, 'dudaplus-rarity-upgrade-refund')
            TriggerClientEvent('QBCore:Notify', src, 'Vehicle record missing. Funds refunded.', 'error')
            return
        end

        local label = row.vehicle_name or normalized
        local charinfo = Player.PlayerData.charinfo or {}
        local playerName = Player.PlayerData.citizenid
        if (charinfo.firstname and charinfo.firstname ~= '') or (charinfo.lastname and charinfo.lastname ~= '') then
            local first = charinfo.firstname or ''
            local last = charinfo.lastname or ''
            playerName = (first .. ' ' .. last):match('^%s*(.-)%s*$') or playerName
        end
        if playerName == '' then
            playerName = Player.PlayerData.citizenid
        end

        local logMessage = ('%s upgraded %s (%s) rarity %s -> %s for €%s'):format(
            playerName,
            label,
            normalized,
            getRarityLabel(currentRarity),
            getRarityLabel(quote.next),
            quote.cost
        )

        print('[dudaplus] ' .. logMessage)
        TriggerEvent('qb-log:server:CreateLog', 'dudaplus', 'Rarity Upgrade', 'green', logMessage)

        TriggerClientEvent('QBCore:Notify', src,
            ('Rarity upgraded to %s (x%.2f payouts).'):format(
                getRarityLabel(quote.next),
                getRarityMultiplier(quote.next)
            ),
            'success'
        )

        local refreshedQuote = buildRarityUpgradeQuote(quote.next, Player)
        if refreshedQuote then
            refreshedQuote.plate = normalized
        end
        TriggerClientEvent('dudaplus:client:rarityUpgradeResult', src, {
            plate = normalized,
            rarity = quote.next,
            quote = refreshedQuote,
            vcondition = vcond
        })
    end)

    finalize()

    if not ok then
        print(('[dudaplus] rarity upgrade failed for %s: %s'):format(normalized, err))
        TriggerClientEvent('QBCore:Notify', src, 'Upgrade failed. Try again later.', 'error')
    end
end)

QBCore.Functions.CreateCallback('dudaplus:canBuyVehicle', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'player_not_found')
        return
    end

    local citizenid = Player.PlayerData.citizenid

    GetPlayerParkingCapacity(citizenid, function(capacity)
        GetPlayerOwnedVehicleCount(citizenid, function(currentCount)
            if capacity <= 0 then
                cb(false, 'no_garages', capacity, currentCount)
                return
            end

            if (currentCount + 1) > capacity then
                cb(false, 'no_space', capacity, currentCount)
            else
                cb(true, 'ok', capacity, currentCount)
            end
        end)
    end)
end)

RegisterNetEvent("dudaplus:buyVehicle", function(listingId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local idx, listing
    for i, l in ipairs(currentListings) do
        if l.id == listingId then
            idx = i
            listing = l
            break
        end
    end

    if not listing then
        TriggerClientEvent('QBCore:Notify', src, 'This listing is no longer available.', 'error')
        return
    end

    if listing.stock <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'This vehicle is sold out.', 'error')
        return
    end

    local citizenid = Player.PlayerData.citizenid

    GetPlayerParkingCapacity(citizenid, function(capacity)
        GetPlayerOwnedVehicleCount(citizenid, function(currentCount)
            if capacity <= 0 then
                TriggerClientEvent('QBCore:Notify', src,
                    'You don\'t own any garages. No place to keep this vehicle.',
                    'error'
                )
                return
            end

            if (currentCount + 1) > capacity then
                TriggerClientEvent('QBCore:Notify', src,
                    ('All your garages are full (%d/%d vehicles). Sell or free a slot first.'):format(currentCount, capacity),
                    'error'
                )
                return
            end

            local account = Config.MoneyAccount or 'cash'
            local PlayerNow = QBCore.Functions.GetPlayer(src)
            if not PlayerNow then return end

            local balance = PlayerNow.Functions.GetMoney(account)

            if balance < listing.price then
                TriggerClientEvent('QBCore:Notify', src, 'Not enough money.', 'error')
                return
            end

            PlayerNow.Functions.RemoveMoney(account, listing.price, 'vehicle-market-purchase')

            listing.stock = listing.stock - 1
            if listing.stock <= 0 and idx then
                table.remove(currentListings, idx)
            end

            GivePlayerVehicle(PlayerNow, listing)

            TriggerClientEvent("dudaplus:setListings", -1, currentListings, lastRefresh + Config.RefreshInterval)
        end)
    end)
end)

RegisterNetEvent('dudaplus:server:AttachVehicleState', function(netId, plate, snapshot)
    local trimmed = NormalizePlate(plate)
    if not trimmed then return end

    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent == 0 then return end

    local row = MySQL.single.await('SELECT handling, vcondition FROM player_vehicles WHERE plate = ?', { trimmed })
    if not row then return end

    local vcond = safeJsonDecode(row.vcondition) or {}
    vcond.damages = vcond.damages or {}

    local savedHandling = sanitizeHandlingPayload(safeJsonDecode(row.handling))
    local snapshotHandling = sanitizeHandlingPayload(snapshot)

    local needsEffective = not vcond.dudaplusEffective or not savedHandling
    local baseTune = savedHandling
    if (needsEffective or not baseTune) and snapshotHandling then
        baseTune = snapshotHandling
    end

    local finalHandling = savedHandling
    if needsEffective and baseTune then
        finalHandling = computeEffectiveHandling(baseTune, vcond)
        if finalHandling then
            vcond.dudaplusEffective = true
            MySQL.update.await('UPDATE player_vehicles SET handling = ?, vcondition = ? WHERE plate = ?',
                { json.encode(finalHandling), json.encode(vcond), trimmed }
            )
        end
    end

    if finalHandling then
        Entity(ent).state:set('dudaplus_handling', finalHandling, true)
    end
    Entity(ent).state:set('dudaplus_vcondition', vcond, true)
end)

exports('AttachVehicleState', function(netId, plate, snapshot)
    TriggerEvent('dudaplus:server:AttachVehicleState', netId, plate, snapshot)
end)
