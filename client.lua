local QBCore = exports['qb-core']:GetCoreObject()
if Config.Debug then print("^2[D3XL-VehicleSave]^7 Sunucu dosyası yüklendi.") end
local lastVehicle = nil


local function GetVehicleVisualDamage(vehicle)
    local damage = {
        doors = {},
        windows = {},
        tires = {}
    }

 
    for i = 0, 5 do
        damage.doors[tostring(i)] = IsVehicleDoorDamaged(vehicle, i)
    end

   
    for i = 0, 7 do
        damage.windows[tostring(i)] = not IsVehicleWindowIntact(vehicle, i)
    end

   
    for i = 0, 7 do
        damage.tires[tostring(i)] = IsVehicleTyreBurst(vehicle, i, false)
    end

    return damage
end


local function ApplyPersistentData(vehicle)
    local state = Entity(vehicle).state
    if not state.isPersistent or state.propsApplied then return end

    if NetworkHasControlOfEntity(vehicle) then
        local props = state.props
        local damage = state.damage
        local fuel = state.fuel
        local engine = state.engine
        local body = state.body

        if props then
            QBCore.Functions.SetVehicleProperties(vehicle, props)
        end

     
        if damage then
            if damage.doors then
                for id, isBroken in pairs(damage.doors) do
                    if isBroken then SetVehicleDoorBroken(vehicle, tonumber(id), true) end
                end
            end
            if damage.windows then
                for id, isSmashed in pairs(damage.windows) do
                    if isSmashed then SmashVehicleWindow(vehicle, tonumber(id)) end
                end
            end
            if damage.tires then
                for id, isBurst in pairs(damage.tires) do
                    if isBurst then SetVehicleTyreBurst(vehicle, tonumber(id), true, 1000.0) end
                end
            end
        end

        if fuel then
            if GetResourceState('d3xl-fuel') == 'started' then
                exports['d3xl-fuel']:setFuel(vehicle, fuel)
            else
                SetVehicleFuelLevel(vehicle, fuel + 0.0)
            end
        end

        if engine then SetVehicleEngineHealth(vehicle, engine + 0.0) end
        if body then SetVehicleBodyHealth(vehicle, body + 0.0) end

        if state.lockstatus then
            TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(vehicle), state.lockstatus)
        end

        TriggerServerEvent('d3xl-vehiclesave:server:setPropsApplied', NetworkGetNetworkIdFromEntity(vehicle))
        if Config.Debug then print("^2[D3XL-VehicleSave]^7 Applied data (Visual Damage Included): " .. (state.plate or "Unknown")) end
    else
        NetworkRequestControlOfEntity(vehicle)
    end
end


CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        
        if veh ~= 0 and not insideVehicle then
            insideVehicle = true
            lastVehicle = veh
        elseif veh == 0 and insideVehicle then
            insideVehicle = false
            Wait(2000)
            
            if lastVehicle and DoesEntityExist(lastVehicle) then
                local plate = GetVehicleNumberPlateText(lastVehicle)
                if plate then
                    local cleanPlate = plate:gsub("^%s*(.-)%s*$", "%1"):upper()
                    local coords = GetEntityCoords(lastVehicle)
                    local heading = GetEntityHeading(lastVehicle)
                    local body = GetVehicleBodyHealth(lastVehicle)
                    local engine = GetVehicleEngineHealth(lastVehicle)
                    local lockstatus = GetVehicleDoorLockStatus(lastVehicle)
                    
                    local fuel = 0
                    if GetResourceState('d3xl-fuel') == 'started' then
                        fuel = exports['d3xl-fuel']:getFuel(lastVehicle) or GetVehicleFuelLevel(lastVehicle)
                    else
                        fuel = GetVehicleFuelLevel(lastVehicle)
                    end
                    
                    local props = QBCore.Functions.GetVehicleProperties(lastVehicle)
                    local damage = GetVehicleVisualDamage(lastVehicle)

                    TriggerServerEvent('d3xl-vehiclesave:server:saveVehicle', cleanPlate, {x = coords.x, y = coords.y, z = coords.z, w = heading}, props, damage, engine, body, fuel, lockstatus)
                end
            end
            lastVehicle = nil
        end
        Wait(1000)
    end
end)


CreateThread(function()
    while true do
        local vehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(vehicles) do
            local state = Entity(vehicle).state
            if state.isPersistent and not state.propsApplied then
                local pedCoords = GetEntityCoords(PlayerPedId())
                local vehCoords = GetEntityCoords(vehicle)
                if #(pedCoords - vehCoords) < 150.0 then
                    ApplyPersistentData(vehicle)
                end
            end
        end
        Wait(2000)
    end
end)
