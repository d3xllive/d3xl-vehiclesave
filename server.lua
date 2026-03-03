local QBCore = exports['qb-core']:GetCoreObject()
if Config.Debug then print("^2[D3XL-VehicleSave]^7 Sunucu dosyası başarıyla yüklendi.") end


CreateThread(function()
    while MySQL == nil do Wait(10) end
    
   
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_persistence` (
            `plate` VARCHAR(255) NOT NULL,
            `citizenid` VARCHAR(50) DEFAULT NULL,
            `coords` LONGTEXT DEFAULT NULL,
            `props` LONGTEXT DEFAULT NULL,
            `damage` LONGTEXT DEFAULT NULL,
            `engine` INT(11) DEFAULT 1000,
            `body` INT(11) DEFAULT 1000,
            `fuel` INT(11) DEFAULT 100,
            `lockstatus` INT(11) DEFAULT 1,
            `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

   
    MySQL.query("ALTER TABLE `vehicle_persistence` ADD COLUMN IF NOT EXISTS `citizenid` VARCHAR(50) DEFAULT NULL AFTER `plate`")
    MySQL.query("ALTER TABLE `vehicle_persistence` ADD COLUMN IF NOT EXISTS `damage` LONGTEXT DEFAULT NULL AFTER `props`")
    MySQL.query("ALTER TABLE `vehicle_persistence` ADD COLUMN IF NOT EXISTS `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER `lockstatus`")
    
    Wait(1000) 
    TriggerEvent('d3xl-vehiclesave:server:spawnAll')
end)


local function SpawnPersistentVehicle(data)
    local coords = json.decode(data.coords)
    local props = json.decode(data.props)
    local damage = json.decode(data.damage or "{}")
    
    if not coords or not props then return nil end

    local model = props.model
    if not model then return nil end

    
    local vehicle = CreateVehicleServerSetter(model, "automobile", coords.x, coords.y, coords.z, coords.w)
    
    local timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 100 do 
        Wait(10) 
        timeout = timeout + 1
    end

    if not DoesEntityExist(vehicle) then return nil end

   
    local state = Entity(vehicle).state
    state:set('isPersistent', true, true)
    state:set('plate', data.plate, true)
    state:set('props', props, true)
    state:set('damage', damage, true)
    state:set('fuel', data.fuel, true)
    state:set('engine', data.engine, true)
    state:set('body', data.body, true)
    state:set('lockstatus', data.lockstatus or 1, true)
    
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleDoorsLocked(vehicle, data.lockstatus or 1)

    if Config.Debug then print("^2[D3XL-VehicleSave]^7 Araç dünyada oluşturuldu: " .. data.plate) end
    return vehicle
end

