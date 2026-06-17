local QBCore = exports['qb-core']:GetCoreObject()
local marketOpen = false

local handlingCache = {} -- [netId] = { baseline = {floats,ints,vectors}, applied = {floats,ints,vectors}, hash = nil }

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
    -- GTA plate text max is 8 chars; keep it safe
    if #p > 7 then p = p:sub(1, 7) end
    return " " .. p
end

local function hashHandlingPayload(payload)
    if type(payload) ~= 'table' then return nil end
    local ok, encoded = pcall(json.encode, payload)
    if not ok or not encoded then return nil end
    return GetHashKey(encoded)
end

local function getOrCreateCache(netId)
    handlingCache[netId] = handlingCache[netId] or {
        baseline = { floats = {}, ints = {}, vectors = {} },
        applied = { floats = {}, ints = {}, vectors = {} },
        hash = nil
    }
    return handlingCache[netId]
end

local function ensureBaselineField(cache, veh, kind, field)
    local store = cache.baseline[kind]
    if store[field] ~= nil then return end

    if kind == 'floats' then
        store[field] = GetVehicleHandlingFloat(veh, 'CHandlingData', field)
    elseif kind == 'ints' then
        store[field] = GetVehicleHandlingInt(veh, 'CHandlingData', field)
    elseif kind == 'vectors' then
        local vec = GetVehicleHandlingVector(veh, 'CHandlingData', field)
        store[field] = { x = vec.x + 0.0, y = vec.y + 0.0, z = vec.z + 0.0 }
    end
end

local function resetAppliedFields(cache, veh)
    for field in pairs(cache.applied.floats) do
        local base = cache.baseline.floats[field]
        if base ~= nil then
            SetVehicleHandlingFloat(veh, 'CHandlingData', field, base + 0.0)
        end
    end
    for field in pairs(cache.applied.ints) do
        local base = cache.baseline.ints[field]
        if base ~= nil then
            SetVehicleHandlingInt(veh, 'CHandlingData', field, math.floor(base + 0.0))
        end
    end
    for field in pairs(cache.applied.vectors) do
        local base = cache.baseline.vectors[field]
        if type(base) == 'table' then
            SetVehicleHandlingVector(veh, 'CHandlingData', field, vector3(base.x + 0.0, base.y + 0.0, base.z + 0.0))
        end
    end

    cache.applied.floats = {}
    cache.applied.ints = {}
    cache.applied.vectors = {}
end

local function applyOverrides(cache, veh, payload)
    if type(payload) ~= 'table' then return end

    if type(payload.floats) == 'table' then
        for field, value in pairs(payload.floats) do
            if value ~= nil then
                ensureBaselineField(cache, veh, 'floats', field)
                if cache.baseline.floats[field] ~= nil then
                    SetVehicleHandlingFloat(veh, 'CHandlingData', field, value + 0.0)
                    cache.applied.floats[field] = true
                end
            end
        end
    end

    if type(payload.ints) == 'table' then
        for field, value in pairs(payload.ints) do
            if value ~= nil then
                ensureBaselineField(cache, veh, 'ints', field)
                if cache.baseline.ints[field] ~= nil then
                    SetVehicleHandlingInt(veh, 'CHandlingData', field, math.floor(value + 0.0))
                    cache.applied.ints[field] = true
                end
            end
        end
    end

    if type(payload.vectors) == 'table' then
        for field, value in pairs(payload.vectors) do
            if type(value) == 'table' then
                ensureBaselineField(cache, veh, 'vectors', field)
                if cache.baseline.vectors[field] then
                    SetVehicleHandlingVector(veh, 'CHandlingData', field, vector3(value.x + 0.0, value.y + 0.0, value.z + 0.0))
                    cache.applied.vectors[field] = true
                end
            end
        end
    end
end

local function applyHandlingStateToEntity(netId, veh, payload)
    if veh == 0 or type(payload) ~= 'table' then return end

    local cache = getOrCreateCache(netId)
    local payloadHash = hashHandlingPayload(payload)
    if cache.hash and payloadHash and cache.hash == payloadHash then
        return
    end

    resetAppliedFields(cache, veh)
    applyOverrides(cache, veh, payload)
    cache.hash = payloadHash
end

local function withVehicleFromBag(bagName, cb)
    local netId = tonumber(bagName:match('entity:(%d+)'))
    if not netId then return end

    local veh = NetToVeh(netId)
    if veh ~= 0 then
        cb(netId, veh)
        return
    end

    CreateThread(function()
        local attempts = 0
        while attempts < 50 do
            Wait(50)
            veh = NetToVeh(netId)
            if veh ~= 0 then
                cb(netId, veh)
                return
            end
            attempts = attempts + 1
        end
    end)