-- Spawn All Saved Vehicles
RegisterServerEvent('d3xl-vehiclesave:server:spawnAll', function()
    local results = MySQL.query.await('SELECT * FROM vehicle_persistence')
    if results and #results > 0 then
        print("^2[D3XL-VehicleSave]^7 Toplam " .. #results .. " kalıcı araç spawn ediliyor...")
        for _, data in ipairs(results) do
            SpawnPersistentVehicle(data)
            Wait(100) 
        end
    end
end)


local function SaveVehicle(source, plate, coords, props, damage, engine, body, fuel, lockstatus)
    if not plate then return end
    
   
    local cleanPlate = plate:gsub("%s+", ""):upper()
    
    
    local ownerCitizenID = MySQL.scalar.await("SELECT citizenid FROM player_vehicles WHERE REPLACE(UPPER(plate), ' ', '') = ?", {cleanPlate})
    
    if not ownerCitizenID then 
        if Config.Debug then print("^1[D3XL-VehicleSave]^7 Kayıt reddedildi (Sahipsiz araç): " .. cleanPlate) end
        return 
    end

   
    MySQL.query([[
        INSERT INTO vehicle_persistence (plate, citizenid, coords, props, damage, engine, body, fuel, lockstatus, last_seen)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE 
            citizenid = VALUES(citizenid),
            coords = VALUES(coords),
            props = VALUES(props),
            damage = VALUES(damage),
            engine = VALUES(engine),
            body = VALUES(body),
            fuel = VALUES(fuel),
            lockstatus = VALUES(lockstatus),
            last_seen = NOW()
    ]], {plate, ownerCitizenID, json.encode(coords), json.encode(props), json.encode(damage), engine, body, fuel, lockstatus}, function(result)
        if result then
            -- Araç dışarıda olduğu için qb-garage durumunu "dışarıda" yap
            MySQL.query('UPDATE player_vehicles SET state = 0, garage = NULL, depotprice = 0 WHERE REPLACE(UPPER(plate), " ", "") = ?', {cleanPlate})
            if Config.Debug then print("^2[D3XL-VehicleSave]^7 Araç kaydedildi: " .. cleanPlate) end
        end
    end)
end

exports('SaveVehicle', SaveVehicle)


RegisterNetEvent('d3xl-vehiclesave:server:saveVehicle', function(plate, coords, props, damage, engine, body, fuel, lockstatus)
    local src = source
    if not plate then return end
    SaveVehicle(src, plate, coords, props, damage, engine, body, fuel, lockstatus)
end)

RegisterNetEvent('d3xl-vehiclesave:server:setPropsApplied', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        Entity(entity).state:set('propsApplied', true, true)
    end
end)


AddEventHandler('qb-garage:server:updateVehicleState', function(state, plate, garage)
    if state == 1 or state == 2 then -- Garajda veya Çekilmişte
        MySQL.query('DELETE FROM vehicle_persistence WHERE REPLACE(UPPER(plate), " ", "") = ?', {plate:gsub("%s+", ""):upper()})
        if Config.Debug then print("^1[D3XL-VehicleSave]^7 Araç garaja girdiği için persistence silindi: " .. plate) end
    end
end)


CreateThread(function()
    while true do
        Wait(Config.SaveInterval * 60000)
        local allVehicles = GetAllVehicles()
        local spawnedPlates = {}
        
     
        for _, veh in ipairs(allVehicles) do
            local plate = GetVehicleNumberPlateText(veh)
            if plate then
                local cleanPlate = plate:gsub("%s+", ""):upper()
                spawnedPlates[cleanPlate] = true
                
                
                local owner = MySQL.scalar.await("SELECT citizenid FROM player_vehicles WHERE REPLACE(UPPER(plate), ' ', '') = ?", {cleanPlate})
                if owner then
                    local coords = GetEntityCoords(veh)
                    local heading = GetEntityHeading(veh)
                    local engine = GetVehicleEngineHealth(veh)
                    local body = GetVehicleBodyHealth(veh)
                    local fuel = Entity(veh).state.fuel or 100
                    local lockstatus = GetVehicleDoorLockStatus(veh)
                    
                    
                    local isOccupied = false
                    for i = -1, 5 do if GetPedInVehicleSeat(veh, i) ~= 0 then isOccupied = true break end end

                    if engine <= 0 then 
                        MySQL.query('DELETE FROM vehicle_persistence WHERE REPLACE(UPPER(plate), " ", "") = ?', {cleanPlate})
                        MySQL.query('UPDATE player_vehicles SET state = 1, depotprice = ? WHERE REPLACE(UPPER(plate), " ", "") = ?', {Config.DepotPrice, cleanPlate})
                        DeleteEntity(veh)
                    else
                        local q = "UPDATE vehicle_persistence SET coords = ?, engine = ?, body = ?, fuel = ?, lockstatus = ?"
                        if isOccupied then q = q .. ", last_seen = NOW()" end
                        q = q .. " WHERE REPLACE(UPPER(plate), ' ', '') = ?"
                        MySQL.query(q, {json.encode({x = coords.x, y = coords.y, z = coords.z, w = heading}), engine, body, fuel, lockstatus, cleanPlate})
                    end
                end
            end
        end

        
        MySQL.query("SELECT plate FROM vehicle_persistence WHERE last_seen < NOW() - INTERVAL ? HOUR", {Config.InactivityHours}, function(inactiveVehs)
            if inactiveVehs and #inactiveVehs > 0 then
                for _, v in ipairs(inactiveVehs) do
                    local cp = v.plate:gsub("%s+", ""):upper()
                 
                    for _, vEntity in ipairs(allVehicles) do
                        if DoesEntityExist(vEntity) and GetVehicleNumberPlateText(vEntity):gsub("%s+", ""):upper() == cp then
                            DeleteEntity(vEntity)
                            break
                        end
                    end
                    MySQL.query('DELETE FROM vehicle_persistence WHERE REPLACE(UPPER(plate), " ", "") = ?', {cp})
                    MySQL.query('UPDATE player_vehicles SET state = 1, depotprice = ? WHERE REPLACE(UPPER(plate), " ", "") = ?', {Config.DepotPrice, cp})
                end
            end
        end)
    end
end)


QBCore.Commands.Add(Config.WipeCommand, "Wipe all persistent vehicles (Admin Only)", {}, false, function(source)
    local src = source
    MySQL.query('DELETE FROM vehicle_persistence', {}, function()
        local allVehicles = GetAllVehicles()
        local count = 0
        for _, veh in ipairs(allVehicles) do
            if Entity(veh).state.isPersistent then
                DeleteEntity(veh)
                count = count + 1
            end
        end
        TriggerClientEvent('QBCore:Notify', src, "Tüm kalıcı araçlar silindi (" .. count .. " adet)", "success")
    end)
end, "admin")