end

AddStateBagChangeHandler('dudaplus_handling', nil, function(bagName, _, value)
    withVehicleFromBag(bagName, function(netId, veh)
        applyHandlingStateToEntity(netId, veh, value)
    end)
end)

local function buildHandlingSnapshot(veh)
    if veh == 0 then return nil end
    local whitelist = Config.ConditionHandling or {}
    local floats, ints, vectors = {}, {}, {}

    if whitelist.floats then
        for field in pairs(whitelist.floats) do
            floats[field] = GetVehicleHandlingFloat(veh, 'CHandlingData', field)
        end
    end

    if whitelist.ints then
        for field in pairs(whitelist.ints) do
            ints[field] = GetVehicleHandlingInt(veh, 'CHandlingData', field)
        end
    end

    if whitelist.vectors then
        for field in pairs(whitelist.vectors) do
            local vec = GetVehicleHandlingVector(veh, 'CHandlingData', field)
            vectors[field] = { x = vec.x + 0.0, y = vec.y + 0.0, z = vec.z + 0.0 }
        end
    end

    return {
        floats = next(floats) and floats or nil,
        ints = next(ints) and ints or nil,
        vectors = next(vectors) and vectors or nil
    }
end

RegisterCommand("market", function()
    if marketOpen then
        -- CLOSE
        SetNuiFocus(false, false)
        marketOpen = false
        SendNUIMessage({ action = "close" })
    else
        -- OPEN
        marketOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "open" })
        TriggerServerEvent("dudaplus:requestListings")
    end
end)

RegisterKeyMapping('market', 'Open vehicle marketplace', 'keyboard', 'F7')

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    marketOpen = false
    SendNUIMessage({ action = "close" })  -- tell JS to hide #app
    cb("ok")
end)

RegisterNetEvent("dudaplus:setListings", function(listings, nextRefresh)
    SendNUIMessage({
        action = "setListings",
        listings = listings,
        nextRefresh = nextRefresh
    })
end)

RegisterNUICallback("buyVehicle", function(data, cb)
    if data and data.listingId then
        TriggerServerEvent("dudaplus:buyVehicle", data.listingId)
    end
    cb("ok")
end)

-- client.lua, inside your "buy car" logic
local vehicleToBuy = {
    model = selectedModel,
    price = selectedPrice
    -- whatever else you want
}

QBCore.Functions.TriggerCallback('dudaplus:canBuyVehicle', function(canBuy, reason, capacity, currentCount)
    if not canBuy then
        if reason == 'no_garages' then
            QBCore.Functions.Notify("You don't own any garages, nowhere to park this car.", "error")
        elseif reason == 'no_space' then
            QBCore.Functions.Notify(("Garage full (%d/%d cars). Upgrade or sell something first."):format(currentCount, capacity), "error")
        else
            QBCore.Functions.Notify("Purchase blocked: "..tostring(reason), "error")
        end
        return
    end

    TriggerServerEvent('dudaplus:buyVehicle', vehicleToBuy)
end, vehicleToBuy)

RegisterNetEvent('dudaplus:client:spawnPurchasedVehicle', function(data)
    local model   = data.model
    local plate   = data.plate
    local coords  = data.coords
    local heading = data.heading or 0.0
    local color   = data.color

    local modelHash = joaat(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    -- Create vehicle
    local veh = CreateVehicle(
        modelHash,
        coords.x, coords.y, coords.z,
        heading,
        true,   -- networked
        false
    )

    if not DoesEntityExist(veh) then
        print("[DUDAPLUS] Vehicle spawn failed:", model)
        return
    end

    -- Apply plate
    SetVehicleNumberPlateText(veh, PlateDisplay(plate))

    -- Apply color (AFTER spawn)
    if color and color.primary and color.secondary then
        SetVehicleColours(veh, color.primary, color.secondary)
    end

    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)

    -- Give keys
    TriggerEvent('vehiclekeys:client:SetOwner', NormalizePlate(plate))
    local snapshot = buildHandlingSnapshot(veh)
    TriggerServerEvent('dudaplus:server:AttachVehicleState', VehToNet(veh), NormalizePlate(plate), snapshot)

    TriggerServerEvent(
        'bp_garage:addownervehicle:server',
        NormalizePlate(plate),
        modelHash,
        model,
        vehprops,
        false
    )

    -- Set GPS waypoint
    SetNewWaypoint(coords.x, coords.y)

    -- Cleanup
    SetModelAsNoLongerNeeded(modelHash)

    print(("[DUDAPLUS] Spawned %s (%s) at %.2f %.2f %.2f"):format(
        model, plate, coords.x, coords.y, coords.z
    ))
end)


